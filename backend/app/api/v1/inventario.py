from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Annotated, List, Optional
from datetime import datetime

from app.core.database import get_db
from app.api.dependencies import require_cajero_or_admin, get_current_active_user
from app.models.usuario import Usuario
from app.models.inventario import Inventario
from app.models.producto import VarianteProducto
from app.repositories.inventario_repository import InventarioRepository
from app.services.inventario_service import MovimientoInventario
from pydantic import BaseModel, Field

router = APIRouter(prefix="/inventario", tags=["Inventario"])


class StockVarianteResponse(BaseModel):
    """Response para consulta de stock."""
    variante_id: int
    nombre_producto: str
    sku: str
    talla: str | None
    color: str | None
    stock_actual: int
    
    class Config:
        from_attributes = True


class MovimientoInventarioRequest(BaseModel):
    """Request para registrar movimiento de inventario."""
    variante_id: int = Field(..., description="ID de la variante")
    tipo: str = Field(..., description="ENTRADA, SALIDA o AJUSTE")
    cantidad: int = Field(..., gt=0, description="Cantidad del movimiento")
    motivo: str = Field(..., description="Motivo del movimiento")
    referencia: str | None = Field(None, description="Referencia opcional (OC, etc.)")


@router.get("/stock", response_model=List[StockVarianteResponse])
def consultar_stock(
    estado: Optional[str] = Query(None, description="Filtrar por estado (OK, BAJO, CRITICO)"),
    current_user: Annotated[Usuario, Depends(get_current_active_user)] = None,
    db: Session = Depends(get_db)
):
    """
    Consultar stock de variantes.
    
    Requiere autenticación.
    """
    query = db.query(
        Inventario.variante_id,
        VarianteProducto.sku,
        VarianteProducto.talla,
        VarianteProducto.color,
        Inventario.stock
    ).join(
        VarianteProducto,
        VarianteProducto.id == Inventario.variante_id
    )
    
    results = query.all()
    
    # Obtener nombres de productos
    response = []
    for result in results:
        variante = db.query(VarianteProducto).filter(
            VarianteProducto.id == result.variante_id
        ).first()
        
        if variante:
            response.append(StockVarianteResponse(
                variante_id=result.variante_id,
                nombre_producto=variante.producto.nombre,
                sku=result.sku,
                talla=result.talla,
                color=result.color,
                stock_actual=result.stock
            ))
    
    return response


@router.get("/stock/bajo", response_model=List[StockVarianteResponse])
def productos_stock_bajo(
    current_user: Annotated[Usuario, Depends(get_current_active_user)],
    db: Session = Depends(get_db)
):
    """
    Productos con stock bajo.
    
    Devuelve variantes con stock <= 10 (umbral configurable).
    
    Requiere autenticación.
    """
    query = db.query(
        Inventario.variante_id,
        VarianteProducto.sku,
        VarianteProducto.talla,
        VarianteProducto.color,
        Inventario.stock
    ).join(
        VarianteProducto,
        VarianteProducto.id == Inventario.variante_id
    ).filter(
        Inventario.stock <= 10
    )
    
    results = query.all()
    
    response = []
    for result in results:
        variante = db.query(VarianteProducto).filter(
            VarianteProducto.id == result.variante_id
        ).first()
        
        if variante:
            response.append(StockVarianteResponse(
                variante_id=result.variante_id,
                nombre_producto=variante.producto.nombre,
                sku=result.sku,
                talla=result.talla,
                color=result.color,
                stock_actual=result.stock
            ))
    
    return response


@router.post("/movimientos", status_code=status.HTTP_201_CREATED)
def registrar_movimiento(
    movimiento: MovimientoInventarioRequest,
    current_user: Annotated[Usuario, Depends(require_cajero_or_admin)],
    db: Session = Depends(get_db)
):
    """
    Registrar movimiento de inventario.
    
    Para registrar entradas, salidas o ajustes manuales.
    Las salidas por venta se registran automáticamente.
    
    **Tipos de movimiento**:
    - ENTRADA: Compra de mercancía, devoluciones de cliente
    - SALIDA: Mermas, daños, transferencias
    - AJUSTE: Corrección de inventario físico
    
    Requiere rol: CAJERO o ADMIN
    """
    service = MovimientoInventario(db)
    
    return service.registrar_movimiento(
        variante_id=movimiento.variante_id,
        tipo=movimiento.tipo,
        cantidad=movimiento.cantidad,
        motivo=movimiento.motivo,
        referencia=movimiento.referencia,
        usuario_id=current_user.id
    )


@router.get("/movimientos")
def listar_movimientos(
    variante_id: Optional[int] = Query(None, description="Filtrar por variante"),
    tipo: Optional[str] = Query(None, description="Filtrar por tipo"),
    limit: int = Query(100, ge=1, le=1000),
    current_user: Annotated[Usuario, Depends(get_current_active_user)] = None,
    db: Session = Depends(get_db)
):
    """
    Listar movimientos de inventario con filtros.
    
    Requiere autenticación.
    """
    service = MovimientoInventario(db)
    
    return service.obtener_movimientos(
        variante_id=variante_id,
        tipo=tipo,
        limit=limit
    )
