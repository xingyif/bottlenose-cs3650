package cs3500.hw02;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Represents a player.
 */
public class Player {
  public int playerNumber;
  public List<Card> hand;

  /**
   * Constructs a player
   *
   * @param playerNumber the number of the player.
   * @param hand the cards in the players hand.
   */
  public Player(int playerNumber, List<Card> hand) {
  this.playerNumber = playerNumber;
  this.hand = hand;
  }

  /**
   * Creates a string of all the cards in the players hand, in sorted order
   * @return
   */
  public String getHand() {
    String stringHand = "";
    List<Card> sortedHand = this.sortHand();
    for(Card c : sortedHand) {
      stringHand += ", " + c.getFace();
    }
    if (this.hand.size() >= 1) {
      stringHand = stringHand.substring(2, stringHand.length());
    }
    else {
      stringHand = "";
    }
    return stringHand;
  }

  /**
   * Sorts this hand by suits and values, with suits sorted alphabetically and values ranging from
   * 2-A according to the enumerations in {@link Card}
   * This allows a sorted hand to be returned for the getHand method without mutating the player's
   * hand.
   * @return a sorted copy of the player's hand.
   */
  public List<Card> sortHand() {
    List<Card> sortedHand = new ArrayList<Card>();
    for (Card c : this.hand) {
      sortedHand.add(c);
    }
    Collections.sort(sortedHand);
    Collections.reverse(sortedHand);
    return sortedHand;
  }

  /**
   * States whether this player's hand is empty or not
   * @return a boolean: true if hand is empty, false if there is at least one card
   */
  public boolean handEmpty() {
    return this.hand.isEmpty();
  }
}
