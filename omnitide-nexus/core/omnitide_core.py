from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def core_system():
    return "Omnitide Core is running!", 200

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 8080))
    app.run(host='0.0.0.0', port=port)