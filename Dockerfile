FROM python:2.7-slim

RUN apt-get update && apt-get install -y nodejs npm

WORKDIR /app

COPY package.json package-lock.json requirements.txt cakeshow.coffee /app/

RUN npm install && pip install -r requirements.txt

COPY client /app/client
COPY config /app/config
COPY database /app/database
COPY form_generator /app/form_generator
COPY lib /app/lib
COPY public /app/public
COPY routes /app/routes
COPY shared /app/shared
COPY views /app/views

ENTRYPOINT ["./node_modules/.bin/coffee", "cakeshow.coffee"]
