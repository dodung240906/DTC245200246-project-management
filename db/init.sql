CREATE TABLE IF NOT EXISTS members (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'Developer',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    status VARCHAR(30) NOT NULL DEFAULT 'In Progress',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    member_id INTEGER REFERENCES members(id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    priority VARCHAR(20) DEFAULT 'Medium',
    status VARCHAR(30) DEFAULT 'Todo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO members (full_name, email, role) VALUES
('Sinh viên DTC245200246', 'dtc245200246@student.edu.vn', 'Project Manager'),
('Trần Thị Bình', 'binh.tran@student.edu.vn', 'Backend Developer'),
('Lê Hoàng Cường', 'cuong.le@student.edu.vn', 'DevOps Engineer')
ON CONFLICT (email) DO NOTHING;

INSERT INTO projects (name, description, status) VALUES
('Đề 14 - Hệ thống Quản lý Dự án (DTC245200246)', 'Triển khai Docker Compose, Nginx, Prometheus, Grafana, Loki', 'In Progress'),
('Ứng dụng Quản lý Kho vận WMS', 'Tối ưu hóa quy trình nhập xuất kho thời gian thực', 'Planning')
ON CONFLICT DO NOTHING;

INSERT INTO tasks (project_id, member_id, title, priority, status) VALUES
(1, 1, 'Cấu hình Nginx Reverse Proxy & HTTPS (DTC245200246)', 'High', 'Done'),
(1, 2, 'Tích hợp Prometheus và Grafana Dashboard', 'High', 'In Progress'),
(1, 3, 'Triển khai Loki, Promtail và Hardening hệ thống', 'Medium', 'Todo');

DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles WHERE rolname = 'pm_app_user') THEN
      CREATE ROLE pm_app_user WITH LOGIN PASSWORD 'App_Us3r#2026!SecurePass';
   END IF;
END
$do$;

GRANT CONNECT ON DATABASE pm_database TO pm_app_user;
GRANT USAGE ON SCHEMA public TO pm_app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO pm_app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO pm_app_user;
