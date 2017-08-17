
 
class Test {
    final static int PASOS = 5000000;
 
    static int i = 0;
 
    static UnsafeCounter c = new UnsafeCounter ();
 
    //static Dekker_fail m = new Dekker_fail();
    static Dekker m = new Dekker();
    
 
    public static void main (String[] args) throws InterruptedException {
      System.out.println("Dekker Counter Demo");
 
      Thread[] thread = new Thread [2];
      for (i = 0; i < 2; i++) {
        thread[i] = new Thread (new Runnable () {
          int tid = i;
          public void run () {
            System.out.println("Running: "+tid);
            for (int s = 0; s < PASOS; s++) {
              m.getMutex(tid);
              c.increment();
              m.relMutex(tid);
            }
          }
        });
        thread[i].start();
      }
 
      for (int i = 0; i < 2; i++) thread[i].join();
        System.out.println("El contador final es: " + c.get() + ".");
    }
}


class UnsafeCounter {
    private int count;
    void increment () { count ++; }
    int get () { return count; }
}