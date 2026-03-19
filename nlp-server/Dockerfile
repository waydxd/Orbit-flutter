# Orbit NLP Parser Server (event/task parsing)
# Models are mounted at runtime via -v ./models:/app/models

FROM python:3.10-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy runtime files only (no training scripts, data, tests, or models)
COPY server.py .
COPY utils/ utils/

EXPOSE 5001

CMD ["python", "server.py"]
