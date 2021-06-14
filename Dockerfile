FROM python:3.9-slim
LABEL maintainer=flsixtyfour@gmail.com
WORKDIR /app
COPY app/requirements.txt .
RUN  pip3 install -r requirements.txt && adduser --disabled-password --gecos '' mwc-app
COPY app .
USER mwc-app
ENTRYPOINT ["gunicorn"]
CMD [ "wsgi:app", "--certfile=/tls/tls.crt", "--keyfile=/tls/tls.key", "--worker-class=sync", "--workers=2", "--bind=0.0.0.0:5000", "--log-level=info" ]
