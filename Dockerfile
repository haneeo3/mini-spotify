FROM python:3.12-alpine
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app/ ./app/
COPY templates/ ./templates/
COPY static/ ./static/
EXPOSE 5000
CMD ["python3", "app/app.py"]