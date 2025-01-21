#!/bin/bash

#
# Copyright The WildFly Authors
# SPDX-License-Identifier: Apache-2.0
#

runReport() {
    pushd "${1}" >> /dev/null || return
    printf "\n\n%s\n" "${2}"
    parse-surefire-report "${CMD_ARGS[@]}"
    popd >> /dev/null || return
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

runReport "annotations-tck/annotations-tck-runner" "Jakarta Annotations TCK"
runReport "cdi-langmodel-tck/cdi-langmodel-tck-runner" "Jakarta CDI Lang Model TCK"
runReport "cdi-lite-tck/cdi-lite-tck-runner" "Jakarta CDI TCK"
runReport "core-profile-tck-runner" "Jakarta EE Core Profile TCK"
runReport "inject-tck/inject-tck-runner" "Jakarta Dependency Injection TCK"
runReport "jsonb-tck/jsonb-tck-runner" "Jakarta JSON Binding TCK"
runReport "jsonp-tck/jsonp-plugability-tck-runner" "Jakarta JSON Processing Plugability TCK"
runReport "jsonp-tck/jsonp-tck-runner" "Jakarta JSON Processing TCK"
runReport "rest-tck/rest-tck-runner" "Jakarta RESTful Web Services TCK"

printf "\n\nTotal:\n"
parse-surefire-report "${CMD_ARGS[@]}"