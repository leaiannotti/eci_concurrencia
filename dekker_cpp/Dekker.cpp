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
atomic<bool> *FLAG_0;
atomic<bool> *FLAG_1;

// atomic_flag flag_atomic = ATOMIC_FLAG_INIT;

void rel_mutex(int i)
{
   if(i==0){
      *TURN=1;
      FLAG_0->store(false,std::memory_order_seq_cst);
   }
   if(i==1){
      *TURN=0;
      FLAG_1->store(false,std::memory_order_seq_cst);
   }

}


void get_mutex(int i)
{

   if(i==0){
      cout<<"Pidiendo el mutex: 0 - 1"<<endl;
      FLAG_0->store(true,memory_order_seq_cst);
            cout<<"Pidiendo el mutex: 0 - 2"<<endl;
      while(FLAG_1->load(memory_order_seq_cst)){
            cout<<"Pidiendo el mutex: 0 - 3"<<endl;
           if(*TURN==1){
                 cout<<"Pidiendo el mutex: 0 - 4"<<endl;
            FLAG_0->store(false,memory_order_seq_cst);
                  cout<<"Pidiendo el mutex: 0 - 5"<<endl;
            while(*TURN==1){}
                  cout<<"Pidiendo el mutex: 0 - 6"<<endl;
            FLAG_0->store(true,memory_order_seq_cst);
                  cout<<"Pidiendo el mutex: 0 - 7"<<endl;
         }
      }
   }
   if(i==1){
         cout<<"Pidiendo el mutex: 1 - 1"<<endl;
      FLAG_1->store(true,memory_order_seq_cst);
            cout<<"Pidiendo el mutex: 1 - 2"<<endl;
      while (FLAG_0->load(memory_order_seq_cst)){
            cout<<"Pidiendo el mutex: 1 - 3"<<endl;
         if(*TURN==0){
               cout<<"Pidiendo el mutex: 1 - 4"<<endl;
            FLAG_1->store(false,memory_order_seq_cst);
                  cout<<"Pidiendo el mutex: 1 - 5"<<endl;
            while(*TURN==0){}
                  cout<<"Pidiendo el mutex: 1 - 6"<<endl;
            FLAG_1->store(true,memory_order_seq_cst);
                  cout<<"Pidiendo el mutex: 1 - 7"<<endl;
         }
      }
   }
}





void process(int i)
{
   for(int k=1;k<=4;k++){
   	    cout<<"Pidiendo el mutex: "<<i<<endl;
       get_mutex(i);
       cout<<"Obteniendo el mutex: "<<i<<endl;
       for(int m=1;m<=5;m++){
           cout<<"Proceso: "<<i<<". Numero: "<<k<<" ("<<m<<"/5)"<<endl;
         }
       cout<<"Por dejar el mutex: "<<i<<endl;
      rel_mutex(i);
      cout<<"Soltando el mutex: "<<i<<endl;
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
   FLAG_0 = (atomic<bool>*) shmat(Id, NULL, 0);
   FLAG_1 = (atomic<bool>*) shmat(Id, NULL, 0);
   FLAG_0->store(false,memory_order_seq_cst);
   FLAG_1->store(false,memory_order_seq_cst);
   sigset(SIGINT, del);

   pid_t pid = fork();

   if (pid == 0) {
      process(0);
      cout<<"TERMINA: 0"<<endl;
      exit(0);
   }
   
   pid_t pid2 = fork();
   
   if (pid2 == 0) {
      process(1);
      cout<<"TERMINA: 1"<<endl;
      exit(0);
   }
	wait(&pid2);
   	wait(&pid);
   del(0);

   return 0;
}
