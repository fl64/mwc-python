from flask import Flask, request, jsonify
import jsonpatch
import copy
import base64
import re
import logging
import http

def create_app():
    app = Flask(__name__)
    app.logger.setLevel(logging.DEBUG)

    @app.route('/mutate', methods=['POST'])
    def mutate():
        request_data = request.json
        app.logger.debug(request_data)
        request_data_object = request_data["request"]["object"]
        new_data = copy.deepcopy(request_data)
        new_data_object = new_data["request"]["object"]
        if new_data_object["metadata"].get("annotations") is not None:
            for k, v in new_data_object["metadata"]["annotations"].items():
                if new_data_object["metadata"].get("labels") is None:
                    new_data_object["metadata"]["labels"] = {}
                k = re.sub(r'[^a-z0-9]', '-', k).strip("-")
                v = re.sub(r'[^a-z0-9]', '-', v).strip("-")
                new_data_object["metadata"]["labels"][k] = v
        patch = jsonpatch.JsonPatch.from_diff(
            request_data_object, new_data_object
        )
        app.logger.debug(f"Patch: {patch}")
        admissionReview = {
            "apiVersion": "admission.k8s.io/v1",
            "kind": "AdmissionReview",
            "response": {
                "allowed": True,
                "uid": request_data["request"]["uid"],
                "patch": base64.b64encode(str(patch).encode()).decode(),
                "patchType": "JSONPatch"
            }
        }
        return jsonify(admissionReview)

    @app.route("/health", methods=["GET"])
    def health():
        return ("", http.HTTPStatus.OK)

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(host='0.0.0.0', debug=False, ssl_context=(
        '/tls/tls.crt', '/tls/tls.key'))
