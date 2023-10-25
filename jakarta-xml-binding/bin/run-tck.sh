#! /bin/bash

set -e

# Global variables
verbose=false
setupOnly=false

# Functions

fail() {
    echo "${1}"
    exit 1
}

addToClassPath() {
    # Filter out the codemode.jar from ${TCK_CLASS_PATH} to get these two tests work with xerces removal
    # xml_schema/msData/datatypes/Facets/Schemas/jaxb/IDREFS_length006_395.html\#IDREFS_length006_395
    # xml_schema/msData/datatypes/Facets/Schemas/jaxb/NMTOKENS_length006_438.html\#NMTOKENS_length006_438
    if [ -d "${1}" ]; then
        TCK_CLASS_PATH="${TCK_CLASS_PATH}$(find "${1}" -name "*.jar" -not -name "codemodel*.jar" | tr '\n' : )"
    else
        echo "Directory ${1} does not exist."
    fi
}

createDir() {
    if [ ! -d "${1}" ]; then
        mkdir -p "${1}"
    fi
}

killAgent() {
    pgrep -f com.sun.javatest.agent.AgentMain | xargs kill -9 &> /dev/null || return 0
}

logDebug() {
    if [ ${verbose} == true ]; then
        echo -e "${1}"
    fi
}

# Parse incoming parameters
while getopts ":sv" opt; do
    case "${opt}" in
        s)
            setupOnly=true
            ;;
        v)
            verbose=true
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

shift $((OPTIND - 1))

# Set the default directory for the base TCK home
if [ -z "${WORK_DIR}" ]; then
    WORK_DIR="/tmp/jakarta-xml-bind"
fi
TCK_HOME="${WORK_DIR}/xml-binding-tck"
TCK_LOG_DIR="${WORK_DIR}/logs"
createDir "${WORK_DIR}"
createDir "${TCK_LOG_DIR}"
if [ -d "${WORK_DIR}/work_directory" ]; then
    logDebug "Deleting ${WORK_DIR}/work_directory"
    rm -rf "${WORK_DIR}/work_directory"
fi

if [ -z "${JBOSS_HOME}" ]; then
    # Does wildfly.zip exist in the WORK_DIR?
    WILDFLY_ZIP="${HOME}/wildfly.zip"
    if [ ! -f "${WILDFLY_ZIP}" ]; then
        fail "The WildFly zip ${WILDFLY_ZIP} does not exist"
    fi
    unzip -o -q -d "${WORK_DIR}" "${WILDFLY_ZIP}"
    JBOSS_HOME="$(readlink -m "${WORK_DIR}"/wildfly-*)"
fi

# If the TCK does not exist, download it required and unzip it
if [ ! -d "${TCK_HOME}" ]; then
    # Download the TCK if it does not already exist
    TCK_ZIP="${WORK_DIR}/jakarta-xml-binding-tck-4.0.0.zip"
    if [ ! -f "${TCK_ZIP}" ]; then
        wget -O "${TCK_ZIP}" https://download.eclipse.org/jakartaee/xml-binding/4.0/jakarta-xml-binding-tck-4.0.0.zip
    fi
    logDebug "Unzipping ${TCK_ZIP} to ${WORK_DIR}"
    unzip -o -q -d "${WORK_DIR}" "${TCK_ZIP}"
fi

# update the following line in testsuite.jtd
# finder=com.sun.javatest.finder.BinaryTestFinder -binary /home/jenkins/workspace/jaxb-tck_master/jaxb-tck-build/xml-binding-tck/tests/testsuite.jtd
# to use correct setting for local machine
FIND=/home/jenkins/agent/workspace/jaxb-tck_master/jaxb-tck-build/XMLB-TCK-4.0/tests/testsuite.jtd
REPLACE=${TCK_HOME}/tests/testsuite.jtd
logDebug "sed -i \"s|${FIND}|${REPLACE}|g\" ${TCK_HOME}/testsuite.jtt"
sed -i "s|${FIND}|${REPLACE}|g" "${TCK_HOME}/testsuite.jtt"

# Setup the class path
BASE_MODULE_DIR="${JBOSS_HOME}/modules/system/layers/base"

# JAXB API
TCK_CLASS_PATH=""
addToClassPath "${BASE_MODULE_DIR}/jakarta/xml/bind/api/main/"
# Legacy implementation module
addToClassPath "${BASE_MODULE_DIR}/com/sun/xml/bind/main/"
# New implementation module
addToClassPath "${BASE_MODULE_DIR}/org/glassfish/jaxb/main/"
addToClassPath "${BASE_MODULE_DIR}/org/apache/xerces/main/"
addToClassPath "${BASE_MODULE_DIR}/jakarta/activation/api/main"
# Required for the com.sun.tools.jxc.SchemaGenerator. The options look for -cp or -classpath passed to the entry point.
# However, the TCK runner does not pass that argument so it falls back to the CLASSPATH environment variable.
CLASSPATH="${TCK_CLASS_PATH}"
export CLASSPATH

cd "${TCK_HOME}"

echo ""
echo "JAVA_HOME:      ${JAVA_HOME}"
echo "JBOSS_HOME:     ${JBOSS_HOME}"
echo "TCK_HOME:       ${TCK_HOME}"
echo "CLASSPATH       ${CLASSPATH}"

# ensure agent isn't already running
killAgent

# Prepares configuration file
echo "
INTERVIEW=com.sun.jaxb_tck.interview.JAXBTCKParameters
LOCALE=cs_CZ
QUESTION=jck.epilog
TESTSUITE=${TCK_HOME}
WORKDIR=${TCK_HOME}/work_directory
jck.concurrency.concurrency=3
jck.env.description=JAXB 4.0 TCK for WildFly
jck.env.envName=jaxb40_wildfly
jck.env.jaxb.agent.agentPassiveHost=localhost
jck.env.jaxb.agent.agentPassivePort=
jck.env.jaxb.agent.agentType=passive
jck.env.jaxb.agent.useAgentPortDefault=Yes
jck.env.jaxb.schemagen.run.schemagenWrapperClass=com.sun.jaxb_tck.lib.SchemaGen
jck.env.jaxb.schemagen.skipJ2XOptional=Yes
jck.env.jaxb.testExecute.cmdAsFile=${JAVA_HOME}/bin/java
jck.env.jaxb.testExecute.otherEnvVars=JBOSS_HOME\=${JBOSS_HOME} JAXB_HOME\=${TCK_HOME}/client JAVA_HOME\=${JAVA_HOME}
jck.env.jaxb.testExecute.otherOpts=-Xmx512m -Xms256m ${CLASSPATH}
jck.env.jaxb.xsd_compiler.defaultOperationMode=Yes
jck.env.jaxb.xsd_compiler.run.compilerWrapperClass=com.sun.jaxb_tck.lib.SchemaCompiler
jck.env.jaxb.xsd_compiler.skipValidationOptional=Yes
jck.env.testPlatform.local=Yes
jck.env.testPlatform.multiJVM=No
jck.excludeList.customFiles=${TCK_HOME}/lib/jaxb_tck40.jtx
jck.excludeList.excludeListType=custom
jck.excludeList.latestAutoCheck=No
jck.excludeList.latestAutoCheckInterval=7
jck.excludeList.latestAutoCheckMode=everyXDays
jck.excludeList.needExcludeList=Yes
jck.keywords.keywords.mode=expr
jck.keywords.needKeywords=No
jck.priorStatus.needStatus=No
jck.priorStatus.status=
jck.tests.needTests=No
jck.tests.tests=
jck.tests.treeOrFile=tree
jck.timeout.timeout=2

" > "${TCK_HOME}"/default_configuration.jti

if [ ${verbose} == true ]; then
    cat "${TCK_HOME}"/default_configuration.jti
fi

# If we're just running the setup, exit
if [ ${setupOnly} == true ]; then
    exit 0
fi

# Required for signature tests
cd ${TCK_HOME}/tests/api/signaturetest

# Starts agent
echo "Starting Agent ...."
java -server -Xmx1024m -Xms128m \
     -classpath "${TCK_HOME}/lib/javatest.jar:${TCK_HOME}/lib/jtlegacy.jar:${TCK_HOME}/classes:${CLASSPATH}" \
     -Djava.security.policy="${TCK_HOME}"/lib/tck.policy \
     com.sun.javatest.agent.AgentMain \
     -passive 1>"${TCK_LOG_DIR}/agent.log" 2>"${TCK_LOG_DIR}/agent-err.log" &
AGENT_ID=$!
echo "Agent started with ID ${AGENT_ID}"

echo "Starting test ..."
java -Xmx512m -Xms128m -classpath "${CLASSPATH}" -jar "${TCK_HOME}"/lib/javatest.jar \
      -verbose:stop,progress -testSuite "${TCK_HOME}" \
      -workdir -create "${WORK_DIR}"/work_directory \
      -config "${TCK_HOME}"/default_configuration.jti \
      -concurrency 3 -timeoutFactor 5 \
      -runtests || TEST_STATUS=$?
echo "Tests completed with ${TEST_STATUS}"

echo "Creating reports ..."
java -jar "${TCK_HOME}"/lib/javatest.jar \
      -verbose -testSuite "${TCK_HOME}" \
      -workdir "${WORK_DIR}"/work_directory \
      -config "${TCK_HOME}"/default_configuration.jti \
      -writereport "${WORK_DIR}"/report || REPORT_STATUS=$?
echo "Reporting completed with ${REPORT_STATUS}"

# Kill the agent
kill -9 ${AGENT_ID} || true