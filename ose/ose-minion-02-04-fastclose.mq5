﻿//+------------------------------------------------------------------+
//|            eaMinion-09-02-00-dx-bolinguer-e-feira-indefinido.mq5 |
//|                                         Copyright 2019, OS Corp. |
//|                                                http://www.os.org |
//|                                                                  |
//| Tem o mesmo algoritmo fastclose da versao 2.3 com as melhorias:  |
//| 1. Corrige BUG qua duplicava as saidas fastclose.                |
//| 2. Coloca stop loss na posicao aberta, caso nao tenha.           |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, OS Corp."
#property link      "http://www.os.org"
#property version   "901.000"

#include <Trade\SymbolInfo.mqh>
#include <Indicators\Trend.mqh> // for class CiMA;

#include <..\Projects\projetcts\os-ea\ClassMinion-02-com-estatistica.mqh>
#include <oslib\osc\osc-minion-trade-03.mqh>
#include <oslib\osc-ind-minion-feira.mqh>
#include <oslib\os-lib.mq5>


input string S01                    = ""      ; //==== PARAMETROS GERAIS ====
input int    EA02_TICKS_FAST_CLOSE  = 4       ; // Quantidade de ticks usados no fast_close;
input double EA03_DX1               = 0.2     ; // EA03_DX1:Tamanho do DX em relacao a banda em %;
input double EA04_DX_TRAILLING_STOP = 1.0     ; // EA04_DX_TRAILLING_STOP:% do DX1 para fazer o para fazer o trailling stop
input double EA05_VOLUME_LOTE       = 1       ; // Tamanho do lote de negociação. Se zero, usa o lote minimo do simbolo.
input int    EA07_TICKS_STOP_LOSS   = 16       ; // Quantidade de ticks usados no stop loss;
input int    EA06_MAGIC             = 20191005; // Numero magico desse EA.
input bool   EA01_DEBUG             = false   ; // EA01_DEBUG:se true, grava informacoes de debug no log do EA.
//---------------------------------------------------------------------------------------------
//  input double SPRED_MAXIMO      = 10 ; // Maior Spred permitido;
//  input int    DX_MIN            = 15 ; // DX mínimo para operar.
//---------------------------------------------------------------------------------------------
// configurando as bandas de bollinguer...
input string S07               = ""; //==== BANDAS DE BOLLINGUER ====
input int    BB_QTD_PERIODO_MA = 21; // Quantidade de periodos usados no calculo da media.
input double BB_DESVIO_PADRAO  = 2 ; // Desvio padrao.
//---------------------------------------------------------------------------------------------
// configurando a feira...
input string S03                       = ""    ; //==== INDICADOR FEIRA ====
input bool   FEIRA01_DEBUG             = false ; // se true, grava informacoes de debug no log.
input bool   FEIRA02_GERAR_VOLUME      = false ; // se true, gera volume baseado nos ticks. Usa em papeis que nao informam volume, tais como o DJ30.
input bool   FEIRA03_GERAR_OFERTAS     = false ; // se true, gera ofertas baseadas nos ticks. Usa em papeis que nao informam o livro de ofertas.
input int    FEIRA04_QTD_BAR_PROC_HIST = 0     ; // Qtd barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
input double FEIRA05_BOOK_OUT          = 0     ; // Porcentagem das extremidades dos precos do book que serão desprezados.
input int    FEIRA06_QTD_PERIODOS      = 2     ; // Quantidade de barras que serao acumulads para calcular as medias.
input bool   FEIRA99_ADD_IND_2_CHART   = true  ; // Se true apresenta o idicador feira no grafico.
input string S04                       = ""    ; //==== FIM PARAM INDICADOR FEIRA ====;
//---------------------------------------------------------------------------------------------
// configurando o horario de inicio e fim da operacao...
input string S09               = ""; //==== HORARIO DE OPERACAO ====
input int    HR_INI_OPERACAO   = 09; // Hora   de inicio da operacao;
input int    MI_INI_OPERACAO   = 05; // Minuto de inicio da operacao;
input int    HR_FIM_OPERACAO   = 17; // Hora   de fim    da operacao;
input int    MI_FIM_OPERACAO   = 30; // Minuto de fim    da operacao;

CiBands*    m_bb;
MqlDateTime m_date;
string      m_name       = "MINION-02-04-FC";
CSymbolInfo m_symb                          ;
double      m_tick_size                     ;// alteracao minima de preco.
double      m_shift                         ;// valor do fastclose;
double      m_stopLoss                      ;// stop loss;

osc_minion_trade     m_trade;
osc_ind_minion_feira m_feira;
//ClassMinion02      m_minion;

int BB_SUPERIOR     =  1;
int BB_INFERIOR     = -1;
int BB_MEDIA        =  0;
int BB_DESCONHECIDA =  2;

int m_ult_toque     = BB_DESCONHECIDA; // indica em que banda foi o ultimo toque do preco.
int m_pri_toque     = BB_DESCONHECIDA; // indica em que banda estah o primeiro toque de preco; A operacao eh aberta no primeiro toque na banda;
int m_ult_oper      = BB_DESCONHECIDA; // indica em que banda foi a ultima operacao;

bool   m_comprado      = false;
bool   m_vendido       = false;
double m_precoPosicao  = 0;
double m_volumePosicao = 0;    // volume da posicao atual
double m_tstop         = 0;

//--- variaveis atualizadas pela funcao refreshMe...
double m_med           = 0;//normalizar( m_bb.Base(0)  ); // preco medio das bandas de bollinguer
double m_inf           = 0;//normalizar( m_bb.Lower(0) ); // preco da banda de bollinger inferior
double m_sup          = 0;//normalizar( m_bb.Upper(0) ); // preco da banda de bollinger superior
double m_bdx          = 0;//MathAbs   ( sup-med       ); // distancia entre as bandas de bollinger e a media, sem sinal;
double m_dx1          = 0;//normalizar( DX1*bdx       ); // normalmente 20% da distancia entre a media e uma das bandas.
int    m_qtdOrdens    = 0;
int    m_qtdPosicoes  = 0;
double m_posicaoProfit = 0;
int    m_min_ult_trade = 0;
MqlRates m_rates[1];


void refreshMe(){
    m_symb.RefreshRates();
    m_bb.Refresh(-1);
    //m_feira.Refresh();
    CopyRates(m_symb.Name(),_Period,0,1,m_rates);

    m_med = normalizar( m_bb.Base(0)  ); // preco medio das bandas de bollinguer
    m_inf = normalizar( m_bb.Lower(0) ); // preco da banda de bollinger inferior
    m_sup = normalizar( m_bb.Upper(0) ); // preco da banda de bollinger superior
    m_bdx = MathAbs   ( m_sup-m_med   ); // distancia entre as bandas de bollinger e a media, sem sinal;
    m_dx1 = normalizar( EA03_DX1*m_bdx); // normalmente 20% da distancia entre a media e uma das bandas.

    m_qtdOrdens   = OrdersTotal();
    m_qtdPosicoes = PositionsTotal();

    // adminstrando posicao aberta...
    if( m_qtdPosicoes > 0 ){
        m_posicaoProfit = 0;
        if ( PositionSelect(m_symb.Name()) ){ // soh funciona em contas hedge
            if( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                setCompradoSoft();
            }else{
                setVendidoSoft();
            }
            m_posicaoProfit = PositionGetDouble(POSITION_PROFIT    );
            m_precoPosicao  = PositionGetDouble(POSITION_PRICE_OPEN);
            m_volumePosicao = PositionGetDouble(POSITION_VOLUME    );
        }
    }
}


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()  {

    printf("***** Iniciando " + m_name + ":" + IntegerToString(EA06_MAGIC) + " as " + TimeToString( TimeCurrent() ) +"... ******");

    m_symb.Name                  ( Symbol() );
    m_symb.Refresh               (); // propriedades do simbolo. Basta executar uma vez.
    m_symb.RefreshRates          (); // valores do tick. execute uma vez por tick.
    m_tick_size = m_symb.TickSize(); //Obtem a alteracao minima de preco
    m_shift     = m_symb.NormalizePrice(EA02_TICKS_FAST_CLOSE*m_tick_size);
    m_stopLoss  = m_symb.NormalizePrice(EA07_TICKS_STOP_LOSS *m_tick_size);
    m_trade.setMagic   (EA06_MAGIC);
    m_trade.setStopLoss(m_stopLoss);
    m_trade.setTakeProf(0);

    double lotes = EA05_VOLUME_LOTE < m_symb.LotsMin()? m_symb.LotsMin():
                   EA05_VOLUME_LOTE > m_symb.LotsMax()? m_symb.LotsMax():
                   EA05_VOLUME_LOTE;
    m_trade.setVolLote (lotes);

    // inicializando a banda de bolinguer...
    m_bb = new CiBands();
    if ( !m_bb.Create(_Symbol         , //string           string,        // Symbol
                     PERIOD_CURRENT   , //ENUM_TIMEFRAMES  period,        // Period
                     BB_QTD_PERIODO_MA, //int              ma_period,     // Averaging period
                     0                , //int              ma_shift,      // Horizontal shift
                     BB_DESVIO_PADRAO , //double           deviation      // Desvio
                     PRICE_MEDIAN       //int              applied        // (máximo + mínimo)/2 (see ENUM_APPLIED_PRICE)
                     )
        ){
        Print(m_name,": Erro inicializando o indicador BB :-(");
        return(1);
    }

    /*
    // inicializando a feira...
    if( ! m_feira.Create(  m_symb.Name(),PERIOD_CURRENT           ,
                                         FEIRA01_DEBUG            ,
                                         FEIRA02_GERAR_VOLUME     ,
                                         false                    , // nao se usa, FEIRA03_GERAR_OFERTAS,
                                         FEIRA04_QTD_BAR_PROC_HIST,
                                         FEIRA05_BOOK_OUT         ,
                                         FEIRA06_QTD_PERIODOS     ,
                                         IFEIRA_VERSAO_0202       )   ){
        Print(m_name,": Erro inicializando o indicador FEIRA :-( ", GetLastError() );
        return(1);
    }
*/
    Print(m_name,": Expert ", m_name, " inicializado :-)" );

    // adicionando FEIRA ao grafico...
    //if( FEIRA99_ADD_IND_2_CHART ){ m_feira.AddToChart(0,0); }

    return(0);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
    refreshMe();

    // executa estrategias de saida.
    //if ( m_qtdPosicoes > 0 ) { doTraillingStop(); return;               } // acionando saidas por trailling stop...
    //if ( m_qtdPosicoes > 0 ) { doFastClose(EA02_TICKS_FAST_CLOSE*m_tick_size ); } // acionando saida rapida...


    m_trade.setStopLoss( m_stopLoss        );
    m_trade.setVolLote ( m_symb.LotsMin()  );
  //m_trade.setVolLote(VOLUME_LOTE);


    if ( m_qtdPosicoes > 0 ) {
         doFastClose(m_shift); // acionando saida rapida...
    }else{
         if( !estah_no_intervalo_de_negociacao() ) {

             // se tem posicao ou ordem aberta, fecha.
             if( m_qtdPosicoes > 0 ){ fecharPosicao ("INTERVALO"); }
             Sleep(2000);
             if( m_qtdOrdens   > 0 ){ cancelarOrdens("INTERVALO"); }

             return;
         }else{
         
             // se tiver ordens fastclose sem posicao aberta, fecha elas...
             m_trade.cancelarOrdensComentadas("FASTCLOSE");
             
             // se tiver ordem sem stop, coloca agora...
             m_trade.colocarStopEmTodasAsOrdens(m_stopLoss);
         }
      //abrirPosicaoNasMediasDoBook() ;              // abre posicao nas medias do book
      //abrirOrdemAlternadaPorMinuto();              // gerador de negociacoes pra testar o fastclose
      //abrirOrdemNoCloseDaBarraContraTendencia();   // tentativa de EA
      //abrirOrdemNoCloseDaBarraNaTendencia();       // tentativa de EA
      //abrirOrdemNoExtremoDaBarraContraTendencia(); // tentativa de EA
      //abrirOrdemNoPrecoAtualContraTendencia();     // tentativa de EA
      //abrirOrdemNoPrecoAtualNaTendencia();         // tentativa de EA
        return;
    }

    return;
}//+------------------------------------------------------------------+

// Abre ordem limitada no sentido contrario a posicao, visando fecha-la...
bool doFastClose(double shift){

   //m_symb.Refresh();
   //m_bb.Refresh(-1);

   double last = m_symb.Last();// m_minion.last(); // preco do ultimo tick;
   double bid  = m_symb.Bid ();
   double ask  = m_symb.Ask ();
   double precoOrdem = m_precoPosicao;
   
   // se tiver ordem sem stop, coloca agora...
   m_trade.colocarStopEmTodasAsOrdens(m_stopLoss);

   if( m_trade.estouComprado(m_symb.Name()) ){

       // definindo o preco do disparo...
       precoOrdem = m_symb.NormalizePrice(m_precoPosicao+shift); // tentando vender mais caro...
       if(bid>precoOrdem) precoOrdem = bid;

       // verificando se jah tem ordem aberta de venda e fechando outras ordens fastclose abertas...
       if( m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), "FASTCLOSE", m_trade.getPositionVolume(), true, 0 ) ){ return true; }

       // Abrindo a ordem FASTCLOSE de venda...
       Print("Posicao comprado a ",m_precoPosicao,": Abrindo ordem de limitada de venda a:",precoOrdem," ... ");
       return m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, m_trade.getPositionVolume(), "FASTCLOSE");
   }else{
      if( m_trade.estouVendido(m_symb.Name()) ){

          // definindo o preco do disparo...
          precoOrdem = m_symb.NormalizePrice(m_precoPosicao-shift); // tentando comprar mais barato...
          if(ask<precoOrdem) precoOrdem = ask;

          // verificando se jah tem ordem aberta de compra e fechando outras ordens fastclose abertas...
          if( m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), "FASTCLOSE", m_trade.getPositionVolume(), true, 0 ) ){ return true; }

          // Abrindo a ordem FASTCLOSE de compra...
          Print("Posicao vendido a ",m_precoPosicao,": Abrindo ordem de limitada de compra a:",precoOrdem," ... ");
          return m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT,precoOrdem, m_trade.getPositionVolume(), "FASTCLOSE");
      }
   }
   
   return true;
}

// compra abaixo da media de ofertas de venda e
// vende acima   da media de ofertas de compra
void abrirPosicaoNasMediasDoBook(){

   //double open  = m_rates[0].open ;
   //double close = m_rates[0].close;
   //double low   = m_rates[0].low  ;
   //double high  = m_rates[0].high ;
   //double preco = m_symb.Last();
   double ask        = m_symb.Ask();
   double bid        = m_symb.Bid();
   string name       = "APMB"; //Abre Posicao nas Medias do Book.
   double vol        = EA05_VOLUME_LOTE;
   double precoOrdem = 0;

   //double pmBid = m_symb.NormalizePrice( m_feira.getPrecoMedioBid(0)+30 );
   //double pmAsk = m_symb.NormalizePrice( m_feira.getPrecoMedioAsk(0)+30 );

   double pmBid = m_symb.NormalizePrice( m_feira.getPrecoMedioSel(0)-36 );
   double pmAsk = m_symb.NormalizePrice( m_feira.getPrecoMedioBuy(0)+36 );


   //Print( "MPBID0:",m_feira.getPrecoMedioBid(0));
   //Print( "MPASK0:",m_feira.getPrecoMedioAsk(0));
   //Print( "MPBID1:",m_feira.getPrecoMedioBid(1));
   //Print( "MPASK1:",m_feira.getPrecoMedioAsk(1)); 
   //Print( "MPBID2:",pmBid);

   //preco das ofertas de compra abaixo da media de ofertas de venda...
   if( bid < pmAsk+5 ){

     //mantemos uma ordem limitada de venda na media das ofertas de venda...
       precoOrdem = pmAsk;

       //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
       if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), name, vol , true, 5 ) ){
            m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, name); //abrindo a ordem...
       }
   //preco das ofertas de compra acima da media de ofertas de venda...
   }else{
        //mantemos uma ordem limitada de venda 1 dx acima da oferta de compra...
          precoOrdem = bid + m_dx1;
       
       //verificando se tem ordens sell abertas (usando 1 dx de tolerância)...
       if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), name, vol , true, m_dx1 ) ){
            m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, name); //abrindo a ordem...
       }
   }

   //preco das ofertas de venda(ask) acima da media de ofertas de compra(pmBid)...
   if( ask > pmBid-5 ){

       // mantemos uma ordem limitada de compra na media das ofertas de compra...
       precoOrdem = pmBid;
       
       //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
       if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), name, vol , true, 5 ) ){           
            m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, vol, name); //abrindo a ordem...
       }
   //preco ofertas de venda(ask) abaixo da media de ofertas de compra(pmBid)...
   }else{
       // mantemos uma ordem limitada de compra 1 dx abaixo da oferta de venda...
       precoOrdem = ask - m_dx1;

       //verificando se tem ordens buy abertas (usando 1 dx de tolerância)...
       if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), name, vol , true, m_dx1 ) ){
           //abrindo a ordem...
           m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, vol, name);
       }
   }
}

// Mantem uma ordem limitada de compra no high da barra e uma ordem limitada de venda no
// low inferior da barra...
void abrirOrdemNoExtremoDaBarraContraTendencia(){

   double open  = m_rates[0].open ;
   double close = m_rates[0].close;
   double low   = m_rates[0].low  ;
   double high  = m_rates[0].high ;

   if( estah_no_intervalo_de_negociacao() && passouUmMinutoDesdeUltimoTrade() ){

       // barra de alta...
       if( open < close ){

          if( !m_trade.tenhoOrdemLimitadaDeVenda( high,"OPENORDERS") &&
               m_symb.Bid() <= high                                    ){
                   Print("MIN:",m_date.min, ":Vendendo...");
                   m_trade.venderLimit( high,"GERADORFASTCLOSE" );
          }
       }else{
          // barra de baixa...
          if( open > close ){
             if( !m_trade.tenhoOrdemLimitadaDeCompra( low,"OPENORDERS") &&
                  m_symb.Ask() >= low                                      ){
                      Print("MIN:",m_date.min, ":Vendendo...");
                      m_trade.comprarLimit( low,"GERADORFASTCLOSE" );
             }
          }
       }
   }
}


// Mantem uma ordem limitada de compra no close superior da barra e uma ordem limitada de venda no
// close inferior da barra...
void abrirOrdemNoCloseDaBarraContraTendencia(){

   double open  = m_rates[0].open ;
   double close = m_rates[0].close;
   double low   = m_rates[0].low  ;
   double high  = m_rates[0].high ;

   if( estah_no_intervalo_de_negociacao() && passouUmMinutoDesdeUltimoTrade() ){

       // barra de alta...
       if( open < close ){

          if( !m_trade.tenhoOrdemLimitadaDeVenda( close,"OPENORDERS") &&
               m_symb.Bid() <= close                                    ){
               Print("MIN:",m_date.min, ":Vendendo...");
               m_trade.venderLimit( close,"GERADORFASTCLOSE" );
          }
       }else{
          // barra de baixa...
          if( open > close ){
             if( !m_trade.tenhoOrdemLimitadaDeCompra( open,"OPENORDERS") &&
                  m_symb.Ask() >= close                                      ){
                  Print("MIN:",m_date.min, ":Comprando...");
                  m_trade.comprarLimit( close,"GERADORFASTCLOSE" );
             }
          }
       }
   }
}

// Abre uma ordem limitada de compra no preco atual se a barra eh de queda ou de venda se a barra eh de subida
void abrirOrdemNoPrecoAtualContraTendencia(){

   double open  = m_rates[0].open ;
   double close = m_rates[0].close;
   double low   = m_rates[0].low  ;
   double high  = m_rates[0].high ;

   if( estah_no_intervalo_de_negociacao() && passouUmMinutoDesdeUltimoTrade() ){

       // barra de alta...
       if( open < close ){

          if( !m_trade.tenhoOrdemLimitadaDeVenda( m_symb.Bid(),"OPENORDERS") ){
               Print("MIN:",m_date.min, ":Vendendo...");
               m_trade.venderLimit( m_symb.Bid(),"GERADORFASTCLOSE" );
          }
       }else{
          // barra de baixa...
          if( open > close ){
             if( !m_trade.tenhoOrdemLimitadaDeCompra( m_symb.Ask(),"OPENORDERS") ){
                  Print("MIN:",m_date.min, ":Comprando...");
                  m_trade.comprarLimit( m_symb.Ask(),"GERADORFASTCLOSE" );
             }
          }
       }
   }
}

// Abre uma ordem limitada de compra no preco atual se a barra eh de queda ou de venda se a barra eh de subida
void abrirOrdemNoPrecoAtualNaTendencia(){

   double open  = m_rates[0].open ;
   double close = m_rates[0].close;
   double low   = m_rates[0].low  ;
   double high  = m_rates[0].high ;
   double shift = m_symb.TickSize()*1.0;

   if( estah_no_intervalo_de_negociacao() && passouUmMinutoDesdeUltimoTrade() ){

       // barra de alta...
       if( open < close ){

          if( !m_trade.tenhoOrdemLimitadaDeCompra( m_symb.NormalizePrice(m_symb.Ask()-shift),m_symb.Name(), "OPENORDERS") ){
               Print("MIN:",m_date.min, ":Comprando...");
               m_trade.comprarLimit( m_symb.Ask()-shift,"GERADORFASTCLOSE" );
          }
       }else{
          // barra de baixa...
          if( open > close ){
             if( !m_trade.tenhoOrdemLimitadaDeVenda( m_symb.NormalizePrice(m_symb.Bid()+shift),m_symb.Name(),"OPENORDERS") ){
                  Print("MIN:",m_date.min, ":Vendendo...");
                  m_trade.venderLimit( m_symb.Bid()+shift,"GERADORFASTCLOSE" );
             }
          }
       }
   }
}

// verifica se jah passou um minuto apos o ultimo trade...
bool passouUmMinutoDesdeUltimoTrade(){
    TimeToStruct(TimeCurrent(),m_date);
    if( m_date.min != m_min_ult_trade ) { return true; }
    return true;
}

// Abre uma ordem limitada de compra ou venda por minuto. Usado como gerador de ordens de teste...
void abrirOrdemAlternadaPorMinuto(){
        if( estah_no_intervalo_de_negociacao() && passouUmMinutoDesdeUltimoTrade() ){

            // iniciando um trade para testar...
            if( m_min_ult_trade != m_date.min ){

                  if(m_min_ult_trade > 30){
                     Print("MIN:",m_date.min, ":Comprando...");
                     m_trade.comprarLimit( m_symb.Ask()-20,"GERADORFASTCLOSE" );
                  }else{
                     Print("MIN:",m_date.min, ":Vendendo...");
                     m_trade.venderLimit ( m_symb.Bid()+20,"GERADORFASTCLOSE" );
                  }

                  // salvando pra nao fazer outro trade no mesmo minuto...
                  m_min_ult_trade = m_date.min;
            }
        }
}

bool estah_no_intervalo_de_negociacao(){
    TimeToStruct(TimeCurrent(),m_date);
//  TimeToStruct(TimeLocal(),m_date);

    // restricao para nao operar no inicio nem no final do dia...
    if(m_date.hour <   HR_INI_OPERACAO     ) {  return false; } // operacao antes de 9:00 distorce os testes.
    if(m_date.hour >=  HR_FIM_OPERACAO + 1 ) {  return false; } // operacao apos    18:00 distorce os testes.

    if(m_date.hour == HR_INI_OPERACAO && m_date.min < MI_INI_OPERACAO ) { return false; } // operacao antes de 9:10 distorce os testes.
    if(m_date.hour == HR_FIM_OPERACAO && m_date.min > MI_FIM_OPERACAO ) { return false; } // operacao apos    17:50 distorce os testes.

    return true;
}


bool doTraillingStop(){

   double last = m_symb.Last();// m_minion.last(); // preco do ultimo tick;
   double bid  = m_symb.Bid ();
   double ask  = m_symb.Ask ();

   double lenstop  = m_dx1 * EA04_DX_TRAILLING_STOP;
   double   sl  = 0;
   //string m_line_tstop = "linha_stoploss";
   //int tendencia = getEstrategiaTendencia_02();
   //string strTendencia = tendencia == 1?"UP":(tendencia==-1?"DW":"ST");

   if( lenstop < 30 ) lenstop = 30;

   // calculando o trailling stop...
   if( estouComprado() ){
    //sl = last - dxsl;
      sl = bid - lenstop;
      if ( m_tstop < sl || m_tstop == 0 ) {
           m_tstop = sl;
           Print(m_name,":COMPRADO: [OPEN "   ,m_precoPosicao,
                                  "][LENSTOP ",lenstop       ,
                                  "][SL "     ,sl            ,
                                  "][BID "    ,bid            ,
                                  "][m_tstop ",m_tstop,
                                  "][profit " ,m_posicaoProfit,
                                  "][sldstop ",m_tstop-m_precoPosicao,"]");
           //if( !HLineMove(0,m_line_tstop,m_tstop) ){ HLineCreate(0,m_line_tstop,0,m_tstop,clrBlack,STYLE_SOLID,1,false,true,false,0);}
           //ChartRedraw(0);
      }
   }else{
      if( estouVendido() ){
         //sl = last + dxsl;
         sl = ask + lenstop;
         if ( m_tstop > sl || m_tstop == 0 ) {
              m_tstop = sl;
              Print(m_name,":VENDIDO: [OPEN ",m_precoPosicao,
                                    "][LENSTOP ",lenstop,
                                    "][SL "     ,sl            ,
                                    "][ASK "    ,ask            ,
                                    "][m_tstop ",m_tstop,
                                    "][profit ",m_posicaoProfit,
                                    "][sldstop ",m_precoPosicao-m_tstop,"]");
              //if( !HLineMove(0,m_line_tstop,m_tstop) ){ HLineCreate(0,m_line_tstop,0,m_tstop,clrBlack,STYLE_SOLID,1,false,true,false,0);}
              //ChartRedraw(0);
         }
      }
   }

   //if(!HlineMove(0,m_line_tstop,m_tstop){ HLineCreate(0,m_line_tstop,0,m_tstop,clrBlack,STYLE_SOLID,1,false,true,false,0);}
   //if ( !ObjectMove(0,"linha_stoploss",0,0,m_tstop) ){
   //    ObjectCreate(0,"linha_stoploss",OBJ_HLINE,0,0,m_tstop);
   //    ObjectSetInteger(0,"linha_stoploss",OBJPROP_COLOR,clrYellow);
   //}

   // acionando o trailling stop...
   if( ( estouComprado() && m_tstop != 0        )  &&
       ( ( bid < m_tstop && bid > m_precoPosicao ) )
     ){
       Print("TSTOP COMPRADO: bid:"+DoubleToString(bid,_Digits)+" m_tstop:"+DoubleToString(m_tstop,_Digits),"[profit ",m_posicaoProfit,"]" );
       fecharPosicao("TRLSTP");

       //ObjectDelete(0,"linha_stoploss");
       //HLineDelete(0,m_line_tstop);
       //ChartRedraw(0);

       return true;
   }
   if( ( estouVendido() && m_tstop != 0 ) &&
       ( ( ask > m_tstop && ask < m_precoPosicao ) )
     ){
       Print("TSTOP VENDIDO: ask:"+DoubleToString(ask,_Digits)+" m_tstop:"+DoubleToString(m_tstop,_Digits),"[profit ",m_posicaoProfit,"]" );
       fecharPosicao("TRLSTP");

       //ObjectDelete(0,"linha_stoploss");
       //HLineDelete(0,m_line_tstop);
       //ChartRedraw(0);

       return true;
   }
   return false;
}

bool doTraillingStop2(){

   m_symb.Refresh();
   m_bb.Refresh(-1);

   double last = m_symb.Last();// m_minion.last(); // preco do ultimo tick;
   double bid  = m_symb.Bid ();
   double ask  = m_symb.Ask ();

   double lenstop  = m_dx1 * EA04_DX_TRAILLING_STOP;
   double sl       = 0;
   double posicaoProfit = 0;

   if( lenstop < 30 ) lenstop = 30;

   // calculando o trailling stop...
   if( m_trade.estouComprado() ){
       sl = bid - lenstop - m_symb.Spread(); // SL eh fixo
       //tstop = sl;         // tstop varia assim que o lucro passar sl

      if ( m_tstop < sl || m_tstop == 0 ) {
           m_tstop = sl;
           Print(m_name,":COMPRADO2: [OPEN "   ,m_precoPosicao,
                                  "][LENSTOP ",lenstop       ,
                                  "][SL "     ,sl            ,
                                  "][BID "    ,bid            ,
                                  "][m_tstop ",m_tstop,
                                  "][profit " ,m_posicaoProfit,
                                  "][sldstop ",m_tstop-m_precoPosicao,"]");
      }
   }else{
      if( m_trade.estouVendido() ){
         sl = ask + lenstop + m_symb.Spread();
         if ( m_tstop > sl || m_tstop == 0 ) {
              m_tstop = sl;
              Print(m_name,":VENDIDO2: [OPEN ",m_precoPosicao,
                                    "][LENSTOP ",lenstop,
                                    "][SL "     ,sl            ,
                                    "][ASK "    ,ask            ,
                                    "][m_tstop ",m_tstop,
                                    "][profit " ,m_posicaoProfit,
                                    "][sldstop ",m_precoPosicao-m_tstop,"]");
         }
      }
   }

   // acionando o trailling stop...
   if( ( estouComprado() && m_tstop != 0        )  &&
       ( ( bid < m_tstop && ask > m_precoPosicao ) )
     ){
       Print("TSTOP2 COMPRADO2: bid:"+DoubleToString(bid,_Digits)+" m_tstop:"+DoubleToString(m_tstop,_Digits),"[profit ",m_posicaoProfit,"]" );
       fecharPosicao("TRLSTP2");

       return true;
   }
   if( ( estouVendido() && m_tstop != 0 ) &&
       ( ( ask > m_tstop && ask < m_precoPosicao ) )
     ){
       Print("TSTOP2 VENDIDO2: ask:"+DoubleToString(ask,_Digits)+" m_tstop:"+DoubleToString(m_tstop,_Digits),"[profit ",m_posicaoProfit,"]" );
       fecharPosicao("TRLSTP2");

       return true;
   }
   return false;
}

double normalizar(double preco){  return m_symb.NormalizePrice(preco); }

bool precoPosicaoAbaixoDaMedia(){ return m_precoPosicao < m_bb.Base(0) ;}
bool precoPosicaoAcimaDaMedia (){ return m_precoPosicao > m_bb.Base(0) ;}

bool precoNaMedia             (){ return m_symb.Last() < m_bb.Base(0) + m_tick_size &&
                                         m_symb.Last() > m_bb.Base(0) - m_tick_size    ;}

bool precoNaBandaInferior     (){ return m_symb.Ask() < m_bb.Lower(0) + m_tick_size &&
                                         m_symb.Ask() > m_bb.Lower(0) - m_tick_size    ;}

bool precoAbaixoBandaInferior (){ return m_symb.Ask() < m_bb.Lower(0) + m_tick_size;}

bool precoNaBandaSuperior     (){ return m_symb.Bid() < m_bb.Upper(0) + m_tick_size &&
                                         m_symb.Bid() > m_bb.Upper(0) - m_tick_size    ;}

bool precoAcimaBandaSuperior  (){ return m_symb.Bid() > m_bb.Upper(0) - m_tick_size;}

void fecharPosicao (string comentario){ m_trade.fecharQualquerPosicao (comentario); setSemPosicao(); }
void cancelarOrdens(string comentario){ m_trade.cancelarOrdens(comentario); setSemPosicao(); }

void setCompradoSoft(){ m_comprado = true ; m_vendido = false; }
void setVendidoSoft() { m_comprado = false; m_vendido = true ; }
void setComprado()    { m_comprado = true ; m_vendido = false; m_tstop = 0;}
void setVendido()     { m_comprado = false; m_vendido = true ; m_tstop = 0;}
void setSemPosicao()  { m_comprado = false; m_vendido = false; m_tstop = 0;}

bool estouComprado(){ return m_comprado; }
bool estouVendido (){ return m_vendido ; }

string status(){
   string obs =
         //" preco="       + m_tick.ask                         +
         //" bid="         + m_tick.bid                         +
         //" spread="      + (m_tick.ask-m_tick.bid)            +
           " last="        + DoubleToString( m_symb.Last() )
         //" time="        + m_tick.time
         ;
   return obs;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)  {
    EventKillTimer();
    m_feira.DeleteFromChart(0,0);
    IndicatorRelease( m_feira.Handle() );
    IndicatorRelease( m_bb.Handle()    );
    return;
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
    //Print(m_name,": ACCOUNT_BALANCE    = ",AccountInfoDouble(ACCOUNT_BALANCE));
    //Print(m_name,": ACCOUNT_PROFIT     = ",AccountInfoDouble(ACCOUNT_PROFIT));
    //Print(m_name,": ACCOUNT_EQUITY     = ",AccountInfoDouble(ACCOUNT_EQUITY));
}


