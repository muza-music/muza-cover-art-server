import logging
import os
import argparse
from flask import Flask, request, send_file, jsonify, abort
from werkzeug.utils import secure_filename

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def create_app(allow_upload=False, images_dir="images"):
    """
    Factory function to create and configure the Flask app.
    """
    logger.info("Creating Flask app with allow_upload=%s, images_dir=%s", allow_upload, images_dir)
    app = Flask(__name__)

    # Ensure the images directory exists
    os.makedirs(images_dir, exist_ok=True)
    logger.info("Ensuring images directory exists: %s", images_dir)

    @app.errorhandler(404)
    def not_found_error(error):
        logger.warning("Resource not found")
        return jsonify({"error": "Not found"}), 404

    @app.errorhandler(403)
    def forbidden_error(error):
        logger.warning("Forbidden access attempt")
        return jsonify({"error": "Forbidden"}), 403

    @app.errorhandler(400)
    def bad_request_error(error):
        logger.warning("Bad request: %s", str(error.description))
        return jsonify({"error": str(error.description)}), 400

    @app.route("/cover-art/<path:image_path>", methods=["GET"])
    def get_cover_art(image_path):
        """
        Serve the requested image from the images_dir folder.
        """
        logger.info("Request for image: %s", image_path)
        safe_path = os.path.normpath(os.path.abspath(os.path.join(images_dir, image_path)))

        # Prevent path traversal outside images_dir
        if not safe_path.startswith(os.path.abspath(images_dir)):
            logger.warning("Path traversal attempt detected for path: %s", image_path)
            abort(403)

        if not os.path.isfile(safe_path):
            logger.warning("Image not found: %s", safe_path)
            abort(404)

        logger.debug("Serving image: %s", safe_path)
        return send_file(safe_path)

    if allow_upload:
        @app.route("/cover-art", methods=["POST"])
        def upload_cover_art():
            """
            Upload/Update cover-art images.
            The client should send the file using form-data with the key 'file'.
            """
            logger.info("Received file upload request")
            
            if 'file' not in request.files:
                logger.warning("File upload attempt with no file part")
                abort(400, description="No file part in request")

            file = request.files['file']
            if file.filename == '':
                logger.warning("File upload attempt with empty filename")
                abort(400, description="No selected file")

            filename = secure_filename(file.filename)
            file_path = os.path.join(images_dir, filename)
            logger.info("Saving uploaded file: %s", file_path)
            file.save(file_path)

            return jsonify({
                "message": "File uploaded successfully",
                "filename": filename
            }), 200

    return app


if __name__ == "__main__":
    # Parse CLI arguments
    parser = argparse.ArgumentParser(description="Muza Cover Art Server")
    parser.add_argument(
        "--allow-upload",
        action="store_true",
        help="Enable the upload (POST) endpoint for cover art"
    )
    parser.add_argument(
        "--host",
        default="0.0.0.0",
        help="Host interface to bind to (default: 0.0.0.0)"
    )
    parser.add_argument(
        "--port",
        type=int,
        default=5000,
        help="Port to run the server on (default: 5000)"
    )
    parser.add_argument(
        "--images-dir",
        default="images",
        help="Directory to store/serve images (default: 'images')"
    )
    parser.add_argument(
        "--cert-file",
        default="certs/server.crt",
        help="Path to SSL certificate file (default: certs/server.crt)"
    )
    parser.add_argument(
        "--key-file",
        default="certs/server.key",
        help="Path to SSL private key file (default: certs/server.key)"
    )
    parser.add_argument(
        "--use-ssl",
        action="store_true",
        help="Enable SSL/TLS support"
    )
    args = parser.parse_args()

    logger.info("Starting Muza Cover Art Server")
    logger.info("Upload endpoint enabled: %s", args.allow_upload)
    logger.info("Images directory: %s", args.images_dir)
    
    # Create the Flask application with/without upload route
    app = create_app(
        allow_upload=args.allow_upload,
        images_dir=args.images_dir
    )

    ssl_context = None
    if args.use_ssl:
        if not os.path.exists(args.cert_file) or not os.path.exists(args.key_file):
            logger.error("Certificate files not found. Generate them using 'make certs'")
            exit(1)
        ssl_context = (args.cert_file, args.key_file)
        logger.info("SSL enabled with cert: %s, key: %s", args.cert_file, args.key_file)

    logger.info("Server starting on %s:%d", args.host, args.port)
    app.run(host=args.host, port=args.port, ssl_context=ssl_context)
