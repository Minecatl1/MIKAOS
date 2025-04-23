from flask import Flask, render_template, request
import os

app = Flask(__name__)

OS_OPTIONS = ["MikaOS", "ChromeOS Flex", "Ubuntu", "Debian", "Arch Linux"]
APP_OPTIONS = ["Spotify", "Discord", "VLC", "Steam", "Minecraft"]

@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        selected_os = request.form.getlist("os")
        selected_apps = request.form.getlist("apps")
        
        # Save selections to config file
        with open("iso_config.txt", "w") as f:
            f.write(f"OS Choices: {', '.join(selected_os)}\n")
            f.write(f"Apps: {', '.join(selected_apps)}\n")

        # Trigger ISO build
        os.system("make all")

        return "ISO generation started!"

    return render_template("index.html", os_options=OS_OPTIONS, app_options=APP_OPTIONS)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
