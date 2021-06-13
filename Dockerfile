FROM python:3.9-slim
LABEL maintainer=flsixtyfour@gmail.com
WORKDIR /app
COPY app .
RUN  pip3 install -r requirements.txt && adduser --disabled-password --gecos '' mwc-app
USER mwc-app
CMD gunicorn --certfile=/tls/tls.crt --keyfile=/tls/tls.key --worker-class sync --workers 2 --bind 0.0.0.0:5000 wsgi:app --max-requests 100 --timeout 5 --keep-alive 1 --log-level info
