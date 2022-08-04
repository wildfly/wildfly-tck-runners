#! /bin/bash

TCK_URL=https://download.eclipse.org/ee4j/jakartaee-tck/jakartaee10/staged/eftl/jakarta-authentication-tck-3.0.1.zip
TCK_ZIP=jakarta-authentication-tck-3.0.1.zip
TCK_HOME=authentication-tck-3.0.1
TCK_ROOT=$TCK_HOME/tck
WILDFLY_HOME=wildfly/target/wildfly
NEW_WILDFLY=servers/new-wildfly
VI_HOME=

################################################
# Install WildFly if not previously installed. #
################################################

# TODO - Override WildFly Version

if [[ -n $JBOSS_HOME ]] 
then
    if test -d $JBOSS_HOME 
    then
        echo "Using existing server installation " $JBOSS_HOME
        WILDFLY_HOME=$JBOSS_HOME
    else
        echo "JBOSS_HOME points to invalid location " $JBOSS_HOME
        exit 1
    fi
else
    echo "JBOSS_HOME Is NOT Set."
    if ! test -d $WILDFLY_HOME
    then
        echo "Provisioning WildFly."
        pushd wildfly
        mvn install -Dprovision.skip=false -Dconfigure.skip=true
        popd
    fi
fi
# At this point WILDFLY_HOME points to the clean server.

####################################
# Create a copy to run the new TCK #
####################################

# First delete any existing clone.
if test -d servers
then
    echo "Deleting existing 'servers' directory."
    rm -fR servers
fi

mkdir servers
echo "Cloning WildFly " $WILDFLY_HOME $NEW_WILDFLY
cp -R $WILDFLY_HOME $NEW_WILDFLY

pushd $NEW_WILDFLY
NEW_WILDFLY=`pwd`
popd

pushd wildfly
mvn install -Dwildfly.home=$NEW_WILDFLY -Dprovision.skip=true -Dconfigure.skip=false
popd

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
mvn install -Pwildfly,\!old-tck -Dtest.wildfly.home=$NEW_WILDFLY -fae
popd

echo "Execution Complete."
sha256sum $TCK_ZIP
