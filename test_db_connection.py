#!/usr/bin/env python3
"""Script temporal para verificar conexión a BD."""
from app.core.database import engine
from sqlalchemy import text

with engine.connect() as conn:
    # Verificar si existe la tabla usuarios
    result = conn.execute(text("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'usuarios'
    """))
    row = result.fetchone()
    print(f"Tabla usuarios encontrada: {row}")
    
    # Intentar hacer un SELECT simple
    try:
        result2 = conn.execute(text("SELECT COUNT(*) FROM usuarios"))
        count = result2.fetchone()[0]
        print(f"Total usuarios en BD: {count}")
    except Exception as e:
        print(f"Error al consultar usuarios: {e}")
