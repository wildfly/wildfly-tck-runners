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
if [[ -z "${JBOSS_HOME}" ]]; then
  echo "The JBOSS_HOME env variable needs to be set to the location of the WildFly server root"
  exit 1
fi

# Check
ca_jar_size=($(wc -c  ${JBOSS_HOME}/modules/system/layers/base/jakarta/annotation/api/main/jakarta.annotation-api-2.1.0.jar ))
if [[ ${ca_jar_size} != 26141 ]]; then
  echo "Patching WFP jakarta.annotation-api-2.1.0.jar to 2.1.1..."
  wget -O ${JBOSS_HOME}/modules/system/layers/base/jakarta/annotation/api/main/jakarta.annotation-api-2.1.0.jar \
    https://repo1.maven.org/maven2/jakarta/annotation/jakarta.annotation-api/2.1.1/jakarta.annotation-api-2.1.1.jar
fi

echo "+++ Environment:"
uname -a
echo "JAVA_HOME=$JAVA_HOME"
$JAVA_HOME/bin/java -version

echo "+++ Running jsonp-standalone-tck"
cd jsonp-standalone-tck
mvn ${STAGING} verify
cd ..

echo "+++ Running jsonb-standalone-tck"
cd jsonb-standalone-tck
mvn ${STAGING} verify
cd ..

echo "+++ Running rest-tck"
cd rest-tck
mvn ${STAGING} -Pupdate-wildfly validate
mvn ${STAGING} verify
cd ..

echo "+++ Running inject-tck"
cd inject-tck
mvn ${STAGING} verify
cd ..

echo "+++ Running cdi-tck"
cd cdi-tck
mvn ${STAGING} -Pupdate-wildfly validate
mvn ${STAGING} verify
echo "+++ Running CDI signature tests"
mvn ${STAGING} -Pcdi-signature-test process-test-sources
echo "+++ Running Commons Annotations signature tests"
mvn ${STAGING} -Pca-signature-test process-test-sources
cd ..

echo "+++ Running cdi-langmodel-tck"
cd cdi-langmodel-tck
mvn ${STAGING} test
cd ..

echo "+++ Running core-tck"
cd core-tck
mvn ${STAGING} verify
cd ..
