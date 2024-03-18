import os
from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def home():
    foo_value = os.environ.get("FOO", "Value not set")
    return jsonify({
        "FOO": foo_value
    })

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=8080)