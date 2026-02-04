from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Annotated, List, Optional
from datetime import date

from app.core.database import get_db
from app.api.dependencies import require_cajero_or_admin, get_current_active_user
from app.models.usuario import Usuario
from app.services.facturacion_service import FacturacionService
from pydantic import BaseModel, Field
from decimal import Decimal

router = APIRouter(prefix="/facturas", tags=["Facturación"])


class FacturaConceptoRequest(BaseModel):
    """Request para concepto de factura."""
    clave_prod_serv: str = Field(..., max_length=10, description="Clave SAT del producto/servicio")
    no_identificacion: str | None = Field(None, description="SKU o número de identificación")
    cantidad: float = Field(..., gt=0)
    clave_unidad: str = Field(..., max_length=10, description="Clave SAT de unidad (H87=Pieza)")
    unidad: str | None = Field(None, max_length=50, description="Descripción de unidad")
    descripcion: str = Field(..., description="Descripción del producto/servicio")
    precio_unitario: float = Field(..., ge=0)
    descuento: float = Field(default=0, ge=0)
    objeto_impuesto: str = Field(default='02', description="01=No objeto, 02=Sí objeto")


class FacturaCreateRequest(BaseModel):
    """Request para crear factura."""
    ventas_ids: List[int] = Field(..., min_length=1)
    
    # Datos del receptor
    rfc_receptor: str = Field(..., min_length=12, max_length=13)
    nombre_receptor: str = Field(..., min_length=1, max_length=255)
    regimen_fiscal_receptor: str | None = Field(None, max_length=10, description="Código régimen fiscal SAT")
    domicilio_fiscal_receptor: str | None = Field(None, max_length=500)
    uso_cfdi: str = Field(default='G03', max_length=10, description="Uso CFDI (G01, G03, P01, etc)")
    
    # Datos del comprobante
    tipo_comprobante: str = Field(default='I', max_length=1, description="I=Ingreso, E=Egreso, T=Traslado")
    forma_pago: str | None = Field(None, max_length=10, description="01=Efectivo, 03=Transferencia, 04=Tarjeta")
    metodo_pago: str = Field(default='PUE', max_length=10, description="PUE=Pago único, PPD=Pago diferido")
    moneda: str = Field(default='MXN', max_length=3)
    tipo_cambio: float | None = Field(None, gt=0, description="Requerido si moneda != MXN")
    
    # Tipo de factura
    tipo_factura: str = Field(default='INDIVIDUAL', description="INDIVIDUAL o GLOBAL")
    
    # Conceptos (si se quieren agregar manualmente en lugar de desde ventas)
    conceptos: List[FacturaConceptoRequest] | None = Field(None, description="Conceptos de la factura")
    
    # Observaciones
    observaciones: str | None = None


class FacturaGlobalRequest(BaseModel):
    """Request para factura global de tarjetas."""
    fecha_desde: date
    fecha_hasta: date
    punto_venta_id: int | None = None


class FacturaConceptoResponse(BaseModel):
    """Response para concepto de factura."""
    id: int
    clave_prod_serv: str
    no_identificacion: str | None
    cantidad: float
    clave_unidad: str
    unidad: str | None
    descripcion: str
    precio_unitario: float
    importe: float
    descuento: float
    objeto_impuesto: str
    numero_linea: int


class FacturaResponse(BaseModel):
    """Response para factura."""
    id: int
    uuid_sat: str | None
    serie: str | None
    folio: int | None
    estado: str
    
    # Fechas
    fecha: str | None
    fecha_emision: str | None
    fecha_timbrado: str | None
    
    # Emisor
    rfc_emisor: str
    nombre_emisor: str | None
    regimen_fiscal_emisor: str | None
    lugar_expedicion: str | None
    
    # Receptor
    rfc_receptor: str | None
    nombre_receptor: str | None
    regimen_fiscal_receptor: str | None
    uso_cfdi: str | None
    
    # Comprobante
    tipo_comprobante: str | None
    moneda: str | None
    tipo_cambio: float | None
    forma_pago: str | None
    metodo_pago: str | None
    
    # Totales
    subtotal: float | None
    descuento: float | None
    iva_trasladado: float | None
    iva_retenido: float | None
    ieps_trasladado: float | None
    isr_retenido: float | None
    total: float
    
    # Archivos
    xml_url: str | None
    pdf_url: str | None
    
    # Datos adicionales
    total_ventas: int | None = None
    conceptos: List[FacturaConceptoResponse] | None = None
    observaciones: str | None = None


@router.post("", response_model=FacturaResponse, status_code=status.HTTP_201_CREATED)
def crear_factura(
    factura_data: FacturaCreateRequest,
    current_user: Annotated[Usuario, Depends(require_cajero_or_admin)],
    db: Session = Depends(get_db)
):
    """
    Crear factura en estado BORRADOR.
    
    Agrupa una o varias ventas en una factura con todos los datos requeridos por el SAT.
    Para timbrar, usar POST /facturas/{id}/timbrar
    
    Requiere rol: CAJERO o ADMIN
    """
    service = FacturacionService(db)
    factura = service.crear_factura_borrador(
        ventas_ids=factura_data.ventas_ids,
        rfc_receptor=factura_data.rfc_receptor,
        nombre_receptor=factura_data.nombre_receptor,
        regimen_fiscal_receptor=factura_data.regimen_fiscal_receptor,
        domicilio_fiscal_receptor=factura_data.domicilio_fiscal_receptor,
        uso_cfdi=factura_data.uso_cfdi,
        tipo_comprobante=factura_data.tipo_comprobante,
        forma_pago=factura_data.forma_pago,
        metodo_pago=factura_data.metodo_pago,
        moneda=factura_data.moneda,
        tipo_cambio=factura_data.tipo_cambio,
        observaciones=factura_data.observaciones,
        serie='A'
    )
    
    return _build_factura_response(factura)


@router.get("", response_model=List[FacturaResponse])
def listar_facturas(
    estado: Optional[str] = Query(None, description="BORRADOR, TIMBRADA, CANCELADA"),
    fecha_desde: Optional[date] = Query(None),
    fecha_hasta: Optional[date] = Query(None),
    current_user: Annotated[Usuario, Depends(get_current_active_user)] = None,
    db: Session = Depends(get_db)
):
    """
    Listar facturas con filtros.
    
    Requiere autenticación.
    """
    service = FacturacionService(db)
    facturas = service.listar_facturas(
        estado=estado,
        fecha_desde=fecha_desde,
        fecha_hasta=fecha_hasta
    )
    
    return [FacturaResponse(**f) for f in facturas]


def _build_factura_response(factura) -> FacturaResponse:
    """Helper para construir response de factura."""
    return FacturaResponse(
        id=factura.id,
        uuid_sat=factura.uuid_sat,
        serie=factura.serie,
        folio=factura.folio,
        estado=factura.estado,
        fecha=factura.fecha.isoformat() if factura.fecha else None,
        fecha_emision=factura.fecha_emision.isoformat() if factura.fecha_emision else None,
        fecha_timbrado=factura.fecha_timbrado.isoformat() if factura.fecha_timbrado else None,
        rfc_emisor=factura.rfc_emisor,
        nombre_emisor=factura.nombre_emisor,
        regimen_fiscal_emisor=factura.regimen_fiscal_emisor,
        lugar_expedicion=factura.lugar_expedicion,
        rfc_receptor=factura.rfc_receptor,
        nombre_receptor=factura.nombre_receptor,
        regimen_fiscal_receptor=factura.regimen_fiscal_receptor,
        uso_cfdi=factura.uso_cfdi,
        tipo_comprobante=factura.tipo_comprobante,
        moneda=factura.moneda,
        tipo_cambio=float(factura.tipo_cambio) if factura.tipo_cambio else None,
        forma_pago=factura.forma_pago,
        metodo_pago=factura.metodo_pago,
        subtotal=float(factura.subtotal) if factura.subtotal else None,
        descuento=float(factura.descuento) if factura.descuento else None,
        iva_trasladado=float(factura.iva_trasladado) if factura.iva_trasladado else None,
        iva_retenido=float(factura.iva_retenido) if factura.iva_retenido else None,
        ieps_trasladado=float(factura.ieps_trasladado) if factura.ieps_trasladado else None,
        isr_retenido=float(factura.isr_retenido) if factura.isr_retenido else None,
        total=float(factura.total) if factura.total else 0,
        xml_url=factura.xml_url,
        pdf_url=factura.pdf_url,
        observaciones=factura.observaciones,
        conceptos=[
            FacturaConceptoResponse(
                id=c.id,
                clave_prod_serv=c.clave_prod_serv,
                no_identificacion=c.no_identificacion,
                cantidad=float(c.cantidad),
                clave_unidad=c.clave_unidad,
                unidad=c.unidad,
                descripcion=c.descripcion,
                precio_unitario=float(c.precio_unitario),
                importe=float(c.importe),
                descuento=float(c.descuento),
                objeto_impuesto=c.objeto_impuesto,
                numero_linea=c.numero_linea
            ) for c in factura.conceptos
        ] if hasattr(factura, 'conceptos') and factura.conceptos else None
    )


@router.get("/{factura_id}", response_model=FacturaResponse)
def obtener_factura(
    factura_id: int,
    current_user: Annotated[Usuario, Depends(get_current_active_user)],
    db: Session = Depends(get_db)
):
    """
    Obtener detalle de una factura.
    
    Requiere autenticación.
    """
    service = FacturacionService(db)
    factura = service.obtener_factura(factura_id)
    
    return _build_factura_response(factura)


@router.post("/{factura_id}/timbrar", response_model=FacturaResponse)
def timbrar_factura(
    factura_id: int,
    current_user: Annotated[Usuario, Depends(require_cajero_or_admin)],
    db: Session = Depends(get_db)
):
    """
    Timbrar factura con el PAC.
    
    Envía la factura al PAC para obtener:
    - UUID del SAT
    - XML timbrado
    - PDF de representación impresa
    
    Requiere rol: CAJERO o ADMIN
    """
    service = FacturacionService(db)
    factura = service.timbrar_factura(factura_id)
    
    return _build_factura_response(factura)


@router.post("/global/tarjetas", response_model=FacturaResponse, status_code=status.HTTP_201_CREATED)
def factura_global_tarjetas(
    factura_data: FacturaGlobalRequest,
    current_user: Annotated[Usuario, Depends(require_cajero_or_admin)],
    db: Session = Depends(get_db)
):
    """
    Generar factura global de ventas con tarjeta.
    
    Agrupa todas las ventas con método de pago TARJETA
    en un rango de fechas (típicamente día completo).
    
    **Uso típico**: Al final del día para facturas SAT.
    
    Requiere rol: CAJERO o ADMIN
    """
    service = FacturacionService(db)
    factura = service.factura_global_tarjetas(
        fecha_desde=factura_data.fecha_desde,
        fecha_hasta=factura_data.fecha_hasta,
        punto_venta_id=factura_data.punto_venta_id
    )
    
    return _build_factura_response(factura)


@router.post("/{factura_id}/cancelar", response_model=FacturaResponse)
def cancelar_factura(
    factura_id: int,
    current_user: Annotated[Usuario, Depends(require_cajero_or_admin)],
    motivo: str = Query('02', description="Código motivo SAT"),
    db: Session = Depends(get_db)
):
    """
    Cancelar factura en el SAT.
    
    **Motivos SAT**:
    - 01: Comprobante emitido con errores con relación
    - 02: Comprobante emitido con errores sin relación
    - 03: No se llevó a cabo la operación
    - 04: Operación nominativa relacionada con factura global
    
    Requiere rol: CAJERO o ADMIN
    """
    service = FacturacionService(db)
    factura = service.cancelar_factura(factura_id, motivo)
    
    return _build_factura_response(factura)
