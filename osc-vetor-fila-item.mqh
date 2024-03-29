﻿//+------------------------------------------------------------------+
//|                                          osc-vetor-fila_item.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+---------------------------------------------------------------------+
//| Vetor circular baseado em filas visando rapido calculo de medias.   |
//+---------------------------------------------------------------------+
#property description "Vetor circular baseado em filas visando rapido calculo de medias."

#include <Generic\Queue.mqh>
#include <oslib/osc-padrao.mqh>

struct Item{
    datetime time    ; // tempo do elemento. Elementos devem ser adicionados em ordem crescente de tempo
    double   val     ; // valor usado no calculo da media
    double   peso    ; // peso usado no calculo da media
    double   pesoAcum; // peso acumulado na ocasiao
    double   media   ; // media calculada
};

class osc_vetor_fila_item : public osc_padrao {
private:
    // ---------usadas em getMaxMin
    double m_newMin,m_indNewMin; 
    double m_newMax,m_indNewMax;
    int    m_qtdAux;
    // ---------usadas em getMaxMin

protected:
    CQueue<datetime> m_filaTime      ;
    CQueue<double>   m_filaVal       ;
    CQueue<double>   m_filaPeso      ;
    CQueue<double>   m_filaPesoAcum  ;
    CQueue<double>   m_filaMedia     ;
public:
    void   peek         (Item &item);
    void   dequeue      (Item &item);
    void   add          (Item &item);
    void   clear        ();
    void   trim         ();
    long   count        (){ return m_filaVal.Count(); } // todas as filas tem o mesmo tamanho. Poderia usar qualquer uma.
    int    getMaxMin    (double &max, double &min, double &distancia); // grava os valores maximos e minimos respectivamente. Retorna -1 se algo der errado;
    int    copyPriceTo  (double &price[]);
};

void osc_vetor_fila_item::add(Item &item){
    m_filaTime    .Enqueue(item.time    );
    m_filaVal     .Enqueue(item.val     );
    m_filaPeso    .Enqueue(item.peso    );
    m_filaPesoAcum.Enqueue(item.pesoAcum);
    m_filaMedia   .Enqueue(item.media   );
}

void osc_vetor_fila_item::peek(Item &item){
    item.time     = m_filaTime    .Peek();
    item.val      = m_filaVal     .Peek();
    item.peso     = m_filaPeso    .Peek();
    item.pesoAcum = m_filaPesoAcum.Peek();
    item.media    = m_filaMedia   .Peek();
}

void osc_vetor_fila_item::clear(){
    m_filaTime    .Clear();
    m_filaVal     .Clear();
    m_filaPeso    .Clear();
    m_filaPesoAcum.Clear();
    m_filaMedia   .Clear();
}

void osc_vetor_fila_item::dequeue(Item &item){
    item.time     = m_filaTime    .Dequeue();
    item.val      = m_filaVal     .Dequeue();
    item.peso     = m_filaPeso    .Dequeue();
    item.pesoAcum = m_filaPesoAcum.Dequeue();
    item.media    = m_filaMedia   .Dequeue();
}

void osc_vetor_fila_item::trim(){
    m_filaTime    .TrimExcess();
    m_filaVal     .TrimExcess();
    m_filaPeso    .TrimExcess();
    m_filaPesoAcum.TrimExcess();
    m_filaMedia   .TrimExcess();
}

//double m_newMin,m_indNewMin; 
//double m_newMax,m_indNewMax;
//int    m_qtdAux;
int osc_vetor_fila_item::getMaxMin(double &max, double &min, double &distancia){
 //trim();
   
    double vet[]                     ;
    m_qtdAux      = m_filaVal.Count();
 //int    lenVet = m_filaVal.CopyTo(vet);
                   m_filaVal.CopyTo(vet);
    m_newMin = vet[0]; m_indNewMin=0;
    m_newMax = vet[0]; m_indNewMax=0;
 //string info;
   
   //if(lenVet != qtd){
   //   //Print(":-( ERROR de INCONSISTENCIA: m_filaVal tem ", qtd, " elementos, mas foram copiados ", lenVet, " elementos! Verifique!!!");
   //}else{
   //   info = ":-| INFO: m_filaVal tem " + qtd + " elementos, e foram copiados " + lenVet+ " elementos!";
   //}
   
//  for(int i=0; i<lenVet; i++){
    for(int i=0; i<m_qtdAux; i++){
        if( MathIsValidNumber(vet[i]) && vet[i] != 0 ){
          //if( vet[i] > newMax ) newMax = vet[i];
          //if( vet[i] < newMin ) newMin = vet[i];
            if( vet[i] > m_newMax ) { m_newMax = vet[i];m_indNewMax=i;} else
            if( vet[i] < m_newMin ) { m_newMin = vet[i];m_indNewMin=i;}
        }
    }
   
    max = m_newMax;
    min = m_newMin;
   
    // max aconteceu apos min, distancia serah positiva, senao negativa.
    if( (m_indNewMax-m_indNewMin)<0 ){ 
      //distancia = (max-min)*-1;
        distancia = ( log(max)-log(min) )*-1;
    }else{
      //distancia = (max-min)   ;
        distancia =   log(max)-log(min);
    }
   
   //info = info + " max=" + max + " newMax=" + newMax + " min=" + min + " newMin=" + newMin;
   //Print(info);
    return 0;
}

int osc_vetor_fila_item::copyPriceTo(double &price[]){ return m_filaVal.CopyTo(price); }
