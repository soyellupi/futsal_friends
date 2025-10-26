"""Main API v1 router"""

from fastapi import APIRouter

api_router = APIRouter()


@api_router.get("/")
async def api_root():
    """API v1 root endpoint"""
    return {"message": "Futsal Friends API v1", "version": "1.0"}
