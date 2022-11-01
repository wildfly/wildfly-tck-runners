package org.wildfly.tck.core.deployment;

import org.jboss.arquillian.container.spi.event.container.BeforeDeploy;
import org.jboss.arquillian.core.api.annotation.Observes;
import org.jboss.shrinkwrap.api.Archive;

/**
 * @author <a href="mailto:jperkins@redhat.com">James R. Perkins</a>
 */
public class WildFlyDeploymentObserver {

    public void removeService(@Observes BeforeDeploy event) {
        final Archive<?> archive = event.getDeployment().getArchive();
        if (archive != null) {
            if (archive.getName()
                    .equals("CustomJsonbSerializationIT.war")) {
                archive.delete("/WEB-INF/classes/META-INF/services/jakarta.json.bind.spi.JsonbProvider");
            }
        }
    }
}
