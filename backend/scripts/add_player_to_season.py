"""Script to add a player to a season with initial rating"""

import asyncio
import sys
from pathlib import Path
from uuid import UUID

# Add the backend directory to the path so we can import from app
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.constants import RatingConfig
from app.models import Player, PlayerSeasonRating, PlayerType
from app.repositories import PlayerRepository, SeasonRepository
from scripts.utils import get_db_session, print_error, print_header, print_info, print_success


async def add_player_to_season(
    player_name: str, season_id: UUID, player_type: PlayerType = PlayerType.REGULAR
) -> tuple[Player, PlayerSeasonRating]:
    """
    Add a player to a season with initial rating.

    Args:
        player_name: Name of the player to add
        season_id: UUID of the season to add the player to
        player_type: Type of player (REGULAR or INVITED), defaults to REGULAR

    Returns:
        Tuple of (player, player_season_rating)
    """
    async with get_db_session() as db:
        season_repo = SeasonRepository(db)
        player_repo = PlayerRepository(db)

        # Verify season exists
        season = await season_repo.get_by_id(season_id)
        if not season:
            print_error(f"Season with ID {season_id} not found")
            return None, None

        print_info(f"Season: {season.name} ({season.year})")

        # Check if player exists
        existing_player = await player_repo.get_by_name(player_name)
        if existing_player:
            print_info(f"Using existing player: {existing_player.name} (Type: {existing_player.player_type.value})")
            player = existing_player

            # Update player type if different
            if player.player_type != player_type:
                print_info(f"Updating player type from {player.player_type.value} to {player_type.value}")
                player.player_type = player_type
                player = await player_repo.update(player)
                print_success(f"Updated player type to {player_type.value}")
        else:
            # Create new player
            player = Player(name=player_name, player_type=player_type)
            player = await player_repo.create(player)
            print_success(f"Created new player: {player.name} (Type: {player_type.value})")

        # Check if player is already in the season
        existing_rating = await season_repo.get_player_season_rating(
            player.id, season.id
        )
        if existing_rating:
            print_error(
                f"Player {player.name} is already in season {season.name}"
            )
            print_info(f"Current rating: {existing_rating.current_rating}")
            print_info(f"Matches completed: {existing_rating.matches_completed}")
            print_info(f"Matches attended: {existing_rating.matches_attended}")
            print_info(f"Rating locked: {existing_rating.rating_locked}")
            return player, existing_rating

        # Create player season rating with initial values
        rating = PlayerSeasonRating(
            player_id=player.id,
            season_id=season.id,
            current_rating=RatingConfig.INITIAL_RATING,
            matches_completed=0,
            matches_attended=0,
            rating_locked=True,
        )
        rating = await season_repo.create_player_season_rating(rating)

        print_success(f"Added {player.name} to season {season.name}")
        print_info(f"Initial rating: {rating.current_rating}")
        print_info(f"Matches completed: {rating.matches_completed}")
        print_info(f"Matches attended: {rating.matches_attended}")
        print_info(f"Rating locked: {rating.rating_locked}")

        return player, rating


async def main():
    """Main function"""
    print_header("Add Player to Season")

    async with get_db_session() as db:
        season_repo = SeasonRepository(db)

        # Get active season
        active_season = await season_repo.get_active_season()
        if not active_season:
            print_error("No active season found")
            print_info("Please create a season first using seed_season.py")
            return

        # Show active season info
        print_info(f"Active season: {active_season.name} ({active_season.year})")
        use_active = input("  Use this season? (Y/n): ").strip().lower()

        if use_active in ["n", "no"]:
            season_id_str = input("  Enter season ID: ").strip()
            try:
                season_id = UUID(season_id_str)
            except ValueError:
                print_error("Invalid UUID format")
                return
        else:
            season_id = active_season.id

    # Get player details
    print_info("\nEnter player details:")
    player_name = input("  Player name: ").strip()
    if not player_name:
        print_error("Player name is required")
        return

    # Get player type
    print_info("\nSelect player type:")
    print("  1. Regular (subject to attendance penalties)")
    print("  2. Invited (no attendance penalties)")
    player_type_choice = input("  Choice (1/2, default: 1): ").strip()

    if player_type_choice == "2":
        player_type = PlayerType.INVITED
    else:
        player_type = PlayerType.REGULAR

    # Add player to season
    player, rating = await add_player_to_season(player_name, season_id, player_type)

    if player and rating:
        print_header("Player Added Successfully!")
        print_info(f"Player ID: {player.id}")
        print_info(f"Player Name: {player.name}")
        print_info(f"Player Type: {player.player_type.value}")
        print_info(f"Season ID: {rating.season_id}")
        print_info(f"Initial Rating: {rating.current_rating}")
        print_info(f"Rating Locked: {rating.rating_locked}")


if __name__ == "__main__":
    asyncio.run(main())
