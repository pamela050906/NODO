# Script PowerShell para instalar dependencias en Windows
# Soluciona problemas de compilación usando wheels precompilados

Write-Host "🔧 Instalando dependencias para Windows..." -ForegroundColor Cyan

# Actualizar pip primero
Write-Host "`n1. Actualizando pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip setuptools wheel

# Instalar dependencias básicas primero (sin compilación)
Write-Host "`n2. Instalando dependencias básicas..." -ForegroundColor Yellow
pip install fastapi==0.109.0
pip install uvicorn[standard]==0.27.0
pip install python-dotenv==1.0.0

# Instalar pydantic (debería tener wheel)
Write-Host "`n3. Instalando pydantic..." -ForegroundColor Yellow
pip install pydantic==2.5.3 pydantic-settings==2.1.0

# Instalar SQLAlchemy y Alembic
Write-Host "`n4. Instalando SQLAlchemy..." -ForegroundColor Yellow
pip install sqlalchemy==2.0.25 alembic==1.13.1

# Intentar asyncpg con versión más antigua (tiene mejor soporte de wheels)
Write-Host "`n5. Instalando asyncpg (puede tomar tiempo)..." -ForegroundColor Yellow
pip install asyncpg==0.28.0 || Write-Host "⚠️  asyncpg falló, intentando versión más reciente..." -ForegroundColor Yellow; pip install asyncpg

# Instalar autenticación
Write-Host "`n6. Instalando módulos de autenticación..." -ForegroundColor Yellow
pip install python-jose[cryptography]==3.3.0
pip install passlib[bcrypt]==1.7.4
pip install bcrypt==3.2.2
pip install python-multipart==0.0.6

# Instalar QR codes
Write-Host "`n7. Instalando qrcode..." -ForegroundColor Yellow
pip install qrcode[pil]==7.4.2

# Intentar psycopg2-binary (opcional, puede fallar)
Write-Host "`n8. Intentando psycopg2-binary (opcional)..." -ForegroundColor Yellow
pip install psycopg2-binary==2.9.9 || Write-Host "⚠️  psycopg2-binary falló, pero no es crítico. El sistema funciona con asyncpg." -ForegroundColor Yellow

Write-Host "`n✅ Instalación completada!" -ForegroundColor Green
Write-Host "`nSi asyncpg falló, necesitarás instalar:" -ForegroundColor Yellow
Write-Host "  1. Microsoft Visual C++ Build Tools: https://visualstudio.microsoft.com/visual-cpp-build-tools/" -ForegroundColor Cyan
Write-Host "  2. O usar Docker para el backend (recomendado)" -ForegroundColor Cyan

Write-Host "`nPara verificar, ejecuta:" -ForegroundColor Yellow
Write-Host "  cd backend" -ForegroundColor White
Write-Host "  uvicorn app.main:app --reload" -ForegroundColor White
