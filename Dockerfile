FROM postgres:16-bookworm
RUN apt-get update && apt-get install -y \
    postgresql-16-partman \
 && rm -rf /var/lib/apt/lists/*