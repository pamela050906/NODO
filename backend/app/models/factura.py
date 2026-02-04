from sqlalchemy import Column, Integer, String, Numeric, Boolean, DateTime, ForeignKey, Text, ARRAY
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class Factura(Base):
    """
    Modelo de Factura (CFDI).
    Representa una factura electrónica SAT con todos los campos requeridos por el SAT.
    """
    
    __tablename__ = "facturas"
    
    id = Column(Integer, primary_key=True, index=True)
    uuid_sat = Column(String(50), unique=True, index=True)  # UUID del SAT después de timbrado
    fecha = Column(DateTime(timezone=True))
    creada_en = Column(DateTime(timezone=True), server_default=func.now())
    
    # Campos básicos de factura
    serie = Column(String(10))
    folio = Column(Integer)
    estado = Column(String(20), default='BORRADOR')  # BORRADOR, TIMBRADA, CANCELADA
    
    # ===== INFORMACIÓN DEL EMISOR =====
    rfc_emisor = Column(String(13), nullable=False)
    nombre_emisor = Column(String(255))
    regimen_fiscal_emisor = Column(String(10))
    lugar_expedicion = Column(String(5))  # Código postal de expedición
    
    # ===== INFORMACIÓN DEL RECEPTOR =====
    rfc_receptor = Column(String(13))
    nombre_receptor = Column(String(255))
    regimen_fiscal_receptor = Column(String(10))
    domicilio_fiscal_receptor = Column(String(500))
    residencia_fiscal = Column(String(3))  # Para extranjeros
    num_reg_id_trib = Column(String(40))  # Número de registro de ID tributario (extranjeros)
    uso_cfdi = Column(String(10))  # G01, G03, etc.
    
    # ===== DATOS DEL COMPROBANTE =====
    tipo_comprobante = Column(String(1), default='I')  # I=Ingreso, E=Egreso, T=Traslado, P=Pago, N=Nómina
    moneda = Column(String(3), default='MXN')
    tipo_cambio = Column(Numeric(10, 6))
    exportacion = Column(String(3), default='01')  # 01=No aplica
    
    # ===== FORMAS Y MÉTODOS DE PAGO =====
    forma_pago = Column(String(10))  # 01=Efectivo, 03=Transferencia, 04=Tarjeta, 99=Por definir
    metodo_pago = Column(String(10))  # PUE=Pago en una exhibición, PPD=Pago diferido
    
    # ===== SUBTOTALES E IMPUESTOS =====
    subtotal = Column(Numeric(16, 2))
    descuento = Column(Numeric(16, 2), default=0)
    total = Column(Numeric(16, 2))
    iva_trasladado = Column(Numeric(16, 2), default=0)
    iva_retenido = Column(Numeric(16, 2), default=0)
    ieps_trasladado = Column(Numeric(16, 2), default=0)
    isr_retenido = Column(Numeric(16, 2), default=0)
    
    # ===== DATOS DE TIMBRADO SAT =====
    fecha_emision = Column(DateTime(timezone=True))
    fecha_timbrado = Column(DateTime(timezone=True))
    fecha_certificacion = Column(DateTime(timezone=True))
    certificado_sat = Column(String(50))
    no_certificado_emisor = Column(String(50))
    no_certificado_sat = Column(String(50))
    
    # Sellos digitales
    sello_cfdi = Column(Text)  # Sello digital del emisor
    sello_sat = Column(Text)  # Sello digital del SAT
    cadena_original_sat = Column(Text)  # Cadena original del complemento de certificación
    
    # ===== RELACIONES DE CFDI =====
    tipo_relacion = Column(String(2))  # 01=Nota de crédito, 02=Nota de débito, etc.
    uuid_relacionados = Column(ARRAY(Text))  # Array de UUIDs relacionados
    
    # ===== XML Y PDF =====
    xml_content = Column(Text)
    xml_url = Column(String(500))
    pdf_url = Column(String(500))
    
    # ===== CANCELACIÓN =====
    motivo_cancelacion = Column(String(2))
    fecha_cancelacion = Column(DateTime(timezone=True))
    
    # ===== OTROS =====
    observaciones = Column(Text)
    
    # Relaciones
    ventas = relationship("FacturaVenta", back_populates="factura")
    conceptos = relationship("FacturaConcepto", back_populates="factura", cascade="all, delete-orphan")


class FacturaVenta(Base):
    """
    Tabla de relación entre Facturas y Ventas.
    Una factura puede incluir múltiples ventas (factura global).
    """
    
    __tablename__ = "factura_ventas"
    
    factura_id = Column(Integer, ForeignKey("facturas.id"), primary_key=True)
    venta_id = Column(Integer, ForeignKey("ventas.id"), primary_key=True)
    
    # Relaciones
    factura = relationship("Factura", back_populates="ventas")


class FolioSAT(Base):
    """
    Modelo de Folios SAT.
    Controla la numeración de facturas por serie.
    """
    
    __tablename__ = "folios_sat"
    
    id = Column(Integer, primary_key=True, index=True)
    serie = Column(String(10))
    folio_actual = Column(Integer, nullable=False, default=0)
    activo = Column(Boolean, default=True)


class FacturaConcepto(Base):
    """
    Modelo de Concepto de Factura.
    Representa un producto o servicio dentro de una factura CFDI.
    """
    
    __tablename__ = "factura_conceptos"
    
    id = Column(Integer, primary_key=True, index=True)
    factura_id = Column(Integer, ForeignKey("facturas.id", ondelete="CASCADE"), nullable=False)
    
    # Identificación del concepto
    clave_prod_serv = Column(String(10), nullable=False)  # Clave SAT del producto/servicio
    no_identificacion = Column(String(100))  # SKU o número de identificación
    cantidad = Column(Numeric(16, 6), nullable=False)
    clave_unidad = Column(String(10), nullable=False)  # Clave SAT de la unidad (H87=Pieza)
    unidad = Column(String(50))  # Descripción de la unidad
    descripcion = Column(Text, nullable=False)
    
    # Valores monetarios
    precio_unitario = Column(Numeric(16, 6), nullable=False)
    importe = Column(Numeric(16, 2), nullable=False)
    descuento = Column(Numeric(16, 2), default=0)
    
    # Impuestos
    objeto_impuesto = Column(String(2), nullable=False, default='02')  # 01=No objeto, 02=Sí objeto
    
    # Orden
    numero_linea = Column(Integer, nullable=False)
    
    # Control
    creado_en = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relaciones
    factura = relationship("Factura", back_populates="conceptos")
    impuestos = relationship("FacturaConceptoImpuesto", back_populates="concepto", cascade="all, delete-orphan")


class FacturaConceptoImpuesto(Base):
    """
    Modelo de Impuestos de Concepto.
    Representa impuestos trasladados o retenidos de un concepto.
    """
    
    __tablename__ = "factura_concepto_impuestos"
    
    id = Column(Integer, primary_key=True, index=True)
    concepto_id = Column(Integer, ForeignKey("factura_conceptos.id", ondelete="CASCADE"), nullable=False)
    
    # Tipo de movimiento
    tipo_movimiento = Column(String(10), nullable=False)  # TRASLADO o RETENCION
    
    # Datos del impuesto
    base = Column(Numeric(16, 2), nullable=False)  # Base gravable
    impuesto = Column(String(10), nullable=False)  # 001=ISR, 002=IVA, 003=IEPS
    tipo_factor = Column(String(10), nullable=False)  # Tasa, Cuota, Exento
    tasa_o_cuota = Column(Numeric(8, 6), nullable=False)
    importe = Column(Numeric(16, 2), nullable=False)
    
    # Relaciones
    concepto = relationship("FacturaConcepto", back_populates="impuestos")


class ConfiguracionFiscal(Base):
    """
    Modelo de Configuración Fiscal.
    Almacena los datos fiscales del emisor (tu empresa).
    """
    
    __tablename__ = "configuracion_fiscal"
    
    id = Column(Integer, primary_key=True, index=True)
    rfc_emisor = Column(String(13), unique=True, nullable=False)
    nombre_emisor = Column(String(255), nullable=False)
    razon_social = Column(String(255), nullable=False)
    regimen_fiscal = Column(String(10), nullable=False)
    
    # Domicilio fiscal
    calle = Column(String(100))
    numero_exterior = Column(String(20))
    numero_interior = Column(String(20))
    colonia = Column(String(100))
    localidad = Column(String(100))
    municipio = Column(String(100))
    estado = Column(String(100))
    pais = Column(String(100), default='México')
    codigo_postal = Column(String(5), nullable=False)
    
    # Certificados SAT (archivos CSD)
    certificado_cer = Column(Text)  # Contenido Base64 del archivo .cer
    certificado_key = Column(Text)  # Contenido Base64 del archivo .key
    certificado_password = Column(String(255))
    no_certificado = Column(String(50))
    vigencia_desde = Column(DateTime(timezone=True))
    vigencia_hasta = Column(DateTime(timezone=True))
    
    # Control
    activo = Column(Boolean, default=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now())
    actualizado_en = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
