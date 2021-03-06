#include <signal.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <stdlib.h>
#include <unistd.h>
#include <iostream>
using namespace std;

int tes;
int Id; /* Segment Id */
int *TURN;
int *FLAG_0;
int *FLAG_1;

void rel_mutex(int i)
{
   if(i==0){
      *TURN=1;
      *FLAG_0=0;
   }
   else{
      *TURN=0;
      *FLAG_1=0;
   }

}


void get_mutex(int i)
{

   if(i==0){
      *FLAG_0=1;
      while(*FLAG_1==1){
           if(*TURN==1){
            *FLAG_0 = 0;
            while(*TURN==1){}
            *FLAG_0=1;
         }
      }
   }
   else{
      *FLAG_1=1;
      while (*FLAG_0==1){
         if(*TURN==0){
            *FLAG_1 = 0;
            while(*TURN==0){}
            *FLAG_1=1;
         }
      }
   }
}





void process(int i)
{
   for(int k=1;k<=10;k++){
       get_mutex(i);
       for(int m=1;m<=10;m++){
           cout<<"Proceso: "<<i<<". Numero: "<<k<<" ("<<m<<"/10)"<<endl;
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
   (void) shmdt((char *) FLAG_0);
   (void) shmdt((char *) FLAG_1);
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
   FLAG_0 = (int*) shmat(Id, NULL, 0);
   FLAG_1 = (int*) shmat(Id, NULL, 0);
   *FLAG_0 = 0;
   *FLAG_1 = 0;
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
