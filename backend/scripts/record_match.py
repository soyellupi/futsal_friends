"""Script to record a complete match with all details"""

import asyncio
from datetime import datetime
from typing import List, Tuple
from uuid import UUID

from app.constants import RatingConfig
from app.models import (
    Match,
    MatchAttendance,
    MatchResult,
    MatchStatus,
    Player,
    ResultType,
    RSVPStatus,
    Season,
    TeamName,
    ThirdTimeAttendance,
)
from app.repositories import (
    MatchRepository,
    PlayerRepository,
    RatingRepository,
    ResultRepository,
    SeasonRepository,
    TeamRepository,
)
from app.services import LeaderboardService, RatingService
from scripts.utils import get_db_session, print_error, print_header, print_info, print_success


async def get_active_season(db) -> Season:
    """Get the active season"""
    season_repo = SeasonRepository(db)
    season = await season_repo.get_active_season()
    if not season:
        print_error("No active season found!")
        print_info("Run 'python scripts/seed_season.py' first")
        return None
    return season


async def get_season_players(db, season: Season) -> List[Tuple[Player, float]]:
    """Get all players in the season with their ratings"""
    player_repo = PlayerRepository(db)
    season_repo = SeasonRepository(db)

    players_with_ratings = await player_repo.get_players_with_season_rating(
        season.id, skip=0, limit=100
    )

    result = []
    for player, rating in players_with_ratings:
        current_rating = rating.current_rating if rating else RatingConfig.INITIAL_RATING
        result.append((player, current_rating))

    return result


async def select_attendees(players: List[Tuple[Player, float]]) -> List[UUID]:
    """Interactive selection of match attendees"""
    print_info("\nSelect players who attended the match:")
    print_info("(Enter player numbers separated by spaces, e.g., '1 2 3 5')")

    # Display players
    for i, (player, rating) in enumerate(players, 1):
        print(f"  {i}. {player.name} (Rating: {rating:.2f})")

    while True:
        selection = input("\nAttendees: ").strip()
        if not selection:
            print_error("Please select at least 2 players")
            continue

        try:
            indices = [int(x) - 1 for x in selection.split()]
            selected_players = [players[i][0].id for i in indices]

            if len(selected_players) < 2:
                print_error("Need at least 2 players")
                continue

            return selected_players
        except (ValueError, IndexError):
            print_error("Invalid selection. Try again.")


async def create_match_with_attendance(
    db, season: Season, attendee_ids: List[UUID]
) -> Tuple[Match, List[MatchAttendance]]:
    """Create match and mark attendance"""
    match_repo = MatchRepository(db)
    player_repo = PlayerRepository(db)
    season_repo = SeasonRepository(db)

    # Get match date
    match_date_str = input("\nMatch date (YYYY-MM-DD, default: today): ").strip()
    if match_date_str:
        match_date = datetime.fromisoformat(match_date_str)
    else:
        match_date = datetime.now()

    location = input("Location (optional): ").strip() or None

    # Create match
    match = Match(
        season_id=season.id,
        match_date=match_date,
        status=MatchStatus.COMPLETED,
        location=location,
    )
    match = await match_repo.create(match)
    print_success(f"Created match (ID: {match.id})")

    # Get all season players
    all_players_with_ratings = await player_repo.get_players_with_season_rating(
        season.id
    )
    all_player_ids = [p[0].id for p in all_players_with_ratings]

    # Create attendance records for ALL season players
    attendances = []
    for player_id in all_player_ids:
        attended = player_id in attendee_ids

        attendance = MatchAttendance(
            match_id=match.id,
            player_id=player_id,
            rsvp_status=RSVPStatus.CONFIRMED if attended else RSVPStatus.DECLINED,
            rsvp_at=match_date if attended else None,
            attended=attended,
        )
        attendance = await match_repo.create_attendance(attendance)
        attendances.append(attendance)

    print_success(f"Recorded attendance for {len(all_player_ids)} players")
    print_info(f"  Attended: {len(attendee_ids)}")
    print_info(f"  Absent: {len(all_player_ids) - len(attendee_ids)}")

    return match, attendances


async def create_teams(
    db, match: Match, season: Season, attendee_ids: List[UUID]
):
    """Create teams with manual player selection"""
    team_repo = TeamRepository(db)
    season_repo = SeasonRepository(db)
    player_repo = PlayerRepository(db)

    # Get attendees with ratings
    attendees_with_ratings = []
    for player_id in attendee_ids:
        player = await player_repo.get_by_id(player_id)
        season_rating = await season_repo.get_player_season_rating(
            player.id, season.id
        )
        rating = season_rating.current_rating if season_rating else RatingConfig.INITIAL_RATING
        attendees_with_ratings.append((player, rating))

    print_info("\nSelect players for Team Black:")
    print_info("(Enter player numbers separated by spaces, e.g., '1 2 3 4')")

    # Display attendees
    for i, (player, rating) in enumerate(attendees_with_ratings, 1):
        print(f"  {i}. {player.name} (Rating: {rating:.2f})")

    while True:
        selection = input("\nTeam Black: ").strip()
        if not selection:
            print_error("Please select at least 1 player")
            continue

        try:
            indices = [int(x) - 1 for x in selection.split()]
            team_black_ids = [attendees_with_ratings[i][0].id for i in indices]

            if len(team_black_ids) < 1:
                print_error("Need at least 1 player")
                continue

            if len(team_black_ids) >= len(attendee_ids):
                print_error("Team Black cannot have all players")
                continue

            # Team Pink gets remaining players
            team_pink_ids = [pid for pid in attendee_ids if pid not in team_black_ids]

            break
        except (ValueError, IndexError):
            print_error("Invalid selection. Try again.")

    # Create Team Black
    from app.models import Team, TeamPlayer
    team_a = Team(
        match_id=match.id,
        name=TeamName.TEAM_A,
    )
    team_a = await team_repo.create(team_a)

    # Add players to Team Black
    team_a_ratings = []
    for player_id in team_black_ids:
        team_player = TeamPlayer(
            team_id=team_a.id,
            player_id=player_id,
        )
        await team_repo.add_player_to_team(team_player)

        # Get rating for average calculation
        season_rating = await season_repo.get_player_season_rating(player_id, season.id)
        rating = season_rating.current_rating if season_rating else RatingConfig.INITIAL_RATING
        team_a_ratings.append(rating)

    # Calculate and update Team Black average
    team_a.average_skill_rating = sum(team_a_ratings) / len(team_a_ratings) if team_a_ratings else None
    await db.flush()

    # Create Team Pink
    team_b = Team(
        match_id=match.id,
        name=TeamName.TEAM_B,
    )
    team_b = await team_repo.create(team_b)

    # Add players to Team Pink
    team_b_ratings = []
    for player_id in team_pink_ids:
        team_player = TeamPlayer(
            team_id=team_b.id,
            player_id=player_id,
        )
        await team_repo.add_player_to_team(team_player)

        # Get rating for average calculation
        season_rating = await season_repo.get_player_season_rating(player_id, season.id)
        rating = season_rating.current_rating if season_rating else RatingConfig.INITIAL_RATING
        team_b_ratings.append(rating)

    # Calculate and update Team Pink average
    team_b.average_skill_rating = sum(team_b_ratings) / len(team_b_ratings) if team_b_ratings else None
    await db.flush()

    # Display teams
    print_success(f"\nTeam Black (avg: {team_a.average_skill_rating:.2f}):")
    for player_id in team_black_ids:
        player = await player_repo.get_by_id(player_id)
        season_rating = await season_repo.get_player_season_rating(player.id, season.id)
        rating = season_rating.current_rating if season_rating else RatingConfig.INITIAL_RATING
        print(f"    - {player.name} ({rating:.2f})")

    print_success(f"\nTeam Pink (avg: {team_b.average_skill_rating:.2f}):")
    for player_id in team_pink_ids:
        player = await player_repo.get_by_id(player_id)
        season_rating = await season_repo.get_player_season_rating(player.id, season.id)
        rating = season_rating.current_rating if season_rating else RatingConfig.INITIAL_RATING
        print(f"    - {player.name} ({rating:.2f})")

    return team_a, team_b


async def record_result(db, match: Match, team_a, team_b) -> MatchResult:
    """Record match result"""
    result_repo = ResultRepository(db)

    print_info("\nEnter match result:")
    team_a_score = int(input("  Team Black score: "))
    team_b_score = int(input("  Team Pink score: "))

    # Determine winner
    if team_a_score > team_b_score:
        winning_team_id = team_a.id
        result_type = ResultType.WIN
    elif team_b_score > team_a_score:
        winning_team_id = team_b.id
        result_type = ResultType.WIN
    else:
        winning_team_id = None
        result_type = ResultType.DRAW

    result = MatchResult(
        match_id=match.id,
        team_a_id=team_a.id,
        team_b_id=team_b.id,
        team_a_score=team_a_score,
        team_b_score=team_b_score,
        winning_team_id=winning_team_id,
        result_type=result_type,
        recorded_at=datetime.now(),
    )
    result = await result_repo.create(result)

    if result_type == ResultType.DRAW:
        print_success(f"Match ended in draw: {team_a_score}-{team_b_score}")
    else:
        winner_name = "Black" if winning_team_id == team_a.id else "Pink"
        print_success(
            f"Team {winner_name} won: {team_a_score}-{team_b_score}"
        )

    return result


async def record_third_time(
    db, match: Match, players: List[Tuple[Player, float]]
) -> List[ThirdTimeAttendance]:
    """Record third time attendance"""
    match_repo = MatchRepository(db)

    print_info("\nWho attended third time (post-match social)?")
    print_info("(Enter player numbers separated by spaces, or press Enter to skip)")

    # Display players
    for i, (player, rating) in enumerate(players, 1):
        print(f"  {i}. {player.name}")

    selection = input("\nThird time attendees: ").strip()
    if not selection:
        print_info("No third time attendance recorded")
        return []

    try:
        indices = [int(x) - 1 for x in selection.split()]
        selected_player_ids = [players[i][0].id for i in indices]
    except (ValueError, IndexError):
        print_error("Invalid selection. Skipping third time.")
        return []

    # Create third time attendance records
    third_times = []
    for player_id in selected_player_ids:
        third_time = ThirdTimeAttendance(
            match_id=match.id,
            player_id=player_id,
            attended=True,
        )
        third_time = await match_repo.create_third_time_attendance(third_time)
        third_times.append(third_time)

    print_success(f"Recorded third time attendance for {len(third_times)} players")

    return third_times


async def calculate_ratings(db, match: Match, season: Season):
    """Calculate and update ratings"""
    rating_repo = RatingRepository(db)
    season_repo = SeasonRepository(db)
    team_repo = TeamRepository(db)
    player_repo = PlayerRepository(db)
    match_repo = MatchRepository(db)

    # Get teams
    teams = await team_repo.get_match_teams(match.id)
    team_a, team_b = teams[0], teams[1]

    # Load match with all relationships
    match = await match_repo.get_match_with_details(match.id)

    # Get all season players
    players_with_ratings = await player_repo.get_players_with_season_rating(season.id)
    season_players = [p[0] for p in players_with_ratings]

    print_info(f"\nCalculating ratings for {len(season_players)} players...")

    # Calculate ratings
    rating_service = RatingService(db, rating_repo, season_repo, team_repo)
    ratings = await rating_service.calculate_match_ratings(
        match, team_a, team_b, season_players
    )

    print_success(f"Updated ratings for all players")

    # Show rating changes
    print_info("\nRating changes:")
    for rating in ratings:
        if rating.rating_change != 0:
            player = await player_repo.get_by_id(rating.player_id)
            change_str = f"+{rating.rating_change:.2f}" if rating.rating_change > 0 else f"{rating.rating_change:.2f}"
            print(
                f"  {player.name}: {rating.rating_before:.2f} → {rating.rating_after:.2f} ({change_str})"
            )


async def show_leaderboard(db, season: Season):
    """Display current leaderboard"""
    season_repo = SeasonRepository(db)
    leaderboard_service = LeaderboardService(db, season_repo)

    print_header("Current Leaderboard")

    leaderboard = await leaderboard_service.calculate_season_leaderboard(season.id)

    # Display leaderboard
    print(f"{'Rank':<6} {'Player':<20} {'Points':<8} {'Rating':<8} {'W/D/L':<10} {'Attendance':<12}")
    print("-" * 70)

    for i, stats in enumerate(leaderboard, 1):
        record = f"{stats.wins}/{stats.draws}/{stats.losses}"
        attendance = f"{stats.matches_attended}/{stats.matches_completed}"
        print(
            f"{i:<6} {stats.player_name:<20} {stats.total_points:<8} "
            f"{stats.current_rating:<8.2f} {record:<10} {attendance:<12}"
        )


async def main():
    """Main function"""
    print_header("Record Match")

    async with get_db_session() as db:
        # Get active season
        season = await get_active_season(db)
        if not season:
            return

        print_info(f"Active season: {season.name} ({season.year})")

        # Get season players
        players = await get_season_players(db, season)
        if not players:
            print_error("No players in season!")
            return

        print_info(f"Season has {len(players)} players")

        # Select attendees
        attendee_ids = await select_attendees(players)

        # Create match and record attendance
        match, attendances = await create_match_with_attendance(
            db, season, attendee_ids
        )

        # Create teams
        team_a, team_b = await create_teams(db, match, season, attendee_ids)

        # Record result
        result = await record_result(db, match, team_a, team_b)

        # Record third time
        third_times = await record_third_time(db, match, players)

        # Calculate ratings
        await calculate_ratings(db, match, season)

        # Show leaderboard
        await show_leaderboard(db, season)

        print_header("Match Recorded Successfully!")
        print_info(f"Match ID: {match.id}")
        print_info(f"Date: {match.match_date}")
        print_info(f"Score: {result.team_a_score}-{result.team_b_score}")


if __name__ == "__main__":
    asyncio.run(main())
