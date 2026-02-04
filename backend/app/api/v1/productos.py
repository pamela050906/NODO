from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile
from sqlalchemy.orm import Session
from typing import Annotated, List, Optional

from app.core.database import get_db
from app.api.dependencies import require_cajero_or_admin, get_current_active_user
from app.models.usuario import Usuario
from app.models.producto import Producto, VarianteProducto
from app.services.producto_service import ProductoService, ProductoCreateRequest, VarianteCreateRequest
from pydantic import BaseModel, Field
from decimal import Decimal

router = APIRouter(prefix="/productos", tags=["Productos"])


class VarianteResponse(BaseModel):
    """Response para variante de producto."""
    id: int
    producto_id: int
    sku: str
    codigo_barras: str
    talla: str | None
    color: str | None
    precio_menudeo: Decimal
    precio_mayoreo: Decimal
    activo: bool
    
    class Config:
        from_attributes = True


class ProductoResponse(BaseModel):
    """Response para producto."""
    id: int
    nombre: str
    descripcion: str | None
    categoria: str | None
    marca: str | None
    activo: bool
    variantes: List[VarianteResponse] = []
    
    class Config:
        from_attributes = True


@router.get("", response_model=List[ProductoResponse])
def listar_productos(
    categoria: Optional[str] = Query(None, description="Filtrar por categoría"),
    buscar: Optional[str] = Query(None, description="Buscar por nombre o SKU"),
    activo: Optional[bool] = Query(None, description="Filtrar por estado activo"),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_user: Annotated[Usuario, Depends(get_current_active_user)] = None,
    db: Session = Depends(get_db)
):
    """
    Listar productos con filtros opcionales.
    
    Requiere autenticación.
    """
    query = db.query(Producto)
    
    if categoria:
        query = query.filter(Producto.categoria == categoria)
    
    if buscar:
        search_term = f"%{buscar}%"
        query = query.filter(
            (Producto.nombre.ilike(search_term))
        )
    
    if activo is not None:
        query = query.filter(Producto.activo.is_(activo))
    
    productos = query.offset(skip).limit(limit).all()
    return productos


@router.get("/{producto_id}", response_model=ProductoResponse)
def obtener_producto(
    producto_id: int,
    current_user: Annotated[Usuario, Depends(get_current_active_user)],
    db: Session = Depends(get_db)
):
    """
    Obtener detalle de producto con todas sus variantes.
    
    Requiere autenticación.
    """
    producto = db.query(Producto).filter(Producto.id == producto_id).first()
    
    if not producto:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Producto {producto_id} no encontrado"
        )
    
    return producto


class ProductoCreateSchema(BaseModel):
    """Schema para crear producto."""
    nombre: str = Field(..., min_length=1, max_length=200)
    descripcion: str | None = None
    categoria: str | None = None
    marca: str | None = None


class VarianteCreateSchema(BaseModel):
    """Schema para crear variante."""
    producto_id: int
    sku: str = Field(..., min_length=1, max_length=50)
    codigo_barras: str = Field(..., min_length=1, max_length=100)
    talla: str | None = Field(None, max_length=20)
    color: str | None = Field(None, max_length=30)
    precio_menudeo: Decimal = Field(..., ge=0)
    precio_mayoreo: Decimal = Field(..., ge=0)
    stock_inicial: int = Field(default=0, ge=0)


@router.post("", response_model=ProductoResponse, status_code=status.HTTP_201_CREATED)
def crear_producto(
    producto_data: ProductoCreateSchema,
    current_user: Annotated[Usuario, Depends(require_cajero_or_admin)],
    db: Session = Depends(get_db)
):
    """
    Crear un nuevo producto.
    
    Requiere rol: CAJERO o ADMIN
    """
    service = ProductoService(db)
    request = ProductoCreateRequest(
        nombre=producto_data.nombre,
        descripcion=producto_data.descripcion,
        categoria=producto_data.categoria,
        marca=producto_data.marca
    )
    return service.crear_producto(request)


@router.post("/variantes", response_model=VarianteResponse, status_code=status.HTTP_201_CREATED)
def crear_variante(
    variante_data: VarianteCreateSchema,
    current_user: Annotated[Usuario, Depends(require_cajero_or_admin)],
    db: Session = Depends(get_db)
):
    """
    Crear una nueva variante de producto.
    
    Crea también el registro de inventario inicial si se proporciona stock_inicial.
    
    Requiere rol: CAJERO o ADMIN
    """
    service = ProductoService(db)
    request = VarianteCreateRequest(
        producto_id=variante_data.producto_id,
        sku=variante_data.sku,
        codigo_barras=variante_data.codigo_barras,
        talla=variante_data.talla,
        color=variante_data.color,
        precio_menudeo=float(variante_data.precio_menudeo),
        precio_mayoreo=float(variante_data.precio_mayoreo),
        stock_inicial=variante_data.stock_inicial
    )
    return service.crear_variante(request)


@router.post("/carga-masiva", status_code=status.HTTP_201_CREATED)
async def carga_masiva(
    file: UploadFile,
    current_user: Annotated[Usuario, Depends(require_cajero_or_admin)],
    db: Session = Depends(get_db)
):
    """
    Carga masiva de productos desde archivo CSV.
    
    Formato esperado:
    ```
    nombre,descripcion,categoria,marca,sku,codigo_barras,talla,color,precio_menudeo,precio_mayoreo,stock_inicial
    Playera Básica,Playera algodón,Ropa,MarcaX,PLY-M-NEG,7501234567890,M,Negro,600.00,500.00,50
    ```
    
    Requiere rol: CAJERO o ADMIN
    """
    service = ProductoService(db)
    return service.carga_masiva_csv(file)


@router.delete("/{producto_id}", status_code=status.HTTP_204_NO_CONTENT)
def eliminar_producto(
    producto_id: int,
    current_user: Annotated[Usuario, Depends(require_cajero_or_admin)],
    db: Session = Depends(get_db)
):
    """
    Desactivar un producto (soft delete).
    
    Requiere rol: CAJERO o ADMIN
    """
    service = ProductoService(db)
    success = service.eliminar_producto(producto_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Producto {producto_id} no encontrado"
        )
    
    return None


from fastapi import UploadFile
