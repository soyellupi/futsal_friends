"""Leaderboard endpoints"""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Match, MatchStatus
from app.repositories.season import SeasonRepository
from app.schemas.leaderboard import LeaderboardEntry, LeaderboardWithRanking
from app.services.leaderboard_service import LeaderboardService

router = APIRouter()


@router.get("/{season_id}", response_model=LeaderboardWithRanking)
async def get_season_leaderboard(
    season_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """Get the leaderboard for a specific season"""
    season_repo = SeasonRepository(db)

    # Check if season exists
    season = await season_repo.get_by_id(season_id)
    if not season:
        raise HTTPException(status_code=404, detail="Season not found")

    # Calculate leaderboard
    leaderboard_service = LeaderboardService(db, season_repo)
    player_stats = await leaderboard_service.calculate_season_leaderboard(season_id)

    # Add rankings
    entries = [
        LeaderboardEntry(rank=idx + 1, player_stats=stats)
        for idx, stats in enumerate(player_stats)
    ]

    # Count total completed matches in the season
    result = await db.execute(
        select(func.count(Match.id)).where(
            Match.season_id == season_id,
            Match.status == MatchStatus.COMPLETED
        )
    )
    total_matches = result.scalar() or 0

    return LeaderboardWithRanking(
        season_id=season.id,
        season_name=season.name,
        season_year=season.year,
        entries=entries,
        total_matches=total_matches,
    )
