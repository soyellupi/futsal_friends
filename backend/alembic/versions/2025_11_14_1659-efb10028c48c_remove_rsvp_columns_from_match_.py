"""remove rsvp columns from match_attendances

Revision ID: efb10028c48c
Revises: 2270fe0f8d73
Create Date: 2025-11-14 16:59:20.197200

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'efb10028c48c'
down_revision: Union[str, None] = '2270fe0f8d73'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Drop the rsvp_at column
    op.drop_column('match_attendances', 'rsvp_at')

    # Drop the rsvp_status column
    op.drop_column('match_attendances', 'rsvp_status')

    # Drop the rsvp_status enum type
    op.execute('DROP TYPE IF EXISTS rsvp_status')


def downgrade() -> None:
    # Recreate the enum type
    op.execute("CREATE TYPE rsvp_status AS ENUM ('pending', 'confirmed', 'declined')")

    # Add back rsvp_status column
    op.add_column('match_attendances',
        sa.Column('rsvp_status',
                  sa.Enum('pending', 'confirmed', 'declined', name='rsvp_status'),
                  nullable=False,
                  server_default='pending')
    )

    # Add back rsvp_at column
    op.add_column('match_attendances',
        sa.Column('rsvp_at', sa.DateTime(), nullable=True)
    )
