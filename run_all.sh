#!/usr/bin/env bash

# Sample run script to go through the steps of running the TCKs once installed

# Uncomment if running against staged API artifacts
#STAGING=-Pstaging

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

echo "Running cdi-tck"
cd cdi-tck
mvn ${STAGING} -Pupdate-wildfly validate
mvn ${STAGING} verify
cd ..

echo "Running core-tck"
cd core-tck
mvn ${STAGING} verify
cd ..
