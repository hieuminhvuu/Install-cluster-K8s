# Hướng dẫn sử file script:
- Link docs Kubespray: https://github.com/kubernetes-sigs/kubespray

## 0. Môi trường đã lab
- architecture: arm64
- os: ubuntu 24.04 noble
- core: 2
- ram: 2G

## 1. Pre-Setup all vm
- Xác định số node master - worker, setup ip, hostname, hosts
file /etc/hosts của tất cả các node đều cần thông tin của chính nó và các node còn lại
```
sudo vim /etc/netplan/00-
sudo vim /etc/hostname
sudo vim /etc/hosts
```
- Sau khi đổi hostname, addhost xong thì reboot lại các vm 
ssh tới các vm
- tắt swap
```
swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

## 2. Setup Master Node
- su qua root user
```
sudo -s
```
- sử dụng git clone project này về
- vim vào file script.sh sửa những thông số sau:
  - USER : user mặc định khi cài vm mới, ví dụ như ubuntu, tránh sử dụng trực tiếp user root
  - KUBESPRAY_VERSION : phiên bản kubespray muốn cài "release-2.25"
  - PASSWORD="password" : password của user ubuntu
  - NODES=("your-node-ip-1" "your-node-ip-2" "your-node-ip-3") : ip của các node
  - MASTER_NODES=("${NAMES[0]}") : ip của các master node
  - WORKER_NODES=("${NAMES[@]:1}") : ip của các worker node
- chạy file bash script để quá trình tự động chạy, thời gian mất khoảng 20-25p hoặc có thể hơn tuỳ vào độ trễ mạng.
```
bash script.sh
```