#!/usr/bin/env python3
"""
Script para verificar la base de datos actual del ERP.
Muestra: nombre de la BD, versión de PostgreSQL, host y lista de tablas.

Ejecutar desde la raíz del proyecto:
    python scripts/verificar_bd.py

O desde backend (si tienes PYTHONPATH o instalas el paquete):
    cd backend && python -m scripts.verificar_bd
"""
import sys
from pathlib import Path

# Permitir importar app (backend/app) cuando se ejecuta desde la raíz del repo
root = Path(__file__).resolve().parent.parent
backend = root / "backend"
if backend.exists():
    sys.path.insert(0, str(backend))
if str(root) not in sys.path:
    sys.path.insert(0, str(root))

def main():
    try:
        from app.core.config import settings
        from app.core.database import engine
        from sqlalchemy import text
    except ImportError as e:
        print("Error: No se pudo importar el módulo app. Ejecuta desde la raíz del proyecto:")
        print("  cd <ruta_del_ERP>")
        print("  python scripts/verificar_bd.py")
        print()
        print("Detalle:", e)
        sys.exit(1)

    print("=" * 60)
    print("VERIFICACIÓN DE BASE DE DATOS - ERP")
    print("=" * 60)

    with engine.connect() as conn:
        # Base de datos actual
        r = conn.execute(text("SELECT current_database()"))
        db_name = r.scalar()
        print(f"\nBase de datos actual: {db_name}")

        # Versión de PostgreSQL
        r = conn.execute(text("SELECT version()"))
        version = r.scalar()
        print(f"PostgreSQL: {version.split(',')[0]}")

        # Host (desde la URL si está disponible)
        url = getattr(settings, "DATABASE_URL", "") or ""
        if "@" in url and "/" in url:
            host_part = url.split("@")[1].split("/")[0].split(":")[0]
            print(f"Host (desde config): {host_part}")
        print(f"Nombre en config: {getattr(settings, 'DATABASE_NAME', 'N/A')}")

        # Listar tablas del esquema public
        r = conn.execute(text("""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            ORDER BY table_name
        """))
        tables = [row[0] for row in r.fetchall()]
        print(f"\nTablas en esquema 'public': {len(tables)}")
        for t in tables:
            print(f"  - {t}")

    print("\n" + "=" * 60)
    print("Verificación completada.")
    print("=" * 60)

if __name__ == "__main__":
    main()
