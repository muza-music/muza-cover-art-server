# Muza Cover Art Server

A lightweight server for serving and optionally uploading cover art images.

## Features

- Secure image serving with path traversal protection
- Optional upload endpoint
- SSL/TLS support
- Podman container support

## Installation and Running (Local)

1. Clone the repository:
```bash
git clone https://github.com/yaacov/muza-cover-art-server.git
cd muza-cover-art-server
```

2. Create a virtual environment and install dependencies:
```bash
# Set up venv
make all
# Activate venv
source venv/bin/activate
```

### Running the Server

#### Production Mode

```bash
# Run with Gunicorn
./run_server.sh
```

Environment variables for configuration:
- `HOST`: Binding address (default: 0.0.0.0)
- `PORT`: Server port (default: 5000)
- `WORKERS`: Number of Gunicorn workers (default: 3)
- `IMAGES_DIR`: Directory for images (default: images)
- `ALLOW_UPLOAD`: Enable upload endpoint if set
- `USE_SSL`: Enable SSL/TLS if set
- `CERT_FILE`: Path to SSL certificate (default: certs/server.crt)
- `KEY_FILE`: Path to SSL key (default: certs/server.key)

#### Development Mode

```bash
# Run with Flask development server
make run-dev
```

### Local Development Options

1. Basic server (readonly):
```bash
make run
```

2. Enable upload capability:
```bash
make run-with-upload
```

3. Run with SSL:
```bash
# First generate certificates
make certs

# Then run with SSL
make run-ssl
# or with uploads enabled
make run-with-upload-ssl
```

## Usage Examples

### Retrieving Images

```bash
# Get an image
curl http://localhost:5000/cover-art/album1.jpg

# Using SSL
curl https://localhost:5000/cover-art/album1.jpg --cacert certs/server.crt
```

### Uploading Images (when enabled)

```bash
# Upload an image
curl -X POST -F "file=@/path/to/local/image.jpg" http://localhost:5000/cover-art

# Upload with SSL
curl -X POST -F "file=@/path/to/local/image.jpg" \
  https://localhost:5000/cover-art \
  --cacert certs/server.crt
```

## Container Support

### Building and Running with Containers

1. Build the container:
```bash
make container-build
# or
podman build -t quay.io/yaacov/muza-cover-art-server:latest -f Containerfile .
```

2. Basic readonly server:
```bash
podman run -p 5000:5000 -v ./images:/app/images:Z quay.io/yaacov/muza-cover-art-server:latest
```

3. With upload enabled:
```bash
podman run -p 5000:5000 \
    -v ./images:/app/images:Z \
    -e ALLOW_UPLOAD=1 \
    quay.io/yaacov/muza-cover-art-server:latest
```

4. With SSL (after generating certificates):
```bash
podman run -p 5000:5000 \
    -v ./images:/app/images:Z \
    -v ./certs:/app/certs:Z \
    -e USE_SSL=true \
    quay.io/yaacov/muza-cover-art-server:latest
```

### Running Containerized with Environment Variables

```bash
podman run -p 5000:5000 \
  -v ./images:/app/images:Z \
  -v ./certs:/app/certs:Z \
  -e USE_SSL=true \
  -e CERT_FILE=certs/server.crt \
  -e KEY_FILE=certs/server.key \
  quay.io/yaacov/muza-cover-art-server:latest
```

## Command Line Options

```bash
usage: muza_cover_art_server.py [-h] [--allow-upload] [--host HOST]
                                [--port PORT] [--images-dir IMAGES_DIR]
                                [--cert-file CERT_FILE] [--key-file KEY_FILE]
                                [--use-ssl]

Options:
  --allow-upload     Enable image upload endpoint
  --host HOST        Host interface (default: 0.0.0.0)
  --port PORT        Port number (default: 5000)
  --images-dir DIR   Images directory (default: images)
  --cert-file FILE   SSL certificate path (default: certs/server.crt)
  --key-file FILE    SSL key path (default: certs/server.key)
  --use-ssl          Enable SSL/TLS support
```
