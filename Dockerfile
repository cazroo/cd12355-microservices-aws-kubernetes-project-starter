# Use an official Python runtime as a parent image
FROM python:3.10-slim-buster

# Set environment variables
ENV DB_USERNAME=myuser
ENV DB_PASSWORD=mypassowrd
ENV DB_HOST=default_host

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the contents of the analytics folder into the container at /usr/src/app
COPY analytics/ .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Make port 5153 available to the world outside this container
EXPOSE 5153

# Run app.py when the container launches
CMD ["python", "app.py"]
