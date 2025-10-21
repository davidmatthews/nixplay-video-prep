#!/bin/bash
# Encode videos for Nixplay photo frames using FFmpeg + x265
# Converts all videos in a folder (or a single file) to 720p HEVC.
# Output is saved in the same folder with "-nixplay-720p.mp4" appended.

# Usage:
#   ./encode_nixplay.sh /path/to/video.mp4
#   ./encode_nixplay.sh /path/to/folder
# Example:
#   ./encode_nixplay.sh ~/videos

# Default bitrate (kbps)
BITRATE=2000

# --- Helper function: encode a single file ---
encode_file() {
    local INPUT="$1"

    # Skip if already encoded
    if [[ "$INPUT" == *"-nixplay-720p.mp4" ]]; then
        echo "⏭️  Skipping already encoded file: $INPUT"
        return
    fi

    local DIRNAME="$(dirname "$INPUT")"
    local BASENAME="$(basename "$INPUT")"
    local NAME="${BASENAME%.*}"
    local OUTPUT="${DIRNAME}/${NAME}-nixplay-720p.mp4"

    echo "---------------------------------------------"
    echo "Encoding: $INPUT"
    echo "Output:   $OUTPUT"
    echo "Bitrate:  ${BITRATE}k"
    echo "---------------------------------------------"

    # Detect orientation
    WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$INPUT")
    HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$INPUT")

    if [ "$WIDTH" -ge "$HEIGHT" ]; then
        SCALE="scale=-2:720"
    else
        SCALE="scale=720:-2"
    fi

    ffmpeg -y -i "$INPUT" \
      -vf "$SCALE" \
      -c:v libx265 -b:v ${BITRATE}k -tag:v hvc1 \
      -c:a aac -b:a 128k -ac 2 \
      -movflags +faststart \
      -pix_fmt yuv420p \
      "$OUTPUT"

    echo "✅ Done: $OUTPUT"
}

# --- Main ---
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 /path/to/video_or_folder"
    exit 1
fi

TARGET="$1"

if [ -d "$TARGET" ]; then
    echo "📁 Processing folder: $TARGET"

    FILES=()
    while IFS= read -r -d '' FILE; do
        FILES+=("$FILE")
    done < <(find "$TARGET" -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.m4v" \) -print0)

    for FILE in "${FILES[@]}"; do
        encode_file "$FILE"
    done

elif [ -f "$TARGET" ]; then
    encode_file "$TARGET"
else
    echo "❌ Error: $TARGET is not a valid file or folder"
    exit 1
fi

echo "🎉 All done!"