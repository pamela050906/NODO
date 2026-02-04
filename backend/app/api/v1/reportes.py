from fastapi import APIRouter, Depends, Query, Path, Response
from sqlalchemy.orm import Session
from typing import Annotated, Optional
from datetime import date

from app.core.database import get_db
from app.api.dependencies import get_current_active_user
from app.models.usuario import Usuario
from app.services.reporte_service import ReporteService

router = APIRouter(prefix="/reportes", tags=["Reportes"])


@router.get("/ventas")
def reporte_ventas(
    fecha_desde: Optional[date] = Query(None, description="Fecha de inicio"),
    fecha_hasta: Optional[date] = Query(None, description="Fecha de fin"),
    metodo_pago: Optional[str] = Query(None, description="EFECTIVO o TARJETA"),
    facturado: Optional[bool] = Query(None, description="Filtrar por facturado"),
    punto_venta_id: Optional[int] = Query(None, description="Filtrar por punto de venta"),
    current_user: Annotated[Usuario, Depends(get_current_active_user)] = None,
    db: Session = Depends(get_db)
):
    """
    Generar reporte de ventas.
    
    Permite filtrar por:
    - Rango de fechas
    - Método de pago
    - Estado de facturación
    - Punto de venta
    
    Requiere autenticación.
    """
    service = ReporteService(db)
    return service.reporte_ventas(
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
        metodo_pago=metodo_pago,
        facturado=facturado,
        punto_venta_id=punto_venta_id
    )


@router.get("/ventas/export")
def exportar_ventas(
    fecha_desde: Optional[date] = Query(None),
    fecha_hasta: Optional[date] = Query(None),
    current_user: Annotated[Usuario, Depends(get_current_active_user)] = None,
    db: Session = Depends(get_db)
):
    """
    Exportar reporte de ventas a CSV.
    
    Requiere autenticación.
    """
    service = ReporteService(db)
    csv_content = service.exportar_ventas_csv(fecha_desde, fecha_hasta)
    
    return Response(
        content=csv_content,
        media_type="text/csv",
        headers={
            "Content-Disposition": f"attachment; filename=ventas_{fecha_desde or 'todos'}_{fecha_hasta or 'todos'}.csv"
        }
    )


@router.get("/almacen")
def reporte_almacen(
    categoria: Optional[str] = Query(None, description="Filtrar por categoría"),
    stock_bajo: bool = Query(False, description="Solo productos con stock bajo"),
    current_user: Annotated[Usuario, Depends(get_current_active_user)] = None,
    db: Session = Depends(get_db)
):
    """
    Generar reporte de existencias en almacén.
    
    Muestra:
    - Productos y variantes
    - Stock actual
    - Valor de inventario
    - Categorización
    
    Requiere autenticación.
    """
    service = ReporteService(db)
    return service.reporte_almacen(categoria=categoria, stock_bajo=stock_bajo)


@router.get("/almacen/export")
def exportar_almacen(
    categoria: Optional[str] = Query(None),
    current_user: Annotated[Usuario, Depends(get_current_active_user)] = None,
    db: Session = Depends(get_db)
):
    """
    Exportar reporte de almacén a CSV.
    
    Requiere autenticación.
    """
    service = ReporteService(db)
    csv_content = service.exportar_almacen_csv(categoria)
    
    return Response(
        content=csv_content,
        media_type="text/csv",
        headers={
            "Content-Disposition": f"attachment; filename=almacen_{categoria or 'todos'}.csv"
        }
    )


@router.get("/movimientos")
def reporte_movimientos(
    fecha_desde: Optional[date] = Query(None, description="Fecha de inicio"),
    fecha_hasta: Optional[date] = Query(None, description="Fecha de fin"),
    tipo: Optional[str] = Query(None, description="ENTRADA, SALIDA o AJUSTE"),
    current_user: Annotated[Usuario, Depends(get_current_active_user)] = None,
    db: Session = Depends(get_db)
):
    """
    Generar reporte de movimientos de inventario.
    
    Requiere autenticación.
    """
    service = ReporteService(db)
    return service.reporte_movimientos(
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta,
        tipo=tipo
    )


@router.get("/general/{mes}/{anio}")
def reporte_general_mensual(
    mes: int = Path(..., ge=1, le=12, description="Mes (1-12)"),
    anio: int = Path(..., ge=2020, le=2030, description="Año"),
    current_user: Annotated[Usuario, Depends(get_current_active_user)] = None,
    db: Session = Depends(get_db)
):
    """
    Generar reporte general mensual con comparativa.
    
    Incluye:
    - Ventas del mes
    - Comparativa con mes anterior
    - Productos más vendidos
    - Totales por método de pago
    
    Requiere autenticación.
    """
    service = ReporteService(db)
    return service.reporte_general_mensual(mes, anio)
