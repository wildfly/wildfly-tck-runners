#!/bin/bash

#
# Copyright The WildFly Authors
# SPDX-License-Identifier: Apache-2.0
#

runReport() {
    cd "${1}" || return
    printf "\n\n%s\n" "${2}"
    parse-surefire-report "${CMD_ARGS[@]}"
    cd ..
}

if ! command -v jbang > /dev/null 2>&1
then
    curl -Ls https://sh.jbang.dev | bash -s - app setup
    export PATH="${PATH}:${HOME}/.jbang/bin"
fi

if ! command -v parse-surefire-report > /dev/null 2>&1
then
    jbang trust add https://github.com/jamezp/jbang-catalog/
    jbang app install parse-surefire-report@jamezp
fi

CMD_ARGS=("${@}")

printf "=%0.s" {1..50}
printf "\nOS Information\n"
printf "=%0.s" {1..50}
printf "\n"
cat /etc/os-release
printf "\n"

printf "=%0.s" {1..50}
printf "\nJava Version\n"
printf "=%0.s" {1..50}
printf "\n"
java -version

runReport "annotations-tck" "Jakarta Annotations TCK"
runReport "cdi-langmodel-tck" "Jakarta CDI Lang Model TCK"
runReport "cdi-tck" "Jakarta CDI TCK"
runReport "core-tck" "Jakarta EE Core Profile TCK"
runReport "inject-tck" "Jakarta Dependency Injection TCK"
runReport "jsonb-standalone-tck" "Jakarta JSON Binding TCK"
runReport "jsonp-plugability-tck" "Jakarta JSON Processing Plugability TCK"
runReport "jsonp-standalone-tck" "Jakarta JSON Processing TCK"
runReport "rest-tck" "Jakarta RESTful Web Services TCK"

printf "\n\nTotal:\n"
parse-surefire-report "${CMD_ARGS[@]}"