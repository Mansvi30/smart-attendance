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