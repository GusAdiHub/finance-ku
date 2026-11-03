"""Initial database schema for Personal & Family Finance Tracker.

Revision ID: 001_initial_schema
Revises:
Create Date: 2026-10-30 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "001_initial_schema"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. users table
    op.create_table(
        "users",
        sa.Column("id", sa.CHAR(36), primary_key=True, comment="Unique identifier (UUID v4)"),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("1")),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column(
            "updated_at",
            sa.DateTime(),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
        ),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    # 2. finance_groups table
    op.create_table(
        "finance_groups",
        sa.Column("id", sa.CHAR(36), primary_key=True, comment="Unique identifier (UUID v4)"),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("created_by_user_id", sa.CHAR(36), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("1")),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column(
            "updated_at",
            sa.DateTime(),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
        ),
        sa.ForeignKeyConstraint(["created_by_user_id"], ["users.id"], ondelete="RESTRICT"),
    )
    op.create_index("ix_finance_groups_created_by", "finance_groups", ["created_by_user_id"])

    # 3. group_members table
    op.create_table(
        "group_members",
        sa.Column("id", sa.CHAR(36), primary_key=True, comment="Unique identifier (UUID v4)"),
        sa.Column("group_id", sa.CHAR(36), nullable=False),
        sa.Column("user_id", sa.CHAR(36), nullable=False),
        sa.Column("role", sa.String(20), nullable=False, server_default="member"),
        sa.Column("joined_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("1")),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column(
            "updated_at",
            sa.DateTime(),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
        ),
        sa.ForeignKeyConstraint(["group_id"], ["finance_groups.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="RESTRICT"),
        sa.UniqueConstraint("group_id", "user_id", name="uq_group_members_group_user"),
        sa.CheckConstraint("role IN ('owner', 'admin', 'member')", name="ck_group_members_role"),
    )
    op.create_index("ix_group_members_group_active", "group_members", ["group_id", "is_active"])
    op.create_index("ix_group_members_user_active", "group_members", ["user_id", "is_active"])

    # 4. group_invitations table
    op.create_table(
        "group_invitations",
        sa.Column("id", sa.CHAR(36), primary_key=True, comment="Unique identifier (UUID v4)"),
        sa.Column("group_id", sa.CHAR(36), nullable=False),
        sa.Column("created_by_user_id", sa.CHAR(36), nullable=False),
        sa.Column("code_hash", sa.String(255), nullable=False),
        sa.Column("expires_at", sa.DateTime(), nullable=False),
        sa.Column("max_uses", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("uses_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_revoked", sa.Boolean(), nullable=False, server_default=sa.text("0")),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column(
            "updated_at",
            sa.DateTime(),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
        ),
        sa.ForeignKeyConstraint(["group_id"], ["finance_groups.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["created_by_user_id"], ["users.id"], ondelete="RESTRICT"),
        sa.CheckConstraint("max_uses >= 1", name="ck_invitations_max_uses"),
        sa.CheckConstraint("uses_count >= 0", name="ck_invitations_uses_count"),
    )
    op.create_index("ix_group_invitations_code_hash", "group_invitations", ["code_hash"], unique=True)
    op.create_index(
        "ix_invitations_group_status",
        "group_invitations",
        ["group_id", "is_revoked", "expires_at"],
    )

    # 5. categories table
    op.create_table(
        "categories",
        sa.Column("id", sa.CHAR(36), primary_key=True, comment="Unique identifier (UUID v4)"),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("type", sa.String(20), nullable=False),
        sa.Column("icon", sa.String(50), nullable=True),
        sa.Column("color", sa.String(20), nullable=True),
        sa.Column("is_system", sa.Boolean(), nullable=False, server_default=sa.text("0")),
        sa.Column("user_id", sa.CHAR(36), nullable=True),
        sa.Column("group_id", sa.CHAR(36), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column(
            "updated_at",
            sa.DateTime(),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["group_id"], ["finance_groups.id"], ondelete="RESTRICT"),
        sa.CheckConstraint("type IN ('income', 'expense')", name="ck_categories_type"),
        sa.CheckConstraint(
            "(user_id IS NULL OR group_id IS NULL)",
            name="ck_categories_single_scope",
        ),
        sa.CheckConstraint(
            "("
            "(is_system = 1 AND user_id IS NULL AND group_id IS NULL) OR "
            "(is_system = 0 AND (user_id IS NOT NULL OR group_id IS NOT NULL))"
            ")",
            name="ck_categories_system_or_custom",
        ),
    )
    op.create_index("ix_categories_type_system", "categories", ["type", "is_system"])
    op.create_index("ix_categories_user_id", "categories", ["user_id"])
    op.create_index("ix_categories_group_id", "categories", ["group_id"])

    # 6. receipts table
    op.create_table(
        "receipts",
        sa.Column("id", sa.CHAR(36), primary_key=True, comment="Unique identifier (UUID v4)"),
        sa.Column("user_id", sa.CHAR(36), nullable=False),
        sa.Column("group_id", sa.CHAR(36), nullable=True),
        sa.Column("file_path", sa.String(500), nullable=False),
        sa.Column("file_name", sa.String(255), nullable=False),
        sa.Column("file_size", sa.Integer(), nullable=False),
        sa.Column("mime_type", sa.String(100), nullable=False),
        sa.Column("merchant_name", sa.String(255), nullable=True),
        sa.Column("receipt_date", sa.DateTime(), nullable=True),
        sa.Column("total_amount", sa.Numeric(15, 2), nullable=True),
        sa.Column("raw_ocr_data", sa.JSON(), nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="draft"),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column(
            "updated_at",
            sa.DateTime(),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["group_id"], ["finance_groups.id"], ondelete="RESTRICT"),
        sa.CheckConstraint(
            "status IN ('draft', 'confirmed', 'rejected', 'failed')",
            name="ck_receipts_status",
        ),
    )
    op.create_index("ix_receipts_user_status", "receipts", ["user_id", "status"])
    op.create_index("ix_receipts_group_id", "receipts", ["group_id"])

    # 7. transactions table
    op.create_table(
        "transactions",
        sa.Column("id", sa.CHAR(36), primary_key=True, comment="Unique identifier (UUID v4)"),
        sa.Column("type", sa.String(20), nullable=False),
        sa.Column("amount", sa.Numeric(15, 2), nullable=False),
        sa.Column("category_id", sa.CHAR(36), nullable=False),
        sa.Column("transaction_date", sa.DateTime(), nullable=False),
        sa.Column("description", sa.String(255), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("owner_user_id", sa.CHAR(36), nullable=True),
        sa.Column("group_id", sa.CHAR(36), nullable=True),
        sa.Column("created_by_user_id", sa.CHAR(36), nullable=False),
        sa.Column("input_method", sa.String(20), nullable=False, server_default="manual"),
        sa.Column("receipt_id", sa.CHAR(36), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column(
            "updated_at",
            sa.DateTime(),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
        ),
        sa.ForeignKeyConstraint(["category_id"], ["categories.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["owner_user_id"], ["users.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["group_id"], ["finance_groups.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["created_by_user_id"], ["users.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["receipt_id"], ["receipts.id"], ondelete="SET NULL"),
        sa.CheckConstraint("type IN ('income', 'expense')", name="ck_transactions_type"),
        sa.CheckConstraint("amount > 0", name="ck_transactions_amount_positive"),
        sa.CheckConstraint(
            "input_method IN ('manual', 'ocr', 'voice')",
            name="ck_transactions_input_method",
        ),
        sa.CheckConstraint(
            "("
            "(owner_user_id IS NOT NULL AND group_id IS NULL) OR "
            "(owner_user_id IS NULL AND group_id IS NOT NULL)"
            ")",
            name="ck_transactions_single_scope",
        ),
    )
    op.create_index("ix_transactions_personal_date", "transactions", ["owner_user_id", "transaction_date"])
    op.create_index("ix_transactions_group_date", "transactions", ["group_id", "transaction_date"])
    op.create_index("ix_transactions_category_id", "transactions", ["category_id"])
    op.create_index("ix_transactions_creator_id", "transactions", ["created_by_user_id"])
    op.create_index("ix_transactions_date", "transactions", ["transaction_date"])

    # 8. transaction_items table
    op.create_table(
        "transaction_items",
        sa.Column("id", sa.CHAR(36), primary_key=True, comment="Unique identifier (UUID v4)"),
        sa.Column("transaction_id", sa.CHAR(36), nullable=True),
        sa.Column("receipt_id", sa.CHAR(36), nullable=True),
        sa.Column("item_name", sa.String(255), nullable=False),
        sa.Column("quantity", sa.Numeric(10, 2), nullable=False, server_default="1.00"),
        sa.Column("price_per_unit", sa.Numeric(15, 2), nullable=False),
        sa.Column("total_price", sa.Numeric(15, 2), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column(
            "updated_at",
            sa.DateTime(),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
        ),
        sa.ForeignKeyConstraint(["transaction_id"], ["transactions.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["receipt_id"], ["receipts.id"], ondelete="CASCADE"),
        sa.CheckConstraint("quantity > 0", name="ck_transaction_items_qty_positive"),
        sa.CheckConstraint("price_per_unit >= 0", name="ck_transaction_items_price_nonneg"),
        sa.CheckConstraint("total_price >= 0", name="ck_transaction_items_total_nonneg"),
        sa.CheckConstraint(
            "(transaction_id IS NOT NULL OR receipt_id IS NOT NULL)",
            name="ck_transaction_items_has_parent",
        ),
    )
    op.create_index("ix_transaction_items_tx_id", "transaction_items", ["transaction_id"])
    op.create_index("ix_transaction_items_rcpt_id", "transaction_items", ["receipt_id"])

    # 9. audit_logs table
    op.create_table(
        "audit_logs",
        sa.Column("id", sa.CHAR(36), primary_key=True, comment="Unique identifier (UUID v4)"),
        sa.Column("user_id", sa.CHAR(36), nullable=True),
        sa.Column("group_id", sa.CHAR(36), nullable=True),
        sa.Column("action", sa.String(100), nullable=False),
        sa.Column("entity_type", sa.String(50), nullable=False),
        sa.Column("entity_id", sa.CHAR(36), nullable=True),
        sa.Column("details", sa.JSON(), nullable=True),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("user_agent", sa.String(255), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["group_id"], ["finance_groups.id"], ondelete="SET NULL"),
    )
    op.create_index("ix_audit_logs_group_created", "audit_logs", ["group_id", "created_at"])
    op.create_index("ix_audit_logs_user_created", "audit_logs", ["user_id", "created_at"])
    op.create_index("ix_audit_logs_entity", "audit_logs", ["entity_type", "entity_id"])


def downgrade() -> None:
    op.drop_table("audit_logs")
    op.drop_table("transaction_items")
    op.drop_table("transactions")
    op.drop_table("receipts")
    op.drop_table("categories")
    op.drop_table("group_invitations")
    op.drop_table("group_members")
    op.drop_table("finance_groups")
    op.drop_table("users")
