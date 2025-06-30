# 🧱 Vagrant Kubernetes Cluster (IaC Setup)

This repository automates the creation of a **3-node Kubernetes cluster** using **Vagrant**, **VirtualBox**, and shell provisioning.

- 1 Master Node
- 2 Worker Nodes
- Based on Ubuntu 22.04
- Container Runtime: CRI-O
- K8s Version: v1.32

---

## 📁 Project Structure
```
📦 vagrant-k8s-cluster/
 ┣ 📄 Vagrantfile
 ┣ 📄 README.md
 ┗ 📁 provisioning/
     ┣ 📜 kube-setup.sh
     ┗ 📜 kube-init.sh
```

---

## 🚀 Quick Start

> Make sure you have **Vagrant**, **VirtualBox**, and **ansible/ssh support** installed.

```bash
# Clone the repository
git clone https://github.com/Khalil-Bouazizi/vagrant-k8s-cluster.git
cd vagrant-k8s-cluster

# Start the machines (master + workers)
vagrant up
```

---

## 📜 Vagrantfile
```ruby
Vagrant.configure("2") do |config|
  config.vm.define "master" do |master|
    master.vm.box = "bento/ubuntu-22.04"
    master.vm.hostname = "master-node"
    master.vm.network "private_network", ip: "10.0.1.15"

    master.vm.provider "virtualbox" do |vb|
      vb.memory = 4048
      vb.cpus = 2
    end

    master.vm.provision "shell", path: "provisioning/kube-setup.sh"
  end

  (1..2).each do |i|
    config.vm.define "node0#{i}" do |node|
      node.vm.box = "bento/ubuntu-22.04"
      node.vm.hostname = "worker-node0#{i}"
      node.vm.network "private_network", ip: "10.0.1.1#{i + 5}"

      node.vm.provider "virtualbox" do |vb|
        vb.memory = 2048
        vb.cpus = 1
      end

      node.vm.provision "shell", path: "provisioning/kube-setup.sh"
    end
  end
end
```

---

## ⚙️ provisioning/kube-setup.sh
```bash
#!/bin/bash
set -e

# Update and configure hosts
apt-get update -y
cat >> /etc/hosts <<EOF
10.0.1.15  master-node
10.0.1.16  worker-node01
10.0.1.17  worker-node02
EOF

# Load modules
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Apply sysctl settings
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# Disable swap permanently
swapoff -a
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true

# Install CRI-O
apt-get install -y software-properties-common gpg curl apt-transport-https ca-certificates
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" \
  | tee /etc/apt/sources.list.d/cri-o.list

apt-get update -y
apt-get install -y cri-o
systemctl daemon-reexec
systemctl enable crio --now

# Install Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' \
  | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl jq
apt-mark hold kubelet kubeadm kubectl

# Set node IP
local_ip="$(ip --json addr show eth0 | jq -r '.[0].addr_info[] | select(.family == "inet") | .local')"
cat > /etc/default/kubelet <<EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF
```

---

## 🧩 provisioning/kube-init.sh (Run only on Master)
```bash
#!/bin/bash
set -e

IPADDR="10.0.1.15"
NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"

kubeadm init \
  --apiserver-advertise-address=$IPADDR \
  --apiserver-cert-extra-sans=$IPADDR \
  --pod-network-cidr=$POD_CIDR \
  --node-name $NODENAME \
  --ignore-preflight-errors Swap

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml
```

---

## 🧱 Worker Join Command (run on each worker)
Get this from `kubeadm token create --print-join-command` after init.
```bash
sudo kubeadm join <MASTER_IP>:6443 --token <TOKEN> \
    --discovery-token-ca-cert-hash sha256:<HASH>
```

---

## 🧠 Author
**Khalil Bouazizi** — [GitHub](https://github.com/Khalil-Bouazizi) | [LinkedIn](https://www.linkedin.com/in/khalil-bouazizi-617905244/)
