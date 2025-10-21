# X-Road Multi-Host Network Architecture

Tài liệu mô tả kiến trúc mạng và cách giao tiếp giữa các máy trong setup multi-host.

## 🏗️ Sơ đồ kiến trúc tổng quan

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
│  │  │   :8888     │  │   :8025      │     │          │
│  │  └─────────────┘  └──────────────┘     │          │
│  │                                          │          │
│  │  ┌─────────────┐  ┌──────────────┐     │          │
│  │  │   issoap    │  │   isrest     │     │          │
│  │  │ 172.30.0.50 │  │ 172.30.0.60  │     │          │
│  │  └─────────────┘  └──────────────┘     │          │
│  └──────────────────────────────────────────┘          │
│                                                          │
│  Exposed Ports:                                          │
│  - 4000: Central Server UI                              │
│  - 4200: Management SS UI                               │
│  - 8080, 8443: Proxy                                    │
│  - 5500, 5577: X-Road messaging                         │
│  - 8888, 8899, 8887: Test CA                           │
└─────────────────────────────────────────────────────────┘
                            │
                            │ Network
                            │ (Internet/LAN)
                            │
┌─────────────────────────────────────────────────────────┐
│                  Máy Security Server 1                   │
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
│  │    cs -> 192.168.1.10                   │          │
│  │    testca -> 192.168.1.10               │          │
│  └──────────────────────────────────────────┘          │
│                                                          │
│  Exposed Ports:                                          │
│  - 4000: Security Server UI                             │
│  - 8080, 8443: Proxy                                    │
│  - 5500, 5577: X-Road messaging                         │
└─────────────────────────────────────────────────────────┘
```

## 🔌 Kết nối giữa các máy

### Central Server → Security Server
- **Management requests**: Port 4000 (HTTPS)
- **Global configuration distribution**: Port 80 (HTTP)

### Security Server → Central Server
- **Registration**: Port 4000 (HTTPS)
- **Download global configuration**: Port 80 (HTTP)
- **OCSP requests**: Port 8888 (TestCA)
- **TSA requests**: Port 8899 (TestCA)

### Security Server → Security Server (Message Exchange)
- **Service requests**: Port 5500 (HTTP/HTTPS)
- **OCSP**: Port 5577

## 📡 Network Requirements

### 1. Connectivity Requirements

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
| Client | SS | 8443 | HTTPS | Service requests |
| Admin | CS | 4000 | HTTPS | Management UI |
| Admin | SS | 4000 | HTTPS | Management UI |

### 2. DNS Resolution

#### Sử dụng /etc/hosts (Đơn giản)

**Trên máy Security Server:**
```bash
sudo nano /etc/hosts

# Thêm các dòng sau:
192.168.1.10    cs cs.xroad.local
192.168.1.10    testca testca.xroad.local
192.168.1.10    issoap issoap.xroad.local
192.168.1.10    isrest isrest.xroad.local
```

#### Sử dụng DNS Server (Khuyến nghị cho production)

Cấu hình DNS server với các records:
```
cs.xroad.local      A    192.168.1.10
testca.xroad.local  A    192.168.1.10
ss1.xroad.local     A    192.168.1.20
ss2.xroad.local     A    192.168.1.30
```

### 3. Firewall Configuration

#### Ubuntu UFW

**Trên máy Central Server:**
```bash
# Allow Web UIs
sudo ufw allow 4000/tcp comment 'Central Server UI'
sudo ufw allow 4200/tcp comment 'Management SS UI'

# Allow Proxy
sudo ufw allow 8080/tcp comment 'Proxy HTTP'
sudo ufw allow 8443/tcp comment 'Proxy HTTPS'

# Allow X-Road messaging
sudo ufw allow 5500/tcp comment 'Message exchange'
sudo ufw allow 5577/tcp comment 'OCSP'

# Allow Test CA
sudo ufw allow 8888/tcp comment 'CA OCSP'
sudo ufw allow 8899/tcp comment 'CA TSA'
sudo ufw allow 8887/tcp comment 'CA ACME'

# Allow global config download
sudo ufw allow 80/tcp comment 'Global config'

# Enable firewall
sudo ufw enable
sudo ufw status
```

**Trên máy Security Server:**
```bash
# Allow Web UI
sudo ufw allow 4000/tcp comment 'Security Server UI'

# Allow Proxy
sudo ufw allow 8080/tcp comment 'Proxy HTTP'
sudo ufw allow 8443/tcp comment 'Proxy HTTPS'

# Allow X-Road messaging
sudo ufw allow 5500/tcp comment 'Message exchange'
sudo ufw allow 5577/tcp comment 'OCSP'

# Enable firewall
sudo ufw enable
sudo ufw status
```

#### CentOS/RHEL firewalld

**Trên máy Central Server:**
```bash
sudo firewall-cmd --permanent --add-port=4000/tcp
sudo firewall-cmd --permanent --add-port=4200/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=8443/tcp
sudo firewall-cmd --permanent --add-port=5500/tcp
sudo firewall-cmd --permanent --add-port=5577/tcp
sudo firewall-cmd --permanent --add-port=8888/tcp
sudo firewall-cmd --permanent --add-port=8899/tcp
sudo firewall-cmd --permanent --add-port=8887/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
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

## 🔒 Security Considerations

### 1. Network Segmentation

**Khuyến nghị cho production:**

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

### 2. SSL/TLS Certificates

- Sử dụng valid certificates trong production
- Test CA chỉ dùng cho development/testing
- Certificate pinning cho enhanced security

### 3. Access Control

- Hạn chế access đến management UIs (port 4000)
- Chỉ allow IPs cụ thể:
  ```bash
  sudo ufw allow from 192.168.1.0/24 to any port 4000
  ```

### 4. VPN/Tunnel

Đối với deployment qua Internet, sử dụng VPN:
- WireGuard
- OpenVPN
- IPSec

## 🧪 Testing Network Connectivity

### Basic Connectivity Tests

```bash
# Từ Security Server machine

# Test ping
ping -c 4 192.168.1.10

# Test TCP connectivity
nc -zv 192.168.1.10 4000
nc -zv 192.168.1.10 8888

# Test HTTPS endpoint
curl -k -v https://192.168.1.10:4000

# Test DNS resolution
nslookup cs.xroad.local
dig cs.xroad.local
```

### X-Road Specific Tests

```bash
# Test global configuration download
curl -k http://192.168.1.10/internalconf

# Test OCSP
curl -k http://192.168.1.10:8888/testca/certs

# Test from inside Security Server container
docker exec ss ping -c 4 cs
docker exec ss curl -k https://cs:4000
```

### Network Monitoring

```bash
# Monitor connections
sudo netstat -tulpn | grep -E ':(4000|8080|5500|8888)'

# Monitor with tcpdump
sudo tcpdump -i any port 5500

# Check Docker network
docker network inspect xroad-central-net
docker network inspect xroad-ss-net
```

## 📈 Performance Optimization

### 1. MTU Settings

```bash
# Check MTU
ip link show

# Set MTU for Docker network
docker network create --opt com.docker.network.driver.mtu=1500 xroad-net
```

### 2. TCP Tuning

```bash
# /etc/sysctl.conf
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# Apply
sudo sysctl -p
```

## 🔍 Troubleshooting Network Issues

### Issue: Security Server không kết nối được đến Central Server

**Kiểm tra:**
1. Network connectivity: `ping [CS_IP]`
2. Port accessibility: `telnet [CS_IP] 4000`
3. Firewall rules: `sudo ufw status`
4. Docker extra_hosts: `docker compose config`
5. DNS resolution: `nslookup cs`

### Issue: Containers không thể resolve hostname

**Solution:**
```bash
# Verify extra_hosts trong docker-compose.yml
docker compose config | grep extra_hosts

# Hoặc thêm vào host system
sudo nano /etc/hosts
```

### Issue: Connection timeout

**Kiểm tra:**
```bash
# Test từ host machine
curl -k -v https://[CS_IP]:4000

# Test từ trong container
docker exec ss curl -k -v https://cs:4000

# Check routing
traceroute [CS_IP]
```

## 📋 Network Checklist

Trước khi deployment, verify:

- [ ] Tất cả máy có IP addresses cố định
- [ ] DNS/hosts file được cấu hình
- [ ] Firewall rules được thiết lập
- [ ] Network connectivity giữa các máy đã test
- [ ] Ports cần thiết không bị block
- [ ] NTP synchronized giữa các máy
- [ ] SSL certificates hợp lệ (nếu production)
- [ ] Backup network plan đã ready

## 🌐 Example Multi-Region Setup

```
Region 1 (Asia)                Region 2 (Europe)
┌─────────────────┐           ┌─────────────────┐
│  Central Server │           │ Security Server │
│  10.1.0.10      │◄─────────►│  10.2.0.10      │
└─────────────────┘           └─────────────────┘
         │                             │
         ▼                             ▼
┌─────────────────┐           ┌─────────────────┐
│ Security Server │           │ Security Server │
│  10.1.0.20      │           │  10.2.0.20      │
└─────────────────┘           └─────────────────┘
```

Sử dụng VPN tunnel hoặc dedicated connection giữa các region.

