VENV = venv
PYTHON = $(VENV)/bin/python
PIP = $(VENV)/bin/pip

# Container settings
CONTAINER_REG ?= quay.io
CONTAINER_ORG ?= yaacov
CONTAINER_NAME ?= muza-cover-art-server
CONTAINER_TAG ?= latest
CONTAINER_IMAGE = $(CONTAINER_REG)/$(CONTAINER_ORG)/$(CONTAINER_NAME):$(CONTAINER_TAG)

.PHONY: all clean run venv help certs run-dev container-build container-run container-run-upload container-run-ssl

help:
	@echo "Available targets:"
	@echo "  help           - Show this help message"
	@echo "  all            - Set up virtual environment and install dependencies"
	@echo "  venv           - Create virtual environment and install requirements"
	@echo "  clean          - Remove virtual environment, certificates and Python cache files"
	@echo "  run            - Run the server in normal mode"
	@echo "  run-with-upload- Run the server with upload capability enabled"
	@echo "  certs          - Generate self-signed SSL certificates"
	@echo "  run-ssl        - Run the server with SSL enabled"
	@echo "  run-with-upload-ssl - Run the server with both SSL and upload capability enabled"
	@echo "  run-dev        - Run the server in development mode"
	@echo "  container-build   - Build container image"
	@echo "  container-run     - Run container in normal mode"
	@echo "  container-run-upload - Run container with upload enabled"
	@echo "  container-run-ssl - Run container with SSL enabled"

all: venv

$(VENV)/bin/activate: requirements.txt
	python3 -m venv $(VENV)
	$(PIP) install -r requirements.txt

venv: $(VENV)/bin/activate

clean:
	rm -rf $(VENV)
	rm -rf certs
	find . -type f -name '*.pyc' -delete
	find . -type d -name '__pycache__' -delete

run: venv
	PYTHON=$(PYTHON) ./run_server.sh

run-dev: venv
	$(PYTHON) muza_cover_art_server.py

run-with-upload: venv
	PYTHON=$(PYTHON) ALLOW_UPLOAD=1 ./run_server.sh

certs:
	mkdir -p certs
	openssl req -x509 -newkey rsa:4096 -nodes -out certs/server.crt -keyout certs/server.key -days 365 -subj "/CN=localhost"

run-ssl: venv
	PYTHON=$(PYTHON) HOST=0.0.0.0 PORT=5000 WORKERS=3 IMAGES_DIR=images USE_SSL=1 \
	CERT_FILE=certs/server.crt KEY_FILE=certs/server.key \
	./run_server.sh

run-with-upload-ssl: venv
	PYTHON=$(PYTHON) HOST=0.0.0.0 PORT=5000 WORKERS=3 IMAGES_DIR=images \
	USE_SSL=1 ALLOW_UPLOAD=1 \
	CERT_FILE=certs/server.crt KEY_FILE=certs/server.key \
	./run_server.sh

# Container targets
container-build:
	podman build -t $(CONTAINER_IMAGE) -f Containerfile .

container-run:
	podman run -p 5000:5000 -v ./images:/app/images:Z $(CONTAINER_IMAGE)

container-run-upload:
	podman run -p 5000:5000 -v ./images:/app/images:Z \
		-e ALLOW_UPLOAD=1 \
		$(CONTAINER_IMAGE)

container-run-ssl:
	podman run -p 5000:5000 \
		-v ./images:/app/images:Z \
		-v ./certs:/app/certs:Z \
		-e USE_SSL=1 \
		-e CERT_FILE=certs/server.crt \
		-e KEY_FILE=certs/server.key \
		$(CONTAINER_IMAGE)
