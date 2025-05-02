FROM python:3.9
WORKDIR /app
COPY . /app

RUN pip install flask
RUN apt-get update && \
    apt-get install -y sudo && \
    apt-get clean
EXPOSE 5000
CMD ["python", "app.py"]
