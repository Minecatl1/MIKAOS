import os
import subprocess
from flask import Flask, render_template, request, Response, send_file

app = Flask(__name__)

OS_OPTIONS = ["MikaOS", "ChromeOS Flex", "Ubuntu", "Debian", "Arch Linux"]
APP_OPTIONS = ["Spotify", "Discord", "VLC", "Steam", "Minecraft"]
ISO_PATH = "output/mikaos.iso"

# Function to stream terminal logs
def generate_terminal_output():
    process = subprocess.Popen(["make", "all"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    for line in iter(process.stdout.readline, ""):
        yield f"data: {line}\n\n"
    process.stdout.close()
    process.wait()
    yield "data: ISO Build Completed! [Download ISO](http://localhost:5000/download)\n\n"

@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        selected_os = request.form.getlist("os")
        selected_apps = request.form.getlist("apps")

        with open("iso_config.txt", "w") as f:
            f.write(f"OS Choices: {', '.join(selected_os)}\n")
            f.write(f"Apps: {', '.join(selected_apps)}\n")

        return "Build Started! Check the terminal below."

    return render_template("index.html", os_options=OS_OPTIONS, app_options=APP_OPTIONS)

@app.route("/terminal-stream")
def terminal_stream():
    return Response(generate_terminal_output(), mimetype="text/event-stream")

@app.route("/download")
def download_iso():
    return send_file(ISO_PATH, as_attachment=True)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
