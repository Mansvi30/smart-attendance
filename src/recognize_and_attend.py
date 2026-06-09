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