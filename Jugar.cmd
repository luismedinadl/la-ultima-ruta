@echo off
setlocal
set "ROUTE_ENGINE=%LOCALAPPDATA%\Programs\Godot\Godot.exe"
if defined GODOT_BIN set "ROUTE_ENGINE=%GODOT_BIN%"
if not exist "%ROUTE_ENGINE%" set "ROUTE_ENGINE=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%ROUTE_ENGINE%" (
  echo No se encontro Godot. Abre project.godot con Godot 4 y pulsa F5.
  echo Tambien puedes definir GODOT_BIN con la ruta de Godot.
  pause
  exit /b 1
)
start "The Last Route" "%ROUTE_ENGINE%" --path "%~dp0."
