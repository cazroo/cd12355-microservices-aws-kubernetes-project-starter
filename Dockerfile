here are all my files at the moment, please review to make sure they will work for deploying a microservices-based coworking space management application on **AWS EKS** using **Kubernetes**. The app consists of a PostgreSQL database and a backend service that interacts with it. 

The deployment uses **Docker** for containerization, **Amazon ECR** for image storage, and **Kubernetes ConfigMaps & Secrets** to manage configuration and sensitive data. We ensure scalability, high availability, and automated rollouts using Kubernetes best practices.
:

Dockerfile =
# Use an official Python runtime as a parent image
FROM python:3.10-slim-buster

# Set environment variables (you can modify them based on your needs)
ENV DB_USERNAME=default_username
ENV DB_PASSWORD=default_password
ENV DB_HOST=default_host

# Set the working directory inside the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY ./analytics/ /app/

# Install any dependencies from the requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Expose the port the app runs on (change if needed)
EXPOSE 5153

# Run the application
CMD ["python", "app.py"]

postgres-service.yaml =
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  ports:
    - port: 5432
  selector:
    app: postgres
  clusterIP: None

postgres-pvs.yaml =
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/postgres-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

postgres-deployment.yaml =
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  labels:
    app: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          value: "postgres"
        - name: POSTGRES_PASSWORD
          value: "postgres_password"
        - name: POSTGRES_DB
          value: "mydb"
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc

buildspec.yaml =
version: 0.2

env:
  variables:
    IMAGE_REPO_NAME: "my-app-repo"  
    IMAGE_TAG: "latest"  

phases:
  install:
    commands:
      - echo Installing dependencies...

  pre_build:
    commands:
      - echo Logging into ECR...
      - aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 474668420471.dkr.ecr.us-east-1.amazonaws.com

  build:
    commands:
      - echo Building the Docker image...
      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .

  post_build:
    commands:
      - echo Pushing the Docker image...
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG 474668420471.dkr.ecr.us-east-1.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
      - docker push 474668420471.dkr.ecr.us-east-1.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG

deployment/configmap.yaml =
apiVersion: v1
kind: ConfigMap
metadata:
  name: coworking-config
data:
  DB_NAME: mydatabase
  DB_USER: postgres
  DB_HOST: postgres
  DB_PORT: "5432"

deployment/secret.yaml =
apiVersion: v1
kind: Secret
metadata:
  name: coworking-secret
type: Opaque
data:
  DB_PASSWORD: bXlzZWNyZXRwYXNzd29yZA==
  
deployment/coworking.yaml =
apiVersion: v1
kind: Service
metadata:
  name: coworking
spec:
  type: LoadBalancer
  selector:
    service: coworking
  ports:
  - name: "5153"
    protocol: TCP
    port: 5153
    targetPort: 5153
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coworking
  labels:
    name: coworking
spec:
  replicas: 1
  selector:
    matchLabels:
      service: coworking
  template:
    metadata:
      labels:
        service: coworking
    spec:
      containers:
      - name: coworking
        image: 474668420471.dkr.ecr.us-east-1.amazonaws.com/my-app-repo:latest
        imagePullPolicy: IfNotPresent
        livenessProbe:
          httpGet:
            path: /health_check
            port: 5153
          initialDelaySeconds: 5
          timeoutSeconds: 2
        readinessProbe:
          httpGet:
            path: "/readiness_check"
            port: 5153
          initialDelaySeconds: 5
          timeoutSeconds: 5
        envFrom:
        - configMapRef:
            name: coworking-config
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: coworking-secret
              key: DB_PASSWORD
      restartPolicy: Always
	  
analytics/app.py =
import logging
import os

from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime, timedelta
from flask import jsonify
from sqlalchemy import and_, text
from random import randint

from config import app, db


port_number = int(os.environ.get("APP_PORT", 5153))


@app.route("/health_check")
def health_check():
    return "ok"


@app.route("/readiness_check")
def readiness_check():
    try:
        count = db.session.execute(text("SELECT COUNT(*) FROM tokens")).scalar()
    except Exception as e:
        app.logger.error(e)
        return "failed", 500
    else:
        return "ok"


def get_daily_visits():
    with app.app_context():
        result = db.session.execute(text("""
        SELECT Date(created_at) AS date,
            Count(*)         AS visits
        FROM   tokens
        WHERE  used_at IS NOT NULL
        GROUP  BY Date(created_at)
        """))

        response = {}
        for row in result:
            response[str(row[0])] = row[1]

        app.logger.info(response)

    return response


@app.route("/api/reports/daily_usage", methods=["GET"])
def daily_visits():
    return jsonify(get_daily_visits())


@app.route("/api/reports/user_visits", methods=["GET"])
def all_user_visits():
    result = db.session.execute(text("""
    SELECT t.user_id,
        t.visits,
        users.joined_at
    FROM   (SELECT tokens.user_id,
                Count(*) AS visits
            FROM   tokens
            GROUP  BY user_id) AS t
        LEFT JOIN users
                ON t.user_id = users.id;
    """))

    response = {}
    for row in result:
        response[row[0]] = {
            "visits": row[1],
            "joined_at": str(row[2])
        }
    
    return jsonify(response)


scheduler = BackgroundScheduler()
job = scheduler.add_job(get_daily_visits, 'interval', seconds=30)
scheduler.start()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=port_number)
	
analytics/config.py =
import logging
import os

from flask import Flask
from flask_sqlalchemy import SQLAlchemy

db_username = os.environ["DB_USERNAME"]
db_password = os.environ["DB_PASSWORD"]
db_host = os.environ.get("DB_HOST", "127.0.0.1")
db_port = os.environ.get("DB_PORT", "5432")
db_name = os.environ.get("DB_NAME", "postgres")

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = f"postgresql://{db_username}:{db_password}@{db_host}:{db_port}/{db_name}"

db = SQLAlchemy(app)

app.logger.setLevel(logging.DEBUG)

analytics/requirements.txt =
APScheduler==3.10.4
Flask==3.0.2
flask_sqlalchemy==3.1.1
SQLAlchemy==2.0.27
psycopg2-binary==2.9.9

deployment-local/configmap.yaml =
apiVersion: v1
kind: ConfigMap
metadata:
  name: <NAME OF THE ConfigMap>
data:
  DB_NAME: <ENTER YOUR DB NAME HERE>
  DB_USER: <ENTER YOUR USER NAME HERE>
  DB_HOST: <ENTER YOUR DB HOST HERE>
  DB_PORT: <ENTER YOUR DB PORT HERE>
---
apiVersion: v1
kind: Secret
metadata:
  name: <NAME OF THE Secret>
type: Opaque
data:
  <THE KEY FROM Secret WHICH has THE ENCODED PASSWORD>: <OUTPUT OF `echo -n 'the password' | base64`>
  
deployment-local/coworking.yaml =
apiVersion: v1
kind: Service
metadata:
  name: coworking
spec:
  # A local environment doesn't generally have a LoadBalancer, so we use NodePort instead.
  type: NodePort
  selector:
    service: coworking
  ports:
  - name: "5153"
    protocol: TCP
    port: 5153
    targetPort: 5153
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coworking
  labels:
    name: coworking
spec:
  replicas: 1
  selector:
    matchLabels:
      service: coworking
  template:
    metadata:
      labels:
        service: coworking
    spec:
      containers:
      - name: coworking
        # Locally hosted docker image
        image: <DOCKER_IMAGE_NAME>:<IMAGE_TAG>
        imagePullPolicy: IfNotPresent
        livenessProbe:
          httpGet:
            path: /health_check
            port: 5153
          initialDelaySeconds: 5
          timeoutSeconds: 2
        readinessProbe:
          httpGet:
            path: "/readiness_check"
            port: 5153
          initialDelaySeconds: 5
          timeoutSeconds: 5
        envFrom:
        - configMapRef:
            name: <NAME OF THE ConfigMap>
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: <NAME OF THE Secret>
              key: <THE KEY FROM Secret WHICH has THE ENCODED PASSWORD>
      restartPolicy: Always
