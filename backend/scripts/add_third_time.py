"""Script to add a third time attendance record"""

import asyncio
import sys
from pathlib import Path
from uuid import UUID

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from app.models import ThirdTimeAttendance
from app.repositories import MatchRepository
from scripts.utils import get_db_session


async def add_third_time_attendance(
    match_id: str,
    player_id: str,
    attended: bool = True
):
    """Add third time attendance for a player"""

    async with get_db_session() as db:
        match_repo = MatchRepository(db)

        # Create third time attendance
        third_time = ThirdTimeAttendance(
            match_id=UUID(match_id),
            player_id=UUID(player_id),
            attended=attended,
        )

        third_time = await match_repo.create_third_time_attendance(third_time)
        await db.commit()

        print(f"✓ Created third time attendance:")
        print(f"  ID: {third_time.id}")
        print(f"  Match ID: {third_time.match_id}")
        print(f"  Player ID: {third_time.player_id}")
        print(f"  Attended: {third_time.attended}")
        print(f"  Created at: {third_time.created_at}")


async def main():
    """Main function"""
    # Your specific values
    match_id = "6514c434-5c57-4efc-b9f9-710aa9fe061e"
    player_id = "d3373e62-c862-48ad-9db6-4cf353621f7e"

    try:
        await add_third_time_attendance(match_id, player_id, attended=True)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
