# Script para iniciar todo el sistema (Backend + Frontend + DB)
Write-Host "🚀 Iniciando Sistema ERP Completo..." -ForegroundColor Green

# 1. Verificar Docker
Write-Host "`n1. Verificando Docker Desktop..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "   ✅ Docker instalado: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Docker no está instalado o no está corriendo" -ForegroundColor Red
    Write-Host "   Por favor, instala Docker Desktop y asegúrate de que esté corriendo." -ForegroundColor Yellow
    exit 1
}

# 2. Levantar servicios con Docker
Write-Host "`n2. Levantando servicios (Backend + DB)..." -ForegroundColor Yellow
docker-compose up -d backend db

# Esperar a que los servicios estén listos
Write-Host "   Esperando a que los servicios estén listos..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 3. Verificar servicios
Write-Host "`n3. Verificando servicios..." -ForegroundColor Yellow
docker-compose ps

# 4. Health check del backend
Write-Host "`n4. Verificando backend..." -ForegroundColor Yellow
$retries = 0
$maxRetries = 10
$backendReady = $false

while ($retries -lt $maxRetries -and -not $backendReady) {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method Get -TimeoutSec 2
        Write-Host "   ✅ Backend funcionando: $($response.status)" -ForegroundColor Green
        $backendReady = $true
    } catch {
        $retries++
        Write-Host "   Intento $retries/$maxRetries..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }
}

if (-not $backendReady) {
    Write-Host "   ⚠️  Backend tardó mucho en responder, pero puede estar iniciando..." -ForegroundColor Yellow
}

# 5. Inicializar base de datos (si es necesario)
Write-Host "`n5. Verificando base de datos..." -ForegroundColor Yellow
$dbCheck = docker-compose exec -T db psql -U postgres -d pos_db -c "SELECT 1;" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "   Creando base de datos..." -ForegroundColor Yellow
    docker-compose exec -T db psql -U postgres -c "CREATE DATABASE pos_db;"
    
    Write-Host "   Inicializando datos..." -ForegroundColor Yellow
    docker cp init_db.sql pos_db:/tmp/init_db.sql
    docker-compose exec -T db psql -U postgres -d pos_db -f /tmp/init_db.sql
} else {
    Write-Host "   ✅ Base de datos lista" -ForegroundColor Green
}

# 6. Instalar dependencias del frontend (si es necesario)
Write-Host "`n6. Preparando frontend..." -ForegroundColor Yellow
Set-Location -Path "frontend"

if (-Not (Test-Path "node_modules")) {
    Write-Host "   Instalando dependencias del frontend..." -ForegroundColor Yellow
    npm install
} else {
    Write-Host "   ✅ Dependencias del frontend ya instaladas" -ForegroundColor Green
}

Set-Location -Path ".."

# 7. Mostrar resumen
Write-Host "`n✅ Sistema iniciado correctamente!" -ForegroundColor Green
Write-Host "`n📚 URLs importantes:" -ForegroundColor Cyan
Write-Host "   Frontend:       http://localhost:3000" -ForegroundColor White
Write-Host "   Backend API:    http://localhost:8000" -ForegroundColor White
Write-Host "   API Docs:       http://localhost:8000/docs" -ForegroundColor White
Write-Host "   PostgreSQL:     localhost:5432" -ForegroundColor White

Write-Host "`n🔑 Credenciales de prueba:" -ForegroundColor Cyan
Write-Host "   admin / admin123 (ADMIN)" -ForegroundColor White
Write-Host "   cajero / cajero123 (CAJERO)" -ForegroundColor White

Write-Host "`n🚀 Opciones para iniciar el frontend:" -ForegroundColor Yellow
Write-Host "   Opción 1 (Desarrollo local - Recomendado):" -ForegroundColor Yellow
Write-Host "     .\start-frontend.ps1" -ForegroundColor White
Write-Host "`n   Opción 2 (Docker - Todo junto):" -ForegroundColor Yellow
Write-Host "     docker-compose up -d frontend" -ForegroundColor White

Write-Host "`n💡 Comandos útiles:" -ForegroundColor Cyan
Write-Host "   Ver logs:        docker-compose logs -f backend" -ForegroundColor White
Write-Host "   Detener todo:    docker-compose down" -ForegroundColor White
Write-Host "   Reiniciar:       docker-compose restart" -ForegroundColor White

Write-Host "`n🎉 ¡Listo para usar!" -ForegroundColor Green
