# 废水站运营管理系统 — 全免费部署指南

> 技术栈：**Vercel**（前端）+ **Railway**（后端）+ **Supabase**（数据库），全部免费额度
> 费用：0 元/月（有免费额度限制，见文末说明）

---

## 一、架构总览

```
浏览器 (手机/电脑)
   │  HTTPS
   ▼
Vercel ─────────────── 前端静态站 (dist/)
   │  /api/* 请求
   ▼
Railway ────────────── 后端 Node.js API (backend/)
   │  PostgreSQL 连接
   ▼
Supabase ───────────── 数据库（7 张表）
```

## 二、四步部署流程

### 步骤 1：前端部署到 Vercel

1. 注册 [Vercel](https://vercel.com)（可用 GitHub 账号登录）
2. 把 `D:\EHS\water-station-tool\` 推送到 GitHub 仓库（注意排除 node_modules/dist）
3. Vercel → Add New Project → Import 该仓库
4. Framework Preset 选 **Vite**，Build Command `npm run build`，Output `dist`
5. 环境变量：`VITE_API_BASE_URL=https://你的后端.railway.app/api`
6. Deploy → 获得 `https://xxx.vercel.app`

> `vercel.json` 已配置好 SPA 路由重写，无需手改。

### 步骤 2：后端部署到 Railway

1. 注册 [Railway](https://railway.app)（GitHub 登录）
2. New Project → Deploy from GitHub Repo → 选 backend 子目录
3. Railway 自动识别 `backend/Dockerfile` 构建
4. Variables 面板配置：

| 变量 | 值 |
|------|-----|
| `DATABASE_URL` | Supabase 连接串（见步骤 3） |
| `JWT_SECRET` | 随机长字符串（可用 `openssl rand -hex 32` 生成） |
| `CORS_ORIGIN` | `https://xxx.vercel.app`（你的前端域名） |
| `PORT` | `3001` |

5. Deploy → 获得 `https://xxx.up.railway.app`，测试 `GET /api/health`

### 步骤 3：数据库搭建（Supabase）

1. 注册 [Supabase](https://supabase.com) → New Project → 记下 Database Password
2. 左侧 **SQL Editor** → 粘贴执行项目根目录的 [`supabase-schema.sql`](./supabase-schema.sql)
3. 建表完成后，**Project Settings → Database → Connection string**，复制 `postgresql://...` 连接串
4. 把连接串填到 Railway 的 `DATABASE_URL`（记得追加 `?sslmode=require` 后缀，如不需要可省略）

> ⚠️ 连接串中的密码是 `postgres` 用户密码，若记不住可在 Settings 中重置。

**初始化管理员账号**（在建表后执行一次）：

```sql
-- 密码请替换为 BCrypt 哈希（后端 /api/auth/register 或手动生成）
-- 简单方案：先临时用明文，首次登录后修改，或用后端注册接口
INSERT INTO users (username, password_hash, name, role)
VALUES ('admin', '$2a$10$GENERATED_HASH', '管理员', 'admin')
ON CONFLICT (username) DO NOTHING;
```

*提示：可用在线 bcrypt 生成器生成哈希，或临时在 PHP/Node 一行命令生成。*

### 步骤 4：前后端联调

1. 确认前端环境变量 `VITE_API_BASE_URL` 指向 Railway 地址
2. 后端 CORS 已按 `CORS_ORIGIN` 放开 Vercel 域名
3. 依次测试：
   - 登录：`POST /api/auth/login` → 拿到 token
   - 日报：`GET /api/daily-record`、`POST /api/daily-record`
   - 配置：`GET /api/config`
4. 手机浏览器打开 `https://xxx.vercel.app` 实测移动端

---

## 三、前端接入后端的适配

当前前端为纯 localStorage 模式。接入后端时，在 `src/api/index.js` 增加请求封装并逐步替换 store：

```js
// src/api/index.js（新增）
const BASE = import.meta.env.VITE_API_BASE_URL || '/api'

export async function request(path, options = {}) {
  const token = localStorage.getItem('auth_token')
  const res = await fetch(`${BASE}${path}`, {
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {})
    },
    ...options
  })
  if (!res.ok) throw new Error((await res.json()).error || '请求失败')
  return res.json()
}

export const authApi = {
  login: (data) => request('/auth/login', { method: 'POST', body: JSON.stringify(data) })
}
export const dailyApi = {
  list: (params) => request(`/daily-record?${new URLSearchParams(params)}`),
  create: (data) => request('/daily-record', { method: 'POST', body: JSON.stringify(data) }),
  signBatch: (data) => request('/daily-record/sign', { method: 'POST', body: JSON.stringify(data) })
}
```

迁移策略（可选渐进式）：
1. 登录接口 → 替换 authStore.login
2. 日报读写 → 替换 dataStore 中 runLogs 相关
3. 其余模块逐步迁移
4. 保留 localStorage 作为离线缓存降级

---

## 四、免费方案限制说明

| 平台 | 免费额度 | 超限处理 |
|------|---------|---------|
| Vercel | 无限静态托管、100GB 带宽/月 | 个人项目基本够用 |
| Railway | 500 小时/月（约 20 天连续运行） | 超出后暂停，手动 Wake Up 或升级 $5/月 |
| Supabase | 500MB 数据库、5 并发连接、1GB 存储 | 超出后只读，需清理数据或升级 |

**国内访问**：三平台服务器均在海外，国内访问速度约 1-3 秒延迟，适合内部使用；追求速度后期可迁阿里云轻量（首年约 20 元）。

## 五、后期迁移建议

1. **升级路径**：Railway → 阿里云 ECS + Docker；Supabase → 自建 PostgreSQL；域名备案 + HTTPS
2. **备份**：Supabase 自带每日备份；建议每周导出 CSV 到本地 `D:\EHS\backup\`
3. **监控**：后期可加 Prometheus + Grafana（免费）或直接看 Railway 日志

---

## 六、常见问题

| 现象 | 排查 |
|------|------|
| 前端白屏 | 浏览器控制台报错；检查 Vercel 环境变量 `VITE_API_BASE_URL` |
| 接口 403/500 | Railway 日志；`DATABASE_URL` 格式或密码错误 |
| 数据写不进去 | Supabase RLS 策略未放行（默认匿名用户无权限），检查 `supabase-schema.sql` 底部注释 |
| 服务自动停 | Railway 500 小时/月用完 → 控制台 Wake Up 或升级 |
| 中文乱码 | 确认 `postgresql://...?sslmode=require` 且建表用 UTF-8（默认即是） |