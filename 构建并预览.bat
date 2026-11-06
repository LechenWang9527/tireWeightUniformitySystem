@echo off
chcp 65001 >nul
title TireWeight Uniformity Analysis - Build ^& Preview
cd /d "%~dp0"

echo ==========================================================
echo   Build frontend, then serve everything via port 8088
echo ==========================================================
echo.

if not exist ".venv\Scripts\python.exe" (
    echo [ERROR] .venv not found.
    pause
    exit /b 1
)

echo [1/2] Building frontend (npm run build) ...
cd /d "%~dp0frontend"
call npm run build
if errorlevel 1 (
    echo.
    echo [ERROR] Frontend build failed.
    pause
    exit /b 1
)

echo.
echo [2/2] Starting backend (serves frontend/dist) ...
cd /d "%~dp0"
start "Backend 8088 (preview)" cmd /k ".venv\Scripts\python.exe backend\run_server.py"

echo.
echo ==========================================================
echo   Open in browser:  http://127.0.0.1:8088
echo ==========================================================
timeout /t 8