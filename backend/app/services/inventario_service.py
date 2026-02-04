"""
Servicio para gestión de inventario y movimientos.
"""
from sqlalchemy.orm import Session
from sqlalchemy import text
from fastapi import HTTPException, status
from typing import List
from datetime import datetime

from app.models.inventario import Inventario
from app.repositories.inventario_repository import InventarioRepository


class MovimientoInventario:
    """Clase para manejar movimientos de inventario."""
    
    def __init__(self, db: Session):
        self.db = db
        self.inventario_repo = InventarioRepository(db)
    
    def registrar_movimiento(
        self, 
        variante_id: int, 
        tipo: str, 
        cantidad: int, 
        motivo: str,
        referencia: str = None,
        usuario_id: int = None
    ) -> dict:
        """
        Registrar un movimiento de inventario.
        
        Args:
            variante_id: ID de la variante
            tipo: ENTRADA, SALIDA o AJUSTE
            cantidad: Cantidad del movimiento
            motivo: Motivo del movimiento
            referencia: Referencia opcional (OC, factura, etc.)
            usuario_id: Usuario que registra el movimiento
            
        Returns:
            Diccionario con resultado del movimiento
        """
        if tipo not in ['ENTRADA', 'SALIDA', 'AJUSTE']:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Tipo debe ser ENTRADA, SALIDA o AJUSTE"
            )
        
        try:
            # Obtener inventario con lock
            inventario = self.inventario_repo.get_by_variante_id_with_lock(variante_id)
            
            if not inventario:
                # Si no existe, crear registro de inventario
                inventario = Inventario(
                    variante_id=variante_id,
                    stock=0
                )
                self.db.add(inventario)
                self.db.flush()
            
            stock_anterior = inventario.stock
            
            # Calcular nuevo stock
            if tipo == 'ENTRADA':
                nuevo_stock = stock_anterior + cantidad
            elif tipo == 'SALIDA':
                if stock_anterior < cantidad:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Stock insuficiente. Disponible: {stock_anterior}, Requerido: {cantidad}"
                    )
                nuevo_stock = stock_anterior - cantidad
            else:  # AJUSTE
                nuevo_stock = cantidad
            
            # Actualizar stock
            inventario.stock = nuevo_stock
            
            # Registrar movimiento en tabla movimientos_inventario
            self.db.execute(
                text("""
                    INSERT INTO movimientos_inventario 
                    (variante_id, tipo, cantidad, referencia, creado_en)
                    VALUES (:variante_id, :tipo, :cantidad, :referencia, NOW())
                """),
                {
                    'variante_id': variante_id,
                    'tipo': tipo,
                    'cantidad': cantidad,
                    'referencia': referencia or motivo
                }
            )
            
            self.db.commit()
            
            return {
                'variante_id': variante_id,
                'tipo': tipo,
                'cantidad': cantidad,
                'stock_anterior': stock_anterior,
                'stock_nuevo': nuevo_stock,
                'mensaje': f'Movimiento {tipo} registrado correctamente'
            }
            
        except HTTPException:
            self.db.rollback()
            raise
        except Exception as e:
            self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al registrar movimiento: {str(e)}"
            )
    
    def obtener_movimientos(
        self,
        variante_id: int = None,
        tipo: str = None,
        fecha_desde: datetime = None,
        fecha_hasta: datetime = None,
        limit: int = 100
    ) -> List[dict]:
        """
        Obtener historial de movimientos de inventario.
        
        Args:
            variante_id: Filtrar por variante
            tipo: Filtrar por tipo de movimiento
            fecha_desde: Filtrar desde fecha
            fecha_hasta: Filtrar hasta fecha
            limit: Límite de resultados
            
        Returns:
            Lista de movimientos
        """
        query = """
            SELECT 
                m.id,
                m.variante_id,
                p.nombre as producto_nombre,
                v.sku,
                v.talla,
                v.color,
                m.tipo,
                m.cantidad,
                m.referencia,
                m.creado_en
            FROM movimientos_inventario m
            JOIN variantes_producto v ON m.variante_id = v.id
            JOIN productos p ON v.producto_id = p.id
            WHERE 1=1
        """
        
        params = {}
        
        if variante_id:
            query += " AND m.variante_id = :variante_id"
            params['variante_id'] = variante_id
        
        if tipo:
            query += " AND m.tipo = :tipo"
            params['tipo'] = tipo
        
        if fecha_desde:
            query += " AND m.creado_en >= :fecha_desde"
            params['fecha_desde'] = fecha_desde
        
        if fecha_hasta:
            query += " AND m.creado_en <= :fecha_hasta"
            params['fecha_hasta'] = fecha_hasta
        
        query += " ORDER BY m.creado_en DESC LIMIT :limit"
        params['limit'] = limit
        
        result = self.db.execute(text(query), params)
        
        movimientos = []
        for row in result:
            movimientos.append({
                'id': row.id,
                'variante_id': row.variante_id,
                'producto_nombre': row.producto_nombre,
                'sku': row.sku,
                'talla': row.talla,
                'color': row.color,
                'tipo': row.tipo,
                'cantidad': row.cantidad,
                'referencia': row.referencia,
                'creado_en': row.creado_en
            })
        
        return movimientos
    
    def obtener_stock_bajo(self, umbral: int = 10) -> List[dict]:
        """
        Obtener productos con stock bajo.
        
        Args:
            umbral: Umbral de stock considerado bajo
            
        Returns:
            Lista de productos con stock <= umbral
        """
        query = """
            SELECT 
                i.variante_id,
                p.nombre as producto_nombre,
                v.sku,
                v.talla,
                v.color,
                i.stock as stock_actual,
                :umbral as stock_minimo
            FROM inventario i
            JOIN variantes_producto v ON i.variante_id = v.id
            JOIN productos p ON v.producto_id = p.id
            WHERE i.stock <= :umbral
            AND v.activo = true
            ORDER BY i.stock ASC
        """
        
        result = self.db.execute(text(query), {'umbral': umbral})
        
        productos = []
        for row in result:
            productos.append({
                'variante_id': row.variante_id,
                'producto_nombre': row.producto_nombre,
                'sku': row.sku,
                'talla': row.talla,
                'color': row.color,
                'stock_actual': row.stock_actual,
                'stock_minimo': row.stock_minimo
            })
        
        return productos
