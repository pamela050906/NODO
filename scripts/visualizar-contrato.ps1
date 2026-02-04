# Script para visualizar el contrato OpenAPI
Write-Host "📋 Visualizador de Contrato API" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

$openApiFile = "openapi.yaml"

# Verificar que existe el archivo
if (-Not (Test-Path $openApiFile)) {
    Write-Host "❌ No se encontró el archivo $openApiFile" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Archivo encontrado: $openApiFile`n" -ForegroundColor Green

Write-Host "🎯 Opciones para visualizar el contrato:`n" -ForegroundColor Yellow

Write-Host "1️⃣  Swagger UI (cuando el backend esté corriendo)" -ForegroundColor White
Write-Host "   URL: http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host "   Permite probar endpoints directamente`n"

Write-Host "2️⃣  Swagger Editor Online" -ForegroundColor White
Write-Host "   URL: https://editor.swagger.io/" -ForegroundColor Cyan
Write-Host "   Copia y pega el contenido de openapi.yaml`n"

Write-Host "3️⃣  VS Code con extensión" -ForegroundColor White
Write-Host "   Extensión: 'Swagger Viewer' o 'OpenAPI (Swagger) Editor'" -ForegroundColor Cyan
Write-Host "   Abre openapi.yaml y visualiza con la extensión`n"

Write-Host "4️⃣  Importar en Postman" -ForegroundColor White
Write-Host "   File → Import → Selecciona openapi.yaml" -ForegroundColor Cyan
Write-Host "   Genera automáticamente colección de requests`n"

Write-Host "5️⃣  Redoc (cuando el backend esté corriendo)" -ForegroundColor White
Write-Host "   URL: http://localhost:8000/redoc" -ForegroundColor Cyan
Write-Host "   Documentación más limpia y legible`n"

Write-Host "📊 Estadísticas del contrato:" -ForegroundColor Yellow
$content = Get-Content $openApiFile -Raw
$pathsCount = ([regex]::Matches($content, "^\s{2}/", [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
$schemasCount = ([regex]::Matches($content, "^\s{4}\w+:", [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count / 2

Write-Host "   📍 Endpoints definidos: ~$pathsCount" -ForegroundColor Cyan
Write-Host "   📦 Schemas definidos: ~$($schemasCount.ToString('F0'))" -ForegroundColor Cyan

Write-Host "`n💡 Recomendación:" -ForegroundColor Yellow
Write-Host "   1. Inicia el backend: .\start-all.ps1" -ForegroundColor White
Write-Host "   2. Abre: http://localhost:8000/docs" -ForegroundColor White
Write-Host "   3. Prueba el endpoint /auth/login con admin/admin123" -ForegroundColor White
Write-Host "   4. Copia el token y úsalo en otros endpoints`n" -ForegroundColor White

Write-Host "📚 Documentación completa: API_CONTRACT.md`n" -ForegroundColor Cyan

# Opción para abrir en navegador
Write-Host "¿Quieres abrir Swagger Editor online? (S/N)" -ForegroundColor Yellow -NoNewline
$response = Read-Host " "

if ($response -eq "S" -or $response -eq "s") {
    Start-Process "https://editor.swagger.io/"
    Write-Host "`n✅ Abriendo Swagger Editor..." -ForegroundColor Green
    Write-Host "   Copia el contenido de openapi.yaml y pégalo en el editor" -ForegroundColor White
}

Write-Host "`n✅ Listo!" -ForegroundColor Green
