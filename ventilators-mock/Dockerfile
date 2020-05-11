FROM ubuntu:18.04

USER root

COPY . /app

WORKDIR /app

RUN apt-get update && apt-get install curl -y

CMD ["./ventilators-mock.sh", "--count", "25", "--exclude", "1"]
