#!/bin/bash

set -e

# Functions

fail() {
    echo "${1}"
    exit 1
}

createDir() {
    if [ ! -d "${1}" ]; then
        mkdir -p "${1}"
    fi
}

if [ -n "${JBOSS_HOME}" ]; then
    echo "Using JBOSS_HOME=${JBOSS_HOME}"
    CONFIG_FILE="standalone.xml"
    # If the standalone-core.xml file exists, we will use that
    if [ -e "${JBOSS_HOME}/docs/examples/configs/standalone-core.xml" ]; then
        cp "${JBOSS_HOME}/docs/examples/configs/standalone-core.xml" "${JBOSS_HOME}/standalone/configuration/"
        CONFIG_FILE="standalone-core.xml"
    fi
    echo "Using configuration file ${CONFIG_FILE}"
    if [ -n "${MAVEN_ARGS}" ]; then
        MAVEN_ARGS="${MAVEN_ARGS} -Dstandalone.xml.file=${CONFIG_FILE}"
    else
        MAVEN_ARGS="-Dstandalone.xml.file=${CONFIG_FILE}"
    fi
fi

for arg in "$@"; do
    MAVEN_ARGS="${MAVEN_ARGS} ${arg}"
done

echo "Running TCK with version ${VERSION}"
echo "mvn clean install ${MAVEN_ARGS}"
# shellcheck disable=SC2086
mvn clean install ${MAVEN_ARGS}
