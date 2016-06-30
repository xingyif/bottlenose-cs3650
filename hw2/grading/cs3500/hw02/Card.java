package cs3500.hw02;

/**
 * Represent a card
 */
public class Card implements Comparable<Card>{
  public Suit suit;
  public Value value;

  /**
   * Constructs a card with the given suit and value.
   * @param suit the suit of the card.
   * @param value the value of the card.
   */
  public Card(Suit suit, Value value) {
    this.suit = suit;
    this.value = value;
  }

  @Override
  public int compareTo(Card that) {
    if (this.suit.compareTo(that.suit) > 0) {
      return 1;
    }
    else if (this.suit.compareTo(that.suit) == 0) {
      if (this.value.compareTo(that.value) > 0) {
        return 1;
      }
      else if (this.value.compareTo(that.value) == 0) {
        return 0;
      }
      else return -1;
    }
    else return -1;
  }

  /**
   * Suits that can be used.
   */
  public enum Suit {

    Spade("♠"),
    Heart("♥"),
    Diamond("♦"),
    Club("♣");

    public final String str;

      Suit(String str) {
      this.str = str;
    }
  }

  /**
   * Values that can be used.
   */
  public enum Value {

    Two("2"),
    Three("3"),
    Four("4"),
    Five("5"),
    Six("6"),
    Seven("7"),
    Eight("8"),
    Nine("9"),
    Ten("10"),
    Jack("J"),
    Queen("Q"),
    King("K"),
    Ace("A");

    public final String str;

    Value(String str) {
      this.str = str;
    }
  }

  /**
   * Returns a string that represents the face of the card, consisting of the value followed
   * by the suit
   * @return the face of the card
   */
  public String getFace() {
    return this.value.str + this.suit.str;
  }
}
