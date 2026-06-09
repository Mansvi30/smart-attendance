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