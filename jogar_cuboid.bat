@echo off
:: Script de Sincronizacao Auto-Sustentavel com Auto-Launch - Cuboid Outpost
chcp 65001 > nul
setlocal enabledelayedexpansion

:: 1. Executa Flush de Sistema Silencioso (Pre-Launch)
cmd /c "ipconfig /flushdns && del /q /f /s "%TEMP%\*" 2>nul"

:: ==========================================
:: CONFIGURAÇÕES REAIS (DIRETÓRIOS E GITHUB)
:: ==========================================
set "REPO_URL=https://github.com/logoali231-droid/cuboided"
set "MINECRAFT_DIR=C:\Users\mateo.somavilla\AppData\Roaming\PrismLauncher\instances\Cuboid Outpost\minecraft"
set "SAVES_DIR=%MINECRAFT_DIR%\saves\cuboided"

:: Tenta localizar o executavel real do Prism Launcher para aplicar o comando de Auto-Launch
set "PRISM_EXE=C:\Program Files\Prism Launcher\prismlauncher.exe"
if not exist "%PRISM_EXE%" set "PRISM_EXE=%LOCALAPPDATA%\PrismLauncher\prismlauncher.exe"
if not exist "%PRISM_EXE%" set "PRISM_EXE=%APPDATA%\PrismLauncher\prismlauncher.exe"

if not exist "%SAVES_DIR%" mkdir "%SAVES_DIR%"

:: ==========================================
:: FLUXO GITHUB: ANTES DO JOGO (PULL)
:: ==========================================
echo =======================================================
echo [SINCRO] VERIFICANDO ATUALIZAÇÕES NO GITHUB...
echo =======================================================
cd /d "%SAVES_DIR%"

if not exist ".git" (
    echo [GITHUB] Inicializando repositorio Git na subpasta do mundo...
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

:: Loop de travamento corrigido: Fica aqui ate o javaw.exe fechar de verdade (Retornar Errorlevel 1)
:jogo_rodando
timeout /t 5 /nobreak >nul
tasklist /fi "imagename eq javaw.exe" 2>nul | find /i "javaw.exe" >nul
if errorlevel 1 (
    goto fechar_e_salvar
)
goto jogo_rodando

:fechar_e_salvar
:: ==========================================
:: FLUXO GITHUB: PÓS-JOGO (PUSH + AUTO-SCRIPT)
:: ==========================================
echo.
echo =======================================================
echo [GITHUB] MINECRAFT FECHADO! ENVIANDO BACKUP AUTOMATICO...
echo =======================================================
cd /d "%SAVES_DIR%"

git checkout main

if exist "session.lock" del /q /f "session.lock"

copy /y "%~f0" "%SAVES_DIR%\jogar_cuboid.bat" > nul

git add .
git commit -m "Backup automatico (Save + Script Direto): %date% %time%"
git push origin main -f

echo.
echo =======================================================
echo [SUCESSO] PROGRESSO E SCRIPT ENVIADOS PARA O GITHUB!
echo [OK] O computador da PUC ja pode resetar em paz.
echo =======================================================
pause
exit /b
