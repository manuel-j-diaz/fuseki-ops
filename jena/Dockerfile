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

## Apache Jena CLI tools Dockerfile (arq, riot, sparql, tdb2, etc.)

ARG JAVA_VERSION=21
ARG JENA_VERSION=""
ARG JENA_DIR=/jena

FROM eclipse-temurin:${JAVA_VERSION}-jre-alpine

ARG JENA_VERSION
ARG JENA_DIR
ARG JENA_TAR=apache-jena-${JENA_VERSION}.tar.gz
ARG REPO=https://repo1.maven.org/maven2
ARG TAR_URL=${REPO}/org/apache/jena/apache-jena/${JENA_VERSION}/${JENA_TAR}

RUN [ "${JENA_VERSION}" != "" ] || { echo && echo '**** Set JENA_VERSION ****' && echo && exit 1 ; }
RUN echo && echo "==== Docker build for Apache Jena ${JENA_VERSION} (CLI tools) ====" && echo

RUN apk add --no-cache bash curl ca-certificates findutils coreutils procps

WORKDIR /tmp/dl

COPY download.sh .
RUN chmod a+x download.sh

RUN ./download.sh --chksum sha1 "$TAR_URL"

RUN tar -xzf ${JENA_TAR} && \
    mv apache-jena-${JENA_VERSION} ${JENA_DIR} && \
    rm -rf ${JENA_DIR}/*javadoc* ${JENA_DIR}/*src* ${JENA_DIR}/bat && \
    rm -rf /tmp/dl

COPY log4j2.properties ${JENA_DIR}/

ARG JENA_USER=jena
ARG JENA_GROUP=jena
ARG JENA_GID=1000
ARG JENA_UID=1000

RUN addgroup -g "${JENA_GID}" "${JENA_GROUP}" && \
    adduser "${JENA_USER}" -G "${JENA_GROUP}" -s /bin/ash -u "${JENA_UID}" -H -D && \
    chown -R ${JENA_USER} ${JENA_DIR} && \
    mkdir /rdf && chown ${JENA_USER} /rdf

USER ${JENA_USER}

ENV \
    JAVA_OPTIONS="-Xmx2048m -Xms512m" \
    JENA_HOME="${JENA_DIR}"            \
    JENA_VERSION=${JENA_VERSION}

ENV PATH="${JENA_DIR}/bin:${PATH}"

## Smoke test — confirms the tools are functional and bash is present.
RUN riot --version

## Mount query files and RDF data here.
WORKDIR /rdf

CMD ["arq", "--help"]
