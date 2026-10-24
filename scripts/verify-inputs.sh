#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 MINA_SOURCE_PNG NORMALIZED_DRIVING_MP4" >&2
  exit 2
fi

source_image=$1
driving_video=$2

command -v ffprobe >/dev/null || { echo "ffprobe is required" >&2; exit 1; }
[[ -s "$source_image" ]] || { echo "missing source image: $source_image" >&2; exit 1; }
[[ -s "$driving_video" ]] || { echo "missing driving video: $driving_video" >&2; exit 1; }

image_codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$source_image")
video_codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$driving_video")
fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=nw=1:nk=1 "$driving_video")
audio_streams=$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$driving_video" | wc -l | tr -d ' ')

[[ "$image_codec" == "png" ]] || { echo "expected PNG source, got $image_codec" >&2; exit 1; }
[[ "$video_codec" == "h264" ]] || { echo "expected H.264 driving video, got $video_codec" >&2; exit 1; }
[[ "$fps" == "25/1" ]] || { echo "expected 25 fps, got $fps" >&2; exit 1; }
[[ "$audio_streams" == "0" ]] || { echo "driving video must not contain audio" >&2; exit 1; }

echo "inputs verified: png source, h264 driving video, 25 fps, no audio"
