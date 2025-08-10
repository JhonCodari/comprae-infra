# Verificar Status do Sistema Compraê
# Este script verifica se todos os serviços estão funcionando corretamente

param(
    [switch]$Detailed,
    [switch]$Continuous,
    [int]$Interval = 30
)

function Show-Header {
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "   Verificação Sistema Compraê      " -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
}

function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$Url,
        [int]$TimeoutSeconds = 10
    )
    
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec $TimeoutSeconds -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            return @{
                Status = "✅ OK"
                ResponseTime = $response.Headers.'X-Response-Time-Milliseconds'
                StatusCode = $response.StatusCode
            }
        } else {
            return @{
                Status = "⚠️ AVISO"
                ResponseTime = "N/A"
                StatusCode = $response.StatusCode
            }
        }
    }
    catch {
        return @{
            Status = "❌ FALHA"
            ResponseTime = "N/A"
            StatusCode = $_.Exception.Message
        }
    }
}

function Show-ContainerStatus {
    Write-Host "📊 Status dos Containers:" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        $containers = docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
        Write-Host $containers
    }
    catch {
        Write-Host "❌ Erro ao obter status dos containers!" -ForegroundColor Red
        return $false
    }
    
    Write-Host ""
    return $true
}

function Show-ServiceHealthStatus {
    Write-Host "🏥 Status de Saúde dos Serviços:" -ForegroundColor Cyan
    Write-Host ""
    
    $services = @(
        @{ Name = "Config Server"; Url = "http://localhost:8888/actuator/health" },
        @{ Name = "Produto Service"; Url = "http://localhost:8082/actuator/health" },
        @{ Name = "PostgreSQL"; Url = "http://localhost:5432" }, # TCP check
        @{ Name = "Redis"; Url = "http://localhost:6379" }, # TCP check
        @{ Name = "Kafka"; Url = "http://localhost:9092" }, # TCP check
        @{ Name = "Elasticsearch"; Url = "http://localhost:9200/_cluster/health" },
        @{ Name = "Kibana"; Url = "http://localhost:5601/api/status" },
        @{ Name = "Prometheus"; Url = "http://localhost:9090/-/healthy" },
        @{ Name = "Grafana"; Url = "http://localhost:3000/api/health" },
        @{ Name = "Kafka UI"; Url = "http://localhost:8090" },
        @{ Name = "Zipkin"; Url = "http://localhost:9411/health" }
    )
    
    $healthyCount = 0
    $totalCount = $services.Count
    
    foreach ($service in $services) {
        $health = Test-ServiceHealth -ServiceName $service.Name -Url $service.Url
        
        if ($health.Status -eq "✅ OK") {
            $healthyCount++
        }
        
        if ($Detailed) {
            Write-Host ("  {0,-20} {1,-12} [{2}]" -f $service.Name, $health.Status, $health.StatusCode) -ForegroundColor $(
                if ($health.Status -eq "✅ OK") { "Green" }
                elseif ($health.Status -eq "⚠️ AVISO") { "Yellow" }
                else { "Red" }
            )
        } else {
            Write-Host ("  {0,-20} {1}" -f $service.Name, $health.Status) -ForegroundColor $(
                if ($health.Status -eq "✅ OK") { "Green" }
                elseif ($health.Status -eq "⚠️ AVISO") { "Yellow" }
                else { "Red" }
            )
        }
    }
    
    Write-Host ""
    Write-Host ("📈 Saúde Geral: {0}/{1} serviços funcionando ({2:P0})" -f $healthyCount, $totalCount, ($healthyCount/$totalCount)) -ForegroundColor $(
        if ($healthyCount -eq $totalCount) { "Green" }
        elseif ($healthyCount -gt ($totalCount * 0.7)) { "Yellow" }
        else { "Red" }
    )
    
    return @{
        Healthy = $healthyCount
        Total = $totalCount
        Percentage = ($healthyCount/$totalCount)
    }
}

function Show-ResourceUsage {
    Write-Host "💻 Uso de Recursos:" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        $stats = docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
        Write-Host $stats
    }
    catch {
        Write-Host "❌ Erro ao obter estatísticas de recursos!" -ForegroundColor Red
    }
    
    Write-Host ""
}

function Show-NetworkInfo {
    Write-Host "🌐 Informações de Rede:" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        $networks = docker network ls --filter "name=comprae" --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
        Write-Host $networks
    }
    catch {
        Write-Host "❌ Erro ao obter informações de rede!" -ForegroundColor Red
    }
    
    Write-Host ""
}

function Show-VolumeInfo {
    Write-Host "💾 Informações de Volumes:" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        $volumes = docker volume ls --filter "name=comprae" --format "table {{.Name}}\t{{.Driver}}\t{{.Size}}"
        Write-Host $volumes
    }
    catch {
        Write-Host "❌ Erro ao obter informações de volumes!" -ForegroundColor Red
    }
    
    Write-Host ""
}

function Show-QuickActions {
    Write-Host "⚡ Ações Rápidas:" -ForegroundColor Cyan
    Write-Host "  • Ver logs: docker-compose logs -f [serviço]" -ForegroundColor White
    Write-Host "  • Reiniciar serviço: docker-compose restart [serviço]" -ForegroundColor White
    Write-Host "  • Parar sistema: docker-compose down" -ForegroundColor White
    Write-Host "  • Verificar novamente: .\verificar-sistema.ps1" -ForegroundColor White
    Write-Host ""
}

# Função principal de verificação
function Invoke-SystemCheck {
    Show-Header
    
    # Verificar se o Docker está rodando
    try {
        docker ps > $null 2>&1
    }
    catch {
        Write-Host "❌ Docker não está em execução!" -ForegroundColor Red
        Write-Host "Inicie o Docker Desktop e tente novamente." -ForegroundColor Yellow
        return $false
    }
    
    # Verificar containers
    $containersOk = Show-ContainerStatus
    
    if (-not $containersOk) {
        return $false
    }
    
    # Verificar saúde dos serviços
    $healthStatus = Show-ServiceHealthStatus
    
    if ($Detailed) {
        Show-ResourceUsage
        Show-NetworkInfo
        Show-VolumeInfo
    }
    
    Show-QuickActions
    
    # Timestamp
    Write-Host ("🕐 Última verificação: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")) -ForegroundColor Gray
    Write-Host ""
    
    return $healthStatus.Percentage -eq 1.0
}

# Execução principal
do {
    $success = Invoke-SystemCheck
    
    if ($Continuous) {
        Write-Host ("⏰ Próxima verificação em {0} segundos... (Ctrl+C para parar)" -f $Interval) -ForegroundColor Yellow
        Start-Sleep $Interval
        Clear-Host
    }
} while ($Continuous)

if (-not $success) {
    exit 1
}
