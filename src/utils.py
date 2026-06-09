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