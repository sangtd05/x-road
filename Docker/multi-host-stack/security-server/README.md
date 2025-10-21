# Security Server Deployment

Hướng dẫn triển khai Security Server cho X-Road multi-host setup.

## 📦 Services bao gồm

- **ss**: Security Server

## 🚀 Khởi động nhanh

```bash
# 1. Copy file cấu hình
cp .env.example .env

# 2. Chỉnh sửa cấu hình với thông tin Central Server
nano .env

# 3. Cấu hình kết nối
# Cập nhật CS_HOST với IP/hostname thực tế của máy Central Server
CS_HOST=192.168.1.10  # Thay bằng IP thực tế

# 4. Khởi động service
chmod +x *.sh
./start.sh
```

## ⚙️ Cấu hình file .env

**QUAN TRỌNG**: Bạn cần cấu hình các thông tin sau trong file `.env`:

```bash
# IP hoặc hostname của máy Central Server
CS_HOST=192.168.1.10

# Các services khác cũng trên máy CS
CA_HOST=192.168.1.10
ISSOAP_HOST=192.168.1.10  # Nếu cần dùng test services
ISREST_HOST=192.168.1.10
```

## 🔑 Thông tin truy cập

### Security Server
- URL: https://localhost:4000
- Username: `xrd-sys`
- Password: `secret`

## 📝 Các bước sau khi khởi động

1. **Truy cập Security Server UI**
   - Mở https://localhost:4000

2. **Initialize Software Token**
   - Nhập PIN code: `Secret1234` (hoặc theo cấu hình trong .env)

3. **Configure Server**
   - Instance identifier: `DEV` (phải giống với CS)
   - Member class: Chọn class đã tạo ở Central Server
   - Member code: Mã định danh tổ chức của bạn
   - Security server code: Mã định danh server (VD: `SS1`, `SS2`)

4. **Generate Keys**
   - Generate signing key
   - Generate authentication key và CSR

5. **Register with Central Server**
   - Central Server address: `https://[IP_CS]:4000`
   - Submit registration request

6. **Get API Token from Central Server administrator**
   - Cần API token từ Central Server
   - Administrator của CS có thể lấy bằng:
     ```bash
     docker exec cs cat /etc/xroad/conf.d/local.ini | grep api-token
     ```

7. **Complete registration on Central Server**
   - Administrator của CS cần approve registration request

8. **Configure subsystems and services**
   - Thêm subsystems
   - Đăng ký services
   - Cấu hình access rights

## 🌐 Kiểm tra kết nối đến Central Server

Trước khi khởi động, đảm bảo có thể kết nối đến Central Server:

```bash
# Test network connectivity
ping [CS_IP]

# Test HTTPS connectivity
curl -k https://[CS_IP]:4000

# Test specific ports
telnet [CS_IP] 4000
telnet [CS_IP] 8888  # TestCA
```

## 🛑 Dừng services

```bash
./stop.sh
```

## 📊 Kiểm tra trạng thái

```bash
docker compose ps
docker compose logs -f ss
```

## 🔧 Ports được export

| Port | Service | Mô tả |
|------|---------|-------|
| 4000 | ss | Security Server UI |
| 8080 | ss | Proxy HTTP |
| 8443 | ss | Proxy HTTPS |
| 5500 | ss | Message exchange |
| 5577 | ss | OCSP |

## 🔍 Troubleshooting

### Không kết nối được đến Central Server

1. Kiểm tra `.env` file có CS_HOST đúng chưa
2. Kiểm tra firewall trên cả 2 máy
3. Kiểm tra network connectivity
4. Kiểm tra extra_hosts trong docker-compose:
   ```bash
   docker compose config | grep extra_hosts
   ```

### Registration bị reject

1. Kiểm tra instance identifier có giống với CS không
2. Kiểm tra member class và member code có tồn tại ở CS không
3. Liên hệ administrator của Central Server để approve request

### Services không healthy

```bash
# Xem logs chi tiết
docker compose logs ss

# Restart service
docker compose restart ss
```

