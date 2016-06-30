package cs3500.hw02;


import org.junit.Test;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static org.junit.Assert.assertEquals;


/**
 * Test methods on cards.
 *
 */
public class CardTest {
  Card c1 = new Card(Card.Suit.Spade, Card.Value.Two);
  Card c2 = new Card(Card.Suit.Club, Card.Value.Ace);
  Card c3 = new Card(Card.Suit.Diamond, Card.Value.Queen);
  Card c4 = new Card(Card.Suit.Heart, Card.Value.King);
  Card c5 = new Card(Card.Suit.Club, Card.Value.Nine);
  Card c6 = new Card(Card.Suit.Club, Card.Value.Nine);
  List<Card> cards = new ArrayList<>();
  List<Card> cards2 = new ArrayList<>();
  List<Card> cards3 = new ArrayList<>();
  public void reset() {
    cards.set(0,c1);
    cards.add(c2);
    cards.add(c3);
    cards.add(c4);
    cards.add(c5);
    cards.add(c6);
    cards2.add(c1);
    cards2.add(c2);
    cards2.add(c3);
    cards2.add(c4);
    cards2.add(c5);
    cards2.add(c6);
    cards3.set(0,c6);
  }


  @Test public void testCard() {
    assertEquals(this.c1.suit, Card.Suit.Spade);
    assertEquals(this.c1.value, Card.Value.Two);
  }

  @Test public void testGetFace() {
    assertEquals(this.c1.getFace(), "2♠");
    assertEquals(this.c2.getFace(), "A♣");
    assertEquals(this.c3.getFace(), "Q♦");
    assertEquals(this.c4.getFace(), "K♥");
    assertEquals(this.c5.getFace(), "9♣");
  }

  @Test
  public void testCompareTo() {
    assertEquals(0, this.c5.compareTo(this.c6));
    assertEquals(-1, this.c1.compareTo(this.c2));
    assertEquals(1, this.c2.compareTo(this.c4));
    assertEquals(1, this.c2.compareTo(this.c6));
    Collections.sort(this.cards2);
  }
}
