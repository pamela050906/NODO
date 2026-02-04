"""
Servicio para generación de reportes.
"""
from sqlalchemy.orm import Session
from sqlalchemy import text, func
from typing import List, Optional
from datetime import datetime, date
from decimal import Decimal
import csv
import io


class ReporteService:
    """Servicio para generar reportes del sistema."""
    
    def __init__(self, db: Session):
        self.db = db
    
    def reporte_ventas(
        self,
        fecha_desde: date = None,
        fecha_hasta: date = None,
        metodo_pago: str = None,
        facturado: bool = None,
        punto_venta_id: int = None
    ) -> dict:
        """
        Generar reporte de ventas con filtros.
        
        Args:
            fecha_desde: Fecha de inicio
            fecha_hasta: Fecha de fin
            metodo_pago: EFECTIVO o TARJETA
            facturado: True/False/None
            punto_venta_id: Filtrar por punto de venta
            
        Returns:
            Diccionario con ventas y resumen
        """
        query = """
            SELECT 
                v.id,
                v.creada_en,
                v.punto_venta_id,
                pv.codigo as punto_venta,
                u.nombre as usuario,
                v.metodo_pago,
                v.estado,
                v.subtotal,
                v.descuento,
                v.impuesto,
                v.total,
                CASE 
                    WHEN EXISTS (
                        SELECT 1 FROM factura_ventas fv 
                        WHERE fv.venta_id = v.id
                    ) THEN true 
                    ELSE false 
                END as facturado
            FROM ventas v
            JOIN puntos_venta pv ON v.punto_venta_id = pv.id
            JOIN usuarios u ON v.usuario_id = u.id
            WHERE 1=1
        """
        
        params = {}
        
        if fecha_desde:
            query += " AND DATE(v.creada_en) >= :fecha_desde"
            params['fecha_desde'] = fecha_desde
        
        if fecha_hasta:
            query += " AND DATE(v.creada_en) <= :fecha_hasta"
            params['fecha_hasta'] = fecha_hasta
        
        if metodo_pago:
            query += " AND v.metodo_pago = :metodo_pago"
            params['metodo_pago'] = metodo_pago
        
        if punto_venta_id:
            query += " AND v.punto_venta_id = :punto_venta_id"
            params['punto_venta_id'] = punto_venta_id
        
        query += " ORDER BY v.creada_en DESC"
        
        result = self.db.execute(text(query), params)
        
        ventas = []
        total_efectivo = Decimal('0')
        total_tarjeta = Decimal('0')
        total_general = Decimal('0')
        ventas_facturadas = 0
        
        for row in result:
            venta = {
                'id': row.id,
                'fecha': row.creada_en.strftime('%Y-%m-%d %H:%M:%S'),
                'punto_venta': row.punto_venta,
                'usuario': row.usuario,
                'metodo_pago': row.metodo_pago,
                'estado': row.estado,
                'subtotal': float(row.subtotal or 0),
                'descuento': float(row.descuento or 0),
                'impuesto': float(row.impuesto or 0),
                'total': float(row.total),
                'facturado': row.facturado
            }
            
            # Filtrar por facturado si se especifica
            if facturado is not None and venta['facturado'] != facturado:
                continue
            
            ventas.append(venta)
            
            # Acumular totales
            total_general += Decimal(str(row.total))
            if row.metodo_pago == 'EFECTIVO':
                total_efectivo += Decimal(str(row.total))
            elif row.metodo_pago == 'TARJETA':
                total_tarjeta += Decimal(str(row.total))
            
            if venta['facturado']:
                ventas_facturadas += 1
        
        return {
            'ventas': ventas,
            'resumen': {
                'total_ventas': len(ventas),
                'total_efectivo': float(total_efectivo),
                'total_tarjeta': float(total_tarjeta),
                'total_general': float(total_general),
                'ventas_facturadas': ventas_facturadas,
                'ventas_sin_facturar': len(ventas) - ventas_facturadas
            },
            'periodo': {
                'desde': fecha_desde.isoformat() if fecha_desde else None,
                'hasta': fecha_hasta.isoformat() if fecha_hasta else None
            }
        }
    
    def reporte_almacen(
        self,
        categoria: str = None,
        stock_bajo: bool = False
    ) -> dict:
        """
        Generar reporte de existencias en almacén.
        
        Args:
            categoria: Filtrar por categoría
            stock_bajo: Solo productos con stock <= 10
            
        Returns:
            Diccionario con existencias por producto
        """
        query = """
            SELECT 
                p.id as producto_id,
                p.nombre as producto_nombre,
                p.categoria,
                p.marca,
                v.id as variante_id,
                v.sku,
                v.talla,
                v.color,
                v.precio_menudeo,
                v.precio_mayoreo,
                COALESCE(i.stock, 0) as stock_actual
            FROM productos p
            JOIN variantes_producto v ON p.id = v.producto_id
            LEFT JOIN inventario i ON v.id = i.variante_id
            WHERE p.activo = true AND v.activo = true
        """
        
        params = {}
        
        if categoria:
            query += " AND p.categoria = :categoria"
            params['categoria'] = categoria
        
        if stock_bajo:
            query += " AND COALESCE(i.stock, 0) <= 10"
        
        query += " ORDER BY p.nombre, v.talla, v.color"
        
        result = self.db.execute(text(query), params)
        
        productos = []
        total_productos = 0
        total_variantes = 0
        total_unidades = 0
        valor_inventario = Decimal('0')
        
        for row in result:
            productos.append({
                'producto_id': row.producto_id,
                'producto_nombre': row.producto_nombre,
                'categoria': row.categoria,
                'marca': row.marca,
                'variante_id': row.variante_id,
                'sku': row.sku,
                'talla': row.talla,
                'color': row.color,
                'precio_menudeo': float(row.precio_menudeo),
                'precio_mayoreo': float(row.precio_mayoreo),
                'stock_actual': row.stock_actual
            })
            
            total_variantes += 1
            total_unidades += row.stock_actual
            valor_inventario += Decimal(str(row.precio_menudeo)) * row.stock_actual
        
        # Contar productos únicos
        productos_unicos = set(p['producto_id'] for p in productos)
        total_productos = len(productos_unicos)
        
        return {
            'productos': productos,
            'resumen': {
                'total_productos': total_productos,
                'total_variantes': total_variantes,
                'total_unidades': total_unidades,
                'valor_inventario': float(valor_inventario)
            }
        }
    
    def reporte_movimientos(
        self,
        fecha_desde: date = None,
        fecha_hasta: date = None,
        tipo: str = None
    ) -> dict:
        """
        Generar reporte de movimientos de inventario.
        
        Args:
            fecha_desde: Fecha de inicio
            fecha_hasta: Fecha de fin
            tipo: ENTRADA, SALIDA o AJUSTE
            
        Returns:
            Diccionario con movimientos y resumen
        """
        query = """
            SELECT 
                m.id,
                m.creado_en,
                m.tipo,
                m.cantidad,
                m.referencia,
                p.nombre as producto_nombre,
                v.sku,
                v.talla,
                v.color
            FROM movimientos_inventario m
            JOIN variantes_producto v ON m.variante_id = v.id
            JOIN productos p ON v.producto_id = p.id
            WHERE 1=1
        """
        
        params = {}
        
        if fecha_desde:
            query += " AND DATE(m.creado_en) >= :fecha_desde"
            params['fecha_desde'] = fecha_desde
        
        if fecha_hasta:
            query += " AND DATE(m.creado_en) <= :fecha_hasta"
            params['fecha_hasta'] = fecha_hasta
        
        if tipo:
            query += " AND m.tipo = :tipo"
            params['tipo'] = tipo
        
        query += " ORDER BY m.creado_en DESC"
        
        result = self.db.execute(text(query), params)
        
        movimientos = []
        total_entradas = 0
        total_salidas = 0
        total_ajustes = 0
        
        for row in result:
            movimientos.append({
                'id': row.id,
                'fecha': row.creado_en.strftime('%Y-%m-%d %H:%M:%S'),
                'tipo': row.tipo,
                'cantidad': row.cantidad,
                'producto': row.producto_nombre,
                'sku': row.sku,
                'talla': row.talla,
                'color': row.color,
                'referencia': row.referencia
            })
            
            if row.tipo == 'ENTRADA':
                total_entradas += row.cantidad
            elif row.tipo == 'SALIDA':
                total_salidas += row.cantidad
            elif row.tipo == 'AJUSTE':
                total_ajustes += row.cantidad
        
        return {
            'movimientos': movimientos,
            'resumen': {
                'total_movimientos': len(movimientos),
                'total_entradas': total_entradas,
                'total_salidas': total_salidas,
                'total_ajustes': total_ajustes
            },
            'periodo': {
                'desde': fecha_desde.isoformat() if fecha_desde else None,
                'hasta': fecha_hasta.isoformat() if fecha_hasta else None
            }
        }
    
    def reporte_general_mensual(self, mes: int, anio: int) -> dict:
        """
        Generar reporte general mensual con comparativa.
        
        Args:
            mes: Mes (1-12)
            anio: Año
            
        Returns:
            Reporte comparativo mensual
        """
        # Ventas del mes actual
        query_actual = """
            SELECT 
                COUNT(*) as total_ventas,
                COUNT(DISTINCT punto_venta_id) as puntos_venta_activos,
                SUM(CASE WHEN metodo_pago = 'EFECTIVO' THEN total ELSE 0 END) as total_efectivo,
                SUM(CASE WHEN metodo_pago = 'TARJETA' THEN total ELSE 0 END) as total_tarjeta,
                SUM(total) as total_general,
                AVG(total) as ticket_promedio
            FROM ventas
            WHERE EXTRACT(MONTH FROM creada_en) = :mes
            AND EXTRACT(YEAR FROM creada_en) = :anio
            AND estado = 'CERRADA'
        """
        
        # Ventas del mes anterior
        mes_anterior = mes - 1 if mes > 1 else 12
        anio_anterior = anio if mes > 1 else anio - 1
        
        query_anterior = query_actual.replace(':mes', ':mes_ant').replace(':anio', ':anio_ant')
        
        result_actual = self.db.execute(
            text(query_actual), 
            {'mes': mes, 'anio': anio}
        ).fetchone()
        
        result_anterior = self.db.execute(
            text(query_anterior),
            {'mes_ant': mes_anterior, 'anio_ant': anio_anterior}
        ).fetchone()
        
        # Productos más vendidos del mes
        query_productos = """
            SELECT 
                p.nombre,
                SUM(vd.cantidad) as cantidad_vendida,
                SUM(vd.subtotal) as total_vendido
            FROM venta_detalle vd
            JOIN ventas v ON vd.venta_id = v.id
            JOIN variantes_producto vp ON vd.variante_id = vp.id
            JOIN productos p ON vp.producto_id = p.id
            WHERE EXTRACT(MONTH FROM v.creada_en) = :mes
            AND EXTRACT(YEAR FROM v.creada_en) = :anio
            AND v.estado = 'CERRADA'
            GROUP BY p.nombre
            ORDER BY cantidad_vendida DESC
            LIMIT 10
        """
        
        result_productos = self.db.execute(
            text(query_productos),
            {'mes': mes, 'anio': anio}
        )
        
        productos_top = []
        for row in result_productos:
            productos_top.append({
                'nombre': row.nombre,
                'cantidad': row.cantidad_vendida,
                'total': float(row.total_vendido)
            })
        
        # Calcular variaciones
        def calcular_variacion(actual, anterior):
            if not anterior or anterior == 0:
                return 0
            return ((actual - anterior) / anterior) * 100
        
        ventas_actual = result_actual.total_ventas or 0
        ventas_anterior = result_anterior.total_ventas or 0
        total_actual = float(result_actual.total_general or 0)
        total_anterior = float(result_anterior.total_general or 0)
        
        return {
            'mes': mes,
            'anio': anio,
            'actual': {
                'total_ventas': ventas_actual,
                'puntos_venta_activos': result_actual.puntos_venta_activos or 0,
                'total_efectivo': float(result_actual.total_efectivo or 0),
                'total_tarjeta': float(result_actual.total_tarjeta or 0),
                'total_general': total_actual,
                'ticket_promedio': float(result_actual.ticket_promedio or 0)
            },
            'mes_anterior': {
                'total_ventas': ventas_anterior,
                'total_general': total_anterior
            },
            'comparativa': {
                'variacion_ventas': calcular_variacion(ventas_actual, ventas_anterior),
                'variacion_monto': calcular_variacion(total_actual, total_anterior)
            },
            'productos_top': productos_top
        }
    
    def exportar_ventas_csv(
        self,
        fecha_desde: date = None,
        fecha_hasta: date = None
    ) -> str:
        """
        Exportar reporte de ventas a CSV.
        
        Returns:
            String con contenido CSV
        """
        reporte = self.reporte_ventas(fecha_desde, fecha_hasta)
        
        output = io.StringIO()
        writer = csv.writer(output)
        
        # Header
        writer.writerow([
            'ID', 'Fecha', 'Punto Venta', 'Usuario', 
            'Método Pago', 'Estado', 'Subtotal', 'Descuento', 
            'Impuesto', 'Total', 'Facturado'
        ])
        
        # Datos
        for venta in reporte['ventas']:
            writer.writerow([
                venta['id'],
                venta['fecha'],
                venta['punto_venta'],
                venta['usuario'],
                venta['metodo_pago'],
                venta['estado'],
                venta['subtotal'],
                venta['descuento'],
                venta['impuesto'],
                venta['total'],
                'Sí' if venta['facturado'] else 'No'
            ])
        
        # Resumen
        writer.writerow([])
        writer.writerow(['RESUMEN'])
        writer.writerow(['Total Ventas', reporte['resumen']['total_ventas']])
        writer.writerow(['Total Efectivo', reporte['resumen']['total_efectivo']])
        writer.writerow(['Total Tarjeta', reporte['resumen']['total_tarjeta']])
        writer.writerow(['Total General', reporte['resumen']['total_general']])
        
        return output.getvalue()
    
    def exportar_almacen_csv(self, categoria: str = None) -> str:
        """
        Exportar reporte de almacén a CSV.
        
        Returns:
            String con contenido CSV
        """
        reporte = self.reporte_almacen(categoria)
        
        output = io.StringIO()
        writer = csv.writer(output)
        
        # Header
        writer.writerow([
            'Producto', 'Categoría', 'Marca', 'SKU', 
            'Talla', 'Color', 'Precio Menudeo', 'Precio Mayoreo', 
            'Stock Actual'
        ])
        
        # Datos
        for item in reporte['productos']:
            writer.writerow([
                item['producto_nombre'],
                item['categoria'],
                item['marca'],
                item['sku'],
                item['talla'],
                item['color'],
                item['precio_menudeo'],
                item['precio_mayoreo'],
                item['stock_actual']
            ])
        
        # Resumen
        writer.writerow([])
        writer.writerow(['RESUMEN'])
        writer.writerow(['Total Productos', reporte['resumen']['total_productos']])
        writer.writerow(['Total Variantes', reporte['resumen']['total_variantes']])
        writer.writerow(['Total Unidades', reporte['resumen']['total_unidades']])
        writer.writerow(['Valor Inventario', reporte['resumen']['valor_inventario']])
        
        return output.getvalue()
