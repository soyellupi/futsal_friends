"""Match endpoints"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.database import get_db
from app.models import Player, PlayerMatchRating, Team, TeamPlayer, ThirdTimeAttendance
from app.repositories.match import MatchRepository
from app.schemas.match import (
    MatchDetailResponse,
    MatchPlayerDetail,
    MatchTeamDetail,
    ThirdTimeAttendee,
)

router = APIRouter()


@router.get("/{year}/matches/{match_week}", response_model=MatchDetailResponse)
async def get_match_details(
    year: int,
    match_week: int,
    db: AsyncSession = Depends(get_db),
):
    """Get complete match details by season year and match week"""
    match_repo = MatchRepository(db)

    # Get match by season year and match week
    match = await match_repo.get_by_season_year_and_week(year, match_week)
    if not match:
        raise HTTPException(
            status_code=404,
            detail=f"Match not found for year {year} week {match_week}"
        )

    # Get teams with players eagerly loaded
    teams_result = await db.execute(
        select(Team)
        .where(Team.match_id == match.id)
        .options(
            joinedload(Team.players).joinedload(TeamPlayer.player)
        )
    )
    teams = list(teams_result.scalars().unique().all())

    # Get player match ratings for this match
    ratings_result = await db.execute(
        select(PlayerMatchRating)
        .where(PlayerMatchRating.match_id == match.id)
    )
    ratings = list(ratings_result.scalars().all())
    rating_map = {rating.player_id: rating.rating_before for rating in ratings}

    # Get third-time attendees
    third_time_result = await db.execute(
        select(ThirdTimeAttendance)
        .where(
            ThirdTimeAttendance.match_id == match.id,
            ThirdTimeAttendance.attended == True
        )
        .options(joinedload(ThirdTimeAttendance.player))
    )
    third_time_attendances = list(third_time_result.scalars().unique().all())

    # Build team details
    team_details = []
    for team in teams:
        # Get score from match result if available
        score = None
        if match.result:
            if team.id == match.result.team_a_id:
                score = match.result.team_a_score
            elif team.id == match.result.team_b_id:
                score = match.result.team_b_score

        # Build player details
        player_details = []
        for team_player in team.players:
            player_rating = rating_map.get(team_player.player_id)
            player_details.append(
                MatchPlayerDetail(
                    id=team_player.player_id,
                    name=team_player.player.name,
                    rating=player_rating,
                )
            )

        team_details.append(
            MatchTeamDetail(
                id=team.id,
                name=team.name,
                score=score,
                players=player_details,
                average_rating=team.average_skill_rating,
            )
        )

    # Build third-time attendee list
    third_time_attendees = [
        ThirdTimeAttendee(
            id=attendance.player.id,
            name=attendance.player.name,
        )
        for attendance in third_time_attendances
    ]

    # Build response
    return MatchDetailResponse(
        id=match.id,
        season_id=match.season_id,
        match_date=match.match_date,
        status=match.status,
        rsvp_deadline=match.rsvp_deadline,
        location=match.location,
        notes=match.notes,
        created_at=match.created_at,
        updated_at=match.updated_at,
        teams=team_details,
        third_time_attendees=third_time_attendees,
    )
