FROM python:3.10-slim-buster

ENV DB_USERNAME=default_username
ENV DB_PASSWORD=default_passowrd
ENV DB_HOST=default_host

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY /analytics/ /app

# Install any needed packages specified in requirements.txt
RUN pip install -r /app/requirements.txt

# Make port 5153 available to the world outside this container
EXPOSE 5153

CMD ["python", "app.py"]

