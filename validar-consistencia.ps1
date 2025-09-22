# Script de Validação de Consistência do Projeto Comprae
# Verifica configurações entre os repositórios individuais e a infraestrutura

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "     VALIDAÇÃO DE CONSISTÊNCIA - PROJETO COMPRAE    " -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

$issues = @()

Write-Host "🔍 Verificando consistência de configurações..." -ForegroundColor Yellow
Write-Host ""

# Função para adicionar issues
function Add-Issue {
    param($Category, $Description, $Severity = "WARNING")
    $script:issues += [PSCustomObject]@{
        Category = $Category
        Description = $Description
        Severity = $Severity
    }
}

# Verificar portas no docker-compose da infraestrutura
Write-Host "📋 Verificando docker-compose da infraestrutura..." -ForegroundColor Cyan

$infraComposeFile = ".\docker-compose.yml"
if (Test-Path $infraComposeFile) {
    $infraContent = Get-Content $infraComposeFile -Raw
    
    # Verificar PostgreSQL Config
    if ($infraContent -match 'postgres-config.*5432:5432') {
        Write-Host "   ✅ PostgreSQL Config: Porta 5432 OK" -ForegroundColor Green
    } else {
        Add-Issue "PostgreSQL" "Config DB não está na porta 5432" "ERROR"
    }
    
    # Verificar PostgreSQL Produto
    if ($infraContent -match 'postgres-produto.*5433:5432') {
        Write-Host "   ✅ PostgreSQL Produto: Porta 5433 OK" -ForegroundColor Green
    } else {
        Add-Issue "PostgreSQL" "Produto DB não está na porta 5433" "ERROR"
    }
    
    # Verificar Config Server
    if ($infraContent -match 'config-server.*8080:8080') {
        Write-Host "   ✅ Config Server: Porta 8080 OK" -ForegroundColor Green
    } else {
        Add-Issue "Config Server" "Não está na porta 8080" "ERROR"
    }
    
    # Verificar Produto Service
    if ($infraContent -match 'produto-service.*8081:8080') {
        Write-Host "   ✅ Produto Service: Porta 8081 OK" -ForegroundColor Green
    } else {
        Add-Issue "Produto Service" "Não está na porta 8081" "ERROR"
    }
    
    # Verificar credenciais
    if ($infraContent -match 'SPRING_DATASOURCE_USERNAME:\s*admin' -and $infraContent -match 'SPRING_DATASOURCE_PASSWORD:\s*admin123') {
        Write-Host "   ✅ Credenciais: admin/admin123 OK" -ForegroundColor Green
    } else {
        Add-Issue "Credenciais" "Credenciais não estão padronizadas como admin/admin123" "WARNING"
    }
    
} else {
    Add-Issue "Infraestrutura" "docker-compose.yml não encontrado" "ERROR"
}

Write-Host ""

# Verificar repositórios individuais
Write-Host "📋 Verificando repositórios individuais..." -ForegroundColor Cyan

# Config Server
$configServerPath = "..\comprae-config-server\docker-compose.yml"
if (Test-Path $configServerPath) {
    $configContent = Get-Content $configServerPath -Raw
    if ($configContent -match '8080:8080') {
        Write-Host "   ✅ Config Server Individual: Porta 8080 OK" -ForegroundColor Green
    } else {
        Add-Issue "Config Server Individual" "Porta diferente de 8080" "WARNING"
    }
} else {
    Add-Issue "Config Server" "docker-compose.yml individual não encontrado" "WARNING"
}

# Produto Service
$produtoServicePath = "..\comprae-produto-service\docker-compose.yml"
if (Test-Path $produtoServicePath) {
    $produtoContent = Get-Content $produtoServicePath -Raw
    if ($produtoContent -match '8080:8080') {
        Write-Host "   ✅ Produto Service Individual: Porta 8080 OK" -ForegroundColor Green
    } else {
        Add-Issue "Produto Service Individual" "Porta diferente de 8080" "WARNING"
    }
} else {
    Add-Issue "Produto Service" "docker-compose.yml individual não encontrado" "WARNING"
}

Write-Host ""

# Verificar scripts
Write-Host "📋 Verificando scripts de execução..." -ForegroundColor Cyan

$scripts = @(
    ".\executar-projeto-completo.ps1",
    ".\iniciar-docker-completo.ps1",
    "..\comprae-config-server\scripts\executar-docker.ps1",
    "..\comprae-produto-service\scripts\executar-docker.ps1"
)

foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "   ✅ $(Split-Path $script -Leaf): Encontrado" -ForegroundColor Green
    } else {
        Add-Issue "Scripts" "Script não encontrado: $script" "WARNING"
    }
}

Write-Host ""

# Verificar imagens Docker
Write-Host "📋 Verificando imagens Docker..." -ForegroundColor Cyan

$configImage = docker images -q comprae/config-server:latest 2>$null
$produtoImage = docker images -q comprae/produto-service:latest 2>$null

if ($configImage) {
    Write-Host "   ✅ comprae/config-server:latest: Disponível" -ForegroundColor Green
} else {
    Add-Issue "Docker Images" "comprae/config-server:latest não encontrada" "WARNING"
}

if ($produtoImage) {
    Write-Host "   ✅ comprae/produto-service:latest: Disponível" -ForegroundColor Green
} else {
    Add-Issue "Docker Images" "comprae/produto-service:latest não encontrada" "WARNING"
}

Write-Host ""

# Resumo dos resultados
Write-Host "📊 RESUMO DA VALIDAÇÃO" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

if ($issues.Count -eq 0) {
    Write-Host "🎉 Nenhum problema encontrado! Projeto está consistente." -ForegroundColor Green
} else {
    $errors = ($issues | Where-Object { $_.Severity -eq "ERROR" }).Count
    $warnings = ($issues | Where-Object { $_.Severity -eq "WARNING" }).Count
    
    Write-Host "Total de issues: $($issues.Count)" -ForegroundColor Yellow
    Write-Host "   Erros: $errors" -ForegroundColor Red
    Write-Host "   Avisos: $warnings" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Detalhes:" -ForegroundColor White
    foreach ($issue in $issues) {
        $color = if ($issue.Severity -eq "ERROR") { "Red" } else { "Yellow" }
        Write-Host "   [$($issue.Severity)] $($issue.Category): $($issue.Description)" -ForegroundColor $color
    }
}

Write-Host ""

# Sugestões
Write-Host "💡 PRÓXIMOS PASSOS RECOMENDADOS:" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

if ($issues.Count -eq 0) {
    Write-Host "1. Execute: .\executar-projeto-completo.ps1 -Background" -ForegroundColor Green
    Write-Host "2. Aguarde todos os serviços subirem" -ForegroundColor Green
    Write-Host "3. Teste os endpoints principais" -ForegroundColor Green
} else {
    Write-Host "1. Corrija os erros listados acima" -ForegroundColor Yellow
    Write-Host "2. Execute esta validação novamente" -ForegroundColor Yellow
    Write-Host "3. Após corrigir, execute o projeto completo" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Validacao concluida!" -ForegroundColor Green