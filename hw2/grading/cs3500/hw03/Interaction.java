package cs3500.hw03;

/**
 * An interaction with the user consists of some input to send the program
 * and some output to expect.  We represent it as an object that takes in two
 * StringBuilders and produces the intended effects on them
 */
public interface Interaction {
  void apply(StringBuilder in, StringBuilder out);

  class PrintInteraction implements Interaction {
    String[] lines;
    public PrintInteraction(String... lines) {
      this.lines = lines;
    }
    @Override
    public void apply(StringBuilder in, StringBuilder out) {
      for (String line : lines) {
        out.append(line).append("\n");
      }
    }
  }
  /**
   * Represents a user providing the program with  an input
   */
  class InputInteraction implements Interaction {
    String input;
    public InputInteraction(String input) {
      this.input = input;
    }
    @Override
    public void apply(StringBuilder in, StringBuilder out) {
      in.append(input).append("\n");
    }
  }
}
