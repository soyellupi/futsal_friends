"""Leaderboard endpoints"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Match, MatchStatus
from app.repositories.season import SeasonRepository
from app.schemas.leaderboard import LeaderboardEntry, LeaderboardWithRanking
from app.services.leaderboard_service import LeaderboardService

router = APIRouter()


@router.get("/{year}/leaderboard", response_model=LeaderboardWithRanking)
async def get_season_leaderboard(
    year: int,
    db: AsyncSession = Depends(get_db),
):
    """Get the leaderboard for a specific season year"""
    season_repo = SeasonRepository(db)

    # Get seasons for the specified year
    seasons = await season_repo.get_by_year(year)
    if not seasons:
        raise HTTPException(status_code=404, detail=f"No season found for year {year}")

    # Use the first season (ordered by start_date)
    season = seasons[0]

    # Calculate leaderboard
    leaderboard_service = LeaderboardService(db, season_repo)
    player_stats = await leaderboard_service.calculate_season_leaderboard(season.id)

    # Add rankings
    entries = [
        LeaderboardEntry(rank=idx + 1, player_stats=stats)
        for idx, stats in enumerate(player_stats)
    ]

    # Count total completed matches in the season
    result = await db.execute(
        select(func.count(Match.id)).where(
            Match.season_id == season.id,
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
