"""Season endpoints"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.repositories.season import SeasonRepository
from app.schemas.season import SeasonResponse

router = APIRouter()


@router.get("/current", response_model=SeasonResponse)
async def get_current_season(
    db: AsyncSession = Depends(get_db),
):
    """Get the currently active season"""
    season_repo = SeasonRepository(db)
    season = await season_repo.get_active_season()

    if not season:
        raise HTTPException(status_code=404, detail="No active season found")

    return season
