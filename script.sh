#!/bin/bash

USER="ubuntu"
PASSWORD="password"
KUBESPRAY_VERSION="release-2.25"
# Define the sudo password
SUDO_PASS="your_sudo_password_here"

# Initialize array of nodes
# Write ip of master node first, then worker node
NODES=("your-node-ip-1" "your-node-ip-2" "your-node-ip-3")

# Number of master nodes
NUM_MASTERS=1  # Adjust this as needed, only odd number

# Get the number of nodes
count=${#NODES[@]}

# Create an array of node names
NAMES=()
for ((i=1; i<=NUM_MASTERS; i++)); do
  NAMES+=("master$i")
done
for ((i=1; i<=(${#NODES[@]}-NUM_MASTERS); i++)); do
  NAMES+=("node$i")
done

# Split nodes into master and worker nodes
MASTER_NODES=("${NAMES[@]:0:NUM_MASTERS}")
WORKER_NODES=("${NAMES[@]:NUM_MASTERS}")

# Update system and install necessary packages
sudo apt-get update
sudo apt-get install -y python3-virtualenv git sshpass ansible-core

# Create Python virtual environment
virtualenv .kubespray
source .kubespray/bin/activate

# Clone Kubespray repository
git clone https://github.com/kubernetes-sigs/kubespray.git --branch $KUBESPRAY_VERSION

# Install Kubespray dependencies
cd kubespray
pip install -r requirements.txt

# Generate ssh-key
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

# Đường dẫn tới file khóa SSH
KEY_PATH="${HOME}/.ssh/id_rsa.pub"

for NODE in "${NODES[@]}"; do
  # Kiểm tra nếu khóa SSH đã tồn tại trên node từ xa
  echo "Checking if SSH key exists on $NODE..."
  sshpass -p $PASSWORD ssh -o StrictHostKeyChecking=no $USER@$NODE "grep -q \"$(cat $KEY_PATH)\" ~/.ssh/authorized_keys"

  # Nếu khóa chưa tồn tại, thì thêm nó
  if [ $? -ne 0 ]; then
    echo "Key not found on $NODE. Adding key..."
    sshpass -p $PASSWORD ssh-copy-id -o StrictHostKeyChecking=no $USER@$NODE
  else
    echo "Key already exists on $NODE"
  fi

  # Kiểm tra xem có thể SSH mà không cần mật khẩu không
  echo "Testing SSH login to $NODE..."
  ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no $USER@$NODE "echo 'SSH login successful to $NODE without password'"
  if [ $? -ne 0 ]; then
    echo "Failed to SSH into $NODE without password."
  else
    echo "SSH into $NODE without password was successful."
  fi
done

# Config
cp -rfp inventory/sample inventory/mycluster
CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${NODES[@]}

# Rename nodes in the hosts.yaml file
for i in "${!NODES[@]}"; do
  old_name="node$((i+1))"
  new_name="${NAMES[i]}"
  sed -i "s/$old_name:/$new_name:/g" inventory/mycluster/hosts.yaml
done

# Modify hosts.yaml to set kube_control_plane, kube_node, and etcd groups
sed -i '/^  children:/,$ d' inventory/mycluster/hosts.yaml
cat << EOF >> inventory/mycluster/hosts.yaml
  children:
    kube_control_plane:
      hosts:
EOF
for node in "${MASTER_NODES[@]}"; do
  echo "        $node:" >> inventory/mycluster/hosts.yaml
done
cat << EOF >> inventory/mycluster/hosts.yaml
    kube_node:
      hosts:
EOF
for node in "${WORKER_NODES[@]}"; do
  echo "        $node:" >> inventory/mycluster/hosts.yaml
done
cat << EOF >> inventory/mycluster/hosts.yaml
    etcd:
      hosts:
EOF
for node in "${MASTER_NODES[@]}"; do
  echo "        $node:" >> inventory/mycluster/hosts.yaml
done
cat << EOF >> inventory/mycluster/hosts.yaml
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
    calico_rr:
      hosts: {}
EOF

# Deploy
ansible-playbook -i inventory/mycluster/hosts.yaml --become --become-user=root cluster.yml -u $USER --extra-vars "ansible_become_pass=$SUDO_PASS"

#Extend cert to 10 years
wget https://raw.githubusercontent.com/yuyicai/update-kube-cert/master/update-kubeadm-cert.sh
chmod 755 update-kubeadm-cert.sh
./update-kubeadm-cert.sh master --cri docker

#Install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Install Ingress controller by Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --set controller.service.type=NodePort

