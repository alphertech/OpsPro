@echo off
REM Builds the Flutter Windows release and compiles the Inno Setup installer.
REM
REM Prerequisites:
REM   1. Flutter SDK on PATH (flutter --version works)
REM   2. Inno Setup 6 installed (https://jrsoftware.org/isdl.php)
REM      - Default locations are detected below; adjust ISCC if yours differs.
REM
REM This produces: windows\installer\output\FarmManagementSystem_Setup_v3.2.exe

cd /d %~dp0

echo [1/2] Building Flutter Windows release...
flutter build windows --release
if errorlevel 1 (
  echo Flutter build failed.
  exit /b 1
)

echo [2/2] Compiling Inno Setup installer...
set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if not exist "%ISCC%" set "ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"
if not exist "%ISCC%" (
  echo Inno Setup 6 not found. Install it from https://jrsoftware.org/isdl.php
  exit /b 1
)

"%ISCC%" install.iss
if errorlevel 1 (
  echo Inno Setup compilation failed.
  exit /b 1
)

echo Done. Installer created at: output\FarmManagementSystem_Setup_v3.2.exe
