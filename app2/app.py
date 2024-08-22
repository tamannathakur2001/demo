from flask import Flask, jsonify
import requests

app = Flask(__name__)

@app.route('/api/reverse-message', methods=['GET'])
def reverse_message():
    response = requests.get('http://app1-service:5000/api/message')
    data = response.json()
    reversed_message = data["message"][::-1]
    return jsonify({"id": data["id"], "message": reversed_message})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
