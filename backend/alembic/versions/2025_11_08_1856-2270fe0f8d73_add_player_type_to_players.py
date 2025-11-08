"""add_player_type_to_players

Revision ID: 2270fe0f8d73
Revises: 6058a914c2b8
Create Date: 2025-11-08 18:56:16.549673

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '2270fe0f8d73'
down_revision: Union[str, None] = '6058a914c2b8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create ENUM type for player_type
    player_type_enum = sa.Enum('regular', 'invited', name='playertype')
    player_type_enum.create(op.get_bind())

    # Add player_type column (nullable initially to allow data migration)
    op.add_column('players',
        sa.Column('player_type', player_type_enum, nullable=True)
    )

    # Set all existing players to 'regular'
    op.execute("UPDATE players SET player_type = 'regular' WHERE player_type IS NULL")

    # Make player_type non-nullable with default 'regular'
    op.alter_column('players', 'player_type', nullable=False, server_default='regular')


def downgrade() -> None:
    # Remove the column
    op.drop_column('players', 'player_type')

    # Drop the ENUM type
    player_type_enum = sa.Enum('regular', 'invited', name='playertype')
    player_type_enum.drop(op.get_bind())
