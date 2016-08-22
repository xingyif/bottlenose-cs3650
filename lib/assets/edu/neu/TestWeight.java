package edu.neu;

import java.lang.annotation.*;

@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface TestWeight {
  public double weight() default 1.0;
}
