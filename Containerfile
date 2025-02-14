FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV HOST=0.0.0.0
ENV PORT=5000
ENV WORKERS=3
ENV IMAGES_DIR=images
ENV ALLOW_UPLOAD=
ENV USE_SSL=
ENV CERT_FILE=certs/server.crt
ENV KEY_FILE=certs/server.key

# Create certs directory
RUN mkdir -p certs

EXPOSE 5000

CMD ["./run_server.sh"]
