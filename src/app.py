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