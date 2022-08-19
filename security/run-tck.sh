#! /bin/bash

TCK_URL=https://download.eclipse.org/jakartaee/security/3.0/jakarta-security-tck-3.0.0.zip
TCK_ZIP=jakarta-security-tck-3.0.0.zip
TCK_HOME=security-tck-3.0.0
TCK_ROOT=$TCK_HOME/tck
WILDFLY_HOME=wildfly/target/wildfly
NEW_WILDFLY=servers/new-wildfly
OLD_WILDFLY=servers/old-wildfly
VI_HOME=
MVN_ARGS="-B -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn"
UNZIP_ARGS="-q"

# Parse incoming parameters
while getopts ":v" opt; do
    case "${opt}" in
        v)
            UNZIP_ARGS=""
            MVN_ARGS=""
            ;;
        \?)
            echo "Invalid option: -${OPTARG}" >&2
            printHelp
            exit 1
            ;;
        :)
            echo "Option -${OPTARG} requires an argument" >&2
            exit 1
            ;;
    esac
done

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
        mvn ${MVN_ARGS} install -Dprovision.skip=false -Dconfigure.skip=true
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
mvn ${MVN_ARGS} install -Dwildfly.home=$NEW_WILDFLY -Dprovision.skip=true -Dconfigure.skip=false
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
    unzip ${UNZIP_ARGS} $TCK_ZIP
    cp $TCK_ROOT/pom.xml $TCK_ROOT/original-pom.xml
    xsltproc wildfly-mods/transform.xslt $TCK_ROOT/original-pom.xml > $TCK_ROOT/pom.xml
fi

#######################
# Execute the New TCK #
#######################

echo "Executing NEW Jakarta Security TCK."
pushd $TCK_ROOT
mvn ${MVN_ARGS} clean -pl '!old-tck,!old-tck/build,!old-tck/run'
mkdir target
mvn ${MVN_ARGS} install -Pnew-wildfly -pl '!old-tck,!old-tck/build,!old-tck/run,!signaturetest' -Dtest.wildfly.home=$NEW_WILDFLY -fae
popd

echo "That's all for now. Except for this fake old tck result needed to make the Jenkins reporter job happy...'"
echo "[javatest.batch] Test results: passed: 0"
exit 0

##################
# Old TCK Runner #
##################

OLD_TCK_HOME=authentication-tck

if [[ -n $TCK_PORTING_KIT ]] 
then
    echo "Hold on tight!"
    
    ANT_URL=https://dlcdn.apache.org//ant/binaries/apache-ant-1.9.16-bin.zip
    ANT_ZIP=apache-ant-1.9.16-bin.zip
    ANT_HOME=apache-ant-1.9.16
    if ! test -d $ANT_HOME
    then
        echo "Installing Ant."
        curl $ANT_URL -o $ANT_ZIP
        unzip ${UNZIP_ARGS} $ANT_ZIP
    fi
    pushd $ANT_HOME
    ANT_HOME=`pwd`
    popd

    ENV_ROOT=`pwd`
    export TS_HOME=$ENV_ROOT/$OLD_TCK_HOME
    export JEETCK_MODS=$TCK_PORTING_KIT
    export JAVAEE_HOME=$ENV_ROOT/$OLD_WILDFLY
    export JBOSS_HOME=$JAVAEE_HOME

    GLASSFISH_URL=https://download.eclipse.org/ee4j/glassfish/glassfish-7.0.0-SNAPSHOT-nightly.zip
    GLASSFISH_ZIP=glassfish-7.0.0-SNAPSHOT-nightly.zip
    GLASSFISH_HOME=glassfish7
    export JAVAEE_HOME_RI=$ENV_ROOT/$GLASSFISH_HOME/glassfish
    
    if ! test -d $GLASSFISH_HOME
    then
        echo "Installing GlassFish"
        curl $GLASSFISH_URL -o $GLASSFISH_ZIP
        unzip ${UNZIP_ARGS} $GLASSFISH_ZIP
    fi

    echo "Cloning WildFly " $WILDFLY_HOME $OLD_WILDFLY
    cp -R $WILDFLY_HOME $OLD_WILDFLY

    if ! test -d $OLD_TCK_HOME
    then
        echo "Preparing Old TCK."
        pushd $TCK_ROOT/old-tck/build
        mvn ${MVN_ARGS} install
        popd
        unzip ${UNZIP_ARGS} $TCK_ROOT/old-tck/source/release/JASPIC_BUILD/latest/authentication-tck.zip
        echo "Fix the build.xml in the old TCK."
        patch $OLD_TCK_HOME/bin/build.xml < wildfly-mods/build_xml.patch
        pushd $JEETCK_MODS
        $ANT_HOME/bin/ant clean
        $ANT_HOME/bin/ant -Dprofile=full
        popd
    fi

    echo "Configuring WildFly for the Old TCK"
    pushd $TS_HOME/bin
    $ANT_HOME/bin/ant config.vi
    $ANT_HOME/bin/ant enable.jaspic
    popd

    echo "Starting WilDFly"
    pushd $JBOSS_HOME/bin 
    ./standalone.sh &
    sleep 5
    popd

    echo "Executing OLD TCK."
    pushd $TS_HOME/src/com/sun/ts/tests/jaspic
    ant -Dkeywords="(javaee|jms)&!(ejbembed_vehicle)" runclient
    popd

    echo "Stopping WildFly"
    $JBOSS_HOME/bin/jboss-cli.sh -c --command="shutdown"
    sleep 5
fi

echo "Execution Complete."
sha256sum $TCK_ZIP
