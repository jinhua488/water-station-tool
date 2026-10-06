@echo off
chcp 65001 >nul
echo ========================================
echo   废水站运营工具 - 快速启动脚本
echo ========================================
echo.

:: 检查 Node.js
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未找到 Node.js，请先安装 Node.js
    pause
    exit /b 1
)

:: 检查依赖
if not exist "node_modules" (
    echo [提示] 首次运行，正在安装依赖...
    call npm install
    if %errorlevel% neq 0 (
        echo [错误] 依赖安装失败
        pause
        exit /b 1
    )
)

:: 启动开发服务器
echo [启动] 正在启动开发服务器...
start "废水站运营工具" cmd /k "npm run dev"

:: 等待服务器启动
echo [等待] 等待服务器启动...
timeout /t 3 /nobreak >nul

:: 检查 ngrok
where ngrok >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo [提示] 未检测到 ngrok，跳过外网穿透
    echo [提示] 如需外网访问，请：
    echo   1. 下载 ngrok: https://ngrok.com/download
    echo   2. 运行: ngrok http 3000
    echo.
    echo [访问] 本地访问：http://localhost:3000
    echo.
    pause
    exit /b 0
)

:: 启动 ngrok
echo.
echo [穿透] 正在启动 ngrok 外网穿透...
start "ngrok" cmd /k "ngrok http 3000"

echo.
echo ========================================
echo   启动完成！
echo ========================================
echo.
echo [本地] http://localhost:3000
echo [外网] 请查看 ngrok 窗口中的 https 地址
echo.
echo [提示] 按任意键退出此窗口（服务继续运行）
pause >nul
