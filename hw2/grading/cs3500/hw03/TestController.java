package cs3500.hw03;

import cs3500.hw02.Card;
import cs3500.hw02.Player;
import org.junit.Test;

import java.io.IOException;
import java.io.StringReader;
import java.util.ArrayList;

import static org.junit.Assert.assertEquals;

/**
 * Tests on the WhistController class
 */
public class TestController {
  WhistModel w1 = new WhistModel();
  Player p1;
  Player p2;

  void reset() {
    this.w1 = new WhistModel();
    this.p1 =  new Player(1, new ArrayList<>());
    this.p1.hand.add(new Card(Card.Suit.Club, Card.Value.Ace));
    this.p1.hand.add(new Card(Card.Suit.Spade, Card.Value.Two));
    this.p2 = new Player(2, new ArrayList<>());
    this.p2.hand.add(new Card(Card.Suit.Heart, Card.Value.Three));
    this.p2.hand.add(new Card(Card.Suit.Spade, Card.Value.King));

    this.w1.players.add(this.p1);
    this.w1.players.add(this.p2);
  }

  Interaction[] interactions = new Interaction[] {
    new Interaction.PrintInteraction("Number of players: 2 Player 1: A♣, "
      + "2♠\nPlayer 2: K♥, 3♥\n"
      + "      + Player 1: 0 hands won \nPlayer 2: 0 hands won\nTurn: Player1"),
    new Interaction.InputInteraction("1"),
    new Interaction.PrintInteraction("Number of players: 2\nPlayer 1: A♣, "
      + "\nPlayer 2: K♥, 3♥\n"
      + "      + Player 1: 0 hands won\nPlayer 2: 0 hands won\nTurn: Player2"),
    new Interaction.InputInteraction("q"),
    new Interaction.PrintInteraction("Try again, that was invalid input: " +
      "Please play a card of the current suit\n"),
    new Interaction.InputInteraction("0"),
      new Interaction.PrintInteraction("Number of players: 2\nPlayer 1: A♣, "
        + "\nPlayer 2: 3♥\n"
        + "      + \"Player 1: 1 hands won\\nPlayer 2: 0 hands won\\nTurn: Player1\""),
      new Interaction.InputInteraction("0"),
      new Interaction.PrintInteraction("Number of players: 2\nPlayer 1: "
        + "\nPlayer 2: 3♥\n"
        + "      + Player 1: 2 hands won\nPlayer 2: 0 hands won\nGame over: Player 1 won")

  };
  public void build() {
    StringBuilder sb1 = new StringBuilder();
    StringBuilder sb2 = new StringBuilder();
    for (Interaction i : interactions) {
      i.apply(sb1, sb2);
    }
  }
  public void testRun(CardGameModel model, int numPlayers, Interaction... interactions)
    throws IOException {
    StringBuilder fakeUserInput = new StringBuilder();
    StringBuilder expectedOutput = new StringBuilder();

    for (Interaction interaction : interactions) {
      interaction.apply(fakeUserInput, expectedOutput);
    }

    StringReader input = new StringReader(fakeUserInput.toString());
    StringBuilder actualOutput = new StringBuilder();

    WhistController controller = new WhistController(input, actualOutput);
    controller.startGame(model, numPlayers);

    assertEquals(expectedOutput.toString(), actualOutput.toString());
  }
  @Test
  public void testController() throws IOException {
    this.reset();
    //this.build();
    testRun(this.w1, 2,
      new Interaction.PrintInteraction(
        "Number of players: 2",
        "Player 1: A♣, Q♣, 10♣, 8♣, 6♣, "
          + "4♣, 2♣, K♦, J♦, 9♦, 7♦, 5♦, 3♦, A♥, Q♥, 10♥, 8♥, 6♥, 4♥, 2♥, K♠, "
          + "J♠, 9♠, 7♠, 5♠, 3♠",
        "Player 2: K♣, J♣, 9♣, 7♣, 5♣, 3♣, A♦, Q♦, 10♦, 8♦, 6♦, "
          + "4♦, 2♦, K♥, J♥, 9♥, 7♥, 5♥, 3♥, A♠, Q♠, 10♠, 8♠, 6♠, 4♠, 2♠",
        "Player 1: 0 hands won",
        "Player 2: 0 hands won",
        "Turn: Player1"),
      new Interaction.InputInteraction("1"),
      new Interaction.PrintInteraction(
        "Number of players: 2",
        "Player 1: A♣, 10♣, 8♣, 6♣, "
          + "4♣, 2♣, K♦, J♦, 9♦, 7♦, 5♦, 3♦, A♥, Q♥, 10♥, 8♥, 6♥, 4♥, 2♥, K♠, "
          + "J♠, 9♠, 7♠, 5♠, 3♠",
        "Player 2: K♣, J♣, 9♣, 7♣, 5♣, 3♣, A♦, Q♦, 10♦, 8♦, 6♦, "
          + "4♦, 2♦, K♥, J♥, 9♥, 7♥, 5♥, 3♥, A♠, Q♠, 10♠, 8♠, 6♠, 4♠, 2♠",
        "Player 1: 0 hands won",
        "Player 2: 0 hands won",
        "Turn: Player2"),
      new Interaction.InputInteraction("q"),
      new Interaction.PrintInteraction(
        "Try again, that was invalid input: Please play a card of the current suit"),
      new Interaction.InputInteraction("9999999"),
      new Interaction.PrintInteraction(
        "Number of players: 2",
        "Player 1: A♣, 10♣, 8♣, 6♣, "
          + "4♣, 2♣, K♦, J♦, 9♦, 7♦, 5♦, 3♦, A♥, Q♥, 10♥, 8♥, 6♥, 4♥, 2♥, K♠, "
          + "J♠, 9♠, 7♠, 5♠, 3♠",
        "Player 2: K♣, J♣, 9♣, 7♣, 5♣, 3♣, A♦, Q♦, 10♦, 8♦, 6♦, "
          + "4♦, 2♦, K♥, J♥, 9♥, 7♥, 5♥, 3♥, A♠, Q♠, 10♠, 8♠, 6♠, 4♠, 2♠",
        "Player 1: 0 hands won",
        "Player 2: 0 hands won",
        "Turn: Player2",
        "Try again, that was invalid input: Invalid card index"));
  }
}
