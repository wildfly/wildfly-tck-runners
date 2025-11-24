# Jakarta Data TCK Runner for WildFly

This project is a Jakarta Data TCK runner for WildFly. It allows execution of
the in-container Jakarta Data TCK tests against WildFly.

## Running against a WildFly provisioned by the TCK runner

By default, the runner will provision a WildFly instance that includes the `jakarta-data` layer.

Use the `wildfly.feature.pack.groupId`, `wildfly.feature.pack.artifactId` and `version.org.wildfly.wildfly` system properties to control the GAV of the feature pack used to provision the installation. All have default values; see `wildfly-runner/pom.xml` for the current defaults. 

## Running against an externally provisioned WildFly

To disable local provisioning and instead run against a WildFly installation that was provisioned externally, use the `jboss-home` system property to point at your installation.

`mvn clean verify -Djboss.home=/home/developer/my-wildfly`

The TCK runner will execute a CLI script to attempt to add the `jakarta-data` subsystem if it's not already present in the `standalone.xml` configuration. (If it is present, the script will do nothing.) 

## Other configuration settings

Use the `version.org.hibernate.orm` system property to control the version of Hibernate Data Repositories and Hibernate ORM used. Use the `version.jakarta.persistence` system property to control the version of the Jakarta Persistence API.

## Simple testing of WildFly Preview

By default, this project is set up to test a particular version of standard WildFly, using various dependency version and feature pack artifact ids appropriate for that version. Use the `wildfly-preview` profile (activated with `-Pwildfly-preview`) to simply change those settings to ones appropriate for testing a WildFly Preview release of the same version.