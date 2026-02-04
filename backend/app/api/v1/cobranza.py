from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Annotated, Optional
from datetime import date

from app.core.database import get_db
from app.api.dependencies import require_cajero_or_admin, get_current_active_user
from app.models.usuario import Usuario
from app.services.cobranza_service import CobranzaService
from pydantic import BaseModel, Field
from decimal import Decimal

router = APIRouter(prefix="/cobranza", tags=["Cobranza"])


class ClienteCreateRequest(BaseModel):
    """Request para crear cliente."""
    nombre: str = Field(..., min_length=1, max_length=200)
    rfc: str | None = Field(None, max_length=13)
    telefono: str | None = Field(None, max_length=15)
    email: str | None = Field(None, max_length=150)
    direccion: str | None = None
    limite_credito: Decimal = Field(default=Decimal("0"), ge=0)


class VentaCreditoRequest(BaseModel):
    """Request para convertir venta a crédito."""
    venta_id: int
    cliente_id: int
    dias_credito: int = Field(default=30, ge=1, le=365)


class PagoRequest(BaseModel):
    """Request para registrar pago."""
    cuenta_id: int
    monto: Decimal = Field(..., gt=0)
    metodo_pago: str = Field(..., description="EFECTIVO, TARJETA, TRANSFERENCIA, CHEQUE")
    referencia: str | None = Field(None, max_length=100)
    notas: str | None = None


@router.post("/clientes", status_code=status.HTTP_201_CREATED)
def crear_cliente(
    cliente_data: ClienteCreateRequest,
    current_user: Annotated[Usuario, Depends(require_cajero_or_admin)],
    db: Session = Depends(get_db)
):
    """
    Crear un nuevo cliente.
    
    Requiere rol: CAJERO o ADMIN
    """
    service = CobranzaService(db)
    return service.crear_cliente(
        nombre=cliente_data.nombre,
        rfc=cliente_data.rfc,
        telefono=cliente_data.telefono,
        email=cliente_data.email,
        direccion=cliente_data.direccion,
        limite_credito=float(cliente_data.limite_credito)
    )


@router.post("/ventas-credito", status_code=status.HTTP_201_CREATED)
def crear_venta_credito(
    venta_credito: VentaCreditoRequest,
    current_user: Annotated[Usuario, Depends(require_cajero_or_admin)],
    db: Session = Depends(get_db)
):
    """
    Convertir venta a crédito y crear cuenta por cobrar.
    
    Valida que el cliente no exceda su límite de crédito.
    
    Requiere rol: CAJERO o ADMIN
    """
    service = CobranzaService(db)
    return service.crear_venta_credito(
        venta_id=venta_credito.venta_id,
        cliente_id=venta_credito.cliente_id,
        dias_credito=venta_credito.dias_credito
    )


@router.get("/cuentas-por-cobrar")
def listar_cuentas(
    cliente_id: Optional[int] = Query(None, description="Filtrar por cliente"),
    estado: Optional[str] = Query(None, description="PENDIENTE, PAGADA, VENCIDA"),
    vencidas: bool = Query(False, description="Solo cuentas vencidas"),
    current_user: Annotated[Usuario, Depends(get_current_active_user)] = None,
    db: Session = Depends(get_db)
):
    """
    Listar cuentas por cobrar.
    
    Permite filtrar por cliente, estado o vencimiento.
    
    Requiere autenticación.
    """
    service = CobranzaService(db)
    return service.listar_cuentas_por_cobrar(
        cliente_id=cliente_id,
        estado=estado,
        vencidas=vencidas
    )


@router.post("/pagos", status_code=status.HTTP_201_CREATED)
def registrar_pago(
    pago_data: PagoRequest,
    current_user: Annotated[Usuario, Depends(require_cajero_or_admin)],
    db: Session = Depends(get_db)
):
    """
    Registrar un pago/abono a una cuenta por cobrar.
    
    El sistema automáticamente:
    - Actualiza el saldo de la cuenta
    - Cambia estado a PAGADA si el saldo llega a 0
    - Registra el historial de pagos
    
    Requiere rol: CAJERO o ADMIN
    """
    service = CobranzaService(db)
    return service.registrar_pago(
        cuenta_id=pago_data.cuenta_id,
        monto=float(pago_data.monto),
        metodo_pago=pago_data.metodo_pago,
        referencia=pago_data.referencia,
        notas=pago_data.notas,
        usuario_id=current_user.id
    )


@router.get("/estado-cuenta/{cliente_id}")
def estado_cuenta_cliente(
    cliente_id: int,
    current_user: Annotated[Usuario, Depends(get_current_active_user)],
    db: Session = Depends(get_db)
):
    """
    Obtener estado de cuenta completo de un cliente.
    
    Incluye:
    - Info del cliente
    - Saldo total pendiente
    - Crédito disponible
    - Lista de cuentas activas
    - Historial de pagos
    
    Requiere autenticación.
    """
    service = CobranzaService(db)
    return service.obtener_estado_cuenta_cliente(cliente_id)
