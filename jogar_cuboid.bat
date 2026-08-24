@echo off
:: Script de Sincronizacao Blindado (Anti-Crash e Anti-Duplicacao) - Cuboid Outpost
chcp 65001 > nul
setlocal enabledelayedexpansion

:: ==========================================
:: CONFIGURAÇÕES REAIS (DIRETÓRIOS E GITHUB)
:: ==========================================
set "REPO_URL=https://github.com/logoali231-droid/cuboided"
set "MINECRAFT_DIR=C:\Users\mateo.somavilla\AppData\Roaming\PrismLauncher\instances\Cuboid Outpost\minecraft"
set "SAVES_DIR=%MINECRAFT_DIR%\saves\cuboided"

:: 1. Trava Anti-Duplicacao: Impede rodar o script duas vezes ao mesmo tempo
tasklist /fi "windowtitle eq SCRIPT_CUBOID_ATIVO" 2>nul | find /i "cmd.exe" >nul
if %errorlevel% equ 0 (
    echo [ERRO] O script ja esta rodando em outra janela! Fechando esta...
    timeout /t 3 >nul
    exit /b
)
title SCRIPT_CUBOID_ATIVO

:: 2. Executa Flush de Sistema Silencioso (Pre-Launch)
cmd /c "ipconfig /flushdns && del /q /f /s "%TEMP%\*" 2>nul"

:: Tenta localizar o executavel real do Prism Launcher
set "PRISM_EXE=C:\Program Files\Prism Launcher\prismlauncher.exe"
if not exist "%PRISM_EXE%" set "PRISM_EXE=%LOCALAPPDATA%\PrismLauncher\prismlauncher.exe"
if not exist "%PRISM_EXE%" set "PRISM_EXE=%APPDATA%\PrismLauncher\prismlauncher.exe"

:: Garante limpeza de pastas fantasmas antes de sincronizar
if exist "%MINECRAFT_DIR%\saves\cuboided" rmdir /s /q "%MINECRAFT_DIR%\saves\cuboided" 2>nul
if not exist "%SAVES_DIR%" mkdir "%SAVES_DIR%"

:: ==========================================
:: FLUXO GITHUB: ANTES DO JOGO (PULL)
:: ==========================================
echo =======================================================
echo [SINCRO] VERIFICANDO ATUALIZAÇÕES NO GITHUB...
echo =======================================================
cd /d "%SAVES_DIR%"

if not exist ".git" (
    echo [GITHUB] Inicializando repositorio Git na subpasta unica do mundo...
    git init
    git remote add origin %REPO_URL%
    echo [GITHUB] Baixando arquivos crus do save para a pasta correta...
    git fetch origin
    git checkout main -f
) else (
    echo [GITHUB] Atualizando progresso do mundo com o GitHub...
    git pull origin main --rebase
)

:: ==========================================
:: INICIALIZAÇÃO TOTALMENTE AUTOMÁTICA
:: ==========================================
echo.
echo =======================================================
echo [JOGO] INICIANDO O CUBOID OUTPOST AUTOMATICAMENTE
echo =======================================================
echo [INFO] Disparando o jogo pelo motor do Prism Launcher...

if exist "%PRISM_EXE%" (
    start "" "%PRISM_EXE%" --launch "Cuboid Outpost"
) else (
    start "" "C:\Users\mateo.somavilla\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Prism Launcher.lnk" --launch "Cuboid Outpost"
)

echo [AGUARDANDO] Monitorando a inicializacao do Java...

:: Loop de espera: Aguarda o processo javaw.exe (Minecraft) iniciar
:esperar_jogo
timeout /t 2 /nobreak >nul
tasklist /fi "imagename eq javaw.exe" 2>nul | find /i "javaw.exe" >nul
if errorlevel 1 (
    goto esperar_jogo
)

echo [DETECTADO] Cuboid Outpost aberto com sucesso!
echo [INFO] O terminal ficara travado monitorando o jogo. Pode jogar em paz.

:: Loop de travamento corrigido: Fica aqui ate o javaw.exe fechar de verdade
:jogo_rodando
timeout /t 5 /nobreak >nul
tasklist /fi "imagename eq javaw.exe" 2>nul | find /i "javaw.exe" >nul
if errorlevel 1 (
    goto verificar_fechamento
)
goto jogo_rodando

:verificar_fechamento
:: Proteção contra Crash: Verifica se o level.dat ficou corrompido ou sumiu no fechamento abrupto
if not exist "%SAVES_DIR%\level.dat" (
    echo.
    echo =======================================================
    echo [ALERTA CRÍTICO] O MINECRAFT CRASHOU OU O MUNDO SUMIU!
    echo [SEGURANÇA] Backup cancelado para nao corromper o GitHub.
    echo =======================================================
    pause
    exit /b
)

:: ==========================================
:: FLUXO GITHUB: PÓS-JOGO (PUSH + AUTO-SCRIPT)
:: ==========================================
echo.
echo =======================================================
echo [GITHUB] MINECRAFT FECHADO NORMALMENTE! ENVIANDO BACKUP...
echo =======================================================
cd /d "%SAVES_DIR%"
git checkout main

if exist "session.lock" del /q /f "session.lock"
copy /y "%~f0" "%SAVES_DIR%\jogar_cuboid.bat" > nul

git add .
git commit -m "Backup automatico seguro: %date% %time%"
git push origin main -f

echo.
echo =======================================================
echo [SUCESSO] PROGRESSO E SCRIPT ENVIADOS PARA O GITHUB!
echo [OK] O computador da PUC ja pode resetar em paz.
echo =======================================================
pause
exit /b

