#!/usr/bin/env python3
"""
Script to recalculate ratings for a specific match.
This will delete existing rating records for the match and recalculate them.
"""

import asyncio
import sys
from pathlib import Path
from typing import List, Optional

# Add parent directory to path to import app modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.database import AsyncSessionLocal
from app.models import Match, Player, PlayerMatchRating, PlayerSeasonRating, Season
from app.models.player import PlayerType
from app.repositories import RatingRepository, SeasonRepository, TeamRepository
from app.services.rating_service import RatingService
from scripts.utils import print_error, print_header, print_info, print_success


async def get_match_by_week(db: AsyncSession, match_week: int) -> Optional[Match]:
    """Get match by week number"""
    result = await db.execute(
        select(Match)
        .where(Match.match_week == match_week)
        .options(
            joinedload(Match.teams),
            joinedload(Match.result),
            joinedload(Match.third_time_attendances),
        )
    )
    return result.unique().scalar_one_or_none()


async def get_season_players(db: AsyncSession, season_id) -> List[Player]:
    """Get all players in the season (those with season ratings)"""
    result = await db.execute(
        select(Player)
        .join(PlayerSeasonRating)
        .where(PlayerSeasonRating.season_id == season_id)
        .order_by(Player.name)
    )
    players = list(result.scalars().all())

    # If no players found with season ratings, get regular players
    if not players:
        from app.models.player import PlayerType
        result = await db.execute(
            select(Player)
            .where(Player.player_type == PlayerType.REGULAR, Player.is_active == True)
            .order_by(Player.name)
        )
        players = list(result.scalars().all())

    return players


async def delete_match_ratings(db: AsyncSession, match_id) -> int:
    """Delete all rating records for a match"""
    result = await db.execute(
        select(PlayerMatchRating).where(PlayerMatchRating.match_id == match_id)
    )
    ratings = result.scalars().all()
    count = len(ratings)

    for rating in ratings:
        await db.delete(rating)

    await db.flush()
    return count


async def reset_season_ratings(db: AsyncSession, season_id, match_week: int):
    """
    Reset season ratings to recalculate from the beginning.
    This finds all matches from the specified week onwards and recalculates.
    """
    # Get all season ratings
    result = await db.execute(
        select(PlayerSeasonRating)
        .where(PlayerSeasonRating.season_id == season_id)
    )
    season_ratings = list(result.scalars().all())

    # Get all matches up to (but not including) the specified week
    result = await db.execute(
        select(Match)
        .where(Match.season_id == season_id, Match.match_week < match_week)
        .order_by(Match.match_week)
    )
    previous_matches = list(result.scalars().all())

    # Reset each player's season rating based on matches before the specified week
    for season_rating in season_ratings:
        player_id = season_rating.player_id

        # Count matches completed and attended before this week
        result = await db.execute(
            select(PlayerMatchRating)
            .where(
                PlayerMatchRating.player_id == player_id,
                PlayerMatchRating.season_id == season_id,
                PlayerMatchRating.match_number < match_week,
            )
            .order_by(PlayerMatchRating.match_number.desc())
        )
        previous_ratings = list(result.scalars().all())

        if not previous_ratings:
            # No previous matches, reset to initial state
            season_rating.current_rating = 3.0
            season_rating.matches_completed = 0
            season_rating.matches_attended = 0
            season_rating.rating_locked = True
        else:
            # Get the rating from the last match before this week
            last_rating = previous_ratings[0]
            season_rating.current_rating = last_rating.rating_after
            season_rating.matches_completed = last_rating.match_number

            # Count attended matches
            attended_count = sum(
                1 for r in previous_ratings if r.attended_match
            )
            season_rating.matches_attended = attended_count

            # Check if rating should be locked
            season_rating.rating_locked = season_rating.matches_completed < 3

    await db.flush()
    print_success(f"Reset season ratings for {len(season_ratings)} players")


async def recalculate_match_ratings(match_week: int):
    """Recalculate ratings for a specific match"""

    print_header(f"Recalculate Ratings for Match Week {match_week}")

    async with AsyncSessionLocal() as db:
        # Get the match
        match = await get_match_by_week(db, match_week)

        if not match:
            print_error(f"No match found for week {match_week}")
            return

        print_success(f"Found match: Week {match.match_week} - {match.match_date}")
        print_info(f"Match ID: {match.id}")
        print_info(f"Status: {match.status.value}")

        # Check if match has a result
        if not match.result:
            print_error("Match has no result. Cannot calculate ratings.")
            return

        # Check if match has teams
        if len(match.teams) != 2:
            print_error(f"Expected 2 teams, found {len(match.teams)}")
            return

        team_a = match.teams[0]
        team_b = match.teams[1]

        print_info(f"Team A: {team_a.name.value} (avg rating: {team_a.average_skill_rating:.2f})")
        print_info(f"Team B: {team_b.name.value} (avg rating: {team_b.average_skill_rating:.2f})")
        print_info(f"Result: {match.result.team_a_score} - {match.result.team_b_score}")

        # Get season players
        season_players = await get_season_players(db, match.season_id)
        print_info(f"\nFound {len(season_players)} players in season")

        # Confirm deletion
        print_info("\n" + "=" * 80)
        confirm = input(f"Delete existing ratings and recalculate for match week {match_week}? (yes/no): ").strip().lower()

        if confirm != 'yes':
            print_error("Cancelled.")
            return

        # Delete existing ratings for this match
        print_info("\nDeleting existing ratings...")
        deleted_count = await delete_match_ratings(db, match.id)
        print_success(f"Deleted {deleted_count} rating records")

        # Reset season ratings to state before this match
        print_info("\nResetting season ratings to state before this match...")
        await reset_season_ratings(db, match.season_id, match_week)

        # Recalculate ratings
        print_info("\nRecalculating ratings...")

        # Initialize repositories and service
        rating_repo = RatingRepository(db)
        season_repo = SeasonRepository(db)
        team_repo = TeamRepository(db)
        rating_service = RatingService(db, rating_repo, season_repo, team_repo)

        # Calculate new ratings
        new_ratings = await rating_service.calculate_match_ratings(
            match, team_a, team_b, season_players
        )

        print_success(f"\n✓ Calculated {len(new_ratings)} new rating records")

        # Show some examples
        print_header("Sample Rating Changes")
        for rating in new_ratings[:5]:
            player = next(p for p in season_players if p.id == rating.player_id)
            print_info(
                f"{player.name}: "
                f"{rating.rating_before:.2f} → {rating.rating_after:.2f} "
                f"(change: {rating.rating_change:+.3f}, "
                f"attended: {rating.attended_match})"
            )

        if len(new_ratings) > 5:
            print_info(f"... and {len(new_ratings) - 5} more")

        # Commit changes
        await db.commit()

        print_success("\n" + "=" * 80)
        print_success("✓ Ratings recalculated successfully!")
        print_success("=" * 80)


async def main():
    """Main function"""
    if len(sys.argv) < 2:
        print_error("Usage: python3 recalculate_match_ratings.py <match_week>")
        print_info("Example: python3 recalculate_match_ratings.py 1")
        sys.exit(1)

    try:
        match_week = int(sys.argv[1])
        if match_week < 1:
            print_error("Match week must be a positive number")
            sys.exit(1)
    except ValueError:
        print_error("Match week must be a valid number")
        sys.exit(1)

    await recalculate_match_ratings(match_week)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print_error("\n\nScript interrupted by user.")
        sys.exit(0)
