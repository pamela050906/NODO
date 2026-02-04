from pydantic import BaseModel


class TicketResponse(BaseModel):
    """Response para ticket generado."""
    ticket_html: str
    ticket_texto: str
    qr_base64: str | None
    venta_id: int
    
    class Config:
        json_schema_extra = {
            "example": {
                "ticket_html": "<html>...</html>",
                "ticket_texto": "=== TICKET ===\n...",
                "qr_base64": "iVBORw0KGgo...",
                "venta_id": 1
            }
        }
