FROM python:3.10-slim-buster

# Set environment variables
ENV DB_USERNAME=myuser
ENV DB_PASSWORD=mypassword
ENV DB_HOST=default_host

# Set the working directory
WORKDIR /app

# Copy only necessary files
COPY analytics/ /app

# Install system dependencies
RUN apt update && \
    apt install -y build-essential libpq-dev

# Install Python dependencies
RUN pip install --upgrade pip setuptools wheel
RUN pip install -r requirements.txt

# Expose the port the app will run on
EXPOSE 5153

# Set the default command to run your app
CMD ["python", "app.py"]
