#! /bin/bash

set -e
MVN_ARGS="-B -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn"
UNZIP_ARGS="-o -q"
clean=false
cleanOnly=false
skipNewTck=false
verboseArgs=""
status=0
newTckStatus=0
oldTckStatus=0

fail() {
    echo "${1}"
    exit 1
}

printArgHelp() {
    echo -e "${1}\t${2}"
}

printHelp() {
    echo "Runs the Jakarta Faces TCK optionally running the old-tck if the TCK_PORTING_KIT environment variable is set to a valid path."
    printArgHelp "-c" "Cleans the environment before running."
    printArgHelp "-C" "Cleans the environment, then exits without running any tests."
    printArgHelp "-h" "Displays the help text."
    printArgHelp "-s" "Skips the running of the new TCK."
    printArgHelp "-v" "Runs the commands verbosely."
    echo "Usage: ${0##*/}"
}

safeRun() {
    set +e
    cmd="$*"
    ${cmd}
    status=$?
    set -e
}

addModule() {
    local MODULE_NAME="${1}"
    local MODULE_RESOURCES="${2}"
    local MODULE_ARGS="${3}"
    safeRun "${JBOSS_HOME}/bin/jboss-cli.sh" --command="module remove --name=${MODULE_NAME}"
    CLI_COMMAND="module add --name=${MODULE_NAME} --resources=${MODULE_RESOURCES} ${MODULE_ARGS}"
    echo "Adding ${MODULE_NAME} module"
    "${JBOSS_HOME}/bin/jboss-cli.sh" --command="${CLI_COMMAND}"
}

checkExitStatus() {
    exitStatus=0
    if [ ${newTckStatus} -ne 0 ]; then
        echo "The new TCK run failed with ${newTckStatus}."
        exitStatus=1
    fi
    if [ ${oldTckStatus} -ne 0 ]; then
        echo "The old TCK run failed with ${oldTckStatus}."
        exitStatus=1
    fi
    if [ ${exitStatus} -ne 0 ]; then
        echo "At least one of the TCK runs failed. See above for more details."
        exit ${exitStatus}
    fi
}

# Parse incoming parameters
while getopts ":cChsv" opt; do
    case "${opt}" in
        c)
            clean=true
            ;;
        C)
            clean=true
            cleanOnly=true
            ;;
        h)
            printHelp
            exit 0
            ;;
        s)
            skipNewTck=true
            ;;
        v)
            UNZIP_ARGS="-o"
            MVN_ARGS=""
            verboseArgs="-v"
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

# Configure the working directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR="$(dirname "${SCRIPT_DIR}")"
WORK_DIR="${BASE_DIR}/work"
# Clean if applicable
if [ ${clean} == true ]; then
    rm -rf ${verboseArgs} "${WORK_DIR}"
    if [ ${cleanOnly} == true ]; then
        exit
    fi
fi
# Create the directory if required
if [ ! -d "${WORK_DIR}" ]; then
    echo "Creating work directory ${WORK_DIR}"
    mkdir -p "${WORK_DIR}"
fi
if [ -z "${TCK_VERSION}" ]; then
    TCK_VERSION="4.0.2"
fi
TCK_ZIP="${WORK_DIR}/jakarta-faces-tck-${TCK_VERSION}.zip"
TCK_URL=https://download.eclipse.org/jakartaee/faces/4.0/jakarta-faces-tck-${TCK_VERSION}.zip
TCK_HOME="${WORK_DIR}/faces-tck-${TCK_VERSION}"
TCK_ROOT=$TCK_HOME/tck
WILDFLY_HOME=wildfly/target/wildfly
NEW_WILDFLY="${WORK_DIR}/servers/new-wildfly"
OLD_WILDFLY="${WORK_DIR}/servers/old-wildfly"

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
        fail "JBOSS_HOME points to invalid location ${JBOSS_HOME}"
    fi
else
    echo "JBOSS_HOME Is NOT Set."
    if ! test -d $WILDFLY_HOME
    then
        WILDFLY_HOME="${WORK_DIR}/wildfly"
        echo "Provisioning WildFly to ${WILDFLY_HOME}."
        pushd "${BASE_DIR}/wildfly"
        mvn ${MVN_ARGS} install -Dprovision.skip=false -Dconfigure.skip=true -Dwildfly.home="${WILDFLY_HOME}"
        popd
    fi
fi
# At this point WILDFLY_HOME points to the clean server.

####################################
# Create a copy to run the new TCK #
####################################

# First delete any existing clone.
if test -d "${WORK_DIR}"/servers
then
    echo "Deleting existing 'servers' directory."
    rm -fR ${verboseArgs} "${WORK_DIR}"/servers
fi

mkdir ${verboseArgs} "${WORK_DIR}"/servers
echo "Cloning WildFly  $WILDFLY_HOME $NEW_WILDFLY"
cp -R ${verboseArgs} $WILDFLY_HOME $NEW_WILDFLY

pushd "${BASE_DIR}/wildfly"
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
    pushd "${WORK_DIR}"
    echo "Configuring TCK."
    unzip ${UNZIP_ARGS} $TCK_ZIP
    cp $TCK_ROOT/pom.xml $TCK_ROOT/original-pom.xml
    # We need to add a profile which adds the Mojarra dependency for compiling
    xsltproc "${BASE_DIR}/wildfly-mods/transform.xslt" "${TCK_ROOT}/original-pom.xml" > "${TCK_ROOT}/pom.xml"
    popd
fi

#######################
# Execute the New TCK #
#######################

if [ ${skipNewTck} == true ]; then
    echo "Skipping running the NEW Jakarta Faces TCK"
else
    echo "Executing NEW Jakarta Faces TCK."
    pushd $TCK_ROOT
    safeRun mvn ${MVN_ARGS} clean install -pl '!old-tck,!old-tck/build,!old-tck/run' \
        -P 'new-wildfly,wildfly-ci-managed,!glassfish-ci-managed' \
        -Dwildfly.dir="${NEW_WILDFLY}" -fae
    newTckStatus=${status}
    # Run the reporting
    safeRun mvn ${MVN_ARGS} org.apache.maven.plugins:maven-site-plugin:3.12.1:site -pl '!old-tck,!old-tck/build,!old-tck/run' \
        -P 'new-wildfly,wildfly-ci-managed,!glassfish-ci-managed' \
        -DskipAssembly=true surefire-report:failsafe-report-only \
        -Daggregate=true
    if [ ${status} -ne 0 ]; then
      echo "Reporting for the new TCK has failed to generate the test summary."
    fi
    popd
fi

##################
# Old TCK Runner #
##################

export OLD_TCK_HOME=$TCK_ROOT/old-tck/source/release/JSF_BUILD/latest/faces-tck

pushd "${WORK_DIR}"
if [[ -n $TCK_PORTING_KIT ]] 
then
    echo "Hold on tight!"
    
    ANT_URL=https://dlcdn.apache.org//ant/binaries/apache-ant-1.9.16-bin.zip
    ANT_CONTRIB_URL=https://sourceforge.net/projects/ant-contrib/files/ant-contrib/1.0b3/ant-contrib-1.0b3-bin.zip/download
    ANT_ZIP=apache-ant-1.9.16-bin.zip
    ANT_CONTRIB_ZIP=ant-contrib-1.0b3-bin.zip
    export ANT_HOME="${WORK_DIR}"/apache-ant-1.9.16
    export PATH=$ANT_HOME/bin:$PATH
    if ! test -d $ANT_HOME
    then
        echo "Installing Ant."
        if [ ! -f "${ANT_ZIP}" ]; then
            curl $ANT_URL -o $ANT_ZIP
        fi
        unzip ${UNZIP_ARGS} $ANT_ZIP
        if [ ! -f "${ANT_CONTRIB_ZIP}" ]; then
            wget -q --no-check-certificate $ANT_CONTRIB_URL -O $ANT_CONTRIB_ZIP
        fi
        unzip ${UNZIP_ARGS} ${ANT_CONTRIB_ZIP}
        mv ant-contrib/ant-contrib-1.0b3.jar $ANT_HOME/lib
    fi
    ENV_ROOT="${WORK_DIR}"
    export TS_HOME=$OLD_TCK_HOME
    export TS_HOME_ROOT=${WORK_DIR}
    export JEETCK_MODS=$TCK_PORTING_KIT
    export JAVAEE_HOME=$OLD_WILDFLY
    export JBOSS_HOME=$JAVAEE_HOME

    GLASSFISH_URL=https://download.eclipse.org/ee4j/glassfish/glassfish-7.0.0.zip
    GLASSFISH_ZIP=glassfish-7.0.0.zip
    GLASSFISH_HOME=glassfish7
    export JAVAEE_HOME_RI=$ENV_ROOT/$GLASSFISH_HOME/glassfish
    export DERBY_HOME=$ENV_ROOT/$GLASSFISH_HOME/javadb

    echo "Creating Environment File."
    echo "# Faces TCK Environment." > environment
    echo "export TS_HOME=$TS_HOME" >> environment
    echo "export JEETCK_MODS=$JEETCK_MODS" >> environment
    echo "export JAVAEE_HOME=$JAVAEE_HOME" >> environment
    echo "export JBOSS_HOME=$JBOSS_HOME" >> environment
    echo "export JAVAEE_HOME_RI=$JAVAEE_HOME_RI" >> environment
    echo "export DERBY_HOME=$DERBY_HOME" >> environment

    if ! test -d $GLASSFISH_HOME
    then
        echo "Installing GlassFish"
        curl -L $GLASSFISH_URL -o $GLASSFISH_ZIP
        unzip ${UNZIP_ARGS} $GLASSFISH_ZIP
    fi

    echo "Cloning WildFly " $WILDFLY_HOME $OLD_WILDFLY
    cp -R $WILDFLY_HOME $OLD_WILDFLY
    popd # out of WORK_DIR

    if ! test -d $OLD_TCK_HOME
    then
        echo "Preparing Old TCK."
        pushd $TCK_ROOT/old-tck/build
        mvn ${MVN_ARGS} install -Dtck.mode=platform
        popd
        
        pushd $TCK_ROOT/old-tck/source/release/JSF_BUILD/latest/
        echo "about to unzip $TCK_ROOT/old-tck/source/release/JSF_BUILD/latest/faces-tck.zip from ${WORK_DIR}"
        # wildfly-tck-runners/faces will contain faces-tck folder
        unzip ${UNZIP_ARGS} faces-tck.zip
        popd
        pushd $JEETCK_MODS
        $ANT_HOME/bin/ant clean
        $ANT_HOME/bin/ant -Dprofile=full
        popd
    fi

    echo "Configuring WildFly for the Old TCK"
    pushd $TS_HOME/bin
    # switch from jaspic.home to jsf.home and javaee.home to faces.home
    # update javaee.classes=
    echo "ignore the ant config.vi for now until we make that work or not"
    # $ANT_HOME/bin/ant config.vi
    sed -i 's/javaee.classes=/jsf.classes=/1' -i $TS_HOME/bin/ts.jte

    sed -i 's/jaspic.home/jsf.home/1' -i $TS_HOME/bin/ts.jte
    sed -i 's/javaee.home/faces.home/1' -i $TS_HOME/bin/ts.jte
    sed -i '/webServerHost=/ s/=.*/=localhost/' -i $TS_HOME/bin/ts.jte
    sed -i '/webServerPort=/ s/=.*/=8080/' -i $TS_HOME/bin/ts.jte
    popd
    pushd $TS_HOME/bin
    # Delete the old file if it exists
    if [ -f "${TS_HOME}/ts.jte" ]; then
        rm -v "${TS_HOME}/ts.jte"
    fi
    ln -s $TS_HOME/bin/ts.jte $TS_HOME/ts.jte
    popd

    MODULE_RESOURCES=
    for file in "${TS_HOME}"/lib/*.jar
    do
        if [ -z "${MODULE_RESOURCES}" ]; then
            MODULE_RESOURCES="${file}"
        else
            MODULE_RESOURCES="${MODULE_RESOURCES}:${file}"
        fi
    done
    addModule "com.sun.ts" \
        "${TCK_ROOT}/old-tck/source/classes/:${MODULE_RESOURCES}:${JEETCK_MODS}/output/lib/jboss-porting.jar" \
        "--dependencies=org.wildfly.common,org.wildfly.security.elytron,javaee.api,org.jboss.logging,org.jboss.ejb-client,jakarta.faces.api,jakarta.servlet.api --export-dependencies=javax.rmi.api,org.apache.derby.embedded"

    addModule "org.apache.derby.client" \
        "${DERBY_HOME}/lib/derbyclient.jar:${DERBY_HOME}/lib/derbyshared.jar:${DERBY_HOME}/lib/derbytools.jar" \
        "--dependencies=jakarta.servlet.api,jakarta.transaction.api"

    addModule "org.apache.derby.embedded" \
        "${DERBY_HOME}/lib/derby.jar:${DERBY_HOME}/lib/derbyshared.jar:${DERBY_HOME}/lib/derbytools.jar" \
        "--dependencies=javax.api,jakarta.servlet.api,jakarta.transaction.api"

    echo "Starting WildFly"
    pushd $JBOSS_HOME/bin 
    ./standalone.sh  &
    sleep 5

	NUM=0
	while true
	do

	NUM=$[$NUM + 1]
	if (("$NUM" > "20")); then
        echo "Successful application server startup not confirmed! Will run tests anyway."
	    break
	fi

	if ./jboss-cli.sh --connect command=':read-attribute(name=server-state)' | grep running; then
	    echo "Server is running"
	    break
	fi
	    echo "Server is not yet running"
	    sleep 2
	done
    popd

    # Add the global module, required to run after the TCK and WildFly both exist due to dependencies required.
    "${JBOSS_HOME}/bin/jboss-cli.sh" -c --command="/subsystem=ee:write-attribute(name=global-modules, value=[{name=com.sun.ts}, {name=org.apache.derby.client}, {name=org.apache.derby.embedded}])"

    TCK_RUN_ARGS=""
    TEST_PATH_BASE="${TS_HOME}/src"
    # Are we running a single path?
    if [ -z "${TEST_PATH}" ]; then
        TEST_PATH="${TEST_PATH_BASE}/com/sun/ts/tests/jsf"
        TCK_RUN_ARGS="run.all"
    else
        TEST_PATH="${TEST_PATH_BASE}/${TEST_PATH}"
        TCK_RUN_ARGS="runclient"
    fi

    if [ ! -d "${TEST_PATH}" ]; then
        fail "Test path ${TEST_PATH} does not exist."
    fi

    echo "Executing OLD TCK."
    pushd "${TEST_PATH}"
    ant -Dutil.dir="${TCK_HOME}" -Djboss.deploy.dir="${JBOSS_HOME}/standalone/deployments" deploy.all
    echo "Now really Executing OLD TCK."
    safeRun ant -Dutil.dir="${TCK_HOME}" ${TCK_RUN_ARGS}
    oldTckStatus=${status}
    popd

    echo "Stopping WildFly"
    "${JBOSS_HOME}/bin/jboss-cli.sh" -c --command="shutdown"
    echo "Stopping Derby"
    pushd $DERBY_HOME/bin
    ./stopNetworkServer &
    popd
    sleep 5
fi

checkExitStatus
echo "Execution Complete."
sha256sum $TCK_ZIP
