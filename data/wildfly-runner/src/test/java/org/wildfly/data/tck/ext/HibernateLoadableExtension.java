package org.wildfly.data.tck.ext;

import org.jboss.arquillian.container.test.spi.client.deployment.ApplicationArchiveProcessor;
import org.jboss.arquillian.core.spi.LoadableExtension;

public class HibernateLoadableExtension implements LoadableExtension {

    @Override
    public void register(ExtensionBuilder builder) {
        builder.service(ApplicationArchiveProcessor.class, JPAProcessor.class);
        //builder.service(AuxiliaryArchiveAppender.class, TCKFrameworkAppender.class);
    }
}
