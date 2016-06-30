import org.junit.Test;

import java.io.Reader;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import java.util.Scanner;

import static org.junit.Assert.*;

import cs3500.hw03.*;

/**
 * Created by ashesh on 2/12/2016.
 */
@SuppressWarnings({"unchecked", "unsafe"})
public class Grade03resubmit extends GradingSandbox
{

    //weight: 1
    @Test(expected=IllegalArgumentException.class)
    public void testStartGameZeroPlayers()
    {
        String input = "4 3";
        Reader stringReader = new StringReader(input);
        StringBuffer out = new StringBuffer();

        IWhistController controller = new WhistController(stringReader,out);
        CardGameModel model = new WhistModel();
        controller.startGame(model,0);

    }

    //weight: 1
    @Test(expected=IllegalArgumentException.class)
    public void testStartGameOnePlayer()
    {
        String input = "4 3";
        Reader stringReader = new StringReader(input);
        StringBuffer out = new StringBuffer();

        IWhistController controller = new WhistController(stringReader,out);
        CardGameModel model = new WhistModel();
        controller.startGame(model,1);
    }

    //weight: 1
    @Test
    public void testModelCurrentPlayer()
    {
        String input = "";
        Reader stringReader = new StringReader(input);
        StringBuffer out = new StringBuffer();

        CardGameModel model = new WhistModel();
        List<?> deck = model.getDeck();
        model.startPlay(52,deck);
        for (int i=0;i<10;i++)
	    {
		assertEquals("Correct current player?", i,model.getCurrentPlayer());
		model.play(i,0);
	    }
    }

    //weight: 1
    @Test(expected=IllegalArgumentException.class)
    public void testModelInvalidPlayer()
    {
        String input = "";
        Reader stringReader = new StringReader(input);
        StringBuffer out = new StringBuffer();

        CardGameModel model = new WhistModel();
        List<?> deck = model.getDeck();
        model.startPlay(10,deck);
        model.play(0,0);
        model.play(1,0);
        model.play(3,0);
    }

    //weight: 1
    @Test(expected=IllegalArgumentException.class)
    public void testModelInvalidCard()
    {
        String input = "";
        Reader stringReader = new StringReader(input);
        StringBuffer out = new StringBuffer();

        CardGameModel model = new WhistModel();
        List<?> deck = model.getDeck();
        model.startPlay(10,deck);
        model.play(0,0);
        model.play(1,0);
        model.play(2,0);
        model.play(3,10);
    }

    //weight: 1
    @Test(expected=IllegalArgumentException.class)
    public void testModelWrongSuit()
    {
        String input = "";
        Reader stringReader = new StringReader(input);
        StringBuffer out = new StringBuffer();

        CardGameModel model = new WhistModel();
        List<?> deck = model.getDeck();
        model.startPlay(13,deck);
        model.play(0,0);
        model.play(1,0);
        model.play(2,0);
        model.play(3,1);
    }

    //weight: 0.5
    @Test
    public void testGameFourPlayers() throws Exception
    {
        String[] outs;
        int numPlayers=4;

        outs = getCorrectGameInputOutput(numPlayers);
	if (outs == null) {
	    assertEquals("Got a plausible game play via getGameState", true, outs != null);
	} else {

        // System.out.println("Number of plays: "+outs[0].split(" ").length);
        Reader stringReader = new StringReader(outs[0]);
        StringBuffer out = new StringBuffer();

        CardGameModel model = new WhistModel();
        IWhistController controller = new WhistController(stringReader,out);
        controller.startGame(model,numPlayers);
        //extract last game state, this is in the last 2+2*numPlayers lines
        String []lines = out.toString().split("\n");
        StringBuilder builder = new StringBuilder();
        for (int i=0;i<(2+2*numPlayers);i++)
	    {
		if ((lines.length - (2+2*numPlayers) + i) >= 0)
		    builder.append(lines[lines.length-(2+2*numPlayers)+i]+"\n");
	    }
        assertEquals("Correct expected output", outs[1],builder.toString());
	}
    }

    //weight=0.5
    @Test
    public void testGameFourPlayersInvalidPlay() throws Exception
    {
        String[] outs;
        int numPlayers=4;

        outs = getCorrectGameInputOutput(numPlayers);
	if (outs == null) {
	    assertEquals("Got a plausible game play via getGameState", true, outs != null);
	} else {

        //insert an invalid play in the middle
        outs[0] = "50 "+ outs[0];
        Reader stringReader = new StringReader(outs[0]);
        StringBuffer out = new StringBuffer();

        CardGameModel model = new WhistModel();
        IWhistController controller = new WhistController(stringReader,out);
        controller.startGame(model,numPlayers);
        //extract last game state, this is in the last 2+2*numPlayers lines
        String []lines = out.toString().split("\n");
        StringBuilder builder = new StringBuilder();
        for (int i=0;i<(2+2*numPlayers);i++)
	    {
		if ((lines.length - (2+2*numPlayers) + i) >= 0)
		    builder.append(lines[lines.length-(2+2*numPlayers)+i]+"\n");
	    }
        assertEquals("Correct expected output", outs[1],builder.toString());
	}
    }


    //weight: 0.5
    @Test
    public void testGameFivePlayers() throws Exception
    {
        String[] outs;
        int numPlayers=5;

        outs = getCorrectGameInputOutput(numPlayers);
	if (outs == null) {
	    assertEquals("Got a plausible game play via getGameState", true, outs != null);
	} else {
        // System.out.println("Number of plays: "+outs[0].split(" ").length);
        Reader stringReader = new StringReader(outs[0]);
        StringBuffer out = new StringBuffer();

        CardGameModel model = new WhistModel();
        IWhistController controller = new WhistController(stringReader,out);
        controller.startGame(model,numPlayers);
        //extract last game state, this is in the last 2+2*numPlayers lines
        String []lines = out.toString().split("\n");
        StringBuilder builder = new StringBuilder();
        for (int i=0;i<(2+2*numPlayers);i++)
	    {
		if ((lines.length - (2+2*numPlayers) + i) >= 0)
		    builder.append(lines[lines.length-(2+2*numPlayers)+i]+"\n");
	    }
        assertEquals("Correct expected output", outs[1],builder.toString());
	}
    }


    private String [] getCorrectGameInputOutput(int numPlayers) throws Exception
    {
        StringBuilder stb = new StringBuilder();
        CardGameModel model = new WhistModel();
        ArrayList<LinkedList<String>> state = new ArrayList<LinkedList<String>>();
        int []playerScores;
        int []tempscores;
        int cardIdx;
	int cardsPlayed = 0;

        model.startPlay(numPlayers,model.getDeck());
        String distribution = model.getGameState();
	// if (distribution.equals("")) return null;
        state = extractPlayerHands(new String(distribution),numPlayers);
        playerScores = extractPlayerScores(new String(distribution),numPlayers);
        //blindly play card 0 for current player
        char suit = suitOf(state.get(model.getCurrentPlayer()).get(0));
        //blindly play first card of first player
        stb.append("0\n");
        model.play(model.getCurrentPlayer(),0);
	cardsPlayed++;

        distribution = model.getGameState();
        state = extractPlayerHands(new String(distribution),numPlayers);
        tempscores = extractPlayerScores(new String(distribution),numPlayers);

        while (!model.isGameOver())
	    {
		if (tempscores == null)
		    return null;
		if (changeInScores(playerScores,tempscores))
		    {
			playerScores = tempscores;
			if (model.isGameOver())
			    continue;
			suit = suitOf(state.get(model.getCurrentPlayer()).get(0));
			cardIdx = 0;
		    }
		else
		    {
			//look for current suit card in current player's hand
			cardIdx = 0;
			while ((cardIdx<state.get(model.getCurrentPlayer()).size()) && 
			       (suitOf(state.get(model.getCurrentPlayer()).get(cardIdx))!=suit)) {
			    cardIdx++;
			}
			if (cardIdx==state.get(model.getCurrentPlayer()).size())
			    cardIdx = 0;
		    }
		model.play(model.getCurrentPlayer(),cardIdx);
		stb.append(""+cardIdx+"\n");
		cardsPlayed++;

		distribution = model.getGameState();
		state = extractPlayerHands(new String(distribution),numPlayers);
		tempscores = extractPlayerScores(new String(distribution),numPlayers);
	    }

	//	assertEquals("Created a simulation for the correct number of cards", 52, cardsPlayed);
	for (; cardsPlayed < 52; cardsPlayed++)
	    stb.append("0\n");

        String [] outs = new String[2];
        outs[0] = stb.toString();
        outs[1] = distribution;
        if (outs[1].charAt(outs[1].length()-1)!='\n')
            outs[1] = outs[1] +"\n";
        return outs;
    }

    private char suitOf(String card) {
	return card.charAt(card.length() - 1);
    }

    private boolean changeInScores(int []oldScores,int []newScores)
    {
        for (int i=0;i<oldScores.length;i++)
	    {
		if (oldScores[i]!=newScores[i])
		    return true;
	    }
        return false;
    }

    private ArrayList<LinkedList<String>> extractPlayerHands(String gameState,int numPlayers) throws Exception
    {
        ArrayList<LinkedList<String>> hands = new ArrayList<LinkedList<String>>();

        String[] lines = gameState.split("\n");
        //ignore line 0
        for (int i=0;i<numPlayers;i++)
	    {
		hands.add(new LinkedList<String>());
		String[] parts = lines[i+1].split(": ");
		//ignore parts[0]
		if (parts.length!=2)
		    {
			continue;
		    }
		String [] cards = parts[1].split(", ");
		for (String card : cards)
		    hands.get(i).add(card);
		// Scanner sc = new Scanner(parts[1]);
		// sc.useDelimiter("[,\\s+\n]");

		// while (sc.hasNext())
		//     {
		// 	hands.get(i).add(sc.next());
		//     }
	    }
        return hands;
    }

    private int[] extractPlayerScores(String gameState,int numPlayers) throws Exception
    {
        int []scores = new int[numPlayers];
        int offset;
        String[] lines = gameState.split("\n");
        //ignore line 0 and next "numPlayers" lines
        offset = 1+numPlayers;
	if (offset > lines.length)
	    return null;
        while (offset < lines.length && (lines[offset].length()==0))
            offset++;
        for (int i=0;i<numPlayers && i+1+numPlayers < lines.length;i++)
	    {
		String[] parts = lines[i+1+numPlayers].split(":");
		//ignore parts[0]
		//split by space
		if (1 < parts.length) {
		    Scanner sc = new Scanner(parts[1]);
		    sc.useDelimiter("[,\n\\s+]");
		    //first nonzero length word would be score
		    scores[i] = sc.nextInt();
		} else {
		    return null;
		    //		    scores[i] = -1;
		}
	    }
        return scores;
    }


}
