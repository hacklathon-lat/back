# Simple Makefile for common developer tasks
# - clean: remove temporary/build files and caches
# - migrate: run alembic migrations (uses 'uv' if available)

.PHONY: help clean clean-pyc clean-all migrate create-tables lint

SHELL := /bin/bash

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  clean        Remove __pycache__, .pyc files, pytest/mypy caches, build artifacts"
	@echo "  clean-pyc    Remove only python cache files (__pycache__, *.pyc)"
	@echo "  clean-all    Remove everything from clean + .venv (only if CLEAN_VENV=true)"
	@echo "  migrate      Run alembic migrations (uses 'uv' if available; falls back to 'alembic')"
	@echo "  create-tables    Create new migration (interactive - prompts for message)"
	@echo "  lint         - Run linter with auto-fix + format code"


# detect migration command: prefer 'uv' if on path
MIGRATE := $(shell if command -v uv >/dev/null 2>&1; then echo "uv run alembic"; else echo "alembic"; fi)

clean-pyc:
	@echo "Removing Python cache files..."
	@find . -type d -name "__pycache__" -print -exec rm -rf {} + || true
	@find . -name "*.pyc" -print -delete || true

clean:
	@$(MAKE) clean-pyc
	@echo "Removing test/build caches and artifacts..."
	@rm -rf .pytest_cache .mypy_cache .coverage htmlcov dist build *.egg-info || true

clean-all: clean
	@if [ "$(CLEAN_VENV)" = "true" ]; then \
		echo "Removing .venv ..."; \
		rm -rf .venv || true; \
	else \
		echo "Skipping .venv removal (set CLEAN_VENV=true to remove)"; \
	fi

migrate:
	@echo "Running migrations in Docker container..."
	@docker compose exec app alembic upgrade head

create-tables:
	@read -p "Migration message: " msg; \
	docker compose exec app alembic revision --autogenerate -m "$$msg"

# Linting and formatting commands
lint:
	@echo "✨ Formatting code..."
	ruff format .
	@echo "🔍 Running linter with auto-fix..."
	ruff check . --fix