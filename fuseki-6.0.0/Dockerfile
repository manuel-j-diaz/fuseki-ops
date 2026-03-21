## Licensed to the Apache Software Foundation (ASF) under one or more
## contributor license agreements.  See the NOTICE file distributed with
## this work for additional information regarding copyright ownership.
## The ASF licenses this file to You under the Apache License, Version 2.0
## (the "License"); you may not use this file except in compliance with
## the License.  You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.

## Apache Jena Fuseki server Dockerfile (full distribution with web UI).

## This Dockerfile builds a reduced footprint container.

ARG JAVA_VERSION=21

ARG ALPINE_VERSION=3.21.2
ARG JENA_VERSION=""

# Internal, passed between stages.
ARG FUSEKI_DIR=/fuseki
ARG FUSEKI_TAR=apache-jena-fuseki-${JENA_VERSION}.tar.gz
ARG FUSEKI_JAR=fuseki-server.jar
ARG FUSEKI_UI_JAR=jena-fuseki-ui-${JENA_VERSION}.jar
ARG JAVA_MINIMAL=/opt/java-minimal

## ---- Stage: Download and build java.
FROM eclipse-temurin:${JAVA_VERSION}-alpine AS base

ARG JAVA_MINIMAL
ARG JENA_VERSION
ARG FUSEKI_DIR
ARG FUSEKI_TAR
ARG FUSEKI_JAR
ARG FUSEKI_UI_JAR
ARG REPO=https://repo1.maven.org/maven2
ARG TAR_URL=${REPO}/org/apache/jena/apache-jena-fuseki/${JENA_VERSION}/${FUSEKI_TAR}
ARG UI_JAR_URL=${REPO}/org/apache/jena/jena-fuseki-ui/${JENA_VERSION}/${FUSEKI_UI_JAR}

RUN [ "${JENA_VERSION}" != "" ] || { echo -e '\n**** Set JENA_VERSION ****\n' ; exit 1 ; }
RUN echo && echo "==== Docker build for Apache Jena Fuseki ${JENA_VERSION} (full distribution) ====" && echo

# Alpine: For objcopy used in jlink
RUN apk add --no-cache curl binutils

## -- Download and extract the full distribution tarball.
WORKDIR /tmp/dl

COPY download.sh .
RUN chmod a+x download.sh

# Download, with check of the SHA1 checksum.
RUN ./download.sh --chksum sha1 "$TAR_URL"

RUN tar -xzf ${FUSEKI_TAR} && \
    mv apache-jena-fuseki-${JENA_VERSION} ${FUSEKI_DIR}

## -- Download the UI JAR and extract the webapp assets to the filesystem.
## The server is started with --ui /fuseki/webapp (see docker-compose.yaml).
RUN ./download.sh --chksum sha1 "$UI_JAR_URL" && \
    jar xf ${FUSEKI_UI_JAR} webapp/ && \
    mv webapp ${FUSEKI_DIR}/webapp

## -- Make reduced Java JDK

WORKDIR ${FUSEKI_DIR}

ARG JDEPS_EXTRA="jdk.crypto.cryptoki,jdk.crypto.ec"
RUN \
  JDEPS="$(jdeps --multi-release base --print-module-deps --ignore-missing-deps ${FUSEKI_JAR})"  && \
  jlink \
        --compress 2 --strip-debug --no-header-files --no-man-pages \
        --output "${JAVA_MINIMAL}" \
        --add-modules "${JDEPS},${JDEPS_EXTRA}"

COPY entrypoint.sh .
COPY log4j2.properties .
COPY shiro.ini.template .

## ---- Stage: Build runtime
FROM alpine:${ALPINE_VERSION}

## Import ARGs
ARG JENA_VERSION
ARG JAVA_MINIMAL
ARG FUSEKI_DIR

COPY --from=base /opt/java-minimal /opt/java-minimal
COPY --from=base /fuseki /fuseki

WORKDIR $FUSEKI_DIR

ARG LOGS=${FUSEKI_DIR}/logs
ARG DATA=${FUSEKI_DIR}/databases

ARG JENA_USER=fuseki
ARG JENA_GROUP=$JENA_USER
ARG JENA_GID=1000
ARG JENA_UID=1000

# Run as this user
# -H : no home directory
# -D : no password
RUN apk add --no-cache gettext && \
    addgroup -g "${JENA_GID}" "${JENA_GROUP}" && \
    adduser "${JENA_USER}" -G "${JENA_GROUP}" -s /bin/ash -u "${JENA_UID}" -H -D

RUN mkdir --parents "${FUSEKI_DIR}" && \
    chown -R $JENA_USER ${FUSEKI_DIR}

USER $JENA_USER

RUN \
    mkdir -p $LOGS && \
    mkdir -p $DATA && \
    chmod a+x entrypoint.sh

## Default environment variables.
ENV \
    JAVA_HOME=${JAVA_MINIMAL}           \
    JAVA_OPTIONS="-Xmx4096m -Xms4096m"  \
    JENA_VERSION=${JENA_VERSION}        \
    FUSEKI_DIR="${FUSEKI_DIR}"

EXPOSE 3030

ENTRYPOINT ["./entrypoint.sh" ]
CMD []
