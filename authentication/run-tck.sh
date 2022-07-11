#! /bin/bash

TCK_URL=https://download.eclipse.org/ee4j/jakartaee-tck/jakartaee10/staged/eftl/jakarta-authentication-tck-3.0.1.zip
TCK_ZIP=jakarta-authentication-tck-3.0.1.zip
TCK_HOME=authentication-tck-3.0.1
TCK_ROOT=$TCK_HOME/tck
WILDFLY_HOME=wildfly/target/wildfly

################################################
# Install WildFly if not previously installed. #
################################################

# TODO - Override WildFly Version

if test -d $WILDFLY_HOME 
then
    echo "WildFly Already Installed"
else
    echo "WildFly Not Installed"
    pushd wildfly
    mvn install
    popd
fi

##############################################################
# Install and configure the TCK if not previously installed. #
##############################################################

if test -f $TCK_ZIP
then
    echo "TCK Already Downloaded."
else
    echo "Downloading TCK."
    curl $TCK_URL -o $TCK_ZIP
fi

if test -d $TCK_HOME
then
    echo "TCK Already Configured."
else
    echo "Configuring TCK."
    unzip $TCK_ZIP
    cp $TCK_ROOT/pom.xml $TCK_ROOT/original-pom.xml
    xsltproc wildfly-mods/transform.xslt $TCK_ROOT/original-pom.xml > $TCK_ROOT/pom.xml
fi

###################
# Execute the TCK #
###################

echo "Executing Jakarta Authentication TCK."
pushd $TCK_ROOT
mvn clean
mkdir target
mvn install -Pwildfly,\!old-tck
popd

echo "Execution Complete."
sha256sum $TCK_ZIP



