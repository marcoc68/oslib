﻿//+------------------------------------------------------------------+
//|            eaMinion-09-02-00-dx-bolinguer-e-feira-indefinido.mq5 |
//|                                         Copyright 2019, OS Corp. |
//|                                                http://www.os.org |
//| Opera contra tendencia, no afastamento da media.                 |
//| Esta versao 09, usa bandas de bollinguer como na versao 08.      |
//| Busca zonas de briga entre bulls e bears, a saber:               |
//| - na média das BB                                                |
//| - na banda superior das BB                                       |
//| - na banda inferior das BB                                       |
//| - no vwap do dia                                                 |
//| - no ajuste do dia anterior                                      |
//| - no preço máximo do dia                                         |
//| - no preço mínimo do dia                                         |
//|                                                                  |
//| 1. Operando nas BB                                               |
//|                                                                  |
//| 1.1 Operação no primeiro toque na linha da banda. Após o primeiro toque, a briga perde a força na linha.      |
//| 1.2 Operação seguinte serah no primeiro toque de outra linha da banda.                                        |
//| 1.3 Operações esperam que o preço ultrapasse a linha e em seguida recue.                                      |
//| 1.4 Usam TP curto (15 ptos) e SL alto (150 ptos).                                                             |
//|                                                                                                               |
//| 2.1 Último toque foi na banda inferior, então faz compra pendente na media.                                   |
//| 2.2 Último toque foi na banda superior, então faz venda  pendente na media.                                   |
//| 2.3 Último toque foi na media, então faz compra pendente na banda superior e venda pendente na banda inferior.|
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, OS Corp."
#property link      "http://www.os.org"
#property version   "901.000"

#include <Trade\SymbolInfo.mqh>
#include <Indicators\Trend.mqh> // for class CiMA;

#include <..\Projects\projetcts\os-ea\ClassTrade03.mqh>
#include <..\Projects\projetcts\os-ea\ClassMinion-02-com-estatistica.mqh>
#include <oslib\osc-ind-minion-feira.mqh>
#include <oslib\os-lib.mq5>


  input bool   EA01_DEBUG             = false; // EA01_DEBUG:se true, grava informacoes de debug no log do EA.
  input bool   EA02_ADD_IND_2_CHART   = false; // EA02_ADD_IND_2_CHART:se true, adiciona ind feira ao grafico.
  input double DX1                    = 0.2  ; // DX1:Tamanho do DX em relacao a banda em %;
  input double EA04_DX_TRAILLING_STOP = 1.0  ; // EA04_DX_TRAILLING_STOP:% do DX1 para fazer o para fazer o trailling stop
//input int    DX_MIN                 = 15   ; // DX mínimo para operar.
  input double DX_TP                  = 10   ; // multiplica por DX para determinar o ponto de saida com lucro. Se colocar , o ponto de saida eh a media.
  input double DX_SL                  = 2    ; // multiplica por DX para determinar o ponto de saida com perda.
//input double SPRED_MAXIMO           = 10   ; // Maior Spred permitido;

  //---------------------------------------------------------------------------------------------
  // configurando a feira...
  input string S01                       = ""    ; //==== INDICADOR FEIRA ====
  input bool   FEIRA01_DEBUG             = false ; // se true, grava informacoes de debug no log.
  input bool   FEIRA02_GERAR_VOLUME      = false ; // se true, gera volume baseado nos ticks. Usa em papeis que nao informam volume, tais como o DJ30.
  input bool   FEIRA03_GERAR_OFERTAS     = false ; // se true, gera ofertas baseadas nos ticks. Usa em papeis que nao informam o livro de ofertas.
  input int    FEIRA04_QTD_BAR_PROC_HIST = 10    ; // Quantidade de barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
  input double FEIRA05_BOOK_OUT          = 0.4   ; // Porcentagem das extremidades dos precos do book que serão desprezados.
  input string S02                       = ""    ; //==== INDICADOR FEIRA ====;

  //---------------------------------------------------------------------------------------------
  // configurando as bandas de bollinguer...
  input int    QTD_PERIODO_MA    = 21   ; // Quantidade de periodos usados no calculo da media.
  input double DESVIO_PADRAO     = 2    ; // Desvio padrao.

  // configurando o horario de inicio e fim da operacao...
  input int    HR_INI_OPERACAO   = 09   ; // Hora   de inicio da operacao;
  input int    MI_INI_OPERACAO   = 15   ; // Minuto de inicio da operacao;
  input int    HR_FIM_OPERACAO   = 17   ; // Hora   de fim    da operacao;
  input int    MI_FIM_OPERACAO   = 30   ; // Minuto de fim    da operacao;

  // configurando o comportamento das negociacoes...
  input double VOLUME_LOTE       = 01      ; // Tamanho do lote de negociação;
  input int    MAGIC             = 90200   ; // Numero magico desse EA.
//input double TP                = 20      ; // Take Profit da operacao em pontos.
//input double SL                = 150     ; // Stop Loss da operacao em pontos.
  //---------------------------------------------------------------------------------------------

//int         m_feira; // manipulador do indicador feira
CiBands*    m_bb;
MqlDateTime m_date;
string      m_name       = "MINION-09-02-00";
string      m_estrategia = "DX_BB_PB"       ; // bandas de bolinguer - pontos de briga de precos.
CSymbolInfo m_symb                          ;
double      m_tick_size                     ;// alteracao minima de preco.

ClassTrade03         m_trade;
ClassMinion02        m_minion;
osc_ind_minion_feira m_feira;

int BB_SUPERIOR     =  1;
int BB_INFERIOR     = -1;
int BB_MEDIA        =  0;
int BB_DESCONHECIDA =  2;

int m_ult_toque     = BB_DESCONHECIDA; // indica em que banda foi o ultimo toque do preco.
int m_pri_toque     = BB_DESCONHECIDA; // indica em que banda estah o primeiro toque de preco; A operacao eh aberta no primeiro toque na banda;
int m_ult_oper      = BB_DESCONHECIDA; // indica em que banda foi a ultima operacao;

bool   m_comprado     = false;
bool   m_vendido      = false;
double m_precoPosicao = 0;
double m_tstop        = 0;


//--- variaveis atualizadas pela funcao refreshMe...
double m_med         = 0;//normalizar( m_bb.Base(0)  ); // preco medio das bandas de bollinguer
double m_inf         = 0;//normalizar( m_bb.Lower(0) ); // preco da banda de bollinger inferior
double m_sup         = 0;//normalizar( m_bb.Upper(0) ); // preco da banda de bollinger superior
double m_bdx         = 0;//MathAbs   ( sup-med       ); // distancia entre as bandas de bollinger e a media, sem sinal;
double m_dx1         = 0;//normalizar( DX1*bdx       ); // normalmente 20% da distancia entre a media e uma das bandas.
int    m_qtdOrdens   = 0;
int    m_qtdPosicoes = 0;

void refreshMe(){
   m_symb.RefreshRates();
   m_bb.Refresh(-1);
   m_minion.refresh();
   m_feira.Refresh();

   m_med = normalizar( m_bb.Base(0)  ); // preco medio das bandas de bollinguer
   m_inf = normalizar( m_bb.Lower(0) ); // preco da banda de bollinger inferior
   m_sup = normalizar( m_bb.Upper(0) ); // preco da banda de bollinger superior
   m_bdx = MathAbs   ( m_sup-m_med   ); // distancia entre as bandas de bollinger e a media, sem sinal;
   m_dx1 = normalizar( DX1*m_bdx     ); // normalmente 20% da distancia entre a media e uma das bandas.

   m_qtdOrdens   = OrdersTotal();
   m_qtdPosicoes = PositionsTotal();
}


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()  {

   printf("***** Iniciando " + m_name + ":" + IntegerToString(MAGIC) + " as " + TimeToString( TimeCurrent() ) +"... ******");

   m_symb.Name        ( Symbol() );
   m_symb.Refresh     ();
   m_symb.RefreshRates();
   m_tick_size = m_symb.TickSize(); //Obtem a alteracao minima de preco

   m_trade.setMagic   (MAGIC      );
   m_trade.setVolLote (VOLUME_LOTE);

   // inicializando a banda de bolinguer...
   m_bb = new CiBands();
   if ( !m_bb.Create(_Symbol       , //string           string,        // Symbol
                     PERIOD_CURRENT, //ENUM_TIMEFRAMES  period,        // Period
                     QTD_PERIODO_MA, //int              ma_period,     // Averaging period
                     0             , //int              ma_shift,      // Horizontal shift
                     DESVIO_PADRAO , //double           deviation      // Desvio
                     PRICE_MEDIAN    //int              applied        // (máximo + mínimo)/2 (see ENUM_APPLIED_PRICE)
                     )
      ){
      Print("Erro inicializando o indicador BB.");
      return(1);
   }

   // inicializando a feira...
   if( ! m_feira.Create(  m_symb.Name(),PERIOD_CURRENT           ,
                                        FEIRA01_DEBUG            ,
                                        FEIRA02_GERAR_VOLUME     ,
                                        FEIRA03_GERAR_OFERTAS    ,
                                        FEIRA04_QTD_BAR_PROC_HIST,
                                        FEIRA05_BOOK_OUT         )   ){
          Print("Erro inicializando o indicador FEIRA :-( ", GetLastError() );
          return(1);
   }
   Print("FEIRA inicializada :-)" );

   // adicionando FEIRA ao grafico...
    if( EA02_ADD_IND_2_CHART ){ m_feira.AddToChart(0,0); }

   //int subwindow=(int)ChartGetInteger(0,CHART_WINDOWS_TOTAL);
   //PrintFormat("Adicionado indicador FEIRA na janela do gráfico %d",subwindow);
   //if(!ChartIndicatorAdd(0,0,m_feira)){
   //    Print("Erro adicionando FEIRA ao grafico :-(" );
   //    Print( "m_feira:",m_feira,"  ERRO:",GetLastError() );
   //}else{
   //    Print("FEIRA adicionado ao grafico :-)" );
   //}

   if( EA01_DEBUG ){
      string dt = TimeToString( TimeCurrent(),TIME_DATE|TIME_MINUTES|TIME_SECONDS );
      StringReplace ( dt, ".", ""  );
      StringReplace ( dt, ":", ""  );
      StringReplace ( dt, " ", "_" );

      Print("ATENCAO:Em modo DEBUG! Abrindo LOG...");
      m_minion.setLogFileName("osi-01-03-feira_" + m_symb.Name() + "_" + dt + "_ticks.csv");
   }
   //m_minion.setLogFileName(m_name + ".csv");
   return(0);
}



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
   refreshMe();

// escreverLogAfterNewBar( "ONTICK:"+ IntegerToString(m_pri_toque) + ":" + IntegerToString(m_ult_toque) );
// escreverLog           ( "ONTICK:"+ IntegerToString(m_pri_toque) + ":" + IntegerToString(m_ult_toque) );

   // verifica se estah no intervalo de hora:min em que eh permitimos negociacao segura.
   // Se estiver fora do intervalo, fecha todas as posicoes abertas e nao abre novas posicoes.
   if( !estah_no_intervalo_de_negociacao() ) {

       // se tem posicao aberta fora do horario de negociacao, fecha.
       if( m_qtdPosicoes > 0 ){ fecharPosicao ("INTERVALO"); }

       // se tem ordem aberta fora do horario de negociacao, cancela.
       if( m_qtdOrdens    > 0 ){ cancelarOrdens("INTERVALO"); }

       // quando voltar ao intervalo de negociacao, descobre os toques nas BB novamente a partir do zero.
       inicializarVerificacaoToqueNaBanda();
       return;
   }

// executa estrategias de saida.
   if ( m_qtdPosicoes > 0 ) { doTraillingStop(); return; } // acionando saidas por trailling stop...


// executa estrategias de entrada.
   if( m_qtdOrdens == 0 && m_qtdPosicoes == 0 ){ doEstrategiaNegociarOfertaDemanda(); return; }

   return;
}//+------------------------------------------------------------------+

//+----------------------------------------------------------+
//| comprando e vendendo na feira segundo oferta e demanda...|
//+----------------------------------------------------------+
void doEstrategiaNegociarOfertaDemanda(){

       m_trade.setStopLoss( m_dx1 ); // dx1 normalmente eh 20% da distância entre banda e media.
       m_trade.setTakeProf( 0     ); // dx1 normalmente eh 20% da distância entre banda e media.

       // se a media de demanda estah maior que a de oferta, esperamos que o preco caia, entao venda...
     //if( m_feira.getDemandaMedia() > m_feira.getOfertaMedia()                  ){ vender("TST0"); return; }
     //if( m_feira.getSinalPrecoDw1(0) != 0                                      ) { vender("TST1"); return; }
     //if( m_feira.getSinalPrecoDw1(0) != 0 && m_feira.getSinalPrecoDw2(0)  != 0 ) { vender("TST2"); return; }
       if( m_feira.getSinalPrecoDw1(0) != 0 && m_feira.getSinalDemandaSel(0)!= 0 ) { vender("TST3"); return; }

       // se a media de demanda estah menor que a de oferta, esperamos que o preco suba, entao compre...
       //if( m_feira.getDemandaMedia() < m_feira.getOfertaMedia() ){ comprar("TST"); return; }
      //if( m_feira.getSinalPrecoUp1(0) != 0                                      ) { comprar("TST1"); return; }
     //if( m_feira.getSinalPrecoUp1(0) != 0 && m_feira.getSinalPrecoUp2(0)  != 0 ) { comprar("TST2"); return; }
       if( m_feira.getSinalPrecoUp1(0) != 0 && m_feira.getSinalDemandaBuy(0)!= 0 ) { comprar("TST1"); return; }

       return;
}



//
// comprar e vender nos extremos da BB e aguardar a volta pro centro da BB.
//
void doEstrategiaNegociarNosExtremos(){
   double med = normalizar( m_bb.Base(0)  ); // preco medio das bandas de bollinguer
   double inf = normalizar( m_bb.Lower(0) ); // preco da banda de bollinger inferior
   double sup = normalizar( m_bb.Upper(0) ); // preco da banda de bollinger superior
   double bdx = MathAbs   ( sup-med       ); // distancia entre as bandas de bollinger e a media, sem sinal;
   double dx1 = normalizar( DX1*bdx       ); // normalmente 20% da distancia entre a media e uma das bandas.

   // nao tem ordem nem posicao aberta, entao checamos se eh possivel abrir uma negociacao...
   if( PositionsTotal() == 0 && OrdersTotal() == 0 ){
       m_trade.setStopLoss      ( dx1 ); // normalmente 20% da distância entre banda e media.
       m_trade.setTakeProf      ( dx1 ); // normalmente 20% da distância entre banda e media.

       if( precoNaBandaInferior(dx1) && !m_minion.ehTendenciaDeBaixa(2) ) {

           Print( m_minion.toString() );
           Print( "BINF:LAST:" + DoubleToString( m_minion.last(),2) );
           Print( "BINF:BID :" + DoubleToString( m_minion.bid() ,2) );
           Print( "BINF:ASK :" + DoubleToString( m_minion.ask() ,2) );
           Print( "BINF:BBS :" + DoubleToString( m_bb.Upper(0)  ,2) );
           Print( "BINF:BB0 :" + DoubleToString( m_bb.Base(0)   ,2) );
           Print( "BINF:BBI :" + DoubleToString( m_bb.Lower(0)  ,2) );
           Print( "BINF:BDX :" + DoubleToString( bdx            ,2) );
           Print( "BINF:DX1 :" + DoubleToString( dx1            ,2) );

           comprarLimit ( inf, "BINF");
           return;
       }
       if( precoNaBandaSuperior(dx1) && !m_minion.ehTendenciaDeAlta(2) ){
           Print( m_minion.toString() );
           Print( "BINF:LAST:" + DoubleToString( m_minion.last(),2) );
           Print( "BINF:BID :" + DoubleToString( m_minion.bid() ,2) );
           Print( "BINF:ASK :" + DoubleToString( m_minion.ask() ,2) );
           Print( "BINF:BBS :" + DoubleToString( m_bb.Upper(0)  ,2) );
           Print( "BINF:BB0 :" + DoubleToString( m_bb.Base(0)   ,2) );
           Print( "BINF:BBI :" + DoubleToString( m_bb.Lower(0)  ,2) );
           Print( "BINF:BDX :" + DoubleToString( bdx            ,2) );
           Print( "BINF:DX1 :" + DoubleToString( dx1            ,2) );

           venderLimit  ( sup, "BSUP");
           return;
       }
   }else{

       if( OrdersTotal() != 0 ){
          // tem ordem aberta e tendencia eh desfavoravel, cancelamos.
          if( estouComprado() && m_minion.ehTendenciaDeBaixa(2) ){ m_trade.cancelarOrdens("CANC ORD COMPR - TEND"); return; }
          if( estouVendido () && m_minion.ehTendenciaDeAlta (2) ){ m_trade.cancelarOrdens("CANC ORD VENDA - TEND"); return; }

          // tem ordem aberta, e tendencia eh favoravel, checamos se devemos modifica-la em funcao das alteracoes nas BB...
          if( precoNaBandaInferior(dx1) ){ ajustarPontoEntradaNaBandaInferior(); return; }
          if( precoNaBandaSuperior(dx1) ){ ajustarPontoEntradaNaBandaSuperior(); return; }
       }

       // tem posicao aberta e tendencia eh desfavoravel, fechamos.
       if( PositionsTotal() != 0 ){
          //if( estouComprado() && m_minion.ehTendenciaDeBaixa(2)){ m_trade.fecharPosicao("FECH POS COMPR - TEND"); return; }
          //if( estouVendido () && m_minion.ehTendenciaDeAlta (2)){ m_trade.fecharPosicao("FECH POS VENDA - TEND"); return; }
          //Sleep(1000); // sleep de 1 seg por receio de chegar novamente ao ponto cancelamento de ordens e cnacelar a ordem de
                       // fechamento da posicao.
       }
   }

   return;
}

// verifica se o preco estah na banda superior. Recebe um parametro de distancia da banda e da media visando
// sinalizar quando preco estiver mais interno a banda.
//bool precoNaBandaSuperior(double dx ){ return m_minion.last() > m_bb.Base(0)+dx && m_minion.bid() < m_bb.Upper(0)-dx; }
bool precoNaBandaSuperior(double dx ){ return m_minion.last() > m_bb.Base(0)+dx; }

// verifica se o preco estah na banda inferior. Recebe um parametro de distancia da banda e da media visando
// sinalizar quando preco estiver mais interno a banda.
//bool precoNaBandaInferior(double dx ){ return m_minion.last() < m_bb.Base(0)-dx && m_minion.ask() > m_bb.Lower(0)+dx; }
bool precoNaBandaInferior(double dx ){ return m_minion.last() < m_bb.Base(0)-dx; }

// corrige ordem de entrada na banda superior se necessario
void ajustarPontoEntradaNaBandaSuperior(){
   double sup   = normalizar( m_bb.Upper(0) ); // preco na banda superior

   // ordem ficou fora da bandasuperior, altero a ordem para ficar na banda.
   if( m_trade.getPrice() < sup || m_trade.getPrice() > (sup+m_tick_size) ) {

      //Print("PRECO ATUAL NA BANDA SUPERIOR:", m_minion.last()    );
      //Print("PRECO DA ORDEM               :", m_trade.getPrice() );
      //Print("BB_SUPERIOR                  :", sup                );
      //Print("ALTERANDO PARA SELL_LIMIT A  :", sup                );

      if ( m_trade.alterarOrdem( ORDER_TYPE_SELL_LIMIT, sup ) ) return;
      // falhou a alteracao da ordem, entao deletamos e aguardamos a execucao do proximo ciclo,
      // onde serah aberta nova ordem caso a anterior nao foi ainda executada.
      m_trade.cancelarOrdens("CANCELANDO APOS FALHA NA ALTERACAO.");
   }
}

// corrige ordem de entrada na banda inferior se necessario
void ajustarPontoEntradaNaBandaInferior(){
   double inf = normalizar( m_bb.Lower(0) ); // preco na banda inferior

   // ordem ficou fora da banda inferior, altero a ordem para ficar na banda.
   if( m_trade.getPrice() < (inf-m_tick_size) || m_trade.getPrice() > inf ) {
      //Print("PRECO ATUAL NA BANDA INFERIOR:", m_minion.last()    );
      //Print("PRECO DA ORDEM               :", m_trade.getPrice() );
      //Print("BB_INFERIOR                  :", inf                );
      //Print("ALTERANDO PARA BUY_LIMIT A   :", inf                );

      if( m_trade.alterarOrdem( ORDER_TYPE_BUY_LIMIT, inf ) ) return;
      // falhou a alteracao da ordem, entao deletamos e aguardamos a execucao do proximo ciclo,
      // onde serah aberta nova ordem caso a anterior nao foi ainda executada.
      m_trade.cancelarOrdens("CANCELANDO APOS FALHA NA ALTERACAO.");
   }
}


void doMoverPontoEntradaSeNecessario(){
/*
   string log1;
   double bid   = m_minion.bid()   ;
   double ask   = m_minion.ask()   ;
   double open  = m_minion.open()  ; // preco de abertura da vela atual
   double last  = m_minion.last()  ; // preco da vela atual
   double max   = m_minion.high()  ; // preco maximo da vela atual
   double min   = m_minion.low()   ; // preco minimo da vela atual
   double sup   = m_bb.Upper(0)    ; // preco da banda de bollinger superior
   double inf   = m_bb.Lower(0)    ; // preco da banda de bollinger inferior
   double bdx   = MathAbs(sup-med) ; // distancia entre as bandas de bollinger e a media, sem sinal;
   double pdx   = MathAbs(last-med); // distancia entre o preco e a media, sem sinal;
   double dx1   = normalizar( DX1*bdx );
*/
   double med   = normalizar( m_bb.Base(0) )    ; // preco medio das bandas de bollinguer
   // o preco da ordem ficou maior que o da media, altero a ordem para ficar na media.
// if( m_trade.getPrice() != med ){
   if( m_trade.getPrice() < (med-m_tick_size) || m_trade.getPrice() > (med+m_tick_size) ) {

      //Print("PRECO ULTIMA ORDEM:", m_trade.getPrice() );
      //Print("PRECO MEDIA       :", med                );

       m_trade.alterarPrecoOrdem( med );
   }

/*
   double tp    = normalizar(dx1 * DX_TP) ; // take profit baseado na quantidade de DX1.
   double sl    = normalizar(dx1 * DX_SL) ; // stop loss baseado na quantidade de DX1.

   double dx1sup = med + ( dx1 )   ; // nivel superior mais proximo da media. Habitualmente 20% da distancia da media ate a banda superior;
   double dx1inf = med - ( dx1 )   ; // nivel inferior mais proximo da media. Habitualmente 20% da distancia da media ate a banda inferior;

   double dx3sup  = sup - ( 2*dx1 )   ; // nivel inferior a banda superior;
   double dx3inf  = inf + ( 2*dx1 )   ; // nivel superior a banda inferior;

   double dx4sup  = sup - ( dx1 )   ; // nivel inferior a banda superior;
   double dx4inf  = inf + ( dx1 )   ; // nivel superior a banda inferior;

   double dx5sup  = sup + ( dx1 )   ; // nivel superior externo a banda superior;
   double dx5inf  = inf - ( dx1 )   ; // nivel inferior externo a banda inferior;
*/

//   estou na banda inferior e tem uma ordem sell limit
//   if( m_trade.type == ORDER_TYPE_SELL_LIMIT ) {

//   }
}


// verifica toque do preco em uma das linhas da banda de bollinguer e, caso esteja tocando, salva em que linha ocorreu.
void verificarToqueNaBB(){

   // salvando o ultimo toque...
   int ult_toque_anterior = m_ult_toque;

   // atualizando o ultimo toque...
   if ( precoNaMedia() )        {
        m_ult_toque = BB_MEDIA;
   }else{
          if ( precoNaBandaInferior() ){
               m_ult_toque = BB_INFERIOR;
          }else{
                  if ( precoNaBandaSuperior() ){
                       m_ult_toque = BB_SUPERIOR;
                  }
          }
   }

   // ultimo toque mudou de banda, entao atualizamos o primeiro toque...
   if( m_ult_toque != ult_toque_anterior ) {
       m_pri_toque = m_ult_toque;
   }else{
       m_pri_toque = BB_DESCONHECIDA;
   }

   return;
}

// Zera as variaveis usadas pra checar os ultimos toques nas bandas de bollinguer.
// A partir deste momento, o EA passa a coletar as informacoes necessarias para descobrir os ultimos toques nas BB.
void inicializarVerificacaoToqueNaBanda(){
   m_ult_toque = BB_DESCONHECIDA; // indica em que banda foi o ultimo toque do preco.
   m_pri_toque = BB_DESCONHECIDA; // indica em que banda estah o primeiro toque de preco; A operacao eh aberta no primeiro toque na banda;
   m_ult_oper  = BB_DESCONHECIDA; // indica em que banda foi a ultima operacao;
}


bool doTraillingStop(){

   //double med   = m_bb.Base(0)         ; // preco medio das bandas de bollinguer
   //double sup   = m_bb.Upper(0)        ; // preco da banda de bollinger superior
   //double bdx   = MathAbs(sup-med)     ; // distancia entre as bandas de bollinger e a media, sem sinal;
   //double dx    = normalizar( DX1*bdx ); // tamanho do dx em pontos normalizados;
   double last  = m_minion.last()      ; // preco do ultimo tick;

   double dxsl  = m_dx1 * EA04_DX_TRAILLING_STOP;
   double   sl  = 0;
   string m_line_tstop = "linha_stoploss";

   // calculando o trailling stop...
   if( estouComprado() ){
      sl = last - dxsl;
      if ( m_tstop < sl || m_tstop == 0 ) {
           m_tstop = sl;
           if( !HLineMove(0,m_line_tstop,m_tstop) ){ HLineCreate(0,m_line_tstop,0,m_tstop,clrBlack,STYLE_SOLID,1,false,true,false,0);}
           ChartRedraw(0);
      }
   }else{
      if( estouVendido() ){
         sl = last + dxsl;
         if ( m_tstop > sl || m_tstop == 0 ) {
              m_tstop = sl;
              if( !HLineMove(0,m_line_tstop,m_tstop) ){ HLineCreate(0,m_line_tstop,0,m_tstop,clrBlack,STYLE_SOLID,1,false,true,false,0);}
              ChartRedraw(0);
         }
      }
   }


   //if(!HlineMove(0,m_line_tstop,m_tstop){ HLineCreate(0,m_line_tstop,0,m_tstop,clrBlack,STYLE_SOLID,1,false,true,false,0);}
   //if ( !ObjectMove(0,"linha_stoploss",0,0,m_tstop) ){
   //    ObjectCreate(0,"linha_stoploss",OBJ_HLINE,0,0,m_tstop);
   //    ObjectSetInteger(0,"linha_stoploss",OBJPROP_COLOR,clrYellow);
   //}

   // acionando o trailling stop...
   if( estouComprado() && last < m_tstop && m_tstop != 0 && last > m_precoPosicao ){
       Print("TSTOP COMPRADO: last:"+DoubleToString(last,2)+" m_tstop:"+DoubleToString(m_tstop,2) );
       fecharPosicao("TRLSTP");

       //ObjectDelete(0,"linha_stoploss");
       HLineDelete(0,m_line_tstop);
       ChartRedraw(0);

       return true;
   }
   if( estouVendido()  && last > m_tstop && m_tstop != 0 && last < m_precoPosicao ){
       Print("TSTOP VENDIDO: last:"+DoubleToString(last,2)+" m_tstop:"+DoubleToString(m_tstop,2) );
       fecharPosicao("TRLSTP");

       //ObjectDelete(0,"linha_stoploss");
       HLineDelete(0,m_line_tstop);
       ChartRedraw(0);

       return true;
   }
   return false;
}

/*
//-----------------------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ALTA abaixo da media (indo contra-tendencia)
//
// preco buscando a media...
// comprando na continuacao da alta, se preco abaixo do dx1 inferior
////
// preco na banda do canal, vai iniciar a busca da media...
// comprando na reversao de baixa  , se preco abaixo do dx4 inferior interno
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// BAIXA acima da media (indo contra-tendencia)
//
// preco buscando a media...
// vendendo na continuacao da baixa, se preco acima do dx1 mais proximo da media
//
// preco na banda do canal, vai iniciar a busca da media...
// comprando na reversao de alta  , se preco acima do dx4 interno mais proximo da banda superior
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// SL     : <TODO> Ver.
// TP     : <TODO> Ver.
//-----------------------------------------------------------------------------------------
void doEstrategiaDistanciaDaMedia(){

   string log1;
   double bid   = m_minion.bid()   ;
   double ask   = m_minion.ask()   ;
   double open  = m_minion.open()  ; // preco de abertura da vela atual
   double last  = m_minion.last()  ; // preco da vela atual
   double max   = m_minion.high()  ; // preco maximo da vela atual
   double min   = m_minion.low()   ; // preco minimo da vela atual
   double med   = m_bb.Base(0)     ; // preco medio das bandas de bollinguer
   double sup   = m_bb.Upper(0)    ; // preco da banda de bollinger superior
   double inf   = m_bb.Lower(0)    ; // preco da banda de bollinger inferior
   double bdx   = MathAbs(sup-med) ; // distancia entre as bandas de bollinger e a media, sem sinal;
   double pdx   = MathAbs(last-med); // distancia entre o preco e a media, sem sinal;
   double dx1   = normalizar( DX1*bdx );

   //dx1 curto causa muita operacao errada.
//   if (dx1 < DX_MIN){return;}

   // nao operar se distancia entre ultima negociacao em oferta estiver muito alta;
// if( MathAbs(last-bid ) > SPRED_MAXIMO ||
//     MathAbs(ask -last) > SPRED_MAXIMO ){ return; }
//   if(        (last-bid ) > SPRED_MAXIMO ||
//              (ask -last) > SPRED_MAXIMO ){ return; }

   double tp    = normalizar(dx1 * DX_TP) ; // take profit baseado na quantidade de DX1.
   double sl    = normalizar(dx1 * DX_SL) ; // stop loss baseado na quantidade de DX1.

   double dx1sup = med + ( dx1 )   ; // nivel superior mais proximo da media. Habitualmente 20% da distancia da media ate a banda superior;
   double dx1inf = med - ( dx1 )   ; // nivel inferior mais proximo da media. Habitualmente 20% da distancia da media ate a banda inferior;

   double dx3sup  = sup - ( 2*dx1 )   ; // nivel inferior a banda superior;
   double dx3inf  = inf + ( 2*dx1 )   ; // nivel superior a banda inferior;

   double dx4sup  = sup - ( dx1 )   ; // nivel inferior a banda superior;
   double dx4inf  = inf + ( dx1 )   ; // nivel superior a banda inferior;

   double dx5sup  = sup + ( dx1 )   ; // nivel superior externo a banda superior;
   double dx5inf  = inf - ( dx1 )   ; // nivel inferior externo a banda inferior;

//   m_trade.setStopLoss(sl);
//   m_trade.setTakeProf(tp);
   log1 = log1 +
                "ASK:"    + DoubleToString(m_minion.ask(),0) +
                " BID:"   + DoubleToString(m_minion.bid(),0) +
                " DX4I:"  + DoubleToString(dx4inf,2 ) +
                " DX4S:"  + DoubleToString(dx4sup,2 ) +
                " MED:"   + DoubleToString(med,0 ) +
                " LAST:"  + DoubleToString(last,0) +
                " BSUP:"  + DoubleToString(sup,1 ) +
                " BINF:"  + DoubleToString(inf,1 ) +
                " BDX:"   + DoubleToString(bdx,1 ) +
                " DX1:"   + DoubleToString(dx1,0 ) +
                " PDX:"   + DoubleToString(pdx,1 ) +
                " TP:"    + DoubleToString(tp,0  ) +
                " SL:"    + DoubleToString(sl,0  ) +
                " OPEN:"  + DoubleToString(open,0) +
                " MAX:"   + DoubleToString(max,0 ) +
                " MIN:"   + DoubleToString(min,0 ) ;

   m_trade.setStopLoss(SL);
   m_trade.setTakeProf(TP);
//   if( m_pri_toque == BB_INFERIOR ){ comprarPendente("BBI:" + log1); return;}
//   if( m_pri_toque == BB_SUPERIOR ){ venderPendente ("BBS:" + log1); return;}

   if( m_ult_toque == BB_INFERIOR ){ venderLimit ( normalizar(med), "BI2M:" + log1); return; }
   if( m_ult_toque == BB_SUPERIOR ){ comprarLimit( normalizar(med), "BS2M:" + log1); return; }
   return;
}
*/

double normalizar(double preco){  return m_symb.NormalizePrice(preco); }


//bool precoPosicaoNaMedia() { return m_precoPosicao < m_bb.Base(0) + m_tick_size &&
//                                    m_precoPosicao > m_bb.Base(0) - m_tick_size   ;}

bool precoPosicaoAbaixoDaMedia() { return m_precoPosicao < m_bb.Base(0) ;}
bool precoPosicaoAcimaDaMedia () { return m_precoPosicao > m_bb.Base(0) ;}

bool precoNaMedia             () { return m_minion.last() < m_bb.Base(0) + m_tick_size &&
                                          m_minion.last() > m_bb.Base(0) - m_tick_size    ;}

bool precoNaBandaInferior     (){ return m_minion.ask() < m_bb.Lower(0) + m_tick_size &&
                                         m_minion.ask() > m_bb.Lower(0) - m_tick_size    ;}

bool precoAbaixoBandaInferior (){ return m_minion.ask() < m_bb.Lower(0) + m_tick_size;}

bool precoNaBandaSuperior     (){ return m_minion.bid() < m_bb.Upper(0) + m_tick_size &&
                                         m_minion.bid() > m_bb.Upper(0) - m_tick_size    ;}

bool precoAcimaBandaSuperior  (){ return m_minion.bid() > m_bb.Upper(0) - m_tick_size;}

//bool precoNaBandaSuperior() { return ( m_minion.bid() < dx4bsupExterno && m_minion.bid() > dx4bsupInterno );}
//bool precoNaBandaInferior() { return ( m_minion.ask() > dx4binfExterno && m_minion.ask() < dx4binfInterno );}

//void comprar(string comentario){ m_trade.comprar(m_minion.getTick(), comentario ); setComprado(); }
//void vender (string comentario){ m_trade.vender (m_minion.getTick(), comentario ); setVendido (); }

void comprar(string comentario){ escreverLog("COMPR"); m_trade.comprar(m_minion.getTick(), comentario ); setComprado(); }
void vender (string comentario){ escreverLog("VENDA"); m_trade.vender (m_minion.getTick(), comentario ); setVendido (); }

void comprarStop(int offset){ escreverLog("COMST"); m_trade.comprarStop( offset,status() ); setComprado(); }
void venderStop (int offset){ escreverLog("VENST"); m_trade.venderStop ( offset,status() ); setVendido (); }

void comprarLimit(double valor, string obs){ escreverLog("COMLM"); m_trade.comprarLimit( valor,status() ); setComprado(); }
void venderLimit (double valor, string obs){ escreverLog("VENLM"); m_trade.venderLimit ( valor,status() ); setVendido (); }

void fecharPosicao (string comentario){ m_trade.fecharPosicao (comentario); setSemPosicao(); }
void cancelarOrdens(string comentario){ m_trade.cancelarOrdens(comentario); setSemPosicao(); }

void setComprado()   { m_comprado = true ; m_vendido = false; m_precoPosicao = m_minion.ask(); m_tstop = 0;}
void setVendido()    { m_comprado = false; m_vendido = true ; m_precoPosicao = m_minion.bid(); m_tstop = 0;}
void setSemPosicao() { m_comprado = false; m_vendido = false; m_precoPosicao = 0             ; m_tstop = 0;}

bool estouComprado(){ return m_comprado; }
bool estouVendido (){ return m_vendido ; }

string status(){
   string obs =
         m_estrategia
         +
         //" preco="       + m_tick.ask                         +
         //" bid="         + m_tick.bid                         +
         //" spread="      + (m_tick.ask-m_tick.bid)            +
           " last="        + DoubleToString( m_minion.last() )
         //" time="        + m_tick.time
         ;
   return obs;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)  {
   EventKillTimer();
   //ChartIndicatorDelete(0,0,"osi-01-03-feira");
   m_feira.DeleteFromChart(0,0);
   IndicatorRelease(m_feira.Handle() );
   return;
}

//+----------------------------------------------------------------------------+
//| Restricao de horario de operacao no dia e inicio e fim da barra de minuto  |
//+----------------------------------------------------------------------------+
bool estah_no_intervalo_de_negociacao(){
   TimeToStruct(TimeCurrent(),m_date);
 //TimeToStruct(TimeLocal(),m_date);

   // restricao para nao operar no inicio nem no final do dia...
   if(m_date.hour <   HR_INI_OPERACAO     ) {  return false; } // operacao antes de 9:00 distorce os testes.
   if(m_date.hour >=  HR_FIM_OPERACAO + 1 ) {  return false; } // operacao apos    18:00 distorce os testes.

   if(m_date.hour == HR_INI_OPERACAO && m_date.min < MI_INI_OPERACAO ) { return false; } // operacao antes de 9:10 distorce os testes.
   if(m_date.hour == HR_FIM_OPERACAO && m_date.min > MI_FIM_OPERACAO ) { return false; } // operacao apos    17:50 distorce os testes.

   return true;
}

void escreverLogAfterNewBar(string msg){
   MqlDateTime mdt;
   TimeToStruct(TimeCurrent(),mdt);
   //if(estah_no_intervalo_de_negociacao()) { m_minion.logWriteAfterNewBar(msg); }
}

void escreverLog(string msg){
   MqlDateTime mdt;
   TimeToStruct(TimeCurrent(),mdt);
   //if(estah_no_intervalo_de_negociacao()) { m_minion.logWrite(msg); }
}

//+-----------------------------------------------------------+
//| Lucro da ultima transacao                                 |
//+-----------------------------------------------------------+
//void OnTradeTransaction() {
//   printf("ACCOUNT_BALANCE =  %G",AccountInfoDouble(ACCOUNT_BALANCE));
//   printf("ACCOUNT_CREDIT  =  %G",AccountInfoDouble(ACCOUNT_CREDIT));
//   printf("ACCOUNT_PROFIT  =  %G",AccountInfoDouble(ACCOUNT_PROFIT));
//   printf("ACCOUNT_EQUITY  =  %G",AccountInfoDouble(ACCOUNT_EQUITY));
//}

void OnTrade() {
   printf("ACCOUNT_BALANCE        = %G",AccountInfoDouble(ACCOUNT_BALANCE));
//   printf("ACCOUNT_CREDIT         = %G",AccountInfoDouble(ACCOUNT_CREDIT));
   printf("ACCOUNT_PROFIT         = %G",AccountInfoDouble(ACCOUNT_PROFIT));
   printf("ACCOUNT_EQUITY         = %G",AccountInfoDouble(ACCOUNT_EQUITY));
//   printf("ACCOUNT_MARGIN         = %G",AccountInfoDouble(ACCOUNT_MARGIN));
//   printf("ACCOUNT_MARGIN_FREE    = %G",AccountInfoDouble(ACCOUNT_MARGIN_FREE));
}
