package cs3500.hw02;

import org.junit.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.Assert.*;

/**
 * Test methods on Generic Standard Deck Games.
 */
public class GenericStandardDeckGameTest {
  GenericStandardDeckGame game1;
  GenericStandardDeckGame game2;
  GenericStandardDeckGame game3;
  List<Player> playList1;
  List<Player> playList2;
  Player player1;
  Player player2;
  Player player3;
  List<Card> tooManyCards;
  Card c1;

  /**
   * Default test conditions
   */
  void resetDefaults() {
    this.playList1 = new ArrayList<Player>();
    this.playList2 = new ArrayList<Player>();
    this.player1 = new Player(1, new ArrayList<Card>());
    this.player2 = new Player(2, new ArrayList<Card>());
    this.player3 = new Player(3, new ArrayList<Card>());
    this.tooManyCards = new ArrayList<>();
    this.player1.hand.add(new Card(Card.Suit.Spade, Card.Value.Two));
    this.player1.hand.add(new Card(Card.Suit.Club, Card.Value.Ace));
    this.player2.hand.add(new Card(Card.Suit.Heart, Card.Value.Three));
    this.player2.hand.add(new Card(Card.Suit.Heart, Card.Value.King));
    this.player3.hand.add(new Card(Card.Suit.Spade, Card.Value.Two));
    this.player3.hand.add(new Card(Card.Suit.Club, Card.Value.Ace));
    this.player3.hand.add(new Card(Card.Suit.Heart, Card.Value.Three));
    this.player3.hand.add(new Card(Card.Suit.Heart, Card.Value.King));
    this.playList1.add(this.player1);
    this.playList1.add(this.player2);
    this.playList2.add(this.player1);
    this.playList2.add(this.player2);
    this.playList2.add(this.player3);
    this.game1 =  new GenericStandardDeckGame();
    this.game2 = new GenericStandardDeckGame(game1.getDeck(), this.playList1);
    this.game3 = new GenericStandardDeckGame(game1.getDeck(), this.playList2);
    this.tooManyCards.addAll(game1.getDeck());
    this.tooManyCards.add(new Card(Card.Suit.Heart, Card.Value.King));
    this.c1 = new Card(Card.Suit.Club, Card.Value.Ace);
  }

  // tests both the getDeck and defaultDeck methods by effect
  @Test
  public void testGetDeck() {
    this.resetDefaults();
    assertEquals(0, this.c1.compareTo(game1.getDeck().get(0)));
    this.c1 = new Card(Card.Suit.Spade, Card.Value.Two);
    assertEquals(0, this.c1.compareTo(game1.getDeck().get(51)));
  }

  @Test
  public void testStartPlay() {
    this.resetDefaults();
    assertEquals("Number of players: 2\nPlayer 1: \nPlayer 2: \n", this.game1.getGameState());
    this.game1.startPlay(6, this.game1.getDeck());
    assertEquals("Number of players: 6\n"
      + "Player 1: A♣, 8♣, 2♣, 9♦, 3♦, 10♥, 4♥, J♠, 5♠\n"
        + "Player 2: K♣, 7♣, A♦, 8♦, 2♦, 9♥, 3♥, 10♠, 4♠\n"
        + "Player 3: Q♣, 6♣, K♦, 7♦, A♥, 8♥, 2♥, 9♠, 3♠\n"
        + "Player 4: J♣, 5♣, Q♦, 6♦, K♥, 7♥, A♠, 8♠, 2♠\n"
        + "Player 5: 10♣, 4♣, J♦, 5♦, Q♥, 6♥, K♠, 7♠\n"
        + "Player 6: 9♣, 3♣, 10♦, 4♦, J♥, 5♥, Q♠, 6♠\n"
      , this.game1.getGameState());
  }

  // the following 4 methods test the startPlay exceptions
  // as well as the invalidDeck method by effect
  @Test(expected = IllegalArgumentException.class)
  public void testStartPlayTooFewPlayers() throws Exception {
    this.resetDefaults();
    this.game1.startPlay(1, this.game1.getDeck());
  }

  @Test(expected = IllegalArgumentException.class)
  public void testStartPlayTooFewCards() throws Exception {
    this.resetDefaults();
    this.game1.startPlay(3, this.player1.hand);
  }

  @Test(expected = IllegalArgumentException.class)
  public void testStartPlayTooManyCards() throws Exception {
    this.resetDefaults();
    this.game1.startPlay(3, this.tooManyCards);
  }

  @Test
  public void testGetGameState() {
    this.resetDefaults();
    assertEquals("Number of players: 2\nPlayer 1: \nPlayer 2: \n", game1.getGameState());
    assertEquals("Number of players: 2\nPlayer 1: A♣, 2♠\nPlayer 2: K♥, 3♥\n",
      game2.getGameState());
  }

  //Tests for the method getHand() which also test the private method sortHand()
  @Test
  public void testGetHand() {
    this.resetDefaults();
    assertEquals("A♣, 2♠", player1.getHand());
    assertEquals("K♥, 3♥", player2.getHand());
    assertEquals("A♣, K♥, 3♥, 2♠", player3.getHand());
    this.player1.hand = this.player1.sortHand();
    this.player1.hand.remove(0);
    assertEquals("2♠", player1.getHand());
  }

  @Test
  public void testHandEmpty() {
    this.resetDefaults();
    assertEquals(false, this.player1.handEmpty());
    Player p3 = new Player(1, new ArrayList<Card>());
    assertEquals(true, p3.handEmpty());
  }
}










