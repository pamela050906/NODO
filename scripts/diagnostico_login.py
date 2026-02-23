#!/usr/bin/env python3
"""
Script de diagnóstico para problemas de login en Docker.

Verifica:
1. Conexión al backend
2. Estado de la base de datos
3. Existencia de usuarios
4. Configuración de CORS

Ejecutar desde la raíz del proyecto:
    python scripts/diagnostico_login.py
"""
import sys
import requests
from pathlib import Path

# Permitir importar app (backend/app) cuando se ejecuta desde la raíz del repo
root = Path(__file__).resolve().parent.parent
backend = root / "backend"
if backend.exists():
    sys.path.insert(0, str(backend))
if str(root) not in sys.path:
    sys.path.insert(0, str(root))

def main():
    print("=" * 60)
    print("DIAGNÓSTICO DE LOGIN - ERP")
    print("=" * 60)
    
    # 1. Verificar conexión al backend
    print("\n1. Verificando conexión al backend...")
    backend_url = "http://localhost:8000"
    
    try:
        response = requests.get(f"{backend_url}/health", timeout=5)
        if response.status_code == 200:
            print(f"   ✓ Backend respondiendo correctamente en {backend_url}")
            print(f"   Respuesta: {response.json()}")
        else:
            print(f"   ✗ Backend respondió con código {response.status_code}")
    except requests.exceptions.ConnectionError:
        print(f"   ✗ No se puede conectar al backend en {backend_url}")
        print("   Verifica que el contenedor 'pos_backend' esté corriendo:")
        print("   docker ps | grep pos_backend")
        return
    except Exception as e:
        print(f"   ✗ Error al conectar: {e}")
        return
    
    # 2. Verificar endpoint de login
    print("\n2. Verificando endpoint de login...")
    try:
        # Intentar login con credenciales de prueba (debería fallar pero confirmar que el endpoint existe)
        response = requests.post(
            f"{backend_url}/api/v1/auth/login",
            data={"username": "test", "password": "test"},
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            timeout=5
        )
        if response.status_code == 401:
            print("   ✓ Endpoint de login existe y responde correctamente")
            print("   (401 es esperado con credenciales incorrectas)")
        elif response.status_code == 200:
            print("   ⚠ Endpoint responde 200 (login exitoso con credenciales de prueba)")
        else:
            print(f"   ✗ Endpoint respondió con código inesperado: {response.status_code}")
    except Exception as e:
        print(f"   ✗ Error al verificar endpoint: {e}")
    
    # 3. Verificar base de datos y usuarios
    print("\n3. Verificando base de datos y usuarios...")
    try:
        from app.core.database import engine
        from app.models.usuario import Usuario
        from sqlalchemy.orm import sessionmaker
        from sqlalchemy import text
        
        SessionLocal = sessionmaker(bind=engine)
        db = SessionLocal()
        
        # Verificar conexión a BD
        db.execute(text("SELECT 1"))
        print("   ✓ Conexión a base de datos exitosa")
        
        # Contar usuarios
        count = db.query(Usuario).count()
        print(f"   Usuarios en la base de datos: {count}")
        
        if count == 0:
            print("   ⚠ No hay usuarios en la base de datos")
            print("   Necesitas crear usuarios antes de poder hacer login")
            print("\n   Para crear usuarios, ejecuta:")
            print("   python scripts/crear_usuario.py")
        else:
            # Listar usuarios (sin mostrar passwords)
            usuarios = db.query(Usuario).all()
            print("\n   Usuarios disponibles:")
            for u in usuarios:
                rol_info = f"Rol ID: {u.rol_id}" if hasattr(u, 'rol_id') else "Sin rol"
                activo = "✓ Activo" if u.activo else "✗ Inactivo"
                print(f"     - {u.nombre} ({u.email}) - {rol_info} - {activo}")
        
        db.close()
    except ImportError as e:
        print(f"   ✗ Error al importar módulos: {e}")
        print("   Ejecuta desde la raíz del proyecto")
    except Exception as e:
        print(f"   ✗ Error al verificar base de datos: {e}")
    
    # 4. Verificar CORS
    print("\n4. Verificando configuración de CORS...")
    try:
        from app.core.config import settings
        cors_origins = settings.CORS_ORIGINS
        print(f"   CORS_ORIGINS configurado: {cors_origins}")
        if cors_origins == "*":
            print("   ✓ CORS permite todos los orígenes (correcto para desarrollo)")
        else:
            print(f"   Verifica que 'http://localhost:3000' esté en la lista de orígenes permitidos")
    except Exception as e:
        print(f"   ✗ Error al verificar CORS: {e}")
    
    # 5. Verificar variables de entorno del frontend
    print("\n5. Verificando configuración del frontend...")
    frontend_env = root / "frontend" / ".env"
    if frontend_env.exists():
        print("   ✓ Archivo .env encontrado en frontend/")
        with open(frontend_env, 'r') as f:
            for line in f:
                if 'REACT_APP_API_URL' in line:
                    print(f"   {line.strip()}")
    else:
        print("   ⚠ No se encontró archivo .env en frontend/")
        print("   Verifica que REACT_APP_API_URL esté configurado en docker/docker-compose.yml")
    
    print("\n" + "=" * 60)
    print("DIAGNÓSTICO COMPLETADO")
    print("=" * 60)
    print("\nSiguientes pasos si el login no funciona:")
    print("1. Verifica que todos los contenedores estén corriendo: docker ps")
    print("2. Verifica los logs del backend: docker logs pos_backend")
    print("3. Verifica los logs del frontend: docker logs pos_frontend")
    print("4. Abre la consola del navegador (F12) y revisa los errores de red")
    print("5. Asegúrate de que haya usuarios en la base de datos")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nDiagnóstico cancelado por el usuario")
        sys.exit(1)
    except Exception as e:
        print(f"\n\nError inesperado: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
