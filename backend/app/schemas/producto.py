from pydantic import BaseModel
from typing import Optional
from decimal import Decimal


class VarianteProductoResponse(BaseModel):
    """Schema para respuesta de variante de producto (alineado)."""
    id: int
    producto_id: int
    sku: str
    codigo_barras: str
    talla: Optional[str]
    color: Optional[str]
    precio_menudeo: Decimal
    precio_mayoreo: Decimal
    activo: bool
    
    # Información del producto padre
    producto_nombre: Optional[str] = None
    
    # Stock disponible
    stock_disponible: Optional[int] = None
    
    class Config:
        from_attributes = True


class ProductoBusqueda(BaseModel):
    """Schema para búsqueda de productos por código de barras."""
    codigo_barras: str
