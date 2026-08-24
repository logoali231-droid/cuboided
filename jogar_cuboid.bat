@echo off
:: Script de Sincronizacao Auto-Sustentavel - Cuboid Outpost (PUC)
chcp 65001 > nul
setlocal enabledelayedexpansion

:: 1. Executa Flush de Sistema Silencioso (Pre-Launch)
cmd /c "ipconfig /flushdns && del /q /f /s "%TEMP%\*" 2>nul"

:: ==========================================
:: CONFIGURAÇÕES REAIS (DIRETÓRIOS E GITHUB)
:: ==========================================
set "REPO_URL=https://github.com/logoali231-droid/cuboided"
set "PRISM_LNK=C:\Users\mateo.somavilla\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Prism Launcher.lnk"
set "MINECRAFT_DIR=C:\Users\mateo.somavilla\AppData\Roaming\PrismLauncher\instances\Cuboid Outpost\minecraft"

:: Pasta correta do mundo para os arquivos crus do repositório
set "SAVES_DIR=%MINECRAFT_DIR%\saves\Mundo_Cuboid"

:: Criar a arvore de pastas caso nao exista
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
:: INICIALIZAÇÃO DO MINECRAFT
:: ==========================================
echo.
echo =======================================================
echo [JOGO] ABRINDO O PRISM LAUNCHER
echo =======================================================
echo [AVISO] O terminal ficara travado aguardando o fechamento do jogo.
echo Nao feche esta janela preta manualmente!
echo =======================================================
start "" /wait "%PRISM_LNK%"

:: ==========================================
:: FLUXO GITHUB: PÓS-JOGO (PUSH + AUTO-SCRIPT)
:: ==========================================
echo.
echo =======================================================
echo [GITHUB] JOGO FECHADO! ENVIANDO BACKUP AUTOMATICO...
echo =======================================================
cd /d "%SAVES_DIR%"

:: Garante a branch correta do seu repositorio
git checkout main

:: Remove o arquivo de trava do Minecraft para nao dar conflito no Git
if exist "session.lock" del /q /f "session.lock"

:: [NOVO] Faz o script copiar a si mesmo para a raiz do repositório antes de enviar
copy /y "%~f0" "%SAVES_DIR%\jogar_cuboid.bat" > nul

:: Adiciona as alteracoes e envia o save + o script para o GitHub
git add .
git commit -m "Backup automatico (Save + Script): %date% %time%"
git push origin main -f

echo.
echo =======================================================
echo [SUCESSO] PROGRESSO E SCRIPT ENVIADOS PARA O GITHUB!
echo [OK] O computador da PUC ja pode resetar em paz.
echo =======================================================
pause
exit /b
