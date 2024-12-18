# build stage
FROM nimlang/choosenim AS build
RUN choosenim update 2.0.0

RUN nimble update
RUN nimble install docopt
RUN nimble install httpbeast@0.4.2
RUN nimble install jester
RUN nimble install db_connector
RUN nimble install libsha
RUN nimble install htmlgenerator

ADD . /work
WORKDIR /work
RUN nimble install

# prod stage
FROM debian:stable-slim AS prod

RUN apt-get update && \
    apt-get install -y libsqlite3-0 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /work
COPY --from=build /work/bin/webAppBase .
ADD src/static public
RUN ln -s data/webapp.db
