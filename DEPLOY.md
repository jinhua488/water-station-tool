# 废水站运营工具 - 外网访问方案

## 问题说明

当前项目使用 `localhost:3000` 运行，只能在本地访问，外网无法打开。

## 解决方案

### 方案 A：部署到服务器（推荐）

#### 1. 准备服务器

- 配置：2 核 4G 内存，50GB 磁盘
- 系统：Ubuntu 20.04/22.04 或 CentOS 7/8
- 软件：Nginx、Node.js（可选）

#### 2. 部署步骤

```bash
# 1. 上传项目到服务器
scp -r D:\EHS\water-station-tool\dist/* user@your-server:/var/www/water-station-tool/

# 2. 配置 Nginx
sudo nano /etc/nginx/sites-available/water-station

# 配置内容见 nginx.conf.example

# 3. 启用站点
sudo ln -s /etc/nginx/sites-available/water-station /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# 4. 配置防火墙
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# 5. 配置 SSL（推荐）
sudo certbot --nginx -d your-domain.com
```

#### 3. 访问地址

- HTTP: http://your-domain.com
- HTTPS: https://your-domain.com

---

### 方案 B：内网穿透（快速测试）

#### 使用 ngrok（推荐）

```bash
# 1. 下载 ngrok
# Windows: https://ngrok.com/download
# 或：choco install ngrok

# 2. 启动开发服务器
cd D:\EHS\water-station-tool
npm run dev

# 3. 启动 ngrok 穿透
ngrok http 3000

# 4. 获取外网地址
# 输出类似：https://abc123.ngrok.io
# 复制该地址，外网即可访问
```

#### 使用 frp（自建穿透）

```bash
# 1. 下载 frp
# https://github.com/fatedier/frp/releases

# 2. 配置 frpc（客户端）
cat > frpc.toml << EOF
serverAddr = "your-frp-server.com"
serverPort = 7000

[[proxies]]
name = "water-station"
type = "tcp"
localIP = "127.0.0.1"
localPort = 3000
remotePort = 8080
EOF

# 3. 启动客户端
./frpc -c frpc.toml

# 4. 访问：http://your-frp-server.com:8080
```

---

### 方案 C：路由器端口映射（家庭网络）

#### 前提条件

- 有公网 IP 或域名
- 路由器支持端口映射

#### 步骤

1. 登录路由器（通常是 192.168.1.1）
2. 找到"端口映射"或"虚拟服务器"设置
3. 添加规则：
   - 外部端口：8080
   - 内部 IP：192.168.x.x（你的电脑 IP）
   - 内部端口：3000
   - 协议：TCP
4. 保存并重启路由器
5. 访问：http://你的公网 IP:8080

---

### 方案 D：使用 Cloudflare Tunnel（免费安全）

```bash
# 1. 安装 cloudflared
# https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/

# 2. 配置隧道
cloudflared tunnel create water-station

# 3. 编辑配置
cloudflared tunnel edit water-station --url http://localhost:3000

# 4. 启动隧道
cloudflared tunnel run water-station

# 5. 获取地址：https://water-station.your-subdomain.cfapp.io
```

---

## 推荐方案

| 场景 | 推荐方案 | 优点 | 缺点 |
|------|---------|------|------|
| 正式使用 | 方案 A（服务器部署） | 稳定、安全、可定制 | 需要服务器成本 |
| 快速测试 | 方案 B（ngrok） | 免费、快速、简单 | 有速度限制 |
| 家庭网络 | 方案 C（端口映射） | 免费 | 需要公网 IP |
| 安全优先 | 方案 D（Cloudflare） | 免费、安全、CDN | 配置稍复杂 |

---

## 安全建议

1. **修改默认密码**：生产环境必须修改 admin/operator/viewer 密码
2. **启用 HTTPS**：所有数据传输使用加密
3. **访问控制**：配置 IP 白名单或 Basic Auth
4. **数据备份**：定期导出 Excel 备份
5. **日志审计**：记录所有操作日志

---

## 快速测试（ngrok 示例）

```bash
# 1. 启动开发服务器
cd D:\EHS\water-station-tool
npm run dev

# 2. 打开新终端，启动 ngrok
ngrok http 3000

# 3. 复制 ngrok 提供的 https 地址
# 例如：https://abc123-12-34-56.ngrok.io

# 4. 在外网浏览器访问该地址即可
```

---

## 常见问题

**Q: 外网访问速度慢？**
A: 使用 CDN 或优化静态资源缓存

**Q: 数据会丢失吗？**
A: 当前使用 localStorage，不同设备不互通。建议定期导出 Excel 备份。

**Q: 如何多人同时使用？**
A: 需要后端 API + 数据库。可考虑：
- Node.js + Express + MongoDB
- Python + Flask + MySQL
- 或使用现有 SaaS 平台

---

## 下一步

1. 选择适合你的部署方案
2. 按照对应步骤配置
3. 修改默认账号密码
4. 配置访问控制
5. 测试外网访问
