#!/usr/bin/env bash

# Sample run script to go through the steps of running the TCKs once installed

cd jsonp-standalone-tck
mvn -Pstaging verify
cd ..

cd jsonb-standalone-tck
mvn -Pstaging verify
cd ..

cd rest-tck
mvn -Pstaging -Pupdate-wildfly validate
mvn -Pstaging verify
cd ..

cd inject-tck
mvn -Pstaging verify
cd ..

cd cdi-tck
mvn -Pstaging -Pupdate-wildfly validate
mvn -Pstaging verify
cd ..

