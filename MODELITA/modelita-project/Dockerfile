FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    postgresql \
    postgresql-contrib \
    postgis \
    wget \
    sudo \
    python3 \
    python3-pip \
    libcairo2 \
    libglib2.0-0 \
    libpango1.0-0 \
    libgtk2.0-0 \
    openssl \
    libgmp-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install the latest Racket forcibly into /usr/local
RUN wget https://mirror.racket-lang.org/installers/8.14/racket-8.14-x86_64-linux-cs.sh \
    && chmod +x racket-8.14-x86_64-linux-cs.sh \
    && yes | ./racket-8.14-x86_64-linux-cs.sh --in-place --dest /usr/local \
    && rm racket-8.14-x86_64-linux-cs.sh

# Add Racket to the PATH
ENV PATH="/usr/local/racket/bin:${PATH}"


# Now you can run your raco pkg install
RUN raco pkg show db || raco pkg install --auto db

RUN mkdir -p /app/modelita/symbols \
    && mkdir -p /app/modelita/models \
    && mkdir -p /app/modelita/blender

WORKDIR /app/modelita

COPY modelita.rkt /app/modelita/
COPY blender/objimporter.py /app/modelita/blender/
COPY LICENSE.md /app/modelita/

USER postgres
RUN /etc/init.d/postgresql start && \
    psql -c "CREATE DATABASE gisdb;" && \
    psql -d gisdb -c "CREATE EXTENSION postgis;" && \
    psql -c "ALTER USER postgres PASSWORD 'modelita123';" && \
    echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/14/main/pg_hba.conf && \
    echo "listen_addresses='*'" >> /etc/postgresql/14/main/postgresql.conf

USER root
RUN echo '#!/bin/bash\n\
service postgresql start\n\
echo "PostgreSQL started"\n\
echo "Starting DrRacket..."\n\
drracket\n\
' > /app/modelita/start.sh && \
chmod +x /app/modelita/start.sh

EXPOSE 5432

ENTRYPOINT ["/app/modelita/start.sh"]
