package org.jboss.weld.tck.wildfly;


import org.jboss.arquillian.container.spi.client.container.DeploymentExceptionTransformer;
import org.jboss.arquillian.core.spi.LoadableExtension;
import org.jboss.as.arquillian.container.ExceptionTransformer;

public class WildFlyExtension implements LoadableExtension {

    private static final String MANAGED_CONTAINER_CLASS = "org.jboss.as.arquillian.container.managed.ManagedDeployableContainer";
    private static final String REMOTE_CONTAINER_CLASS = "org.jboss.as.arquillian.container.remote.RemoteDeployableContainer";

    public void register(ExtensionBuilder builder) {

        if (Validate.classExists(MANAGED_CONTAINER_CLASS) || Validate.classExists(REMOTE_CONTAINER_CLASS)) {

            // Override the default NOOP exception transformer
            builder.override(DeploymentExceptionTransformer.class, ExceptionTransformer.class,
                             WildFlyExceptionTransformer.class);

        }
    }

}
