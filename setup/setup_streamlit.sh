#!/bin/bash
# Setup Streamlit application using Docker Compose

# Navigate to the Streamlit app directory
cd ~/docker/streamlit_app

# Build the Docker image
docker-compose build

# Start the Streamlit container
docker-compose up -d

echo "Streamlit application deployed successfully!"