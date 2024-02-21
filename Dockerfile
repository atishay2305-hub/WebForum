# Use an official base image
FROM ubuntu:20.04

# Set the working directory
WORKDIR /app

# Copy the application files into the container
COPY . .

# Install dependencies and configure the environment
RUN apt-get update \
    && apt-get install -y some-package \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Specify the command to run on container startup
CMD ["./app.py"]

# Expose any necessary ports
EXPOSE 8080
