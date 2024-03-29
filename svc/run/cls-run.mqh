﻿//+------------------------------------------------------------------+
//|                                                      oss-run.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, OS Corp."
#property link      "http://www.os.org"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Classe para contabilizar estatisticas de mudanca de precos.      |
//+------------------------------------------------------------------+

struct Run{
    ushort len;
    ushort repeticoes;
    uint   qtdPositivas;
    uint   qtdNegativas;
};

class OscRun{
public:
  void   calcRuns(const MqlTick &pVetTicks[], const int pQtdTicks, const int pLenChunk, const double pTickSize, int &run1[], int &run2[]);
  void   calcRuns(const double  &pVetPrice[], const int pQtdTicks, const int pLenChunk, const double pTickSize, int &run1[], int &run2[]);
  string toString(const int &run1[], const int &run2[], int lenChunk);
  double calcIndice(const int &run1[], const int &run2[]);

};

//+--------------------------------------------------------------------------------------------------------------+
//| pVetTicks   : vetor de ticks que serao processados                                                           |
//| pQtdTicks   : quantidade de ticks a processar                                                                |
//| pLenChunk   : tamanho inicial do chunk em ticks                                                              |
//| pTickSize   : tamanho do tick                                                                                |
//| run1        : vetor de runs positivas. retorno por referencia.                                               |
//| run2        : vetor de runs negativas. retorno por referencia.                                               |
//| OBS         : Em run1 e run2, a posicao do vetor eh quantas vezes a run se repetiu seguidamente e o valor na |
//|             : posicao eh quantas vezes a repeticao se concretizou.                                           |
//| Ex          : run1{0,10,8,0,0,2} significa que                                                               |
//|             : houve 10 ocorrencias de repeticoes de 1(uma  ) run;                                            |
//|             : houve 08 ocorrencias de repeticoes de 2(duas ) runs seguidas                                   |
//|             : houve 02 ocorrencias de repeticoes de 5(cinco) runs seguidas;                                  |
//+--------------------------------------------------------------------------------------------------------------+
void OscRun::calcRuns(const MqlTick &pVetTicks[], const int pQtdTicks, const int pLenChunk, const double pTickSize, int &run1[], int &run2[]){
   double price[];
   int size = ArraySize(pVetTicks);
 //ArrayResize(price,pQtdTicks);
   ArrayResize(price,size);
   for(int i=0; i<size; i++){ price[i]=pVetTicks[i].ask;}
   calcRuns(price, pQtdTicks, pLenChunk, pTickSize, run1, run2);
}

//+--------------------------------------------------------------------------------------------------------------+
//| pVetPrice   : vetor de precos que serah processado                                                           |
//| pQtdTicks   : quantidade de ticks a processar                                                                |
//| pLenChunk   : tamanho inicial do chunk em ticks                                                              |
//| pTickSize   : tamanho do tick                                                                                |
//| run1        : vetor de runs positivas. retorno por referencia.                                               |
//| run2        : vetor de runs negativas. retorno por referencia.                                               |
//| OBS         : Em run1 e run2, a posicao do vetor eh quantas vezes a run se repetiu seguidamente e o valor na |
//|             : posicao eh quantas vezes a repeticao se concretizou.                                           |
//| Ex          : run1{0,10,8,0,0,2} significa que                                                               |
//|             : houve 10 ocorrencias de repeticoes de 1(uma  ) run;                                            |
//|             : houve 08 ocorrencias de repeticoes de 2(duas ) runs seguidas                                   |
//|             : houve 02 ocorrencias de repeticoes de 5(cinco) runs seguidas;                                  |
//+--------------------------------------------------------------------------------------------------------------+
void OscRun::calcRuns(const double &pVetPrice[], const int pQtdTicks, const int pLenChunk, const double pTickSize, int &run1[], int &run2[]){

   int    run[]               ; //vetor de mudancas de precos   
   int    ir       = 0        ; //indice do vetor run
   int    lenChunk = pLenChunk; //chunk eh o tamanho da run medido em ticks...
   int    chunk    = 0;
   int    vp       = 0;
   int    p        = 0; //preco          normalizado para unidade de ticks;
   int    pAnt     = 0; //preco anterior normalizado para unidade de ticks;
   int    dp       = 0; //quantidade de ticks entre p e pAnt;
   int    qtdRuns1 = 0;
   int    qtdRuns2 = 0;
   int    lenVetPrice = ArraySize(pVetPrice);
   
   ArrayResize(run1,10,10);
   ArrayResize(run2,10,10);
   ArrayInitialize(run1,0);
   ArrayInitialize(run2,0);
   
   ArrayResize(run,10,10);
   ArrayInitialize(run,0);
   
   // varrendo o array de ticks(precos) e montando o array de runs (run)...
   for( int i=1; i<pQtdTicks && i<lenVetPrice; i++ ){

       // delta p (dp) eh a quantidade de ticks entre p e pAnt...
       dp = (int)( (pVetPrice[i]     - pVetPrice[i-1]    ) / pTickSize );
     //dp = (int)( (pVetTicks[i].ask - pVetTicks[i-1].ask) / pTickSize );
       p  = pAnt + dp;
       if( p == pAnt ){ continue; }

       chunk = chunk+dp;
       
     //Print("pAnt=",pAnt," p=",p," dp=",dp, " chunkP=",chunkP, "chunkN=",chunkN);
       if( ArraySize(run)<= ir ) ArrayResize(run,ir+10,10);
       if( chunk>=  lenChunk ){ run[ir++] =  1; chunk=0; }
       if( chunk<= -lenChunk ){ run[ir++] = -1; chunk=0; }
       
       pAnt = p;
   }

   //ArrayPrint(run);
   
   // montando os vetores de quantidade de runs...
   int pos=0; int neg =0;
   int r  =0; int rAnt=0;
   ArrayInitialize(run1,0);
   ArrayInitialize(run2,0);
   for( int i=0; i<ArraySize(run); i++ ){

       // ajutando tamanho de run1 e run2, caso tenham ficado pequenos...
       if( ArraySize(run1) == pos+1 ){ 
           ArrayResize(run1,ArraySize(run1)+10, 10);
           for(int t=pos+1; t<ArraySize(run1); t++){run1[t]=0;} // array cresceu, inicializa os campos novos com zeros...
       }
       if( ArraySize(run2) == neg+1 ){ 
           ArrayResize(run2,ArraySize(run2)+10, 10);
           for(int t=neg+1; t<ArraySize(run2); t++){run2[t]=0;}
       }

       // saindo do laco se os valores nao sao chunks...
       if( run[i] != 1 && run[i] != -1) break;

       // preeenchendo run1 e run2...
       if(i==0){
           if(run[i]>0){pos++;}else{neg++;}
       }else{
          if(run[i]==run[i-1]){
              // igual ao valor anterior, acumulamos
              if(run[i]>0){pos++;}else{neg++;}
          }else{
              // diferente do valor anterior, salvamos o acumulado anterior no vetor e voltamos a acumular...  
              if(run[i-1]>0){run1[pos]++; pos=0; neg++;}else
                            {run2[neg]++; neg=0; pos++;}
          }
       }
   }
   // complemento apos o final do laco
   if( pos>0 )run1[pos]++;
   if( neg>0 )run2[neg]++;       
   
   return;
}

string OscRun::toString(const int &run1[], const int &run2[], int lenChunk){
       int qtdRuns1=0;
       int qtdRuns2=0;
       string strRun = IntegerToString(lenChunk) + "[POS";

       // Calculando e apresentando o vetor de runs positivas...
       strRun += "[POS"  ;
       for(int i=0; i<ArraySize(run1); i++){
           if(run1[i]==0){continue;}
           strRun+=(" "+IntegerToString(i)+":"+IntegerToString(run1[i]) );
           qtdRuns1+=(i*run1[i]);
       }
       strRun+=("] " + IntegerToString(qtdRuns1)+"\n");
       
       // Calculando e apresentando o vetor de runs negativas...
       strRun+=IntegerToString(lenChunk);
       strRun+="[NEG";
       for( int i=0; i<ArraySize(run2); i++ ){
           if(run2[i]==0){continue;}
           strRun+=(" "+IntegerToString(i)+":"+IntegerToString(run2[i]) );
           qtdRuns2+=(i*run2[i]);
       }
       
       if(qtdRuns1+qtdRuns2 > 0){
           strRun+=("] " + IntegerToString(qtdRuns2)+ " " + DoubleToString(((double)(qtdRuns1-qtdRuns2)/(double)(qtdRuns1+qtdRuns2))*100.0, 0) +"%\n");
       }else{
           strRun+=("] " + IntegerToString(qtdRuns2)+ "0%\n");
       }
       return strRun;
}

double OscRun::calcIndice(const int &run1[], const int &run2[]){
       int qtdRuns1=0;
       int qtdRuns2=0;

       // Calculando o indice do vetor de runs positivas...
       for(int i=0; i<ArraySize(run1); i++){
           if(run1[i]==0){continue;}
           qtdRuns1+=(i*run1[i]);
       }
       
       // Calculando e apresentando o vetor de runs negativas...
       for( int i=0; i<ArraySize(run2); i++ ){
           if(run2[i]==0){continue;}
           qtdRuns2+=(i*run2[i]);
       }
       
       if(qtdRuns1+qtdRuns2 == 0) return 0;
       return (double)(qtdRuns1-qtdRuns2)/(double)(qtdRuns1+qtdRuns2);
}

//+------------------------------------------------------------------+
  