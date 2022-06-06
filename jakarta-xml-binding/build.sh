#! /bin/bash

if [ -z "${1}" ]; then
    IMAGE_NAME="standalone-jakarta-xml-bind-tck-4.0-image"
else
    IMAGE_NAME="${1}"
fi

docker build -t "${IMAGE_NAME}" .
