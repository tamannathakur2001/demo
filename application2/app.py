from flask import Flask, jsonify
import requests
import os

app = Flask(__name__)

minikube_ip = os.getenv('MINIKUBE_IP')
app1_nodeport = os.getenv('APP1_NODEPORT')

app1_url = f"http://{minikube_ip}:{app1_nodeport}/application1/msg-response"

def reverse_string(string):
    rev = ""
    for i in string:
        rev = i + rev
    return rev

@app.route('/application2/reverse-msg-response', methods=['GET'])
def reverse_message():
    try:
        response = requests.get(app1_url)

        if response.status_code == 200:
            data = response.json()
            data["message"] = reverse_string(data["message"])
            return jsonify(data)
        else:
            return f"App1 returned an error: HTTP {response.status_code}", response.status_code
    except requests.RequestException as e:
        return f"Error: {str(e)}", 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
