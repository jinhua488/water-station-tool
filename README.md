# 废水站运营工具网站

基于 Vue3 + Element Plus 的废水站运营管理系统，参考 LYEHS 风格设计。

## 功能模块

- **登录与权限**：管理员/运行员/查看者三级权限
- **运行台账**：
  - 快速录入班次数据（综合表单）
  - 车间排水量（高浓废水、低浓废水）
  - 水站处理废水量
  - 自来水用量、电用量
  - 生化情况、pH 情况
  - 风机切换（A/B/C）
  - 标准录入（进出水、COD、氨氮、SS、总磷）
- **加药与耗材**：药剂投加记录、库存管理、领用记录、低库存预警
- **设备巡检**：巡检点管理、巡检记录、异常项跟踪
- **危废与污泥**：产生记录、转移联单、处置单位管理
- **异常与应急**：超标/故障上报、处置措施记录、处理流程跟踪
- **报表与导出**：日报/周报/月报生成、Excel 导出、趋势分析
- **基础配置**：指标配置、设备台账、人员管理、系统设置

## 技术栈

- Vue 3.5.13
- Element Plus 2.9.7
- Vue Router 4
- Pinia 状态管理
- SheetJS (xlsx) Excel 导出
- Vite 构建工具

## 快速开始

### 方式一：双击启动（推荐）

```bash
双击 start.bat
```

自动安装依赖、启动开发服务器、可选启动 ngrok 外网穿透。

### 方式二：命令行启动

```bash
# 安装依赖
cd D:\EHS\water-station-tool
npm install

# 开发模式
npm run dev
```

访问 http://localhost:3000

### 生产构建

```bash
npm run build
```

构建产物在 `dist/` 目录

## 外网访问

当前项目默认在本地运行（localhost:3000），外网无法访问。请参考 [DEPLOY.md](./DEPLOY.md) 选择部署方案：

| 方案 | 适用场景 | 说明 |
|------|---------|------|
| 服务器部署 | 正式使用 | Nginx + HTTPS，稳定可靠 |
| ngrok 穿透 | 快速测试 | 免费、简单，适合临时使用 |
| 路由器映射 | 家庭网络 | 需要公网 IP |
| Cloudflare Tunnel | 安全优先 | 免费 CDN + 安全隧道 |

### 快速测试（ngrok）

```bash
# 1. 启动开发服务器
npm run dev

# 2. 新终端启动 ngrok
ngrok http 3000

# 3. 复制 ngrok 提供的 https 地址，外网即可访问
```

## 默认账号

| 用户名 | 密码 | 角色 |
|--------|------|------|
| admin | 123456 | 管理员 |
| operator | 123456 | 运行员 |
| viewer | 123456 | 查看者 |

⚠️ **生产环境务必修改默认密码！**

## 数据说明

- 所有数据保存在浏览器 localStorage
- 支持数据导出为 Excel
- 不同浏览器/设备数据不互通

## 部署建议

### 外网访问

1. **HTTPS 配置**：使用 Nginx/Apache 反向代理，配置 SSL 证书
2. **访问控制**：建议配合 VPN 或 IP 白名单限制访问
3. **数据备份**：定期导出 localStorage 数据备份

### 部署步骤

```bash
# 1. 构建项目
npm run build

# 2. 将 dist/ 目录部署到 Web 服务器
# 例如 Nginx 配置：
# server {
#     listen 80;
#     server_name your-domain.com;
#     root /path/to/dist;
#     index index.html;
#     location / {
#         try_files $uri $uri/ /index.html;
#     }
# }

# 3. 配置 HTTPS（推荐）
# 使用 Let's Encrypt 免费证书或商业证书
```

## 后续扩展

- [ ] 后端 API 集成（Node.js/Python）
- [ ] 数据库持久化（MySQL/MongoDB）
- [ ] 移动端 App 适配
- [ ] 数据可视化图表增强
- [ ] 短信/邮件通知功能
- [ ] 多站点管理

## 参考站点

- LYEHS EHS 智慧工具矩阵：http://8.163.94.160/

## 许可证

MIT
