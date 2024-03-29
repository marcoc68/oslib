﻿//+------------------------------------------------------------------+
//|                                           osc-vetor-circular.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+---------------------------------------------------------------------+
//| Vetor circular de tamaho fixo visando rapido calculo de medias.     |
//+---------------------------------------------------------------------+
#property description "Vetor circular de tamaho fixo visando rapido calculo de medias."
#property description "V2: acrescenta suporte a mudanca de tamanho."

#include <oslib\osc-padrao.mqh>
#define OSC_VETOR_CIRCULAR_LEN_PADRAO 210

class osc_vetor_circular : public osc_padrao {
private:
   double m_vet[]           ; //vetor com item para o qual serao calculadas as medias;
   int    m_lenReal         ; //tamanho real   do vetor de medias;
   int    m_len             ; //tamanho logico do vetor de medias;
   int    m_ind             ; //indice atual dos vetores;
   int    m_tail            ; //elemento mais antigo do vetor de medias;
   double m_media           ; //ultima media calculada;
   double m_soma            ; //ultima soma total calculada do vetor de itens;
   double m_old             ; //entrada mais antiga no vetor;
   double m_new             ; //entrada mais nova   no vetor;
   ulong  m_qtdVolta        ;
   bool   m_deuPrimeiraVolta; //indica se a quantidade adicoes passou o tamanho do vetor.
                              //O calcula da media usa o tamnho do vetor apos a primeira volta.
   double m_distancia       ;
public:
   osc_vetor_circular(){ initialize(OSC_VETOR_CIRCULAR_LEN_PADRAO); }
  //~osc_vetor_circular();

   int  initialize(int    len);//cria o vetor circular com o tamanho informado;
   int  resize    (int    len);//muda o tamanho do array;
   void add       (double val);//substitui a posicao mais antiga do vetor pelo valor recebido;

   double getMedia     (){return m_media           ;} //Media dos elementos do vetor;
   double getSoma      (){return m_soma            ;} //Soma  dos elementos do vetor;
 //double getDistancia (){return m_new - m_old     ;} //Diferenca entre o elemento mais novo e o mais antigo da lista. Soh fica correto após uma volta completa na lista.
   double getDistancia (){return m_distancia       ;} //Diferenca entre o elemento mais novo e o mais antigo da lista.
   int    getLen       (){return m_len             ;} //Tamanho do vetor circular;
   int    getInd       (){return m_ind             ;} //indice do proximo elemento da lista[serve pra debug]
   bool   deuPrimVolta (){return m_deuPrimeiraVolta;} //true se jah deu a primaira volta   [serve pra debug];
   ulong  getQtdVolta  (){return m_qtdVolta        ;} //Quantidade de voltas que jah deu no vetor;
//------------------------------------------------------
};

//+---------------------------------------------------------------------------------------+
//| inicializa vetor circular com vetor de tamanho len contendo 0.0 em todos os elementos.|
//+---------------------------------------------------------------------------------------+
int osc_vetor_circular::initialize(int pLen){
    if(pLen < 1) return 0; // previnindo array com tamanho invalido;

    m_ind = 0; m_media = 0; m_soma = 0; m_old = 0; m_new = 0; m_deuPrimeiraVolta=false; m_qtdVolta=0; m_distancia=0; m_lenReal=0; m_tail=0;

  //        ArrayResize(m_vet2,pLen); // prevenindo para o caso do algoritimo Arrayresize aumente mais que tamanho solicitado. Entao colocamos o novo tamanho do vetor na variavem m_len.
    m_len = ArrayResize(m_vet ,pLen); // prevenindo para o caso do algoritimo Arrayresize aumente mais que tamanho solicitado. Entao colocamos o novo tamanho do vetor na variavem m_len.
  //ArrayFill(m_vet2,0,m_len,0);      // inicializando os elementos do vetor com zeros.
    ArrayFill(m_vet ,0,m_len,0);      // inicializando os elementos do vetor com zeros.
    m_lenReal = m_len;                // salvando o tamanho real do vetor, pois durante sua operacao pode ser que opere com tamanho menor.
    return m_len;
}

//+---------------------------------------------------------------------+
//| 1. substitui a posicao mais antiga do vetor pelo valor recebido.    |
//| 2. m_ind fica apontado para o proximo campo que serah adicionado ao |
//|    vetor circular.                                                  |
//| 3. Recalcula soma e media de valores do vetor.                      |
//+---------------------------------------------------------------------+
void osc_vetor_circular::add(double val){

   m_old          = m_vet[m_tail]; // m_old ficarah correto apos a segunda chamada a este metodo(add). Antes disso, nao serve.
   m_new          = val          ; // m_new sempre eh correto.
   m_distancia    = m_new - m_old;

   if(m_deuPrimeiraVolta){
      m_soma         -= m_old;        // retirando o elemento que estah sendo subtituido, da soma de elementos...[na primeira volta nao faz isso]
      m_soma         += m_new;        // adicionando novo valor a soma de elementos do vetor...
      m_vet [m_ind++] = m_new;        // atribuindo o novo valor ao vetor e movendo o ponteiro a frente...
      m_media         = m_soma/m_len; // recalculando a media...[apos primeira volta, usa o tamanho do vetor]
      if(m_ind>=m_len){m_ind=0; m_qtdVolta++;}     // chegou o final do vetor, entao voltamos pro inicio...
      m_tail          = m_ind;
      return;
   }

   m_soma         += m_new;                             // adicionando novo valor a soma de elementos do vetor...
   m_vet [m_ind++] = m_new;                             // atribuindo o novo valor ao vetor...
   m_media         = m_soma/m_ind;                      // recalculando a media...[na primeira volta, usa a quantidade de elementos adicionados]
   if(m_ind>=m_len){m_ind=0; m_deuPrimeiraVolta=true; m_qtdVolta++;} // chegou o final do vetor, entao voltamos pro inicio...
}

int osc_vetor_circular::resize(int len){
   if(len<1){return 0;}

   // diminuindo o tamnho do vetor...
   if(len < m_len){
      int retirar = m_len - len;
      Print("Diminuindo tamanho do vetor de ", m_len, " para ", len, "... [Head:", m_ind, "] [Tail:", m_tail, "]");


      //for(int i=m_tail; i<m_len; i++){ m_soma -= m_vet[i];} // retirando os elementos antigos da media...
      for(int i=0; i<retirar; m_tail++){m_soma -= m_vet[m_tail];} // retirando os elementos antigos da media...
      m_media = m_soma/len;                                       // recalculando a media...
      if(m_tail>=len){ m_tail=0; m_ind=0;}                        // <TODO: desloque os ultimos elementos para a posicao seguinte a do indice.>

      m_len = len;
}

  return m_len;
}


//+---------------------------------------------------------------------+
//| 1. substitui a posicao mais antiga do vetor pelo valor recebido.    |
//| 2. m_ind fica apontado para o proximo valor que serah adicionado ao |
//|    vetor circular.                                                  |
//| 3. Recalcula soma e media de valores do vetor.                      |
//+---------------------------------------------------------------------+
// void osc_vetor_circular::add(double val){
//    m_old          = m_vet[m_ind]    ; // m_old ficarah correto apos o fim da primeira volta na lista. Antes disso, nao serve.
//    m_new          = val             ; // m_new sempre eh correto.
//    m_distancia    = m_new - m_vet[0]; // se nao deu a primeira volta, a distancia eh a dierenca do mais novo pro indice zero.
//    if(m_deuPrimeiraVolta){
//       m_distancia     = m_new - m_old;
//       m_soma         -= m_old;        // retirando o elemento que estah sendo subtituido, da soma de elementos...[na primeira volta nao faz isso]
//       m_soma         += m_new;        // adicionando novo valor a soma de elementos do vetor...
//       m_vet [m_ind++] = m_new;        // atribuindo o novo valor ao vetor e movendo o ponteiro a frente...
//       m_media         = m_soma/m_len; // recalculando a media...[apos primeira volta, usa o tamanho do vetor]
//       if(m_ind==m_len){m_ind=0; m_qtdVolta++;}     // chegou o final do vetor, entao voltamos pro inicio...
//       return;
//    }
//    m_soma         += m_new;                             // adicionando novo valor a soma de elementos do vetor...
//    m_vet [m_ind++] = m_new;                             // atribuindo o novo valor ao vetor...
//    m_media         = m_soma/m_ind;                      // recalculando a media...[na primeira volta, usa a quantidade de elementos adicionados]
//    if(m_ind==m_len){m_ind=0; m_deuPrimeiraVolta=true; m_qtdVolta++;} // chegou o final do vetor, entao voltamos pro inicio...
// }

// void osc_vetor_circular::addAntesPrimeiraVolta(double val){
//    m_old          = m_vet[m_ind]; // m_old ficarah correto apos o fim da primeira volta na lista. Antes disso, nao serve.
//    m_new          = val;          // m_new sempre eh correto.
//  //m_soma        -= m_vet[m_ind]; // retirando o elemento que estah sendo subtituido, da soma de elementos...
//    m_soma        += val;          // adicionando novo valor a soma de elementos do vetor...
//    m_vet[m_ind++] = val;          // atribuindo o novo valor ao vetor...
//    m_media        = m_soma/m_ind; // recalculando a media...[na primeira volta, usa a quantidade de elementos adicionados]
//    if(m_ind==m_len){m_ind=0; m_deuPrimeiraVolta=true;}     // chegou o final do vetor, entao voltamos pro inicio...
// }

// void osc_vetor_circular::addAposPrimeiraVolta(double val){
//    m_old          = m_vet[m_ind]; // m_old ficarah correto apos o fim da primeira volta na lista. Antes disso, nao serve.
//    m_new          = val;          // m_new sempre eh correto.
//    m_soma        -= m_vet[m_ind]; // retirando o elemento que estah sendo subtituido, da soma de elementos...
//    m_soma        += val;          // adicionando novo valor a soma de elementos do vetor...
//    m_vet[m_ind++] = val;          // atribuindo o novo valor ao vetor...
//    m_media        = m_soma/m_len; // recalculando a media...[apos primeira volta, usa o tamanho do vetor]
//    if(m_ind==m_len){m_ind=0;}     // chegou o final do vetor, entao voltamos pro inicio...
// }

// void osc_vetor_circular::add(double val){
//     m_old          = m_vet[m_ind]; // m_old ficarah correto apos o fim da primeira volta na lista. Antes disso, nao serve.
//     m_new          = val;          // m_new sempre eh correto.
//     m_soma        -= m_vet[m_ind]; // retirando o elemento que estah sendo subtituido, da soma de elementos...
//     m_soma        += val;          // adicionando novo valor a soma de elementos do vetor...
//     m_vet[m_ind++] = val;          // atribuindo o novo valor ao vetor...
//     m_media        = m_soma/m_len; // recalculando a media...
//     if(m_ind==m_len){m_ind=0;}     // chegou o final do vetor, entao voltamos pro inicio...
// }
