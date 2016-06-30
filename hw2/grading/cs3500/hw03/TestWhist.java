package cs3500.hw03;
import cs3500.hw02.Card;
import cs3500.hw02.GenericStandardDeckGame;
import cs3500.hw02.Player;
import org.junit.Test;
import java.io.Reader;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static org.junit.Assert.*;

/**
 * Test methods related to the whist game
 */
public class TestWhist {
  WhistModel w1;
  WhistModel w2;
  Player p1;
  Player p2;
  Player p3;
  List<Player> playerList1;//list of p1&2
  List<Player> playerList2;// list of p1, 2, 3
  ArrayList<Integer> ints;
  StringBuffer out = new StringBuffer();
  Reader in = new StringReader("");
  WhistController control;

  /**
   * Resets the test conditions to their defaults to prevent unwanted mutation.
   */
  void resetDefaults() {
    this.playerList1 = new ArrayList<Player>();
    this.playerList2 = new ArrayList<Player>();
    this.p1 = new Player(1, new ArrayList<Card>());
    this.p2 = new Player(2, new ArrayList<Card>());
    this.p3 = new Player(3, new ArrayList<Card>());
    this.p1.hand.add(new Card(Card.Suit.Spade, Card.Value.Two));
    this.p1.hand.add(new Card(Card.Suit.Club, Card.Value.Ace));
    this.p2.hand.add(new Card(Card.Suit.Heart, Card.Value.Three));
    this.p2.hand.add(new Card(Card.Suit.Heart, Card.Value.King));
    this.p3.hand.add(new Card(Card.Suit.Spade, Card.Value.Two));
    this.p3.hand.add(new Card(Card.Suit.Club, Card.Value.Ace));
    this.p3.hand.add(new Card(Card.Suit.Heart, Card.Value.Three));
    this.p3.hand.add(new Card(Card.Suit.Heart, Card.Value.King));
    this.playerList1.add(this.p1);
    this.playerList1.add(this.p2);
    this.playerList2.add(this.p1);
    this.playerList2.add(this.p2);
    this.playerList2.add(this.p3);
    this.w1 = new WhistModel(GenericStandardDeckGame.defaultDeck(), this.playerList1);
    this.w2 = new WhistModel(GenericStandardDeckGame.defaultDeck(), this.playerList2);
    this.ints = new ArrayList<>();
    this.ints.add(3);
    this.ints.add(19);
    this.ints.add(0);
    this.control = new WhistController(this.in, this.out);

  }

  @Test
  public void testMaxIndex() {
    this.resetDefaults();
    assertEquals(1, this.w1.maxIndex(ints));
    this.ints.add(100);
    assertEquals(3, this.w1.maxIndex(ints));
  }

  //Tests getStateMessage by effect
  @Test
  public void testGetGameState() {
    this.resetDefaults();
    assertEquals("Number of players: 2\nPlayer 1: A♣, 2♠\nPlayer 2: K♥, 3♥\n"
      + "Player 1: 0 hands won\nPlayer 2: 0 hands won\nTurn: Player1", this.w1.getGameState());
  }

  // also tests scoreHand by effect. HandIsFull should never be true, as it is called by increment
  //turn
  @Test
  public void testHandIsFull() {
    this.resetDefaults();
    assertEquals(false, this.w1.handIsFull());
    this.w1.play(1,1);
    assertEquals(false, this.w1.handIsFull());
    assertEquals("Number of players: 2\nPlayer 1: 2♠\nPlayer 2: K♥, 3♥\n"
      + "Player 1: 0 hands won\nPlayer 2: 0 hands won\nTurn: Player2", this.w1.getGameState());
    this.w1.play(2,1);
    // tests to see if the winning hand was awarded correctly
    assertEquals("Number of players: 2\nPlayer 1: 2♠\nPlayer 2: 3♥\n"
      + "Player 1: 1 hands won\nPlayer 2: 0 hands won\nTurn: Player1", this.w1.getGameState());
  }

  @Test
  public void testStartPlay() {
    this.resetDefaults();
    this.w1.startPlay(6, WhistModel.defaultDeck());
    assertEquals("Number of players: 6\n"
        + "Player 1: A♣, 8♣, 2♣, 9♦, 3♦, 10♥, 4♥, J♠, 5♠\n"
        + "Player 2: K♣, 7♣, A♦, 8♦, 2♦, 9♥, 3♥, 10♠, 4♠\n"
        + "Player 3: Q♣, 6♣, K♦, 7♦, A♥, 8♥, 2♥, 9♠, 3♠\n"
        + "Player 4: J♣, 5♣, Q♦, 6♦, K♥, 7♥, A♠, 8♠, 2♠\n"
        + "Player 5: 10♣, 4♣, J♦, 5♦, Q♥, 6♥, K♠, 7♠\n"
        + "Player 6: 9♣, 3♣, 10♦, 4♦, J♥, 5♥, Q♠, 6♠\n"
        + "Player 1: 0 hands won\n"
        + "Player 2: 0 hands won\n"
        + "Player 3: 0 hands won\n"
        + "Player 4: 0 hands won\n"
        + "Player 5: 0 hands won\n"
        + "Player 6: 0 hands won\n"
        + "Turn: Player1"
      , this.w1.getGameState());
    List<Card> shuffledDeck = this.w1.getDeck();
    Collections.shuffle(shuffledDeck);
    this.w1.startPlay(6, shuffledDeck);
    assertNotEquals("Number of players: 6\n"
        + "Player 1: A♣, 8♣, 2♣, 9♦, 3♦, 10♥, 4♥, J♠, 5♠\n"
        + "Player 2: K♣, 7♣, A♦, 8♦, 2♦, 9♥, 3♥, 10♠, 4♠\n"
        + "Player 3: Q♣, 6♣, K♦, 7♦, A♥, 8♥, 2♥, 9♠, 3♠\n"
        + "Player 4: J♣, 5♣, Q♦, 6♦, K♥, 7♥, A♠, 8♠, 2♠\n"
        + "Player 5: 10♣, 4♣, J♦, 5♦, Q♥, 6♥, K♠, 7♠\n"
        + "Player 6: 9♣, 3♣, 10♦, 4♦, J♥, 5♥, Q♠, 6♠\n"
        + "Player 1: 0 hands won\n"
        + "Player 2: 0 hands won\n"
        + "Player 3: 0 hands won\n"
        + "Player 4: 0 hands won\n"
        + "Player 5: 0 hands won\n"
        + "Player 6: 0 hands won\n"
        + "Turn: Player1"
      , this.w1.getGameState());
    this.w1.startPlay(4, WhistModel.defaultDeck());
    assertEquals("Number of players: 4\n"
      + "Player 1: A♣, 10♣, 6♣, 2♣, J♦, 7♦, 3♦, Q♥, 8♥, 4♥, K♠, 9♠, 5♠\n"
      + "Player 2: K♣, 9♣, 5♣, A♦, 10♦, 6♦, 2♦, J♥, 7♥, 3♥, Q♠, 8♠, 4♠\n"
      + "Player 3: Q♣, 8♣, 4♣, K♦, 9♦, 5♦, A♥, 10♥, 6♥, 2♥, J♠, 7♠, 3♠\n"
      + "Player 4: J♣, 7♣, 3♣, Q♦, 8♦, 4♦, K♥, 9♥, 5♥, A♠, 10♠, 6♠, 2♠\n"
      + "Player 1: 0 hands won\n"
      + "Player 2: 0 hands won\n"
      + "Player 3: 0 hands won\n"
      + "Player 4: 0 hands won\n"
      + "Turn: Player1", this.w1.getGameState());
  }

  @Test(expected = NullPointerException.class)
  public void testStartPlayNullPointer() {
    this.resetDefaults();
    this.w1.startPlay(6, WhistModel.defaultDeck());
    assertEquals(false, this.w1.playerCanPlay());
  }

  @Test(expected = IllegalArgumentException.class)
  public void testStartPlayIllegalArgument() {
    this.resetDefaults();
    List<Card> badDeck = WhistModel.defaultDeck();
    badDeck.add(new Card(Card.Suit.Spade, Card.Value.Ace));
    this.w1.startPlay(6, badDeck);
    assertEquals(false, this.w1.playerCanPlay());
  }

  @Test
  public void testPlayerCanPlay() {
    this.resetDefaults();
    this.w1.startPlay(6, WhistModel.defaultDeck());
    this.w1.play(1, 0);
    assertEquals(true, this.w1.playerCanPlay());
    this.w1.play(2, 0);
    assertEquals(true, this.w1.playerCanPlay());
    this.w1.play(3, 0);
    assertEquals(true, this.w1.playerCanPlay());
  }

  @Test
  public void testGetCurrentPlayer() {
    this.resetDefaults();
    assertEquals(1, this.w1.getCurrentPlayer());
    this.w1.startPlay(2, WhistModel.defaultDeck());
    assertEquals(1, this.w1.getCurrentPlayer());
    this.w1.play(1, 0);
    assertEquals(2, this.w1.getCurrentPlayer());
  }
  @Test(expected = IllegalStateException.class)
  public void testGetCurrentPlayerGameOver() {
    this.resetDefaults();
    this.w1.play(1,0);
    this.w1.play(2,0);
    this.w1.play(1,0);
    this.w1.getCurrentPlayer();
  }

  @Test(expected = IllegalArgumentException.class)
    public void testPlayWrongTurn() {
    this.resetDefaults();
    this.w1.startPlay(4, WhistModel.defaultDeck());
    assertEquals(1, this.w1.getCurrentPlayer());
    this.w1.play(2, 0);
  }

  @Test(expected = IndexOutOfBoundsException.class)
  public void testPlayInvalidCardIndex() {
    this.resetDefaults();
    this.w1.startPlay(4, WhistModel.defaultDeck());
    this.w1.play(1, 490);
  }

  @Test
  public void testPlay() {
    this.resetDefaults();
    this.w1.startPlay(6, WhistModel.defaultDeck());
    assertEquals("Number of players: 6\n"
        + "Player 1: A♣, 8♣, 2♣, 9♦, 3♦, 10♥, 4♥, J♠, 5♠\n"
        + "Player 2: K♣, 7♣, A♦, 8♦, 2♦, 9♥, 3♥, 10♠, 4♠\n"
        + "Player 3: Q♣, 6♣, K♦, 7♦, A♥, 8♥, 2♥, 9♠, 3♠\n"
        + "Player 4: J♣, 5♣, Q♦, 6♦, K♥, 7♥, A♠, 8♠, 2♠\n"
        + "Player 5: 10♣, 4♣, J♦, 5♦, Q♥, 6♥, K♠, 7♠\n"
        + "Player 6: 9♣, 3♣, 10♦, 4♦, J♥, 5♥, Q♠, 6♠\n"
        + "Player 1: 0 hands won\n"
        + "Player 2: 0 hands won\n"
        + "Player 3: 0 hands won\n"
        + "Player 4: 0 hands won\n"
        + "Player 5: 0 hands won\n"
        + "Player 6: 0 hands won\n"
        + "Turn: Player1"
      , this.w1.getGameState());
    this.w1.play(1, 0);
    assertEquals("Number of players: 6\n"
        + "Player 1: 8♣, 2♣, 9♦, 3♦, 10♥, 4♥, J♠, 5♠\n"
        + "Player 2: K♣, 7♣, A♦, 8♦, 2♦, 9♥, 3♥, 10♠, 4♠\n"
        + "Player 3: Q♣, 6♣, K♦, 7♦, A♥, 8♥, 2♥, 9♠, 3♠\n"
        + "Player 4: J♣, 5♣, Q♦, 6♦, K♥, 7♥, A♠, 8♠, 2♠\n"
        + "Player 5: 10♣, 4♣, J♦, 5♦, Q♥, 6♥, K♠, 7♠\n"
        + "Player 6: 9♣, 3♣, 10♦, 4♦, J♥, 5♥, Q♠, 6♠\n"
        + "Player 1: 0 hands won\n"
        + "Player 2: 0 hands won\n"
        + "Player 3: 0 hands won\n"
        + "Player 4: 0 hands won\n"
        + "Player 5: 0 hands won\n"
        + "Player 6: 0 hands won\n"
        + "Turn: Player2"
      , this.w1.getGameState());
    this.resetDefaults();
    assertEquals(1, this.w1.getCurrentPlayer());
    this.w1.play(1, 1);
    assertEquals(2, this.w1.getCurrentPlayer());
  }

  @Test(expected = IllegalArgumentException.class)
  public void testPlayWrongSuit() {
    this.resetDefaults();
    this.w1.startPlay(6, WhistModel.defaultDeck());
    this.w1.play(1, 0);
    this.w1.play(2, 5);
  }

  @Test(expected = IllegalStateException.class)
  public void testPlayAfterGameEnds(){
    this.resetDefaults();
    this.w1.play(1, 0);
    this.w1.play(2, 0);
    assertEquals(false, this.w1.isGameOver());
    this.w1.play(1, 0);
    assertEquals(true, this.w1.isGameOver());
    this.w1.play(2, 1);
  }
  @Test
  public void testIsGameOver() {
    this.resetDefaults();
    assertEquals(false, this.w1.isGameOver());
    this.w1.play(1,0);
    assertEquals(false, this.w1.isGameOver());
    this.w1.play(2,0);
    assertEquals(false, this.w1.isGameOver());
    this.w1.play(1,0);
    assertEquals(true, this.w1.isGameOver());
  }

  @Test
  public void testResetScores() {
    this.resetDefaults();
    assertEquals("Number of players: 2\nPlayer 1: A♣, 2♠\nPlayer 2: K♥, 3♥\n"
      + "Player 1: 0 hands won\nPlayer 2: 0 hands won\nTurn: Player1", this.w1.getGameState());
    this.w1.play(1, 0);
    this.w1.play(2, 0);
    assertEquals("Number of players: 2\nPlayer 1: A♣\nPlayer 2: K♥\n"
      + "Player 1: 1 hands won\nPlayer 2: 0 hands won\nTurn: Player1", this.w1.getGameState());
    this.resetDefaults();
    this.w1.startPlay(2, WhistModel.defaultDeck());
    assertEquals("Number of players: 2\nPlayer 1: A♣, Q♣, 10♣, 8♣, 6♣, 4♣, 2♣, K♦, J♦, 9♦,"
      + " 7♦, 5♦, 3♦, A♥, Q♥, 10♥, 8♥, 6♥, 4♥, 2♥, K♠, J♠, 9♠, 7♠, 5♠, 3♠"
      + "\nPlayer 2: K♣, J♣, 9♣, 7♣, 5♣, 3♣, A♦, Q♦, 10♦, 8♦, 6♦, 4♦, 2♦, K♥, J♥, 9♥, 7♥,"
      + " 5♥, 3♥, A♠, Q♠, 10♠, 8♠, 6♠, 4♠, 2♠\n"
      + "Player 1: 0 hands won\nPlayer 2: 0 hands won\nTurn: Player1", this.w1.getGameState());
  }
}






















