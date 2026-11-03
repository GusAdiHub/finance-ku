"""API v1 endpoints package."""
from app.api.v1.endpoints.auth import router as auth_router
from app.api.v1.endpoints.categories import router as categories_router
from app.api.v1.endpoints.transactions import router as transactions_router
from app.api.v1.endpoints.dashboard import router as dashboard_router
from app.api.v1.endpoints.reports import router as reports_router
from app.api.v1.endpoints.groups import router as groups_router
from app.api.v1.endpoints.receipts import router as receipts_router
from app.api.v1.endpoints.voice import router as voice_router

__all__ = [
    "auth_router",
    "categories_router",
    "transactions_router",
    "dashboard_router",
    "reports_router",
    "groups_router",
    "receipts_router",
    "voice_router",
]
