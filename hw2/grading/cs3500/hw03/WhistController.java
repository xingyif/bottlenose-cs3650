package cs3500.hw03;

import cs3500.hw02.Card;

import java.io.IOException;
import java.util.Scanner;

/**
 *
 */
public class WhistController implements IWhistController {
  CardGameModel<Card> gameModel;
  final Readable rd;
  final Appendable ap;

  /**
   * Constructs a WhistController from the given readable object and appendable object.
   * @param rd the readable object
   * @param ap the appendable object
   */
  public WhistController(Readable rd, Appendable ap) {
    this.rd = rd;
    this.ap = ap;
  }

  @Override public void startGame(CardGameModel game, int numPlayers) {
    this.gameModel = game;
    this.gameModel.startPlay(numPlayers,this.gameModel.getDeck());
    Scanner scan = new Scanner(this.rd);
    while (!this.gameModel.isGameOver() && (scan.hasNext())) {
      try {
      this.ap.append(this.gameModel.getGameState() + "\n");
        String nextPlay = scan.next();
        this.gameModel.play(this.gameModel.getCurrentPlayer(), Integer.parseInt(nextPlay));
      } catch (IndexOutOfBoundsException i) {
        try {
          this.ap.append(i.getMessage() + "\n");
        } catch (IOException e) {
          e.printStackTrace();
        }
      }
      catch (IllegalArgumentException i) {
        try {
          this.ap.append("Try again, that was invalid input: " +
            "Please play a card of the current suit\n");
        } catch (IOException e) {
          e.printStackTrace();
        }
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
    if (this.gameModel.isGameOver()) {
      try {
        this.ap.append(this.gameModel.getGameState() + "\n");
      } catch (IOException e) {
        e.printStackTrace();
      }
      return;
    }
  }
}
