# Use a lightweight Python image
FROM python:3.9-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the HTML and Python server files into the container
COPY index.html /app/index.html
COPY app.py /app/app.py

# Install Flask
RUN pip install flask

# Expose port 8080 to the outside world
EXPOSE 8080

# Command to run the Python server
CMD ["python", "app.py"]
