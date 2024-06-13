FROM postgres:16-bookworm
RUN apt-get update \
     && apt-get install -y postgresql-16-partman \
     && apt-get clean \
     && rm -rf /var/lib/apt/lists/* \
