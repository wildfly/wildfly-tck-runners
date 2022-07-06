#! /bin/bash

TCK_ZIP=jakarta-authentication-tck-3.0.1.zip
TCK_HOME=authentication-tck-3.0.1

rm -fR $TCK_HOME
rm $TCK_ZIP
pushd wildfly
mvn clean
popd

echo "TCK Environment Cleaned."
