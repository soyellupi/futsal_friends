#!/usr/bin/env python3
"""
Script to record third time attendance.
Prompts for match week and player names who attended the third time.
"""

import asyncio
import sys
from pathlib import Path

# Add parent directory to path to import app modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import select
from app.models import Match, Player, ThirdTimeAttendance
from app.models.player import PlayerType
from datetime import datetime
from scripts.utils import get_db_session, print_success, print_info, print_error, print_header


async def record_third_time_attendance():
    """Record third time attendance by prompting for match week and player names"""

    print_header("Record Third Time Attendance")

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

        # Get all regular active players
        result = await db.execute(
            select(Player)
            .where(Player.player_type == PlayerType.REGULAR, Player.is_active == True)
            .order_by(Player.name)
        )
        regular_players = list(result.scalars().all())

        if not regular_players:
            print_error("No regular players found")
            return

        # Display regular players
        print_info(f"\nRegular Active Players ({len(regular_players)}):")
        for i, player in enumerate(regular_players, 1):
            print(f"  {i}. {player.name}")

        # Get player names who attended third time
        print_info("\nEnter the names of players who attended third time (separated by comma):")
        player_names_input = input("Player names: ").strip()

        if not player_names_input:
            print_error("No players entered. Cancelled.")
            return

        # Parse player names
        player_names = [name.strip() for name in player_names_input.split(",")]
        player_names = [name for name in player_names if name]  # Remove empty strings

        if not player_names:
            print_error("No valid player names entered. Cancelled.")
            return

        # Create a map of player names to player objects
        player_map = {player.name.lower(): player for player in regular_players}

        # Process each player
        created_count = 0
        skipped_count = 0
        not_found_count = 0

        print_info(f"\nProcessing {len(player_names)} player(s)...")

        for player_name in player_names:
            player_name_lower = player_name.lower()

            # Try to find the player (case-insensitive)
            player = player_map.get(player_name_lower)

            if not player:
                # Try partial match
                matching_players = [
                    p for p_name, p in player_map.items()
                    if player_name_lower in p_name or p_name in player_name_lower
                ]
                if len(matching_players) == 1:
                    player = matching_players[0]
                    print_info(f"  Matched '{player_name}' to '{player.name}'")
                else:
                    print_error(f"  Player not found: {player_name}")
                    not_found_count += 1
                    continue

            # Check if record already exists
            existing = await db.execute(
                select(ThirdTimeAttendance).where(
                    ThirdTimeAttendance.match_id == match.id,
                    ThirdTimeAttendance.player_id == player.id
                )
            )
            if existing.scalar_one_or_none():
                print_info(f"  Already recorded: {player.name}")
                skipped_count += 1
                continue

            # Create third time attendance record
            third_time = ThirdTimeAttendance(
                match_id=match.id,
                player_id=player.id,
                attended=True,
                created_at=datetime.utcnow()
            )
            db.add(third_time)
            print_success(f"  Created: {player.name}")
            created_count += 1

        print_header("Summary")
        print_info(f"Match Week: {match_week}")
        print_info(f"Created: {created_count} record(s)")
        print_info(f"Skipped (already exists): {skipped_count} record(s)")
        if not_found_count > 0:
            print_error(f"Not found: {not_found_count} player(s)")

        if created_count > 0:
            print_success("\nThird time attendance recorded successfully!")


if __name__ == "__main__":
    asyncio.run(record_third_time_attendance())
