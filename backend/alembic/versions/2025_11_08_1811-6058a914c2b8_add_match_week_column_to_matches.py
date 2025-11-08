"""add_match_week_column_to_matches

Revision ID: 6058a914c2b8
Revises: 0a8702210b54
Create Date: 2025-11-08 18:11:20.202517

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '6058a914c2b8'
down_revision: Union[str, None] = '0a8702210b54'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add match_week column (nullable initially to allow data migration)
    op.add_column('matches',
        sa.Column('match_week', sa.Integer(), nullable=True)
    )

    # Populate existing matches with sequential match_week per season
    # Assigns match_week based on match_date order within each season
    op.execute("""
        UPDATE matches
        SET match_week = subquery.row_num
        FROM (
            SELECT id,
                   ROW_NUMBER() OVER (PARTITION BY season_id ORDER BY match_date) as row_num
            FROM matches
        ) AS subquery
        WHERE matches.id = subquery.id
    """)

    # Make match_week non-nullable now that data is populated
    op.alter_column('matches', 'match_week', nullable=False)

    # Add unique constraint: one match_week per season
    op.create_unique_constraint(
        'uq_season_match_week',
        'matches',
        ['season_id', 'match_week']
    )

    # Add index for efficient queries
    op.create_index(
        op.f('ix_matches_match_week'),
        'matches',
        ['match_week'],
        unique=False
    )

    # Add check constraint: match_week must be positive
    op.create_check_constraint(
        'ck_match_week_positive',
        'matches',
        'match_week > 0'
    )


def downgrade() -> None:
    # Remove constraints and column in reverse order
    op.drop_constraint('ck_match_week_positive', 'matches', type_='check')
    op.drop_index(op.f('ix_matches_match_week'), table_name='matches')
    op.drop_constraint('uq_season_match_week', 'matches', type_='unique')
    op.drop_column('matches', 'match_week')
