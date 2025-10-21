#!/bin/bash
# Encode videos for Nixplay photo frames using FFmpeg
# Automatically outputs as "<original>-nixplay-720p.mp4" in the same folder
# Usage: ./encode_nixplay.sh input.mp4 [bitrate]

# Check arguments
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 input.mp4 [bitrate]"
    echo "Example: $0 vacation.mov 2000"
    exit 1
fi

INPUT="$1"
BITRATE="${2:-2000}" # Default to 2000 kbps

# Derive file path components
DIRNAME="$(dirname "$INPUT")"
BASENAME="$(basename "$INPUT")"
NAME="${BASENAME%.*}"
OUTPUT="${DIRNAME}/${NAME}-nixplay-720p.mp4"

# Detect orientation using ffprobe
WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$INPUT")
HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$INPUT")

if [ "$WIDTH" -ge "$HEIGHT" ]; then
    # Landscape: limit height to 720p
    SCALE="scale=-2:720"
else
    # Portrait: limit width to 720p
    SCALE="scale=720:-2"
fi

echo "---------------------------------------------"
echo "Encoding: $INPUT"
echo "Output:   $OUTPUT"
echo "Bitrate:  ${BITRATE}k"
echo "Scaling:  $SCALE"
echo "---------------------------------------------"

ffmpeg -i "$INPUT" \
  -vf "$SCALE" \
  -c:v libx265 -b:v ${BITRATE}k -tag:v hvc1 \
  -c:a aac -b:a 128k -ac 2 \
  -movflags +faststart \
  -pix_fmt yuv420p \
  "$OUTPUT"

echo "✅ Done: $OUTPUT"