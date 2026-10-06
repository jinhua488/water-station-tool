// 废水站运营管理系统 - 后端 API 入口
// 部署目标：Railway / Render / 任何 Node 环境
// 数据库：Supabase (PostgreSQL)

const express = require('express')
const cors = require('cors')
const rateLimit = require('express-rate-limit')
const { Pool } = require('pg')
const bcrypt = require('bcryptjs')
const jwt = require('jsonwebtoken')

const app = express()
const PORT = process.env.PORT || 3001

// ==================== 中间件 ====================
app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || '*', // Vercel 域名
  credentials: true
}))
app.use(express.json({ limit: '10mb' })) // 签名图片较大，放宽限制

// 登录限流：5 次/15 分钟
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: { error: '登录尝试次数过多，请 15 分钟后再试' },
  standardHeaders: true
})

// ==================== 数据库 ====================
const pool = new Pool({
  connectionString: process.env.DATABASE_URL, // Supabase 连接串
  ssl: process.env.DATABASE_SSL === 'false' ? false : { rejectUnauthorized: false }
})

// ==================== JWT 认证 ====================
const JWT_SECRET = process.env.JWT_SECRET || 'water-station-secret-change-me'

function auth(roles = []) {
  return (req, res, next) => {
    const token = req.headers.authorization?.replace('Bearer ', '')
    if (!token) return res.status(401).json({ error: '未登录' })
    try {
      const payload = jwt.verify(token, JWT_SECRET)
      if (roles.length && !roles.includes(payload.role)) {
        return res.status(403).json({ error: '无权限' })
      }
      req.user = payload
      next()
    } catch {
      return res.status(401).json({ error: '登录已过期' })
    }
  }
}

// ==================== 认证接口 ====================
app.post('/api/auth/login', loginLimiter, async (req, res) => {
  const { username, password } = req.body
  try {
    const { rows } = await pool.query(
      'SELECT id, username, name, role, password_hash FROM users WHERE username = $1',
      [username]
    )
    const user = rows[0]
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      return res.status(401).json({ error: '用户名或密码错误' })
    }
    const token = jwt.sign(
      { id: user.id, username: user.username, name: user.name, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    )
    res.json({ token, user: { id: user.id, username: user.username, name: user.name, role: user.role } })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

// ==================== 运行日报 ====================
// 新增/更新日报
app.post('/api/daily-record', auth(['admin', 'operator']), async (req, res) => {
  const { record_date, shift, ...fields } = req.body
  try {
    const { rows } = await pool.query(`
      INSERT INTO daily_record (record_date, shift, operator, treated_water, high_conc_waste,
        low_conc_waste, high_conc_cod, low_conc_cod, cod, ph, compliance_status,
        electricity, tap_water, utility_cost, direct_labor, indirect_labor, labor_cost,
        pac, pam, demulsifier, caustic, defoamer, chemical_cost,
        ro_membrane, sludge_bag, consumable_cost, sludge, floor_wash, hazmat_cost,
        seal, impeller, spare_cost, cost_per_ton, signature, sign_time, sign_user, remark, created_by)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34,$35,$36,$37,$38,$39)
      ON CONFLICT (record_date, shift)
      DO UPDATE SET ${Object.keys(fields).map((k, i) => `${k} = $${i + 3}`).join(', ')}
      RETURNING *`,
      [record_date, shift, req.user.name, ...Object.values(fields).map(v => v ?? null)]
    )
    res.json(rows[0])
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

// 日报列表（按月/日期范围）
app.get('/api/daily-record', auth(), async (req, res) => {
  const { start, end } = req.query
  try {
    const { rows } = await pool.query(`
      SELECT * FROM daily_record
      WHERE ($1::date IS NULL OR record_date >= $1)
        AND ($2::date IS NULL OR record_date <= $2)
      ORDER BY record_date DESC, shift`,
      [start || null, end || null]
    )
    res.json(rows)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

// 一键签名（批量更新）
app.post('/api/daily-record/sign', auth(['admin', 'operator']), async (req, res) => {
  const { ids, signature } = req.body
  if (!ids?.length || !signature) {
    return res.status(400).json({ error: '参数不完整' })
  }
  try {
    const { rowCount } = await pool.query(`
      UPDATE daily_record SET signature = $1, sign_time = NOW(), sign_user = $2
      WHERE id = ANY($3) AND signature IS NULL`,
      [signature, req.user.name, ids]
    )
    res.json({ count: rowCount })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

// ==================== 药剂 / 巡检 / 危废 / 备品（通用 CRUD） ====================
function createCrud(table, roles = ['admin', 'operator']) {
  return {
    list: async (req, res) => {
      try {
        const { rows } = await pool.query(`SELECT * FROM ${table} ORDER BY created_at DESC LIMIT 500`)
        res.json(rows)
      } catch (err) { res.status(500).json({ error: err.message }) }
    },
    create: async (req, res) => {
      try {
        const cols = Object.keys(req.body)
        const vals = cols.map((c, i) => `$${i + 1}`)
        const { rows } = await pool.query(
          `INSERT INTO ${table} (${cols.join(',')}, created_by) VALUES (${vals.join(',')}, $${cols.length + 1}) RETURNING *`,
          [...cols.map(c => req.body[c]), req.user.name]
        )
        res.json(rows[0])
      } catch (err) { res.status(500).json({ error: err.message }) }
    },
    update: async (req, res) => {
      try {
        const cols = Object.keys(req.body)
        const set = cols.map((c, i) => `${c} = $${i + 1}`)
        const { rows } = await pool.query(
          `UPDATE ${table} SET ${set.join(',')}, updated_at = NOW() WHERE id = $${cols.length + 1} RETURNING *`,
          [...cols.map(c => req.body[c]), req.params.id]
        )
        res.json(rows[0])
      } catch (err) { res.status(500).json({ error: err.message }) }
    },
    remove: async (req, res) => {
      try {
        await pool.query(`DELETE FROM ${table} WHERE id = $1`, [req.params.id])
        res.json({ ok: true })
      } catch (err) { res.status(500).json({ error: err.message }) }
    }
  }
}

const chemicalCrud = createCrud('chemical_record')
app.get('/api/chemical-record', auth(), chemicalCrud.list)
app.post('/api/chemical-record', auth(['admin', 'operator']), chemicalCrud.create)
app.put('/api/chemical-record/:id', auth(['admin', 'operator']), chemicalCrud.update)
app.delete('/api/chemical-record/:id', auth(['admin']), chemicalCrud.remove)

const inspectionCrud = createCrud('equipment_inspection')
app.get('/api/equipment-inspection', auth(), inspectionCrud.list)
app.post('/api/equipment-inspection', auth(['admin', 'operator']), inspectionCrud.create)
app.put('/api/equipment-inspection/:id', auth(['admin', 'operator']), inspectionCrud.update)
app.delete('/api/equipment-inspection/:id', auth(['admin']), inspectionCrud.remove)

const wasteCrud = createCrud('waste_record')
app.get('/api/waste-record', auth(), wasteCrud.list)
app.post('/api/waste-record', auth(['admin', 'operator']), wasteCrud.create)
app.put('/api/waste-record/:id', auth(['admin', 'operator']), wasteCrud.update)
app.delete('/api/waste-record/:id', auth(['admin']), wasteCrud.remove)

const spareCrud = createCrud('spare_part_record')
app.get('/api/spare-part-record', auth(), spareCrud.list)
app.post('/api/spare-part-record', auth(['admin', 'operator']), spareCrud.create)
app.put('/api/spare-part-record/:id', auth(['admin', 'operator']), spareCrud.update)
app.delete('/api/spare-part-record/:id', auth(['admin']), spareCrud.remove)

// ==================== 配置 ====================
app.get('/api/config', auth(), async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT config_key, config_value FROM config')
    const config = {}
    rows.forEach(r => { config[r.config_key] = r.config_value })
    res.json(config)
  } catch (err) { res.status(500).json({ error: err.message }) }
})

app.put('/api/config/:key', auth(['admin']), async (req, res) => {
  try {
    const { rows } = await pool.query(`
      INSERT INTO config (config_key, config_value, updated_by, updated_at)
      VALUES ($1, $2, $3, NOW())
      ON CONFLICT (config_key)
      DO UPDATE SET config_value = $2, updated_by = $3, updated_at = NOW()
      RETURNING *`,
      [req.params.key, JSON.stringify(req.body), req.user.name]
    )
    res.json(rows[0])
  } catch (err) { res.status(500).json({ error: err.message }) }
})

// ==================== 健康检查 ====================
app.get('/api/health', (req, res) => res.json({ status: 'ok', time: new Date().toISOString() }))

app.listen(PORT, () => console.log(`✅ 废水站后端运行于 :${PORT}`))