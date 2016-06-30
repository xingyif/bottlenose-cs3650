import org.junit.Before;
import org.junit.After;
import org.junit.Rule;
import org.junit.rules.Timeout;

import java.security.Permission;
import java.util.HashSet;
import java.util.Set;

/**
 * Runs JUnit tests in a sandbox. Wraps each test case to use a restrictive
 * security manager (based on the default, but allowing us to restore each time
 * afterward). Extend the class to mixin the functionality.
 */
public abstract class GradingSandbox {
  @Rule
  public Timeout globalTimeout = Timeout.millis(3000);

  protected static final Set<String> allowed = new HashSet<>();
  static {
      allowed.add("setSecurityManager");
      allowed.add("createSecurityManager");
      allowed.add("createClassLoader");
      allowed.add("suppressAccessChecks");
      allowed.add("accessDeclaredMembers");
      allowed.add("getStackTrace");
      allowed.add("line.separator");
      allowed.add("sun.invoke.util.ValueConversions.MAX_ARITY");
      allowed.add("/usr/share/java/junit-4.12.jar");
      allowed.add("/usr/local/jdk1.8.0_20/jre/lib/ext/jfxrt.jar");
      allowed.add("getProtectionDomain");
      allowed.add("java.locale.providers");
      allowed.add("java.home");
  }

  protected SecurityManager saved;

  protected SecurityManager getManager() {
    return new SecurityManager()
    {
      @Override
      @SuppressWarnings("deprecation")
      public void checkPermission(Permission perm) {
        if (allowed.contains(perm.getName())) {
          return;
        } else if (this.inClass("java.lang.invoke.CallSite")) {
	    return;
	} else if (this.inClass("java.text.NumberFormat")) {
	    return;
	}
	//System.err.println("Perm: " + perm.toString());
        super.checkPermission(perm);
      }
    };
  }

  @Before
  public void setupManager() {
    saved = System.getSecurityManager();
    System.setSecurityManager(getManager());
    try {
      System.in.close();
    } catch(Exception e) {
    }
  }

  @After
  public void restoreManager() {
    System.setSecurityManager(saved);
  }
}
