@echo off
cd /d "%~dp0"
"..\RojoSetup\rojo.exe" serve default.project.json
pause
