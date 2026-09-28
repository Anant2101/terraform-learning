#!/bin/bash

echo "Hello from Terraform provisioner!"

sudo apt update -y
sudo apt install nginx -y

sudo systemctl enable nginx
sudo systemctl start nginx

echo "Nginx installed successfully!"