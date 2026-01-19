#!/bin/sh
# High-quality GIF encoder using 2-pass palettegen approach
# Based on: https://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html

palette="/tmp/palette.png"
filters="fps=15,scale=1000:-1:flags=lanczos"

echo "Pass 1: Generating palette..."
ffmpeg -v warning -i "$1" -vf "$filters,palettegen=stats_mode=diff" -update 1 -frames:v 1 -y "$palette"

echo "Pass 2: Creating GIF..."
ffmpeg -v warning -i "$1" -i "$palette" -lavfi "$filters [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" -y "$2"

echo "Done! GIF saved to: $2"
ls -lh "$2"
