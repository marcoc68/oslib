﻿//+------------------------------------------------------------------+
//|                                                      runs-01.mq5 |
//|                                         Copyright 2020, OS Corp. |
//|                                                http://www.os.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "1.001"

#include <Files\FileTxt.mqh>
//+------------------------------------------------------------------+
//| Script para testar estatisticas de mudanca de precos             |
//+------------------------------------------------------------------+
input int QTD_MINUTOS   = 21;
input int LEN_CHUNK_INI = 1;
input int LEN_CHUNK_FIM = 10;

void OnStart(){
   //datetime from = D'2020.02.10 13:58:00';
   //datetime to   = D'2020.02.10 14:14:00'; //TimeCurrent();

   //datetime from = D'2020.02.13 09:45:00';
   //datetime to   = D'2020.02.13 09:54:00'; //TimeCurrent();

   datetime from = D'2021.02.24 15:30:00';
   datetime to   = D'2021.02.24 16:30:00'; //TimeCurrent();

   int     run  []; //vetor de mudancas de precos
   int     run1 []; //vetor de quantidade de mudancas de preco positivas
   int     run2 []; //vetor de quantidade de mudancas de preco negativas
   MqlTick ticks[]; //vetor de ticks que serao processados;
   
   double  tickSize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);

   int     ir  = 0; //indice do vetor ir
   int     ir1 = 0; //indice do vetor ir1
   int     ir2 = 0; //indice do vetor ir2

   int    qtdTicks = 0;
   int    lenChunk = LEN_CHUNK_INI; // chunk eh o tamanho da run medido em ticks...
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
   
   
     for(int j=0; j<1; j++){
   //while(true){
       

     //Obtendo o ultimo minuto de ticks...
     //Print(__FUNCTION__,": Obtendo ticks a processar...");
     qtdTicks = CopyTicksRange(_Symbol,ticks,COPY_TICKS_INFO,TimeCurrent()*1000 - (60000*QTD_MINUTOS), TimeCurrent()*1000 );
     //qtdTicks = CopyTicksRange(_Symbol,ticks,COPY_TICKS_INFO,from*1000                     , to*1000            );

       strRun = "";
     //for( varLenChunk=lenChunk-lenChunk/2; varLenChunk< lenChunk+lenChunk/2+1; varLenChunk++ ){
     //for( varLenChunk=1                  ; varLenChunk<=lenChunk+lenChunk    ; varLenChunk++ ){
       for( varLenChunk=LEN_CHUNK_INI      ; varLenChunk<=LEN_CHUNK_FIM        ; varLenChunk++ ){
           
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
           if( qtdRuns2==0){qtdRuns2=1;}
         //strRun+=("] " + IntegerToString(qtdRuns2)+ " " + IntegerToString(((qtdRuns1/qtdRuns2)-1)*100) +"%\n");
           strRun+=("] " + IntegerToString(qtdRuns2)+ " " + DoubleToString(((double)(qtdRuns1-qtdRuns2)/(double)(qtdRuns1+qtdRuns2))*100.0,2) +"%\n");
           
       }
       strRun = "=========================================\n"+
                "FROM: " + TimeToString(from)+
                "  TO: " + TimeToString(to  )+ 
                "\n=========================================\n" +
                strRun                                +
                  "========================================="   ;
       Comment(strRun);
       Print(strRun);
       Sleep(60000);
   }
}
//+------------------------------------------------------------------+
