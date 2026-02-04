from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.api.v1 import auth, ventas, pos, productos, inventario, reportes, cobranza, facturas, configuracion

# Crear aplicación FastAPI
app = FastAPI(
    title=settings.PROJECT_NAME,
    debug=settings.DEBUG,
    version="1.0.0",
    description="""
    Backend profesional para sistema POS/Almacén - YOMYOM
    
    ## Características
    
    * **Autenticación JWT** con roles (ADMIN, CAJERO, ALMACEN)
    * **Transacciones ACID** para operaciones de venta
    * **SELECT FOR UPDATE** para manejo de concurrencia
    * **Búsqueda por código de barras** optimizada para POS
    * **Control de inventario** con validación de stock
    * **Precios diferenciados** (menudeo/mayoreo)
    * **Facturación SAT** preparada
    
    ## Arquitectura
    
    * Clean Architecture (Repositories → Services → API)
    * SQLAlchemy 2.0 con PostgreSQL
    * Manejo profesional de errores
    * Alineado con almacen_db.sql
    """
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En producción, especificar orígenes permitidos
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Registrar routers (ALINEADO con openapi.yaml)
app.include_router(auth.router, prefix=settings.API_V1_PREFIX)
app.include_router(pos.router, prefix=settings.API_V1_PREFIX)
app.include_router(ventas.router, prefix=settings.API_V1_PREFIX)
app.include_router(productos.router, prefix=settings.API_V1_PREFIX)
app.include_router(inventario.router, prefix=settings.API_V1_PREFIX)
app.include_router(reportes.router, prefix=settings.API_V1_PREFIX)
app.include_router(cobranza.router, prefix=settings.API_V1_PREFIX)
app.include_router(facturas.router, prefix=settings.API_V1_PREFIX)
app.include_router(configuracion.router, prefix=settings.API_V1_PREFIX)


@app.get("/")
def root():
    """Endpoint raíz."""
    return {
        "message": "POS Backend API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health"
    }


@app.get("/health")
def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
