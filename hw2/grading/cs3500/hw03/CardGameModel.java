package cs3500.hw03;

import cs3500.hw02.GenericCardGameModel;

/**
 * Represents a card game.
 */
public interface CardGameModel<K> extends GenericCardGameModel<K> {
  /**
   * plays the card at index cardIdx in the set of cards for player number playerNo.
   * It is assumed that both player numbers and card indices begin with 0.
   * It is further assumed that players’ hands are sorted.
   * @param playerNo the player number
   * @param cardIndex the index of the card in the players hand
   */
  void play(int playerNo, int cardIndex);

  /**
   * Returns the player whose turn it is to play.
   * @return the player number
   */
  int getCurrentPlayer();

  /**
   * Returns whether the game is over.
   * @return true if the game is over, false otherwise
   */
  boolean isGameOver();
}
