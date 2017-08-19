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
int Id;
int M_TURN;
int M_FLAG_0;
int M_FLAG_1;

atomic<int> *TURN;
atomic<bool> *FLAG_0;
atomic<bool> *FLAG_1;

void rel_mutex(int i)
{
   if(i==0){
      TURN->store(1,std::memory_order_seq_cst);
      FLAG_0->store(false,std::memory_order_seq_cst);
   }
   if(i==1){
      TURN->store(0,std::memory_order_seq_cst);
      FLAG_1->store(false,std::memory_order_seq_cst);
   }
	sleep(1);
}


void get_mutex(int i)
{

   if(i==0){

      FLAG_0->store(true,memory_order_seq_cst);
       //     cout<<"Pidiendo el mutex: 0 - 2"<<endl;
      while(FLAG_1->load(memory_order_seq_cst)){
         //   cout<<"Pidiendo el mutex: 0 - 3"<<endl;
           if(TURN->load(memory_order_seq_cst)==1){
           //      cout<<"Pidiendo el mutex: 0 - 4"<<endl;
            FLAG_0->store(false,memory_order_seq_cst);
             //     cout<<"Pidiendo el mutex: 0 - 5"<<endl;
            while(TURN->load(memory_order_seq_cst)==1){}
               //   cout<<"Pidiendo el mutex: 0 - 6"<<endl;
            FLAG_0->store(true,memory_order_seq_cst);
                 // cout<<"Pidiendo el mutex: 0 - 7"<<endl;
         }
      }
   }
   if(i==1){
       //  cout<<"Pidiendo el mutex: 1 - 1"<<endl;
      FLAG_1->store(true,memory_order_seq_cst);
         //   cout<<"Pidiendo el mutex: 1 - 2"<<endl;
      while (FLAG_0->load(memory_order_seq_cst)){
           // cout<<"Pidiendo el mutex: 1 - 3"<<endl;
         if(TURN->load(memory_order_seq_cst)==0){
             //  cout<<"Pidiendo el mutex: 1 - 4"<<endl;
            FLAG_1->store(false,memory_order_seq_cst);
               //   cout<<"Pidiendo el mutex: 1 - 5"<<endl;
            while(TURN->load(memory_order_seq_cst)==0){}
                 // cout<<"Pidiendo el mutex: 1 - 6"<<endl;
            FLAG_1->store(true,memory_order_seq_cst);
                 // cout<<"Pidiendo el mutex: 1 - 7"<<endl;
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



void del(int sig)
{
   (void) shmdt((char *) &TURN);
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

   M_TURN = shmget(IPC_PRIVATE, sizeof(int), 0600);
   TURN = (atomic<int>*) shmat(M_TURN, NULL, 0);
   TURN->store(0,memory_order_seq_cst);
   
   M_FLAG_0 = shmget(IPC_PRIVATE, sizeof(bool), 0600);
   FLAG_0 = (atomic<bool>*) shmat(M_FLAG_0, NULL, 0);
   FLAG_0->store(false,memory_order_seq_cst);
   
   M_FLAG_1 = shmget(IPC_PRIVATE, sizeof(bool), 0600);
   FLAG_1 = (atomic<bool>*) shmat(M_FLAG_1, NULL, 0);
   FLAG_1->store(false,memory_order_seq_cst);
   
   sigset(SIGINT, del);

   // OS X
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

//   Linux
//
//   if (fork() == 0) {
//      process(0);
//      exit(0);
//   }
//   
//   if (fork() == 0) {
//      process(1);
//      exit(0);
//   }
//   wait();
//   wait();
//   del(0);

   return 0;
}

// Por que funcionó este algoritmo y no el anterior?
//
// Al principio copiamos la implementación de Dekker que no andaba.
// Probamos con cambiar la variable TURN a volatil como lo habíamos hecho en JAVA
// pero teníamos el mismo comportamiento. Luego cambiamos las variables de FLAG y TURN
// a atómicas y le asignamos el tipo de orden de memoria como SC al load y store de cada una de ellas. 
// Esto permite setear y obtener las variables de forma atomica y respetando el modelo de SC. 
// Luego nos dimos cuenta que no funcionaba al querer correr los dos procesos, buscamos en internet y
// lo solucionamos cambiando la forma de obtener la  memoria para las variables (asignamos partes de memoria
// diferentes a cada una de las variables y no al mismo bloque de memoria como estabamos haciendo)
// y  el algoritmo funciono exitosamente.
