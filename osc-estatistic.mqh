﻿//+------------------------------------------------------------------+
//|                                               osc-estatistic.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"

#include "osc-padrao.mqh"
#include "osc-vetor-circular-temporizado.mqh"
//+-----------------------------------------------------------------------------------------------+
//| Informa estatísticas de ticks acumulados.                                                     |
//+-----------------------------------------------------------------------------------------------+

  #define QTD_TICK_ACEVOL 0.17  // aproximadamente 1/6 da quantidade de acumulos usados calculo das demais medias.
  #define QTD_TICK_PROC   400
  #define MUL_QTD_BOOK    7
class osc_estatistic:public osc_padrao{
private:

// ==================== OFERTAS(DOM): Calculo de PRECO EM FUNCAO DO VOLUME =====================
   osc_vetor_circular_temporizado m_vetBookAsk; //acumulacao de ofertas de venda  (ask).
   osc_vetor_circular_temporizado m_vetBookBid; //acumulacao de ofertas de compra (bid).
   osc_vetor_circular_temporizado m_vetBookTot; //acumulacao de ofertas de venda e compra (ask e bid).
   double                         m_dxAsk     ;
   double                         m_dxBid     ;
   uint                           m_lenVetMediaBook      ; // tamanho do  vetor   de acumulo de medias de ofertas totais            do book;
   uint                           m_lenVetMediaBookAskBid; // tamanho dos vetores de acumulo de medias de ofertas de compra e venda do book;
// ==================== OFERTAS(DOM): FIM Calculo de PRECO EM FUNCAO DO VOLUME ================

// ==================== TRADES(TICKS): Calculo de PRECO EM FUNCAO DO VOLUME =====================
  // media geral de preco de trades ponderados pelos respectivos volumes...
  osc_vetor_circular_temporizado m_vetTradeTot; // medias de trades/agressoes totais    dos ultimos QTD_TICK_PROC.
  osc_vetor_circular_temporizado m_vetTradeSel; // medias de trades/agressoes de venda  dos ultimos QTD_TICK_PROC.
  osc_vetor_circular_temporizado m_vetTradeBuy; // medias de trades/agressoes de compra dos ultimos QTD_TICK_PROC.
  double                         m_dxBuyAnt   ; // distancia entre a media de compra e geral    (compra menos geral);
  double                         m_dxSelAnt   ; // distancia entre a media geral     e de venda (geral  menos venda);
  double                         m_dxBuy      ; // distancia entre a media de compra e geral    (compra menos geral);
  double                         m_dxSel      ; // distancia entre a media geral     e de venda (geral  menos venda);
  uint                           m_lenVetMediaTick; // tamanho dos vetores de acumulo de medias de ticks;
// ==================== TRADES(TICKS): FIM Calculo de PRECO EM FUNCAO DO VOLUME =====================

// ==================== TRADES(TICKS): Calculo de ACELERACAO DE VOLUME =====================
  osc_vetor_circular_temporizado m_aceVolTotQ; // fila com ultimas QTD_TICK_VELVOL aceleracoes de volume
  osc_vetor_circular_temporizado m_aceVolSelQ; // fila com ultimas QTD_TICK_VELVOL aceleracoes de volume de venda
  osc_vetor_circular_temporizado m_aceVolBuyQ; // fila com ultimas QTD_TICK_VELVOL aceleracoes de volume de compras
  //double m_aceVolTot ;         // aceleracao media do volume    total   nos ultimos QTD_TICK_VELVOL
  //double m_aceVolSel ;         // aceleracao media do volume de vendas  nos ultimos QTD_TICK_VELVOL
  //double m_aceVolBuy ;         // aceleracao media do volume de compras nos ultimos QTD_TICK_VELVOL
// ==================== TRADES(TICKS): Fim do Calculo de ACELERACAO DE VOLUME ===============

  double   m_open    ; // primeiro preco do periodo.
  double   m_max     ; // maior preco do periodo.
  double   m_min     ; // menor preco do periodo.
  double   m_close   ; // ultimo preco do periodo.
  double   m_last    ; // ultimo preco do periodo.

  double   m_ask;  // preco de oferta de compra do ultimo tick adicionado
  double   m_bid;  // preco de oferta de venda  do ultimo tick adicionado
  long     m_time; // hora do ultimo tick acumulado

  MqlTick  m_ult_tick;

  void acumularTick  ( MqlTick&     tick );
  //void acumularBook  ( MqlBookInfo& book[], double book_out, double tickSize);
  //void acumularBook  ( const datetime pTime, const MqlBookInfo& book[], const int tamanhoBook, const double book_out, const double tickSize);
  void calcAcelVol   ( MqlTick&     tick );
  void normalizarTick( MqlTick&     tick ); // transforma ticks em ticks de compra e venda;

public:
   osc_estatistic(){Print(__FUNCTION__,":compilado em:",__DATETIME__);}
  ~osc_estatistic(){Print(__FUNCTION__,":finalizado!"               );}// {delete(&m_aceVolTot);}

  void   initialize(uint lenVetMedia=QTD_TICK_PROC ){ initialize ( lenVetMedia, MUL_QTD_BOOK); }
  void   initialize(uint lenVetMedia, uint mulQtdBook);
  void   addTick( MqlTick& tick );
  void   addBook( const datetime pTime, const MqlBookInfo& book[], const int tamanhoBook, const double book_out, const double tickSize);
  void   checkResize(double tolerancia); // equaliza o tamanho dos vetores de media para que a diferenca de tempo de acumulacao das estatisticao fique abaixo da tolerancia.

  double ask (){return m_ask ;}
  double bid (){return m_bid ;}
  double last(){return m_last;}

  double getAceVol()   { return m_aceVolTotQ.getMedia(); } // aceleracao do crescimento de volume
  double getAceVolBuy(){ return m_aceVolBuyQ.getMedia(); } // aceleracao do crescimento do volume de compras
  double getAceVolSel(){ return m_aceVolSelQ.getMedia(); } // aceleracao do crescimento do volume de vendas

  //--- dados de trades (agressoes ao book)
  ulong getQtdVoltaTradeSel(){return m_vetTradeSel.getQtdVolta();}//indica se vetor circular de vendas     deu prim volta;
  ulong getQtdVoltaTradeBuy(){return m_vetTradeBuy.getQtdVolta();}//indica se vetor circular de compras    deu prim volta;
  ulong getQtdVoltaTrade   (){return m_vetTradeTot.getQtdVolta();}//indica se vetor circular de transacoes deu prim volta;

  int getIndTradeSel(){return m_vetTradeSel.getInd();}//indice do vetor circular de vendas     realizadas.
  int getIndTradeBuy(){return m_vetTradeBuy.getInd();}//indice do vetor circular de compras    realizadas.
  int getIndTrade   (){return m_vetTradeTot.getInd();}//indice do vetor circular de transacoes realizadas.

  double getVolTradeSel(){return m_vetTradeSel.getSomaPeso();}//volume de vendas     realizadas.
  double getVolTradeBuy(){return m_vetTradeBuy.getSomaPeso();}//volume de compras    realizadas.
  double getVolTrade   (){return m_vetTradeTot.getSomaPeso();}//volume de transacoes realizadas.

  double getVolMedTradeSel(){return m_vetTradeSel.getMediaPeso();}//volume de medio de vendas     realizadas.
  double getVolMedTradeBuy(){return m_vetTradeBuy.getMediaPeso();}//volume de medio de compras    realizadas.
  double getVolMedTrade   (){return m_vetTradeTot.getMediaPeso();}//volume de medio de transacoes realizadas.

  double getPrecoMedTradeSel(){return m_vetTradeSel.getMedia();}//preco medio de trades de vendas  ponderado pelo volume;
  double getPrecoMedTradeBuy(){return m_vetTradeBuy.getMedia();}//preco medio de trades de compras ponderado pelo volume;
  double getPrecoMedTrade   (){return m_vetTradeTot.getMedia();}//preco medio de trades    totais  ponderado pelo volume;

  double getInclinacaoTradeSel(){return m_vetTradeSel.getCoefLinear();}//inclinacao da reta de trades de vendas  ponderado pelo volume;
  double getInclinacaoTradeBuy(){return m_vetTradeBuy.getCoefLinear();}//inclinacao da reta de trades de compras ponderado pelo volume;
  double getInclinacaoTrade   (){return m_vetTradeTot.getCoefLinear();}//inclinacao da reta de trades    totais  ponderado pelo volume;

  double getDxSel      (){return m_dxSel      ;}//distancia entre o preco medio das transacoes e o preco medio das vendas ;
  double getDxBuy      (){return m_dxBuy      ;}//distancia entre o preco medio das transacoes e o preco medio das compras;
  //double getDxSelDelta (){return m_dxSelDelta ;}//distancia entre o preco medio das transacoes e o preco medio das vendas ;
  //double getDxBuyDelta (){return m_dxBuyDelta ;}//distancia entre o preco medio das transacoes e o preco medio das compras;

  long   getTempoAcumTrade     (){return m_vetTradeTot.getTempoDecorrido     ();}// tempo       desde o trade(tick) mais antigo considerado na estatistica e o mais novo.
  long   getTempoAcumTradeSel  (){return m_vetTradeSel.getTempoDecorrido     ();}// tempo       desde o trade(tick) mais antigo considerado na estatistica e o mais novo.
  long   getTempoAcumTradeBuy  (){return m_vetTradeBuy.getTempoDecorrido     ();}// tempo       desde o trade(tick) mais antigo considerado na estatistica e o mais novo.
  long   getTempoAcumTradeMedio(){return m_vetTradeTot.getTempoDecorridoMedio();}// tempo medio desde o trade(tick) mais antigo considerado na estatistica e o mais novo.

  //uint getLenVetAcumTrade(){return m_lenVetMediaTick     ;}
  uint   getLenVetAcumTrade(){return m_vetTradeTot.getLen();}
  //--- dados de trades (agressoes ao book)

  //--- dados de ofertas (book)
  ulong getQtdVoltaBookAsk(){return m_vetBookAsk.getQtdVolta();}//indica se vetor circular ofertas de venda  deu prim volta;
  ulong getQtdVoltaBookBid(){return m_vetBookBid.getQtdVolta();}//indica se vetor circular ofertas de compra deu prim volta;
  ulong getQtdVoltaBook   (){return m_vetBookTot.getQtdVolta();}//indica se vetor circular ofertas totais    deu prim volta;

  int getIndBookAsk(){return m_vetBookAsk.getInd();}//indice do vetor circular de ofertas de venda  realizadas.
  int getIndBookBid(){return m_vetBookBid.getInd();}//indice do vetor circular de ofertas de compra realizadas.
  int getIndBook   (){return m_vetBookTot.getInd();}//indice do vetor circular de ofertas    totais realizadas.

  double getVolBookAsk(){return m_vetBookAsk.getSomaPeso();}//volume de ofertas de venda  realizadas. obs: volumes multiplicados pelos pesos calculados como distancia do preco.
  double getVolBookBid(){return m_vetBookBid.getSomaPeso();}//volume de ofertas de compra realizadas. obs: volumes multiplicados pelos pesos calculados como distancia do preco.
  double getVolBook   (){return m_vetBookTot.getSomaPeso();}//volume de ofertas    totais realizadas. obs: volumes multiplicados pelos pesos calculados como distancia do preco.

  double getVolMedBookAsk(){return m_vetBookAsk.getMediaPeso();}//volume de medio de ofertas de venda  realizadas. obs: volumes multiplicados pelos pesos calculados como distancia do preco.
  double getVolMedBookBid(){return m_vetBookBid.getMediaPeso();}//volume de medio de ofertas de compra realizadas. obs: volumes multiplicados pelos pesos calculados como distancia do preco.
  double getVolMedBook   (){return m_vetBookTot.getMediaPeso();}//volume de medio de ofertas    totais realizadas. obs: volumes multiplicados pelos pesos calculados como distancia do preco.

  double getPrecoMedBookAsk(){return m_vetBookAsk.getMedia();}//preco medio de Books ofertas de venda  ponderado pelo volume e distancia do preco;
  double getPrecoMedBookBid(){return m_vetBookBid.getMedia();}//preco medio de Books ofertas de compra ponderado pelo volume e distancia do preco;
  double getPrecoMedBook   (){return m_vetBookTot.getMedia();}//preco medio de Books ofertas    totais ponderado pelo volume e distancia do preco;

  double getInclinacaoBookAsk(){return m_vetBookAsk.getCoefLinear();}//inclinacao da reta de ofertas de vendas  ponderadas pelo volume;
  double getInclinacaoBookBid(){return m_vetBookBid.getCoefLinear();}//inclinacao da reta de ofertas de compras ponderadas pelo volume;
  double getInclinacaoBook   (){return m_vetBookTot.getCoefLinear();}//inclinacao da reta de ofertas    totais  ponderadas pelo volume;

  double getDxAsk(){return m_dxAsk ;}//distancia entre o preco medio das ofertas e o preco medio das ofertas de venda ;
  double getDxBid(){return m_dxBid ;}//distancia entre o preco medio das ofertas e o preco medio das ofertas de compra;

  long   getTempoAcumBook     (){return m_vetBookTot.getTempoDecorrido     ();}// tempo       desde a posicao do noob mais antiga considerado na estatistica e a mais nova.
  long   getTempoAcumBookAsk  (){return m_vetBookAsk.getTempoDecorrido     ();}// tempo       desde a posicao do noob mais antiga considerado na estatistica e a mais nova.
  long   getTempoAcumBookBid  (){return m_vetBookBid.getTempoDecorrido     ();}// tempo       desde a posicao do noob mais antiga considerado na estatistica e a mais nova.
  long   getTempoAcumBookMedio(){return m_vetBookTot.getTempoDecorridoMedio();}// tempo medio desde a posicao do noob mais antiga considerado na estatistica e a mais nova.

  //uint getLenVetAcumBook       (){return m_lenVetMediaBook      ;} // tamanho do  vetor   de acumulo de medias de ofertas totais            do book;
  uint   getLenVetAcumBook       (){return m_vetBookTot.getLen()  ;} // tamanho do  vetor   de acumulo de medias de ofertas totais            do book;
  uint   getLenVetAcumBookAskBid (){return m_lenVetMediaBookAskBid;} // tamanho dos vetores de acumulo de medias de ofertas de compra e venda do book;
  //--- dados de ofertas (book)

}; // fim do corpo da classe

void osc_estatistic::initialize(uint lenVetMedia=QTD_TICK_PROC, uint mulQtdBook=MUL_QTD_BOOK){

    m_lenVetMediaTick       = lenVetMedia;
    m_lenVetMediaBookAskBid = lenVetMedia * mulQtdBook ;
    m_lenVetMediaBook       = m_lenVetMediaBookAskBid * 1; // use 2 voltar a acumular as ocorrencias do book no vetor. vetor com todas as medias do book eh o dobro do tamanho dos vetores ask e bid pra suportar a media de ambas.
  //m_lenVetMediaBook       = m_lenVetMediaBookAskBid * 2; // vetor com todas as medias do book eh o dobro do tamanho dos vetores ask e bid pra suportar a media de ambas.

    m_vetTradeTot.initialize(m_lenVetMediaTick);// medias de preco de trades ponderados por volume nos ultimos TICKS informados no parametro.
    m_vetTradeSel.initialize(m_lenVetMediaTick);// medias de preco de trades ponderados por volume nos ultimos TICKS informados no parametro.
    m_vetTradeBuy.initialize(m_lenVetMediaTick);// medias de preco de trades ponderados por volume nos ultimos TICKS informados no parametro.

    m_vetBookTot.initialize(m_lenVetMediaBook      );// medias de preco no book ponderados pelo volume e peso dos precos.
    m_vetBookAsk.initialize(m_lenVetMediaBookAskBid);// medias de preco no book ponderados pelo volume e peso dos precos.
    m_vetBookBid.initialize(m_lenVetMediaBookAskBid);// medias de preco no book ponderados pelo volume e peso dos precos.

    //aceleracao de volume de trade...
    m_aceVolTotQ.initialize( (int)(lenVetMedia * QTD_TICK_ACEVOL) );
    m_aceVolSelQ.initialize( (int)(lenVetMedia * QTD_TICK_ACEVOL) );
    m_aceVolBuyQ.initialize( (int)(lenVetMedia * QTD_TICK_ACEVOL) );

  //m_dxBuyDelta=0; m_dxBuyDelta=0; // distancia entre as medias de            venda(sel)/compra(buy) e a media geral           de compra e venda.
  //m_dxBuyAnt  =0; m_dxSelAnt  =0; // distancia entre as medias de            venda(sel)/compra(buy) e a media geral           de compra e venda.
    m_dxBuy     =0; m_dxSel     =0; // distancia entre as medias de            venda(sel)/compra(buy) e a media geral           de compra e venda.
    m_dxAsk     =0; m_dxBid     =0; // distancia entre as medias de ofertas de venda(ask)/compra(bid) e a media geral de oferta de compra e venda.
  // ==================== Fim Calculo de PRECO EM FUNCAO DO VOLUME =====================
}

void osc_estatistic::addTick( MqlTick& tick ){

  //em modo hibrido, simula compra e venda em funcao da variacao em ask e bid
  //m_modoHibrido = false;
  //if(  m_modoHibrido ){ normalizarTick(tick); }
  if( !isTkTra(tick) ){ return; }

  m_time     = tick.time;
  m_ask      = tick.ask;
  m_bid      = tick.bid;
  m_last     = tick.last;
  m_close    = tick.last;
  m_max      = tick.last > m_max?tick.last:m_max;
  m_min      = tick.last < m_min?tick.last:m_min;

  // calculando as medias baseado no fluxo continuo de ticks...
  acumularTick(tick);
  calcAcelVol (tick);// calculos das aceleracoes de volume deve ser antes de pisar m_ult_tick...
  m_ult_tick = tick; // pisando m_ulti_tick...
}

//+-----------------------------------------------------------------------------------------------------+
//| ==================== Calculo de PRECO DE OFERTA EM FUNCAO DO VOLUME =====================           |
//|                                                                                                     |
//| Recebe: MqlBookInfo& book[]  : Array de entradas no book de ofertas.                                |
//|         double       book_out: Porcentagem do book que serah eliminada do calculo das medias e      |
//|                                totais. Eliminacao se dah a partir dos extremos superior(ofertas ask)|
//|                                e inferior(ofertas bid)                                              |
//|         int       tamanhoBook: tamanho do array do book de ofertas.                                 |
//|         double       tickSize: Tamanho do tick. Eh usado pra determinar o peso das ofertas no book. |
//|                                                                                                     |
//| Faz: - adiciona entradas no book de ofertas aoss vetores de calculo de medias ponderados por volume.|
//|      - recalcula medias de precos ofertas ponderadas por volume.                                    |
//+-----------------------------------------------------------------------------------------------------+
// void osc_estatistic::addBook(const datetime pTime, const MqlBookInfo& book[], const int tamanhoBook, const double book_out, const double tickSize){

//   double pesoAsk = 0; double pesoBid = 0;// peso adicional das ofertas de venda e compra (peso referente a posicao do preco no book)

//   // calculando a posicao dos precos significativos no book...
//   int desprezarAsk = (int)( tamanhoBook * (book_out/2.0) )-1;
//   int desprezarBid =        tamanhoBook - desprezarAsk    -1;

//   for(int i=0; i<tamanhoBook; i++){
//       // calibrando os pesos em funcao da posicao do preco no book...
//       pesoAsk = book[0].price - book[i            ].price + tickSize;
//       pesoBid = book[i].price - book[tamanhoBook-1].price + tickSize;
//       //  m_vetTradeTot.add(tick.time, totPrice, totVol);
//       if( book[i].type == BOOK_TYPE_SELL && i > desprezarAsk ){
//           m_vetBookAsk.add(m_time, book[i].price, book[i].volume_real*pesoAsk);
//           m_vetBookTot.add(m_time, book[i].price, book[i].volume_real*pesoAsk);
//       }else{
//           if( book[i].type == BOOK_TYPE_BUY && i < desprezarBid ){
//               m_vetBookBid.add(m_time, book[i].price, book[i].volume_real*pesoBid);
//               m_vetBookTot.add(m_time, book[i].price, book[i].volume_real*pesoBid);
//           }else{
//               if( i>desprezarAsk && i<desprezarBid ){
//                   Print("Nenhum tipo ///////////////////////////////////////// desprezarAsk:",desprezarAsk," desprezarBid:",desprezarBid, " i:", i);
//               }
//           }
//       }
//   }//laco for
//   m_dxAsk = ( m_vetBookAsk.getMedia() - m_vetBookTot.getMedia() );
//   m_dxBid = ( m_vetBookTot.getMedia() - m_vetBookBid.getMedia() );
// }

 //+-----------------------------------------------------------------------------------------------------+
 //| ==================== Calculo de PRECO DE OFERTA EM FUNCAO DO VOLUME =====================           |
 //|                                                                                                     |
 //| Recebe: MqlBookInfo& book[]  : Array de entradas no book de ofertas.                                |
 //|         double       book_out: Porcentagem do book que serah eliminada do calculo das medias e      |
 //|                                totais. Eliminacao se dah a partir dos extremos superior(ofertas ask)|
 //|                                e inferior(ofertas bid)                                              |
 //|         int       tamanhoBook: tamanho do array do book de ofertas.                                 |
 //|         double       tickSize: Tamanho do tick. Eh usado pra determinar o peso das ofertas no book. |
 //|                                                                                                     |
 //| Faz: - adiciona entradas no book de ofertas aos vetores de calculo de medias ponderados por volume. |
 //|      - recalcula medias de precos ofertas ponderadas por volume.                                    |
 //|      - esta versao adiciona os precos medios jah calculados.                                        |
 //+-----------------------------------------------------------------------------------------------------+
 void osc_estatistic::addBook(const datetime pTime, const MqlBookInfo& book[], const int tamanhoBook, const double book_out, const double tickSize){

   double pesoAsk = 0; double pesoBid = 0;// peso adicional das ofertas de venda e compra (peso referente a posicao do preco no book)

   // calculando a posicao dos precos significativos no book...
   int desprezarAsk = (int)( tamanhoBook * (book_out/2.0) )-1;
   int desprezarBid =        tamanhoBook - desprezarAsk    -1;

   double pesXvolXask = 0, pesXvolXbid = 0; // numerador  : soma dos precos x pesos
   double pesXvolAsk  = 0, pesXvolBid  = 0; // denominador: soma dos          pesos

   for(int i=0; i<tamanhoBook; i++){
       // calibrando os pesos em funcao da posicao do preco no book...
       pesoAsk = book[0].price - book[i            ].price + tickSize;
       pesoBid = book[i].price - book[tamanhoBook-1].price + tickSize;
       if( book[i].type == BOOK_TYPE_SELL && i > desprezarAsk ){
           pesXvolXask += book[i].price*book[i].volume_real*pesoAsk;// numerador  : soma dos precos x pesos
           pesXvolAsk  +=               book[i].volume_real*pesoAsk;// denominador: soma dos          pesos
       }else{
           if( book[i].type == BOOK_TYPE_BUY && i < desprezarBid ){
               pesXvolXbid += book[i].price*book[i].volume_real*pesoBid;// numerador  : soma dos precos x pesos
               pesXvolBid  +=               book[i].volume_real*pesoBid;// denominador: soma dos          pesos
           }else{
               if( i>desprezarAsk && i<desprezarBid ){
                   Print("Nenhum tipo ///////////////////////////////////////// desprezarAsk:",desprezarAsk," desprezarBid:",desprezarBid, " i:", i);
               }
           }
       }
   }//laco for

   m_vetBookAsk.add(m_time,  pesXvolXask/pesXvolAsk);
   m_vetBookBid.add(m_time,  pesXvolXbid/pesXvolBid);
   m_vetBookTot.add(m_time, (pesXvolXask+pesXvolXbid)/(pesXvolAsk+pesXvolBid) );

   m_dxAsk = ( m_vetBookAsk.getMedia() - m_vetBookTot.getMedia() );
   m_dxBid = ( m_vetBookTot.getMedia() - m_vetBookBid.getMedia() );
 }

  //+---------------------------------------------------------------------------------------+
  //| ==================== Calculo de PRECO EM FUNCAO DO VOLUME =====================       |
  //| Faz: - adiciona tick nos vetores de calculo de medias de precos ponderados por volume.|
  //|      - recalcula medias de precos transacoes ponderadas por volume.                   |
  //+---------------------------------------------------------------------------------------+
  void osc_estatistic::acumularTick( MqlTick& tick ){
     double totVol =                (double)tick.volume   ;
     double selVol = (isTkSel(tick)?(double)tick.volume:0);
     double buyVol = (isTkBuy(tick)?(double)tick.volume:0);

     double totPrice =                tick.last   ;
     double selPrice = (isTkSel(tick)?tick.last:0);
     double buyPrice = (isTkBuy(tick)?tick.last:0);

     m_vetTradeTot.add(tick.time, totPrice, totVol);
     if(selPrice>0) m_vetTradeSel.add(tick.time, selPrice, selVol);
     if(buyPrice>0) m_vetTradeBuy.add(tick.time, buyPrice, buyVol);

     m_dxSel = m_vetTradeTot.getMedia() - m_vetTradeSel.getMedia();
     m_dxBuy = m_vetTradeBuy.getMedia() - m_vetTradeTot.getMedia();
  }

  // verifica se eh necessario alterar o tamanho dos vetores.
  void osc_estatistic::checkResize( double tolerancia){
     if( m_vetBookTot.getTempoDecorrido() > m_vetTradeTot.getTempoDecorrido() ){
         // se o menor jah deu a primeira volta e o maior mais de 30% maior...
         if( m_vetTradeTot.getQtdVolta()>0 &&
             m_vetTradeTot.getTempoDecorrido()/m_vetBookTot.getTempoDecorrido() < tolerancia ){
             m_vetBookTot.resize( m_vetBookTot.getLen()-(int)(m_vetBookTot.getLen()*0.2) ); // diminuimos 10% do tamanho do vetor maior...
         }
     }
  }

  //------------------------------------------------------------------------------+
  // ==================== Calculo de ACELERACAO DE VOLUME =====================   |
  // Faz: inclui a aceleracao de volume do tick informado na fila                 |
  //      de aceleracoes informada. Se a fila ficar maior que a qtd               |
  //      de aceleracoes usada no calculo da aceleracao media, retira             |
  //      a aceleracao mais antiga da mesma.                                      |
  //                                                                              |
  // Obs: a aceleracao do tick recebido eh calculada como a diferenca             |
  //      o volume do ultimo tick (m_ult_tick) e o tick recebido como             |
  //      parametro neste metodo.                                                 |
  //                                                                              |
  // Retorna: a aceleracao media na file de aceleracoes de volume                 |
  //          recebida, considerando a inclusao do tick tambem recebido.          |
  //------------------------------------------------------------------------------+
  void osc_estatistic::calcAcelVol( MqlTick& tick ){

     double volAnt    =                      (double)m_ult_tick.volume   ;
     double volAntSel = (isTkSel(m_ult_tick)?(double)m_ult_tick.volume:0);
     double volAntBuy = (isTkBuy(m_ult_tick)?(double)m_ult_tick.volume:0);

     double volAtu    =                (double)tick.volume   ;
     double volAtuSel = (isTkSel(tick)?(double)tick.volume:0);
     double volAtuBuy = (isTkBuy(tick)?(double)tick.volume:0);

     double ace    = (volAtu   -volAnt   );
     double aceSel = (volAtuSel-volAntSel);
     double aceBuy = (volAtuBuy-volAntBuy);

     m_aceVolTotQ.add( ace   , tick.time );
     m_aceVolSelQ.add( aceSel, tick.time );
     m_aceVolBuyQ.add( aceBuy, tick.time );
  }
  //--------------------------------------------------------------
// ==================== Calculo de VELOCIDADE DE VOLUME =====================





