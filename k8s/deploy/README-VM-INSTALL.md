# YAS K8S - VM Installation Guide (Ubuntu)

This guide explains how to install the environment to run YAS on an Ubuntu VM using Docker, Minikube, kubectl, and Helm.

## 1: Minimum Requirements

- OS: Ubuntu 20.04+ (Ubuntu 22.04 recommended)
- CPU: at least 4 vCPU
- RAM: at least 12 GB (16 GB recommended)
- Disk: at least 40 GB (60 GB recommended)
- User with `sudo` privileges
- VM with Internet connectivity

## 2: Install Docker Engine

```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove -y $pkg
done

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg git conntrack

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker

docker version
```

If `newgrp docker` does not apply permissions immediately, log out and log back in to your SSH session.

## 3: Install kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

## 4: Install Minikube

```bash
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube version
```

## 5: Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

## 6: Start Minikube Cluster

```bash
minikube start --driver=docker --cpus=4 --disk-size='40000mb' --memory='16g'
minikube addons enable ingress
kubectl get nodes -o wide
kubectl get pods -A
```

## 7: Deploy YAS on the Cluster

From the repository root, go to the deploy folder:

```bash
cd k8s/deploy
```

Run these scripts in order:

```bash
./setup-cluster.sh
./setup-keycloak.sh
./setup-redis.sh
./deploy-yas-applications.sh
```

Check pod status:

```bash
kubectl get pods -A
kubectl get pods -n yas
```

Get Minikube IP to update your local hosts file:

```bash
minikube ip
```

Then add the `*.yas.local.com` domains to the hosts file on your client machine (developer machine).

## 8: Quick Troubleshooting

- Check Minikube:

```bash
minikube status
```

- Restart Minikube:

```bash
minikube stop
minikube start --driver=docker --cpus=4 --memory=12288 --disk-size=40g
```


- Fix in-cluster DNS for `identity.yas.local.com` (CoreDNS static host):

```bash
kubectl -n kube-system edit configmap coredns
```

In `Corefile`, add/update the `hosts` entry (replace the IP if your `minikube ip` is different):

```txt
hosts {
  192.168.49.2 identity.yas.local.com
  fallthrough
}
```

Then restart CoreDNS:

```bash
kubectl -n kube-system rollout restart deployment coredns
kubectl -n kube-system rollout status deployment coredns
```
