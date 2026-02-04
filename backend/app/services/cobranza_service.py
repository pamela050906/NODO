"""
Servicio para gestión de cobranza (ventas a crédito).
"""
from sqlalchemy.orm import Session
from sqlalchemy import text
from fastapi import HTTPException, status
from typing import List
from datetime import datetime, timedelta
from decimal import Decimal

from app.models.cliente import Cliente, CuentaPorCobrar, PagoCuenta


class CobranzaService:
    """Servicio para gestión de ventas a crédito y cobranza."""
    
    def __init__(self, db: Session):
        self.db = db
    
    def crear_cliente(
        self,
        nombre: str,
        rfc: str = None,
        telefono: str = None,
        email: str = None,
        direccion: str = None,
        limite_credito: float = 0
    ) -> Cliente:
        """Crear un nuevo cliente."""
        try:
            cliente = Cliente(
                nombre=nombre,
                rfc=rfc,
                telefono=telefono,
                email=email,
                direccion=direccion,
                limite_credito=limite_credito,
                activo=True
            )
            
            self.db.add(cliente)
            self.db.commit()
            self.db.refresh(cliente)
            
            return cliente
            
        except Exception as e:
            self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al crear cliente: {str(e)}"
            )
    
    def crear_venta_credito(
        self,
        venta_id: int,
        cliente_id: int,
        dias_credito: int = 30
    ) -> CuentaPorCobrar:
        """
        Crear cuenta por cobrar para una venta a crédito.
        
        Args:
            venta_id: ID de la venta
            cliente_id: ID del cliente
            dias_credito: Días de plazo para pago
            
        Returns:
            Cuenta por cobrar creada
        """
        try:
            # Obtener total de la venta
            result = self.db.execute(
                text("SELECT total FROM ventas WHERE id = :venta_id"),
                {'venta_id': venta_id}
            ).fetchone()
            
            if not result:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Venta {venta_id} no encontrada"
                )
            
            monto_total = result.total
            
            # Validar límite de crédito del cliente
            cliente = self.db.query(Cliente).filter(Cliente.id == cliente_id).first()
            
            if not cliente:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Cliente {cliente_id} no encontrado"
                )
            
            # Calcular saldo actual del cliente
            saldo_actual = self.db.execute(
                text("SELECT COALESCE(SUM(saldo_pendiente), 0) FROM cuentas_por_cobrar WHERE cliente_id = :cliente_id AND estado != 'PAGADA'"),
                {'cliente_id': cliente_id}
            ).scalar()
            
            if (saldo_actual + monto_total) > cliente.limite_credito:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Excede límite de crédito. Límite: ${cliente.limite_credito}, Saldo: ${saldo_actual}, Venta: ${monto_total}"
                )
            
            # Crear cuenta por cobrar
            fecha_vencimiento = datetime.now() + timedelta(days=dias_credito)
            
            cuenta = CuentaPorCobrar(
                venta_id=venta_id,
                cliente_id=cliente_id,
                monto_total=monto_total,
                monto_pagado=0,
                saldo_pendiente=monto_total,
                fecha_vencimiento=fecha_vencimiento,
                estado='PENDIENTE'
            )
            
            self.db.add(cuenta)
            
            # Actualizar tipo de venta
            self.db.execute(
                text("UPDATE ventas SET tipo_venta = 'CREDITO', cliente_id = :cliente_id WHERE id = :venta_id"),
                {'cliente_id': cliente_id, 'venta_id': venta_id}
            )
            
            self.db.commit()
            self.db.refresh(cuenta)
            
            return cuenta
            
        except HTTPException:
            self.db.rollback()
            raise
        except Exception as e:
            self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al crear venta a crédito: {str(e)}"
            )
    
    def registrar_pago(
        self,
        cuenta_id: int,
        monto: float,
        metodo_pago: str,
        referencia: str = None,
        notas: str = None,
        usuario_id: int = None
    ) -> PagoCuenta:
        """
        Registrar un pago/abono a una cuenta por cobrar.
        
        Args:
            cuenta_id: ID de la cuenta
            monto: Monto del pago
            metodo_pago: EFECTIVO, TARJETA, TRANSFERENCIA, CHEQUE
            referencia: Número de referencia
            notas: Notas adicionales
            usuario_id: Usuario que registra el pago
            
        Returns:
            Pago registrado
        """
        try:
            # Validar cuenta existe
            cuenta = self.db.query(CuentaPorCobrar).filter(
                CuentaPorCobrar.id == cuenta_id
            ).with_for_update().first()
            
            if not cuenta:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Cuenta {cuenta_id} no encontrada"
                )
            
            if cuenta.estado == 'PAGADA':
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="La cuenta ya está pagada completamente"
                )
            
            # Validar monto no excede saldo
            if monto > cuenta.saldo_pendiente:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"El monto (${monto}) excede el saldo pendiente (${cuenta.saldo_pendiente})"
                )
            
            # Crear registro de pago
            pago = PagoCuenta(
                cuenta_id=cuenta_id,
                monto=monto,
                metodo_pago=metodo_pago,
                referencia=referencia,
                notas=notas,
                usuario_id=usuario_id
            )
            
            self.db.add(pago)
            # El trigger fn_actualizar_cuenta_pago actualizará automáticamente
            # el saldo y estado de la cuenta
            
            self.db.commit()
            self.db.refresh(pago)
            
            return pago
            
        except HTTPException:
            self.db.rollback()
            raise
        except Exception as e:
            self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al registrar pago: {str(e)}"
            )
    
    def listar_cuentas_por_cobrar(
        self,
        cliente_id: int = None,
        estado: str = None,
        vencidas: bool = False
    ) -> List[dict]:
        """
        Listar cuentas por cobrar con filtros.
        
        Args:
            cliente_id: Filtrar por cliente
            estado: PENDIENTE, PAGADA, VENCIDA
            vencidas: Solo cuentas vencidas
            
        Returns:
            Lista de cuentas
        """
        query = """
            SELECT 
                c.id,
                c.venta_id,
                c.cliente_id,
                cl.nombre as cliente_nombre,
                cl.rfc,
                c.monto_total,
                c.monto_pagado,
                c.saldo_pendiente,
                c.fecha_vencimiento,
                c.estado,
                c.creada_en,
                v.creada_en as fecha_venta
            FROM cuentas_por_cobrar c
            JOIN clientes cl ON c.cliente_id = cl.id
            JOIN ventas v ON c.venta_id = v.id
            WHERE 1=1
        """
        
        params = {}
        
        if cliente_id:
            query += " AND c.cliente_id = :cliente_id"
            params['cliente_id'] = cliente_id
        
        if estado:
            query += " AND c.estado = :estado"
            params['estado'] = estado
        
        if vencidas:
            query += " AND c.fecha_vencimiento < NOW() AND c.estado = 'PENDIENTE'"
        
        query += " ORDER BY c.fecha_vencimiento ASC, c.creada_en DESC"
        
        result = self.db.execute(text(query), params)
        
        cuentas = []
        for row in result:
            cuentas.append({
                'id': row.id,
                'venta_id': row.venta_id,
                'cliente_id': row.cliente_id,
                'cliente_nombre': row.cliente_nombre,
                'rfc': row.rfc,
                'monto_total': float(row.monto_total),
                'monto_pagado': float(row.monto_pagado),
                'saldo_pendiente': float(row.saldo_pendiente),
                'fecha_vencimiento': row.fecha_vencimiento.isoformat() if row.fecha_vencimiento else None,
                'estado': row.estado,
                'fecha_venta': row.fecha_venta.isoformat(),
                'dias_vencido': (datetime.now() - row.fecha_vencimiento).days if row.fecha_vencimiento and datetime.now() > row.fecha_vencimiento else 0
            })
        
        return cuentas
    
    def obtener_estado_cuenta_cliente(self, cliente_id: int) -> dict:
        """
        Obtener estado de cuenta de un cliente.
        
        Args:
            cliente_id: ID del cliente
            
        Returns:
            Estado de cuenta completo
        """
        # Info del cliente
        cliente = self.db.query(Cliente).filter(Cliente.id == cliente_id).first()
        
        if not cliente:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Cliente {cliente_id} no encontrado"
            )
        
        # Cuentas del cliente
        cuentas = self.listar_cuentas_por_cobrar(cliente_id=cliente_id)
        
        # Calcular totales
        saldo_total = sum(c['saldo_pendiente'] for c in cuentas if c['estado'] == 'PENDIENTE')
        credito_disponible = float(cliente.limite_credito) - saldo_total
        cuentas_vencidas = sum(1 for c in cuentas if c['dias_vencido'] > 0)
        
        return {
            'cliente': {
                'id': cliente.id,
                'nombre': cliente.nombre,
                'rfc': cliente.rfc,
                'telefono': cliente.telefono,
                'email': cliente.email,
                'limite_credito': float(cliente.limite_credito)
            },
            'estado_cuenta': {
                'saldo_total': saldo_total,
                'credito_disponible': credito_disponible,
                'cuentas_activas': len([c for c in cuentas if c['estado'] == 'PENDIENTE']),
                'cuentas_vencidas': cuentas_vencidas
            },
            'cuentas': cuentas
        }
