package cs3500.hw03;

import java.io.IOException;

/**
 * Represents the interface for the Whist controller
 */
public interface IWhistController {

  /**
   * Start the provided game with the provided number of players.
   * @param game
   * @param numPlayers
   */
  void startGame(CardGameModel game, int numPlayers);
}
