FROM python:3.8-slim
WORKDIR /app
COPY demo-app/requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
COPY demo-app/app.py .
EXPOSE 8080
CMD ["python3", "app.py"]