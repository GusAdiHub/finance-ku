"""Category ORM model."""
from typing import TYPE_CHECKING, List, Optional
from sqlalchemy import Boolean, CheckConstraint, ForeignKey, Index, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database.base import Base, TimestampMixin, UUIDPrimaryKeyMixin

if TYPE_CHECKING:
    from app.models.finance_group import FinanceGroup
    from app.models.transaction import Transaction
    from app.models.user import User


class Category(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Financial category model for income and expense classification."""

    __tablename__ = "categories"
    __table_args__ = (
        CheckConstraint("type IN ('income', 'expense')", name="ck_categories_type"),
        CheckConstraint(
            "(user_id IS NULL OR group_id IS NULL)",
            name="ck_categories_single_scope",
        ),
        CheckConstraint(
            "("
            "(is_system = TRUE AND user_id IS NULL AND group_id IS NULL) OR "
            "(is_system = FALSE AND (user_id IS NOT NULL OR group_id IS NOT NULL))"
            ")",
            name="ck_categories_system_or_custom",
        ),
        Index("ix_categories_type_system", "type", "is_system"),
        Index("ix_categories_user_id", "user_id"),
        Index("ix_categories_group_id", "group_id"),
    )

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    type: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        comment="Category type: 'income' or 'expense'",
    )
    icon: Mapped[Optional[str]] = mapped_column(
        String(50),
        nullable=True,
        comment="UI icon identifier",
    )
    color: Mapped[Optional[str]] = mapped_column(
        String(20),
        nullable=True,
        comment="Hex color code (e.g. #10B981)",
    )
    is_system: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
        comment="System-provided default category flag",
    )
    user_id: Mapped[Optional[str]] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=True,
        comment="Owner user for custom personal categories",
    )
    group_id: Mapped[Optional[str]] = mapped_column(
        String(36),
        ForeignKey("finance_groups.id", ondelete="RESTRICT"),
        nullable=True,
        comment="Finance group for custom group categories",
    )

    # Relationships
    user: Mapped[Optional["User"]] = relationship(
        "User",
        back_populates="custom_categories",
        foreign_keys=[user_id],
    )
    group: Mapped[Optional["FinanceGroup"]] = relationship(
        "FinanceGroup",
        back_populates="categories",
        foreign_keys=[group_id],
    )
    transactions: Mapped[List["Transaction"]] = relationship(
        "Transaction",
        back_populates="category",
        foreign_keys="Transaction.category_id",
    )

    def __repr__(self) -> str:
        return f"<Category id={self.id} name='{self.name}' type={self.type} is_system={self.is_system}>"
