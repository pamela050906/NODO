# Script para iniciar el frontend en Windows
Write-Host "🚀 Iniciando Frontend React..." -ForegroundColor Green

# Navegar al directorio del frontend
Set-Location -Path "frontend"

# Verificar si existe node_modules
if (-Not (Test-Path "node_modules")) {
    Write-Host "`n📦 Instalando dependencias..." -ForegroundColor Yellow
    npm install
} else {
    Write-Host "`n✅ Dependencias ya instaladas" -ForegroundColor Green
}

# Verificar si el backend está corriendo
Write-Host "`n🔍 Verificando backend..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method Get -TimeoutSec 2
    Write-Host "   ✅ Backend corriendo en http://localhost:8000" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️  Backend no detectado en http://localhost:8000" -ForegroundColor Yellow
    Write-Host "   Por favor, inicia el backend primero." -ForegroundColor Yellow
}

# Iniciar el frontend
Write-Host "`n🌐 Iniciando servidor de desarrollo..." -ForegroundColor Cyan
Write-Host "   Frontend: http://localhost:3000" -ForegroundColor White
Write-Host "   Backend:  http://localhost:8000" -ForegroundColor White
Write-Host "`n💡 Presiona Ctrl+C para detener`n" -ForegroundColor Yellow

npm start
