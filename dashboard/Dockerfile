FROM python:3.10-slim

WORKDIR /app

# Copy dashboard & ingestion scripts
COPY . /app

# Install dependencies
RUN pip install --no-cache-dir -r requirement.txt

# Run ingestion first, then start dashboard
CMD ["bash", "-c", "python ingest_data.py && streamlit run app.py --server.port=8501 --server.address=0.0.0.0"]