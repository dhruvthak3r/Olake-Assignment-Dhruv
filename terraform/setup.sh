#!/bin/bash

sudo apt update -y

echo "[+] Installing curl and docker..."
sudo apt install curl docker.io -y

echo "[+] Starting and enabling Docker..."
sudo systemctl enable docker
sudo systemctl start docker

echo "[+] Adding ubuntu user to docker group..."
sudo usermod -aG docker ubuntu


echo "[+] Switching to ubuntu user to avoid root issues..."

su - ubuntu << 'EOF'

# Ensure Docker works without sudo
echo "[+] Testing Docker as ubuntu user..."
docker --version

# Install kubectl
echo "[+] Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
rm -f kubectl.sha256

# Install Minikube
echo "[+] Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

# Install Helm
echo "[+] Installing Helm..."
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm -y

echo "[+] Verifying installations..."
docker --version
kubectl version --client
minikube version
helm version

echo "[+] Starting Minikube with Docker driver (as non-root)..."
minikube start --cpus=3 --memory=6144 --driver=docker

echo "[+] Enabling Minikube addons..."
minikube addons enable ingress
minikube addons enable storage-provisioner

echo "[+] Minikube addons status:"
minikube addons list

echo "[+] Minikube is ready!"
minikube status

EOF