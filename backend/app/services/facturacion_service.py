"""
Servicio para facturación SAT.
"""
from sqlalchemy.orm import Session
from sqlalchemy import text
from fastapi import HTTPException, status
from typing import List, Optional
from datetime import datetime, date
from decimal import Decimal

from app.models.factura import Factura, FacturaVenta, FolioSAT, ConfiguracionFiscal, FacturaConcepto


class PACAdapter:
    """
    Adapter para integración con PAC (Proveedor Autorizado de Certificación).
    
    Esta clase es un stub para desarrollo. En producción, implementar con:
    - Finkok, Diverza, SW Sapien, etc.
    """
    
    @staticmethod
    def timbrar_factura(factura_data: dict) -> dict:
        """
        Timbrar factura con el PAC.
        
        Args:
            factura_data: Datos de la factura (RFC, total, conceptos, etc.)
            
        Returns:
            Respuesta del PAC con UUID, XML, PDF
        """
        # STUB - En producción, integrar con API del PAC
        import uuid
        
        # Simular respuesta del PAC
        uuid_generado = str(uuid.uuid4())
        
        return {
            'exitoso': True,
            'uuid': uuid_generado,
            'xml_content': '<?xml version="1.0"?><!-- XML CFDI aquí -->',
            'xml_url': f'https://pac.example.com/xml/{uuid_generado}.xml',
            'pdf_url': f'https://pac.example.com/pdf/{uuid_generado}.pdf',
            'fecha_timbrado': datetime.now().isoformat()
        }
    
    @staticmethod
    def cancelar_factura(uuid_sat: str, motivo: str) -> dict:
        """
        Cancelar factura en el SAT.
        
        Args:
            uuid_sat: UUID de la factura a cancelar
            motivo: Motivo de cancelación (código SAT)
            
        Returns:
            Respuesta del PAC
        """
        # STUB - En producción, integrar con API del PAC
        return {
            'exitoso': True,
            'mensaje': 'Factura cancelada en el SAT',
            'fecha_cancelacion': datetime.now().isoformat()
        }


class FacturacionService:
    """Servicio para gestión de facturación SAT."""
    
    def __init__(self, db: Session):
        self.db = db
        self.pac = PACAdapter()
    
    def obtener_siguiente_folio(self, serie: str = 'A') -> int:
        """Obtener siguiente folio disponible para una serie."""
        folio_sat = self.db.query(FolioSAT).filter(
            FolioSAT.serie == serie,
            FolioSAT.activo == True
        ).with_for_update().first()
        
        if not folio_sat:
            # Crear serie si no existe
            folio_sat = FolioSAT(serie=serie, folio_actual=1, activo=True)
            self.db.add(folio_sat)
            self.db.flush()
            return 1
        
        folio_sat.folio_actual += 1
        self.db.flush()
        
        return folio_sat.folio_actual
    
    def crear_factura_borrador(
        self,
        ventas_ids: List[int],
        rfc_receptor: str,
        nombre_receptor: str,
        uso_cfdi: str = 'G03',
        serie: str = 'A',
        regimen_fiscal_receptor: str = None,
        domicilio_fiscal_receptor: str = None,
        tipo_comprobante: str = 'I',
        forma_pago: str = None,
        metodo_pago: str = 'PUE',
        moneda: str = 'MXN',
        tipo_cambio: float = None,
        observaciones: str = None
    ) -> Factura:
        """
        Crear factura en estado BORRADOR.
        
        Args:
            ventas_ids: Lista de IDs de ventas a facturar
            rfc_receptor: RFC del cliente
            uso_cfdi: Uso de CFDI (G01, G03, etc.)
            serie: Serie de facturación
            
        Returns:
            Factura creada
        """
        try:
            # Validar ventas existen y están cerradas
            ventas = self.db.execute(
                text("""
                    SELECT id, total, metodo_pago, estado
                    FROM ventas
                    WHERE id = ANY(:ventas_ids)
                """),
                {'ventas_ids': ventas_ids}
            ).fetchall()
            
            if len(ventas) != len(ventas_ids):
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Una o más ventas no encontradas"
                )
            
            # Validar todas están cerradas
            for venta in ventas:
                if venta.estado != 'CERRADA':
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Venta {venta.id} debe estar CERRADA para facturar"
                    )
            
            # Obtener configuración fiscal del emisor
            config_fiscal = self.db.query(ConfiguracionFiscal).filter(
                ConfiguracionFiscal.activo == True
            ).first()
            
            if not config_fiscal:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="No hay configuración fiscal activa. Configure los datos del emisor."
                )
            
            # Calcular totales
            subtotal = sum(v.total for v in ventas)
            # TODO: Calcular IVA desde los conceptos cuando se implementen
            iva_tasa = Decimal('0.16')
            iva_trasladado = subtotal * iva_tasa
            total = subtotal + iva_trasladado
            
            # Obtener siguiente folio
            folio = self.obtener_siguiente_folio(serie)
            
            # Crear factura con todos los campos CFDI
            factura = Factura(
                serie=serie,
                folio=folio,
                fecha=datetime.now(),
                fecha_emision=datetime.now(),
                estado='BORRADOR',
                
                # Emisor (desde configuración fiscal)
                rfc_emisor=config_fiscal.rfc_emisor,
                nombre_emisor=config_fiscal.nombre_emisor,
                regimen_fiscal_emisor=config_fiscal.regimen_fiscal,
                lugar_expedicion=config_fiscal.codigo_postal,
                
                # Receptor
                rfc_receptor=rfc_receptor,
                nombre_receptor=nombre_receptor,
                regimen_fiscal_receptor=regimen_fiscal_receptor,
                domicilio_fiscal_receptor=domicilio_fiscal_receptor,
                uso_cfdi=uso_cfdi,
                
                # Comprobante
                tipo_comprobante=tipo_comprobante,
                moneda=moneda,
                tipo_cambio=tipo_cambio,
                forma_pago=forma_pago,
                metodo_pago=metodo_pago,
                
                # Totales
                subtotal=subtotal,
                descuento=Decimal('0'),
                iva_trasladado=iva_trasladado,
                iva_retenido=Decimal('0'),
                ieps_trasladado=Decimal('0'),
                isr_retenido=Decimal('0'),
                total=total,
                
                # Otros
                observaciones=observaciones
            )
            
            self.db.add(factura)
            self.db.flush()
            
            # Crear conceptos desde las ventas
            self._crear_conceptos_desde_ventas(factura.id, ventas_ids)
            
            # Relacionar ventas con factura
            for venta_id in ventas_ids:
                relacion = FacturaVenta(
                    factura_id=factura.id,
                    venta_id=venta_id
                )
                self.db.add(relacion)
            
            self.db.commit()
            self.db.refresh(factura)
            
            return factura
            
        except HTTPException:
            self.db.rollback()
            raise
        except Exception as e:
            self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al crear factura: {str(e)}"
            )
    
    def _crear_conceptos_desde_ventas(self, factura_id: int, ventas_ids: List[int]):
        """
        Crear conceptos de factura a partir de los detalles de ventas.
        
        Agrupa los productos vendidos y crea los conceptos para la factura.
        """
        # Obtener detalles de todas las ventas
        detalles = self.db.execute(
            text("""
                SELECT 
                    vp.nombre as producto_nombre,
                    vd.cantidad,
                    vd.precio_unitario,
                    SUM(vd.cantidad) as cantidad_total,
                    vd.precio_unitario as precio_promedio
                FROM venta_detalles vd
                JOIN variantes_producto vp ON vd.variante_id = vp.id
                WHERE vd.venta_id = ANY(:ventas_ids)
                GROUP BY vp.nombre, vd.cantidad, vd.precio_unitario
            """),
            {'ventas_ids': ventas_ids}
        ).fetchall()
        
        numero_linea = 1
        for detalle in detalles:
            cantidad = detalle.cantidad
            precio_unitario = detalle.precio_unitario
            importe = cantidad * precio_unitario
            
            concepto = FacturaConcepto(
                factura_id=factura_id,
                clave_prod_serv='01010101',  # Clave genérica - TODO: obtener del producto
                no_identificacion=None,
                cantidad=cantidad,
                clave_unidad='H87',  # H87 = Pieza
                unidad='Pieza',
                descripcion=detalle.producto_nombre,
                precio_unitario=precio_unitario,
                importe=importe,
                descuento=Decimal('0'),
                objeto_impuesto='02',  # Sí objeto de impuesto
                numero_linea=numero_linea
            )
            
            self.db.add(concepto)
            numero_linea += 1
        
        self.db.flush()
    
    def timbrar_factura(self, factura_id: int) -> Factura:
        """
        Timbrar factura con el PAC.
        
        Envía la factura al PAC para obtener UUID y archivos XML/PDF.
        
        Args:
            factura_id: ID de la factura
            
        Returns:
            Factura timbrada
        """
        try:
            factura = self.db.query(Factura).filter(
                Factura.id == factura_id
            ).with_for_update().first()
            
            if not factura:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Factura {factura_id} no encontrada"
                )
            
            if factura.estado != 'BORRADOR':
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Solo se pueden timbrar facturas en BORRADOR. Estado actual: {factura.estado}"
                )
            
            # Preparar datos para el PAC
            factura_data = {
                'serie': factura.serie,
                'folio': factura.folio,
                'fecha': factura.fecha.isoformat(),
                'rfc_emisor': factura.rfc_emisor,
                'rfc_receptor': factura.rfc_receptor,
                'total': float(factura.total),
                'uso_cfdi': factura.uso_cfdi
            }
            
            # Timbrar con PAC
            resultado = self.pac.timbrar_factura(factura_data)
            
            if not resultado['exitoso']:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Error al timbrar con el PAC"
                )
            
            # Actualizar factura con datos del timbrado
            factura.uuid_sat = resultado['uuid']
            factura.xml_content = resultado['xml_content']
            factura.xml_url = resultado['xml_url']
            factura.pdf_url = resultado['pdf_url']
            factura.estado = 'TIMBRADA'
            
            self.db.commit()
            self.db.refresh(factura)
            
            return factura
            
        except HTTPException:
            self.db.rollback()
            raise
        except Exception as e:
            self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al timbrar factura: {str(e)}"
            )
    
    def factura_global_tarjetas(
        self,
        fecha_desde: date,
        fecha_hasta: date,
        punto_venta_id: int = None
    ) -> Factura:
        """
        Generar factura global de ventas con tarjeta.
        
        Agrupa todas las ventas con método de pago TARJETA
        en un rango de fechas y crea una factura global.
        
        Args:
            fecha_desde: Fecha de inicio
            fecha_hasta: Fecha de fin
            punto_venta_id: Filtrar por punto de venta (opcional)
            
        Returns:
            Factura global creada
        """
        try:
            # Buscar ventas con tarjeta sin facturar
            query = """
                SELECT v.id
                FROM ventas v
                LEFT JOIN factura_ventas fv ON v.id = fv.venta_id
                WHERE v.metodo_pago = 'TARJETA'
                AND v.estado = 'CERRADA'
                AND DATE(v.creada_en) >= :fecha_desde
                AND DATE(v.creada_en) <= :fecha_hasta
                AND fv.factura_id IS NULL
            """
            
            params = {
                'fecha_desde': fecha_desde,
                'fecha_hasta': fecha_hasta
            }
            
            if punto_venta_id:
                query += " AND v.punto_venta_id = :punto_venta_id"
                params['punto_venta_id'] = punto_venta_id
            
            result = self.db.execute(text(query), params)
            ventas_ids = [row.id for row in result]
            
            if not ventas_ids:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="No se encontraron ventas con tarjeta sin facturar en el periodo"
                )
            
            # Crear factura global
            # RFC genérico para factura global
            factura = self.crear_factura_borrador(
                ventas_ids=ventas_ids,
                rfc_receptor='XAXX010101000',  # Público en general
                uso_cfdi='G03',  # Gastos en general
                serie='G'  # Serie para facturas globales
            )
            
            return factura
            
        except HTTPException:
            raise
        except Exception as e:
            self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al crear factura global: {str(e)}"
            )
    
    def cancelar_factura(self, factura_id: int, motivo: str = '02') -> Factura:
        """
        Cancelar factura en el SAT.
        
        Args:
            factura_id: ID de la factura
            motivo: Código de motivo SAT (01, 02, 03, 04)
            
        Returns:
            Factura cancelada
        """
        try:
            factura = self.db.query(Factura).filter(
                Factura.id == factura_id
            ).with_for_update().first()
            
            if not factura:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Factura {factura_id} no encontrada"
                )
            
            if factura.estado != 'TIMBRADA':
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Solo se pueden cancelar facturas TIMBRADAS"
                )
            
            # Cancelar en el PAC
            resultado = self.pac.cancelar_factura(factura.uuid_sat, motivo)
            
            if not resultado['exitoso']:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Error al cancelar en el SAT"
                )
            
            # Actualizar estado
            factura.estado = 'CANCELADA'
            
            self.db.commit()
            self.db.refresh(factura)
            
            return factura
            
        except HTTPException:
            self.db.rollback()
            raise
        except Exception as e:
            self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al cancelar factura: {str(e)}"
            )
    
    def obtener_factura(self, factura_id: int) -> Factura:
        """Obtener factura por ID."""
        factura = self.db.query(Factura).filter(Factura.id == factura_id).first()
        
        if not factura:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Factura {factura_id} no encontrada"
            )
        
        return factura
    
    def listar_facturas(
        self,
        estado: str = None,
        fecha_desde: date = None,
        fecha_hasta: date = None,
        rfc_receptor: str = None
    ) -> List[dict]:
        """Listar facturas con filtros."""
        query = """
            SELECT 
                f.id,
                f.uuid_sat,
                f.serie,
                f.folio,
                f.fecha,
                f.total,
                f.rfc_emisor,
                f.rfc_receptor,
                f.estado,
                f.xml_url,
                f.pdf_url,
                COUNT(fv.venta_id) as total_ventas
            FROM facturas f
            LEFT JOIN factura_ventas fv ON f.id = fv.factura_id
            WHERE 1=1
        """
        
        params = {}
        
        if estado:
            query += " AND f.estado = :estado"
            params['estado'] = estado
        
        if fecha_desde:
            query += " AND DATE(f.fecha) >= :fecha_desde"
            params['fecha_desde'] = fecha_desde
        
        if fecha_hasta:
            query += " AND DATE(f.fecha) <= :fecha_hasta"
            params['fecha_hasta'] = fecha_hasta
        
        if rfc_receptor:
            query += " AND f.rfc_receptor = :rfc_receptor"
            params['rfc_receptor'] = rfc_receptor
        
        query += " GROUP BY f.id ORDER BY f.fecha DESC"
        
        result = self.db.execute(text(query), params)
        
        facturas = []
        for row in result:
            facturas.append({
                'id': row.id,
                'uuid_sat': row.uuid_sat,
                'serie': row.serie,
                'folio': row.folio,
                'fecha': row.fecha.isoformat() if row.fecha else None,
                'total': float(row.total) if row.total else 0,
                'rfc_emisor': row.rfc_emisor,
                'rfc_receptor': row.rfc_receptor,
                'estado': row.estado,
                'xml_url': row.xml_url,
                'pdf_url': row.pdf_url,
                'total_ventas': row.total_ventas
            })
        
        return facturas
