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