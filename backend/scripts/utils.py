"""Utility functions for management scripts"""

from contextlib import asynccontextmanager
from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal


@asynccontextmanager
async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    """
    Get a database session for scripts.

    Usage:
        async with get_db_session() as db:
            # Use db here
            pass
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception as e:
            await session.rollback()
            print(f"Error: {e}")
            raise
        finally:
            await session.close()


def print_success(message: str) -> None:
    """Print success message in green"""
    print(f"\033[92m✓ {message}\033[0m")


def print_error(message: str) -> None:
    """Print error message in red"""
    print(f"\033[91m✗ {message}\033[0m")


def print_info(message: str) -> None:
    """Print info message in blue"""
    print(f"\033[94mℹ {message}\033[0m")


def print_header(message: str) -> None:
    """Print header message"""
    print(f"\n{'=' * 60}")
    print(f"  {message}")
    print(f"{'=' * 60}\n")
