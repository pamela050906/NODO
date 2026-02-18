#!/usr/bin/env python3
"""
Script para crear usuarios en la base de datos.

Ejecutar desde la raíz del proyecto:
    python scripts/crear_usuario.py

O crear usuarios específicos:
    python scripts/crear_usuario.py --nombre Admin --password admin123 --rol 1 --email admin@local.com
"""
import sys
import argparse
from pathlib import Path

# Permitir importar app (backend/app) cuando se ejecuta desde la raíz del repo
root = Path(__file__).resolve().parent.parent
backend = root / "backend"
if backend.exists():
    sys.path.insert(0, str(backend))
if str(root) not in sys.path:
    sys.path.insert(0, str(root))

def main():
    parser = argparse.ArgumentParser(description='Crear usuario en la base de datos')
    parser.add_argument('--nombre', type=str, help='Nombre de usuario (username)')
    parser.add_argument('--password', type=str, help='Contraseña')
    parser.add_argument('--email', type=str, help='Email del usuario')
    parser.add_argument('--rol', type=int, choices=[1, 2], help='ID del rol (1=ADMIN, 2=CAJERO)', default=1)
    parser.add_argument('--crear-defaults', action='store_true', help='Crear usuarios por defecto (Admin y Cajero)')
    
    args = parser.parse_args()
    
    try:
        from app.core.database import SessionLocal
        from app.models.usuario import Usuario
        from app.core.security import get_password_hash
        from sqlalchemy import text
        
        db = SessionLocal()
        
        # Verificar que la tabla roles existe y tiene datos
        result = db.execute(text("SELECT id, nombre FROM roles ORDER BY id"))
        roles = result.fetchall()
        
        if not roles:
            print("Error: No se encontraron roles en la base de datos.")
            print("Asegúrate de que la base de datos esté inicializada correctamente.")
            db.close()
            return
        
        print("Roles disponibles:")
        for rol_id, rol_nombre in roles:
            print(f"  {rol_id}: {rol_nombre}")
        print()
        
        if args.crear_defaults:
            # Crear usuarios por defecto
            usuarios_default = [
                {
                    'nombre': 'Admin',
                    'email': 'admin@local.com',
                    'password': 'admin123',
                    'rol_id': 1  # ADMIN
                },
                {
                    'nombre': 'Cajero',
                    'email': 'cajero@local.com',
                    'password': 'cajero123',
                    'rol_id': 2  # CAJERO
                }
            ]
            
            for usuario_data in usuarios_default:
                # Verificar si el usuario ya existe
                usuario_existente = db.query(Usuario).filter(
                    Usuario.nombre == usuario_data['nombre']
                ).first()
                
                if usuario_existente:
                    print(f"⚠ Usuario '{usuario_data['nombre']}' ya existe. Saltando...")
                    continue
                
                nuevo_usuario = Usuario(
                    nombre=usuario_data['nombre'],
                    email=usuario_data['email'],
                    password_hash=get_password_hash(usuario_data['password']),
                    rol_id=usuario_data['rol_id'],
                    activo=True
                )
                
                db.add(nuevo_usuario)
                print(f"✓ Usuario '{usuario_data['nombre']}' creado exitosamente")
                print(f"  Email: {usuario_data['email']}")
                print(f"  Password: {usuario_data['password']}")
                print(f"  Rol: {usuario_data['rol_id']}")
                print()
            
            db.commit()
            print("Usuarios por defecto creados exitosamente!")
            
        elif args.nombre and args.password and args.email:
            # Crear usuario específico
            # Verificar si el usuario ya existe
            usuario_existente = db.query(Usuario).filter(
                (Usuario.nombre == args.nombre) | (Usuario.email == args.email)
            ).first()
            
            if usuario_existente:
                print(f"Error: Ya existe un usuario con nombre '{args.nombre}' o email '{args.email}'")
                db.close()
                return
            
            nuevo_usuario = Usuario(
                nombre=args.nombre,
                email=args.email,
                password_hash=get_password_hash(args.password),
                rol_id=args.rol,
                activo=True
            )
            
            db.add(nuevo_usuario)
            db.commit()
            
            print(f"✓ Usuario '{args.nombre}' creado exitosamente")
            print(f"  Email: {args.email}")
            print(f"  Rol ID: {args.rol}")
            
        else:
            print("Modo interactivo:")
            print("=" * 60)
            
            nombre = input("Nombre de usuario: ").strip()
            if not nombre:
                print("Error: El nombre es requerido")
                db.close()
                return
            
            # Verificar si ya existe
            usuario_existente = db.query(Usuario).filter(Usuario.nombre == nombre).first()
            if usuario_existente:
                print(f"Error: Ya existe un usuario con nombre '{nombre}'")
                db.close()
                return
            
            email = input("Email: ").strip()
            if not email:
                print("Error: El email es requerido")
                db.close()
                return
            
            # Verificar si el email ya existe
            email_existente = db.query(Usuario).filter(Usuario.email == email).first()
            if email_existente:
                print(f"Error: Ya existe un usuario con email '{email}'")
                db.close()
                return
            
            password = input("Contraseña: ").strip()
            if not password:
                print("Error: La contraseña es requerida")
                db.close()
                return
            
            print("\nSelecciona el rol:")
            for rol_id, rol_nombre in roles:
                print(f"  {rol_id}: {rol_nombre}")
            
            try:
                rol_id = int(input("Rol ID: ").strip())
                if rol_id not in [r[0] for r in roles]:
                    print(f"Error: Rol ID {rol_id} no válido")
                    db.close()
                    return
            except ValueError:
                print("Error: Debes ingresar un número válido")
                db.close()
                return
            
            nuevo_usuario = Usuario(
                nombre=nombre,
                email=email,
                password_hash=get_password_hash(password),
                rol_id=rol_id,
                activo=True
            )
            
            db.add(nuevo_usuario)
            db.commit()
            
            print(f"\n✓ Usuario '{nombre}' creado exitosamente")
            print(f"  Email: {email}")
            print(f"  Rol ID: {rol_id}")
        
        db.close()
        
    except ImportError as e:
        print("Error: No se pudo importar el módulo app. Ejecuta desde la raíz del proyecto:")
        print("  cd <ruta_del_ERP>")
        print("  python scripts/crear_usuario.py")
        print()
        print("Detalle:", e)
        sys.exit(1)
    except Exception as e:
        print(f"Error al crear usuario: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
