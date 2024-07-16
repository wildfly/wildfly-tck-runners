#! /bin/bash
TCK_VERSION="3.0.2"
TCK_ZIP=jakarta-security-tck-${TCK_VERSION}.zip
TCK_HOME=security-tck-${TCK_VERSION}
OLD_TCK_HOME=security-tck
ANT_ZIP=apache-ant-1.9.16-bin.zip
ANT_HOME=apache-ant-1.9.16
GLASSFISH_ZIP=glassfish-7.0.0.zip
GLASSFISH_HOME=glassfish7

rm $GLASSFISH_ZIP
rm -fR $GLASSFISH_HOME
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
