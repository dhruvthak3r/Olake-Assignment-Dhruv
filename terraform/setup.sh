#!/bin/bash

set -e

sudo apt update -y
sudo apt install -y curl docker.io

sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

su - ubuntu <<'EOF'

docker --version

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
rm -f kubectl.sha256

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install -y helm

docker --version
kubectl version --client
minikube version
helm version

minikube start --cpus=3 --memory=6144 --driver=docker
minikube addons enable ingress
minikube addons enable storage-provisioner
minikube status

sudo apt install -y nginx
sudo systemctl enable nginx

cat <<'NGINX_CONF' | sudo tee /etc/nginx/sites-available/olake
server {
    listen 8000;
    server_name _;

    location / {
        root /var/www/olake;
        index index.html;
    }

    location /app/ {
        proxy_pass http://192.168.49.2:30082/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_CONF

sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/olake /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

EOF
