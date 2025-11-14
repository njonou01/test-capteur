FROM python:3.11-slim

WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir paho-mqtt==1.6.1

# Copy simulator code
COPY simulator.py /app/

# Make script executable
RUN chmod +x /app/simulator.py

CMD ["python", "-u", "simulator.py"]
