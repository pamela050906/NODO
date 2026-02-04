from sqlalchemy.orm import Session, joinedload
from typing import Optional, List
from datetime import datetime
from app.models.venta import Venta, VentaDetalle, EstadoVentaEnum


class VentaRepository:
    """Repositorio para operaciones de Venta."""
    
    def __init__(self, db: Session):
        self.db = db
    
    def create(self, venta: Venta) -> Venta:
        """Crear una nueva venta."""
        self.db.add(venta)
        self.db.flush()  # Flush para obtener el ID sin commit
        return venta
    
    def get_by_id(self, venta_id: int) -> Optional[Venta]:
        """
        Obtener venta por ID con sus detalles.
        """
        return self.db.query(Venta).options(
            joinedload(Venta.detalles)
        ).filter(
            Venta.id == venta_id
        ).first()
    
    def get_by_id_with_lock(self, venta_id: int) -> Optional[Venta]:
        """
        Obtener venta por ID con lock para actualización.
        Usa SELECT FOR UPDATE.
        """
        return self.db.query(Venta).filter(
            Venta.id == venta_id
        ).with_for_update().first()
    
    def add_detalle(self, detalle: VentaDetalle) -> VentaDetalle:
        """Agregar un detalle a una venta."""
        self.db.add(detalle)
        self.db.flush()
        return detalle
    
    def update_totales(
        self,
        venta_id: int,
        subtotal: float,
        descuento: float,
        impuesto: float,
        total: float
    ) -> bool:
        """Actualizar totales de una venta."""
        venta = self.get_by_id_with_lock(venta_id)
        
        if not venta:
            return False
        
        venta.subtotal = subtotal
        venta.descuento = descuento
        venta.impuesto = impuesto
        venta.total = total
        
        self.db.flush()
        return True
    
    def completar_venta(self, venta_id: int) -> bool:
        """Marcar una venta como cerrada."""
        venta = self.get_by_id_with_lock(venta_id)
        
        if not venta:
            return False
        
        venta.estado = EstadoVentaEnum.CERRADA.value
        venta.completed_at = datetime.utcnow()
        
        self.db.flush()
        return True
    
    def cancelar_venta(self, venta_id: int) -> bool:
        """Cancelar una venta."""
        venta = self.get_by_id_with_lock(venta_id)
        
        if not venta:
            return False
        
        venta.estado = EstadoVentaEnum.CANCELADA.value
        
        self.db.flush()
        return True
    
    def list_ventas(
        self,
        skip: int = 0,
        limit: int = 100,
        estado: Optional[EstadoVentaEnum] = None
    ) -> List[Venta]:
        """Listar ventas con paginación."""
        query = self.db.query(Venta).options(
            joinedload(Venta.detalles)
        )
        
        if estado:
            query = query.filter(Venta.estado == estado.value)
        
        return query.order_by(Venta.creada_en.desc()).offset(skip).limit(limit).all()
