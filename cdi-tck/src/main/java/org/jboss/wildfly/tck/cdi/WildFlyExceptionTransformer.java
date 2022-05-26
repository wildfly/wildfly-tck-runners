/*
 * Copyright \(c\) "2022" Red Hat and others
 *
 * This program and the accompanying materials are made available under the Apache Software License 2.0 which is available at:
 *  https://www.apache.org/licenses/LICENSE-2.0.
 *
 *  SPDX-License-Identifier: Apache-2.0
 */

package org.jboss.wildfly.tck.cdi;

import java.util.List;

import jakarta.enterprise.inject.spi.DefinitionException;
import jakarta.enterprise.inject.spi.DeploymentException;
import org.apache.commons.lang.exception.ExceptionUtils;
import org.jboss.arquillian.container.spi.client.container.DeploymentExceptionTransformer;

public class WildFlyExceptionTransformer implements DeploymentExceptionTransformer {

    private static final String[] DEPLOYMENT_EXCEPTION_FRAGMENTS = new String[] {
            "org.jboss.weld.exceptions.DeploymentException", "org.jboss.weld.exceptions.UnserializableDependencyException",
            "org.jboss.weld.exceptions.InconsistentSpecializationException",
            "org.jboss.weld.exceptions.NullableDependencyException" };

    private static final String[] DEFINITION_EXCEPTION_FRAGMENTS = new String[] { "org.jboss.weld.exceptions.DefinitionException" };

    public Throwable transform(Throwable throwable) {

        // Arquillian sometimes returns InvocationException with nested AS7
        // exception and sometimes AS7 exception itself
        @SuppressWarnings("unchecked")
        List<Throwable> throwableList = ExceptionUtils.getThrowableList(throwable);
        if (throwableList.isEmpty())
            return throwable;

        Throwable root = null;

        if (throwableList.size() == 1) {
            root = throwable;
        } else {
            root = ExceptionUtils.getRootCause(throwable);
        }

        if (root instanceof DeploymentException || root instanceof DefinitionException) {
            return root;
        }
        if (isFragmentFound(DEPLOYMENT_EXCEPTION_FRAGMENTS, root)) {
            return new DeploymentException(root.getMessage());
        }
        if (isFragmentFound(DEFINITION_EXCEPTION_FRAGMENTS, root)) {
            return new DefinitionException(root.getMessage());
        }
        return throwable;
    }

    private boolean isFragmentFound(String[] fragments, Throwable rootException) {
        for (String fragment : fragments) {
            if (rootException.getMessage().contains(fragment)) {
                return true;
            }
        }
        return false;
    }

}
