# Script Final - Finalizar Docker Completo Comprae
param(
    [switch]$Build,
    [switch]$Start,
    [switch]$Test,
    [switch]$All
)

$ErrorActionPreference = "Continue"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "    FINALIZACAO DOCKER COMPRAE      " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$baseDir = "c:\Users\jony_\Documents\GitHub\projeto-comprae"
Set-Location $baseDir

if ($Build -or $All) {
    Write-Host "=== STEP 1: BUILD IMAGES ===" -ForegroundColor Yellow
    
    # Build Config Server
    Write-Host "Building Config Server..." -ForegroundColor White
    docker build -t comprae/config-server ./comprae-config-server/config-server/
    
    # Build Produto Service
    Write-Host "Building Produto Service..." -ForegroundColor White
    docker build -t comprae/produto-service ./comprae-produto-service-new/
    
    Write-Host "Verificando imagens criadas:" -ForegroundColor Green
    docker images | findstr "comprae"
    Write-Host ""
}

if ($Start -or $All) {
    Write-Host "=== STEP 2: START ECOSYSTEM ===" -ForegroundColor Yellow
    
    Set-Location "$baseDir\comprae-infra"
    
    # Parar containers existentes
    Write-Host "Parando containers existentes..." -ForegroundColor White
    docker-compose down
    
    # Remover volumes orfaos
    Write-Host "Limpando volumes..." -ForegroundColor White
    docker volume prune -f
    
    # Iniciar infraestrutura
    Write-Host "Iniciando infraestrutura..." -ForegroundColor Green
    docker-compose up -d postgres redis kafka zookeeper elasticsearch kibana prometheus grafana zipkin
    
    # Aguardar infraestrutura
    Write-Host "Aguardando infraestrutura (30s)..." -ForegroundColor White
    Start-Sleep -Seconds 30
    
    # Iniciar microservicos
    Write-Host "Iniciando microservicos..." -ForegroundColor Green
    docker-compose up -d config-server
    
    # Aguardar config server
    Write-Host "Aguardando Config Server (20s)..." -ForegroundColor White
    Start-Sleep -Seconds 20
    
    # Iniciar produto service
    docker-compose up -d produto-service
    
    Write-Host "Sistema iniciado!" -ForegroundColor Green
    Write-Host ""
}

if ($Test -or $All) {
    Write-Host "=== STEP 3: TEST SYSTEM ===" -ForegroundColor Yellow
    
    Set-Location "$baseDir\comprae-infra"
    
    # Aguardar inicializacao
    Write-Host "Aguardando inicializacao completa (30s)..." -ForegroundColor White
    Start-Sleep -Seconds 30
    
    # Executar testes
    Write-Host "Executando testes..." -ForegroundColor Green
    .\testar-docker.ps1
}

Write-Host ""
Write-Host "=== COMANDOS UTEIS ===" -ForegroundColor Cyan
Write-Host "Build:     .\finalizar-docker.ps1 -Build" -ForegroundColor White
Write-Host "Start:     .\finalizar-docker.ps1 -Start" -ForegroundColor White
Write-Host "Test:      .\finalizar-docker.ps1 -Test" -ForegroundColor White
Write-Host "All:       .\finalizar-docker.ps1 -All" -ForegroundColor White
Write-Host ""
Write-Host "Ver logs:  docker-compose logs -f [servico]" -ForegroundColor White
Write-Host "Status:    docker-compose ps" -ForegroundColor White
Write-Host "Parar:     docker-compose down" -ForegroundColor White
Write-Host ""

if (-not $Build -and -not $Start -and -not $Test -and -not $All) {
    Write-Host "Use -All para executar todo o processo de finalizacao" -ForegroundColor Yellow
}
