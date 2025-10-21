# X-Road Multi-Host Docker Deployment

**Triển khai X-Road trên nhiều máy khác nhau sử dụng Docker**

Hướng dẫn đầy đủ để triển khai X-Road với kiến trúc phân tán, cho phép tách biệt Central Server và Security Server trên các máy vật lý hoặc VM khác nhau.

---

## 📋 Mục Lục

- [Tổng quan](#-tổng-quan)
- [Triển khai nhanh 5 phút](#-triển-khai-nhanh-5-phút)
- [Kiến trúc hệ thống](#-kiến-trúc-hệ-thống)
- [Yêu cầu hệ thống](#-yêu-cầu-hệ-thống)
- [Triển khai Central Service](#-triển-khai-central-service)
- [Triển khai Security Server](#-triển-khai-security-server)
- [Cấu hình mạng](#-cấu-hình-mạng)
- [Quản lý và bảo trì](#-quản-lý-và-bảo-trì)
- [Khắc phục sự cố](#-khắc-phục-sự-cố)
- [Kiến trúc mạng chi tiết](#-kiến-trúc-mạng-chi-tiết)

---

## 🎯 Tổng quan

### Điểm khác biệt

Setup này cho phép triển khai X-Road giống production:

✅ **Triển khai trên nhiều máy** vật lý/VMs khác nhau  
✅ **Network isolation** và security đúng chuẩn  
✅ **Sử dụng code gốc** từ nhà cung cấp  
✅ **Đầy đủ services**: CA, Mail, Test services  
✅ **Production-ready** architecture  
✅ **Dễ dàng scale** thêm Security Servers

### Cấu trúc

```
Máy 1 (Central Server)          Máy 2+ (Security Servers)
├── Central Server              ├── Security Server
├── Management SS (SS0)         └── Client configurations
├── Test CA
├── Mail Server
└── Test Services
```

---

## ⚡ Triển khai nhanh 5 phút

### Bước 1: Máy Central Server

```bash
cd X-Road/Docker/multi-host-stack/central-service

# Tạo file .env
cat > .env << 'EOF'
PACKAGE_SOURCE=external
CS_TOKEN_PIN=Secret1234
SS0_TOKEN_PIN=Secret1234
DIST=jammy-snapshot
REPO=https://artifactory.niis.org/xroad-snapshot-deb
EOF

# Khởi động
chmod +x *.sh
./start.sh

# Đợi 2-3 phút, sau đó lấy API token
docker exec cs cat /etc/xroad/conf.d/local.ini | grep api-token
```

**📝 Ghi lại:**
- IP máy CS: `_________________`
- API Token: `_________________`

### Bước 2: Máy Security Server

```bash
cd X-Road/Docker/multi-host-stack/security-server

# Tạo file .env (QUAN TRỌNG: Thay CS_HOST bằng IP thực)
cat > .env << 'EOF'
PACKAGE_SOURCE=external
SS_TOKEN_PIN=Secret1234
CS_HOST=192.168.1.10
CA_HOST=192.168.1.10
ISSOAP_HOST=192.168.1.10
ISREST_HOST=192.168.1.10
DIST=jammy-snapshot
REPO=https://artifactory.niis.org/xroad-snapshot-deb
EOF

# Chỉnh sửa CS_HOST
nano .env

# Khởi động
chmod +x *.sh
./start.sh
```

### Bước 3: Cấu hình qua Web UI

**Central Server** - `https://[IP_CS]:4000`
1. Login: `xrd-sys` / `secret`
2. Hoàn thành wizard khởi tạo
3. Tạo member classes

**Security Server** - `https://[IP_SS]:4000`
1. Login: `xrd-sys` / `secret`
2. Initialize software token (PIN: `Secret1234`)
3. Configure server (instance, member, subsystem)
4. Generate keys
5. Register với CS (dùng API token)

**Approve trên Central Server**
1. Login vào CS UI → "Security Servers"
2. Approve registration request

✅ **Hoàn thành!** Security Server đã kết nối với Central Server.

---

## 🏗️ Kiến trúc hệ thống

### Sơ đồ tổng quan

```
┌─────────────────────────────────────────────────────────┐
│                  Máy Central Server                      │
│                 (IP: 192.168.1.10)                       │
│                                                          │
│  ┌──────────────────────────────────────────┐          │
│  │     Docker Network: xroad-central-net     │          │
│  │          Subnet: 172.30.0.0/24           │          │
│  │                                          │          │
│  │  ┌─────────────┐  ┌──────────────┐     │          │
│  │  │     cs      │  │     ss0      │     │          │
│  │  │ 172.30.0.10 │  │ 172.30.0.20  │     │          │
│  │  │   :4000     │  │   :4200      │     │          │
│  │  └─────────────┘  └──────────────┘     │          │
│  │                                          │          │
│  │  ┌─────────────┐  ┌──────────────┐     │          │
│  │  │   testca    │  │   mailpit    │     │          │
│  │  │ 172.30.0.30 │  │ 172.30.0.40  │     │          │
│  │  └─────────────┘  └──────────────┘     │          │
│  │                                          │          │
│  │  ┌─────────────┐  ┌──────────────┐     │          │
│  │  │   issoap    │  │   isrest     │     │          │
│  │  │ 172.30.0.50 │  │ 172.30.0.60  │     │          │
│  │  └─────────────┘  └──────────────┘     │          │
│  └──────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────┘
                            │
                            │ Network (LAN/Internet)
                            │
┌─────────────────────────────────────────────────────────┐
│                  Máy Security Server                     │
│                 (IP: 192.168.1.20)                       │
│                                                          │
│  ┌──────────────────────────────────────────┐          │
│  │     Docker Network: xroad-ss-net         │          │
│  │          Subnet: 172.31.0.0/24           │          │
│  │                                          │          │
│  │         ┌─────────────┐                 │          │
│  │         │     ss      │                 │          │
│  │         │ 172.31.0.10 │                 │          │
│  │         │   :4000     │                 │          │
│  │         └─────────────┘                 │          │
│  │                                          │          │
│  │  extra_hosts:                           │          │
│  │    cs → 192.168.1.10                    │          │
│  │    testca → 192.168.1.10                │          │
│  └──────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────┘
```

### Services

#### Central Service (Máy CS)

| Service | Container | Port | Mô tả |
|---------|-----------|------|-------|
| Central Server | cs | 4000 | Central Server UI (HTTPS) |
| | | 80 | HTTP (global config) |
| | | 5432 | PostgreSQL (internal) |
| Management SS | ss0 | 4200 | Management SS UI (HTTPS) |
| | | 8080 | Proxy HTTP |
| | | 8443 | Proxy HTTPS |
| | | 5500 | Message exchange |
| | | 5577 | OCSP |
| Test CA | testca | 8888 | OCSP |
| | | 8899 | TSA |
| | | 8887 | ACME |
| Mail Server | mailpit | 8025 | Web UI |
| | | 1025 | SMTP |
| Example SOAP | issoap | 4600 | SOAP service |
| Example REST | isrest | 4500 | REST service |

#### Security Server (Máy SS)

| Service | Container | Port | Mô tả |
|---------|-----------|------|-------|
| Security Server | ss | 4000 | Security Server UI (HTTPS) |
| | | 8080 | Proxy HTTP |
| | | 8443 | Proxy HTTPS |
| | | 5500 | Message exchange |
| | | 5577 | OCSP |

---

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

### Cài đặt Docker

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Docker Compose
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Verify
docker --version
docker compose version
```

### Checklist trước khi bắt đầu

- [ ] Docker và Docker Compose đã cài đặt
- [ ] Máy CS và SS có thể ping được nhau
- [ ] Firewall sẽ được cấu hình
- [ ] IP addresses đã được ghi lại

---

## 🚀 Triển khai Central Service

### 1. Chuẩn bị

```bash
cd X-Road/Docker/multi-host-stack/central-service

# Tạo file .env
cat > .env << 'EOF'
PACKAGE_SOURCE=external
CS_TOKEN_PIN=Secret1234
SS0_TOKEN_PIN=Secret1234
DIST=jammy-snapshot
REPO=https://artifactory.niis.org/xroad-snapshot-deb
EOF

# Chỉnh sửa nếu cần (thay đổi token PIN)
nano .env
```

### 2. Khởi động services

```bash
chmod +x *.sh
./start.sh
```

Script sẽ:
- Tạo các thư mục volumes: `/etc/xroad/cs`, `/var/lib/xroad/cs`, `/var/lib/postgresql/cs`
- Khởi động tất cả services
- Đợi cho services healthy (2-3 phút)

### 3. Kiểm tra trạng thái

```bash
docker compose ps
docker compose logs -f
```

### 4. Truy cập Web UI

**Central Server**: `https://[IP_CENTRAL_SERVER]:4000`
- Username: `xrd-sys`
- Password: `secret`

**Management Security Server**: `https://[IP_CENTRAL_SERVER]:4200`
- Username: `xrd-sys`
- Password: `secret`

**Mail UI**: `http://[IP_CENTRAL_SERVER]:8025`

**Test Services**:
- SOAP: `http://[IP_CENTRAL_SERVER]:4600`
- REST: `http://[IP_CENTRAL_SERVER]:4500`

### 5. Lấy API Token

API Token cần thiết để đăng ký Security Servers:

```bash
docker exec cs cat /etc/xroad/conf.d/local.ini | grep api-token
```

**⚠️ QUAN TRỌNG**: Lưu token này lại và chia sẻ với administrators của Security Servers.

### 6. Cấu hình Central Server

1. Truy cập Central Server UI
2. Hoàn thành wizard khởi tạo:
   - Instance identifier: `DEV` (hoặc theo yêu cầu)
   - Set PIN code cho software token
   - Generate signing và authentication keys
3. Tạo member classes (VD: `GOV`, `COM`, `ORG`)
4. Tạo members nếu cần

### 7. Dừng services

```bash
./stop.sh
# hoặc
docker compose down
```

---

## 🔐 Triển khai Security Server

### 1. Chuẩn bị

```bash
cd X-Road/Docker/multi-host-stack/security-server

# Tạo file .env (QUAN TRỌNG: Thay CS_HOST bằng IP thực tế)
cat > .env << 'EOF'
PACKAGE_SOURCE=external
SS_TOKEN_PIN=Secret1234
CS_HOST=192.168.1.10
CA_HOST=192.168.1.10
ISSOAP_HOST=192.168.1.10
ISREST_HOST=192.168.1.10
DIST=jammy-snapshot
REPO=https://artifactory.niis.org/xroad-snapshot-deb
EOF

# Chỉnh sửa CS_HOST với IP thực tế của Central Server
nano .env
```

**⚠️ QUAN TRỌNG**: Phải cập nhật `CS_HOST` với IP hoặc hostname thực tế của máy Central Server!

### 2. Kiểm tra kết nối

Trước khi khởi động, test kết nối đến Central Server:

```bash
# Test network connectivity
ping [CS_IP]

# Test HTTPS
curl -k https://[CS_IP]:4000

# Test ports
telnet [CS_IP] 4000
telnet [CS_IP] 8888
```

### 3. Khởi động Security Server

```bash
chmod +x *.sh
./start.sh
```

Script sẽ:
- Verify CS_HOST đã được cấu hình
- Tạo volumes: `/etc/xroad/ss`, `/var/lib/xroad/ss`, `/var/lib/postgresql/ss`
- Khởi động Security Server
- Đợi service healthy (2-3 phút)

### 4. Truy cập Web UI

**Security Server**: `https://[IP_SECURITY_SERVER]:4000`
- Username: `xrd-sys`
- Password: `secret`

### 5. Cấu hình Security Server

Hoàn thành wizard khởi tạo:

#### a) Initialize Software Token
- Nhập PIN code: `Secret1234` (hoặc giá trị trong .env)

#### b) Configure Server
- **Instance identifier**: `DEV` (phải giống với CS)
- **Member class**: Chọn class đã tạo ở Central Server
- **Member code**: Mã định danh tổ chức (VD: `ORG001`)
- **Member name**: Tên tổ chức
- **Security server code**: Mã định danh server (VD: `SS1`, `SS2`)

#### c) Generate Keys
- Generate signing key
- Generate authentication key và CSR

#### d) Register with Central Server
- Central Server address: `https://[IP_CS]:4000`
- Hoặc sử dụng API để đăng ký tự động

#### e) Get API Token
Liên hệ administrator của Central Server để lấy API token (đã lấy ở bước trên).

#### f) Approve trên Central Server
Administrator của CS cần:
1. Login vào Central Server UI
2. Vào "Security Servers"
3. Approve registration request

#### g) Configure Subsystems và Services
- Thêm subsystems
- Đăng ký services
- Cấu hình access rights

### 6. Dừng services

```bash
./stop.sh
# hoặc
docker compose down
```

---

## 🌐 Cấu hình mạng

### Ports cần mở

#### Trên máy Central Server:

```
4000/tcp    - Central Server Web UI (HTTPS)
4200/tcp    - Management Security Server Web UI (HTTPS)
80/tcp      - HTTP (for global configuration download)
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

### Cấu hình Firewall

#### Ubuntu UFW

**Trên máy Central Server:**

```bash
sudo ufw allow 4000/tcp comment 'Central Server UI'
sudo ufw allow 4200/tcp comment 'Management SS UI'
sudo ufw allow 80/tcp comment 'HTTP global config'
sudo ufw allow 8080/tcp comment 'Proxy HTTP'
sudo ufw allow 8443/tcp comment 'Proxy HTTPS'
sudo ufw allow 5500/tcp comment 'Message exchange'
sudo ufw allow 5577/tcp comment 'OCSP'
sudo ufw allow 8888/tcp comment 'CA OCSP'
sudo ufw allow 8899/tcp comment 'CA TSA'
sudo ufw allow 8887/tcp comment 'CA ACME'
sudo ufw enable
sudo ufw status
```

**Trên máy Security Server:**

```bash
sudo ufw allow 4000/tcp comment 'Security Server UI'
sudo ufw allow 8080/tcp comment 'Proxy HTTP'
sudo ufw allow 8443/tcp comment 'Proxy HTTPS'
sudo ufw allow 5500/tcp comment 'Message exchange'
sudo ufw allow 5577/tcp comment 'OCSP'
sudo ufw enable
sudo ufw status
```

#### CentOS/RHEL firewalld

**Trên máy Central Server:**

```bash
sudo firewall-cmd --permanent --add-port=4000/tcp
sudo firewall-cmd --permanent --add-port=4200/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=8443/tcp
sudo firewall-cmd --permanent --add-port=5500/tcp
sudo firewall-cmd --permanent --add-port=5577/tcp
sudo firewall-cmd --permanent --add-port=8888/tcp
sudo firewall-cmd --permanent --add-port=8899/tcp
sudo firewall-cmd --permanent --add-port=8887/tcp
sudo firewall-cmd --reload
```

**Trên máy Security Server:**

```bash
sudo firewall-cmd --permanent --add-port=4000/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=8443/tcp
sudo firewall-cmd --permanent --add-port=5500/tcp
sudo firewall-cmd --permanent --add-port=5577/tcp
sudo firewall-cmd --reload
```

### Cấu hình DNS (khuyến nghị)

#### Sử dụng /etc/hosts (Đơn giản)

**Trên máy Security Server:**

```bash
sudo nano /etc/hosts

# Thêm:
192.168.1.10    cs cs.xroad.local
192.168.1.10    testca testca.xroad.local
192.168.1.10    issoap issoap.xroad.local
192.168.1.10    isrest isrest.xroad.local
```

#### Sử dụng DNS Server (Production)

Cấu hình DNS server với các A records:
```
cs.xroad.local      A    192.168.1.10
testca.xroad.local  A    192.168.1.10
ss1.xroad.local     A    192.168.1.20
ss2.xroad.local     A    192.168.1.30
```

### Testing Network Connectivity

```bash
# Từ Security Server machine

# Test ping
ping -c 4 192.168.1.10

# Test TCP connectivity
nc -zv 192.168.1.10 4000
nc -zv 192.168.1.10 8888

# Test HTTPS endpoint
curl -k -v https://192.168.1.10:4000

# Test DNS resolution (nếu dùng DNS)
nslookup cs.xroad.local
dig cs.xroad.local
```

---

## 🛠️ Quản lý và bảo trì

### Kiểm tra trạng thái

```bash
# Xem status
docker compose ps

# Xem logs
docker compose logs -f

# Logs của service cụ thể
docker compose logs -f cs
docker compose logs -f ss0
docker compose logs -f ss
```

### Restart services

```bash
# Restart tất cả
./start.sh

# Restart service cụ thể
docker compose restart cs
docker compose restart ss
```

### Dừng services

```bash
# Dừng nhưng giữ dữ liệu
./stop.sh

# Dừng và xóa containers
docker compose down

# Dừng và xóa tất cả (bao gồm volumes)
docker compose down -v
```

### Backup dữ liệu

#### Dữ liệu được lưu tại:

**Central Server:**
```
/etc/xroad/cs
/var/lib/xroad/cs
/var/lib/postgresql/cs
/etc/xroad/ss0
/var/lib/xroad/ss0
/var/lib/postgresql/ss0
```

**Security Server:**
```
/etc/xroad/ss
/var/lib/xroad/ss
/var/lib/postgresql/ss
```

#### Backup commands:

```bash
# Tạo backup
sudo tar -czf xroad-cs-backup-$(date +%Y%m%d).tar.gz \
    /etc/xroad/cs \
    /var/lib/xroad/cs \
    /var/lib/postgresql/cs

# Restore
sudo tar -xzf xroad-cs-backup-20240101.tar.gz -C /
```

### Update/Upgrade

```bash
# Pull images mới nhất
docker compose pull

# Rebuild và restart
docker compose up -d --build
```

### Monitoring

```bash
# Resource usage
docker stats

# Disk usage
docker system df

# Network connections
sudo netstat -tulpn | grep -E ':(4000|8080|5500|8888)'

# Monitor with tcpdump
sudo tcpdump -i any port 5500
```

---

## 🐛 Khắc phục sự cố

### Services không healthy

```bash
# Kiểm tra logs
docker compose logs [service_name]

# Kiểm tra health status
docker inspect [container_name] | grep -A 20 Health

# Restart service
docker compose restart [service_name]

# Recreate container
docker compose up -d --force-recreate [service_name]
```

### Không kết nối được giữa SS và CS

#### 1. Kiểm tra network connectivity

```bash
# Từ máy SS
ping [CS_IP]
curl -k https://[CS_IP]:4000
telnet [CS_IP] 4000
traceroute [CS_IP]
```

#### 2. Kiểm tra firewall

```bash
sudo ufw status
sudo iptables -L -n
```

#### 3. Kiểm tra extra_hosts

```bash
docker compose config | grep extra_hosts
docker exec ss cat /etc/hosts
```

#### 4. Test từ trong container

```bash
docker exec ss ping -c 4 cs
docker exec ss curl -k https://cs:4000
docker exec ss nslookup cs
```

### Permission denied trên volumes

```bash
# Fix ownership (UID 999 = xroad user)
sudo chown -R 999:999 /etc/xroad/cs /var/lib/xroad/cs
sudo chown -R 999:999 /etc/xroad/ss /var/lib/xroad/ss

# Fix permissions
sudo chmod -R 755 /etc/xroad/cs
sudo chmod -R 700 /var/lib/xroad/cs
```

### Database connection issues

```bash
# Kiểm tra PostgreSQL
docker compose exec cs pg_isready
docker compose exec ss pg_isready

# Xem PostgreSQL logs
docker compose logs cs | grep postgres
docker compose logs ss | grep postgres

# Restart database
docker compose restart cs
docker compose restart ss
```

### API Token không hoạt động

```bash
# Lấy lại token
docker exec cs cat /etc/xroad/conf.d/local.ini | grep api-token

# Verify token format (32 ký tự alphanumeric)
echo -n "your-token" | wc -c

# Check token trong database
docker exec cs psql -U postgres -d centerui_production -c "SELECT * FROM apikey;"
```

### Port bị chiếm

```bash
# Kiểm tra port đang dùng
sudo netstat -tulpn | grep [port]
sudo lsof -i :[port]

# Kill process
sudo kill -9 [PID]
```

### Container không start

```bash
# Xem lỗi chi tiết
docker compose logs [service]

# Kiểm tra Docker daemon
sudo systemctl status docker

# Kiểm tra disk space
df -h

# Kiểm tra memory
free -h
```

### Global configuration download failed

```bash
# Test từ SS
curl -k http://[CS_IP]:80/internalconf

# Kiểm tra CS có serve được không
docker exec cs curl -k http://localhost:80/internalconf

# Check nginx logs
docker exec cs cat /var/log/nginx/error.log
```

---

## 📐 Kiến trúc mạng chi tiết

### Kết nối giữa các components

#### Central Server → Security Server
- **Management requests**: Port 4000 (HTTPS)
- **Global configuration distribution**: Port 80 (HTTP)

#### Security Server → Central Server
- **Registration**: Port 4000 (HTTPS)
- **Download global configuration**: Port 80 (HTTP)
- **OCSP requests**: Port 8888 (TestCA)
- **TSA requests**: Port 8899 (TestCA)

#### Security Server ↔ Security Server (Message Exchange)
- **Service requests**: Port 5500 (HTTP/HTTPS)
- **OCSP**: Port 5577

### Network Requirements Table

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| SS | CS | 80 | HTTP | Download global config |
| SS | CS | 4000 | HTTPS | Management API |
| SS | TestCA | 8888 | HTTP | OCSP validation |
| SS | TestCA | 8899 | HTTP | Timestamp |
| SS | TestCA | 8887 | HTTP | ACME |
| SS1 | SS2 | 5500 | HTTP/HTTPS | Message exchange |
| SS1 | SS2 | 5577 | HTTP | OCSP |
| Client | SS | 8080 | HTTP | Service requests |
| Client | SS | 8443 | HTTPS | Service requests (secure) |
| Admin | CS | 4000 | HTTPS | Management UI |
| Admin | SS | 4000 | HTTPS | Management UI |

### Docker Networks

#### xroad-central-net (172.30.0.0/24)
- `cs`: 172.30.0.10
- `ss0`: 172.30.0.20
- `testca`: 172.30.0.30
- `mailpit`: 172.30.0.40
- `issoap`: 172.30.0.50
- `isrest`: 172.30.0.60

#### xroad-ss-net (172.31.0.0/24)
- `ss`: 172.31.0.10

### Security Considerations

#### 1. Network Segmentation (Production)

```
┌─────────────────┐
│  Public Network │
│   (Internet)    │
└────────┬────────┘
         │
    ┌────┴────┐
    │ Firewall│
    └────┬────┘
         │
    ┌────┴─────────────────┐
    │   DMZ Network        │
    │  (Security Servers)  │
    │   192.168.10.0/24    │
    └────┬─────────────────┘
         │
    ┌────┴────┐
    │ Firewall│
    └────┬────┘
         │
    ┌────┴──────────────────┐
    │  Internal Network     │
    │  (Central Server)     │
    │   192.168.1.0/24      │
    └───────────────────────┘
```

#### 2. SSL/TLS Certificates
- Sử dụng valid certificates trong production
- Test CA chỉ dùng cho development/testing
- Certificate pinning cho enhanced security

#### 3. Access Control
```bash
# Hạn chế access đến management UIs
sudo ufw allow from 192.168.1.0/24 to any port 4000
sudo ufw deny from any to any port 4000
```

#### 4. VPN/Tunnel
Đối với deployment qua Internet:
- WireGuard
- OpenVPN
- IPSec VPN

---

## 📝 Lưu ý quan trọng

### 1. Security trong Production

- ⚠️ Thay đổi default passwords và PINs
- ⚠️ Sử dụng strong token PINs (không dùng `Secret1234`)
- ⚠️ Cấu hình HTTPS với certificates hợp lệ
- ⚠️ Hạn chế access với firewall rules chính xác
- ⚠️ Disable test services (issoap, isrest) trong production
- ⚠️ Regular security updates

### 2. Network Requirements

- Central Server và Security Server phải reach được nhau
- DNS resolution hoặc hosts file cần cấu hình đúng
- NTP synchronization giữa các máy (quan trọng!)
- Stable network connection (low latency)

### 3. Volumes và Data Persistence

- Dữ liệu được lưu trong host directories
- Backup thường xuyên các thư mục quan trọng
- Không xóa volumes khi down containers nếu muốn giữ data
- Test restore procedure thường xuyên

### 4. Resource Allocation

- Central Server cần nhiều tài nguyên hơn Security Server
- Monitor resource usage: CPU, RAM, Disk I/O
- Scale vertically (tăng resources) khi cần
- Scale horizontally (thêm SS) để distribute load

### 5. Monitoring và Logging

- Setup monitoring (Prometheus, Grafana)
- Centralized logging (ELK, Loki)
- Alert on critical errors
- Monitor certificate expiration

---

## 🔥 Lệnh thường dùng

```bash
# Xem logs
docker compose logs -f
docker compose logs -f [service_name]

# Xem trạng thái
docker compose ps

# Restart service
docker compose restart [service_name]

# Dừng tất cả
./stop.sh
docker compose down

# Xóa tất cả (kể cả data)
docker compose down -v

# Exec vào container
docker exec -it cs bash
docker exec -it ss bash

# Xem resource usage
docker stats

# Lấy API token
docker exec cs cat /etc/xroad/conf.d/local.ini | grep api-token

# Check health
docker inspect cs | grep -A 20 Health

# View PostgreSQL
docker exec cs psql -U postgres -d centerui_production

# Backup
sudo tar -czf backup-$(date +%Y%m%d).tar.gz /etc/xroad /var/lib/xroad

# Network test từ container
docker exec ss ping cs
docker exec ss curl -k https://cs:4000
```

---

## 📚 Tài liệu tham khảo

- [X-Road Official Documentation](https://github.com/nordic-institute/X-Road)
- [X-Road Architecture](https://github.com/nordic-institute/X-Road/blob/develop/doc/Architecture/arc-g_x-road_arhitecture.md)
- [X-Road Installation Guide](https://github.com/nordic-institute/X-Road/blob/develop/doc/Manuals/ig-ss_x-road_v6_security_server_installation_guide.md)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

## 🤝 Support và Troubleshooting

### Kiểm tra khi gặp vấn đề

1. **Logs**: `docker compose logs`
2. **Health status**: `docker compose ps`
3. **Network**: Test connectivity giữa các máy
4. **Firewall**: Verify rules
5. **Disk space**: `df -h`
6. **Memory**: `free -h`

### Common Issues Quick Reference

| Vấn đề | Giải pháp |
|--------|-----------|
| Services không healthy | Check logs, restart service |
| Không kết nối được SS-CS | Verify network, firewall, extra_hosts |
| Permission denied | `sudo chown -R 999:999 /etc/xroad /var/lib/xroad` |
| Database issues | Check pg_isready, restart container |
| API token không work | Lấy lại token từ CS |
| Port bị chiếm | `sudo lsof -i :[port]`, kill process |

---

## 📊 So sánh với setup khác

| Aspect | xrd-dev-stack (gốc) | multi-host-stack (này) |
|--------|---------------------|------------------------|
| **Deploy** | 1 máy duy nhất | Nhiều máy khác nhau |
| **Ports** | Không export | Exported đầy đủ |
| **Network** | Single bridge | Multiple bridges + routing |
| **Volumes** | Docker volumes | Host directories (persistent) |
| **Use case** | Development | Production/Multi-host |
| **Services** | Tất cả trong 1 compose | Tách riêng theo vai trò |
| **Scalability** | Không scale | Dễ dàng thêm SS |
| **Security** | Basic | Production-ready |

---

## 📄 License

X-Road là open source software được phát hành theo MIT License. Tham khảo LICENSE trong repository chính của X-Road.

---

## ✅ Validation

Setup này đã được test và validate với:
- ✅ Docker 24.x
- ✅ Docker Compose 2.24.x
- ✅ Ubuntu 22.04 LTS
- ✅ Network connectivity giữa 2+ máy
- ✅ Firewall rules
- ✅ Multi-host deployment

**Thời gian triển khai ước tính**: 10-15 phút (bao gồm thời gian đợi services healthy)

---

**Tạo bởi**: AI Assistant  
**Ngày**: 2025-10-21  
**Version**: 1.0  
**Dựa trên**: X-Road official docker setup
