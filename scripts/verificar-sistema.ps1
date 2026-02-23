# Script de verificación del sistema ERP
Write-Host "🔍 Verificando Sistema ERP..." -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

$allOk = $true

# 1. Verificar Docker
Write-Host "1. Docker Desktop" -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "   ✅ Docker instalado: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Docker no encontrado" -ForegroundColor Red
    $allOk = $false
}

# 2. Verificar Node.js
Write-Host "`n2. Node.js" -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "   ✅ Node.js instalado: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Node.js no encontrado" -ForegroundColor Red
    $allOk = $false
}

# 3. Verificar npm
Write-Host "`n3. npm" -ForegroundColor Yellow
try {
    $npmVersion = npm --version
    Write-Host "   ✅ npm instalado: v$npmVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ npm no encontrado" -ForegroundColor Red
    $allOk = $false
}

# 4. Verificar archivos del backend
Write-Host "`n4. Archivos del Backend" -ForegroundColor Yellow
$backendFiles = @(
    "backend\app\main.py",
    "docker\docker-compose.yml",
    "docker\Dockerfile",
    "backend\requirements.txt",
    "docs\almacen_db.sql"
)

foreach ($file in $backendFiles) {
    if (Test-Path $file) {
        Write-Host "   ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $file no encontrado" -ForegroundColor Red
        $allOk = $false
    }
}

# 5. Verificar archivos del frontend
Write-Host "`n5. Archivos del Frontend" -ForegroundColor Yellow
$frontendFiles = @(
    "frontend\package.json",
    "frontend\src\App.js",
    "frontend\src\index.js",
    "frontend\public\index.html"
)

foreach ($file in $frontendFiles) {
    if (Test-Path $file) {
        Write-Host "   ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $file no encontrado" -ForegroundColor Red
        $allOk = $false
    }
}

# 6. Verificar dependencias del frontend
Write-Host "`n6. Dependencias del Frontend" -ForegroundColor Yellow
if (Test-Path "frontend\node_modules") {
    Write-Host "   ✅ node_modules instalado" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  node_modules no encontrado (ejecuta: cd frontend && npm install)" -ForegroundColor Yellow
}

# 7. Verificar servicios Docker
Write-Host "`n7. Servicios Docker" -ForegroundColor Yellow
try {
    $dockerPS = docker compose -f docker/docker-compose.yml ps --services 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Docker Compose configurado" -ForegroundColor Green
    }
} catch {
    Write-Host "   ⚠️  No se pudo verificar servicios Docker" -ForegroundColor Yellow
}

# 8. Verificar si los servicios están corriendo
Write-Host "`n8. Estado de Servicios" -ForegroundColor Yellow

# Backend
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method Get -TimeoutSec 2
    Write-Host "   ✅ Backend corriendo en http://localhost:8000" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Backend no está corriendo (ejecuta: docker compose -f docker/docker-compose.yml up -d backend)" -ForegroundColor Yellow
}

# Frontend
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -Method Get -TimeoutSec 2
    Write-Host "   ✅ Frontend corriendo en http://localhost:3000" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Frontend no está corriendo (ejecuta: cd frontend && npm start)" -ForegroundColor Yellow
}

# Base de datos
try {
    $dbCheck = docker compose -f docker/docker-compose.yml exec -T db psql -U postgres -d pos_db -c "SELECT 1;" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Base de datos configurada" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Base de datos no inicializada" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠️  Base de datos no accesible" -ForegroundColor Yellow
}

# Resumen final
Write-Host "`n================================" -ForegroundColor Cyan
if ($allOk) {
    Write-Host "✅ SISTEMA LISTO" -ForegroundColor Green
    Write-Host "`n🚀 Para iniciar:" -ForegroundColor Cyan
    Write-Host "   1. .\start-all.ps1        (Inicia backend + DB)" -ForegroundColor White
    Write-Host "   2. .\start-frontend.ps1   (Inicia frontend)" -ForegroundColor White
} else {
    Write-Host "⚠️  REVISA LOS ERRORES ARRIBA" -ForegroundColor Yellow
    Write-Host "`nInstalaciones necesarias:" -ForegroundColor Cyan
    Write-Host "   - Docker Desktop: https://www.docker.com/products/docker-desktop" -ForegroundColor White
    Write-Host "   - Node.js: https://nodejs.org/" -ForegroundColor White
}

Write-Host "`n📚 Documentación:" -ForegroundColor Cyan
Write-Host "   - INICIO_COMPLETO.md      (Guía completa)" -ForegroundColor White
Write-Host "   - FRONTEND_README.md      (Guía del frontend)" -ForegroundColor White
Write-Host "   - INICIO_WINDOWS.md       (Guía del backend)" -ForegroundColor White

Write-Host ""
