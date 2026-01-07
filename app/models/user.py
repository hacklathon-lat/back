from datetime import datetime
from typing import ClassVar

from pydantic import EmailStr
from sqlmodel import Column, DateTime, Field

from .abstract import AbstractTimestampMixin


class User(AbstractTimestampMixin, table=True):
    __tablename__: ClassVar[str] = "users"

    name: str | None = Field(
        default=None,
        min_length=2,
        max_length=50,
    )
    surname: str | None = Field(
        default=None,
        min_length=2,
        max_length=50,
    )
    email: EmailStr = Field(index=True, unique=True)
    hashed_password: str = Field(min_length=8, max_length=128)

    is_verified: bool = False
    is_active: bool = True
    is_superuser: bool = False

    locale: str = "en"
    timezone: str = "UTC"

    last_login: datetime | None = Field(
        default=None,
        sa_column=Column(DateTime(timezone=True), nullable=True),
    )
