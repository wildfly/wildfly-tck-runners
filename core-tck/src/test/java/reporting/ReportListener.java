/*
 * Copyright (c) "2022" Red Hat and others
 *
 * This program and the accompanying materials are made available under the
 * Apache Software License 2.0 which is available at:
 * https://www.apache.org/licenses/LICENSE-2.0.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 */
package reporting;

import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;

import org.junit.platform.engine.TestExecutionResult;
import org.junit.platform.engine.reporting.ReportEntry;
import org.junit.platform.launcher.TestExecutionListener;
import org.junit.platform.launcher.TestIdentifier;
import org.junit.platform.launcher.TestPlan;

/**
 * An example Junit5 TestExecutionListener that collects the emitted ReportEntry records
 * and writes them to target/ReportListener.txt
 */
public class ReportListener implements TestExecutionListener {
    private ArrayList<String> reportEntries = new ArrayList<>();

    @Override
    public void testPlanExecutionStarted(TestPlan testPlan) {
        reportEntries.add(String.format("testPlanExecutionStarted, roots=%s", testPlan.getRoots()));
    }

    @Override
    public void testPlanExecutionFinished(TestPlan testPlan) {
        reportEntries.add(String.format("testPlanExecutionFinished, roots=%s", testPlan.getRoots()));
        try(FileWriter writer = new FileWriter("target/ReportListener.txt")) {
            for(String entry : reportEntries) {
                writer.append(String.format("%s\n", entry));
            }
            writer.flush();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void dynamicTestRegistered(TestIdentifier testIdentifier) {
        reportEntries.add(String.format("dynamicTestRegistered, %s", testIdentifier.getDisplayName()));
    }

    @Override
    public void executionSkipped(TestIdentifier testIdentifier, String reason) {
        reportEntries.add(String.format("executionSkipped, %s; %s", testIdentifier.getDisplayName(), reason));
    }

    @Override
    public void executionStarted(TestIdentifier testIdentifier) {
        reportEntries.add(String.format("executionStarted, %s", testIdentifier.getDisplayName()));
    }

    @Override
    public void executionFinished(TestIdentifier testIdentifier, TestExecutionResult testExecutionResult) {
        reportEntries.add(String.format("executionFinished, %s", testIdentifier.getDisplayName()));
    }

    @Override
    public void reportingEntryPublished(TestIdentifier testIdentifier, ReportEntry entry) {
        System.out.printf("%s: %s\n", testIdentifier.getDisplayName(), entry.getKeyValuePairs());
        reportEntries.add(entry.toString());
    }
}
