@echo off
echo =====================================
echo      Verificar Docker - Comprae     
echo =====================================
echo.

REM Verificar se Docker esta instalado
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker nao esta instalado!
    echo.
    echo 📋 Para instalar o Docker:
    echo 1. Acesse: https://www.docker.com/products/docker-desktop
    echo 2. Baixe e instale o Docker Desktop
    echo 3. Reinicie o computador
    echo 4. Execute este script novamente
    pause
    exit /b 1
)

echo ✅ Docker instalado!
docker --version

REM Verificar se Docker esta rodando
docker ps >nul 2>&1
if errorlevel 1 (
    echo.
    echo ⚠️ Docker nao esta em execucao!
    echo.
    echo 📋 Iniciando Docker Desktop...
    
    REM Tentar iniciar Docker Desktop
    set "DOCKER_PATH=%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
    if exist "%DOCKER_PATH%" (
        start "" "%DOCKER_PATH%"
        echo ⏳ Aguardando Docker inicializar...
        timeout /t 30 /nobreak >nul
        
        REM Verificar novamente
        docker ps >nul 2>&1
        if errorlevel 1 (
            echo ❌ Nao foi possivel iniciar automaticamente!
            echo 📋 Inicie o Docker Desktop manualmente e tente novamente.
            pause
            exit /b 1
        )
    ) else (
        echo ❌ Docker Desktop nao encontrado em: %DOCKER_PATH%
        echo 📋 Inicie o Docker Desktop manualmente.
        pause
        exit /b 1
    )
)

echo ✅ Docker esta rodando!
echo.

REM Verificar Docker Compose
docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker Compose nao esta disponivel!
    pause
    exit /b 1
)

echo ✅ Docker Compose disponivel!
docker-compose --version
echo.

REM Verificar se esta no diretorio correto
if not exist "docker-compose.yml" (
    echo ❌ Arquivo docker-compose.yml nao encontrado!
    echo 📋 Execute este script no diretorio comprae-infra
    pause
    exit /b 1
)

echo ✅ Arquivo docker-compose.yml encontrado!
echo.

REM Validar configuracao
echo 🔍 Validando configuracao...
docker-compose config --quiet
if errorlevel 1 (
    echo ❌ Erro na configuracao do docker-compose.yml!
    echo 📋 Verifique o arquivo de configuracao
    pause
    exit /b 1
)

echo ✅ Configuracao valida!
echo.

echo 🎉 Sistema pronto para uso!
echo.
echo 📋 Proximos passos:
echo   • Para iniciar: iniciar-sistema-completo.ps1
echo   • Para verificar: verificar-sistema.ps1
echo   • Para parar: docker-compose down
echo.

pause
