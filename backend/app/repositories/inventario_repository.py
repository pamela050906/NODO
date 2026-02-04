from sqlalchemy.orm import Session
from sqlalchemy import select
from typing import Optional
from app.models.inventario import Inventario


class InventarioRepository:
    """
    Repositorio para operaciones de Inventario.
    
    IMPORTANTE: Usa SELECT FOR UPDATE para prevenir condiciones de carrera
    en operaciones concurrentes.
    """
    
    def __init__(self, db: Session):
        self.db = db
    
    def get_by_variante_id(self, variante_id: int) -> Optional[Inventario]:
        """Obtener inventario de una variante (sin lock)."""
        return self.db.query(Inventario).filter(
            Inventario.variante_id == variante_id
        ).first()
    
    def get_by_variante_id_with_lock(self, variante_id: int) -> Optional[Inventario]:
        """
        Obtener inventario con lock exclusivo para actualización.
        
        Usa SELECT FOR UPDATE para bloquear el registro hasta que
        termine la transacción. Esto previene que dos ventas simultáneas
        vendan el mismo stock.
        
        DEBE usarse dentro de una transacción.
        """
        return self.db.query(Inventario).filter(
            Inventario.variante_id == variante_id
        ).with_for_update().first()
    
    def check_stock_disponible(self, variante_id: int, cantidad_requerida: int) -> bool:
        """
        Verificar si hay stock suficiente.
        
        Args:
            variante_id: ID de la variante
            cantidad_requerida: Cantidad que se necesita
            
        Returns:
            True si hay stock suficiente, False en caso contrario
        """
        inventario = self.get_by_variante_id(variante_id)
        
        if not inventario:
            return False
        
        return inventario.stock >= cantidad_requerida
    
    def actualizar_stock(self, variante_id: int, cantidad_delta: int) -> bool:
        """
        Actualizar stock de inventario.
        
        NOTA: Los triggers de PostgreSQL manejan esto automáticamente.
        Este método existe como respaldo si no hay triggers configurados.
        
        Args:
            variante_id: ID de la variante
            cantidad_delta: Cambio en cantidad (negativo para ventas, positivo para entradas)
            
        Returns:
            True si se actualizó correctamente
        """
        inventario = self.get_by_variante_id_with_lock(variante_id)
        
        if not inventario:
            return False
        
        nuevo_stock = inventario.stock + cantidad_delta
        
        if nuevo_stock < 0:
            return False
        
        inventario.stock = nuevo_stock
        self.db.flush()
        
        return True
