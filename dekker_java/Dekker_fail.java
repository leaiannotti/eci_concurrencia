
public class Dekker_fail {
	  public Dekker_fail () {
	    flag[0] = false; flag[1] = false; turn = 0;
	  }
	 
	  public void getMutex(int t) {
	    int other;
	 
	    other = 1-t;
	    flag[t] = true;
	    while (flag[other] == true) {
	      if (turn == other) {
	        flag[t] = false;
	        while (turn == other)
	          ;
	        flag[t] = true;
	      }
	    }
	  }
	 
	  public void relMutex(int t) {
	    turn = 1-t;
	    flag[t] = false;
	  }
	 
	  private int turn;
	  private boolean [] flag = new boolean [2];

}
