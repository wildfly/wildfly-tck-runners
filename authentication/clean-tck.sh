#! /bin/bash

TCK_ZIP=jakarta-authentication-tck-3.0.1.zip
TCK_HOME=authentication-tck-3.0.1
OLD_TCK_HOME=authentication-tck
ANT_ZIP=apache-ant-1.9.16-bin.zip
ANT_HOME=apache-ant-1.9.16

rm $ANT_ZIP
rm -fR $ANT_HOME
rm -fR $TCK_HOME
rm -fR $OLD_TCK_HOME
rm $TCK_ZIP
rm -fR servers
pushd wildfly
mvn clean
popd

echo "TCK Environment Cleaned."
