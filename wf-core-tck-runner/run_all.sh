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

# locate SPEC API jars if not already specified
if [[ -z "${ANNOTATION_API}" ]]; then
  pushd ${JBOSS_HOME}
  export ANNOTATION_API=`find * -name jakarta*annotation*api*.jar`
  popd
fi

if [[ -z "${EXPRESSION_LANGUAGE_API}" ]]; then
  pushd ${JBOSS_HOME}
  export EXPRESSION_LANGUAGE_API=`find * -name *el-api*.jar`
  popd
fi

if [[ -z "${INTERCEPTER_API}" ]]; then
  pushd ${JBOSS_HOME}
  export INTERCEPTER_API=`find * -name *interceptor-api*.jar`
  popd
fi

if [[ -z "${INJECT_API}" ]]; then
  pushd ${JBOSS_HOME}
  export INJECT_API=`find * -name *inject-api*.jar`
  popd
fi

if [[ -z "${CDI_API}" ]]; then
  pushd ${JBOSS_HOME}
  export CDI_API=`find * -name *enterprise*cdi*api*.jar`
  popd
fi

if [[ -z "${CDI_LANG_MODEL_API}" ]]; then
  pushd ${JBOSS_HOME}
  export CDI_LANG_MODEL_API=`find * -name *enterprise*lang*model*.jar`
  popd
fi

if [[ -z "${JSONP_API}" ]]; then
  pushd ${JBOSS_HOME}
  export JSONP_API=`find * -name *json-api*.jar`
  popd
fi

if [[ -z "${JSONB_API}" ]]; then
  pushd ${JBOSS_HOME}
  export JSONB_API=`find * -name *json.bind*api*.jar`
  popd
fi

if [[ -z "${REST_API}" ]]; then
  pushd ${JBOSS_HOME}
  export REST_API=`find * -name *ws.rs-api*.jar`
  popd
fi

if [[ -z "${XML_BIND_API}" ]]; then
  pushd ${JBOSS_HOME}
  export XML_BIND_API=`find * -name *xml*bind*api*.jar`
  popd
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
