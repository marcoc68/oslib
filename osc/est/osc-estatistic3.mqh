//+------------------------------------------------------------------+
//|                                              osc-estatistic2.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"

#include <oslib\osc-padrao.mqh>
#include <oslib\osc\data\osc-vetor-circular3.mqh>
#include <oslib\osc\est\CStat.mqh>
#include <oslib\osc\est\C0003ModelRegLin.mqh>
//+-----------------------------------------------------------------------------------------------+
//| Informa estatísticas de ticks acumulados.                                                     |
//| Esta versao acumula por tempo diferente da anterior que acumulava por quantidade de ticks     |
//| 20201104: volta a acumular por tick                                                           |
//+-----------------------------------------------------------------------------------------------+

//#define EST2_QTD_TICK_ACEVOL 0.17  // aproximadamente 1/6 da quantidade de acumulos usados calculo das demais medias.
//#define QTD_TICK_PROC  400
#define EST2_PERIODO_ACUM_DEFAULT 10 //420 segundos que equivalem a 7 minutos
#define BOOK_DEEP 10  // profundidade do book que deve ser processada
//#define MUL_QTD_BOOK    7

class osc_estatistic3:public osc_padrao{
private:

//  ==================== CALCULO DO FLUXO DE ORDENS NO BOOK ============================
    osc_vetor_circular2 m_vetFluxAsk ; //fluxo de ordens  (ask).
    osc_vetor_circular2 m_vetFluxBid ; //fluxo de ordens  (bid).
    uint                m_lenVetFluxo; //tamanho dos  vetores de fluxo de ordens no book;

    // Variaveis para administrar o fluxo de ordens no book. Passar para o nivel da classe...
    MqlBookInfo m_bookAnt[]  ;
    MqlBookInfo m_bookDif[]  ;
    int         m_tamanhoBook;
    int         m_meioDoBook;
    double      m_PUP[BOOK_DEEP]; // vetor de deep imbalances
    void        calcPUP(MqlBookInfo &book[], const int meioDoBook); // atualiza o vetor de deep imbalances

    double      m_tick_size;
    CStat       m_stat;
   
    // variacao de ordens bid e ask em relacao a ultima alteracao do book.
    double m_fluxoBid; // var auxiliar para o calculo do fluxo ask por segundo. Nao deve ser consultada nem usada em calculos. 
    double m_fluxoAsk; // var auxiliar para o calculo do fluxo bid por segundo. Nao deve ser consultada nem usada em calculos.  
    double m_bidLiquido; // variavel temporaria. usada no calculo da probabilidade do preco mover em funcao do fluxo. nao deve ser consultada.
    double m_askLiquido; // variavel temporaria. usada no calculo da probabilidade do preco mover em funcao do fluxo. nao deve ser consultada.

    double m_fluxoAskPorSeg   ;//fluxo de ordens ask por segundo.
    double m_fluxoBidPorSeg   ;//fluxo de ordens bid por segundo.
    double m_volTradeSelPorSeg;//volume de vendas                  realizadas por segundo.
    double m_volTradeBuyPorSeg;//volume de compras                 realizadas por segundo.
    double m_volTradeTotPorSeg;//volume de transacoes              realizadas por segundo.
    double m_volTradeLiqPorSeg;//volume de compras menos de vendas realizadas por segundo.
  
    double m_newAskPorSeg ;//novas ordens ask por segundo.
    double m_newBidPorSeg ;//novas ordens bid por segundo.
    double m_cancAskPorSeg;//cancelamentos ask por segundo.
    double m_cancBidPorSeg;//cancelamentos bid por segundo.
    double m_prbAskSubir  ;//probabilidade Ask subir.
    double m_prbAskDescer ;//probabilidade Ask descer.
    double m_prbBidDescer ;//probabilidade Bid subir.
    double m_prbBidSubir  ;//probabilidade Bid descer.
//  ==================== FIM CALCULO DO FLUXO DE ORDENS NO BOOK ========================


// ==================== OFERTAS(DOM): Calculo de PRECO EM FUNCAO DO VOLUME =====================
   osc_vetor_circular2 m_vetBookAsk; //acumulacao de ofertas de venda  (ask).
   osc_vetor_circular2 m_vetBookBid; //acumulacao de ofertas de compra (bid).
   osc_vetor_circular2 m_vetBookTot; //acumulacao de ofertas de venda e compra (ask e bid).
   double              m_dxAsk     ;
   double              m_dxBid     ;
   uint                m_lenVetMediaBook      ; // tamanho do  vetor   de acumulo de medias de ofertas totais            do book;
   uint                m_lenVetMediaBookAskBid; // tamanho dos vetores de acumulo de medias de ofertas de compra e venda do book;
   double              m_dxAskTrade; // distancia da media ask(book) a media de agressoes totais.
   double              m_dxBidTrade; // distancia da media bid(book) a media de agressoes totais.
// ==================== OFERTAS(DOM): FIM Calculo de PRECO EM FUNCAO DO VOLUME ================

// ==================== TRADES(TICKS): Calculo de PRECO EM FUNCAO DO VOLUME =====================
  // media geral de preco de trades ponderados pelos respectivos volumes...
  osc_vetor_circular2 m_vetTradeTot; // medias de trades/agressoes totais    dos ultimos QTD_TICK_PROC.
  osc_vetor_circular2 m_vetTradeSel; // medias de trades/agressoes de venda  dos ultimos QTD_TICK_PROC.
  osc_vetor_circular2 m_vetTradeBuy; // medias de trades/agressoes de compra dos ultimos QTD_TICK_PROC.
  double              m_dxBuyAnt   ; // distancia entre a media de compra e geral    (compra menos geral);
  double              m_dxSelAnt   ; // distancia entre a media geral     e de venda (geral  menos venda);
  double              m_dxBuy      ; // distancia entre a media de compra e geral    (compra menos geral);
  double              m_dxSel      ; // distancia entre a media geral     e de venda (geral  menos venda);
  uint                m_lenVetMediaTick; // tamanho dos vetores de acumulo de medias de ticks;
// ==================== TRADES(TICKS): FIM Calculo de PRECO EM FUNCAO DO VOLUME =====================

  osc_vetor_circular2 m_vetCirc[6];// = {m_vetBookAsk,m_vetBookBid, m_vetBookTot, m_vetTradeSel, m_vetTradeBuy, m_vetTradeTot};
  static const int ASK  ;
  static const int BID  ;
  static const int BOOK ;
  static const int BUY  ;
  static const int SELL ;
  static const int TRADE;


// ==================== TRADES(TICKS): Calculo de ACELERACAO DE VOLUME =====================
//osc_vetor_circular2 m_aceVolTotQ; // fila com ultimas QTD_TICK_VELVOL aceleracoes de volume
//osc_vetor_circular2 m_aceVolSelQ; // fila com ultimas QTD_TICK_VELVOL aceleracoes de volume de venda
//osc_vetor_circular2 m_aceVolBuyQ; // fila com ultimas QTD_TICK_VELVOL aceleracoes de volume de compras
// ==================== TRADES(TICKS): Fim do Calculo de ACELERACAO DE VOLUME ===============

// ==================== TRADES(TICKS): Calculo de TENDENCIA E REVERSAO =====================
//osc_vetor_circular2 m_vetTendencia; // fila com ultimas diferencas entre o preco atual e o anterior
//osc_vetor_circular2 m_vetReversao ; // x% da fila anterior
// ==================== TRADES(TICKS): Fim do Calculo de ACELERACAO DE VOLUME ===============


// ==================== TRADES(TICKS): VOLUME DE AGRESSOES TOTAIS E SALDOS  =====================
  double m_totVol; // volume de agressoes            processadas.  
  double m_selVol; // volume de agressoes de vendas  processadas
  double m_buyVol; // volume de agressoes de compras processadas
  double m_sldVol; // saldo  de agressoes. Se positivo, entao buy>sel. Se negativo, entao sel>buy.
// ==================== TRADES(TICKS): VOLUME DE AGRESSOES TOTAIS E SALDOS  =====================

  double   m_open    ; // primeiro preco do periodo.
  double   m_max     ; // maior preco do periodo.
  double   m_min     ; // menor preco do periodo.
  double   m_close   ; // ultimo preco do periodo.
  double   m_last    ; // ultimo preco do periodo.

  double   m_ask;  // preco de oferta de compra do ultimo tick adicionado
  double   m_bid;  // preco de oferta de venda  do ultimo tick adicionado
  long     m_time; // hora do ultimo tick acumulado

  MqlTick  m_ult_tick;

  // variaveis usadas na funcao acumularTick
  double m_totVolTmp;
  double m_selVolTmp;
  double m_buyVolTmp;
  double m_totPriceTmp;
  double m_selPriceTmp;
  double m_buyPriceTmp;
  // variaveis usadas na funcao acumularTick
  void acumularTick           (     MqlTick&     tick, bool flag_volume_tick=false );

  //void acumularBook  ( MqlBookInfo& book[], double book_out, double tickSize);
  //void acumularBook  ( const datetime pTime, const MqlBookInfo& book[], const int tamanhoBook, const double book_out, const double tickSize);
//void   calcAcelVol          (      MqlTick&     tick       );
  void   normalizarTick       (      MqlTick&     tick       ); //transforma ticks em ticks de compra e venda;
//void   calcTendenciaReversao(      MqlTick&     tick       );
  double calcFluxoBook        (const MqlBookInfo& book, int i, double peso); // calculo do fluxo de ordens no book...
  void   calcProbFluxo(); // calcula probabilidade do preco subir/descer em funcao do fluxo de trades e ordens do periodo.
  // para geracao da linha com insert do book;
  string m_sql_insert_book      ;
  bool   m_gerar_sql_insert_book;
  string m_symbolStr            ;
  ulong  m_microsecbook_atu     ;
  ulong  m_microsecbook_ant     ;

  // flag que indica se deve tentar consertar ticks sem flag antes do addtick.
  bool m_consertar_ticks;
  
  // modelo de regressao linear simples
  C0003ModelRegLin m_regLin;
  
public:
   osc_estatistic3(){Print(__FUNCTION__,":compilado em:",__DATETIME__);}
  ~osc_estatistic3(){Print(__FUNCTION__,":finalizado!"               );}
  void   initialize(uint lenVetMedia=EST2_PERIODO_ACUM_DEFAULT, bool flg_consertar_tick=false, bool relogio_por_evento=false );
  void   addTick( MqlTick& tick );
  void   addBook              ( const datetime pTime,       MqlBookInfo& book[], const int pTamanhoBook, const double book_out, const double tickSize);
  void   addBookSemPesoPosicao( const datetime pTime, const MqlBookInfo& book[], const int tamanhoBook , const double book_out, const double tickSize);
  void   checkResize(double tolerancia); // equaliza o tamanho dos vetores de media para que a diferenca de tempo de acumulacao das estatisticao fique abaixo da tolerancia.
   int   copyPriceTo       (double &price       [] ){return m_vetTradeTot.copyPriceTo       (price     );} // fornece copia do vetor de precos
   int   copyPriceMedioTo  (double &priceMedio  [] ){return m_vetTradeTot.copyMediaTo       (priceMedio);} // fornece copia do vetor de preco medio das agressoes;
   int   copyOrderFlowRetTo(double &orderFlowRet[] ){return m_vetTradeTot.copyOrderFlowRetTo(orderFlowRet);} // fornece copia do vetor de retornos de order flow;
//bool   estimarProxAgressao(double& price, double& b0, double& b1, double& r2);
  bool   regLinCompile(double& r2);
  bool   regLinCompile(double& vetX[], double& r2);
  double regLinPredict();
  double regLinGetB1   (){ return m_regLin.getB1(); }
  double regLinGetSlope(){ return m_regLin.getSlope(); }
  double regLinGetIntercept(){ return m_regLin.getIntercept(); }
  double getPUP(int deep){ return m_PUP[deep]; } // deep inbalance

  double ask (){return m_ask ;}
  double bid (){return m_bid ;}
  double last(){return m_last;}
  double pmed(){return (m_ask+m_bid)/2.0;}
  double getLogRetTrade     (){ return m_vetTradeTot.getLogRet     (); }
  double getLogRetTradeMedio(){ return m_vetTradeTot.getLogRetMedio(); }

  //void setDebugMode(bool debugMode){ m_debug = debugMode;}

  //--- dados de tendencia e reversao (agressoes ao book)
//double getTendencia(){ return m_vetTendencia.getSoma(); } // acumulo de diferencas de precos nos ultimos trades
//double getReversao (){ return m_vetReversao .getSoma(); } // acumulo de diferencas de precos em x% dos ultimos trades

//long   getTempoAcumTendencia(){return m_vetTendencia.getLenInSec();}// tamanho, em segundos, do vetor de tendencias.
//long   getTempoAcumRversao  (){return m_vetReversao .getLenInSec();}// tamanho, em segundos, do vetor de reversao.

//long   getLenVetTendencia(){return m_vetTendencia.getLenInSec();}// tamanho do vetor de tendencias.
//long   getLenVetRversao  (){return m_vetReversao .getLenInSec();}// tamanho do vetor de reversao.

  //--- dados de aceleracao de volume de trades (agressoes ao book)
  //double getAceVol()   { return m_aceVolTotQ.getMedia(); } // aceleracao do crescimento de volume
  //double getAceVolBuy(){ return m_aceVolBuyQ.getMedia(); } // aceleracao do crescimento do volume de compras
  //double getAceVolSel(){ return m_aceVolSelQ.getMedia(); } // aceleracao do crescimento do volume de vendas
  double getAceVol()   { return m_vetTradeTot.getAcelVol(); } // aceleracao do crescimento de volume
  double getAceVolBuy(){ return m_vetTradeBuy.getAcelVol(); } // aceleracao do crescimento do volume de compras
  double getAceVolSel(){ return m_vetTradeSel.getAcelVol(); } // aceleracao do crescimento do volume de vendas
  double getAceVolLiq(){ return m_vetTradeBuy.getAcelVol() - 
                                m_vetTradeSel.getAcelVol(); } // aceleracao liquida, do crescimento do volume. se negativa, volume de vendas cresce mais rapido (ou freia mais lenta) que o de venda. se positiva, interprete ao contrario

//long   getTempoAcumAceVol   (){return m_aceVolTotQ.getLenInSec();}// tamanho, em segundos, do vetor de aceleracao de ticks    total.
//long   getTempoAcumAceVolBuy(){return m_aceVolBuyQ.getLenInSec();}// tamanho, em segundos, do vetor de aceleracao de ticks de compra.
//long   getTempoAcumAceVolSel(){return m_aceVolSelQ.getLenInSec();}// tamanho, em segundos, do vetor de aceleracao de ticks de venda.

//long getLenVetAcumAceVol   (){return m_aceVolTotQ.getLenVet();} // tamanho do vetor de aceleracao de ticks;
//long getLenVetAcumAceVolBuy(){return m_aceVolBuyQ.getLenVet();} // tamanho do vetor de aceleracao de ticks de compra;
//long getLenVetAcumAceVolSel(){return m_aceVolSelQ.getLenVet();} // tamanho do vetor de aceleracao de ticks de venda;
  //--- dados de aceleracao de volume de trades (agressoes ao book)


// ==================== TRADES(TICKS): VOLUME DE AGRESSOES TOTAIS E SALDOS DESDE O INICIO DA EXECUCAO  =====================
  double getVolTotTot(){ return m_totVol; }// volume de agressoes            processadas desde o inicio da acumulacao.  
  double getVolTotSel(){ return m_selVol; }// volume de agressoes de vendas  processadas desde o inicio da acumulacao.
  double getVolTotBuy(){ return m_buyVol; }// volume de agressoes de compras processadas desde o inicio da acumulacao.
  double getVolTotSld(){ return m_sldVol; }// saldo  de agressoes. Se positivo, entao buy>sel. Se negativo, entao sel>buy.  Desde o inicio da acumulacao.
// ==================== TRADES(TICKS): VOLUME DE AGRESSOES TOTAIS E SALDOS DESDE O INICIO DA EXECUCAO  =====================

  //--- dados de trades (agressoes ao book) na janela de estatistica
  double getVolTradeSel(){return m_vetTradeSel.getSomaPeso();}//volume de vendas     realizadas no periodo.
  double getVolTradeBuy(){return m_vetTradeBuy.getSomaPeso();}//volume de compras    realizadas no periodo.
  double getVolTrade   (){return m_vetTradeTot.getSomaPeso();}//volume de transacoes realizadas no periodo.

  double getVolTradeSelPorSeg(){return m_volTradeSelPorSeg;}//volume de vendas               por segundo no periodo.
  double getVolTradeBuyPorSeg(){return m_volTradeBuyPorSeg;}//volume de compras              por segundo no periodo.
  double getVolTradeTotPorSeg(){return m_volTradeTotPorSeg;}//volume de transacoes           por segundo no periodo.
  double getVolTradeLiqPorSeg(){return m_volTradeLiqPorSeg;}//volume de compras menos vendas por segundo no periodo.
  
  double getvolTradePorSegDeltaPorc(){return m_volTradeTotPorSeg==0.0?0.0:((m_volTradeLiqPorSeg)/m_volTradeTotPorSeg);}


  double getVolMedTradeSel(){return m_vetTradeSel.getMediaPeso();}//volume de medio de vendas     no periodo.
  double getVolMedTradeBuy(){return m_vetTradeBuy.getMediaPeso();}//volume de medio de compras    no periodo.
  double getVolMedTrade   (){return m_vetTradeTot.getMediaPeso();}//volume de medio de transacoes no periodo.

  double getPrecoMedTradeSel(){return m_vetTradeSel.getMedia();}//preco medio de trades de vendas  ponderado pelo volume;
  double getPrecoMedTradeBuy(){return m_vetTradeBuy.getMedia();}//preco medio de trades de compras ponderado pelo volume;
  double getPrecoMedTrade   (){return m_vetTradeTot.getMedia();}//preco medio de trades    totais  ponderado pelo volume;

  double getVarTradeSel     (){return m_vetTradeSel.getO2()   ;}//variancia em relacao a media de agressoes de venda;
  double getVarTradeBuy     (){return m_vetTradeBuy.getO2()   ;}//variancia em relacao a media de agressoes de compra;
  double getVarTrade        (){return m_vetTradeTot.getO2()   ;}//variancia em relacao a media de agressoes totais;

  double getDPTradeSel     (){return sqrt( m_vetTradeSel.getO2() );}//desvio padrao em relacao a media de agressoes de venda;
  double getDPTradeBuy     (){return sqrt( m_vetTradeBuy.getO2() );}//desvio padrao em relacao a media de agressoes de compra;
  double getDPTrade        (){return sqrt( m_vetTradeTot.getO2() );}//desvio padrao em relacao a media de agressoes totais;

  double getVarTradeSelLogRet     (){return m_vetTradeSel.getO2LogRet()   ;}//variancia em relacao a media de agressoes de venda;
  double getVarTradeBuyLogRet     (){return m_vetTradeBuy.getO2LogRet()   ;}//variancia em relacao a media de agressoes de compra;
  double getVarTradeLogRet        (){return m_vetTradeTot.getO2LogRet()   ;}//variancia em relacao a media de agressoes totais;

  double getDPTradeSelLogRet     (){return sqrt( m_vetTradeSel.getO2LogRet());}//desvio padrao em relacao a media de retornos de agressoes de venda;
  double getDPTradeBuyLogRet     (){return sqrt( m_vetTradeBuy.getO2LogRet());}//desvio padrao em relacao a media de retronos de agressoes de compra;
  double getDPTradeLogRet        (){return sqrt( m_vetTradeTot.getO2LogRet());}//desvio padrao em relacao a media de retornos de agressoes totais;

  double getInclinacaoTradeSel(){return m_vetTradeSel.getCoefLinear();}//inclinacao da reta de trades de vendas  ponderado pelo volume;
  double getInclinacaoTradeBuy(){return m_vetTradeBuy.getCoefLinear();}//inclinacao da reta de trades de compras ponderado pelo volume;
  double getInclinacaoTrade   (){return m_vetTradeTot.getCoefLinear();}//inclinacao da reta de trades    totais  ponderado pelo volume;

  double getInclinacaoHLTradeSel(){return m_vetTradeSel.getCoefLinearHL();}//inclinacao maxima da reta de trades de vendas  no periodo;
  double getInclinacaoHLTradeBuy(){return m_vetTradeBuy.getCoefLinearHL();}//inclinacao maxima da reta de trades de compras no periodo;
  double getInclinacaoHLTrade   (){return m_vetTradeTot.getCoefLinearHL();}//inclinacao maxima da reta de trades    totais  no periodo;
  double getKyleLambdaHLTrade   (){return m_vetTradeTot.getKyleLambdaHL();}//inclinacao maxima da reta de trades    totais  em funcao do volume negociado;
  double getKyleLambda          (){return m_vetTradeTot.getKyleLambda  ();}//inclinacao maxima da reta de trades    totais  em funcao do volume negociado;

  double getFreqAskIni         (){return m_vetTradeBuy.getFreqValIni  ();}//frequencia de novas cotacoes ask;
  double getFreqBidIni         (){return m_vetTradeSel.getFreqValIni  ();}//frequencia de novas cotacoes bid;
  double getFreqAsk            (){return m_vetTradeBuy.getFreqVal     ();}//frequencia de novas cotacoes ask;
  double getFreqBid            (){return m_vetTradeSel.getFreqVal     ();}//frequencia de novas cotacoes bid;
  double getDeltaFreqAsk       (){return m_vetTradeBuy.getDeltaFreqVal();}//alteracao na frequencia de novas cotacoes ask;
  double getDeltaFreqBid       (){return m_vetTradeSel.getDeltaFreqVal();}//alteracao na frequencia de novas cotacoes bid;
  double getOrderFlow          (){return m_vetTradeTot.getFreqVal     ();}//testando order flow sendo acumulado no contador de frequencia de alteracao de precos;
  double getOrderFlowRet       (){return m_vetTradeTot.getOrderFlowRet();}//retorno de order flow;
  
  double getOrderFlowRetInPoint(){ 
      double v[];
      m_vetTradeTot.copyOrderFlowRetTo(v); 
      return m_stat.calcZscore(v); 
  }//retorno de order flow;
  
  double getDxSel             (){return m_dxSel;}//distancia entre o preco medio das transacoes e o preco medio das vendas ;
  double getDxBuy             (){return m_dxBuy;}//distancia entre o preco medio das transacoes e o preco medio das compras;

  long   getTempoAcumTrade     (){return m_vetTradeTot.getLenInSec();}// tempo desde o trade(tick) mais antigo considerado na estatistica e o mais novo.
  long   getTempoAcumTradeSel  (){return m_vetTradeSel.getLenInSec();}// tempo desde o trade(tick) mais antigo considerado na estatistica e o mais novo.
  long   getTempoAcumTradeBuy  (){return m_vetTradeBuy.getLenInSec();}// tempo desde o trade(tick) mais antigo considerado na estatistica e o mais novo.

  long getLenVetAcumTrade   (){return m_vetTradeTot.getLenVet();} // tamanho do vetor de acumulo de ticks;
  long getLenVetAcumTradeBuy(){return m_vetTradeBuy.getLenVet();} // tamanho do vetor de acumulo de ticks de compra;
  long getLenVetAcumTradeSel(){return m_vetTradeSel.getLenVet();} // tamanho do vetor de acumulo de venda;
  
//double getTradeOpen (){ return m_vetTradeTot.getOpen (); }
  double getTradeClose(){ return m_vetTradeTot.getClose(); }
  double getTradeHigh (){ return m_vetTradeTot.getHigh (); }
  double getTradeLow  (){ return m_vetTradeTot.getLow  (); }
  double getTradeSuporte        (){ return m_vetTradeTot.getSuporte       (); }
  double getTradeSuporteFut     (){ return m_vetTradeTot.getSuporteFut    (); } // suporte     previsto para o proximo periodo
  double getTradeResistencia    (){ return m_vetTradeTot.getResistencia   (); }
  double getTradeResistenciaFut (){ return m_vetTradeTot.getResistenciaFut(); } // resistencia prevista para o proximo periodo
  //double getTradeSuporteM       (){ return m_vetTradeTot.getSuporteM       (); }
  //double getTradeSuporteFutM    (){ return m_vetTradeTot.getSuporteFutM    (); } // suporte     previsto para o proximo periodo baseados nos precos medios
  //double getTradeResistenciaM   (){ return m_vetTradeTot.getResistenciaM   (); }
  //double getTradeResistenciaFutM(){ return m_vetTradeTot.getResistenciaFutM(); } // resistencia prevista para o proximo periodo baseados nos precos medios
  //--- dados de trades (agressoes ao book)

  //--- dados de fluxo de ordens (book)
  double getFluxoAsk(){return m_vetFluxAsk.getSoma();}//fluxo de ordens ask.
  double getFluxoBid(){return m_vetFluxBid.getSoma();}//fluxo de ordens bid.
    
  //--- fluxo de ordens (entrada-saidas-cancelamentos) por segundo (book)
  double getFluxoAskPorSeg(){return m_fluxoAskPorSeg;}//fluxo de ordens ask por segundo.
  double getFluxoBidPorSeg(){return m_fluxoBidPorSeg;}//fluxo de ordens bid por segundo.

  //--- fluxo de novas ordens no book (por segundo)
  //    obs: fluxoAskPorSeg e fluxoBidPorSeg podem ser negativos.
  //double getNewAskPorSeg(){return getFluxoAskPorSeg()+getVolTradeBuyPorSeg()<0?0:getFluxoAskPorSeg()+getVolTradeBuyPorSeg();}//novas ordens ask por segundo.
  //double getNewBidPorSeg(){return getFluxoBidPorSeg()+getVolTradeSelPorSeg()<0?0:getFluxoBidPorSeg()+getVolTradeSelPorSeg();}//novas ordens bid por segundo.
  //void  calcNewAskPorSeg(){ m_newAskPorSeg = m_fluxoAskPorSeg+m_volTradeBuyPorSeg<0?0:m_fluxoAskPorSeg+m_volTradeBuyPorSeg; }//novas ordens ask por segundo.
  //void  calcNewBidPorSeg(){ m_newBidPorSeg = m_fluxoBidPorSeg+m_volTradeSelPorSeg<0?0:m_fluxoBidPorSeg+m_volTradeSelPorSeg; }//novas ordens bid por segundo.
  double getNewAskPorSeg(){ return m_newAskPorSeg; }//novas ordens ask por segundo.
  double getNewBidPorSeg(){ return m_newBidPorSeg; }//novas ordens bid por segundo.

  //--- cancelamentos...
  //double getCancAskPorSeg(){return getFluxoAskPorSeg()+getVolTradeBuyPorSeg()>0?0:(getFluxoAskPorSeg()+getVolTradeBuyPorSeg())*-1;}//cancelamentos ask por segundo.
  //double getCancBidPorSeg(){return getFluxoBidPorSeg()+getVolTradeSelPorSeg()>0?0:(getFluxoBidPorSeg()+getVolTradeSelPorSeg())*-1;}//cancelamentos bid por segundo.
  //void  calcCancAskPorSeg(){m_cancAskPorSeg = m_fluxoAskPorSeg+m_volTradeBuyPorSeg>0?0:(m_fluxoAskPorSeg+m_volTradeBuyPorSeg)*-1;}//cancelamentos ask por segundo.
  //void  calcCancBidPorSeg(){m_cancBidPorSeg = m_fluxoBidPorSeg+m_volTradeSelPorSeg>0?0:(m_fluxoBidPorSeg+m_volTradeSelPorSeg)*-1;}//cancelamentos bid por segundo.
  double getCancAskPorSeg (){return m_cancAskPorSeg;}//cancelamentos ask por segundo.
  double getCancBidPorSeg (){return m_cancBidPorSeg;}//cancelamentos bid por segundo.

  //--- probabilidade do preco mover...
//double getPrbAskSubir (){return (getNewAskPorSeg()+getVolTradeBuyPorSeg())==0?0:getNewAskPorSeg     ()/(getNewAskPorSeg()+getVolTradeBuyPorSeg());}//probabilidade Ask subir.
//double getPrbAskDescer(){return (getNewAskPorSeg()+getVolTradeBuyPorSeg())==0?0:getVolTradeBuyPorSeg()/(getNewAskPorSeg()+getVolTradeBuyPorSeg());}//probabilidade Ask descer.

//void  calcPrbAskSubir (){m_prbAskSubir  = (getNewAskPorSeg()+getVolTradeBuyPorSeg()+getCancAskPorSeg())==0?0:(getNewAskPorSeg     ()                   )/(getNewAskPorSeg()+getVolTradeBuyPorSeg()+getCancAskPorSeg());}//probabilidade Ask subir.
//void  calcPrbAskDescer(){m_prbAskDescer = (getNewAskPorSeg()+getVolTradeBuyPorSeg()+getCancAskPorSeg())==0?0:(getVolTradeBuyPorSeg()+getCancAskPorSeg())/(getNewAskPorSeg()+getVolTradeBuyPorSeg()+getCancAskPorSeg());}//probabilidade Ask descer.
//void  calcPrbAskSubir (){m_prbAskSubir  = (m_newAskPorSeg+m_volTradeBuyPorSeg+m_cancAskPorSeg)==0?0:(m_newAskPorSeg                     )/(m_newAskPorSeg+m_volTradeBuyPorSeg+m_cancAskPorSeg);}//probabilidade Ask subir.
//void  calcPrbAskDescer(){m_prbAskDescer = (m_newAskPorSeg+m_volTradeBuyPorSeg+m_cancAskPorSeg)==0?0:(m_volTradeBuyPorSeg+m_cancAskPorSeg)/(m_newAskPorSeg+m_volTradeBuyPorSeg+m_cancAskPorSeg);}//probabilidade Ask descer.
  double getPrbAskSubir (){return m_prbAskSubir ;}//probabilidade Ask subir.
  double getPrbAskDescer(){return m_prbAskDescer;}//probabilidade Ask descer.

//double getPrbBidSubir (){return (getNewBidPorSeg()+getVolTradeSelPorSeg())==0?0:getNewBidPorSeg     ()/(getNewBidPorSeg()+getVolTradeSelPorSeg());}//probabilidade Bid subir.
//double getPrbBidDescer(){return (getNewBidPorSeg()+getVolTradeSelPorSeg())==0?0:getVolTradeSelPorSeg()/(getNewBidPorSeg()+getVolTradeSelPorSeg());}//probabilidade Bid descer.
//void  calcPrbBidDescer (){m_prbBidDescer = (getNewBidPorSeg()+getVolTradeSelPorSeg()+getCancBidPorSeg())==0?0:(getNewBidPorSeg     ()                   )/(getNewBidPorSeg()+getVolTradeSelPorSeg()+getCancBidPorSeg());}//probabilidade Bid subir.
//void  calcPrbBidSubir  (){m_prbBidSubir  = (getNewBidPorSeg()+getVolTradeSelPorSeg()+getCancBidPorSeg())==0?0:(getVolTradeSelPorSeg()+getCancBidPorSeg())/(getNewBidPorSeg()+getVolTradeSelPorSeg()+getCancBidPorSeg());}//probabilidade Bid descer.
//void  calcPrbBidDescer (){m_prbBidDescer = (m_newBidPorSeg+m_volTradeSelPorSeg+m_cancBidPorSeg)==0?0:(m_newBidPorSeg                     )/(m_newBidPorSeg+m_volTradeSelPorSeg+m_cancBidPorSeg);}//probabilidade Bid subir.
//void  calcPrbBidSubir  (){m_prbBidSubir  = (m_newBidPorSeg+m_volTradeSelPorSeg+m_cancBidPorSeg)==0?0:(m_volTradeSelPorSeg+m_cancBidPorSeg)/(m_newBidPorSeg+m_volTradeSelPorSeg+m_cancBidPorSeg);}//probabilidade Bid descer.
  double getPrbBidDescer (){return m_prbBidDescer;}//probabilidade Bid subir.
  double getPrbBidSubir  (){return m_prbBidSubir ;}//probabilidade Bid descer.

  //--- dados de ofertas (book)
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

  double getDxAskTrade(){return m_dxAskTrade ;}//distancia entre o preco medio das ofertas(ask) e o preco medio das agressoes ;
  double getDxBidTrade(){return m_dxBidTrade ;}//distancia entre o preco medio das ofertas(bid) e o preco medio das agressoes;
  double getDxMedTradeBook(){return m_vetTradeTot.getMedia()-m_vetBookTot.getMedia() ;}//distancia entre a media de agressoes e do book;

  long   getTempoAcumBook     (){return m_vetBookTot.getLenInSec();}// tempo desde a posicao do noob mais antiga considerado na estatistica e a mais nova.
  long   getTempoAcumBookAsk  (){return m_vetBookAsk.getLenInSec();}// tempo desde a posicao do noob mais antiga considerado na estatistica e a mais nova.
  long   getTempoAcumBookBid  (){return m_vetBookBid.getLenInSec();}// tempo desde a posicao do noob mais antiga considerado na estatistica e a mais nova.

  long getLenVetAcumBook   (){return m_vetBookTot.getLenVet();} // tamanho do  vetor   de acumulo de medias de ofertas totais            do book;
  long getLenVetAcumBookAsk(){return m_vetBookAsk.getLenVet();} // tamanho do  vetor   de acumulo de medias de ofertas totais            do book;
  long getLenVetAcumBookBid(){return m_vetBookBid.getLenVet();} // tamanho do  vetor   de acumulo de medias de ofertas totais            do book;

    double getDesbalanceamentoUP0(){ return m_pUP0;}// desbalancelamento positivo (preco sobe) na primeira fila de ofertas;  Para encontrar o negativo, subtraia de 1;
    double getDesbalanceamentoUP1(){ return m_pUP1;}// desbalancelamento positivo (preco sobe) na segunda  fila de ofertas;  Para encontrar o negativo, subtraia de 1;  
    double getDesbalanceamentoUP2(){ return m_pUP2;}// desbalancelamento positivo (preco sobe) na terceira fila de ofertas;  Para encontrar o negativo, subtraia de 1;  
    double getDesbalanceamentoUP3(){ return m_pUP3;}// desbalancelamento positivo (preco sobe) na quarta   fila de ofertas;  Para encontrar o negativo, subtraia de 1;  
  
    //--- dados de ofertas (book)
  
    // para geracao da linha com insert do book;
    void setFlagGerarSqlInsertBook(bool   gerar_sql){ m_gerar_sql_insert_book=gerar_sql; m_sql_insert_book=""; }
    void setSymbolStr             (string symbolStr){ m_symbolStr            =symbolStr;                       }

    // opcao para consertar ticks sem flag antes de cada addTick.
    void setConsertarTicksSemFlag (bool   opcao    ){ m_consertar_ticks=opcao; if(opcao) initQtdTickConsertado(); }
   
    // spread bid-ask efetivo. calculado segundo Irene Aldridge:
    // eh igual a duas vezes a diferença entre o ultimo preco de negociacao e o ponto medio
    // entre os preços bid e ask cotados, dividido pelo ponto medio entre os precos bid e ask cotados. 
    static double calcSpreadEfetivo(MqlTick& tick);

    // calculo da probabilidade do preco subir/descer em funcao do volume nos niveis do livro de ofertas...  
}; // fim do corpo da classe

  const int osc_estatistic3::ASK  = 0;
  const int osc_estatistic3::BID  = 1;
  const int osc_estatistic3::BOOK = 2;
  const int osc_estatistic3::BUY  = 3;
  const int osc_estatistic3::SELL = 4;
  const int osc_estatistic3::TRADE= 5;

void osc_estatistic3::initialize(uint lenVetMedia=EST2_PERIODO_ACUM_DEFAULT, bool flg_consertar_tick=false, bool relogio_por_evento=false){

    Print(__FUNCTION__," [",getId(),"]","[Inicializando vetores de media com tamanho em segundos ", lenVetMedia,"...]");
    
    m_vetCirc[ASK]   = m_vetBookAsk; 
    m_vetCirc[BID]   = m_vetBookBid;
    m_vetCirc[BOOK]  = m_vetBookTot;
    m_vetCirc[BUY]   = m_vetTradeSel;
    m_vetCirc[SELL]  = m_vetTradeBuy;
    m_vetCirc[TRADE] = m_vetTradeTot;
  
    setFlagGerarSqlInsertBook(false);
    
    setConsertarTicksSemFlag(flg_consertar_tick);
    m_microsecbook_atu = GetMicrosecondCount();
    m_microsecbook_ant = m_microsecbook_atu;
    
    m_lenVetMediaTick       = lenVetMedia;
    m_lenVetMediaBookAskBid = lenVetMedia;
    m_lenVetMediaBook       = lenVetMedia;
    m_lenVetFluxo           = lenVetMedia;

    m_vetTradeTot.initialize(m_lenVetMediaTick,"TradeTot",relogio_por_evento);// medias de preco de trades ponderados por volume nos ultimos TICKS informados no parametro.
    m_vetTradeBuy.initialize(m_lenVetMediaTick,"TradeBuy",relogio_por_evento);// medias de preco de trades ponderados por volume nos ultimos TICKS informados no parametro.
    m_vetTradeSel.initialize(m_lenVetMediaTick,"TradeSel",relogio_por_evento);// medias de preco de trades ponderados por volume nos ultimos TICKS informados no parametro.
    m_vetTradeTot.setSouCandle(true);

//  m_vetTendencia.initialize(m_lenVetMediaTick  ,"Tendencia");// medias de preco de trades ponderados por volume nos ultimos TICKS informados no parametro.
//  m_vetReversao .initialize(m_lenVetMediaTick/6,"Reversao" );// medias de preco de trades ponderados por volume nos ultimos TICKS informados no parametro.

    m_vetBookTot.initialize(m_lenVetMediaBook      ,"BookTot" ,relogio_por_evento);// medias de preco no book ponderados pelo volume e peso dos precos.
    m_vetBookAsk.initialize(m_lenVetMediaBookAskBid,"BookAsk" ,relogio_por_evento);// medias de preco no book ponderados pelo volume e peso dos precos.
    m_vetBookBid.initialize(m_lenVetMediaBookAskBid,"BookBid" ,relogio_por_evento);// medias de preco no book ponderados pelo volume e peso dos precos.
    m_vetFluxAsk.initialize(m_lenVetFluxo          ,"FluxoAsk",relogio_por_evento);// fluxo de ordens ask no book.
    m_vetFluxBid.initialize(m_lenVetFluxo          ,"FluxoBid",relogio_por_evento);// fluxo de ordens bid no book.

    //aceleracao de volume de trade...
    //m_aceVolTotQ.initialize( (int)(lenVetMedia * EST2_QTD_TICK_ACEVOL),"AceVolTradeTot" );
    //m_aceVolBuyQ.initialize( (int)(lenVetMedia * EST2_QTD_TICK_ACEVOL),"AceVolTradeBuy" );
    //m_aceVolSelQ.initialize( (int)(lenVetMedia * EST2_QTD_TICK_ACEVOL),"AceVolTradeSel" );

    m_dxAskTrade=0; m_dxBidTrade=0;
    m_dxBuy=0; m_dxSel =0; // distancia entre as medias de            venda(sel)/compra(buy) e a media geral           de compra e venda.
    m_dxAsk=0; m_dxBid =0; // distancia entre as medias de ofertas de venda(ask)/compra(bid) e a media geral de oferta de compra e venda.
    m_max  =0; m_min   =0;

    // volume da primeira e segunda fila bid/ask do livro de ofertas
    m_bs0 = 0;
    m_bs1 = 0;
    m_as0 = 0;
    m_as1 = 0;

    m_ult_tick.last  =0;
    m_ult_tick.volume=0;
    m_ult_tick.ask   =0;
    m_ult_tick.bid   =0;
    m_ult_tick.time  =0;

    m_totVol=0; // volume de agressoes            processadas.  
    m_selVol=0; // volume de agressoes de vendas  processadas
    m_buyVol=0; // volume de agressoes de compras processadas
    m_sldVol=0; // saldo  de agressoes. Se positivo, entao buy>sel. Se negativo, entao sel>buy.
  // ==================== Fim Calculo de PRECO EM FUNCAO DO VOLUME =====================
}

void osc_estatistic3::addTick( MqlTick& tick ){

  //em modo hibrido, simula compra e venda em funcao da variacao em ask e bid
  //m_modoHibrido = false;
  
  if(m_consertar_ticks) consertarTickSemFlag(tick);
  
  //if(  m_modoHibrido ){ normalizarTick(tick); }
    if( !isTkTra(tick) ){ return; }

  m_time     = tick.time;
  m_ask      = tick.ask ;
  m_bid      = tick.bid ;
  m_last     = tick.last;
  m_close    = tick.last;
  m_max      = tick.last > m_max?tick.last:m_max;
  m_min      = tick.last < m_min?tick.last:m_min;

  // calculando as medias baseado no fluxo continuo de ticks...
  acumularTick         (tick);
  //calcTendenciaReversao(tick);
  //calcAcelVol          (tick);// calculos das aceleracoes de volume deve ser antes de pisar m_ult_tick...

  m_ult_tick = tick; // pisando m_ult_tick...
  //m_tick_ant_last   = tick.last;
  //m_tick_ant_volume = tick.volume;

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
 //| Faz: - adiciona entradas no book de ofertas aos vetores de calculo de medias ponderados por volume. |
 //|      - recalcula medias de precos ofertas ponderadas por volume.                                    |
 //|      - esta versao adiciona os precos medios jah calculados.                                        |
 //+-----------------------------------------------------------------------------------------------------+
 void osc_estatistic3::addBookSemPesoPosicao(const datetime pTime, const MqlBookInfo& book[], const int tamanhoBook, const double book_out, const double tickSize){

   //double pesoAsk = 0; double pesoBid = 0;// peso adicional das ofertas de venda e compra (peso referente a posicao do preco no book)

   // calculando a posicao dos precos significativos no book...
   int desprezarAsk = (int)( tamanhoBook * (book_out/2.0) )-1;
   int desprezarBid =        tamanhoBook - desprezarAsk    -1;

   double pesXvolXask = 0, pesXvolXbid = 0; // numerador  : soma dos precos x pesos
   double pesXvolAsk  = 0, pesXvolBid  = 0; // denominador: soma dos          pesos

   for(int i=0; i<tamanhoBook; i++){
       // calibrando os pesos em funcao da posicao do preco no book...
       //pesoAsk = book[0].price - book[i            ].price + tickSize;
       //pesoBid = book[i].price - book[tamanhoBook-1].price + tickSize;
       if( book[i].type == BOOK_TYPE_SELL && i > desprezarAsk ){
           pesXvolXask += book[i].price*book[i].volume_real;//*pesoAsk;// numerador  : soma dos precos x pesos
           pesXvolAsk  +=               book[i].volume_real;//*pesoAsk;// denominador: soma dos          pesos
       }else{
           if( book[i].type == BOOK_TYPE_BUY && i < desprezarBid ){
               pesXvolXbid += book[i].price*book[i].volume_real;//*pesoBid;// numerador  : soma dos precos x pesos
               pesXvolBid  +=               book[i].volume_real;//*pesoBid;// denominador: soma dos          pesos
           }else{
               if( i>desprezarAsk && i<desprezarBid ){
                   Print("Nenhum tipo ///////////////////////////////////////// desprezarAsk:",desprezarAsk," desprezarBid:",desprezarBid, " i:", i);
               }
           }
       }
   }//laco for

   m_vetBookAsk.add(  pesXvolXask/pesXvolAsk                          , 1, m_time );
   m_vetBookBid.add(  pesXvolXbid/pesXvolBid                          , 1, m_time );
   m_vetBookTot.add( (pesXvolXask+pesXvolXbid)/(pesXvolAsk+pesXvolBid), 1, m_time );

   m_dxAsk = ( m_vetBookAsk.getMedia() - m_vetBookTot.getMedia() );
   m_dxBid = ( m_vetBookTot.getMedia() - m_vetBookBid.getMedia() );

   m_dxAskTrade = ( m_vetBookAsk.getMedia () - m_vetTradeTot.getMedia() );
   m_dxBidTrade = ( m_vetTradeTot.getMedia() - m_vetBookBid.getMedia () );

   if( tamanhoBook > 7){
       m_meioDoBook = tamanhoBook/2;
       m_as3 = book[(m_meioDoBook)-4].volume_real;// volume quarta   fila ask
       m_as2 = book[(m_meioDoBook)-3].volume_real;// volume terceira fila ask
       m_as1 = book[(m_meioDoBook)-2].volume_real;// volume segunda  fila ask
       m_as0 = book[(m_meioDoBook)-1].volume_real;// volume primeira fila ask
       m_bs0 = book[(m_meioDoBook)  ].volume_real;// volume primeira fila bid
       m_bs1 = book[(m_meioDoBook)+1].volume_real;// volume segunda  fila bid
       m_bs2 = book[(m_meioDoBook)+2].volume_real;// volume terceira fila bid
       m_bs3 = book[(m_meioDoBook)+3].volume_real;// volume quarta   fila bid
       m_pUP0 =  m_bs0                   /(m_bs0+                  m_as0                  );
       m_pUP1 = (m_bs0+m_bs1            )/(m_bs0+m_bs1+            m_as0+m_as1            );
       m_pUP2 = (m_bs0+m_bs1+m_bs2      )/(m_bs0+m_bs1+m_bs2+      m_as0+m_as1+m_as2      );
       m_pUP3 = (m_bs0+m_bs1+m_bs2+m_bs3)/(m_bs0+m_bs1+m_bs2+m_bs3+m_as0+m_as1+m_as2+m_as3);
   }else{
      if( tamanhoBook > 1 ){
           m_meioDoBook = tamanhoBook/2;
           m_as0 = book[(m_meioDoBook)-1].volume_real;// volume primeira fila ask
           m_bs0 = book[(m_meioDoBook)  ].volume_real;// volume primeira fila bid
           m_pUP0 = m_bs0/(m_bs0+m_as0);
           m_pUP1 = 0;
      }else{
           m_pUP0 = 0;
           m_pUP1 = 0;
      }
   }

 //m_pUP0 = m_bs0/(m_bs0+m_as0);
 //m_pDW0 = m_as0/(m_as0+m_bs0);   
 //m_pUP1 = (m_bs0+m_bs1)/(m_bs0+m_bs1+m_as0+m_as1);
 //m_pDW1 = (m_as0+m_as1)/(m_as0+m_as1+m_bs0+m_bs1);   
}


double osc_estatistic3::calcFluxoBook(const MqlBookInfo& book, int i, double peso){

    //20210319 <TODO> por enquanto tiramos o claculo de fluxo no book ateh que avalie se estah correto...
    return 0;
    
    
    //Print("BVOL:",book.volume, " BVOLR:",book.volume_real);
    
    //if(m_bookDif[i].type != book[i].type) return 0;
    
    // calculando as diferencas do book...
  //m_bookDif[i].price       = book.price;
  //m_bookDif[i].volume      = book.volume      - m_bookAnt[i].volume;

    if( m_bookDif[i].type == book.type ){
        m_bookDif[i].volume_real = book.volume_real*peso - m_bookAnt[i].volume_real;
    }else{
        m_bookDif[i].type        = book.type;
        m_bookDif[i].volume_real = 0        ;
    }
   
    //salvando o book na variavel do book anterior...
    m_bookAnt[i].type        = book.type;
  //m_bookAnt[i].price       = book.price;
  //m_bookAnt[i].volume      = book.volume;
    m_bookAnt[i].volume_real = book.volume_real*peso;

   //Print("i:",i, " TYPE:",book.type, " DIF_TYPE:",m_bookDif[i].type, " VBOOK:",book.volume, " VDIF:",m_bookDif[i].volume);
   return m_bookDif[i].volume_real;
}

//|-----------------------------------------------------------------------------------------------------------------
//| calcula a probilidade do preco subir ou descer em funcao do fluxo de ordens no book e transacoes efetuadas.
//| este metodo deve ser executado sempre que se adiciona um tick ou uma alteracao de book aos vetores estatisticos.
//| ou seja, sempre que as variaveis m_fluxoXXXPorSeg ou m_volTradeXXXPorSeg forem atualizadas.
//|-----------------------------------------------------------------------------------------------------------------
void osc_estatistic3::calcProbFluxo(){

    m_newAskPorSeg  = m_fluxoAskPorSeg+m_volTradeBuyPorSeg<0?0: m_fluxoAskPorSeg+m_volTradeBuyPorSeg; //novas ordens ask por segundo no book.
    m_newBidPorSeg  = m_fluxoBidPorSeg+m_volTradeSelPorSeg<0?0: m_fluxoBidPorSeg+m_volTradeSelPorSeg; //novas ordens bid por segundo no book.
    m_cancAskPorSeg = m_fluxoAskPorSeg+m_volTradeBuyPorSeg>0?0:(m_fluxoAskPorSeg+m_volTradeBuyPorSeg)*-1;//cancelamentos ask por segundo.
    m_cancBidPorSeg = m_fluxoBidPorSeg+m_volTradeSelPorSeg>0?0:(m_fluxoBidPorSeg+m_volTradeSelPorSeg)*-1;//cancelamentos bid por segundo.

    m_bidLiquido = m_newBidPorSeg+m_volTradeSelPorSeg+m_cancBidPorSeg;
    m_askLiquido = m_newAskPorSeg+m_volTradeBuyPorSeg+m_cancAskPorSeg;

    m_prbAskSubir  = (m_askLiquido)==0?0:(m_newAskPorSeg                     )/(m_askLiquido);
    m_prbAskDescer = (m_askLiquido)==0?0:(m_volTradeBuyPorSeg+m_cancAskPorSeg)/(m_askLiquido);
    m_prbBidDescer = (m_bidLiquido)==0?0:(m_newBidPorSeg                     )/(m_bidLiquido);
    m_prbBidSubir  = (m_bidLiquido)==0?0:(m_volTradeSelPorSeg+m_cancBidPorSeg)/(m_bidLiquido);

//  void  calcPrbAskSubir (){m_prbAskSubir  = (m_newAskPorSeg+m_volTradeBuyPorSeg+m_cancAskPorSeg)==0?0:(m_newAskPorSeg                     )/(m_newAskPorSeg+m_volTradeBuyPorSeg+m_cancAskPorSeg);}//probabilidade Ask subir.
//  void  calcPrbAskDescer(){m_prbAskDescer = (m_newAskPorSeg+m_volTradeBuyPorSeg+m_cancAskPorSeg)==0?0:(m_volTradeBuyPorSeg+m_cancAskPorSeg)/(m_newAskPorSeg+m_volTradeBuyPorSeg+m_cancAskPorSeg);}//probabilidade Ask descer.
//  void  calcPrbBidDescer(){m_prbBidDescer = (m_newBidPorSeg+m_volTradeSelPorSeg+m_cancBidPorSeg)==0?0:(m_newBidPorSeg                     )/(m_newBidPorSeg+m_volTradeSelPorSeg+m_cancBidPorSeg);}//probabilidade Bid subir.
//  void  calcPrbBidSubir (){m_prbBidSubir  = (m_newBidPorSeg+m_volTradeSelPorSeg+m_cancBidPorSeg)==0?0:(m_volTradeSelPorSeg+m_cancBidPorSeg)/(m_newBidPorSeg+m_volTradeSelPorSeg+m_cancBidPorSeg);}//probabilidade Bid descer.
}

double m_bs0 ;
double m_bs1 ;
double m_bs2 ;
double m_bs3 ;
double m_as0 ;
double m_as1 ;
double m_as2 ;
double m_as3 ;
double m_pUP0;
double m_pUP1;
double m_pUP2;
double m_pUP3;
double m_pDW0;
double m_pDW1;

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

void osc_estatistic3::addBook(const datetime pTime, MqlBookInfo& book[], const int pTamanhoBook, const double book_out, const double tickSize){
   

   //addBookSemPesoPosicao(pTime,book,tamanhoBook,book_out,tickSize);
   //return;
   
     int tamanhoBook = ArraySize(book);
   //if( tamanhoBook != pTamanhoBook ){ Print(":-( ",__FUNCTION__, " ERRO tamanho do book errado=",pTamanhoBook, " deveria ser ", tamanhoBook); return; }
     if( tamanhoBook%2 == 1){ Print(":-( ",__FUNCTION__, " ERRO tamanho do book impar=",tamanhoBook); return; }
   
   //calibrando o tamanho dos arrays de medicao de fluxo de ordens no book...
   if( tamanhoBook > m_tamanhoBook ){
       m_tamanhoBook = tamanhoBook;
       ArrayResize(m_bookAnt,tamanhoBook);
       ArrayResize(m_bookDif,tamanhoBook);
       m_tamanhoBook = tamanhoBook;
   }
   
   double ask = book[tamanhoBook/2 -1].price;
   double bid = book[tamanhoBook/2   ].price;
   
   double maxAsk = book[0].price;
   double minBid = book[tamanhoBook-1].price;
   
   int tamanhoAsks = (int)round((maxAsk-ask)/tickSize);
   int tamanhoBids = (int)round((bid-minBid)/tickSize);

   double tamanho = (book[0].price - book[tamanhoBook-1].price ) / tickSize;
   Print("tamanhoBookReal:", tamanho, " arred:", (int)round(tamanho));
   Print("tamanhoAsk:", tamanhoAsks, " tamanhoBid:", tamanhoBids);
   
   double pesoAsk = 0; double pesoBid = 0;// peso adicional das ofertas de venda e compra (peso referente a posicao do preco no book)

   // calculando a posicao dos precos significativos no book...
   int desprezarAsk = (int)( tamanhoBook * (book_out/2.0) )-1;
   int desprezarBid =        tamanhoBook - desprezarAsk    -1;
   
   int desprezarAskFluxo = (int)( tamanhoBook * (0.75/2.0) )-1;
   int desprezarBidFluxo =        tamanhoBook - desprezarAsk-1;
   

   double pesXvolXask = 0, pesXvolXbid = 0; // numerador  : soma dos precos x pesos
   double pesXvolAsk  = 0, pesXvolBid  = 0; // denominador: soma dos          pesos
   
   m_fluxoAsk=0;
   m_fluxoBid=0;
 //Print(" pTime=",pTime, " m_tamanhoBook=",m_tamanhoBook," tamanhoBook=",tamanhoBook, " desprezarAsk=",desprezarAsk);
   
   if( tamanhoBook < 2 ){ Print(":-( ",__FUNCTION__, " ERRO tamanho do book=",tamanhoBook); return; }
   
   if( !m_gerar_sql_insert_book ){
   
       for(int i=0; i<tamanhoBook; i++){           
           
         //Print("No for... desprezarAsk=",desprezarAsk, " desprezarBid=",desprezarBid, " i=", i, " book[i].type=", book[i].type, " BOOK_TYPE_SELL=",BOOK_TYPE_SELL," BOOK_TYPE_BUY=",BOOK_TYPE_BUY," book_out=",book_out);

           // calibrando os pesos em funcao da posicao do preco no book...
           pesoAsk = book[0].price - book[i            ].price + tickSize;
           pesoBid = book[i].price - book[tamanhoBook-1].price + tickSize; //<TODO> 20210309 array aut of range (703,42)
           if( i > desprezarAsk && book[i].type == BOOK_TYPE_SELL ){
         //if( i < desprezarBid && book[i].type == BOOK_TYPE_SELL ){
               pesXvolXask += book[i].price*(1/book[i].volume_real)*pesoAsk;// numerador  : soma dos precos x pesos
               pesXvolAsk  +=               (1/book[i].volume_real)*pesoAsk;// denominador: soma dos          pesos
             //Print("chamando calcFluxoBook ASK...");
               if(i>desprezarAskFluxo) m_fluxoAsk  += calcFluxoBook(book[i],i,pesoAsk); // calculando o fluxo de ordens no book...
           }else{
               if( i < desprezarBid && book[i].type == BOOK_TYPE_BUY ){
             //if( i > desprezarAsk && book[i].type == BOOK_TYPE_BUY ){
                   pesXvolXbid += book[i].price*(1/book[i].volume_real)*pesoBid;// numerador  : soma dos precos x pesos
                   pesXvolBid  +=               (1/book[i].volume_real)*pesoBid;// denominador: soma dos          pesos
                 //Print("chamando calcFluxoBook BID...");
                   if(i<desprezarBidFluxo) m_fluxoBid  += calcFluxoBook(book[i],i,pesoBid); // calculando o fluxo de ordens no book...
               }else{
                   if( i>desprezarAsk || i<desprezarBid ){
                       //Print("Nenhum tipo ///////////////////////////////////////// desprezarAsk:",desprezarAsk," desprezarBid:",desprezarBid, " i:", i);
                   }
               }
           }
       }//laco for
   }else{
       m_microsecbook_atu = GetMicrosecondCount();
       datetime tc                 = TimeCurrent   ();
       double   vtrade_tot         = getVolTrade   ();
       double   vtrade_sel         = getVolTradeSel();
       double   vtrade_buy         = getVolTradeBuy();
       double   vtrade_tot_por_seg = m_vetTradeBuy.getVolPorSeg();
       double   vtrade_sel_por_seg = m_vetTradeSel.getVolPorSeg();
       double   vtrade_buy_por_seg = m_vetTradeBuy.getVolPorSeg();
       
       // string com comando para fazer insert em tabela sql. O primeiro campo (nulo) eh o id da tabela.
       m_sql_insert_book = "insert into book2(symbol,timecurr,msc";
       StringAdd( m_sql_insert_book, ",vtrade_tot"         ); // volume de trades 
       StringAdd( m_sql_insert_book, ",vtrade_sel"         ); // volume de trades de venda
       StringAdd( m_sql_insert_book, ",vtrade_buy"         ); // volume de trades de compra
       StringAdd( m_sql_insert_book, ",vtrade_tot_por_seg" ); // volume por segundo de trades 
       StringAdd( m_sql_insert_book, ",vtrade_sel_por_seg" ); // volume por segundo de trades de venda
       StringAdd( m_sql_insert_book, ",vtrade_buy_por_seg" ); // volume por segundo de trades de compra

  //double getVolTradeSel(){return m_vetTradeSel.getSomaPeso();}//volume de vendas     realizadas.
  //double getVolTradeBuy(){return m_vetTradeBuy.getSomaPeso();}//volume de compras    realizadas.
  //double getVolTrade   (){return m_vetTradeTot.getSomaPeso();}//volume de transacoes realizadas.

  //long   getTempoAcumTrade     (){return m_vetTradeTot.getLenInSec();}// tempo desde o trade(tick) mais antigo considerado na estatistica e o mais novo.
  //long   getTempoAcumTradeSel  (){return m_vetTradeSel.getLenInSec();}// tempo desde o trade(tick) mais antigo considerado na estatistica e o mais novo.
  //long   getTempoAcumTradeBuy  (){return m_vetTradeBuy.getLenInSec();}// tempo desde o trade(tick) mais antigo considerado na estatistica e o mais novo.

       
       // acrescentando os campos que serao inseridos...
       int metadeBook = tamanhoBook/2;
       for(int i=0; i<tamanhoBook; i++){
           if(i<metadeBook){ 
              StringAdd( m_sql_insert_book, ",askp" +IntegerToString( MathAbs(i  -metadeBook ) ) );
              StringAdd( m_sql_insert_book, ",askv" +IntegerToString( MathAbs(i  -metadeBook ) ) );
           }else{
              StringAdd( m_sql_insert_book, ",bidp" +IntegerToString(         i+1-metadeBook   ) );
              StringAdd( m_sql_insert_book, ",bidv" +IntegerToString(         i+1-metadeBook   ) );
           }
       }
       StringAdd( m_sql_insert_book, ")values('" + m_symbolStr
                                         + "','"+ TimeToString(TimeCurrent(),TIME_DATE|TIME_MINUTES|TIME_SECONDS) 
                                         + "'," + IntegerToString(m_microsecbook_atu-m_microsecbook_ant)
                                         //
                                         // dados de trade....
                                         + ","  + DoubleToString(vtrade_tot         )
                                         + ","  + DoubleToString(vtrade_sel         )
                                         + ","  + DoubleToString(vtrade_buy         )
                                         + ","  + DoubleToString(vtrade_tot_por_seg )
                                         + ","  + DoubleToString(vtrade_sel_por_seg )
                                         + ","  + DoubleToString(vtrade_buy_por_seg )
                                           );
                                           
       
       for(int i=0; i<tamanhoBook; i++){
           //StringAdd(m_sql_insert_book,",");
           //StringAdd(m_sql_insert_book,IntegerToString(book[i].type       ) );
           StringAdd(m_sql_insert_book,",");
           StringAdd(m_sql_insert_book,DoubleToString (book[i].price      ) );
           StringAdd(m_sql_insert_book,",");
           StringAdd(m_sql_insert_book,DoubleToString (book[i].volume     ) );
         //StringAdd(m_sql_insert_book,",");
         //StringAdd(m_sql_insert_book,DoubleToString (book[i].volume_real) );

           // calibrando os pesos em funcao da posicao do preco no book...
           pesoAsk = book[0].price - book[i            ].price + tickSize;
           pesoBid = book[i].price - book[tamanhoBook-1].price + tickSize;
           if( book[i].type == BOOK_TYPE_SELL && i > desprezarAsk ){
         //if( i < desprezarBid && book[i].type == BOOK_TYPE_SELL ){
               pesXvolXask += book[i].price*(1/book[i].volume_real)*pesoAsk;// numerador  : soma dos precos x pesos
               pesXvolAsk  +=               (1/book[i].volume_real)*pesoAsk;// denominador: soma dos          pesos
               m_fluxoAsk  += calcFluxoBook(book[i],i,pesoAsk); // calculando o fluxo de ordens no book...
           }else{
               if( book[i].type == BOOK_TYPE_BUY && i < desprezarBid ){
             //if( i > desprezarAsk && book[i].type == BOOK_TYPE_BUY ){
                   pesXvolXbid += book[i].price*(1/book[i].volume_real)*pesoBid;// numerador  : soma dos precos x pesos
                   pesXvolBid  +=               (1/book[i].volume_real)*pesoBid;// denominador: soma dos          pesos
                   m_fluxoBid  += calcFluxoBook(book[i],i,pesoBid); // calculando o fluxo de ordens no book...
               }else{
                   if( i>desprezarAsk && i<desprezarBid ){
                       //Print(":-( ERRO: Nenhum tipo desprezarAsk:",desprezarAsk," desprezarBid:",desprezarBid, " i:", i);
                   }
               }
           }
       }//laco for
       
       StringAdd(m_sql_insert_book,");");
       Print(m_sql_insert_book);
       m_microsecbook_ant = m_microsecbook_atu;
   }


   m_vetFluxAsk.add(  m_fluxoAsk                                      , 1, m_time );
   m_vetFluxBid.add(  m_fluxoBid                                      , 1, m_time );

   m_fluxoBidPorSeg = m_vetFluxBid.getVolPorSeg();
   m_fluxoAskPorSeg = m_vetFluxAsk.getVolPorSeg();
   
   // alterou as variaveis de fluxo de ordens no book m_fluxoXXXPorSeg, entao recalcalculamos a probabilidade do preco subir ou descer em funcao do fluxo.
   calcProbFluxo();
   
   m_vetBookAsk.add(  pesXvolAsk            ==0?0:pesXvolXask/pesXvolAsk                           , 1, m_time );
   m_vetBookBid.add(  pesXvolBid            ==0?0:pesXvolXbid/pesXvolBid                           , 1, m_time );
   m_vetBookTot.add( (pesXvolAsk+pesXvolBid)==0?0:(pesXvolXask+pesXvolXbid)/(pesXvolAsk+pesXvolBid), 1, m_time );

   m_dxAsk = ( m_vetBookAsk.getMedia() - m_vetBookTot.getMedia() );
   m_dxBid = ( m_vetBookTot.getMedia() - m_vetBookBid.getMedia() );

   m_dxAskTrade = ( m_vetBookAsk.getMedia () - m_vetTradeTot.getMedia() );
   m_dxBidTrade = ( m_vetTradeTot.getMedia() - m_vetBookBid.getMedia () );

   // desbalanceamento do book...
   if( tamanhoBook > BOOK_DEEP*2){
       m_meioDoBook = tamanhoBook/2;
       calcPUP(book,m_meioDoBook);
       m_pUP0 = getPUP(0);
       m_pUP1 = getPUP(1);
       m_pUP2 = getPUP(2);
       m_pUP3 = getPUP(3);
       
/*
       m_as3 = book[(m_meioDoBook)-4].volume_real;// volume quarta   fila ask
       m_as2 = book[(m_meioDoBook)-3].volume_real;// volume terceira fila ask
       m_as1 = book[(m_meioDoBook)-2].volume_real;// volume segunda  fila ask
       m_as0 = book[(m_meioDoBook)-1].volume_real;// volume primeira fila ask
       m_bs0 = book[(m_meioDoBook)  ].volume_real;// volume primeira fila bid
       m_bs1 = book[(m_meioDoBook)+1].volume_real;// volume segunda  fila bid
       m_bs2 = book[(m_meioDoBook)+2].volume_real;// volume terceira fila bid
       m_bs3 = book[(m_meioDoBook)+3].volume_real;// volume quarta   fila bid
       //m_pUP0 =  m_bs0                   /(m_bs0+                  m_as0                  );
       //m_pUP1 = (m_bs0+m_bs1            )/(m_bs0+m_bs1+            m_as0+m_as1            );
       //m_pUP2 = (m_bs0+m_bs1+m_bs2      )/(m_bs0+m_bs1+m_bs2+      m_as0+m_as1+m_as2      );
       //m_pUP3 = (m_bs0+m_bs1+m_bs2+m_bs3)/(m_bs0+m_bs1+m_bs2+m_bs3+m_as0+m_as1+m_as2+m_as3);

       m_pUP0 = (m_bs0                                    -m_as0)/(m_bs0+                  m_as0                  );
       m_pUP1 = (m_bs0+m_bs1                        -m_as2-m_as3)/(m_bs0+m_bs1+            m_as0+m_as1            );
       m_pUP2 = (m_bs0+m_bs1+m_bs2            -m_as1-m_as2-m_as3)/(m_bs0+m_bs1+m_bs2+      m_as0+m_as1+m_as2      );
       m_pUP3 = (m_bs0+m_bs1+m_bs2+m_bs3-m_as0-m_as1-m_as2-m_as3)/(m_bs0+m_bs1+m_bs2+m_bs3+m_as0+m_as1+m_as2+m_as3);
*/

   }else{
      if( tamanhoBook > 1 ){
          m_meioDoBook = tamanhoBook/2;
          m_as0 = book[(m_meioDoBook)-1].volume_real;// volume primeira fila ask
          m_bs0 = book[(m_meioDoBook)  ].volume_real;// volume primeira fila bid
          m_pUP0 = m_bs0/(m_bs0+m_as0);
          m_pUP1 = 0;
      }else{ m_pUP0 = 0; m_pUP1 = 0; }
   }
   
   
 //m_pUP0 = m_bs0/(m_bs0+m_as0);
 //m_pDW0 = m_as0/(m_as0+m_bs0);   
 //m_pUP1 = (m_bs0+m_bs1)/(m_bs0+m_bs1+m_as0+m_as1);
 //m_pDW1 = (m_as0+m_as1)/(m_as0+m_as1+m_bs0+m_bs1);
    
}

void osc_estatistic3::calcPUP(MqlBookInfo &book[], const int meioDoBook){
    double askSide = 0;
    double bidSide = 0;
    
    for(int i=0; i<BOOK_DEEP; i++){
        askSide += book[meioDoBook-i-1].volume_real;
        bidSide += book[meioDoBook+i  ].volume_real;
        m_PUP[i] = (bidSide-askSide)/(bidSide+askSide);
    }
}


  //+---------------------------------------------------------------------------------------+
  //| ==================== Calculo de PRECO EM FUNCAO DO VOLUME =====================       |
  //| Faz: - adiciona tick nos vetores de calculo de medias de precos ponderados por volume.|
  //|      - recalcula medias de precos transacoes ponderadas por volume.                   |
  //+---------------------------------------------------------------------------------------+

void osc_estatistic3::acumularTick( MqlTick& tick, bool flag_volume_tick=false ){

     m_totVolTmp =                tick.volume_real   ;
     m_selVolTmp = (isTkSel(tick)?tick.volume_real:0);
     m_buyVolTmp = (isTkBuy(tick)?tick.volume_real:0);

     // opcao para acumular volume de ticks e nao o volume real.
     if( flag_volume_tick ){
         m_totVolTmp =                (double)tick.volume   ;
         m_selVolTmp = (isTkSel(tick)?(double)tick.volume:0);
         m_buyVolTmp = (isTkBuy(tick)?(double)tick.volume:0);
     }

     m_totPriceTmp =                tick.last   ;
     m_selPriceTmp = (isTkSel(tick)?tick.last:0);
     m_buyPriceTmp = (isTkBuy(tick)?tick.last:0);

                         m_vetTradeTot.add(m_totPriceTmp, m_totVolTmp, tick.time);
     if(m_selPriceTmp>0) m_vetTradeSel.add(m_selPriceTmp, m_selVolTmp, tick.time);
     if(m_buyPriceTmp>0) m_vetTradeBuy.add(m_buyPriceTmp, m_buyVolTmp, tick.time);

     m_volTradeSelPorSeg = m_vetTradeSel.getVolPorSeg();//volume de vendas     realizadas por segundo.
     m_volTradeBuyPorSeg = m_vetTradeBuy.getVolPorSeg();//volume de compras    realizadas por segundo.
     m_volTradeTotPorSeg = m_vetTradeTot.getVolPorSeg();//volume de transacoes realizadas por segundo.
     m_volTradeLiqPorSeg = m_volTradeBuyPorSeg-m_volTradeSelPorSeg;//volume de compras menos vendas realizadas por segundo.
     calcProbFluxo(); // alterou as variaveis de fluxo de trades m_volTradeXXXPorSeg, entao recalcalculamos a probabilidade do preco subir ou descer em funcao do fluxo.

     m_dxSel = m_vetTradeTot.getMedia() - m_vetTradeSel.getMedia();
     m_dxBuy = m_vetTradeBuy.getMedia() - m_vetTradeTot.getMedia();

     // atualizando acumuladores de volume...
     m_totVol += m_totVolTmp;
     m_selVol += m_selVolTmp;
     m_buyVol += m_buyVolTmp;
     m_sldVol  = m_buyVol - m_selVol;
}

// spread bid-ask efetivo. calculado segundo Irene Aldridge:
// eh igual a duas vezes a diferença entre o ultimo preco de negociacao e o ponto medio
// entre os preços bid e ask cotados, dividido pelo ponto medio entre os precos bid e ask cotados. 
static double osc_estatistic3::calcSpreadEfetivo(MqlTick& tick){
   return (   ( 2 * ( (tick.last) - ((tick.ask+tick.bid)/2) ) ) / ((tick.ask+tick.bid)/2)   );
}

//---------------------------------------------------------------------------------------------------
// estima o valor da proxima agressao baseado regressao lenear das agressoes contidas na estatistica.
//---------------------------------------------------------------------------------------------------
// parametros:
// -----------
// price out double valor da agressao estimada
// b0    out double coeficiente dependente   b0
// b1    out double coeficiente independente b1 (coeficiente angular)
// r2    out double coefiente de explicacao da regressao
//
// retorna:
// true se estimativa foi ok e false, caso contrario
// 
//---------------------------------------------------------------------------------------------------
//bool osc_estatistic3::estimarProxAgressao(double& price, double& b0, double& b1, double& r2){
//    
//    double priceX[], indY[];
//    int qtd = m_vetTradeTot.copyPriceTo(priceX,indY);
//    string msg;
//    
//    CStat stat;
//    if ( !stat.calcRegLin(priceX,indY,b0,b1,r2,msg) ){
//        Print(msg);
//    }
//    
//    price = b0 + (qtd+1)*b1;
//    
//    return true;
//}
//---------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------
// compilar modelo de regressao linear simples baseado valores das agressoes armazenadas.
//---------------------------------------------------------------------------------------------------
// parametros:
// -----------
// r2    out double coefiente de explicacao da regressao
//
// retorna:
// true se a compilacao foi ok e false, caso contrario
// Apos compilacao com sucesso pode ser usado o metodo regLinPredict que retorna o proximo preco estimado
//---------------------------------------------------------------------------------------------------
bool osc_estatistic3::regLinCompile(double& r2){
    
    double priceY[], indX[];
    m_vetTradeTot.copyPriceTo(priceY,indX);
    
    if ( !m_regLin.compile(priceY, indX, r2) ){
        Print(__FUNCTION__, m_regLin.getMsgErro());
        return false;
    }
    return true;
}
//---------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------
// compilar modelo de regressao linear simples baseado valores das agressoes armazenadas e variaveis 
// independentes que explicariam o valor dos precos.
//---------------------------------------------------------------------------------------------------
// parametros:
// -----------
// vetX  in  double vetor de variaveis independentes (eixo x)
// r2    out double coefiente de explicacao da regressao
//
// retorna:
// true se a compilacao foi ok e false, caso contrario
// Apos compilacao com sucesso pode ser usado o metodo regLinPredict que retorna o proximo preco estimado
//---------------------------------------------------------------------------------------------------
bool osc_estatistic3::regLinCompile(double& vetX[], double& r2){
    
    double priceY[];
    m_vetTradeTot.copyPriceTo(priceY);
    
    if ( !m_regLin.compile(priceY, vetX, r2) ){
        Print(__FUNCTION__, m_regLin.getMsgErro());
        return false;
    }
    return true;
}
//---------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------------
// estimar o proximo preco do ativo baseado na ultima compilacao do modelo de regressao linear simples
//---------------------------------------------------------------------------------------------------
// retorna:
// --------
// o valor estimado do proximo preco do ativo
//---------------------------------------------------------------------------------------------------
double osc_estatistic3::regLinPredict(){    
    return m_regLin.predict( m_vetTradeTot.getLenVet()+1 );
}
//---------------------------------------------------------------------------------------------------
