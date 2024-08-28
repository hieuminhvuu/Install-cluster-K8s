# Hướng dẫn sử file script:

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
  - PASSWORD="password"
  - NODES=("your-node-ip-1" "your-node-ip-2" "your-node-ip-3")
- chạy file bash script để quá trình tự động chạy, thời gian mất khoảng 20-25p hoặc có thể hơn tuỳ vào độ trễ mạng.
```
bash script.sh
```