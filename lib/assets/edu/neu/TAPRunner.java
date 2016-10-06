package edu.neu;

import java.util.List;
import java.util.ArrayList;
import java.util.Collections;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;

import org.junit.runner.JUnitCore;
import org.junit.runner.Computer;
import org.junit.runner.Result;
import org.junit.runner.notification.Failure;

import java.net.URL;
import java.net.URLClassLoader;
import org.junit.internal.Classes;

public class TAPRunner {

  public static void main(String[] args) {
    JUnitCore core = new JUnitCore();
    ByteArrayOutputStream tapOut = new ByteArrayOutputStream();
    ByteArrayOutputStream delayedStdout = new ByteArrayOutputStream();
    PrintStream origStdout = System.out;
    
    core.addListener(new TAPListener(new PrintStream(tapOut, true)));
    System.setOut(new PrintStream(delayedStdout, true));

    List<Class<?>> classes = new ArrayList<Class<?>>();
    for (String arg : args) {
      try {
        //        classes.add(Thread.currentThread().getContextClassLoader().loadClass(arg));
        classes.add(Classes.getClass(arg));
      } catch (ClassNotFoundException e) {
        System.err.println("TAPRunner could not find class [" + arg + "]");
        System.err.println(e.getMessage());
        e.printStackTrace(System.err);
        for (URL url : ((URLClassLoader) (Thread.currentThread()
                                              .getContextClassLoader())).getURLs())
          System.err.println(url.getFile());
        System.exit(1);
      }
    }

    try {
      boolean fail = false;
      for (Class<?> c : classes) {
        Result result = core.run(c);
        if (!result.wasSuccessful()) fail = true;
      }
      System.out.flush();
      delayedStdout.flush();
      // System.setOut(origStdout);
      String[] tapLines = tapOut.toString().split("\n");
      origStdout.println(tapLines[0]);
      origStdout.println(tapLines[1]);
      String testOutput = delayedStdout.toString();
      if (testOutput.length() > 0) {
        origStdout.println("# Unexpected test output:");
        String[] lines = delayedStdout.toString().split("\n");
        if (lines.length < 100) {
          for (String line : lines)
            origStdout.println("# " + line);
        } else {
          origStdout.println("# " + lines.length + " lines (elided for brevity)");
        }
      }
      for (int i = 2; i < tapLines.length; i++)
        origStdout.println(tapLines[i]);
      System.exit(0);
    } catch (Exception e) {
      System.err.println("A test unexpectedly errored, instead of passed or failed:");
      System.err.println(e.toString());
      System.err.println("Standard out:");
      System.err.println(delayedStdout.toString());
      System.exit(1);
    }
  }
}
