from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello, This is nikhil Lohar! Task 2 - 100925168"

@app.route('/health-check')
def health_check():
    return "This is a health check"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
