#!/bin/bash
# Frame-and-motion builder for the Annamayya anime video.
# Usage: ./scripts/build.sh <narration.mp3> <output.mp4>
# Splits the narration evenly across the 4 stage frames, renders each
# frame with a camera move (zoompan), hard-cuts the segments together,
# and muxes the narration in. Output: 1080x1920, 30 fps, H.264 + AAC.
# Requires: ffmpeg, ffprobe. No network, no paid services.
set -e
cd "$(dirname "$0")/.."

NARRATION="${1:?Usage: build.sh <narration.mp3> <output.mp4>}"
OUTPUT="${2:?Usage: build.sh <narration.mp3> <output.mp4>}"

FRAMES=(
  "images/stage1-divine-birth.webp"
  "images/stage2-pilgrimage-hills.webp"
  "images/stage3-temple-singing.webp"
  "images/stage4-jail-miracle.webp"
)
MOTIONS=(zoomin panright zoomin zoomout)

DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$NARRATION")
SEG=$(python3 -c "print(f'{$DUR/4:.4f}')")
F=$(python3 -c "print(int(float('$SEG')*30))")
echo "narration=$NARRATION dur=$DUR seg=$SEG frames=$F"

render() { # $1=image $2=motion $3=out
  local z x y
  case "$2" in
    zoomin)   z="1+0.12*on/$F"; x="(iw-iw/zoom)/2"; y="(ih-ih/zoom)/2";;
    zoomout)  z="1.12-0.12*on/$F"; x="(iw-iw/zoom)/2"; y="(ih-ih/zoom)/2";;
    panright) z="1.12"; x="(iw-iw/zoom)*on/$F"; y="(ih-ih/zoom)/2";;
    panleft)  z="1.12"; x="(iw-iw/zoom)*(1-on/$F)"; y="(ih-ih/zoom)/2";;
  esac
  ffmpeg -y -v error -i "$1" \
    -vf "scale=2160:3840:force_original_aspect_ratio=increase,crop=2160:3840,zoompan=z='$z':x='$x':y='$y':d=$F:s=1080x1920:fps=30" \
    -frames:v "$F" -c:v libx264 -pix_fmt yuv420p "$3"
}

TMPDIR_BUILD=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BUILD"' EXIT

for i in 0 1 2 3; do
  render "${FRAMES[$i]}" "${MOTIONS[$i]}" "$TMPDIR_BUILD/seg$((i+1)).mp4"
  echo "file '$TMPDIR_BUILD/seg$((i+1)).mp4'" >> "$TMPDIR_BUILD/list.txt"
done

ffmpeg -y -v error -f concat -safe 0 -i "$TMPDIR_BUILD/list.txt" -c copy "$TMPDIR_BUILD/base.mp4"
ffmpeg -y -v error -i "$TMPDIR_BUILD/base.mp4" -i "$NARRATION" \
  -map 0:v -map 1:a -c:v copy -c:a aac -t "$DUR" "$OUTPUT"

echo "DONE $OUTPUT"
ffprobe -v error -show_entries format=duration,size -of default=noprint_wrappers=1 "$OUTPUT"
