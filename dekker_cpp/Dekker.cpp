#include <signal.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <stdlib.h>
#include <unistd.h>
#include <iostream>
#include <atomic>

using namespace std;

int tes;
int Id; /* Segment Id */
volatile int *TURN;
atomic<int> *FLAG_0;
atomic<int> *FLAG_1;

atomic_flag flag_atomic = ATOMIC_FLAG_INIT;

void rel_mutex(int i)
{
   if(i==0){
      *TURN=1;
      FLAG_0->store(0,std::memory_order_seq_cst);
   }
   else{
      *TURN=0;
      FLAG_1->store(0,std::memory_order_seq_cst);
   }

}


void get_mutex(int i)
{

   if(i==0){
      FLAG_0->store(1,memory_order_seq_cst);
      while(FLAG_1->load(memory_order_seq_cst) == 1){
           if(*TURN==1){
            FLAG_0->store(0,memory_order_seq_cst);
            while(*TURN==1){}
            FLAG_0->store(1,memory_order_seq_cst);
         }
      }
   }
   else{
      FLAG_1->store(1,memory_order_seq_cst);
      while (FLAG_0->load(memory_order_seq_cst) == 1){
         if(*TURN==0){
            FLAG_1->store(0,memory_order_seq_cst);
            while(*TURN==0){}
            FLAG_1->store(1,memory_order_seq_cst);
         }
      }
   }
}





void process(int i)
{
   for(int k=1;k<=2;k++){
       get_mutex(i);
       for(int m=1;m<=5;m++){
           cout<<"Proceso: "<<i<<". Numero: "<<k<<" ("<<m<<"/5)"<<endl;
         }
      rel_mutex(i);
   }
}


/*
 System.out.println("Running: "+tid);
            for (int s = 0; s < PASOS; s++) {
              m.getMutex(tid);
              c.increment();
              m.relMutex(tid);
            }*/

void del(int sig)
{
   (void) shmdt((char *) TURN);
   (void) shmdt((char *) &FLAG_0);
   (void) shmdt((char *) &FLAG_1);
   (void) shmctl(Id, IPC_RMID, NULL);
   exit(0);
}

int main()
{
   cout<<endl;
   Id = shmget(IPC_PRIVATE, sizeof(int)*100, 0600);

   if (Id == -1)
      exit(1);

   TURN = (int *) shmat(Id, NULL, 0);
   *TURN = 0;
   FLAG_0 = (atomic<int>*) shmat(Id, NULL, 0);
   FLAG_1 = (atomic<int>*) shmat(Id, NULL, 0);
   FLAG_0->store(0,memory_order_seq_cst);
   FLAG_1->store(0,memory_order_seq_cst);
   sigset(SIGINT, del);

   if (fork() == 0) {
      process(0);
      exit(0);
   }
   if (fork() == 0) {
      process(1);
      exit(0);
   }
   wait();
   wait();
   del(0);

   return 0;
}
