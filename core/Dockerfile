FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Copy source code to container
COPY . /app

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose the container's port
EXPOSE 8080

# Start the app
CMD ["python", "omnitide_core.py"]
