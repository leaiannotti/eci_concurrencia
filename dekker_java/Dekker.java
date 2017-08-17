import java.util.concurrent.atomic.AtomicIntegerArray;

public class Dekker {
	  public Dekker () {
	    flag.set(0,0); flag.set(1,0); turn = 0;
	  }
	 
	  public void getMutex(int t) {
	    int other;
	 
	    other = 1-t;
	    flag.set(t,1);
	    while (flag.get(other) == 1) {
	      if (turn == other) {
	        flag.set(t,0);
	        while (turn == other)
	          ;
	        flag.set(t,1);
	      }
	    }
	  }
	 
	  public void relMutex(int t) {
	    turn = 1-t;
	    flag.set(t,0);
	  }
	 
	  private volatile int turn;
	  private AtomicIntegerArray flag = new AtomicIntegerArray(2);
	}

//¿Por que esta implementacion anda y la otra no?

/*Lo que sucede aquí es que, la variable turn no ha sido declarada como volátil, 
 * el compilador asume que la variable de condición es una constante ya que no se espera que otro subproceso lo modifique.
 * Si la declaramos como volatil  el compilador ya no puede suponer que la condición de variable no será modificada por un 
 * subproceso concurrente y, a su vez, no podrá realizar una optimización erronea (erronea en el contexto de nuestro problema)
 * Ademas tenemos que usar objetos atomicos para nuestras variables flag.*/
 