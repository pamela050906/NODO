"""Script para generar hash bcrypt de contraseñas."""
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Generar hashes
admin_hash = pwd_context.hash("admin123")
cajero_hash = pwd_context.hash("cajero123")

print("=" * 60)
print("HASHES BCRYPT GENERADOS")
print("=" * 60)
print(f"\nPassword: admin123")
print(f"Hash: {admin_hash}")
print(f"\nPassword: cajero123")
print(f"Hash: {cajero_hash}")
print("\n" + "=" * 60)
print("\nUSA ESTOS HASHES PARA ACTUALIZAR LA BASE DE DATOS:")
print("=" * 60)
print(f"\nUPDATE usuarios SET password_hash = '{admin_hash}' WHERE email = 'admin@local.com';")
print(f"UPDATE usuarios SET password_hash = '{cajero_hash}' WHERE email = 'cajero@local.com';")
print()
