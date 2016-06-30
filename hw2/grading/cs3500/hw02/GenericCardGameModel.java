package cs3500.hw02;

import java.util.List;

/**
 *<p> Represents card games. Card games share the common aspects:
 * <ul>
 *   <li>They can be played by many players.
 *   <li>They use an entire deck of cards.
 *   <li>The deck of cards are distributed among all the players.
 *   <li>Each player has a subset of cards at any time in the game.
 *   <li>Players give up their cards as the game progresses.
 *   <li>The game ends when all players have run out of cards.
 * </ul>
 */
public interface GenericCardGameModel<K> {
  /**
   * Returns a list representing the entire deck of relevant cards.
   * @return the entire deck of cards
   */
  List<K> getDeck();

  /** Distributes the cards from the deck in the specified order among the
   * players in round-robin fashion.
   *
   * @param numPlayers the number of players
   * @param deck a deck of cards
   * @throws IllegalArgumentException if the number of players !> 1
   * @throws IllegalArgumentException if the deck passed is invalid
   */
  void startPlay(int numPlayers, List<K> deck);

  /**  <p>returns a String that contains the entire state of the game as follows, one on each line:
   * <ul>
   *   <li>Number of players: N (printed as a normal decimal number)
   *   <li>Player 1: cards in sorted order (printed as a comma-separated list)
   *   <li>Player 2: cards in sorted order (printed as a comma-separated list)
   *   <li>...
   *   <li>Player N: cards in sorted order (printed as a comma-separated list)
   * </ul>
   *@return the state of the game
   */
  String getGameState();




}
