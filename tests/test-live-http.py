"""HTTP boundary tests with a fake engine; no models, camera, or GPU required."""
import importlib.util
import http.client
from pathlib import Path
import threading
import unittest

spec = importlib.util.spec_from_file_location('portrait_server', Path(__file__).parents[1] / 'live/server.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class Engine:
    calls = 0
    resets = 0
    def reset(self):
        self.resets += 1
    def render(self, data):
        self.calls += 1
        if data == b'invalid':
            raise ValueError('invalid')
        return b'jpeg-result', 12.5

class BoundaryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = Engine()
        cls.server = module.DemoServer(('127.0.0.1', 0), cls.engine, Path(__file__))
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()
    def request(self, path='/frame', body=b'jpeg', headers=None):
        c = http.client.HTTPConnection(*self.server.server_address, timeout=2)
        c.request('POST', path, body=body, headers=headers or {'Content-Type':'application/octet-stream'})
        r=c.getresponse(); result=(r.status, dict(r.getheaders()), r.read()); c.close()
        return result
    def test_frame_success_and_timing(self):
        status,headers,body=self.request()
        self.assertEqual((status,body),(200,b'jpeg-result'))
        self.assertEqual(headers['X-Inference-Ms'],'12.500')
        self.assertEqual(headers['Cache-Control'],'no-store')
    def test_cross_origin_rejected_before_inference(self):
        calls=self.engine.calls
        self.assertEqual(self.request(headers={'Origin':'https://evil.example','Content-Type':'application/octet-stream'})[0],403)
        self.assertEqual(self.engine.calls,calls)
    def test_simple_form_rejected(self):
        self.assertEqual(self.request(headers={'Content-Type':'text/plain'})[0],415)
    def test_oversize_rejected(self):
        self.assertEqual(self.request(body=b'',headers={'Content-Type':'application/octet-stream','Content-Length':str(module.MAX_BODY+1)})[0],413)
    def test_busy_does_not_queue(self):
        self.server.gpu_lock.acquire()
        try:self.assertEqual(self.request()[0],429)
        finally:self.server.gpu_lock.release()
    def test_invalid_frame_releases_lock(self):
        self.assertEqual(self.request(body=b'invalid')[0],422)
        self.assertEqual(self.request()[0],200)
    def test_reset(self):
        count=self.engine.resets
        self.assertEqual(self.request('/reset',b'')[0],200)
        self.assertEqual(self.engine.resets,count+1)
    def test_echo(self):
        self.assertEqual(self.request('/echo',b'payload')[2],b'payload')

if __name__=='__main__':unittest.main()
