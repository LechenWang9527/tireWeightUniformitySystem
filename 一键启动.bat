@echo off
chcp 65001 >nul
title TireWeight Uniformity Analysis - Dev Mode
cd /d "%~dp0"

echo ==========================================================
echo   Tire Weight & Uniformity Analysis  ^|  Dev Mode
echo ==========================================================
echo.

if not exist ".venv\Scripts\python.exe" (
    echo [ERROR] .venv not found. Please restore the virtual environment first.
    pause
    exit /b 1
)

echo [1/2] Starting backend  -^>  http://127.0.0.1:8088/docs
start "Backend 8088" cmd /k ".venv\Scripts\python.exe backend\run_server.py"

timeout /t 4 /nobreak >nul

echo [2/2] Starting frontend -^>  http://localhost:5173
start "Frontend 5173" cmd /k "cd /d "%~dp0frontend" && npm run dev"

echo.
echo ==========================================================
echo   Backend  API : http://127.0.0.1:8088/docs
echo   Backend  Wiki: http://127.0.0.1:8088/wiki
echo   Frontend     : http://localhost:5173
echo ==========================================================
echo   Close the two opened windows to stop the services.
echo ==========================================================
timeout /t 8