#include <signal.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <stdlib.h>
#include <unistd.h>
#include <iostream>
using namespace std;

std::atomic<int> tes(1);
int Id; /* Segment Id */
int *TURN;
int *FLAG_0;
int *FLAG_1;

void get_out_of_critical(int i)
{
   if(i==0){
      *TURN=1;i=1;
      *FLAG_0=0;
   }
   else{
      *TURN=0;i=0;
      *FLAG_1=0;
   }

}

void get_in_critical(int i)
{
   if(i==0){
      *FLAG_0=1;
      while(*FLAG_1!=0){
           if(*TURN==1){
            *FLAG_0 = 0;
            while(*TURN==1){}
         *FLAG_0=1;
         }
      }
   }
   else{
   *FLAG_1=1;
   while (*FLAG_0!=0){
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
   for(int k=1;k<=5;k++){
       get_in_critical(i);
       for(int m=1;m<=5;m++){
           cout<<"Proceso: "<<i<<". Numero: "<<k<<" ("<<m<<"/5)"<<endl;
                   //sleep(1);
      }
      get_out_of_critical(i);
   }
}


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