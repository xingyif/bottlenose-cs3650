package cs3500.hw03;

import cs3500.hw02.Card;
import cs3500.hw02.GenericStandardDeckGame;
import cs3500.hw02.Player;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Represents the model for the game of Whist.
 * The game uses a standard 52-card deck.
 * The game ends when all the players have run out of cards,
 * and the player with the maximum number of hands wins the game.
 * Play starts with player 1. The player who
 * starts a hand is free to play any card. This card determines the suit of the current hand.
 * Each player in order must play a card of the same suit with the objective of winning the hand.
 * If a player does not have a card of the same suit, he or she “discards” the hand by playing any
 * other card. When the last player has played, the winner of the hand is determined.
 * The winner of a hand is the player who played the card of the correct suit and the highest
 * value.
 * The winner starts the next hand.
 * The game continues until there are fewer than 2 players with cards in their hands
 */
public class WhistModel extends GenericStandardDeckGame  implements CardGameModel<Card>{
  protected List<Card> deck;
  public List<Player> players;
  protected ArrayList<Integer> scores;
  protected Card[] hand;
  protected int turn;
  protected Card.Suit currentSuit;

  /**
   * Constructs a game using the given deck and list of players.
   *
   * @param deck the deck to use with the game
   * @param players the players who will play the game
   */
  public WhistModel(List<Card> deck, List<Player> players) {
    this.deck = deck;
    this.players = players;
    this.scores = new ArrayList<>();
    this.hand = new Card[players.size()];
    this.turn = 1;
    this.resetScores(this.players.size());
  }

  /**
   * A default constructor that uses a standard 52 card deck and a list of 2 players.
   */
  public WhistModel() {
    this.deck = defaultDeck();
    this.players = defaultPlayers();
    this.scores = new ArrayList<>();
    this.hand = new Card[players.size()];
    this.turn = 1;
    this.resetScores(this.players.size());
  }

  @Override public int getCurrentPlayer() {
    if (this.isGameOver()) {
      throw new IllegalStateException("Game is over");
    }
    else {
      return this.turn;
    }
  }

  @Override public void play(int playerNo, int cardIndex) {

    if (playerNo != this.turn) {
      throw new IllegalArgumentException("Try again, that was invalid input: "
        + "It is player " + this.turn +"'s turn");
    }
    else if (this.isGameOver()) {
      throw new IllegalStateException("The game is over");
    }
    else if (cardIndex > this.players.get(playerNo - 1).hand.size()) {
      throw new IndexOutOfBoundsException("Try again, that was invalid input: Invalid card index");
    }
    else if (cardIndex < 0) {
      throw new IndexOutOfBoundsException("Try again, that was invalid input: Invalid card index");
    }

    Card toPlay = this.players.get(playerNo - 1).hand.get(cardIndex);

    if (this.currentSuit == null) {
      this.currentSuit = toPlay.suit;
    }
    else if (this.currentSuit != toPlay.suit && this.playerCanPlay()) {
      throw new IllegalArgumentException("Try again, that was invalid input: "
        + "Player has a card of suit " + this.currentSuit);
    }


    this.hand[playerNo-1] = toPlay;
    this.players.get(playerNo - 1).hand.remove(cardIndex);

    this.incrementTurn();
  }

  @Override public boolean isGameOver() {
    int x = players.size();
    for (int i = 0; i < players.size(); i++) {
      if (players.get(i).getHand() == "") {
        x-=1;
      }
    }
    return !(x >= 2) && (this.handIsFull() || (this.hand.length == 0));
  }


  @Override public void startPlay(int numPlayers, List<Card> deck) {
    if (numPlayers <= 1) {
      throw new IllegalArgumentException("Number of players must be greater than 1.");
    }
    if (invalidDeck(deck)) {
      throw new IllegalArgumentException("Invalid deck.");
    }

    this.resetScores(numPlayers);
    this.deck = deck;
    this.setPlayers(numPlayers);
    this.hand = new Card[numPlayers];
    this.turn = 1;
    this.currentSuit = null;

    int counter = 0;
    for(int i = 0; i < this.deck.size(); i++) {
      this.players.get(counter).hand.add(this.deck.get(i));
      counter = counter + 1;
      if (counter == numPlayers) {
        counter = 0;
      }
    }
    for(Player p: this.players) {
      Collections.sort(p.hand);
      Collections.reverse(p.hand);
    }
  }

  /**
   * Creates a list of players for this game. Each player has an empty hand and they are ordered
   * with the first player number = 1.
   * @param numPlayers the number of players in the game
   */
  protected void setPlayers(int numPlayers) {
    this.players = new ArrayList<>();
    for(int i = 0; i < numPlayers; i++) {
      this.players.add(new Player(i + 1, new ArrayList<Card>()));
    }
  }

  /**
   * Sets the scores of all players to zero.
   * @param numPlayers the number of players in the game
   */
  protected void resetScores(int numPlayers) {
    this.scores = new ArrayList<Integer>();
    for(int i = 0; i < numPlayers; i++) {
      this.scores.add(0);
    }
  }

  @Override public String getGameState() {
    String state = "Number of players: " + Integer.toString(this.players.size()) + "\n";

    for(Player p : this.players) {
      state += ("Player " + Integer.toString(p.playerNumber) + ": " + p.getHand()+"\n");
    }

    for(Player p : this.players) {
      state+= ("Player " + Integer.toString(p.playerNumber) + ": "
        + this.scores.get(p.playerNumber - 1) + " hands won"+"\n");
    }

    state += this.getStateMessage();
    return state;
  }

  /**
   * Creates the special message for the game state. If the game is over,
   * returns the player with
   * the highest score, otherwise returns the player whose turn is next.
   * @return the special message as a string
   */
  protected String getStateMessage() {
    if (isGameOver()) {
      return "Game over. Player " + Integer.toString(maxIndex(this.scores) + 1) + " won";
    }
    else {
      return "Turn: Player" + Integer.toString(this.turn);
    }
  }

  /**
   * Finds the index of an arraylist of ints that has the highest value.
   * @param ints the arraylist of ints
   * @return the index of the largest int
   */
  public int maxIndex(ArrayList<Integer> ints) {
    int maxValue = 0;
    int maxIndex = 0;
    for (int i = 0; i < ints.size(); i++) {
      if (ints.get(i) >  maxValue) {
        maxValue = ints.get(i);
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  /**
   * Scores the hand based on card values and returns the player with the winning card.
   * Compares all cards to the card played by the player whose turn it currently is.
   * @return the player number of the winning card
   */
  protected int scoreHand() {
    int winner = this.turn + 1;
    if (winner > players.size()) {
      winner = 1;
    }
    Card winningCard = this.hand[winner - 1];
    for (int i = 0; i < this.hand.length; i++) {
      Card other = this.hand[i];
      if (other.suit.compareTo(winningCard.suit) == 0 && other.compareTo(winningCard) > 0) {
        winner = i + 1;
        winningCard = this.hand[winner - 1];
      }
    }
    return winner;
  }

  /**
   * Increments the turn. If all players have played, score the hand, add one to the winning
   * player's hand, reset the hand, and set the turn to the winning player.
   */
  protected void incrementTurn() {
    if (this.handIsFull()) {
      //score the current hand
      int winner = this.scoreHand();
      int newScore = this.scores.get(winner - 1) + 1;
      this.scores.set(winner - 1, newScore);
      //reset the hand
      this.hand = new Card[players.size()];
      // reset the current suit
      this.currentSuit = null;
      //set turn to winning player
      this.turn = winner;
    }
    else if (this.turn >= this.players.size()) {
      this.turn = 1;
    }
    else {
      this.turn += 1;
    }
    while(this.players.get(this.turn -1).handEmpty() && !this.isGameOver()) {
      this.turn += 1;
      if (this.turn >= this.players.size()) {
        this.turn = 1;
      }
    }
  }

  /**
   * Checks if the current hand is full.
   * @return a boolean: true if the hand is full, false if it is not
   */
  protected boolean handIsFull() {
    boolean b = true;

    //checks if all players have played a card
    for (int i = 0; i < this.hand.length; i++) {
      if (this.hand[i] == null) {
        b = false;
      }
    }

    //checks if everyone's hand is empty. This is necessary in a situation where some players
    // start with one more card than others.
    int x = players.size();
    for (int i = 0; i < players.size(); i++) {
      if (players.get(i).getHand() == "") {
        x-=1;
      }
    }
    if (x == 0) {
      b = true;
    }

    return b;
  }

  /**
   * Checks if the current player has a card of the current suit
   * @return a boolean indicating if the player has the current suit
   */
  protected boolean playerCanPlay() {
    String hand = this.players.get(this.turn - 1).getHand();
    if (this.currentSuit == null) {
      throw new NullPointerException("No current suit");
    }
     return hand.contains(this.currentSuit.str);
  }
}
