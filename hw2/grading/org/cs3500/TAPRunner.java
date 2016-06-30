package org.cs3500;

import java.util.List;
import java.util.ArrayList;
import java.util.Collections;

import org.junit.runner.JUnitCore;
import org.junit.runner.Computer;
import org.junit.runner.Result;
import org.junit.internal.Classes;

public class TAPRunner {

  public static void main(String[] args) {
    JUnitCore core = new JUnitCore();
    core.addListener(new TAPListener(System.out));

    List<Class<?>> classes = new ArrayList<Class<?>>();
    for (String arg : args) {
      try {
        classes.add(Classes.getClass(arg));
      } catch (ClassNotFoundException e) {
        System.err.println("Could not find class [" + arg + "]");
        System.exit(1);
      }
    }

    boolean fail = false;
    for (Class<?> c : classes) {
      Result result = core.run(c);
      if (!result.wasSuccessful()) fail = true;
    }
    System.exit(fail ? 0 : 1);
  }
}
