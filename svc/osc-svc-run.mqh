﻿//+------------------------------------------------------------------+
//|                                                      oss-run.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, OS Corp."
#property link      "http://www.os.org"
#property version   "1.00"
#include "osc-svc.mqh"
//+------------------------------------------------------------------+
//| Script para testar estatisticas de mudanca de precos             |
//+------------------------------------------------------------------+

struct Run{
    ushort len;
    ushort repeticoes;
    uint   qtdPositivas;
    uint   qtdNegativas;
};

class OscSvcRun : public OscSvc{
public:
  void onStart(int pTimeFrameInMinutes, int pLenChunkIni, int pLenChunkFim, string pSimbolo, long pSleep);
  void calcRuns(MqlTick &pVetTicks[], uint pQtdTicks, int pLenChunkIni, int pLenChunkFim, double pTickSize);
};

void OscSvcRun::onStart(int pTimeFrameInMinutes, int pLenChunkIni, int pLenChunkFim, string pSimbolo, long pSleep){
   datetime from = D'2020.02.10 13:58:00';
   datetime to   = D'2020.02.10 14:14:00'; //TimeCurrent();

   MqlTick ticks[]; //vetor de ticks que serao processados;
   
   double  tickSize = SymbolInfoDouble(pSimbolo,SYMBOL_TRADE_TICK_SIZE);
   double  ponto    = SymbolInfoDouble(pSimbolo,SYMBOL_POINT          );
   Print("SVCRUN PROCESSANDO ATIVO:",pSimbolo," PONTO:",ponto," TICK_SIZE:",tickSize);

   int    qtdTicks = 0;
   int    lenChunk = pLenChunkIni; // chunk eh o tamanho da run medido em ticks...
   int    chunk    = 0;
   //string strRun   ="";

   // loop de execucao do servico
   while(true){
     //Obtendo o ultimo minuto de ticks...
     //Print(__FUNCTION__,": Obtendo ticks a processar...");
       qtdTicks = CopyTicksRange(pSimbolo,ticks,COPY_TICKS_INFO,TimeCurrent()*1000 - (60000*pTimeFrameInMinutes), TimeCurrent()*1000 );
     //qtdTicks = CopyTicksRange(SIMBOLO ,ticks,COPY_TICKS_INFO,from*1000                                        , to*1000            );
     if( qtdTicks > 0 ) calcRuns(ticks,qtdTicks,pLenChunkIni,pLenChunkFim,tickSize);
     Sleep(pSleep);
   }
}


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
//|             : houve 10 ocorrencias de repeticoes de 1(uma) run;                                              |
//|             : houve 10 ocorrencias de repeticoes de 1(uma) run;                                              |
//+--------------------------------------------------------------------------------------------------------------+
void OscSvcRun::calcRuns(const MqlTick &pVetTicks[], uint pQtdTicks, int pLenChunk, double pTickSize, double &run1[], double &run2[]){

   int     run  []; //vetor de mudancas de precos
 //int     run1 []; //vetor de quantidade de mudancas de preco positivas
 //int     run2 []; //vetor de quantidade de mudancas de preco negativas
   
   int    ir       = 0        ; //indice do vetor run
   int    lenChunk = pLenChunk; // chunk eh o tamanho da run medido em ticks...
   int    chunk    = 0;
   int    vp       = 0;

   int    p           ; //preco          normalizado para unidade de ticks;
   int    pAnt        ; //preco anterior normalizado para unidade de ticks;
   int    dp       = 0; //quantidade de ticks entre p e pAnt;
   int    qtdRuns1 = 0;
   int    qtdRuns2 = 0;
 //string strRun   ="";
   int    lenVetTicks = ArraySize(pVetTicks);
   
   ArrayResize(run1,10,10);
   ArrayResize(run2,10,10);
   ArrayInitialize(run1,0);
   ArrayInitialize(run2,0);
   
   p=0; pAnt=0; vp=0; ir=0; chunk=0; 
   ArrayResize(run,10,10);
   ArrayInitialize(run,0);
   
   // varrendo o array de ticks e montando o array de runs (run)...
   for( uint i=1; i<pQtdTicks && i<lenVetTicks; i++ ){

       // delta p (dp) eh a quantidade de ticks entre p e pAnt...
       dp = (int)( (pVetTicks[i].ask - pVetTicks[i-1].ask) / pTickSize );
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


//+--------------------------------------------------------------------------------------------------------------+
//| pVetTicks   : vetor de ticks que serao processados                                                           |
//| pQtdTicks   : quantidade de ticks a processar                                                                |
//| pLenChunkIni: tamanho inicial dos chunks(runs) que serao processados                                         |
//| pLenChunkFim: tamanho final   dos chunks(runs) que serao processados                                         |
//| pTickSize   : tamanho do tick                                                                                |
//+--------------------------------------------------------------------------------------------------------------+
void OscSvcRun::calcRuns(MqlTick &pVetTicks[], uint pQtdTicks, int pLenChunkIni, int pLenChunkFim, double pTickSize){

   int     run  []; //vetor de mudancas de precos
   int     run1 []; //vetor de quantidade de mudancas de preco positivas
   int     run2 []; //vetor de quantidade de mudancas de preco negativas
   
   int    ir       = 0; //indice do vetor run
   int    lenChunk = pLenChunkIni; // chunk eh o tamanho da run medido em ticks...
   int    chunk    = 0;
   int    vp       = 0;

   int    p           ; //preco          normalizado para unidade de ticks;
   int    pAnt        ; //preco anterior normalizado para unidade de ticks;
   int    dp       = 0; //quantidade de ticks entre p e pAnt;
   int    qtdRuns1 = 0;
   int    qtdRuns2 = 0;
   string strRun   ="";
   int    lenVetTicks = ArraySize(pVetTicks);
   
   ArrayResize(run1,10,10);
   ArrayResize(run2,10,10);
   ArrayInitialize(run1,0);
   ArrayInitialize(run2,0);
   
   for( lenChunk=pLenChunkIni; lenChunk<=pLenChunkFim; lenChunk++ ){
       
       p=0; pAnt=0; vp=0; ir=0; chunk=0; 
       ArrayResize(run,10,10);
       ArrayInitialize(run,0);
       
       // varrendo o array de ticks e montando o array de runs (run)...
       for( uint i=1; i<pQtdTicks && i<lenVetTicks; i++ ){

           // delta p (dp) eh a quantidade de ticks entre p e pAnt...
           dp = (int)( (pVetTicks[i].ask - pVetTicks[i-1].ask) / pTickSize );
           p  = pAnt + dp;
           if( p == pAnt ){ continue; }

           chunk  = chunk+dp;
           
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
       
       // a partir daqui eh print da saida e deveria se feito pela funcao que chamou esta.
       
       
       //ArrayPrint(run1);
       //ArrayPrint(run2);

       //montando a string com o vetor de runs (serve para debug)...
       //strRun = strRun+ IntegerToString(lenChunk)+"[";
       //for( int i=0; i<ArraySize(run); i++ ){
       //    if( run[i]==1 || run[i]==-1 ){
       //        strRun = strRun+IntegerToString(run[i]);
       //    }
       //}
       //strRun=strRun+"]"+IntegerToString(ArraySize(run));
/*
       qtdRuns1=0;
       qtdRuns2=0;

       uint lenRun1 = ArraySize((run1);
       uint lenRun2 = ArraySize((run2);
       Run  vetSaidaRun[];
       uint iVetSaida = 0;

struct Run{
    ushort len;
    ushort repeticoes;
    uint   qtdPositivas;
    uint   qtdNegativas;
}

       for(int i1=0, int i2=0; i1<lenRun1 || i2<lenRun2; ){
       
           Run r;
           
           if(i1==i2){
              r.len                    = lenChunk;
              r.repeticoes             = i1      ;
              r.qtdPositivas           = run1[i1];
              r.qtdNegativas           = run2[i2];
              vetSaidaRun[iVetSaida++] = r;
              i1++;i2++;
           }else if(i1>i2){
              r.len                    = lenChunk;
              r.repeticoes             = i1      ;
              r.qtdPositivas           = run1[i1];
              r.qtdNegativas           = run2[i2];
              vetSaidaRun[iVetSaida++] = r;
              i1++;i2++;
           }else if(i2<i1){
           }
       
       }
*/
       qtdRuns1=0;
       qtdRuns2=0;

       // Calculando e apresentando o vetor de runs positivas...
       strRun += IntegerToString(lenChunk);
       strRun += "[POS"  ;
       for(int i=0; i<ArraySize(run1); i++){
           if(run1[i]==0){continue;}
           strRun+=(" "+i+":"+run1[i]);
           qtdRuns1+=(i*run1[i]);
       }
       strRun+=("] " + IntegerToString(qtdRuns1)+"\n");
       
       // Calculando e apresentando o vetor de runs negativas...
       strRun+=lenChunk;
       strRun+="[NEG";
       for( int i=0; i<ArraySize(run2); i++ ){
           if(run2[i]==0){continue;}
           strRun+=(" "+i+":"+run2[i]);
           qtdRuns2+=(i*run2[i]);
       }
       strRun+=("] " + IntegerToString(qtdRuns2)+ " " + IntegerToString(((double)(qtdRuns1-qtdRuns2)/(double)(qtdRuns1+qtdRuns2))*100) +"%\n");
   }    
   //Comment(strRun);
   //Print("PROCESSANDO ATIVO:",pSimbolo," PONTO:",ponto," TICK_SIZE:",pTickSize);
   //Print("SVC_RUN:",SVC_RUN);
   //Print(strRun);
   broadcastEvent(SVC_RUN, 0, 0,strRun);
   //Sleep(250);
}

/*
void OscSvcRun::onStartAnt(int pTimeFrameInMinutes, int pLenChunkIni, int pLenChunkFim, string pSimbolo){

//void OnStart(){
   datetime from = D'2020.02.10 13:58:00';
   datetime to   = D'2020.02.10 14:14:00'; //TimeCurrent();

   int     run  []; //vetor de mudancas de precos
   int     run1 []; //vetor de quantidade de mudancas de preco positivas
   int     run2 []; //vetor de quantidade de mudancas de preco negativas
   MqlTick ticks[]; //vetor de ticks que serao processados;
   
   double  tickSize = SymbolInfoDouble(pSimbolo,SYMBOL_TRADE_TICK_SIZE);
   double  ponto    = SymbolInfoDouble(pSimbolo,SYMBOL_POINT          );
   Print("SVCRUN PROCESSANDO ATIVO:",pSimbolo," PONTO:",ponto," TICK_SIZE:",tickSize);

   int     ir  = 0; //indice do vetor ir
   int     ir1 = 0; //indice do vetor ir1
   int     ir2 = 0; //indice do vetor ir2

   int    qtdTicks = 0;
   int    lenChunk = pLenChunkIni; // chunk eh o tamanho da run medido em ticks...
   int    chunk    = 0;
   //int    chunkN   = 0; // chunk de baixa
   //int    chunkP   = 0; // chunk de alta
   //int    chunkN   = 0; // chunk de baixa
   int    vp       = 0;

   int    p, pAnt, dp  = 0;
   string strRun ="";

   int varLenChunk = 0;
   pAnt = 0;
   double qtdRuns1 = 0;
   double qtdRuns2 = 0;
   
   ArrayResize(run1,10,10);
   ArrayResize(run2,10,10);
   ArrayInitialize(run1,0);
   ArrayInitialize(run2,0);
   
   
   //for(int j=0; j<1; j++){
     while(true){
       

     //Obtendo o ultimo minuto de ticks...
     //Print(__FUNCTION__,": Obtendo ticks a processar...");
       qtdTicks = CopyTicksRange(pSimbolo,ticks,COPY_TICKS_INFO,TimeCurrent()*1000 - (60000*pTimeFrameInMinutes), TimeCurrent()*1000 );
     //qtdTicks = CopyTicksRange(SIMBOLO,ticks,COPY_TICKS_INFO,from*1000                     , to*1000            );

       strRun = "";
     //for( varLenChunk=lenChunk-lenChunk/2; varLenChunk< lenChunk+lenChunk/2+1; varLenChunk++ ){
     //for( varLenChunk=1                  ; varLenChunk<=lenChunk+lenChunk    ; varLenChunk++ ){
       for( varLenChunk=pLenChunkIni       ; varLenChunk<=pLenChunkFim         ; varLenChunk++ ){
           
           p=0; pAnt=0; vp=0; ir=0; chunk=0; //chunkN=0; chunkP=0; 
           ArrayResize(run,10,10);
           ArrayInitialize(run,0);
           
           // varrendo o array de ticks...
           for( int i=1; i<qtdTicks; i++ ){
    
               // delta p (dp) eh a quantidade de ticks entre p e pAnt...
               dp = (int)( (ticks[i].ask - ticks[i-1].ask) / tickSize );
               p  = pAnt + dp;
               if( p == pAnt ){ continue; }
    
               chunk  = chunk+dp;
               
             //Print("pAnt=",pAnt," p=",p," dp=",dp, " chunkP=",chunkP, "chunkN=",chunkN);
               if( ArraySize(run)<= ir ) ArrayResize(run,ir+10,10);
               if( chunk>=  varLenChunk ){ run[ir++] =  1; chunk=0; }
               if( chunk<= -varLenChunk ){ run[ir++] = -1; chunk=0; }
             //if( p>pAnt && chunkP>= varLenChunk ){ run[ir++] =  1; chunkN=0; chunkP=0; }
             //if( p<pAnt && chunkN<=-varLenChunk ){ run[ir++] = -1; chunkN=0; chunkP=0; }
               
               pAnt = p;
           }
    
           //ArrayPrint(run);
           
           // montando o vetor de quantidade de runs...
           int pos=0; int neg =0;
           int r  =0; int rAnt=0;
           ArrayInitialize(run1,0);
           ArrayInitialize(run2,0);
           for( int i=0; i<ArraySize(run); i++ ){

               if( ArraySize(run1) == pos+1 ){ 
                   ArrayResize(run1,ArraySize(run1)+10, 10);
                   for(int t=pos+1; t<ArraySize(run1); t++){run1[t]=0;}
               }
               if( ArraySize(run2) == neg+1 ){ 
                   ArrayResize(run2,ArraySize(run2)+10, 10);
                   for(int t=neg+1; t<ArraySize(run2); t++){run2[t]=0;}
               }

               // saindo do laco se os valores nao sao chunks...
               if( run[i] != 1 && run[i] != -1) break;

               if(i==0){
                   if(run[i]>0){pos++;}else{neg++;}
               }else{
                  if(run[i]==run[i-1]){
                      // igual ao valor anterior, acumulamos
                      if(run[i]>0){pos++;}else{neg++;}
                  }else{
                      // diferente do valor anterior, salvamos o acumulado anterior no vetor
                      // e voltamos a acumular...  
                      if(run[i-1]>0){run1[pos]++; pos=0; neg++;}else{run2[neg]++; neg=0; pos++;}
                  }
               }
           }
           
           if( pos>0 )run1[pos]++;
           if( neg>0 )run2[neg]++;
           
           //ArrayPrint(run1);
           //ArrayPrint(run2);

           // montando a string que serah apresentada na tela...
           //strRun = strRun+ IntegerToString(varLenChunk)+"[";
           //for( int i=0; i<ArraySize(run); i++ ){
           //    if( run[i]==1 || run[i]==-1 ){
           //        strRun = strRun+IntegerToString(run[i]);
           //    }
           //}
           //strRun=strRun+"]"+IntegerToString(ArraySize(run));
           qtdRuns1=0;
           qtdRuns2=0;

           // Calculando e apresentando o vetor de runs positivas...
           strRun+=varLenChunk;
           strRun+="[POS";
           for(int i=0; i<ArraySize(run1); i++){
               if(run1[i]==0){continue;}
               strRun+=(" "+i+":"+run1[i]);
               qtdRuns1+=(i*run1[i]);
           }
           strRun+=("] " + IntegerToString(qtdRuns1)+"\n");
           
           // Calculando e apresentando o vetor de runs negativas...
           strRun+=varLenChunk;
           strRun+="[NEG";
           for( int i=0; i<ArraySize(run2); i++ ){
               if(run2[i]==0){continue;}
               strRun+=(" "+i+":"+run2[i]);
               qtdRuns2+=(i*run2[i]);
           }
         //if( qtdRuns2==0){qtdRuns2=1;}
         //strRun+=("] " + IntegerToString(qtdRuns2)+ " " + IntegerToString(((qtdRuns1/qtdRuns2)-1                  )*100) +"%\n");
           strRun+=("] " + IntegerToString(qtdRuns2)+ " " + IntegerToString(((qtdRuns1-qtdRuns2)/(qtdRuns1+qtdRuns2))*100) +"%\n");
       }    
       //Comment(strRun);
       //Print("PROCESSANDO ATIVO:",pSimbolo," PONTO:",ponto," TICK_SIZE:",tickSize);
       //Print("SVC_RUN:",SVC_RUN);
       Print(strRun);
       broadcastEvent(SVC_RUN, 0, 0,strRun);
       Sleep(250);
   }
}
*/
//+------------------------------------------------------------------+
  