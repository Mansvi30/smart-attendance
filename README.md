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