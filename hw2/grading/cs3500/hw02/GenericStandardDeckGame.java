package cs3500.hw02;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Represents a card game model which utilizes a deck of 52 cards of suits and values
 * specified by {@link cs3500.hw02.Card.Suit} and {@link cs3500.hw02.Card.Value}
 */
public class GenericStandardDeckGame implements GenericCardGameModel<Card> {
  private List<Card> deck;
  private List<Player> players;

  /**
   * Constructs a game using the given deck and list of players.
   *
   * @param deck the deck to use with the game
   * @param players the players who will play the game
   */
  public GenericStandardDeckGame(List<Card> deck, List<Player> players) {
        this.deck = deck;
        this.players = players;
      }

  /**
   * Constructs the game using the default 52 card deck and an arbitrary 2 players.
   */
  public GenericStandardDeckGame() {
    this(defaultDeck(), defaultPlayers());
  }

  /**
   * Creates the default 52 card deck for a game, with one of each card using the 4 standard suits
   * and values of 1-9, J, Q, K, A
   * @return the deck as an arrayList of Cards
   */
  public static List<Card> defaultDeck() {
    List<Card> deck = new ArrayList<Card>();
    for (Card.Suit s : Card.Suit.values()) {
      for(Card.Value v : Card.Value.values()) {
        deck.add(new Card(s, v));
      }
    }
    Collections.reverse(deck);
    return deck;
  }

  /**
   * Creates a list of 2 {@link Player} with an empty hand to be used in the default constructor.
   * @return a list of Players
   */
  public static List<Player> defaultPlayers() {
    List<Player> players = new ArrayList<Player>();
    players.add(new Player(1, new ArrayList<Card>()));
    players.add(new Player(2, new ArrayList<Card>()));

    return players;
  }

  @Override
  public List<Card> getDeck() {
    return this.deck;
  }

  @Override
  public void startPlay(int numPlayers, List<Card> deck) {

    if (numPlayers <= 1) {
      throw new IllegalArgumentException("Number of players must be greater than 1.");
    }
    if (invalidDeck(deck)) {
      throw new IllegalArgumentException("Invalid deck.");
    }
    this.deck = deck;
    this.setPlayers(numPlayers);
    int counter = 0;
    for (Card aDeck : this.deck) {
      this.players.get(counter).hand.add(aDeck);
      counter = counter + 1;
      if (counter == numPlayers) {
        counter = 0;
      }
    }
  }

  /**
   * Creates a list of players for this game. Each player has an empty hand and they are ordered
   * with the first player number = 1.
   * @param numPlayers the number of players in the game
   */
  private void setPlayers(int numPlayers) {
    this.players = new ArrayList<>();
    for(int i = 0; i < numPlayers; i++) {
      this.players.add(new Player(i + 1, new ArrayList<Card>()));
    }
  }

  @Override
  public String getGameState() {
    String state = "Number of players: " + Integer.toString(this.players.size()) + "\n";
    for(Player p : this.players) {
      state += ("Player " + Integer.toString(p.playerNumber) + ": " + p.getHand()+"\n");
    }
    return state;
  }

  public boolean invalidDeck(List<Card> deck) { // // TODO: 2/3/2016 private
    if (deck.size() != 52) {
      return true;
          }
          else {
            for (int x = 0; x < deck.size(); x++) {
              for (int y = x + 1; y < deck.size(); y++) {
                if (deck.get(x).compareTo(deck.get(y)) == 0) {
                  return true;
                }
              }
            }
    }
      return false;
  }
}

