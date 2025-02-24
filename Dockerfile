# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /analytics

# Copy the current directory contents into the container at /analytics
COPY . /analytics

# Install dependencies from the 'analytics' folder's requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port the app runs on (adjust to your app's port, default for Flask is 5000)
EXPOSE 5000

# Define environment variable for Flask (or adjust if using another framework)
ENV FLASK_APP=app.py  
ENV FLASK_RUN_HOST=0.0.0.0

# Run the application
CMD ["flask", "run"]

