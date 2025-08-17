# Script para finalizar todos os containers Docker do Compraê

$baseDir = "c:\Users\jony_\Documents\GitHub\projeto-comprae"
Set-Location $baseDir

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host " FINALIZANDO DOCKER COMPRAE " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Parando e removendo todos os containers e volumes..." -ForegroundColor Yellow

# Parar e remover todos os containers do projeto
cd "$baseDir\comprae-infra"
docker-compose down -v

Write-Host "Todos os containers e volumes do Compraê foram finalizados!" -ForegroundColor Green
