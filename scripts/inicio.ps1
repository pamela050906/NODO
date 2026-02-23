# Script de inicio rápido para Windows - Backend POS
# Uso: .\inicio.ps1

Write-Host "🚀 Iniciando Backend POS..." -ForegroundColor Green
Write-Host ""

# 1. Levantar servicios
Write-Host "1. Levantando servicios Docker..." -ForegroundColor Yellow
docker compose -f docker/docker-compose.yml up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Error al levantar servicios Docker" -ForegroundColor Red
    Write-Host "   Verifica que Docker Desktop esté corriendo" -ForegroundColor Yellow
    exit 1
}

# Esperar a que estén listos
Write-Host "   Esperando a que los servicios estén listos..." -ForegroundColor Gray
Start-Sleep -Seconds 8

# 2. Verificar servicios
Write-Host "`n2. Verificando servicios..." -ForegroundColor Yellow
docker compose -f docker/docker-compose.yml ps

# 3. Verificar si la DB necesita inicialización
Write-Host "`n3. Verificando base de datos..." -ForegroundColor Yellow

# Intentar conectar a la base de datos
$dbCheck = docker compose -f docker/docker-compose.yml exec -T db psql -U postgres -d pos_db -c "SELECT 1;" 2>&1

if ($LASTEXITCODE -ne 0 -or $dbCheck -match "does not exist" -or $dbCheck -match "could not connect") {
    Write-Host "   Base de datos no existe o no está lista, creándola..." -ForegroundColor Yellow
    
    # Crear base de datos si no existe
    docker compose -f docker/docker-compose.yml exec -T db psql -U postgres -c "CREATE DATABASE pos_db;" 2>&1 | Out-Null
    
    Write-Host "   Inicializando datos..." -ForegroundColor Yellow
    docker cp docs/almacen_db.sql pos_db:/tmp/almacen_db.sql
    
    if ($LASTEXITCODE -eq 0) {
        docker compose -f docker/docker-compose.yml exec -T db psql -U postgres -d pos_db -f /tmp/almacen_db.sql 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Base de datos inicializada correctamente" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  Error al inicializar, pero puedes continuar" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ⚠️  No se pudo copiar docs/almacen_db.sql" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ✅ Base de datos ya existe y está lista" -ForegroundColor Green
}

# 4. Health check
Write-Host "`n4. Verificando API..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$maxRetries = 5
$retry = 0
$apiReady = $false

while ($retry -lt $maxRetries -and -not $apiReady) {
    try {
        $health = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method Get -TimeoutSec 3
        if ($health.status -eq "healthy") {
            Write-Host "   ✅ API funcionando correctamente" -ForegroundColor Green
            $apiReady = $true
        }
    } catch {
        $retry++
        if ($retry -lt $maxRetries) {
            Write-Host "   Esperando API... (intento $retry/$maxRetries)" -ForegroundColor Gray
            Start-Sleep -Seconds 3
        } else {
            Write-Host "   ⚠️  API aún no responde, pero los servicios están corriendo" -ForegroundColor Yellow
            Write-Host "   Espera unos segundos más y verifica manualmente" -ForegroundColor Yellow
        }
    }
}

# 5. Mostrar URLs y resumen
Write-Host "`n" + ("="*60) -ForegroundColor Cyan
Write-Host "✅ Backend iniciado correctamente!" -ForegroundColor Green
Write-Host ("="*60) -ForegroundColor Cyan

Write-Host "`n📚 URLs importantes:" -ForegroundColor Cyan
Write-Host "   🌐 API:        http://localhost:8000" -ForegroundColor White
Write-Host "   📖 Docs:       http://localhost:8000/docs" -ForegroundColor White
Write-Host "   ❤️  Health:     http://localhost:8000/health" -ForegroundColor White

Write-Host "`n🔑 Usuarios de prueba:" -ForegroundColor Cyan
Write-Host "   👤 admin  / admin123  (ADMIN)" -ForegroundColor White
Write-Host "   👤 cajero / cajero123 (CAJERO)" -ForegroundColor White

Write-Host "`n💡 Tips:" -ForegroundColor Cyan
Write-Host "   • Abre http://localhost:8000/docs para probar los endpoints" -ForegroundColor Gray
Write-Host "   • Usa 'Authorize' (botón verde) para autenticarte" -ForegroundColor Gray
Write-Host "   • Ver logs: docker compose -f docker/docker-compose.yml logs -f backend" -ForegroundColor Gray

Write-Host "`n" + ("="*60) -ForegroundColor Cyan

# Preguntar si quiere abrir el navegador
$abrir = Read-Host "`n¿Abrir documentación en el navegador? (S/N)"
if ($abrir -eq "S" -or $abrir -eq "s" -or $abrir -eq "Y" -or $abrir -eq "y") {
    Start-Process "http://localhost:8000/docs"
    Write-Host "`n✅ Navegador abierto" -ForegroundColor Green
}

Write-Host "`n✨ ¡Listo para usar!" -ForegroundColor Green
