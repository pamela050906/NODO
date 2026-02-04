#!/usr/bin/env python3
"""
Script para aplicar migraciones de base de datos.
"""
import psycopg2
from pathlib import Path
import sys

# Configuración de conexión (ajustar según tu entorno)
DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'almacen_db',
    'user': 'postgres',
    'password': 'postgres'
}

def aplicar_migracion(cursor, archivo_sql):
    """Aplica una migración SQL"""
    try:
        with open(archivo_sql, 'r', encoding='utf-8') as f:
            sql = f.read()
        
        cursor.execute(sql)
        print(f"✅ Migración aplicada: {archivo_sql.name}")
        return True
    except Exception as e:
        print(f"❌ Error aplicando {archivo_sql.name}: {e}")
        return False

def main():
    """Aplica todas las migraciones pendientes"""
    migrations_dir = Path(__file__).parent
    
    # Lista de migraciones en orden
    migrations = [
        migrations_dir / '001_add_venta_fields.sql',
        migrations_dir / '002_mejora_precios_acumulado.sql',
        migrations_dir / '003_modulo_cobranza.sql',
        migrations_dir / '004_alinear_productos_facturas.sql',
    ]
    
    # Conectar a la base de datos
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        print("✅ Conectado a la base de datos")
    except Exception as e:
        print(f"❌ Error conectando a la base de datos: {e}")
        sys.exit(1)
    
    # Aplicar migraciones
    exito = True
    for migration in migrations:
        if not migration.exists():
            print(f"⚠️  Archivo no encontrado: {migration}")
            continue
        
        if not aplicar_migracion(cursor, migration):
            exito = False
            break
    
    # Commit o rollback
    if exito:
        conn.commit()
        print("\n✅ Todas las migraciones aplicadas correctamente")
    else:
        conn.rollback()
        print("\n❌ Algunas migraciones fallaron. Se hizo rollback.")
    
    cursor.close()
    conn.close()

if __name__ == '__main__':
    main()
