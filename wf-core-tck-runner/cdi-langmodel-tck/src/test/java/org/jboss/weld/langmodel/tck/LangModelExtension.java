/*
 * Copyright \(c\) "2022" Red Hat and others
 *
 * This program and the accompanying materials are made available under the Apache Software License 2.0 which is available at:
 *  https://www.apache.org/licenses/LICENSE-2.0.
 *
 *  SPDX-License-Identifier: Apache-2.0
 */

package org.jboss.weld.langmodel.tck;


import jakarta.enterprise.inject.build.compatible.spi.BuildCompatibleExtension;
import jakarta.enterprise.inject.build.compatible.spi.Enhancement;
import jakarta.enterprise.lang.model.declarations.ClassInfo;
import org.jboss.cdi.lang.model.tck.LangModelVerifier;

public class LangModelExtension implements BuildCompatibleExtension {

    public static int ENHANCEMENT_INVOKED = 0;

    @Enhancement(types = LangModelVerifier.class)
    public void run(ClassInfo clazz) {
        ENHANCEMENT_INVOKED++;
        LangModelVerifier.verify(clazz);
    }
}
