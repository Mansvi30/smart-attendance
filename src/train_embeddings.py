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