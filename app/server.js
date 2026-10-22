const express = require('express');
const { Pool } = require('pg');
const path = require('path');
const client = require('prom-client');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const pool = new Pool({
  host: process.env.DB_HOST || 'postgres',
  port: process.env.DB_PORT || 5432,
  database: process.env.POSTGRES_DB || 'pm_database',
  user: process.env.APP_DB_USER || 'pm_app_user',
  password: process.env.APP_DB_PASSWORD || 'App_Us3r#2026!SecurePass',
});

const register = new client.Registry();
client.collectDefaultMetrics({ register, prefix: 'pm_app_' });

const httpRequestCounter = new client.Counter({
  name: 'pm_http_requests_total',
  help: 'Tong so HTTP request vao ung dung Quan ly Du an',
  labelNames: ['method', 'route', 'status'],
  registers: [register],
});

const httpRequestDuration = new client.Histogram({
  name: 'pm_http_request_duration_seconds',
  help: 'Thoi gian xu ly HTTP request (giay)',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.01, 0.05, 0.1, 0.3, 0.5, 1, 2],
  registers: [register],
});

app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;
    httpRequestCounter.inc({ method: req.method, route, status: res.statusCode });
    httpRequestDuration.observe({ method: req.method, route, status: res.statusCode }, duration);

    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      level: res.statusCode >= 400 ? 'error' : 'info',
      service: 'project-management-app',
      student_id: 'DTC245200246',
      method: req.method,
      path: req.originalUrl,
      status: res.statusCode,
      duration_ms: Math.round(duration * 1000),
      ip: req.headers['x-real-ip'] || req.ip,
    }));
  });
  next();
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.get('/api/health', async (req, res) => {
  try {
    const result = await pool.query('SELECT current_user, current_database(), NOW() as server_time');
    res.json({ status: 'OK', db_connected: true, info: result.rows[0] });
  } catch (err) {
    console.error(JSON.stringify({ level: 'error', msg: 'Database connection failed', error: err.message }));
    res.status(500).json({ status: 'ERROR', db_connected: false, error: err.message });
  }
});

app.get('/api/dashboard', async (req, res) => {
  try {
    const projects = await pool.query('SELECT * FROM projects ORDER BY id DESC');
    const members = await pool.query('SELECT * FROM members ORDER BY id DESC');
    const tasks = await pool.query(`
      SELECT t.*, p.name as project_name, m.full_name as member_name
      FROM tasks t
      LEFT JOIN projects p ON t.project_id = p.id
      LEFT JOIN members m ON t.member_id = m.id
      ORDER BY t.id DESC
    `);
    res.json({ projects: projects.rows, members: members.rows, tasks: tasks.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/projects', async (req, res) => {
  const { name, description, status } = req.body;
  if (!name) return res.status(400).json({ error: 'Ten du an khong duoc de trong' });
  try {
    const result = await pool.query(
      'INSERT INTO projects (name, description, status) VALUES ($1, $2, $3) RETURNING *',
      [name, description || '', status || 'In Progress']
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/members', async (req, res) => {
  const { full_name, email, role } = req.body;
  if (!full_name || !email) return res.status(400).json({ error: 'Ho ten va Email la bat buoc' });
  try {
    const result = await pool.query(
      'INSERT INTO members (full_name, email, role) VALUES ($1, $2, $3) RETURNING *',
      [full_name, email, role || 'Developer']
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/tasks', async (req, res) => {
  const { project_id, member_id, title, priority, status } = req.body;
  if (!title) return res.status(400).json({ error: 'Tieu de cong viec la bat buoc' });
  try {
    const result = await pool.query(
      'INSERT INTO tasks (project_id, member_id, title, priority, status) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [project_id || null, member_id || null, title, priority || 'Medium', status || 'Todo']
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/simulate-error', (req, res) => {
  console.error(JSON.stringify({
    timestamp: new Date().toISOString(),
    level: 'error',
    service: 'project-management-app',
    student_id: 'DTC245200246',
    msg: 'Simulated permission error for LogQL demonstration',
    code: 'ERR_PROJECT_LOCKED'
  }));
  res.status(500).json({ error: 'Simulated error logged for Loki/LogQL testing' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    level: 'info',
    msg: `Project Management Server listening on port ${PORT}`
  }));
});
