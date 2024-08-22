from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/application1/msg-response', methods=['GET'])
def get_message():
    data = {"id": "1", "message": "Hello world"}
    return jsonify(data)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
