#!/bin/bash
echo "Building Docker container..."
docker build -t iso-builder .

echo "Starting Docker container..."
docker run -d -p 5000:5000 --name iso-builder iso-builder

echo "Docker container is running. Access the web interface at http://localhost:5000"
