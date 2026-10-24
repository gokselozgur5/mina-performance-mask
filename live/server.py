"""Single-client portrait demo. Bind only to loopback and access through SSH."""
import argparse
import io
import json
import socket
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

MAX_BODY = 2 * 1024 * 1024

class PortraitEngine:
    def __init__(self, upstream, source):
        import sys
        sys.path.insert(0, str(upstream))
        import cv2
        import numpy as np
        import torch
        from PIL import Image
        from src.config.inference_config import InferenceConfig
        from src.config.crop_config import CropConfig
        from src.live_portrait_wrapper import LivePortraitWrapper
        from src.utils.cropper import Cropper
        from src.utils.camera import get_rotation_matrix
        from src.utils.crop import prepare_paste_back, paste_back
        from src.utils.io import load_image_rgb, resize_to_limit
        if not torch.cuda.is_available():
            raise RuntimeError('This GPU latency demo requires CUDA; no CPU fallback')
        torch.set_num_threads(8)
        self.cv2, self.np, self.torch, self.Image = cv2, np, torch, Image
        self.rotation, self.paste_back = get_rotation_matrix, paste_back
        self.wrapper = LivePortraitWrapper(InferenceConfig())
        self.cropper = Cropper(crop_cfg=CropConfig())
        self.driving_crop = CropConfig(scale=2.2, vy_ratio=-0.1)
        self.source = resize_to_limit(load_image_rgb(str(source)), 960, 2)
        crop = self.cropper.crop_source_image(self.source, CropConfig())
        if crop is None:
            raise RuntimeError('Source face not found')
        self.matrix = crop['M_c2o']
        self.mask = prepare_paste_back(self.wrapper.inference_cfg.mask_crop, self.matrix,
                                      dsize=(self.source.shape[1], self.source.shape[0]))
        tensor = self.wrapper.prepare_source(crop['img_crop_256x256'])
        self.info = self.wrapper.get_kp_info(tensor)
        self.source_rotation = self.rotation(self.info['pitch'], self.info['yaw'], self.info['roll'])
        self.feature = self.wrapper.extract_feature_3d(tensor)
        self.keypoints = self.wrapper.transform_keypoint(self.info)
        self.lip_delta = None
        lip_ratio = self.wrapper.calc_combined_lip_ratio([0.], crop['lmk_crop'])
        if lip_ratio[0][0] >= self.wrapper.inference_cfg.lip_normalize_threshold:
            self.lip_delta = self.wrapper.retarget_lip(self.keypoints, lip_ratio)
        self.first = None

    def reset(self):
        self.first = None

    def render(self, data):
        # Check encoded dimensions before allocating the decoded image.
        with self.Image.open(io.BytesIO(data)) as image:
            if image.format != 'JPEG' or max(image.size) > 1280 or min(image.size) < 64:
                raise ValueError('Expected JPEG with dimensions between 64 and 1280')
        cv2, np, torch = self.cv2, self.np, self.torch
        bgr = cv2.imdecode(np.frombuffer(data, dtype=np.uint8), cv2.IMREAD_COLOR)
        if bgr is None:
            raise ValueError('Invalid JPEG')
        rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
        torch.cuda.synchronize()
        started = time.perf_counter()
        crop = self.cropper.crop_source_image(rgb, self.driving_crop)
        if crop is None:
            raise ValueError('No face detected; face the camera')
        info = self.wrapper.get_kp_info(self.wrapper.prepare_source(crop['img_crop_256x256']))
        rotation = self.rotation(info['pitch'], info['yaw'], info['roll'])
        if self.first is None:
            self.first = (info, rotation)
        first, first_rotation = self.first
        rotation_new = (rotation @ first_rotation.permute(0, 2, 1)) @ self.source_rotation
        expression = self.info['exp'] + info['exp'] - first['exp']
        scale = self.info['scale'] * info['scale'] / first['scale']
        translation = (self.info['t'] + info['t'] - first['t']).clone()
        translation[..., 2].fill_(0)
        target = scale * (self.info['kp'] @ rotation_new + expression) + translation
        target = self.wrapper.stitching(self.keypoints, target)
        if self.lip_delta is not None:
            target = target + self.lip_delta
        result = self.wrapper.warp_decode(self.feature, self.keypoints, target)
        face = self.wrapper.parse_output(result['out'])[0]
        output = self.paste_back(face, self.matrix, self.source, self.mask)
        torch.cuda.synchronize()
        inference_ms = (time.perf_counter() - started) * 1000
        ok, encoded = cv2.imencode('.jpg', cv2.cvtColor(output, cv2.COLOR_RGB2BGR),
                                  [cv2.IMWRITE_JPEG_QUALITY, 80])
        if not ok:
            raise RuntimeError('Output encoding failed')
        return encoded.tobytes(), inference_ms

class DemoServer(ThreadingHTTPServer):
    daemon_threads = True
    def __init__(self, address, engine, sample, allow_camera=False):
        super().__init__(address, Handler)
        self.engine, self.sample = engine, sample
        self.allow_camera = allow_camera
        self.gpu_lock = threading.Lock()

class Handler(BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'
    def setup(self):
        super().setup()
        self.connection.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

    def log_message(self, *_):
        pass  # No request bodies, frames, or access logs.

    def reply(self, status, body=b'', mime='application/json', headers=None):
        self.send_response(status)
        self.send_header('Content-Type', mime)
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        for key, value in (headers or {}).items():
            self.send_header(key, str(value))
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def do_GET(self):
        if self.path == '/':
            self.reply(200, Path(__file__).with_name('index.html').read_bytes(), 'text/html; charset=utf-8')
        elif self.path == '/health':
            self.reply(200, json.dumps({'ready': True, 'allow_camera': self.server.allow_camera,
                                       'input_storage': 'none', 'source': 'Mina'}).encode())
        elif self.path == '/sample.mp4':
            self.reply(200, self.server.sample.read_bytes(), 'video/mp4')
        else:
            self.reply(404, b'{"error":"not found"}')

    def do_POST(self):
        start = time.perf_counter()
        origin = self.headers.get('Origin')
        if origin and origin not in {'http://127.0.0.1:18765', 'http://localhost:18765'}:
            self.close_connection = True
            return self.reply(403, b'{"error":"origin denied"}')
        if self.headers.get('Transfer-Encoding'):
            self.close_connection = True
            return self.reply(400, b'{"error":"chunked input unsupported"}')
        try:
            length = int(self.headers.get('Content-Length', '-1'))
        except ValueError:
            length = -1
        if not 0 <= length <= MAX_BODY:
            self.close_connection = True
            return self.reply(413, b'{"error":"invalid body size"}')
        self.connection.settimeout(10)
        try:
            data = self.rfile.read(length)
        except (TimeoutError, OSError):
            self.close_connection = True
            return
        if len(data) != length:
            self.close_connection = True
            return self.reply(400, b'{"error":"incomplete body"}')
        if self.path not in {'/frame', '/echo', '/reset'}:
            return self.reply(404, b'{"error":"not found"}')
        if self.headers.get('Content-Type') != 'application/octet-stream':
            return self.reply(415, b'{"error":"expected binary frame"}')
        if self.path == '/echo':
            return self.reply(200, data, 'application/octet-stream')
        if not self.server.gpu_lock.acquire(blocking=False):
            return self.reply(429, b'{"error":"busy; drop frame"}')
        try:
            if self.path == '/reset':
                self.server.engine.reset()
                return self.reply(200, b'{"reset":true}')
            output, inference_ms = self.server.engine.render(data)
            server_ms = (time.perf_counter() - start) * 1000
            self.reply(200, output, 'image/jpeg', {'X-Inference-Ms': f'{inference_ms:.3f}',
                       'X-Server-Ms': f'{server_ms:.3f}'})
        except (ValueError, OSError):
            self.reply(422, b'{"error":"invalid image or no face"}')
        except Exception:
            self.reply(500, b'{"error":"inference failed"}')
        finally:
            self.server.gpu_lock.release()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--upstream', type=Path, required=True)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--sample', type=Path, required=True)
    parser.add_argument('--allow-camera', action='store_true')
    args = parser.parse_args()
    engine = PortraitEngine(args.upstream.resolve(), args.source.resolve())
    server = DemoServer(('127.0.0.1', 8765), engine, args.sample.resolve(), args.allow_camera)
    print('READY 127.0.0.1:8765; frames are not saved', flush=True)
    server.serve_forever()
