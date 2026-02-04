from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Annotated

from app.core.database import get_db
from app.api.dependencies import require_cajero_or_admin
from app.models.usuario import Usuario
from app.repositories.producto_repository import ProductoRepository
from app.repositories.inventario_repository import InventarioRepository
from pydantic import BaseModel
from decimal import Decimal

router = APIRouter(prefix="/pos", tags=["POS"])


class VarianteBarcodeResponse(BaseModel):
    """Response para búsqueda por código de barras."""
    variante_id: int
    producto_id: int
    nombre_producto: str
    sku: str
    codigo_barras: str
    talla: str | None
    color: str | None
    precio_menudeo: Decimal
    precio_mayoreo: Decimal
    stock_actual: int
    activo: bool
    
    class Config:
        from_attributes = True


@router.get("/barcode/{codigo}", response_model=VarianteBarcodeResponse)
def buscar_por_codigo_barras(
    codigo: str,
    current_user: Annotated[Usuario, Depends(require_cajero_or_admin)],
    db: Session = Depends(get_db)
):
    """
    Buscar producto por código de barras.
    
    Endpoint optimizado para POS. Escanea un código de barras y devuelve
    toda la información necesaria para agregarlo a una venta.
    
    Requiere rol: CAJERO o ADMIN
    """
    producto_repo = ProductoRepository(db)
    inventario_repo = InventarioRepository(db)
    
    # Buscar variante por código de barras
    result = producto_repo.get_variante_with_stock(codigo)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Código de barras '{codigo}' no encontrado"
        )
    
    variante, inventario = result
    
    # Construir respuesta
    response = VarianteBarcodeResponse(
        variante_id=variante.id,
        producto_id=variante.producto_id,
        nombre_producto=variante.producto.nombre,
        sku=variante.sku,
        codigo_barras=variante.codigo_barras,
        talla=variante.talla,
        color=variante.color,
        precio_menudeo=variante.precio_menudeo,
        precio_mayoreo=variante.precio_mayoreo,
        stock_actual=inventario.stock if inventario else 0,
        activo=bool(variante.activo)
    )
    
    return response
