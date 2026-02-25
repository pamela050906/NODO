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
pip install "pydantic>=2.10,<3" "pydantic-settings>=2.5,<3"

# Instalar SQLAlchemy y Alembic
Write-Host "`n4. Instalando SQLAlchemy..." -ForegroundColor Yellow
pip install sqlalchemy==2.0.25 alembic==1.13.1

# Driver PostgreSQL (psycopg v3, sin compilación en Windows)
Write-Host "`n5. Instalando driver PostgreSQL (psycopg)..." -ForegroundColor Yellow
pip install "psycopg[binary]>=3.1.18"

# Instalar autenticación
Write-Host "`n6. Instalando módulos de autenticación..." -ForegroundColor Yellow
pip install python-jose[cryptography]==3.3.0
pip install passlib[bcrypt]==1.7.4
pip install bcrypt==3.2.2
pip install python-multipart==0.0.6

# Instalar QR codes
Write-Host "`n7. Instalando qrcode..." -ForegroundColor Yellow
pip install qrcode[pil]==7.4.2

Write-Host "`n✅ Instalación completada!" -ForegroundColor Green

Write-Host "`nPara verificar, ejecuta:" -ForegroundColor Yellow
Write-Host "  cd backend" -ForegroundColor White
Write-Host "  uvicorn app.main:app --reload" -ForegroundColor White
