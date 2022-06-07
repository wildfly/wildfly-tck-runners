#! /bin/bash

fail() {
    echo "${1}"
    printHelp
    exit 1
}

printArgHelp() {
    echo -e "${1}\t${2}"
}

printHelp() {
    echo "Starts a container to execute the Jakarta XML Binding 4.0 TCK."
    echo "Usage: ${0##*/} ~/projects/wildfly/wildfly/dist/target/wildfly-\${VERSION}.zip"
}

WILDFLY_ZIP="${1}"
if [ -f "${WILDFLY_ZIP}" ]; then
    WILDFLY_ZIP="$(readlink -m "${WILDFLY_ZIP}")"
else
    fail "The path to a WildFly ZIP file is required."
fi
shift

# If the second argument is a number the Java version is being specified

CONTAINER_NAME="standalone-jakarta-xml-bind-tck-4.0-container"
IMAGE_NAME="standalone-jakarta-xml-bind-tck-4.0-image"

# Check if the container exists, if not build it
if ! docker images | grep -q "${IMAGE_NAME}"
then
    echo "Could not find container ${IMAGE_NAME}, building image."
    ./build.sh "${IMAGE_NAME}"
fi
if [ "$(docker ps -qa -f name="${CONTAINER_NAME}")" ]; then
    # Check if the container has already been started
    if [ "$(docker ps -q -f name="${CONTAINER_NAME}")" ]; then
        docker stop "${CONTAINER_NAME}"
    fi
    # Delete the container
    docker rm "${CONTAINER_NAME}" &> /dev/null
fi

docker run -u jboss:jboss --hostname=localhost --name "${CONTAINER_NAME}" -v "${WILDFLY_ZIP}":/home/jboss/wildfly.zip:Z -it "${IMAGE_NAME}" "$@"
