from flask import Flask, jsonify
import requests

app = Flask(__name__)

def reverse_string(string):
    rev = ""
    for i in string:
        rev = i + rev
    return rev

@app.route('/application2/reverse-msg-response', methods=['GET'])
def reverse_message():
    response = requests.get('http://application1:5000/application1/msg-response')
    data = response.json()
    data["message"] = reverse_string(data["message"])
    return jsonify(data)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
