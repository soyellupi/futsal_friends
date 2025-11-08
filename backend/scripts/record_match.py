#!/usr/bin/env python3
"""
Script to create a match and assign players to teams.
This creates the match structure but does not record the result.
"""

import asyncio
import sys
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Tuple

# Add parent directory to path to import app modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal
from app.models import Match, MatchStatus, Player, Season, Team, TeamPlayer
from app.models.player import PlayerType
from app.models.team import TeamName
from app.repositories import (
    MatchRepository,
    PlayerRepository,
    SeasonRepository,
    TeamRepository,
)
from app.constants import RatingConfig


def print_info(message: str):
    """Print info message in blue"""
    print(f"\033[94m{message}\033[0m")


def print_success(message: str):
    """Print success message in green"""
    print(f"\033[92m{message}\033[0m")


def print_error(message: str):
    """Print error message in red"""
    print(f"\033[91m{message}\033[0m")


def print_warning(message: str):
    """Print warning message in yellow"""
    print(f"\033[93m{message}\033[0m")


def print_header(message: str):
    """Print header"""
    print_info("=" * 80)
    print_info(message)
    print_info("=" * 80)


async def get_active_season(db: AsyncSession) -> Optional[Season]:
    """Get the active season"""
    season_repo = SeasonRepository(db)
    season = await season_repo.get_active_season()
    if not season:
        print_error("No active season found!")
        return None
    return season


async def get_regular_players(db: AsyncSession) -> List[Player]:
    """Get all regular (non-invited) players"""
    result = await db.execute(
        select(Player)
        .where(Player.player_type == PlayerType.REGULAR, Player.is_active == True)
        .order_by(Player.name)
    )
    return list(result.scalars().all())


async def get_invited_players(db: AsyncSession) -> List[Player]:
    """Get all invited players"""
    result = await db.execute(
        select(Player)
        .where(Player.player_type == PlayerType.INVITED)
        .order_by(Player.name)
    )
    return list(result.scalars().all())


async def create_invited_player(db: AsyncSession, name: str) -> Player:
    """Create a new invited player"""
    player = Player(
        name=name,
        player_type=PlayerType.INVITED,
        is_active=True
    )
    db.add(player)
    await db.flush()
    await db.refresh(player)
    return player


def find_player_by_name(players: List[Player], name_input: str) -> Optional[Player]:
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
        print_warning(f"Multiple players match '{name_input}':")
        for p in matches:
            print(f"  - {p.name}")
        print_warning("Please be more specific.")
        return None

    return None


async def prompt_create_match(
    db: AsyncSession,
    season: Season,
    match_repo: MatchRepository
) -> Match:
    """Prompt user to create a match"""
    print_header("Create Match")

    # Get next match week
    result = await db.execute(
        select(Match)
        .where(Match.season_id == season.id)
        .order_by(Match.match_week.desc())
    )
    last_match = result.scalars().first()
    next_week = (last_match.match_week + 1) if last_match else 1

    print_info(f"\nSeason: {season.year} - {season.name}")
    print_info(f"Next match week: {next_week}")

    # Get match date
    while True:
        date_str = input("\nMatch date (YYYY-MM-DD HH:MM) or press Enter for today: ").strip()
        if date_str == "":
            match_date = datetime.now()
            break
        try:
            match_date = datetime.strptime(date_str, "%Y-%m-%d %H:%M")
            break
        except ValueError:
            print_error("Invalid date format. Use YYYY-MM-DD HH:MM")

    # Create match
    match = Match(
        season_id=season.id,
        match_week=next_week,
        match_date=match_date,
        status=MatchStatus.SCHEDULED,
    )
    match = await match_repo.create(match)

    print_success(f"\n✓ Match created: Week {next_week} on {match_date.strftime('%Y-%m-%d %H:%M')}")
    return match


async def prompt_select_regular_players(
    db: AsyncSession,
    regular_players: List[Player]
) -> List[Player]:
    """Prompt user to select regular players"""
    print_header("Select Regular Players")

    print_info("\nAvailable regular players:")
    for player in regular_players:
        print(f"  - {player.name}")

    print_info("\nEnter player names one at a time (press Enter when done)")

    selected_players = []

    while True:
        player_name = input("\nPlayer name (or press Enter to finish): ").strip()

        if player_name == "":
            break

        player = find_player_by_name(regular_players, player_name)

        if not player:
            print_error(f"Player '{player_name}' not found. Try again.")
            continue

        if player in selected_players:
            print_warning(f"{player.name} already selected.")
            continue

        selected_players.append(player)
        print_success(f"✓ Added {player.name}")

    print_success(f"\nTotal regular players selected: {len(selected_players)}")
    return selected_players


async def prompt_select_invited_players(
    db: AsyncSession,
    invited_players: List[Player]
) -> List[Player]:
    """Prompt user to select or create invited players"""
    print_header("Select Invited Players")

    if invited_players:
        print_info("\nExisting invited players:")
        for player in invited_players:
            print(f"  - {player.name}")
    else:
        print_info("\nNo existing invited players.")

    print_info("\nEnter player names to add (create new if they don't exist)")
    print_info("Press Enter without typing a name to finish")

    selected_players = []
    all_invited = list(invited_players)  # Copy to track new ones

    while True:
        player_name = input("\nInvited player name (or press Enter to finish): ").strip()

        if player_name == "":
            break

        # Try to find existing invited player
        player = find_player_by_name(all_invited, player_name)

        if not player:
            # Create new invited player
            confirm = input(f"Player '{player_name}' doesn't exist. Create as invited? (y/n): ").strip().lower()
            if confirm == 'y':
                player = await create_invited_player(db, player_name)
                all_invited.append(player)
                print_success(f"✓ Created invited player: {player.name}")
            else:
                continue

        if player in selected_players:
            print_warning(f"{player.name} already selected.")
            continue

        selected_players.append(player)
        print_success(f"✓ Added {player.name}")

    print_success(f"\nTotal invited players selected: {len(selected_players)}")
    return selected_players


async def prompt_select_goalkeepers(
    all_players: List[Player]
) -> List[Player]:
    """Prompt user to select goalkeepers from all players"""
    print_header("Select Goalkeepers")

    print_info("\nAll players:")
    for i, player in enumerate(all_players, 1):
        player_type = " (invited)" if player.player_type == PlayerType.INVITED else ""
        print(f"  {i}. {player.name}{player_type}")

    print_info("\nEnter names of goalkeepers (can select multiple)")
    print_info("Press Enter without typing a name to finish")

    goalkeepers = []

    while True:
        gk_name = input("\nGoalkeeper name (or press Enter to finish): ").strip()

        if gk_name == "":
            break

        player = find_player_by_name(all_players, gk_name)

        if not player:
            print_error(f"Player '{gk_name}' not found. Try again.")
            continue

        if player in goalkeepers:
            print_warning(f"{player.name} already selected as goalkeeper.")
            continue

        goalkeepers.append(player)
        print_success(f"✓ {player.name} marked as goalkeeper")

    print_success(f"\nTotal goalkeepers: {len(goalkeepers)}")
    return goalkeepers


def balance_teams_auto(
    all_players: List[Player],
    goalkeepers: List[Player],
    player_ratings: dict
) -> Tuple[List[Player], List[Player]]:
    """
    Automatically create balanced teams.

    Rules:
    - One goalkeeper per team if possible
    - Equal number of players (±1)
    - If odd players and 1 GK, team with GK has more players
    - Balanced by rating
    """
    num_players = len(all_players)
    num_goalkeepers = len(goalkeepers)

    # Sort players by rating (excluding goalkeepers first)
    non_gk_players = [p for p in all_players if p not in goalkeepers]
    non_gk_players.sort(key=lambda p: player_ratings.get(p.id, 3.0), reverse=True)

    team_a = []
    team_b = []

    # Assign goalkeepers
    if num_goalkeepers >= 2:
        # Assign one GK to each team (take first two)
        team_a.append(goalkeepers[0])
        team_b.append(goalkeepers[1])
    elif num_goalkeepers == 1:
        # Assign the only GK to team A
        team_a.append(goalkeepers[0])

    # Calculate how many players each team should have
    team_a_target = num_players // 2
    team_b_target = num_players - team_a_target

    # If odd number and only 1 GK, team with GK gets more players
    if num_players % 2 == 1 and num_goalkeepers == 1:
        team_a_target = (num_players // 2) + 1
        team_b_target = num_players // 2

    # Snake draft for non-GK players
    for i, player in enumerate(non_gk_players):
        if len(team_a) < team_a_target and len(team_b) < team_b_target:
            # Both teams need players, assign to team with lower total rating
            team_a_rating = sum(player_ratings.get(p.id, 3.0) for p in team_a)
            team_b_rating = sum(player_ratings.get(p.id, 3.0) for p in team_b)

            if team_a_rating <= team_b_rating:
                team_a.append(player)
            else:
                team_b.append(player)
        elif len(team_a) < team_a_target:
            team_a.append(player)
        else:
            team_b.append(player)

    return team_a, team_b


async def prompt_create_teams_manual(
    all_players: List[Player],
    goalkeepers: List[Player]
) -> Tuple[List[Player], List[Player]]:
    """Prompt user to manually create teams"""
    print_header("Create Teams Manually")

    team_black = []
    team_pink = []

    print_info("\nAvailable players:")
    for player in all_players:
        gk_marker = " [GK]" if player in goalkeepers else ""
        player_type = " (invited)" if player.player_type == PlayerType.INVITED else ""
        print(f"  - {player.name}{gk_marker}{player_type}")

    # Team Black
    print_success("\n" + "-" * 40)
    print_success("Team Black")
    print_success("-" * 40)

    available_players = list(all_players)

    print_info("Enter player names for Team Black (press Enter when done)")
    while True:
        player_name = input("\nPlayer name (or press Enter to finish): ").strip()

        if player_name == "":
            break

        player = find_player_by_name(available_players, player_name)

        if not player:
            print_error(f"Player '{player_name}' not found or already assigned. Try again.")
            continue

        team_black.append(player)
        available_players.remove(player)

        gk_marker = " [GK]" if player in goalkeepers else ""
        print_success(f"✓ Added {player.name}{gk_marker} to Team Black")

    # Assign remaining to Team Pink
    team_pink = available_players

    print_success("\n" + "-" * 40)
    print_success("Team Pink (remaining players)")
    print_success("-" * 40)
    for player in team_pink:
        gk_marker = " [GK]" if player in goalkeepers else ""
        print(f"  - {player.name}{gk_marker}")

    return team_black, team_pink


async def create_teams_in_db(
    db: AsyncSession,
    match: Match,
    team_black_players: List[Player],
    team_pink_players: List[Player],
    goalkeepers: List[Player],
    player_ratings: dict,
    team_repo: TeamRepository,
    season_repo: SeasonRepository
) -> Tuple[Team, Team]:
    """Create teams in database"""
    print_info("\nCreating teams in database...")

    # Calculate average ratings
    team_black_avg = sum(player_ratings.get(p.id, 3.0) for p in team_black_players) / len(team_black_players) if team_black_players else 0.0
    team_pink_avg = sum(player_ratings.get(p.id, 3.0) for p in team_pink_players) / len(team_pink_players) if team_pink_players else 0.0

    # Create Team Black
    team_black = Team(
        match_id=match.id,
        name=TeamName.TEAM_A,
        average_skill_rating=team_black_avg,
    )
    team_black = await team_repo.create(team_black)

    # Add players to Team Black
    for player in team_black_players:
        position = 'goalkeeper' if player in goalkeepers else None
        team_player = TeamPlayer(
            team_id=team_black.id,
            player_id=player.id,
            position=position,
        )
        await team_repo.add_player_to_team(team_player)

    # Create Team Pink
    team_pink = Team(
        match_id=match.id,
        name=TeamName.TEAM_B,
        average_skill_rating=team_pink_avg,
    )
    team_pink = await team_repo.create(team_pink)

    # Add players to Team Pink
    for player in team_pink_players:
        position = 'goalkeeper' if player in goalkeepers else None
        team_player = TeamPlayer(
            team_id=team_pink.id,
            player_id=player.id,
            position=position,
        )
        await team_repo.add_player_to_team(team_player)

    print_success("✓ Teams created in database")

    return team_black, team_pink


def display_teams(
    team_black_players: List[Player],
    team_pink_players: List[Player],
    goalkeepers: List[Player],
    player_ratings: dict
):
    """Display final teams"""
    print_header("Final Teams")

    # Team Black
    print_success(f"\nTeam Black ({len(team_black_players)} players):")
    black_avg = sum(player_ratings.get(p.id, 3.0) for p in team_black_players) / len(team_black_players) if team_black_players else 0.0
    print_info(f"Average rating: {black_avg:.2f}")
    for player in team_black_players:
        rating = player_ratings.get(player.id, 3.0)
        gk_marker = " [GK]" if player in goalkeepers else ""
        player_type = " (invited)" if player.player_type == PlayerType.INVITED else ""
        print(f"  - {player.name} ({rating:.2f}){gk_marker}{player_type}")

    # Team Pink
    print_success(f"\nTeam Pink ({len(team_pink_players)} players):")
    pink_avg = sum(player_ratings.get(p.id, 3.0) for p in team_pink_players) / len(team_pink_players) if team_pink_players else 0.0
    print_info(f"Average rating: {pink_avg:.2f}")
    for player in team_pink_players:
        rating = player_ratings.get(player.id, 3.0)
        gk_marker = " [GK]" if player in goalkeepers else ""
        player_type = " (invited)" if player.player_type == PlayerType.INVITED else ""
        print(f"  - {player.name} ({rating:.2f}){gk_marker}{player_type}")


async def get_player_ratings(
    db: AsyncSession,
    season: Season,
    players: List[Player],
    season_repo: SeasonRepository
) -> dict:
    """Get ratings for all players"""
    ratings = {}
    for player in players:
        season_rating = await season_repo.get_player_season_rating(player.id, season.id)
        ratings[player.id] = season_rating.current_rating if season_rating else 3.0
    return ratings


async def main():
    """Main function"""
    print_header("Record Match - Create Match and Teams")

    async with AsyncSessionLocal() as db:
        # Get active season
        season = await get_active_season(db)
        if not season:
            return

        # Initialize repositories
        match_repo = MatchRepository(db)
        player_repo = PlayerRepository(db)
        season_repo = SeasonRepository(db)
        team_repo = TeamRepository(db)

        # Step 1: Create match
        match = await prompt_create_match(db, season, match_repo)

        # Step 2: Get available players
        regular_players = await get_regular_players(db)
        invited_players = await get_invited_players(db)

        # Step 3: Select regular players
        selected_regular = await prompt_select_regular_players(db, regular_players)

        if not selected_regular:
            print_error("No regular players selected. Cancelling...")
            await db.rollback()
            return

        # Step 4: Select invited players
        selected_invited = await prompt_select_invited_players(db, invited_players)

        # All selected players
        all_players = selected_regular + selected_invited

        print_success(f"\nTotal players: {len(all_players)}")

        # Step 5: Select goalkeepers
        goalkeepers = await prompt_select_goalkeepers(all_players)

        # Get player ratings
        player_ratings = await get_player_ratings(db, season, all_players, season_repo)

        # Step 6: Create teams (manual or automatic)
        print_header("Create Teams")
        print_info("How would you like to create teams?")
        print_info("1. Automatic (balanced by rating)")
        print_info("2. Manual (you assign players)")

        while True:
            choice = input("\nEnter choice (1 or 2): ").strip()
            if choice in ['1', '2']:
                break
            print_error("Invalid choice. Enter 1 or 2.")

        if choice == '1':
            # Automatic team creation
            print_info("\nCreating balanced teams...")
            team_black_players, team_pink_players = balance_teams_auto(
                all_players,
                goalkeepers,
                player_ratings
            )
        else:
            # Manual team creation
            team_black_players, team_pink_players = await prompt_create_teams_manual(
                all_players,
                goalkeepers
            )

        # Display teams
        display_teams(team_black_players, team_pink_players, goalkeepers, player_ratings)

        # Confirm
        print_info("\n" + "=" * 80)
        confirm = input("Create these teams? (y/n): ").strip().lower()

        if confirm != 'y':
            print_warning("Cancelled. No changes made.")
            await db.rollback()
            return

        # Create teams in database
        team_black, team_pink = await create_teams_in_db(
            db,
            match,
            team_black_players,
            team_pink_players,
            goalkeepers,
            player_ratings,
            team_repo,
            season_repo
        )

        # Commit
        await db.commit()

        print_success("\n" + "=" * 80)
        print_success("✓ Match and teams created successfully!")
        print_success("=" * 80)
        print_info(f"\nMatch ID: {match.id}")
        print_info(f"Match Week: {match.match_week}")
        print_info(f"Date: {match.match_date.strftime('%Y-%m-%d %H:%M')}")
        print_info(f"Team Black: {len(team_black_players)} players")
        print_info(f"Team Pink: {len(team_pink_players)} players")
        print_info("\nTo record the match result, use: python3 scripts/record_result.py")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print_warning("\n\nScript interrupted by user.")
        sys.exit(0)
