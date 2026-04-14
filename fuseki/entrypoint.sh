#!/bin/sh
## Licensed under the terms of http://www.apache.org/licenses/LICENSE-2.0

## Generate shiro.ini from template, substituting admin credentials from env vars.
## Only ${FUSEKI_ADMIN_USER} and ${FUSEKI_ADMIN_PASSWORD} are substituted;
## other $ signs in the template (e.g. $plainMatcher, $/ping) are left as-is.
mkdir -p "${FUSEKI_DIR}/run"
envsubst '${FUSEKI_ADMIN_USER} ${FUSEKI_ADMIN_PASSWORD}' \
    < "${FUSEKI_DIR}/shiro.ini.template" \
    > "${FUSEKI_DIR}/run/shiro.ini"

export FUSEKI_HOME="${FUSEKI_DIR}"
export JVM_ARGS="${JAVA_OPTIONS}"

exec "${FUSEKI_DIR}/fuseki-server" "$@"
