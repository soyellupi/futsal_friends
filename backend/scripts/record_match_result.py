#!/usr/bin/env python3
"""
Script to record match results.
Prompts for match week number and scores for both teams.
"""

import asyncio
import sys
from pathlib import Path

# Add parent directory to path to import app modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import select
from app.models import Match, Team, MatchResult
from app.models.team import TeamName
from app.models.result import ResultType
from datetime import datetime
from scripts.utils import get_db_session, print_success, print_info, print_error, print_header


async def record_match_result():
    """Record a match result by prompting for match week and scores"""

    print_header("Record Match Result")

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

    async with get_db_session() as db:
        # Find the match
        result = await db.execute(
            select(Match).where(Match.match_week == match_week)
        )
        match = result.scalar_one_or_none()

        if not match:
            print_error(f"No match found for week {match_week}")
            return

        print_success(f"Found match: Week {match.match_week} - {match.match_date}")

        # Check if result already exists
        existing_result = await db.execute(
            select(MatchResult).where(MatchResult.match_id == match.id)
        )
        if existing_result.scalar_one_or_none():
            print_error(f"Result already exists for match week {match_week}")
            overwrite = input("Do you want to overwrite it? (yes/no): ").strip().lower()
            if overwrite != 'yes':
                print_info("Cancelled.")
                return
            # Delete existing result
            await db.execute(
                select(MatchResult).where(MatchResult.match_id == match.id)
            )
            existing = existing_result.scalar_one()
            await db.delete(existing)
            await db.flush()

        # Find the teams
        teams_result = await db.execute(
            select(Team).where(Team.match_id == match.id)
        )
        teams = list(teams_result.scalars().all())

        if len(teams) != 2:
            print_error(f"Expected 2 teams for this match, found {len(teams)}")
            return

        # Identify black and pink teams
        black_team = next((t for t in teams if t.name == TeamName.TEAM_A), None)
        pink_team = next((t for t in teams if t.name == TeamName.TEAM_B), None)

        if not black_team or not pink_team:
            print_error("Could not find both black and pink teams")
            return

        print_info(f"\nBlack team ID: {black_team.id}")
        print_info(f"Pink team ID: {pink_team.id}")

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
            print_info(f"\nResult: BLACK wins {black_score}-{pink_score}")
        elif pink_score > black_score:
            result_type = ResultType.WIN
            winning_team_id = pink_team.id
            print_info(f"\nResult: PINK wins {pink_score}-{black_score}")
        else:
            result_type = ResultType.DRAW
            winning_team_id = None
            print_info(f"\nResult: DRAW {black_score}-{pink_score}")

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

        print_header("Summary")
        print_info(f"Match Week: {match_week}")
        print_info(f"Black team score: {black_score}")
        print_info(f"Pink team score: {pink_score}")
        print_info(f"Result type: {result_type.value}")
        if winning_team_id:
            winner_name = "BLACK" if winning_team_id == black_team.id else "PINK"
            print_success(f"Winner: {winner_name}")
        else:
            print_success("Result: DRAW")

        print_success("\nMatch result recorded successfully!")


if __name__ == "__main__":
    asyncio.run(record_match_result())
