@echo off
title Edumy Online Server (Cloudflare Tunnel)
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-tunnel.ps1"
pause
