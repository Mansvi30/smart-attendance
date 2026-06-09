#!/usr/bin/env bash
set -e
source .venv/bin/activate || true
python3 src/recognize_and_attend.py --encodings data/encodings.pickle --output data/attendance.csv