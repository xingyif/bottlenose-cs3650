package edu.neu;

import java.io.PrintStream;
import java.text.NumberFormat;
import java.util.List;
import java.util.ArrayList;
import java.util.HashMap;
import java.lang.annotation.Annotation;
import java.lang.annotation.Target;
import java.lang.annotation.Retention;

import org.junit.runner.Description;
import org.junit.runner.Result;
import org.junit.runner.notification.Failure;
import org.junit.runner.notification.RunListener;

public class TAPListener extends RunListener {

  private final PrintStream writer;
  
  private final ArrayList<Description> tests = new ArrayList<>();
  private final HashMap<Description, Failure> failures = new HashMap<>();

  public TAPListener(PrintStream writer) {
    this.writer = writer;
  }

  @Override
  public void testRunFinished(Result result) {
    getWriter().println("TAP version 13");
    getWriter().println(String.format("1..%d", this.tests.size()));
    printHeader(result.getRunTime());
    printTests();
    // printFooter(result);
  }

  @Override
  public void testStarted(Description description) {
    if (description.isTest()) {
      this.tests.add(description);
    }
  }

  @Override
  public void testFinished(Description description) {
  }

  @Override
  public void testFailure(Failure failure) {
    this.failures.put(failure.getDescription(), failure);
  }

  @Override
  public void testIgnored(Description description) {
    tests.remove(description);
  }

  /*
   * Internal methods
   */

  private PrintStream getWriter() {
    return writer;
  }

  protected void printHeader(long runTime) {
    getWriter().println("# Time: " + elapsedTimeAsString(runTime));
  }

  protected void printFailures(Result result) {
    List<Failure> failures = result.getFailures();
    if (failures.isEmpty()) {
      return;
    }
    if (failures.size() == 1) {
      getWriter().println("There was " + failures.size() + " failure:");
    } else {
      getWriter().println("There were " + failures.size() + " failures:");
    }
    int i = 1;
    for (Failure each : failures) {
      printFailure(each);
    }
  }

  protected String escapeString(String s) {
    if (s == null)
      return "<null>";
    return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n");
  }
  
  protected void printFailure(Failure f) {
    if (f == null) return;
    getWriter().println(String.format("  header: \"%s\"", escapeString(f.getTestHeader())));
    getWriter().println(String.format("  message: \"%s\"", escapeString(f.getMessage())));
    getWriter().println(String.format("  stack: ["));
    String trace = f.getTrace();
    if (trace == null) {
      getWriter().println(String.format("    \"<no trace available>\","));
    } else {
      for (String line : f.getTrace().split("\n")) {
        getWriter().println(String.format("    \"%s\",", escapeString(line)));
      }
    }
    getWriter().println(String.format("    ]"));
  }

  protected void printTests() {
    for (int i = 0; i < this.tests.size(); i++) {
      Description d = this.tests.get(i);
      if (this.failures.containsKey(d)) {
        getWriter().println(String.format("not ok %d %s", i + 1, d.getDisplayName()));
      } else {
        getWriter().println(String.format("ok %d %s", i + 1, d.getDisplayName()));
      }
      getWriter().println("# More information");
      getWriter().println("  ---");
      printFailure(this.failures.get(d));
      TestWeight w = d.getAnnotation(TestWeight.class);
      if (w != null) {
        getWriter().println(String.format("  weight: %f", w.weight()));
      }
      ArrayList<Annotation> relevantAnns = new ArrayList<>();
      for (Annotation a : d.getAnnotations()) {
        if (a != w && !(a instanceof org.junit.Test))
          relevantAnns.add(a);
      }
      if (relevantAnns.size() > 0) {
        getWriter().println("  annotations:");
        for (Annotation a : relevantAnns)
          getWriter().println(String.format("    - %s", a.toString()));
      }
      getWriter().println("  ...");
    }
  }

  protected void printFooter(Result result) {
    if (result.wasSuccessful()) {
      getWriter().println();
      getWriter().print("OK");
      getWriter().println(" (" + result.getRunCount() + " test" + (result.getRunCount() == 1 ? "" : "s") + ")");

    } else {
      getWriter().println();
      getWriter().println("FAILURES!!!");
      getWriter().println("Tests run: " + result.getRunCount() + ",  Failures: " + result.getFailureCount());
    }
    getWriter().println();
  }

  /**
   * Returns the formatted string of the elapsed time. Duplicated from
   * BaseTestRunner. Fix it.
   */
  protected String elapsedTimeAsString(long runTime) {
    return NumberFormat.getInstance().format((double) runTime / 1000);
  }
}
