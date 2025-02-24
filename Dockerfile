# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory inside the container
WORKDIR /analytics

# Copy the current directory contents into the container at /analytics
COPY . /analytics

# Install any dependencies specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port the app runs on (adjust to your app's port, default for Flask is 5000)
EXPOSE 5000

# Define environment variable (optional, adjust based on your app)
ENV APP_ENV=production

# Run the application (adjust this based on how your app is run, e.g., flask run or python app.py)
CMD ["python", "app.py"]

