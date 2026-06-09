#!/usr/bin/env bash
# create_archive.sh
# Creates the smart-attendance project files and produces smart-attendance.zip and smart-attendance.tar.gz
# Usage:
# 1. Save this script: wget -O create_archive.sh 'PASTE_THIS_SCRIPT'  OR create file and paste contents
# 2. Make executable: chmod +x create_archive.sh
# 3. Run in an empty directory: ./create_archive.sh
#
# After running you'll have:
#  - ./smart-attendance/  (project tree)
#  - ./smart-attendance.zip
#  - ./smart-attendance.tar.gz
set -euo pipefail

ROOT="smart-attendance"
rm -rf "$ROOT"
mkdir -p "$ROOT"

# Helper to write files
write() {
  local path="$ROOT/$1"
  mkdir -p "$(dirname "$path")"
  cat > "$path"
  echo "Wrote $path"
}

# README.md
write "README.md" <<'EOF'
# Smart Attendance

Raspberry Pi-based face-recognition attendance system. Uses a TFLite face-embedding model when available and falls back to dlib/face_recognition if not. Minimal starter project to capture datasets, train embeddings, and run recognition/attendance logging.

Features
- Capture face dataset from Pi Camera / USB webcam
- Train embeddings (stores a pickle of known encodings)
- Recognition pipeline using TFLite or dlib fallback
- Attendance logging to CSV with timestamps
- Optional Flask app to view attendance

Quick start (on your Pi)
1. Clone the repo: git clone https://github.com/Mansvi30/smart-attendance.git
2. Make scripts executable: chmod +x scripts/*.sh
3. Run setup:
   - sudo ./scripts/setup_pi.sh
   - ./scripts/setup_dlib.sh (only if you need dlib)
4. Enroll a user: ./scripts/enroll.sh "Person Name"
5. Train embeddings:
   python3 src/train_embeddings.py --dataset data/dataset --output data/encodings.pickle
6. Start attendance: ./scripts/run_attendance.sh

See scripts/ for systemd service to run on boot.

Notes
- dlib/face_recognition can be heavy to build on Pi. If you have a Coral USB Accelerator or want faster inference, use a TFLite model and tflite-runtime.
- Tuning thresholds and dataset quality (lighting, angles) is crucial for good recognition.
EOF

# LICENSE
write "LICENSE" <<'EOF'
MIT License

Copyright (c) 2026 Mansvi30

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# requirements.txt
write "requirements.txt" <<'EOF'
numpy
opencv-python
Pillow
flask
imutils
# Optional / fallback libraries:
face_recognition
dlib
# If you have a TFLite runtime on your Pi, install it instead of full TF:
# tflite-runtime
EOF

# scripts/setup_pi.sh
write "scripts/setup_pi.sh" <<'EOF'
#!/usr/bin/env bash
set -e

echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

echo "Installing system dependencies..."
sudo apt-get install -y build-essential cmake libatlas-base-dev libjpeg-dev libtiff5-dev libjasper-dev libpng-dev \
    libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libxvidcore-dev libx264-dev \
    libgtk2.0-dev pkg-config python3-dev python3-venv

echo "Creating venv..."
python3 -m venv .venv
source .venv/bin/activate

echo "Upgrading pip and installing Python requirements..."
pip install --upgrade pip
pip install -r requirements.txt

echo "Setup complete. Activate the venv: source .venv/bin/activate"
EOF
chmod +x "$ROOT/scripts/setup_pi.sh"

# scripts/setup_dlib.sh
write "scripts/setup_dlib.sh" <<'EOF'
#!/usr/bin/env bash
set -e
echo "Installing system packages needed for building dlib..."
sudo apt-get update
sudo apt-get install -y build-essential cmake python3-dev libopenblas-dev liblapack-dev libx11-dev

echo "Recommended: increase swap space if building on low-memory Pi models."
echo "Now installing dlib via pip (may take a while)..."
source .venv/bin/activate || true
pip install dlib || {
  echo "dlib pip install failed. Consider building from source or use a prebuilt wheel for your platform."
  exit 1
}
echo "dlib installed."
EOF
chmod +x "$ROOT/scripts/setup_dlib.sh"

# scripts/enroll.sh
write "scripts/enroll.sh" <<'EOF'
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
EOF
chmod +x "$ROOT/scripts/enroll.sh"

# scripts/run_attendance.sh
write "scripts/run_attendance.sh" <<'EOF'
#!/usr/bin/env bash
set -e
source .venv/bin/activate || true
python3 src/recognize_and_attend.py --encodings data/encodings.pickle --output data/attendance.csv
EOF
chmod +x "$ROOT/scripts/run_attendance.sh"

# systemd service
write "systemd/raspi-attendance.service" <<'EOF'
[Unit]
Description=Raspi Smart Attendance
After=network.target

[Service]
# Adjust WorkingDirectory to where you clone the repo on your Pi
WorkingDirectory=/home/pi/smart-attendance
ExecStart=/home/pi/smart-attendance/scripts/run_attendance.sh
User=pi
Restart=always
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# src/utils.py
write "src/utils.py" <<'EOF'
#!/usr/bin/env python3
import os
import cv2
import numpy as np
from datetime import datetime
import pickle

CASCADE_PATH = cv2.data.haarcascades + "haarcascade_frontalface_default.xml"

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

def load_image(path):
    return cv2.imread(path)

def detect_faces_cv(image, scaleFactor=1.1, minNeighbors=5):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    detector = cv2.CascadeClassifier(CASCADE_PATH)
    rects = detector.detectMultiScale(gray, scaleFactor=scaleFactor, minNeighbors=minNeighbors)
    faces = []
    for (x, y, w, h) in rects:
        faces.append((x, y, x+w, y+h))
    return faces

def save_encodings(encodings, path):
    with open(path, "wb") as f:
        pickle.dump(encodings, f)

def load_encodings(path):
    if not os.path.exists(path):
        return {}
    with open(path, "rb") as f:
        return pickle.load(f)

def mark_attendance(name, csv_path):
    ensure_dir(os.path.dirname(csv_path) or ".")
    ts = datetime.utcnow().isoformat()
    line = f"{name},{ts}\n"
    with open(csv_path, "a") as f:
        f.write(line)
EOF

# src/capture_dataset.py
write "src/capture_dataset.py" <<'EOF'
#!/usr/bin/env python3
"""
Capture images from webcam and save face crops into output directory.
"""
import argparse
import cv2
import os
from src.utils import detect_faces_cv, ensure_dir

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--output", required=True, help="Output dir for images")
    ap.add_argument("--num", type=int, default=20, help="Number of face samples to capture")
    ap.add_argument("--camera", type=int, default=0, help="Camera index")
    args = ap.parse_args()

    ensure_dir(args.output)
    cap = cv2.VideoCapture(args.camera)
    count = 0
    print("Press 'q' to quit early.")
    while count < args.num:
        ret, frame = cap.read()
        if not ret:
            continue
        faces = detect_faces_cv(frame)
        for (x1, y1, x2, y2) in faces:
            face = frame[y1:y2, x1:x2]
            path = os.path.join(args.output, f"{count:03d}.jpg")
            cv2.imwrite(path, face)
            count += 1
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0,255,0), 2)
            print(f"Captured {path}")
            if count >= args.num:
                break
        cv2.imshow("Capture", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
EOF
chmod +x "$ROOT/src/capture_dataset.py"

# src/tflite_pipeline.py
write "src/tflite_pipeline.py" <<'EOF'
#!/usr/bin/env python3
"""
Simple TFLite embedder wrapper with fallback to face_recognition.
"""
import numpy as np

class TFLiteFaceEmbedder:
    def __init__(self, model_path=None):
        self.model_path = model_path
        self.interpreter = None
        if model_path:
            try:
                import tflite_runtime.interpreter as tflite
            except Exception:
                try:
                    from tensorflow.lite.python.interpreter import Interpreter as tflite
                except Exception:
                    tflite = None
            if tflite:
                try:
                    self.interpreter = tflite.Interpreter(model_path=model_path)
                    self.interpreter.allocate_tensors()
                    self.input_details = self.interpreter.get_input_details()
                    self.output_details = self.interpreter.get_output_details()
                except Exception:
                    self.interpreter = None

    def embed(self, face_image):
        """
        face_image: RGB numpy array of shape (h,w,3)
        returns 1D numpy embedding
        """
        if self.interpreter:
            inp = face_image.astype('float32')
            # resize to interpreter input if needed
            h, w = self.input_details[0]['shape'][1:3]
            import cv2
            inp_resized = cv2.resize(inp, (w, h))
            inp_resized = np.expand_dims(inp_resized, axis=0)
            self.interpreter.set_tensor(self.input_details[0]['index'], inp_resized)
            self.interpreter.invoke()
            out = self.interpreter.get_tensor(self.output_details[0]['index'])
            return out.flatten()
        else:
            # fallback to face_recognition
            try:
                import face_recognition
                enc = face_recognition.face_encodings(face_image)
                if enc:
                    return np.array(enc[0])
            except Exception:
                pass
        return None
EOF

# src/train_embeddings.py
write "src/train_embeddings.py" <<'EOF'
#!/usr/bin/env python3
"""
Build embeddings from dataset directory. Expects each subfolder to be a person name.
Saves encodings to a pickle file.
"""
import os
import argparse
import cv2
import numpy as np
from src.utils import save_encodings, ensure_dir
from src.tflite_pipeline import TFLiteFaceEmbedder

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dataset", required=True, help="Dataset folder (subdirs per person)")
    ap.add_argument("--output", required=True, help="Output encodings pickle path")
    ap.add_argument("--tflite", help="Optional TFLite model path for embeddings")
    args = ap.parse_args()

    embedder = TFLiteFaceEmbedder(args.tflite)

    encodings = {}
    for person in sorted(os.listdir(args.dataset)):
        person_dir = os.path.join(args.dataset, person)
        if not os.path.isdir(person_dir):
            continue
        encodings.setdefault(person, [])
        for fname in sorted(os.listdir(person_dir)):
            path = os.path.join(person_dir, fname)
            img = cv2.imread(path)
            if img is None:
                continue
            rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
            emb = embedder.embed(rgb)
            if emb is not None:
                encodings[person].append(emb.tolist())
                print(f"Encoded {path}")
            else:
                print(f"Warning: could not compute embedding for {path}")

    ensure_dir(os.path.dirname(args.output) or ".")
    save_encodings(encodings, args.output)
    print(f"Saved encodings to {args.output}")

if __name__ == "__main__":
    main()
EOF

# src/recognize_and_attend.py
write "src/recognize_and_attend.py" <<'EOF'
#!/usr/bin/env python3
"""
Recognize faces on a webcam stream and log attendance.
"""
import argparse
import cv2
import numpy as np
from src.utils import load_encodings, detect_faces_cv, mark_attendance
from src.tflite_pipeline import TFLiteFaceEmbedder
import time
import os

def compare_embeddings(known_embs, query, thresh=0.6):
    # known_embs: list of numpy arrays
    dists = [np.linalg.norm(np.array(k) - query) for k in known_embs]
    if not dists:
        return None, None
    idx = int(np.argmin(dists))
    return idx, dists[idx]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--encodings", required=True, help="Path to encodings pickle")
    ap.add_argument("--output", default="data/attendance.csv", help="Attendance CSV")
    ap.add_argument("--tflite", help="Optional tflite model path")
    ap.add_argument("--camera", type=int, default=0)
    args = ap.parse_args()

    encodings = load_encodings(args.encodings)
    # flatten per person
    known = {person: [np.array(e) for e in arr] for person, arr in encodings.items()}

    embedder = TFLiteFaceEmbedder(args.tflite)

    cap = cv2.VideoCapture(args.camera)
    seen = set()

    print("Starting recognition. Press 'q' to quit.")
    while True:
        ret, frame = cap.read()
        if not ret:
            time.sleep(0.1)
            continue
        faces = detect_faces_cv(frame)
        for (x1, y1, x2, y2) in faces:
            face = frame[y1:y2, x1:x2]
            rgb = cv2.cvtColor(face, cv2.COLOR_BGR2RGB)
            emb = embedder.embed(rgb)
            label = "Unknown"
            if emb is not None:
                best_name = None
                best_dist = None
                for person, arr in known.items():
                    idx, dist = compare_embeddings(arr, emb)
                    if idx is None:
                        continue
                    if best_dist is None or dist < best_dist:
                        best_dist = dist
                        best_name = person
                if best_name is not None and best_dist is not None and best_dist < 0.6:
                    label = best_name
                    if best_name not in seen:
                        mark_attendance(best_name, args.output)
                        seen.add(best_name)
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0,255,0), 2)
            cv2.putText(frame, label, (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0,255,0), 2)
        cv2.imshow("Attendance", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
EOF
chmod +x "$ROOT/src/recognize_and_attend.py"

# src/app.py
write "src/app.py" <<'EOF'
#!/usr/bin/env python3
from flask import Flask, send_file, render_template_string
import os

APP = Flask(__name__)

TEMPLATE = """
<!doctype html>
<title>Attendance</title>
<h1>Attendance</h1>
{% if path_exists %}
<a href="/download">Download CSV</a>
<pre>{{csv}}</pre>
{% else %}
<p>No attendance file yet.</p>
{% endif %}
"""

CSV_PATH = "data/attendance.csv"

@APP.route("/")
def index():
    if os.path.exists(CSV_PATH):
        with open(CSV_PATH) as f:
            csv = f.read()
        return render_template_string(TEMPLATE, csv=csv, path_exists=True)
    return render_template_string(TEMPLATE, csv="", path_exists=False)

@APP.route("/download")
def download():
    if os.path.exists(CSV_PATH):
        return send_file(CSV_PATH, as_attachment=True)
    return "No attendance recorded yet", 404

if __name__ == "__main__":
    APP.run(host="0.0.0.0", port=5000)
EOF

# .github/workflows/lint.yml
write ".github/workflows/lint.yml" <<'EOF'
name: Lint

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install flake8
      - name: Run flake8
        run: |
          flake8 .
EOF

# finalize: create archives
cd "$ROOT/.."
ZIPNAME="${ROOT}.zip"
TARNAME="${ROOT}.tar.gz"

# Remove any previous archives
rm -f "$ZIPNAME" "$TARNAME"

echo "Generating zip: $ZIPNAME"
zip -r -q "$ZIPNAME" "$ROOT"
echo "Generating tar.gz: $TARNAME"
tar -czf "$TARNAME" "$ROOT"

# checksum
sha256sum "$ZIPNAME" "$TARNAME" | tee "${ROOT}-checksums.txt"

echo "Done. Files produced:"
ls -lh "$ZIPNAME" "$TARNAME" "${ROOT}-checksums.txt"
echo
echo "To extract:"
echo "  unzip $ZIPNAME"
echo "  tar -xzf $TARNAME"