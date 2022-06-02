#!/usr/bin/env bash

#
# Copyright \(c\) "2022" Red Hat and others
#
# This program and the accompanying materials are made available under the Apache Software License 2.0 which is available at:
#  https://www.apache.org/licenses/LICENSE-2.0.
#
#  SPDX-License-Identifier: Apache-2.0
#

# Sample run script to go through the steps of running the TCKs once installed

# Uncomment if running against staged API artifacts
#STAGING=-Pstaging

# Validate required env variables
if [[ -z "${CDI_TCK_HOME}" ]]; then
  echo "The CDI_TCK_HOME env variable needs to be set to the location of the CDI TCK root"
fi
if [[ -z "${JBOSS_HOME}" ]]; then
  echo "The JBOSS_HOME env variable needs to be set to the location of the WildFly server root"
fi

echo "Running jsonp-standalone-tck"
cd jsonp-standalone-tck
mvn ${STAGING} verify
cd ..

echo "Running jsonb-standalone-tck"
cd jsonb-standalone-tck
mvn ${STAGING} verify
cd ..

echo "Running rest-tck"
cd rest-tck
mvn ${STAGING} -Pupdate-wildfly validate
mvn ${STAGING} verify
cd ..

echo "Running inject-tck"
cd inject-tck
mvn ${STAGING} verify
cd ..

echo "Running cdi-tck, signature tests"
cd cdi-tck
mvn ${STAGING} -Pupdate-wildfly validate
mvn ${STAGING} verify
mvn ${STAGING} -Psignature-test validate
cd ..

echo "Running core-tck"
cd core-tck
mvn ${STAGING} verify
cd ..
