# X-Road Multi-Host Docker Deployment

Triển khai X-Road trên nhiều máy khác nhau sử dụng Docker. Setup này cho phép tách biệt Central Server và Security Server trên các máy vật lý hoặc VM khác nhau.

## 📋 Mục Lục

- [Kiến trúc](#kiến-trúc)
- [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
- [Triển khai Central Service](#triển-khai-central-service)
- [Triển khai Security Server](#triển-khai-security-server)
- [Cấu hình mạng](#cấu-hình-mạng)
- [Quản lý và bảo trì](#quản-lý-và-bảo-trì)
- [Khắc phục sự cố](#khắc-phục-sự-cố)

## 🏗️ Kiến trúc

### Máy Central Server (Máy CS)
Triển khai các services:
- **Central Server**: Quản lý cấu hình và chứng chỉ toàn hệ thống
- **Management Security Server (SS0)**: Security Server quản lý, đóng vai trò producer
- **Test CA**: Certificate Authority cho môi trường development
- **Mail Server**: Mailpit cho email notifications
- **Test Services**: Example SOAP và REST services

### Máy Security Server (Máy SS)
Triển khai:
- **Security Server**: Client security server cho các tổ chức thành viên

## 🔧 Yêu cầu hệ thống

### Phần cứng (mỗi máy)
- **CPU**: 2+ cores
- **RAM**: 4GB+ (khuyến nghị 8GB cho Central Server)
- **Disk**: 20GB+ dung lượng trống
- **Network**: Kết nối mạng giữa các máy

### Phần mềm
- **OS**: Ubuntu 22.04 LTS hoặc tương đương
- **Docker**: Version 24.x+
- **Docker Compose**: Version 2.24.x+

### Cài đặt Docker (nếu chưa có)

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Docker Compose
sudo apt-get update
sudo apt-get install docker-compose-plugin
```

## 🚀 Triển khai Central Service

### Bước 1: Chuẩn bị trên máy Central Server

```bash
cd X-Road/Docker/multi-host-stack/central-service

# Copy và chỉnh sửa file cấu hình
cp .env.example .env
nano .env  # Điều chỉnh token PIN nếu cần
```

### Bước 2: Khởi động services

```bash
# Cho phép scripts thực thi
chmod +x *.sh

# Khởi động tất cả services
./start.sh
```

Script sẽ:
- Tạo các thư mục volumes cần thiết
- Khởi động Central Server, Management Security Server, Test CA và các services khác
- Đợi cho tất cả services healthy (2-3 phút)

### Bước 3: Truy cập Web UI

Sau khi khởi động thành công:

**Central Server**: https://[IP_CUA_MAY_CS]:4000
- Username: `xrd-sys`
- Password: `secret`

**Management Security Server**: https://[IP_CUA_MAY_CS]:4200
- Username: `xrd-sys`
- Password: `secret`

**Mail UI**: http://[IP_CUA_MAY_CS]:8025

### Bước 4: Lấy API Token

API Token cần thiết để đăng ký Security Server từ các máy khác:

```bash
docker exec cs cat /etc/xroad/conf.d/local.ini | grep api-token
```

**⚠️ LƯU Ý QUAN TRỌNG**: Lưu token này lại, bạn sẽ cần nó khi cấu hình Security Server.

### Bước 5: Cấu hình Central Server qua UI

1. Truy cập Central Server UI
2. Hoàn thành wizard khởi tạo:
   - Instance identifier: `DEV` (hoặc theo yêu cầu)
   - Set PIN code cho software token
   - Generate signing và authentication keys
3. Tạo member classes và members theo nhu cầu

## 🔐 Triển khai Security Server

### Bước 1: Chuẩn bị trên máy Security Server

```bash
cd X-Road/Docker/multi-host-stack/security-server

# Copy và chỉnh sửa file cấu hình
cp .env.example .env
nano .env
```

### Bước 2: Cấu hình kết nối đến Central Server

Chỉnh sửa file `.env`:

```bash
# Thay đổi IP/hostname của máy Central Server
CS_HOST=192.168.1.10        # IP thực tế của máy CS
CA_HOST=192.168.1.10        # Cùng IP với CS
ISSOAP_HOST=192.168.1.10    # Nếu cần dùng test services
ISREST_HOST=192.168.1.10

# Token PIN
SS_TOKEN_PIN=Secret1234
```

### Bước 3: Cấu hình firewall/network

Đảm bảo máy Security Server có thể kết nối đến Central Server:

```bash
# Test kết nối
ping 192.168.1.10
curl -k https://192.168.1.10:4000
```

### Bước 4: Khởi động Security Server

```bash
# Cho phép scripts thực thi
chmod +x *.sh

# Khởi động Security Server
./start.sh
```

### Bước 5: Cấu hình Security Server qua UI

**Truy cập**: https://[IP_CUA_MAY_SS]:4000
- Username: `xrd-sys`
- Password: `secret`

Hoàn thành wizard:

1. **Initialize Software Token**
   - Nhập PIN code (default: `Secret1234`)

2. **Configure Server**
   - Instance identifier: `DEV`
   - Member class: Chọn class đã tạo ở CS
   - Member code: Mã định danh tổ chức
   - Security server code: Mã định danh server (VD: `SS1`)

3. **Generate Keys**
   - Generate signing key
   - Generate authentication key

4. **Register with Central Server**
   - Central Server address: `https://[IP_CS]:4000`
   - API token: Token đã lấy từ bước 4 phần Central Service

5. **Approve on Central Server**
   - Đăng nhập vào Central Server UI
   - Vào phần "Security Servers"
   - Approve registration request từ Security Server mới

## 🌐 Cấu hình mạng

### Ports cần mở

#### Trên máy Central Server:
```
4000/tcp    - Central Server Web UI (HTTPS)
4200/tcp    - Management Security Server Web UI (HTTPS)
8080/tcp    - Management SS Proxy HTTP
8443/tcp    - Management SS Proxy HTTPS
5500/tcp    - Message exchange
5577/tcp    - OCSP
8888/tcp    - Test CA OCSP
8899/tcp    - Test CA TSA
8887/tcp    - Test CA ACME
```

#### Trên máy Security Server:
```
4000/tcp    - Security Server Web UI (HTTPS)
8080/tcp    - Proxy HTTP
8443/tcp    - Proxy HTTPS
5500/tcp    - Message exchange
5577/tcp    - OCSP
```

### Cấu hình firewall Ubuntu

**Trên máy Central Server:**
```bash
sudo ufw allow 4000/tcp
sudo ufw allow 4200/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 8443/tcp
sudo ufw allow 5500/tcp
sudo ufw allow 5577/tcp
sudo ufw allow 8888/tcp
sudo ufw enable
```

**Trên máy Security Server:**
```bash
sudo ufw allow 4000/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 8443/tcp
sudo ufw allow 5500/tcp
sudo ufw allow 5577/tcp
sudo ufw enable
```

### Cấu hình DNS (khuyến nghị)

Thay vì dùng IP, nên cấu hình DNS hoặc `/etc/hosts`:

```bash
# Trên máy Security Server, thêm vào /etc/hosts:
192.168.1.10    cs.xroad.local cs
192.168.1.10    testca.xroad.local testca
```

## 📊 Services và Ports Map

| Service | Container | Internal Port | External Port | Máy |
|---------|-----------|---------------|---------------|-----|
| Central Server UI | cs | 4000 | 4000 | CS |
| CS Database | cs | 5432 | 5432 | CS |
| Management SS UI | ss0 | 4000 | 4200 | CS |
| Management SS Proxy | ss0 | 8080 | 8080 | CS |
| Test CA OCSP | testca | 8888 | 8888 | CS |
| Test CA TSA | testca | 8899 | 8899 | CS |
| Test CA ACME | testca | 8887 | 8887 | CS |
| Mail UI | mailpit | 8025 | 8025 | CS |
| Example SOAP | issoap | 8080 | 4600 | CS |
| Example REST | isrest | 8080 | 4500 | CS |
| Security Server UI | ss | 4000 | 4000 | SS |
| Security Server Proxy | ss | 8080 | 8080 | SS |

## 🛠️ Quản lý và bảo trì

### Kiểm tra trạng thái services

```bash
# Trên máy Central Server
cd X-Road/Docker/multi-host-stack/central-service
docker compose ps

# Trên máy Security Server
cd X-Road/Docker/multi-host-stack/security-server
docker compose ps
```

### Xem logs

```bash
# Xem logs của tất cả services
docker compose logs -f

# Xem logs của service cụ thể
docker compose logs -f cs
docker compose logs -f ss0
docker compose logs -f ss
```

### Dừng services

```bash
# Dừng nhưng giữ lại dữ liệu
./stop.sh

# Hoặc
docker compose down
```

### Khởi động lại services

```bash
./start.sh

# Hoặc khởi động lại một service cụ thể
docker compose restart cs
```

### Backup dữ liệu

Dữ liệu được lưu trong các thư mục:

```bash
# Central Server
/etc/xroad/cs
/var/lib/xroad/cs
/var/lib/postgresql/cs

# Management Security Server
/etc/xroad/ss0
/var/lib/xroad/ss0
/var/lib/postgresql/ss0

# Security Server
/etc/xroad/ss
/var/lib/xroad/ss
/var/lib/postgresql/ss
```

Backup:
```bash
# Tạo backup
sudo tar -czf xroad-backup-$(date +%Y%m%d).tar.gz \
    /etc/xroad/cs \
    /var/lib/xroad/cs \
    /var/lib/postgresql/cs

# Restore
sudo tar -xzf xroad-backup-20240101.tar.gz -C /
```

### Update/Upgrade

```bash
# Pull images mới nhất
docker compose pull

# Rebuild và restart
docker compose up -d --build
```

## 🐛 Khắc phục sự cố

### Services không healthy

```bash
# Kiểm tra logs
docker compose logs [service_name]

# Restart service
docker compose restart [service_name]

# Kiểm tra health check
docker inspect [container_name] | grep -A 20 Health
```

### Không kết nối được giữa SS và CS

1. **Kiểm tra network connectivity:**
```bash
# Từ máy SS, test kết nối đến CS
ping [CS_IP]
curl -k https://[CS_IP]:4000
telnet [CS_IP] 4000
```

2. **Kiểm tra firewall:**
```bash
sudo ufw status
```

3. **Kiểm tra extra_hosts trong docker-compose:**
```bash
docker compose config | grep extra_hosts
```

### Permission denied trên volumes

```bash
# Fix quyền truy cập
sudo chown -R 999:999 /etc/xroad/cs /var/lib/xroad/cs
sudo chown -R 999:999 /etc/xroad/ss /var/lib/xroad/ss
```

### Database connection issues

```bash
# Kiểm tra PostgreSQL
docker compose exec cs pg_isready
docker compose exec ss pg_isready

# Restart database
docker compose restart cs
docker compose restart ss
```

### API Token không hoạt động

```bash
# Lấy lại token từ Central Server
docker exec cs cat /etc/xroad/conf.d/local.ini | grep api-token

# Verify token format (phải là 32 ký tự alphanumeric)
```

## 📝 Lưu ý quan trọng

1. **Security trong Production:**
   - Thay đổi default passwords
   - Sử dụng strong token PINs
   - Cấu hình HTTPS với certificates hợp lệ
   - Hạn chế access với firewall rules chính xác

2. **Network Requirements:**
   - Central Server và Security Server phải reach được nhau
   - DNS resolution hoặc hosts file cần cấu hình đúng
   - NTP synchronization giữa các máy

3. **Volumes và Data Persistence:**
   - Dữ liệu được lưu trong host directories
   - Backup thường xuyên các thư mục quan trọng
   - Không xóa volumes khi down containers nếu muốn giữ data

4. **Resource Allocation:**
   - Central Server cần nhiều tài nguyên hơn Security Server
   - Monitor resource usage và scale khi cần

## 📚 Tài liệu tham khảo

- [X-Road Official Documentation](https://github.com/nordic-institute/X-Road)
- [X-Road Architecture](https://github.com/nordic-institute/X-Road/blob/develop/doc/Architecture/arc-g_x-road_arhitecture.md)
- [Docker Documentation](https://docs.docker.com/)

## 🤝 Support

Nếu gặp vấn đề, kiểm tra:
1. Logs của containers: `docker compose logs`
2. Health status: `docker compose ps`
3. Network connectivity giữa các máy
4. Firewall rules

## 📄 License

X-Road là open source software. Tham khảo LICENSE trong repository chính.

