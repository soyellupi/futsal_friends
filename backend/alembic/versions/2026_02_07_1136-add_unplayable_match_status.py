"""add_unplayable_match_status

Revision ID: add_unplayable_status
Revises: efb10028c48c
Create Date: 2026-02-07

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'add_unplayable_status'
down_revision: Union[str, None] = 'efb10028c48c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add 'UNPLAYABLE' value to the match_status enum
    # Note: PostgreSQL enum values are case-sensitive, and existing values are uppercase
    op.execute("ALTER TYPE match_status ADD VALUE 'UNPLAYABLE'")


def downgrade() -> None:
    # Note: PostgreSQL doesn't support removing enum values directly.
    # This would require recreating the enum type and updating all references.
    # For safety, we'll leave the enum value in place during downgrade.
    pass
