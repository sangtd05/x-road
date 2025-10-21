# Central Service Deployment

Hướng dẫn triển khai Central Server service cho X-Road multi-host setup.

## 📦 Services bao gồm

- **cs**: Central Server
- **ss0**: Management Security Server
- **testca**: Test Certificate Authority
- **mailpit**: Mail server cho notifications
- **issoap**: Example SOAP service
- **isrest**: Example REST service (Wiremock)

## 🚀 Khởi động nhanh

```bash
# 1. Copy file cấu hình
cp .env.example .env

# 2. Chỉnh sửa cấu hình (nếu cần)
nano .env

# 3. Khởi động services
chmod +x *.sh
./start.sh

# 4. Lấy API token để đăng ký Security Servers
docker exec cs cat /etc/xroad/conf.d/local.ini | grep api-token
```

## 🔑 Thông tin truy cập

### Central Server
- URL: https://localhost:4000
- Username: `xrd-sys`
- Password: `secret`

### Management Security Server
- URL: https://localhost:4200
- Username: `xrd-sys`
- Password: `secret`

### Mail UI
- URL: http://localhost:8025

### Test Services
- SOAP Service: http://localhost:4600
- REST Service: http://localhost:4500

## 📝 Các bước sau khi khởi động

1. Truy cập Central Server UI
2. Hoàn thành wizard khởi tạo
3. Tạo member classes
4. Lấy API token
5. Chia sẻ API token với administrators của Security Servers

## 🛑 Dừng services

```bash
./stop.sh
```

## 📊 Kiểm tra trạng thái

```bash
docker compose ps
docker compose logs -f
```

## 🔧 Ports được export

| Port | Service | Mô tả |
|------|---------|-------|
| 4000 | cs | Central Server UI |
| 4200 | ss0 | Management SS UI |
| 5432 | cs | PostgreSQL |
| 8080 | ss0 | Proxy HTTP |
| 8443 | ss0 | Proxy HTTPS |
| 5500 | ss0 | Message exchange |
| 5577 | ss0 | OCSP |
| 8888 | testca | OCSP |
| 8899 | testca | TSA |
| 8887 | testca | ACME |
| 8025 | mailpit | Mail UI |
| 4600 | issoap | SOAP service |
| 4500 | isrest | REST service |

