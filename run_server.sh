#!/bin/bash

# Default values
PYTHON=${PYTHON:-"python3"}
HOST=${HOST:-"0.0.0.0"}
PORT=${PORT:-5000}
WORKERS=${WORKERS:-3}
IMAGES_DIR=${IMAGES_DIR:-"images"}
ALLOW_UPLOAD=${ALLOW_UPLOAD:-""}
USE_SSL=${USE_SSL:-""}
CERT_FILE=${CERT_FILE:-"certs/server.crt"}
KEY_FILE=${KEY_FILE:-"certs/server.key"}

# Construct flags
UPLOAD_FLAG=""
if [ ! -z "$ALLOW_UPLOAD" ]; then
    UPLOAD_FLAG="--allow-upload"
fi

SSL_FLAGS=""
if [ ! -z "$USE_SSL" ]; then
    SSL_FLAGS="--keyfile=${KEY_FILE} --certfile=${CERT_FILE}"
fi

# Convert empty ALLOW_UPLOAD to False, non-empty to True for Python
ALLOW_UPLOAD_VALUE="False"
if [ ! -z "$ALLOW_UPLOAD" ]; then
    ALLOW_UPLOAD_VALUE="True"
fi

# Run with Gunicorn
exec ${PYTHON} -m gunicorn \
    --bind ${HOST}:${PORT} \
    --workers ${WORKERS} \
    ${SSL_FLAGS} \
    "muza_cover_art_server:create_app(allow_upload=${ALLOW_UPLOAD_VALUE}, images_dir='${IMAGES_DIR}')"
