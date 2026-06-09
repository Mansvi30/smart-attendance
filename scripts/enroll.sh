#!/usr/bin/env bash
set -e
NAME="$1"
OUT_DIR="data/dataset"

if [ -z "$NAME" ]; then
  echo "Usage: $0 \"Person Name\""
  exit 1
fi

mkdir -p "$OUT_DIR/$NAME"
python3 src/capture_dataset.py --output "$OUT_DIR/$NAME" --num 20
echo "Captured dataset for $NAME in $OUT_DIR/$NAME"