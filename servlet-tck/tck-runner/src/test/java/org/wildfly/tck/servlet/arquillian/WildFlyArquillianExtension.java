/*
 * Copyright The WildFly Authors
 * SPDX-License-Identifier: Apache-2.0
 */

package org.wildfly.tck.servlet.arquillian;

import java.util.List;

import org.jboss.arquillian.container.spi.client.deployment.DeploymentDescription;
import org.jboss.arquillian.container.test.impl.client.deployment.AnnotationDeploymentScenarioGenerator;
import org.jboss.arquillian.container.test.spi.client.deployment.DeploymentScenarioGenerator;
import org.jboss.arquillian.core.spi.LoadableExtension;
import org.jboss.arquillian.test.spi.TestClass;
import org.jboss.shrinkwrap.api.Archive;
import org.jboss.shrinkwrap.api.spec.WebArchive;

/**
 * @author <a href="mailto:jperkins@redhat.com">James R. Perkins</a>
 */
public class WildFlyArquillianExtension implements LoadableExtension {
    @Override
    public void register(final ExtensionBuilder builder) {
        builder.override(DeploymentScenarioGenerator.class, AnnotationDeploymentScenarioGenerator.class, ScenarioBasedUpdater.class);
    }

    /**
     * Hacks the {@link AnnotationDeploymentScenarioGenerator} to add missing resources in deployments.
     */
    public static class ScenarioBasedUpdater extends AnnotationDeploymentScenarioGenerator {

        @Override
        public List<DeploymentDescription> generate(TestClass testClass) {
            final List<DeploymentDescription> descriptions = super.generate(testClass);

            for (DeploymentDescription description : descriptions) {
                final Archive<?> applicationArchive = description.getArchive();
                if (applicationArchive instanceof WebArchive webArchive) {

                    final var className = testClass.getName();

                    // This works around a future TCK challenge and can be removed when it's resolved
                    if (className.equals("servlet.tck.pluggability.api.jakarta_servlet.registration.RegistrationTests")) {
                        webArchive.addClass(servlet.tck.api.jakarta_servlet.servletcontext30.AddFilterString.class);
                    }
                    // These two tests need a security domain to be enabled. We add a default security domain for
                    // BASIC authentication. For these two cases we'll simply use a jboss-web.xml to enable the security
                    // domain.
                    if (className.equals("servlet.tck.spec.security.clientcert.ClientCertTests") ||
                            className.equals("servlet.tck.spec.security.clientcertanno.ClientCertAnnoTests")) {
                        webArchive.addAsWebInfResource(getClass().getResource("/jboss-web.xml"), "jboss-web.xml");
                    }

                    // This works around a TCK challenge and can be removed once a release including
                    // https://github.com/jakartaee/servlet/issues/691 is out.
                    if (className.equals("servlet.tck.spec.defaultmapping.DefaultMappingTests")) {
                        webArchive.addClasses(servlet.tck.spec.requestmap.TestServlet1.class,
                                servlet.tck.spec.requestmap.TestServlet2.class,
                                servlet.tck.spec.requestmap.TestServlet3.class,
                                servlet.tck.spec.requestmap.TestServlet4.class,
                                servlet.tck.spec.requestmap.TestServlet5.class);
                    }
                }
            }

            return descriptions;
        }

    }
}
