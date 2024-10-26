FROM python:3.9-slim

WORKDIR /app

# Install required packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY main.py .

# make the data directory
RUN mkdir /data

# Run the script
CMD ["python", "main.py"]
