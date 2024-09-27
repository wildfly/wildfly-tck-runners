# Jakarta Data TCK Runner for WildFly

This project is a Jakarta Data TCK runner for WildFly. It allows execution of
the Jakarta Data TCK tests against WildFly.

## Running against a WildFly provisioned by the TCK runner

By default, the runner will provision a WildFly instance that includes the `jakarta-data` layer.

Use the `wildfly.feature.pack.artifactId`, `wildfly.feature.pack.artifactId` and `version.org.wildfly.wildfly` system properties to control the GAV of the feature pack used to provision the installation. All have default values; see `wildfly-runner/pom.xml` for the current defaults. 

## Running against an externally provisioned WildFly

To disable local provisioning and instead run against a WildFly installation that was provisioned externally, use the `jboss-home` system property to point at your installation.

`mvn clean verify -Djboss.home=/home/developer/my-wildfly`

The TCK runner will execute a CLI script to attempt to add the `jakarta-data` subsystem if it's not already present in the `standalone.xml` configuration. (If it is present, the script will do nothing.) 