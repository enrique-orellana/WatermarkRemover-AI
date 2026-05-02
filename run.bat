@echo off
cd /d "%~dp0"

if exist "%~dp0venv\Scripts\python.exe" (
    "%~dp0venv\Scripts\python.exe" remwmgui.py
) else if exist "%~dp0python\pythonw.exe" (
    "%~dp0python\pythonw.exe" remwmgui.py
) else (
    python remwmgui.py
)
