@echo off
REM Simple batch file to run the PowerShell preparation script
REM Double-click this file to prepare your files for deployment

echo ========================================
echo SCCDMS File Preparation
echo ========================================
echo.

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell is available'" >nul 2>&1
if errorlevel 1 (
    echo ERROR: PowerShell is not available on this system.
    echo Please run prepare_local.ps1 manually in PowerShell.
    pause
    exit /b 1
)

REM Run the PowerShell script
echo Running file preparation script...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0prepare_local.ps1"

echo.
echo ========================================
echo Done!
echo ========================================
echo.
pause

