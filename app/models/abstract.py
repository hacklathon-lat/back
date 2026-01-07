from datetime import datetime
from uuid import UUID, uuid4

from sqlmodel import Column, DateTime, Field, SQLModel, text


class AbstractBase(SQLModel):
    id: UUID = Field(default_factory=uuid4, primary_key=True)

    created_at: datetime = Field(
        sa_column=Column(
            DateTime(timezone=True),
            nullable=False,
            server_default=text("CURRENT_TIMESTAMP"),
        ),
    )


class AbstractTimestampMixin(AbstractBase):
    updated_at: datetime | None = Field(
        default=None,
        sa_column=Column(
            DateTime(timezone=True),
            nullable=False,
            server_default=text("CURRENT_TIMESTAMP"),
            server_onupdate=text("CURRENT_TIMESTAMP"),
        ),
    )
