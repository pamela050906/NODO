# Script para crear usuarios por defecto en Docker
# Ejecutar desde PowerShell: .\scripts\crear_usuarios_docker.ps1

Write-Host "Creando usuarios por defecto en la base de datos..." -ForegroundColor Cyan

$comando = @"
from app.core.database import SessionLocal
from app.models.usuario import Usuario
from app.core.security import get_password_hash

db = SessionLocal()
usuarios = [
    ('Admin', 'admin@local.com', 'admin123', 1),
    ('Cajero', 'cajero@local.com', 'cajero123', 2)
]

for name, email, pwd, rol_id in usuarios:
    if db.query(Usuario).filter(Usuario.nombre == name).first():
        print(f'Usuario {name} ya existe')
        continue
    u = Usuario(nombre=name, email=email, password_hash=get_password_hash(pwd), rol_id=rol_id, activo=True)
    db.add(u)
    print(f'Creado: {name}')

db.commit()
db.close()
print('Usuarios creados exitosamente.')
"@

docker exec -it pos_backend python -c $comando

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✓ Usuarios creados correctamente." -ForegroundColor Green
    Write-Host "`nCredenciales:" -ForegroundColor Yellow
    Write-Host "  Admin  / admin123" -ForegroundColor White
    Write-Host "  Cajero / cajero123" -ForegroundColor White
} else {
    Write-Host "`n✗ Error al crear usuarios. Verifica que el contenedor 'pos_backend' esté corriendo." -ForegroundColor Red
    Write-Host "Ejecuta: docker ps" -ForegroundColor Yellow
}
