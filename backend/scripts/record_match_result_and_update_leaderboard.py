#!/usr/bin/env python3
"""
Script to record match results, third time attendance, and update leaderboard.

This script:
1. Records the match result (scores)
2. Records third time attendance
3. Calculates player match ratings
4. Updates player season ratings (leaderboard)
"""

import asyncio
import sys
from pathlib import Path
from datetime import datetime

# Add parent directory to path to import app modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import select
from sqlalchemy.orm import joinedload

from app.database import AsyncSessionLocal
from app.models import Match, Team, MatchResult, Player, PlayerSeasonRating, ThirdTimeAttendance
from app.models.match import MatchStatus
from app.models.team import TeamName
from app.models.result import ResultType
from app.models.player import PlayerType
from app.repositories import RatingRepository, SeasonRepository, TeamRepository
from app.services.rating_service import RatingService
from scripts.utils import print_success, print_info, print_error, print_header


def find_player_by_name(players: list, name_input: str):
    """Find a player by name (case-insensitive, partial match)"""
    name_lower = name_input.lower().strip()

    # Try exact match first
    for player in players:
        if player.name.lower() == name_lower:
            return player

    # Try partial match
    matches = [p for p in players if name_lower in p.name.lower()]

    if len(matches) == 1:
        return matches[0]
    elif len(matches) > 1:
        print_error(f"Multiple players match '{name_input}':")
        for p in matches:
            print(f"  - {p.name}")
        return None

    return None


async def record_match_result_and_update_leaderboard():
    """Record match result, third time, and update ratings"""

    print_header("Record Match Result and Update Leaderboard")

    # Get match week number
    while True:
        try:
            match_week_input = input("Enter match week number: ").strip()
            match_week = int(match_week_input)
            if match_week < 1:
                print_error("Match week must be a positive number")
                continue
            break
        except ValueError:
            print_error("Please enter a valid number")

    async with AsyncSessionLocal() as db:
        # Find the match with relationships
        result = await db.execute(
            select(Match)
            .where(Match.match_week == match_week)
            .options(
                joinedload(Match.teams),
                joinedload(Match.result),
                joinedload(Match.third_time_attendances),
            )
        )
        match = result.unique().scalar_one_or_none()

        if not match:
            print_error(f"No match found for week {match_week}")
            return

        # Check if unplayable
        if match.status == MatchStatus.UNPLAYABLE:
            print_error(f"Match week {match_week} is marked as UNPLAYABLE.")
            print_info("Use record_third_time_attendance.py to record third time for unplayable matches.")
            return

        print_success(f"Found match: Week {match.match_week} - {match.match_date}")
        print_info(f"Status: {match.status.value}")

        # Check if match has teams
        if len(match.teams) != 2:
            print_error(f"Expected 2 teams for this match, found {len(match.teams)}")
            return

        # Identify teams
        black_team = next((t for t in match.teams if t.name == TeamName.TEAM_A), None)
        pink_team = next((t for t in match.teams if t.name == TeamName.TEAM_B), None)

        if not black_team or not pink_team:
            print_error("Could not find both black and pink teams")
            return

        # ============================================================
        # STEP 1: Record match result
        # ============================================================
        print_header("Step 1: Match Result")

        # Check if result already exists
        if match.result:
            print_info(f"Result already exists: BLACK {match.result.team_a_score} - {match.result.team_b_score} PINK")
            overwrite = input("Do you want to overwrite it? (yes/no): ").strip().lower()
            if overwrite != 'yes':
                print_info("Keeping existing result.")
            else:
                await db.delete(match.result)
                await db.flush()
                match.result = None

        if not match.result:
            # Get scores
            while True:
                try:
                    black_score_input = input("\nEnter BLACK team score: ").strip()
                    black_score = int(black_score_input)
                    if black_score < 0:
                        print_error("Score must be non-negative")
                        continue
                    break
                except ValueError:
                    print_error("Please enter a valid number")

            while True:
                try:
                    pink_score_input = input("Enter PINK team score: ").strip()
                    pink_score = int(pink_score_input)
                    if pink_score < 0:
                        print_error("Score must be non-negative")
                        continue
                    break
                except ValueError:
                    print_error("Please enter a valid number")

            # Determine result
            if black_score > pink_score:
                result_type = ResultType.WIN
                winning_team_id = black_team.id
                print_success(f"Result: BLACK wins {black_score}-{pink_score}")
            elif pink_score > black_score:
                result_type = ResultType.WIN
                winning_team_id = pink_team.id
                print_success(f"Result: PINK wins {pink_score}-{black_score}")
            else:
                result_type = ResultType.DRAW
                winning_team_id = None
                print_success(f"Result: DRAW {black_score}-{pink_score}")

            # Create the match result
            match_result = MatchResult(
                match_id=match.id,
                team_a_id=black_team.id,
                team_b_id=pink_team.id,
                team_a_score=black_score,
                team_b_score=pink_score,
                winning_team_id=winning_team_id,
                result_type=result_type,
                recorded_at=datetime.utcnow(),
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            db.add(match_result)
            await db.flush()

            # Reload match to get the result
            await db.refresh(match)

        # ============================================================
        # STEP 2: Record third time attendance
        # ============================================================
        print_header("Step 2: Third Time Attendance")

        # Get all regular active players
        players_result = await db.execute(
            select(Player)
            .where(Player.player_type == PlayerType.REGULAR, Player.is_active == True)
            .order_by(Player.name)
        )
        regular_players = list(players_result.scalars().all())

        # Show existing third time attendees
        existing_third_time = list(match.third_time_attendances)
        if existing_third_time:
            print_info(f"\nExisting third time attendees ({len(existing_third_time)}):")
            for tta in existing_third_time:
                player = await db.get(Player, tta.player_id)
                if player:
                    print(f"  - {player.name}")

            modify = input("\nModify third time attendance? (yes/no): ").strip().lower()
            if modify != 'yes':
                print_info("Keeping existing third time attendance.")
            else:
                # Delete existing
                for tta in existing_third_time:
                    await db.delete(tta)
                await db.flush()
                existing_third_time = []

        if not existing_third_time:
            print_info(f"\nRegular players ({len(regular_players)}):")
            for i, player in enumerate(regular_players, 1):
                print(f"  {i}. {player.name}")

            print_info("\nEnter names of players who attended third time (comma-separated):")
            print_info("Press Enter to skip if no one attended.")
            third_time_input = input("Third time attendees: ").strip()

            if third_time_input:
                player_names = [name.strip() for name in third_time_input.split(",")]
                player_names = [name for name in player_names if name]

                created_count = 0
                for player_name in player_names:
                    player = find_player_by_name(regular_players, player_name)
                    if not player:
                        print_error(f"  Player not found: {player_name}")
                        continue

                    third_time = ThirdTimeAttendance(
                        match_id=match.id,
                        player_id=player.id,
                        attended=True,
                        created_at=datetime.utcnow()
                    )
                    db.add(third_time)
                    print_success(f"  ✓ {player.name}")
                    created_count += 1

                await db.flush()
                print_success(f"\nRecorded {created_count} third time attendees")
            else:
                print_info("No third time attendance recorded.")

        # Reload match to get updated third time attendances
        result = await db.execute(
            select(Match)
            .where(Match.id == match.id)
            .options(
                joinedload(Match.teams),
                joinedload(Match.result),
                joinedload(Match.third_time_attendances),
            )
        )
        match = result.unique().scalar_one()

        # ============================================================
        # STEP 3: Calculate ratings and update leaderboard
        # ============================================================
        print_header("Step 3: Calculate Ratings")

        # Get all season players
        season_ratings_result = await db.execute(
            select(Player)
            .join(PlayerSeasonRating)
            .where(PlayerSeasonRating.season_id == match.season_id)
            .order_by(Player.name)
        )
        season_players = list(season_ratings_result.scalars().all())

        if not season_players:
            # Fallback: get regular active players
            result = await db.execute(
                select(Player)
                .where(Player.player_type == PlayerType.REGULAR, Player.is_active == True)
                .order_by(Player.name)
            )
            season_players = list(result.scalars().all())

        print_info(f"Found {len(season_players)} players in season")

        # Initialize services
        rating_repo = RatingRepository(db)
        season_repo = SeasonRepository(db)
        team_repo = TeamRepository(db)
        rating_service = RatingService(db, rating_repo, season_repo, team_repo)

        # Calculate ratings
        print_info("Calculating ratings...")

        try:
            new_ratings = await rating_service.calculate_match_ratings(
                match, black_team, pink_team, season_players
            )
            print_success(f"✓ Calculated ratings for {len(new_ratings)} players")

            # Show sample rating changes
            print_info("\nRating changes (sample):")
            for rating in new_ratings[:5]:
                player = next((p for p in season_players if p.id == rating.player_id), None)
                if player:
                    status = "attended" if rating.attended_match else "absent"
                    print_info(
                        f"  {player.name}: {rating.rating_before:.2f} → {rating.rating_after:.2f} "
                        f"({rating.rating_change:+.3f}) [{status}]"
                    )

            if len(new_ratings) > 5:
                print_info(f"  ... and {len(new_ratings) - 5} more")

        except Exception as e:
            print_error(f"Error calculating ratings: {e}")
            await db.rollback()
            return

        # Update match status to COMPLETED
        match.status = MatchStatus.COMPLETED

        # Commit all changes
        await db.commit()

        # ============================================================
        # Summary
        # ============================================================
        print_header("Summary")
        print_success(f"Match Week: {match_week}")
        print_success(f"Result: BLACK {match.result.team_a_score} - {match.result.team_b_score} PINK")
        print_success(f"Status: COMPLETED")
        print_success(f"Ratings calculated for {len(new_ratings)} players")
        print_success("\n✓ Leaderboard updated successfully!")


if __name__ == "__main__":
    try:
        asyncio.run(record_match_result_and_update_leaderboard())
    except KeyboardInterrupt:
        print_error("\n\nScript interrupted by user.")
        sys.exit(0)
