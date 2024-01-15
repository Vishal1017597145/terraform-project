#!/bin/bash

# Update and upgrade the system
apt-get update && apt-get upgrade -y

# Install Apache
apt-get install apache2 -y

# Getting the instance id using the metadata
Instance_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

rm -rf /var/www/html/index.html

# Creating an html file for printing on screen
cat >> /var/www/html/index.html << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Portfolio</title>
    <style>
    @keyframes colorChange {
        0% {color: red; }
        50% {color: blue; }
        100% {color: green; }
    }
    h1 {
        animation: colorChange 1s infinite;
    }
    </style>
</head>
<body>
    <h1> Terraform Project Server </h1>
    <h2> Instance_ID: <span style="color:green">$Instance_ID</span></h2>
    <p> Welcome to my first channel </p>
</body>
</html>
EOL

# Starting the Apache server
systemctl enable apache2
systemctl start apache2
