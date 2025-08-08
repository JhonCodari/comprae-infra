param(
    [Parameter(Position=0)]
    [string]$Mode = "interactive"
)

$ErrorActionPreference = "Stop"

# Função para log colorido
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    switch ($Level) {
        "INFO" { Write-Host "[$timestamp] [INFO] $Message" -ForegroundColor Cyan }
        "SUCCESS" { Write-Host "[$timestamp] [SUCCESS] $Message" -ForegroundColor Green }
        "WARNING" { Write-Host "[$timestamp] [WARNING] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "[$timestamp] [ERROR] $Message" -ForegroundColor Red }
    }
}

function Test-Prerequisites {
    Write-Log "Verificando pré-requisitos..." "INFO"
    
    # Verificar Docker
    try {
        $dockerVersion = docker --version
        Write-Log "Docker encontrado: $dockerVersion" "SUCCESS"
    }
    catch {
        Write-Log "Docker não está instalado!" "ERROR"
        exit 1
    }
    
    # Verificar Docker Compose
    try {
        $composeVersion = docker-compose --version
        Write-Log "Docker Compose encontrado: $composeVersion" "SUCCESS"
    }
    catch {
        Write-Log "Docker Compose não está instalado!" "ERROR"
        exit 1
    }
    
    # Verificar Git
    try {
        $gitVersion = git --version
        Write-Log "Git encontrado: $gitVersion" "SUCCESS"
    }
    catch {
        Write-Log "Git não está instalado!" "ERROR"
        exit 1
    }
    
    # Verificar se Docker está rodando
    try {
        docker info | Out-Null
        Write-Log "Docker está rodando!" "SUCCESS"
    }
    catch {
        Write-Log "Docker não está rodando! Inicie o Docker e tente novamente." "ERROR"
        exit 1
    }
    
    # Verificar PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 5) {
        Write-Log "PowerShell 5.0+ é necessário. Versão atual: $psVersion" "WARNING"
    } else {
        Write-Log "PowerShell versão: $psVersion" "SUCCESS"
    }
}

function Initialize-Environment {
    Write-Log "Configurando arquivo de ambiente..." "INFO"
    
    $envPath = Join-Path $PSScriptRoot ".." ".env"
    $envExamplePath = Join-Path $PSScriptRoot ".." ".env.example"
    
    if (-not (Test-Path $envPath)) {
        if (Test-Path $envExamplePath) {
            Copy-Item $envExamplePath $envPath
            Write-Log "Arquivo .env criado a partir do .env.example" "SUCCESS"
            Write-Log "Edite o arquivo .env para personalizar as configurações" "WARNING"
        } else {
            Write-Log "Arquivo .env.example não encontrado!" "ERROR"
        }
    } else {
        Write-Log "Arquivo .env já existe" "WARNING"
    }
}

function New-RequiredDirectories {
    Write-Log "Criando diretórios necessários..." "INFO"
    
    $projectRoot = Join-Path $PSScriptRoot ".."
    
    $directories = @(
        "logs",
        "volumes\postgres",
        "volumes\redis",
        "volumes\rabbitmq",
        "volumes\elasticsearch",
        "volumes\grafana",
        "volumes\prometheus"
    )
    
    foreach ($dir in $directories) {
        $fullPath = Join-Path $projectRoot $dir
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-Log "Diretório criado: $fullPath" "SUCCESS"
        }
    }
}

function Set-ScriptsExecutable {
    Write-Log "Configurando permissões de scripts..." "INFO"
    
    $scriptsPath = $PSScriptRoot
    
    # Para Windows, verificar política de execução
    $executionPolicy = Get-ExecutionPolicy
    if ($executionPolicy -eq "Restricted") {
        Write-Log "Política de execução restrita detectada." "WARNING"
        Write-Log "Execute: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" "WARNING"
    } else {
        Write-Log "Política de execução: $executionPolicy" "SUCCESS"
    }
    
    # Verificar scripts PowerShell
    $psScripts = Get-ChildItem -Path $scriptsPath -Filter "*.ps1"
    foreach ($script in $psScripts) {
        try {
            # Verificar sintaxe básica
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script.FullName -Raw), [ref]$null)
            Write-Log "Script validado: $($script.Name)" "SUCCESS"
        }
        catch {
            Write-Log "Erro no script $($script.Name): $($_.Exception.Message)" "ERROR"
        }
    }
}

function Test-ComposeFiles {
    Write-Log "Validando arquivos Docker Compose..." "INFO"
    
    $projectRoot = Join-Path $PSScriptRoot ".."
    Push-Location $projectRoot
    
    try {
        # Validar docker-compose.yml
        docker-compose -f docker-compose.yml config | Out-Null
        Write-Log "docker-compose.yml válido" "SUCCESS"
        
        # Validar docker-compose.dev.yml
        docker-compose -f docker-compose.dev.yml config | Out-Null
        Write-Log "docker-compose.dev.yml válido" "SUCCESS"
        
        # Validar docker-compose.test.yml
        docker-compose -f docker-compose.test.yml config | Out-Null
        Write-Log "docker-compose.test.yml válido" "SUCCESS"
    }
    catch {
        Write-Log "Erro na validação dos arquivos Docker Compose: $($_.Exception.Message)" "ERROR"
        throw
    }
    finally {
        Pop-Location
    }
}

function Get-BaseImages {
    Write-Log "Baixando imagens base..." "INFO"
    
    $images = @(
        "postgres:15-alpine",
        "redis:7-alpine",
        "rabbitmq:3-management-alpine",
        "docker.elastic.co/elasticsearch/elasticsearch:8.11.0",
        "docker.elastic.co/kibana/kibana:8.11.0",
        "prom/prometheus:latest",
        "grafana/grafana:latest",
        "openzipkin/zipkin:latest",
        "mailhog/mailhog:latest",
        "adminer:latest"
    )
    
    foreach ($image in $images) {
        Write-Log "Baixando $image..." "INFO"
        try {
            docker pull $image
        }
        catch {
            Write-Log "Erro ao baixar $image" "WARNING"
        }
    }
    
    Write-Log "Download de imagens base concluído!" "SUCCESS"
}

function Initialize-Networks {
    Write-Log "Configurando redes Docker..." "INFO"
    
    # Criar rede principal se não existir
    $networks = docker network ls --format "{{.Name}}"
    if ($networks -notcontains "comprae-network") {
        docker network create comprae-network
        Write-Log "Rede comprae-network criada" "SUCCESS"
    } else {
        Write-Log "Rede comprae-network já existe" "WARNING"
    }
    
    # Criar rede de desenvolvimento se não existir
    if ($networks -notcontains "comprae-dev-network") {
        docker network create comprae-dev-network
        Write-Log "Rede comprae-dev-network criada" "SUCCESS"
    } else {
        Write-Log "Rede comprae-dev-network já existe" "WARNING"
    }
}

function Test-Environment {
    Write-Log "Testando ambiente básico..." "INFO"
    
    $projectRoot = Join-Path $PSScriptRoot ".."
    Push-Location $projectRoot
    
    try {
        # Iniciar apenas os serviços de infraestrutura para teste
        Write-Log "Iniciando serviços de infraestrutura para teste..." "INFO"
        docker-compose up -d postgres redis rabbitmq
        
        # Aguardar serviços ficarem prontos
        Write-Log "Aguardando serviços ficarem prontos..." "INFO"
        Start-Sleep -Seconds 30
        
        # Verificar PostgreSQL
        try {
            $postgresCheck = docker-compose exec -T postgres pg_isready -U comprae_user
            if ($LASTEXITCODE -eq 0) {
                Write-Log "PostgreSQL está funcionando" "SUCCESS"
            } else {
                Write-Log "PostgreSQL não está funcionando!" "ERROR"
            }
        }
        catch {
            Write-Log "Erro ao verificar PostgreSQL" "WARNING"
        }
        
        # Verificar Redis
        try {
            $redisCheck = docker-compose exec -T redis redis-cli ping
            if ($redisCheck -match "PONG") {
                Write-Log "Redis está funcionando" "SUCCESS"
            } else {
                Write-Log "Redis não está funcionando!" "ERROR"
            }
        }
        catch {
            Write-Log "Erro ao verificar Redis" "WARNING"
        }
        
        # Parar serviços de teste
        Write-Log "Parando serviços de teste..." "INFO"
        docker-compose down
    }
    finally {
        Pop-Location
    }
}

function Show-Menu {
    Write-Host ""
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "  COMPRAE INFRASTRUCTURE SETUP" -ForegroundColor Cyan
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Escolha uma opção:" -ForegroundColor White
    Write-Host "1) Setup completo (recomendado)" -ForegroundColor White
    Write-Host "2) Verificar pré-requisitos apenas" -ForegroundColor White
    Write-Host "3) Configurar ambiente apenas" -ForegroundColor White
    Write-Host "4) Baixar imagens apenas" -ForegroundColor White
    Write-Host "5) Testar ambiente" -ForegroundColor White
    Write-Host "6) Sair" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Digite sua opção [1-6]"
    return $choice
}

function Invoke-FullSetup {
    Write-Log "Executando setup completo..." "INFO"
    
    Test-Prerequisites
    Initialize-Environment
    New-RequiredDirectories
    Set-ScriptsExecutable
    Test-ComposeFiles
    Initialize-Networks
    Get-BaseImages
    Test-Environment
    
    Write-Log "Setup completo finalizado!" "SUCCESS"
}

function Show-NextSteps {
    Write-Host ""
    Write-Log "Setup concluído!" "SUCCESS"
    Write-Host ""
    Write-Host "Próximos passos:" -ForegroundColor Yellow
    Write-Host "1. Edite o arquivo .env se necessário" -ForegroundColor White
    Write-Host "2. Execute: .\scripts\manage.ps1 dev (para desenvolvimento)" -ForegroundColor White
    Write-Host "3. Execute: .\scripts\manage.ps1 start (para produção)" -ForegroundColor White
    Write-Host "4. Acesse: http://localhost:8080 (API Gateway)" -ForegroundColor White
    Write-Host ""
}

# Função principal
switch ($Mode.ToLower()) {
    "full" {
        Invoke-FullSetup
        Show-NextSteps
    }
    "check" {
        Test-Prerequisites
    }
    "env" {
        Initialize-Environment
        New-RequiredDirectories
        Set-ScriptsExecutable
    }
    "images" {
        Get-BaseImages
    }
    "test" {
        Test-Environment
    }
    default {
        $choice = Show-Menu
        
        switch ($choice) {
            "1" {
                Invoke-FullSetup
                Show-NextSteps
            }
            "2" {
                Test-Prerequisites
            }
            "3" {
                Initialize-Environment
                New-RequiredDirectories
                Set-ScriptsExecutable
            }
            "4" {
                Get-BaseImages
            }
            "5" {
                Test-Environment
            }
            "6" {
                Write-Log "Saindo..." "INFO"
                exit 0
            }
            default {
                Write-Log "Opção inválida!" "ERROR"
                exit 1
            }
        }
    }
}
