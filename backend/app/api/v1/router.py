"""Main API v1 router"""

from fastapi import APIRouter

from app.api.v1.endpoints import leaderboard, seasons

api_router = APIRouter()


@api_router.get("/")
async def api_root():
    """API v1 root endpoint"""
    return {"message": "Futsal Friends API v1", "version": "1.0"}


# Include endpoint routers
api_router.include_router(seasons.router, prefix="/seasons", tags=["seasons"])
api_router.include_router(leaderboard.router, prefix="/leaderboard", tags=["leaderboard"])
