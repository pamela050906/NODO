"""
Router para configuración fiscal del sistema.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Annotated
from datetime import datetime

from app.core.database import get_db
from app.api.dependencies import require_admin, get_current_active_user
from app.models.usuario import Usuario
from app.models.factura import ConfiguracionFiscal
from pydantic import BaseModel, Field

router = APIRouter(prefix="/configuracion", tags=["Configuración"])


class ConfiguracionFiscalRequest(BaseModel):
    """Request para configuración fiscal."""
    rfc_emisor: str = Field(..., min_length=12, max_length=13)
    nombre_emisor: str = Field(..., max_length=255)
    razon_social: str = Field(..., max_length=255)
    regimen_fiscal: str = Field(..., max_length=10, description="Código régimen fiscal SAT")
    
    # Domicilio
    calle: str | None = None
    numero_exterior: str | None = None
    numero_interior: str | None = None
    colonia: str | None = None
    localidad: str | None = None
    municipio: str | None = None
    estado: str | None = None
    pais: str = Field(default='México')
    codigo_postal: str = Field(..., min_length=5, max_length=5)
    
    # Certificados
    no_certificado: str | None = None
    vigencia_desde: str | None = None
    vigencia_hasta: str | None = None


class ConfiguracionFiscalResponse(BaseModel):
    """Response para configuración fiscal."""
    id: int
    rfc_emisor: str
    nombre_emisor: str
    razon_social: str
    regimen_fiscal: str
    calle: str | None
    numero_exterior: str | None
    numero_interior: str | None
    colonia: str | None
    localidad: str | None
    municipio: str | None
    estado: str | None
    pais: str
    codigo_postal: str
    no_certificado: str | None
    vigencia_desde: str | None
    vigencia_hasta: str | None
    activo: bool


@router.get("/fiscal", response_model=ConfiguracionFiscalResponse)
def obtener_configuracion_fiscal(
    current_user: Annotated[Usuario, Depends(get_current_active_user)],
    db: Session = Depends(get_db)
):
    """
    Obtener configuración fiscal activa del emisor.
    
    Requiere autenticación.
    """
    config = db.query(ConfiguracionFiscal).filter(
        ConfiguracionFiscal.activo == True
    ).first()
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No hay configuración fiscal configurada"
        )
    
    return ConfiguracionFiscalResponse(
        id=config.id,
        rfc_emisor=config.rfc_emisor,
        nombre_emisor=config.nombre_emisor,
        razon_social=config.razon_social,
        regimen_fiscal=config.regimen_fiscal,
        calle=config.calle,
        numero_exterior=config.numero_exterior,
        numero_interior=config.numero_interior,
        colonia=config.colonia,
        localidad=config.localidad,
        municipio=config.municipio,
        estado=config.estado,
        pais=config.pais,
        codigo_postal=config.codigo_postal,
        no_certificado=config.no_certificado,
        vigencia_desde=config.vigencia_desde.isoformat() if config.vigencia_desde else None,
        vigencia_hasta=config.vigencia_hasta.isoformat() if config.vigencia_hasta else None,
        activo=config.activo
    )


@router.post("/fiscal", response_model=ConfiguracionFiscalResponse, status_code=status.HTTP_201_CREATED)
def crear_configuracion_fiscal(
    config_data: ConfiguracionFiscalRequest,
    current_user: Annotated[Usuario, Depends(require_admin)],
    db: Session = Depends(get_db)
):
    """
    Crear o actualizar configuración fiscal del emisor.
    
    Si ya existe una configuración con el mismo RFC, la desactiva
    y crea una nueva.
    
    Requiere rol: ADMIN
    """
    # Desactivar configuraciones anteriores con el mismo RFC
    db.query(ConfiguracionFiscal).filter(
        ConfiguracionFiscal.rfc_emisor == config_data.rfc_emisor
    ).update({'activo': False})
    
    # Crear nueva configuración
    config = ConfiguracionFiscal(
        rfc_emisor=config_data.rfc_emisor,
        nombre_emisor=config_data.nombre_emisor,
        razon_social=config_data.razon_social,
        regimen_fiscal=config_data.regimen_fiscal,
        calle=config_data.calle,
        numero_exterior=config_data.numero_exterior,
        numero_interior=config_data.numero_interior,
        colonia=config_data.colonia,
        localidad=config_data.localidad,
        municipio=config_data.municipio,
        estado=config_data.estado,
        pais=config_data.pais,
        codigo_postal=config_data.codigo_postal,
        no_certificado=config_data.no_certificado,
        vigencia_desde=datetime.fromisoformat(config_data.vigencia_desde) if config_data.vigencia_desde else None,
        vigencia_hasta=datetime.fromisoformat(config_data.vigencia_hasta) if config_data.vigencia_hasta else None,
        activo=True
    )
    
    db.add(config)
    db.commit()
    db.refresh(config)
    
    return ConfiguracionFiscalResponse(
        id=config.id,
        rfc_emisor=config.rfc_emisor,
        nombre_emisor=config.nombre_emisor,
        razon_social=config.razon_social,
        regimen_fiscal=config.regimen_fiscal,
        calle=config.calle,
        numero_exterior=config.numero_exterior,
        numero_interior=config.numero_interior,
        colonia=config.colonia,
        localidad=config.localidad,
        municipio=config.municipio,
        estado=config.estado,
        pais=config.pais,
        codigo_postal=config.codigo_postal,
        no_certificado=config.no_certificado,
        vigencia_desde=config.vigencia_desde.isoformat() if config.vigencia_desde else None,
        vigencia_hasta=config.vigencia_hasta.isoformat() if config.vigencia_hasta else None,
        activo=config.activo
    )


@router.put("/fiscal/{config_id}", response_model=ConfiguracionFiscalResponse)
def actualizar_configuracion_fiscal(
    config_id: int,
    config_data: ConfiguracionFiscalRequest,
    current_user: Annotated[Usuario, Depends(require_admin)],
    db: Session = Depends(get_db)
):
    """
    Actualizar configuración fiscal existente.
    
    Requiere rol: ADMIN
    """
    config = db.query(ConfiguracionFiscal).filter(
        ConfiguracionFiscal.id == config_id
    ).first()
    
    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Configuración fiscal no encontrada"
        )
    
    # Actualizar campos
    config.rfc_emisor = config_data.rfc_emisor
    config.nombre_emisor = config_data.nombre_emisor
    config.razon_social = config_data.razon_social
    config.regimen_fiscal = config_data.regimen_fiscal
    config.calle = config_data.calle
    config.numero_exterior = config_data.numero_exterior
    config.numero_interior = config_data.numero_interior
    config.colonia = config_data.colonia
    config.localidad = config_data.localidad
    config.municipio = config_data.municipio
    config.estado = config_data.estado
    config.pais = config_data.pais
    config.codigo_postal = config_data.codigo_postal
    config.no_certificado = config_data.no_certificado
    
    if config_data.vigencia_desde:
        config.vigencia_desde = datetime.fromisoformat(config_data.vigencia_desde)
    if config_data.vigencia_hasta:
        config.vigencia_hasta = datetime.fromisoformat(config_data.vigencia_hasta)
    
    config.actualizado_en = datetime.now()
    
    db.commit()
    db.refresh(config)
    
    return ConfiguracionFiscalResponse(
        id=config.id,
        rfc_emisor=config.rfc_emisor,
        nombre_emisor=config.nombre_emisor,
        razon_social=config.razon_social,
        regimen_fiscal=config.regimen_fiscal,
        calle=config.calle,
        numero_exterior=config.numero_exterior,
        numero_interior=config.numero_interior,
        colonia=config.colonia,
        localidad=config.localidad,
        municipio=config.municipio,
        estado=config.estado,
        pais=config.pais,
        codigo_postal=config.codigo_postal,
        no_certificado=config.no_certificado,
        vigencia_desde=config.vigencia_desde.isoformat() if config.vigencia_desde else None,
        vigencia_hasta=config.vigencia_hasta.isoformat() if config.vigencia_hasta else None,
        activo=config.activo
    )
