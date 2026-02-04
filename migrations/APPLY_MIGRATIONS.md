# 🔄 Aplicar Migraciones de Base de Datos

## Instrucciones

### Opción 1: Aplicar migraciones manualmente (Recomendado para desarrollo)

```bash
# Conectarse a PostgreSQL
psql -U postgres -d almacen_db

# Aplicar migración 001
\i migrations/001_add_venta_fields.sql

# Verificar que se aplicó correctamente
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'ventas'
ORDER BY ordinal_position;
```

### Opción 2: Usando script Python

```bash
cd ERP
python migrations/apply_migrations.py
```

## Migraciones Disponibles

### ✅ 001_add_venta_fields.sql
**Fecha**: 2026-01-21  
**Propósito**: Agregar campos de control a tabla ventas

**Cambios**:
- Agrega `subtotal`, `descuento`, `impuesto` a `ventas`
- Agrega `estado` (ABIERTA/CERRADA/CANCELADA) a `ventas`
- Agrega `completed_at` para timestamp de cierre
- Crea constraints para validar estados y montos
- Actualiza ventas existentes con valores por defecto
- Crea índices para mejorar performance

**Verificación**:
```sql
-- Debe mostrar los nuevos campos
\d ventas
```

## Estado de Migraciones

| # | Nombre | Estado | Fecha Aplicada | Notas |
|---|--------|--------|----------------|-------|
| 001 | add_venta_fields | ⏳ Pendiente | - | Requerida para Fase 1 |

## Rollback (Si es necesario)

Para revertir la migración 001:

```sql
ALTER TABLE ventas DROP COLUMN IF EXISTS subtotal;
ALTER TABLE ventas DROP COLUMN IF EXISTS descuento;
ALTER TABLE ventas DROP COLUMN IF EXISTS impuesto;
ALTER TABLE ventas DROP COLUMN IF EXISTS estado;
ALTER TABLE ventas DROP COLUMN IF EXISTS completed_at;
```

⚠️ **ADVERTENCIA**: Hacer rollback después de usar el sistema puede causar pérdida de datos.
