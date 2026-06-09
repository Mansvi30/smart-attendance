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