"""Script to create a new season with initial players"""

import asyncio
from datetime import date
from uuid import UUID

from app.constants import RatingConfig
from app.models import Player, PlayerSeasonRating, Season
from app.repositories import PlayerRepository, SeasonRepository
from scripts.utils import get_db_session, print_error, print_header, print_info, print_success


async def create_season(
    name: str, year: int, start_date: date
) -> tuple[Season, list[Player]]:
    """
    Create a new season and add initial players.

    Args:
        name: Season name (e.g., "2025 Season")
        year: Season year
        start_date: Season start date

    Returns:
        Tuple of (created_season, list_of_players)
    """
    async with get_db_session() as db:
        season_repo = SeasonRepository(db)
        player_repo = PlayerRepository(db)

        # Check if season already exists
        existing_season = await season_repo.get_active_season()
        if existing_season:
            print_error(
                f"Active season already exists: {existing_season.name} ({existing_season.year})"
            )
            print_info("Deactivate it first or use a different year")
            return None, []

        # Create season
        season = Season(
            name=name,
            year=year,
            start_date=start_date,
            is_active=True,
        )
        season = await season_repo.create(season)
        print_success(f"Created season: {season.name} (ID: {season.id})")

        # Get player names
        print_info("\nEnter player names (press Enter with empty name to finish):")
        players = []
        player_number = 1

        while True:
            player_name = input(f"  Player {player_number}: ").strip()
            if not player_name:
                break

            # Check if player exists
            existing_player = await player_repo.get_by_name(player_name)
            if existing_player:
                print_info(f"    Using existing player: {existing_player.name}")
                player = existing_player
            else:
                # Create new player
                player = Player(name=player_name)
                player = await player_repo.create(player)
                print_success(f"    Created player: {player.name}")

            players.append(player)
            player_number += 1

        if not players:
            print_error("No players added!")
            return season, []

        # Initialize player season ratings
        print_info(f"\nInitializing ratings for {len(players)} players...")
        for player in players:
            # Check if rating already exists
            existing_rating = await season_repo.get_player_season_rating(
                player.id, season.id
            )
            if not existing_rating:
                rating = PlayerSeasonRating(
                    player_id=player.id,
                    season_id=season.id,
                    current_rating=RatingConfig.INITIAL_RATING,
                    matches_completed=0,
                    matches_attended=0,
                    rating_locked=True,
                )
                await season_repo.create_player_season_rating(rating)

        print_success(f"Initialized ratings for all players at {RatingConfig.INITIAL_RATING}")

        return season, players


async def main():
    """Main function"""
    print_header("Create New Season")

    # Get season details
    print_info("Enter season details:")
    year = int(input("  Year (e.g., 2025): "))
    name = input(f"  Season name (default: '{year} Season'): ").strip()
    if not name:
        name = f"{year} Season"

    start_date_str = input("  Start date (YYYY-MM-DD, default: today): ").strip()
    if start_date_str:
        start_date = date.fromisoformat(start_date_str)
    else:
        start_date = date.today()

    # Create season
    season, players = await create_season(name, year, start_date)

    if season and players:
        print_header("Season Created Successfully!")
        print_info(f"Season ID: {season.id}")
        print_info(f"Season Name: {season.name}")
        print_info(f"Year: {season.year}")
        print_info(f"Start Date: {season.start_date}")
        print_info(f"Players: {len(players)}")
        print_info("\nPlayers:")
        for i, player in enumerate(players, 1):
            print(f"  {i}. {player.name} (ID: {player.id})")


if __name__ == "__main__":
    asyncio.run(main())
