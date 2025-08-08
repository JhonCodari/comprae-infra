param(
    [Parameter(Position=0)]
    [string]$ServiceName = ""
)

$ErrorActionPreference = "SilentlyContinue"

# Definição dos serviços e seus endpoints de health check
$Services = @(
    @{Name="config-server"; Port=8888; Endpoint="/actuator/health"},
    @{Name="eureka-server"; Port=8761; Endpoint="/actuator/health"},
    @{Name="api-gateway"; Port=8080; Endpoint="/actuator/health"},
    @{Name="user-service"; Port=8081; Endpoint="/actuator/health"},
    @{Name="product-service"; Port=8082; Endpoint="/actuator/health"},
    @{Name="order-service"; Port=8083; Endpoint="/actuator/health"},
    @{Name="payment-service"; Port=8084; Endpoint="/actuator/health"},
    @{Name="notification-service"; Port=8085; Endpoint="/actuator/health"},
    @{Name="postgres"; Port=5432; Endpoint=""},
    @{Name="redis"; Port=6379; Endpoint=""},
    @{Name="rabbitmq"; Port=15672; Endpoint="/api/overview"},
    @{Name="elasticsearch"; Port=9200; Endpoint="/_cluster/health"},
    @{Name="grafana"; Port=3000; Endpoint="/api/health"},
    @{Name="prometheus"; Port=9090; Endpoint="/-/healthy"},
    @{Name="zipkin"; Port=9411; Endpoint="/health"}
)

function Test-ServiceHealth {
    param(
        [hashtable]$Service
    )
    
    if ($Service.Endpoint -ne "") {
        # HTTP health check
        $url = "http://localhost:$($Service.Port)$($Service.Endpoint)"
        try {
            $response = Invoke-WebRequest -Uri $url -TimeoutSec 5 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Host "✅ $($Service.Name): Saudável ($url)" -ForegroundColor Green
                return $true
            } else {
                Write-Host "❌ $($Service.Name): Status $($response.StatusCode) ($url)" -ForegroundColor Red
                return $false
            }
        }
        catch {
            Write-Host "❌ $($Service.Name): Falha na verificação ($url)" -ForegroundColor Red
            return $false
        }
    } else {
        # TCP health check
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $connect = $tcpClient.BeginConnect("localhost", $Service.Port, $null, $null)
            $wait = $connect.AsyncWaitHandle.WaitOne(3000, $false)
            
            if ($wait) {
                $tcpClient.EndConnect($connect)
                $tcpClient.Close()
                Write-Host "✅ $($Service.Name): Porta $($Service.Port) respondendo" -ForegroundColor Green
                return $true
            } else {
                Write-Host "❌ $($Service.Name): Timeout na porta $($Service.Port)" -ForegroundColor Red
                return $false
            }
        }
        catch {
            Write-Host "❌ $($Service.Name): Porta $($Service.Port) não está respondendo" -ForegroundColor Red
            return $false
        }
        finally {
            if ($tcpClient) {
                $tcpClient.Close()
            }
        }
    }
}

function Show-HealthSummary {
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "       COMPRAE HEALTH CHECK" -ForegroundColor Cyan
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host ""
    
    $failedServices = 0
    $totalServices = 0
    
    foreach ($service in $Services) {
        # Se um serviço específico foi fornecido, verificar apenas ele
        if ($ServiceName -ne "" -and $service.Name -ne $ServiceName) {
            continue
        }
        
        $totalServices++
        
        if (-not (Test-ServiceHealth -Service $service)) {
            $failedServices++
        }
    }
    
    Write-Host ""
    Write-Host "==================================" -ForegroundColor Cyan
    $healthyServices = $totalServices - $failedServices
    Write-Host "Resumo: $healthyServices/$totalServices serviços saudáveis" -ForegroundColor White
    
    if ($failedServices -eq 0) {
        Write-Host "🎉 Todos os serviços estão funcionando!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "⚠️  $failedServices serviço(s) com problemas" -ForegroundColor Yellow
        return $false
    }
}

function Show-DetailedStatus {
    Write-Host ""
    Write-Host "Status detalhado dos containers:" -ForegroundColor Cyan
    try {
        docker-compose ps
    }
    catch {
        Write-Host "❌ Erro ao executar docker-compose ps" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Uso de recursos:" -ForegroundColor Cyan
    try {
        docker stats --no-stream
    }
    catch {
        Write-Host "❌ Erro ao executar docker stats" -ForegroundColor Red
    }
}

# Execução principal
$isHealthy = Show-HealthSummary

if ($ServiceName -eq "") {
    Show-DetailedStatus
}

if (-not $isHealthy) {
    exit 1
}
