## ------------------------------- Builder Stage ------------------------------ ##
FROM python:3.13-bookworm AS builder

# Install small tooling and the uv CLI to manage dependencies
RUN apt-get update \
    && apt-get install --no-install-recommends -y curl ca-certificates build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install uv (astral) to manage dependencies exactly like local dev
ADD https://astral.sh/uv/install.sh /install.sh
RUN chmod +x /install.sh && /install.sh && rm /install.sh
ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /app

# Copy only the files needed to resolve dependencies (pyproject + lock)
COPY pyproject.toml uv.lock ./

# Install dependencies with uv (creates .venv automatically and installs all packages)
RUN uv sync

## ------------------------------- Production Stage ------------------------------ ##
FROM python:3.13-slim-bookworm AS production

# Minimal runtime packages (libpq5 needed for PostgreSQL drivers)
RUN apt-get update \
    && apt-get install --no-install-recommends -y ca-certificates libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd --create-home --shell /bin/bash appuser

WORKDIR /app

# Copy the prepared .venv from the builder into the app dir so console-scripts exist
COPY --from=builder --chown=appuser:appuser /app/.venv /app/.venv

# Copy application code, alembic migrations, and entrypoint
COPY --chown=appuser:appuser ./app ./app
COPY --chown=appuser:appuser ./alembic ./alembic
COPY --chown=appuser:appuser ./entrypoint.sh ./entrypoint.sh
COPY --chown=appuser:appuser ./alembic.ini ./alembic.ini

RUN chmod +x ./entrypoint.sh

# Switch to non-root user
USER appuser

# Environment variables
ENV PATH="/app/.venv/bin:${PATH}" \
    PYTHONPATH="/app:${PYTHONPATH}" \
    PYTHONUNBUFFERED=1

EXPOSE 8000

# Healthcheck to verify container is running properly
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/').read()" || exit 1

CMD ["/app/entrypoint.sh"]
