#!/bin/bash
docker build -t mikaos-achiso-builder .
echo "Build completed. Starting container to build ISO..."
sleep 3
docker run --privileged -d --name mikaos-iso-builder   -v "$PWD":/workspace   -v "$HOME/arch/iso":/iso-output   -w /workspace   mikaos-iso-builder
echo "Container started. Building ISO inside container..."
echo "View logs with: docker logs -f mikaos-iso-builder"
echo "Once the build is complete, the ISO will be available in the 'arch/iso' directory on your host machine."
