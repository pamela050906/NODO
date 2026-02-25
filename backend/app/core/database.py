from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session, DeclarativeBase
from typing import Generator
from app.core.config import settings

# Usar driver psycopg (v3) si la URL es postgresql:// (evita depender de psycopg2 en Windows/Python 3.13)
_db_url = settings.DATABASE_URL
if _db_url.startswith("postgresql://") and "+" not in _db_url.split("://")[0]:
    _db_url = _db_url.replace("postgresql://", "postgresql+psycopg://", 1)

# Motor de base de datos
engine = create_engine(
    _db_url,
    echo=settings.DEBUG,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20
)

# Session factory
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


# Base declarativa para modelos
class Base(DeclarativeBase):
    pass


def get_db() -> Generator[Session, None, None]:
    """
    Dependency para obtener sesión de base de datos.
    Se usa en endpoints FastAPI.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
