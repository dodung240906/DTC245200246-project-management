# HỆ THỐNG QUẢN LÝ DỰ ÁN (PROJECT MANAGEMENT SYSTEM)

- Mã số sinh viên: DTC245200246
- Học phần: Triển khai và Quản trị Hệ thống Phần mềm
- Địa chỉ IP hệ thống: 192.168.23.128

## 1. Thành phần hệ thống
- Ứng dụng Web: Node.js (Express) quản lý Dự án, Công việc (Task), Thành viên.
- Cơ sở dữ liệu: PostgreSQL 15 + pgAdmin 4.
- Reverse Proxy: Nginx bọc HTTPS tự ký (TLSv1.2/1.3) + Security Headers.
- Giám sát (Monitoring): Prometheus + Grafana + Postgres Exporter + cAdvisor.
- Quản lý Log tập trung: Loki + Promtail + Truy vấn LogQL.
- Hardening: Non-root container (USER node), Network Isolation (frontend_net/backend_net), Least-Privilege DB User (pm_app_user), .env strong passwords.

## 2. Đường dẫn truy cập dịch vụ
- Web Quản lý Dự án (HTTPS/HTTP): https://192.168.23.128 hoặc http://192.168.23.128
- pgAdmin 4: http://192.168.23.128:5050
- Prometheus: http://192.168.23.128:9090/targets
- Grafana: http://192.168.23.128:3001
