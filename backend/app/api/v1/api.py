"""API v1 router aggregator."""
from fastapi import APIRouter
from app.api.v1.endpoints.auth import router as auth_router
from app.api.v1.endpoints.categories import router as categories_router
from app.api.v1.endpoints.transactions import router as transactions_router
from app.api.v1.endpoints.dashboard import router as dashboard_router
from app.api.v1.endpoints.reports import router as reports_router
from app.api.v1.endpoints.groups import router as groups_router
from app.api.v1.endpoints.receipts import router as receipts_router
from app.api.v1.endpoints.voice import router as voice_router

api_router = APIRouter()
api_router.include_router(auth_router)
api_router.include_router(categories_router)
api_router.include_router(transactions_router)
api_router.include_router(dashboard_router)
api_router.include_router(reports_router)
api_router.include_router(groups_router)
api_router.include_router(receipts_router)
api_router.include_router(voice_router)
