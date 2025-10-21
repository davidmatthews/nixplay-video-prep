#!/bin/bash
# Encode videos for Nixplay photo frames using FFmpeg
# Usage: ./nixplay-encode.sh input.mp4 output.mp4 [bitrate in kbps]

# Check arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 input.mp4 output.mp4 [bitrate]"
    echo "Example: $0 vacation.mov vacation_nixplay.mp4 2000"
    exit 1
fi

INPUT="$1"
OUTPUT="$2"
BITRATE="${3:-2000}" # Default to 2000 kbps if not provided

# Detect orientation (portrait vs landscape)
WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$INPUT")
HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$INPUT")

if [ "$WIDTH" -ge "$HEIGHT" ]; then
    # Landscape: limit height to 720p
    SCALE="scale=-2:720"
else
    # Portrait: limit width to 720p
    SCALE="scale=720:-2"
fi

echo "Encoding $INPUT -> $OUTPUT"
echo "Bitrate: ${BITRATE}k | Scale: $SCALE"

ffmpeg -i "$INPUT" \
  -vf "$SCALE" \
  -c:v libx265 -b:v ${BITRATE}k -tag:v hvc1 \
  -c:a aac -b:a 128k -ac 2 \
  -movflags +faststart \
  -pix_fmt yuv420p \
  "$OUTPUT"

echo "✅ Done: $OUTPUT"