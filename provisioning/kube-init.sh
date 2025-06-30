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