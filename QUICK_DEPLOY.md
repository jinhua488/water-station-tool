# 废水站运营管理系统 - 一键部署指南

> 目标：5 分钟内让系统在外网可访问

---

## 方案选择

| 方案 | 部署时间 | 数据同步 | 多用户 | 推荐场景 |
|------|---------|---------|--------|---------|
| **A. 纯前端** | 5 分钟 | ❌ 仅本地 | ❌ 单设备 | 临时演示/个人使用 |
| **B. 全栈** | 20 分钟 | ✅ 云端 | ✅ 多角色 | 正式生产/团队协作 |

---

## 方案 A：纯前端部署（最快 5 分钟）

### 步骤 1：推送到 GitHub

```bash
cd D:\EHS\water-station-tool
git init
git add .
git commit -m "废水站运营管理系统 v1.0"
git remote add origin https://github.com/你的用户名/water-station-tool.git
git push -u origin main
```

### 步骤 2：Vercel 部署

1. 打开 https://vercel.com → 用 GitHub 账号登录
2. 点击 **Add New Project**
3. 选择 `water-station-tool` 仓库 → **Import**
4. Framework Preset 选 **Vite**
5. 点击 **Deploy** → 等待 2 分钟
6. 获得外网地址：`https://water-station-tool.vercel.app`

### 步骤 3：访问测试

- 电脑/手机浏览器打开 `https://xxx.vercel.app`
- 登录：admin / 123456
- 数据保存在浏览器 localStorage（不同设备不互通）

---

## 方案 B：全栈部署（推荐，20 分钟）

### 前置准备（5 分钟）

注册三个账号（都用 GitHub 登录）：
- [Vercel](https://vercel.com) - 前端托管
- [Railway](https://railway.app) - 后端 API
- [Supabase](https://supabase.com) - 数据库

### 步骤 1：Supabase 建库（5 分钟）

1. 登录 Supabase → **New Project** → 名称 `water-station` → 密码记下来
2. 左侧 **SQL Editor** → **New query**
3. 复制 `supabase-schema.sql` 全部内容 → 粘贴 → **Run**
4. 建表完成后：**Settings → Database → Connection string** → 复制 `postgresql://...` 连接串

### 步骤 2：Railway 部署后端（5 分钟）

1. 登录 Railway → **New Project** → **Deploy from GitHub repo**
2. 选择 `water-station-tool` 仓库
3. Railway 自动识别 `backend/Dockerfile` 构建
4. **Variables** 面板添加：

| 变量 | 值 |
|------|-----|
| `DATABASE_URL` | `postgresql://postgres:你的密码@db.xxx.supabase.co:5432/postgres?sslmode=require` |
| `JWT_SECRET` | `openssl rand -hex 32`（或任意长随机字符串） |
| `CORS_ORIGIN` | `https://xxx.vercel.app`（先留空，等 Vercel 部署后补上） |
| `PORT` | `3001` |

5. 保存后自动部署 → 获得后端地址 `https://xxx.up.railway.app`
6. 测试：浏览器打开 `https://xxx.up.railway.app/api/health` → 应返回 `{"status":"ok"}`

### 步骤 3：Vercel 部署前端（3 分钟）

1. 同方案 A 步骤 2
2. **环境变量** 添加：

| 变量 | 值 |
|------|-----|
| `VITE_API_BASE_URL` | `https://xxx.up.railway.app/api` |

3. Deploy → 获得 `https://xxx.vercel.app`
4. 回到 Railway 补填 `CORS_ORIGIN=https://xxx.vercel.app`

### 步骤 4：初始化管理员账号（2 分钟）

在 Supabase SQL Editor 执行：

```sql
-- 密码 admin123 的 bcrypt 哈希
INSERT INTO users (username, password_hash, name, role)
VALUES ('admin', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', '管理员', 'admin')
ON CONFLICT (username) DO NOTHING;
```

### 步骤 5：联调测试

1. 打开 `https://xxx.vercel.app`
2. 登录：admin / admin123
3. 录入一条日报 → 刷新页面 → 数据仍在（云端存储）
4. 手机浏览器打开同一地址 → 登录同一账号 → 数据同步

---

## 快速验证清单

- [ ] Vercel 地址可访问（电脑 + 手机）
- [ ] 登录成功（admin / admin123）
- [ ] 录入日报 → 刷新 → 数据仍在
- [ ] 手机访问同一地址 → 数据同步
- [ ] 签名功能正常（Settings → 我的签名 → 保存 → RunLog → 一键签名）

---

## 故障排查

| 现象 | 解决 |
|------|------|
| Vercel 白屏 | 检查 `VITE_API_BASE_URL` 环境变量 |
| 登录 401 | Railway 日志 → 检查 `DATABASE_URL` 格式 |
| 数据写不进去 | Supabase RLS 策略未放行（默认匿名用户无权限） |
| 后端 500 | Railway 控制台 → Logs → 查看错误详情 |
| 服务自动停 | Railway 500 小时/月用完 → 控制台 Wake Up |

---

## 后续优化

1. **域名绑定**：Vercel Settings → Domains → 添加自定义域名（需备案）
2. **HTTPS 证书**：Vercel 自动配置，无需手动
3. **数据备份**：Supabase Settings → Backups → 开启每日自动备份
4. **监控告警**：Railway → Metrics → 设置 CPU/内存告警

---

## 费用说明

| 平台 | 免费额度 | 超限处理 |
|------|---------|---------|
| Vercel | 无限静态托管 | 个人项目够用 |
| Railway | 500 小时/月 | 超出后暂停，手动重启或升级 $5/月 |
| Supabase | 500MB 数据库 | 超出后只读，清理数据或升级 |

**月成本：0 元**（正常使用不超限）
