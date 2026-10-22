#!/bin/bash
set -e

# 1. Tắt triệt để Nginx/Apache mặc định của Ubuntu để không tranh cổng 80/443
systemctl stop nginx apache2 2>/dev/null || true
systemctl disable nginx apache2 2>/dev/null || true
fuser -k 80/tcp 443/tcp 2>/dev/null || true

# 2. Xóa container pm_nginx cũ bị lỗi và tạo lại chứng chỉ SSL cho IP 172.20.10.2
docker rm -f pm_nginx 2>/dev/null || true
rm -rf nginx
mkdir -p nginx/certs

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/certs/selfsigned.key \
  -out nginx/certs/selfsigned.crt \
  -subj "/C=VN/ST=ThaiNguyen/L=ThaiNguyen/O=ICTU/OU=IT/CN=172.20.10.2"

chmod 644 nginx/certs/selfsigned.key nginx/certs/selfsigned.crt

# 3. Ghi lại file nginx/nginx.conf chuẩn 100%
cat << 'NGINX_EOF' > nginx/nginx.conf
events {
    worker_connections 1024;
}

http {
    server_tokens off;

    upstream pm_backend {
        server app:3000;
    }

    server {
        listen 80;
        server_name _;
        return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl;
        server_name _;

        ssl_certificate /etc/nginx/certs/selfsigned.crt;
        ssl_certificate_key /etc/nginx/certs/selfsigned.key;
        ssl_protocols TLSv1.2 TLSv1.3;

        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;

        location / {
            proxy_pass http://pm_backend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
NGINX_EOF

# 4. Làm sạch khoảng trắng ẩn trong docker-compose.yml và bật lại pm_nginx
sed -i 's/\xc2\xa0/ /g' docker-compose.yml nginx/nginx.conf
docker compose up -d --force-recreate nginx
sleep 3

echo "=== KIEM TRA TRANG THAI PM_NGINX ==="
docker ps --filter "name=pm_nginx"

echo "=== KIEM TRA KET NOI HTTPS://172.20.10.2 ==="
curl -k -I https://172.20.10.2
