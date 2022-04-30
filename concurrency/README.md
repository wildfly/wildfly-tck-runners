# wildfly-ee10-tckrunner-concurrency
Jakarta EE 10 Concurrency TCK Runner for WildFly

### Building and running the TCK

mvn clean test

### Inspect TCK run results

* TCK logs: target/ConcurrentTCK*.log

* WildFly server log: target/wildfly/standalone/logs/server.log

### Customize the TCK run
* Tests to include/exclude: suite.xml
* JDK Logging: logging.properties

### Under the hood

 * Maven compile phase
   * WildFly is built on target/wildfly (through Galleon provisioning)
   * WildFly is configured using src/main/resources/configure-server.cli
     * Adds TCK Security context
     * Adds global directory for server side TCK libs (target/wildfly/tck-lib)
 * Maven test-compile phase
   * Server side TCK libs are copied to WildFly global directory tck-lib
 * Maven test phase
   * TCK testsuite is run using TestNG + Arquillian


