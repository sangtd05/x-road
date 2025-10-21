# 🚀 Quick Start Guide

Hướng dẫn triển khai nhanh X-Road trên nhiều máy.

## Tổng quan nhanh

Bạn cần ít nhất **2 máy**:
- **Máy 1**: Central Server + Management Security Server + Test CA
- **Máy 2+**: Security Server(s) cho các tổ chức thành viên

## ⚡ Triển khai trong 5 phút

### Bước 1: Máy Central Server

```bash
cd X-Road/Docker/multi-host-stack/central-service

# Setup
cp .env.example .env
chmod +x *.sh

# Khởi động
./start.sh

# Đợi 2-3 phút để services healthy
# Lấy API token
docker exec cs cat /etc/xroad/conf.d/local.ini | grep api-token
```

**Ghi lại:**
- IP máy CS: `_________________`
- API Token: `_________________`

### Bước 2: Máy Security Server

```bash
cd X-Road/Docker/multi-host-stack/security-server

# Setup
cp .env.example .env

# Chỉnh sửa .env với IP của máy CS
nano .env
# Thay CS_HOST=192.168.1.10 bằng IP thực tế

# Khởi động
chmod +x *.sh
./start.sh
```

### Bước 3: Cấu hình qua Web UI

**Central Server** (https://[IP_CS]:4000)
1. Login: `xrd-sys` / `secret`
2. Hoàn thành wizard khởi tạo
3. Tạo member classes nếu cần

**Security Server** (https://[IP_SS]:4000)
1. Login: `xrd-sys` / `secret`
2. Initialize software token
3. Configure server (instance, member, subsystem)
4. Generate keys
5. Register với CS (dùng API token từ bước 1)

**Approve trên Central Server**
1. Login vào CS UI
2. Vào "Security Servers"
3. Approve registration request

✅ **Xong!** Security Server đã kết nối với Central Server.

## 📝 Checklist

Trước khi bắt đầu:
- [ ] Docker và Docker Compose đã cài đặt
- [ ] Máy CS và SS có thể ping được nhau
- [ ] Firewall đã cấu hình (xem NETWORK_ARCHITECTURE.md)
- [ ] IP addresses đã note lại

## 🔥 Lệnh thường dùng

```bash
# Xem logs
docker compose logs -f

# Xem trạng thái
docker compose ps

# Restart service
docker compose restart cs

# Dừng tất cả
./stop.sh

# Xóa tất cả (kể cả data)
docker compose down -v
```

## 📚 Tài liệu chi tiết

- [README.md](README.md) - Hướng dẫn đầy đủ
- [NETWORK_ARCHITECTURE.md](NETWORK_ARCHITECTURE.md) - Kiến trúc mạng
- [central-service/README.md](central-service/README.md) - Chi tiết Central Service
- [security-server/README.md](security-server/README.md) - Chi tiết Security Server

## 🆘 Cần trợ giúp?

**Vấn đề thường gặp:**

1. **Services không healthy**
   ```bash
   docker compose logs [service_name]
   ```

2. **SS không kết nối được CS**
   ```bash
   # Kiểm tra từ máy SS
   ping [IP_CS]
   curl -k https://[IP_CS]:4000
   ```

3. **Permission denied**
   ```bash
   sudo chown -R 999:999 /etc/xroad /var/lib/xroad
   ```

4. **Port bị chiếm**
   ```bash
   sudo netstat -tulpn | grep [port]
   sudo lsof -i :[port]
   ```

## 🎯 Mục tiêu setup này

✅ Triển khai trên nhiều máy vật lý/VMs
✅ Network isolation và security
✅ Production-ready architecture
✅ Dễ dàng scale thêm Security Servers
✅ Sử dụng code gốc từ nhà cung cấp
✅ Đầy đủ services (CA, Mail, Test services)

---

**Thời gian triển khai ước tính:** 10-15 phút (đã bao gồm thời gian đợi services healthy)

