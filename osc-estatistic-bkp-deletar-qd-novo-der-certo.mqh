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

class osc_estatistic:public osc_padrao{
private:

  MqlDateTime time         ; // horario de inicio do tick;

// ==================== Calculo de PRECO EM FUNCAO DO VOLUME =====================
  // media geral de preco ponderado pelo volume...
  osc_vetor_circular_temporizado m_totVolQ     ; // volume                   dos ultimos QTD_TICK_PROC.
  osc_vetor_circular_temporizado m_totPriceQ   ; // preco                    dos ultimos QTD_TICK_PROC.
  osc_vetor_circular_temporizado m_totPriceVolQ; // preco medio apos chegada dos ultimos QTD_TICK_PROC.

  // media geral de preco de vendas ponderado pelo volume de vendas...
  osc_vetor_circular_temporizado m_selVolQ     ; // volume                   dos ultimos QTD_TICK_PROC.
  osc_vetor_circular_temporizado m_selPriceQ   ; // preco                    dos ultimos QTD_TICK_PROC.
  osc_vetor_circular_temporizado m_selPriceVolQ; // preco medio apos chegada dos ultimos QTD_TICK_PROC.

  // media geral de preco de compra ponderado pelo volume de compra...
  osc_vetor_circular_temporizado m_buyVolQ     ; // volume                   dos ultimos QTD_TICK_PROC.
  osc_vetor_circular_temporizado m_buyPriceQ   ; // preco                    dos ultimos QTD_TICK_PROC.
  osc_vetor_circular_temporizado m_buyPriceVolQ; // preco medio apos chegada dos ultimos QTD_TICK_PROC.

  double m_totPS  ; double m_selPS  ; double m_buyPS  ; // preco          (soma )
  double m_totPM  ; double m_selPM  ; double m_buyPM  ; // preco          (medio)
  double m_totVS  ; double m_selVS  ; double m_buyVS  ; // volume         (soma )
  double m_totVM  ; double m_selVM  ; double m_buyVM  ; // volume         (medio)
  double m_totPVS ; double m_selPVS ; double m_buyPVS ; // preco x volume (soma )
  double m_totPVM ; double m_selPVM ; double m_buyPVM ; // preco x volume (medio)
  double m_totPMPV; double m_selPMPV; double m_buyPMPV; // preco medio ponderado pelo volume
  double m_dxBuy  ; double m_dxSel  ;                   // distancia entre as medias de venda/compra e a media geral
// ==================== Fim Calculo de PRECO EM FUNCAO DO VOLUME =====================

// ==================== Calculo de ACELERACAO DE VOLUME =====================
  osc_vetor_circular_temporizado m_aceVolTotQ; // fila com ultimas QTD_TICK_VELVOL aceleracoes de volume
  osc_vetor_circular_temporizado m_aceVolSelQ; // fila com ultimas QTD_TICK_VELVOL aceleracoes de volume de venda
  osc_vetor_circular_temporizado m_aceVolBuyQ; // fila com ultimas QTD_TICK_VELVOL aceleracoes de volume de compras
  //double m_aceVolTot ;         // aceleracao media do volume    total   nos ultimos QTD_TICK_VELVOL
  //double m_aceVolSel ;         // aceleracao media do volume de vendas  nos ultimos QTD_TICK_VELVOL
  //double m_aceVolBuy ;         // aceleracao media do volume de compras nos ultimos QTD_TICK_VELVOL
// ==================== Fim do Calculo de ACELERACAO DE VOLUME =====================


  double   m_open    ; // primeiro preco do periodo.
  double   m_max     ; // maior preco do periodo.
  double   m_min     ; // menor preco do periodo.
  double   m_close   ; // ultimo preco do periodo.
  double   m_last    ; // ultimo preco do periodo.

  double   m_ask; // preco de oferta de compra do ultimo tick adicionado
  double   m_bid; // preco de oferta de venda  do ultimo tick adicionado

  MqlTick  m_ult_tick;
  bool     m_modoHibrido;

  bool isTkBuy(MqlTick& tick){ return (tick.flags&TICK_FLAG_BUY   )==TICK_FLAG_BUY   ;} // Aconteceu uma compra
  bool isTkSel(MqlTick& tick){ return (tick.flags&TICK_FLAG_SELL  )==TICK_FLAG_SELL  ;} // Aconteceu uma venda
  bool isTkAsk(MqlTick& tick){ return (tick.flags&TICK_FLAG_ASK   )==TICK_FLAG_ASK   ;} // Aconteceu uma alteracao no preco de compra
  bool isTkBid(MqlTick& tick){ return (tick.flags&TICK_FLAG_BID   )==TICK_FLAG_BID   ;} // Aconteceu uma alteracao no preco de venda
  bool isTkLas(MqlTick& tick){ return (tick.flags&TICK_FLAG_LAST  )==TICK_FLAG_LAST  ;} // Aconteceu uma alteracao no preco negociado
  bool isTkVol(MqlTick& tick){ return (tick.flags&TICK_FLAG_VOLUME)==TICK_FLAG_VOLUME;} // Aconteceu uma alteracao no volume total negociado
  bool isTkTra(MqlTick& tick){ return ( isTkBuy(tick) || isTkSel(tick) );             } // Aconteceu uma compra ou uma venda

  void acumularTick  ( MqlTick&     tick );
  void acumularBook  ( MqlBookInfo& book[], double book_out, double tickSize);
  void calcAcelVol   ( MqlTick&     tick );
  void normalizarTick( MqlTick&     tick ); // transforma ticks em ticks de compra e venda;

public:
   osc_estatistic(){Print(__FUNCTION__,":compilado em:",__DATETIME__);}
  ~osc_estatistic(){Print(__FUNCTION__,":finalizado!"               );}// {delete(&m_aceVolTot);}

  void   initialize(int lenVetMedia);
  void   addTick( MqlTick& tick );
  void   setModoHibrido(bool modo){ m_modoHibrido = modo; } // em modo hibrido os ticks sao normalizados antes da adicao as estatisticas.|

  double ask (){return m_ask ;}
  double bid (){return m_bid ;}
  double last(){return m_last;}

  double getAceVol()   { return m_aceVolTotQ.getMedia(); } // aceleracao do crescimento de volume
  double getAceVolBuy(){ return m_aceVolBuyQ.getMedia(); } // aceleracao do crescimento do volume de compras
  double getAceVolSel(){ return m_aceVolSelQ.getMedia(); } // aceleracao do crescimento do volume de vendas

  //--- dados de trades (agressoes ao book)
  double getVolSel     (){return m_selVS  ;}//volume de vendas     realizadas.
  double getVolBuy     (){return m_buyVS  ;}//volume de compras    realizadas.
  double getVolTrade   (){return m_totVS  ;}//volume de transacoes realizadas.

  double getVolMedSel  (){return m_selVM  ;}//volume de medio de vendas     realizadas.
  double getVolMedBuy  (){return m_buyVM  ;}//volume de medio de compras    realizadas.
  double getVolMedTrade(){return m_totVM  ;}//volume de medio de transacoes realizadas.

  double getMedSel     (){return m_selPMPV;}//preco medio das vendas     ponderado pelo volume;
  double getMedBuy     (){return m_buyPMPV;}//preco medio das compras    ponderado pelo volume;
  double getMedTrade   (){return m_totPMPV;}//preco medio das transacoes ponderado pelo volume;
  double getDxSel      (){return m_dxSel  ;}//distancia entre o preco medio das transacoes e o preco medio das vendas ;
  double getDxBuy      (){return m_dxBuy  ;}//distancia entre o preco medio das transacoes e o preco medio das compras;

  long   getTempoAcumTrade     (){return m_totVolQ.getTempoDecorrido     ();}// tempo       desde o trade(tick) mais antigo considerado na estatistica e o mais novo.
  long   getTempoAcumTradeMedio(){return m_totVolQ.getTempoDecorridoMedio();}// tempo medio desde o trade(tick) mais antigo considerado na estatistica e o mais novo.
  //--- dados de trades (agressoes ao book)

}; // fim do corpo da classe

void osc_estatistic::initialize(int lenVetMedia=QTD_TICK_PROC){
    // media geral de preco ponderado pelo volume...
    m_totVolQ     .initialize(lenVetMedia); // volume                   dos ultimos QTD_TICK_PROC.
    m_totPriceQ   .initialize(lenVetMedia); // preco                    dos ultimos QTD_TICK_PROC.
    m_totPriceVolQ.initialize(lenVetMedia); // preco medio apos chegada dos ultimos QTD_TICK_PROC.

    // media geral de preco de vendas ponderado pelo volume de vendas...
    m_selVolQ     .initialize(lenVetMedia); // volume                   dos ultimos QTD_TICK_PROC.
    m_selPriceQ   .initialize(lenVetMedia); // preco                    dos ultimos QTD_TICK_PROC.
    m_selPriceVolQ.initialize(lenVetMedia); // preco medio apos chegada dos ultimos QTD_TICK_PROC.

    // media geral de preco de compra ponderado pelo volume de compra...
    m_buyVolQ     .initialize(lenVetMedia); // volume                   dos ultimos QTD_TICK_PROC.
    m_buyPriceQ   .initialize(lenVetMedia); // preco                    dos ultimos QTD_TICK_PROC.
    m_buyPriceVolQ.initialize(lenVetMedia); // preco medio apos chegada dos ultimos QTD_TICK_PROC.

    //aceleracao de volume de trade...
    m_aceVolTotQ.initialize( (int)(lenVetMedia * QTD_TICK_ACEVOL) );
    m_aceVolSelQ.initialize( (int)(lenVetMedia * QTD_TICK_ACEVOL) );
    m_aceVolBuyQ.initialize( (int)(lenVetMedia * QTD_TICK_ACEVOL) );

    m_totPS  =0; m_selPS  =0; m_buyPS  =0; // preco          (soma )
    m_totPM  =0; m_selPM  =0; m_buyPM  =0; // preco          (medio)
    m_totVS  =0; m_selVS  =0; m_buyVS  =0; // volume         (soma )
    m_totVM  =0; m_selVM  =0; m_buyVM  =0; // volume         (medio)
    m_totPVS =0; m_selPVS =0; m_buyPVS =0; // preco x volume (soma )
    m_totPVM =0; m_selPVM =0; m_buyPVM =0; // preco x volume (medio)
    m_totPMPV=0; m_selPMPV=0; m_buyPMPV=0; // preco medio ponderado pelo volume
    m_dxBuy  =0; m_dxSel  =0;              // distancia entre as medias de venda/compra e a media geral
  // ==================== Fim Calculo de PRECO EM FUNCAO DO VOLUME =====================
}

void osc_estatistic::addTick( MqlTick& tick ){

  //em modo hibrido, simula compra e venda em funcao da variacao em ask e bid
  //m_modoHibrido = false;
  if( m_modoHibrido ){ normalizarTick(tick); }
  if( !isTkTra(tick) ){return;}

  m_ask      = tick.ask;
  m_bid      = tick.bid;
  m_last     = tick.last;
  m_close    = tick.last;
  m_max      = tick.last > m_max?tick.last:m_max;
  m_min      = tick.last < m_min?tick.last:m_min;

  // calculando as medias baseado no fluxo continuo de ticks...
  acumularTick(tick);
  calcAcelVol(tick); // calculo das aceleracoes de volume deve ser antes de pisar m_ult_tick...
  m_ult_tick = tick; // pisando m_ulti_tick...
}



//-----------------------------------------------------------------------------------------------------+
// ==================== Calculo de PRECO DE OFERTA EM FUNCAO DO VOLUME =====================           |
//                                                                                                     |
// Recebe: MqlBookInfo& book[]  : Array de entradas no book de ofertas.                                |
//         double       book_out: Porcentagem do book que serah eliminada do calculo das medias e      |
//                                totais. Eliminacao se dah a partir dos extremos superior(ofertas ask)|
//                                e inferior(ofertas bid)                                              |
//         double       tickSize: Tamanho do tick. Eh usado pra determinar o peso das ofertas no book. |
//                                                                                                     |
// Faz: - adiciona entradas no book de ofertas aoss vetores de calculo de medias ponderados por volume.|
//      - recalcula medias de precos ofertas ponderadas por volume.                                    |
//                                                                                                     |
//-----------------------------------------------------------------------------------------------------+
void osc_estatistic::acumularBook(MqlBookInfo& book[], double book_out, double tickSize){

  //  int tamanhoBook = ArraySize(book);
  //  if(tamanhoBook == 0) { printf("Falha carregando livro de ofertas. Motivo: " + (string)GetLastError()); return; }

  //  double vask    = 0; double vbid    = 0;
  //  double vpask   = 0; double vpbid   = 0; // volume de ofertas de venda  x peso e compra x peso;
  //  double pvpask  = 0; double pvpbid  = 0; // preco de ofertas de venda  x volume de ofertas de venda x peso e o mesmo com relacao a compras
  //  double pmask   = 0; double pmbid   = 0; // preco medio das ofertas de compra(bid) e venda(bid);
  //  double pm      = 0;
  //  double pesoAsk = 0; double pesoBid = 0;// peso adicional das ofertas de venda e compra (peso referente a posicao do preco no book)
  //  m_dom_txt      = "" ;

  //  // calculando os precos significativos no book...
  //  int desprezarAsk = (int)( tamanhoBook * (book_out/2.0) )-1;
  //  int desprezarBid =        tamanhoBook - desprezarAsk    -1;

  //  double askVol          = 0; // volume
  //  double askVolPeso      = 0; // volume x peso da posicao
  //  double askVolPesoPrice = 0; // volume x peso da posicao x preco

  //  double bidVol          = 0; // volume
  //  double bidVolPeso      = 0; // volume x peso da posicao
  //  double bidVolPesoPrice = 0; // volume x peso da posicao x preco

  //  for(int i=0; i<tamanhoBook; i++){

  //    // calibrando os pesos em funcao da posicao do preco no book...
  //    pesoAsk = book[0].price - book[i            ].price + tickSize;
  //    pesoBid = book[i].price - book[tamanhoBook-1].price + tickSize;

  //    if( book[i].type == BOOK_TYPE_SELL && i > desprezarAsk ){
  //        vask       +=   book[i].volume_real;
  //        vpask      += (                         book[i].volume_real*pesoAsk ); //<TODO> Verifique se aqui deve ser soma.
  //        pvpask     += ( book[i].volume_real   * book[i].price      *pesoAsk );
  //    }else{
  //        if( book[i].type == BOOK_TYPE_BUY && i < desprezarBid ){
  //           vbid   +=   book[i].volume_real;
  //           vpbid  += (                       book[i].volume_real*pesoBid ); //<TODO> Verifique se aqui deve ser soma.
  //           pvpbid += ( book[i].volume_real * book[i].price      *pesoBid );
  //        }else{
  //           if( i>desprezarAsk && i<desprezarBid ){
  //               Print("Nenhum tipo ///////////////////////////////////////// desprezarAsk:",desprezarAsk," desprezarBid:",desprezarBid, " i:", i);
  //           }
  //        }
  //    }
  //  }//laco for

  //  pmask =  pvpask         / oneIfZero(  vpask        );
  //  pmbid =  pvpbid         / oneIfZero(  vpbid        );
  //  pm    = (pvpask+pvpbid) / oneIfZero( (vpask+vpbid) );

  //  double dx_pmask = (pmask - pm   );
  //  double dx_pmbid = (pm    - pmbid);

  //  m_pmask = pmask;
  //  m_pmbid = pmbid;
  //  m_pm    = pm;
}


  //---------------------------------------------------------------------------------------+
  // ==================== Calculo de PRECO EM FUNCAO DO VOLUME =====================       |
  // Faz: - adiciona tick nos vetores de calculo de medias de precos ponderados por volume.|
  //      - recalcula medias de precos transacoes ponderadas por volume.                   |
  //---------------------------------------------------------------------------------------+
  void osc_estatistic::acumularTick( MqlTick& tick ){
     double totVol =                (double)tick.volume   ;
     double selVol = (isTkSel(tick)?(double)tick.volume:0);
     double buyVol = (isTkBuy(tick)?(double)tick.volume:0);

     double totPrice =                tick.last   ;
     double selPrice = (isTkSel(tick)?tick.last:0);
     double buyPrice = (isTkBuy(tick)?tick.last:0);

   // Print ("totVol,selVol,buyVol,totPrice,selPrice,buyPrice:",totVol,selVol,buyVol,totPrice,selPrice,buyPrice,"---",m_selVolQ.Count());
     // media geral de precos          ponderados pelo volume...
     m_totVolQ     .add(tick.time, totVol         ); // volume        .
     m_totPriceQ   .add(tick.time, totPrice       ); // preco         .
   //m_totPriceVolQ.add(tick.time, totVol*totPrice); // preco x volume.

    // media geral de preco de compra ponderado pelo volume de compra...
     m_selVolQ     .add(tick.time, selVol         ); // volume        .
     m_selPriceQ   .add(tick.time, selPrice       ); // preco         .
   //m_selPriceVolQ.add(tick.time, selVol*selPrice); // preco x volume.

    // media geral de preco de vendas ponderado pelo volume de vendas...
     m_buyVolQ     .add(tick.time, buyVol         ); // volume        .
     m_buyPriceQ   .add(tick.time, buyPrice       ); // preco         .
   //m_buyPriceVolQ.add(tick.time, buyVol*buyPrice); // preco x volume.

     // soma e media de volumes...
     m_totVS = m_totVolQ.getSoma(); m_totVM  = m_totVolQ.getMedia();
     m_selVS = m_selVolQ.getSoma(); m_selVM  = m_selVolQ.getMedia();
     m_buyVS = m_buyVolQ.getSoma(); m_buyVM  = m_buyVolQ.getMedia();

     // soma e media de precos...
     /*m_totPS  = m_totPriceQ.getSoma();*/ m_totPM  = m_totPriceQ.getMedia();
     /*m_selPS  = m_selPriceQ.getSoma();*/ m_selPM  = m_selPriceQ.getMedia();
     /*m_buyPS  = m_buyPriceQ.getSoma();*/ m_buyPM  = m_buyPriceQ.getMedia();

     // soma e media de precos multiplicados pelos volumes (pesos)...
     m_totPVS = m_totPriceVolQ.getSoma(); m_totPVM = m_totPriceVolQ.getMedia();
     m_selPVS = m_selPriceVolQ.getSoma(); m_selPVM = m_selPriceVolQ.getMedia();
     m_buyPVS = m_buyPriceVolQ.getSoma(); m_buyPVM = m_buyPriceVolQ.getMedia();

     //preco medio ponderado pelo volume...
     m_totPMPV = (m_totVS==0)?0:m_totPVS / m_totVS;
     m_selPMPV = (m_selVS==0)?0:m_selPVS / m_selVS;
     m_buyPMPV = (m_buyVS==0)?0:m_buyPVS / m_buyVS;

     // atualiza a distancias entre as medias de compra e venda ateh a media de preco geral...
     // <TODO> verifique se a distancia negativa pode gerar sinais.
     m_dxSel = m_totPMPV - m_selPMPV;
     m_dxBuy = m_buyPMPV - m_totPMPV;
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


//+------------------------------------------------------------------+
//| Transforma ticks sem volume em ticks de trade.                   |
//| Usado para simular trades em corretoras que nao informam ticks   |
//| de trade.                                                        |
//+------------------------------------------------------------------+
void osc_estatistic::normalizarTick( MqlTick& tick ){
     double i    = 0;
     double last = 0;
     int    vol  = 1;
     if ( isTkAsk(tick) ){//&& m_ult_tick.ask!=0 ){

        // subiu o preco ask, entao simulamos a compra que subiu o ask
        if( tick.ask > m_ult_tick.ask ||
            tick.bid > m_ult_tick.bid   ){
            tick.volume++; tick.volume_real++; vol++;
            tick.last        = tick.last        == 0 ? m_ult_tick.ask: tick.last       ;
          //tick.volume      = tick.volume      == 0 ? vol           : tick.volume     ;
          //tick.volume_real = tick.volume_real == 0 ? vol           : tick.volume_real;
            tick.flags       = tick.flags|TICK_FLAG_BUY|TICK_FLAG_LAST|TICK_FLAG_VOLUME;
            last            += tick.last;
            i++;
        }
     }
     if ( isTkBid(tick) ){//&& m_ult_tick.bid!=0 ){
        // baixou o preco bid, entao simulamos a venda que baixou o bid
      if(tick.bid < m_ult_tick.bid ||
         tick.ask < m_ult_tick.ask  ){
         tick.volume++; tick.volume_real++; vol++;
         tick.last        = tick.last        == 0 ? m_ult_tick.bid: tick.last       ;
       //tick.volume      = tick.volume      == 0 ? vol             : tick.volume     ;
       //tick.volume_real = tick.volume_real == 0 ? vol             : tick.volume_real;
          tick.flags       = tick.flags|TICK_FLAG_SELL|TICK_FLAG_LAST|TICK_FLAG_VOLUME;
          last            += tick.last;
          i++;
      }
     }
     //tick.volume = vol; tick.volume_real = vol;
     if(i>1){tick.last = last/i;}
}

