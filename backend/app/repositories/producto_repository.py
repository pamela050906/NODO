from sqlalchemy.orm import Session, joinedload
from typing import Optional
from app.models.producto import VarianteProducto, Producto
from app.models.inventario import Inventario


class ProductoRepository:
    """Repositorio para operaciones de Producto y Variante."""
    
    def __init__(self, db: Session):
        self.db = db
    
    def get_variante_by_codigo_barras(self, codigo_barras: str) -> Optional[VarianteProducto]:
        """
        Buscar variante de producto por código de barras.
        Incluye información del producto padre.
        """
        return self.db.query(VarianteProducto).options(
            joinedload(VarianteProducto.producto)
        ).filter(
            VarianteProducto.codigo_barras == codigo_barras,
            VarianteProducto.activo.is_(True)
        ).first()
    
    def get_variante_by_sku(self, sku: str) -> Optional[VarianteProducto]:
        """Buscar variante de producto por SKU."""
        return self.db.query(VarianteProducto).options(
            joinedload(VarianteProducto.producto)
        ).filter(
            VarianteProducto.sku == sku,
            VarianteProducto.activo.is_(True)
        ).first()
    
    def get_variante_with_stock(self, codigo_barras: str) -> Optional[tuple]:
        """
        Obtener variante con información de stock.
        
        Returns:
            Tupla (VarianteProducto, Inventario) o None
        """
        result = self.db.query(VarianteProducto, Inventario).join(
            Inventario,
            Inventario.variante_id == VarianteProducto.id
        ).filter(
            VarianteProducto.codigo_barras == codigo_barras,
            VarianteProducto.activo.is_(True)
        ).first()
        
        return result
