﻿//+------------------------------------------------------------------+
//|            eaMinion-09-02-00-dx-bolinguer-e-feira-indefinido.mq5 |
//|                                         Copyright 2019, OS Corp. |
//|                                                http://www.os.org |
//|                                                                  |
//| Tem o mesmo algoritmo fastclose da versao 2.3 com as melhorias:  |
//| 1. Fork da versao 2.7 feito em 05/11/2019.                       |
//| 2. Abertura e fechamento de rajadas pra acompanhar tendencia.    |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, OS Corp."
#property link      "http://www.os.org"
#property version   "901.000"

#include <Indicators\Trend.mqh> // for class CiMA;
#include <Generic\Queue.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

#include <..\Projects\projetcts\os-ea\ClassMinion-02-com-estatistica.mqh>
#include <oslib\osc\osc-minion-trade-03.mqh>
#include <oslib\osc-ind-minion-feira.mqh>
#include <oslib\os-lib.mq5>

//---------------------------------------------------------------------------------------------
input string S01                    = ""        ; //==== PARAMETROS GERAIS ====
input bool   EA07_FULL_AUTO         = false     ; //EA07_FULL_AUTO:se true, EA abre posicoes automaticamente.
input double EA03_PASSO_RAJADA      = 1         ; //EA03_PASSO_RAJADA:Incremento de preco, em tick, na direcao contraria a posicao;
input int    EA02_QTD_TICKS_4_GAIN  = 6         ; //EA02_QTD_TICKS_4_GAIN:Quantidade de ticks para o gain;
input int    EA01_MAX_VOL_EM_RISCO  = 150       ; //EA01_MAX_VOL_EM_RISCO:Qtd maxima de ticks em risco;
input double EA07_STOP_LOSS         = -800     ; //EA07_STOP_LOSS:Valor maximo de perda aceitavel;
input int    EA07_TICKS_STOP_LOSS   = 100       ; //EA07_TICKS_STOP_LOSS:Quantidade de ticks usados no stop loss;
input bool   EA03_FECHAR_RAJADA     = true      ; //EA03_FECHAR_RAJADA:Fechar ordens rajada qd nao houver posicao. 
input double EA05_VOLUME_LOTE       = 1         ; //EA05_VOLUME_LOTE:Tamanho do lote de negociação. Se zero, usa o lote minimo do simbolo.
input double EA09_INCL_SAIDA        = 0.2       ; //EA09_INCL_SAIDA:Inclinacao para sair do trade.
input double EA09_INCL_MIN          = 0.2       ; //EA09_INCL_MIN:Inclinacao maxima para entrar no trade.
input double EA09_INCL_MAX          = 0.5       ; //EA09_INCL_MAX:Inclinacao maxima para entrar no trade.
input bool   EA01_DEBUG             = false     ; //EA01_DEBUG:se true, grava informacoes de debug no log do EA.
input double EA04_DX_TRAILLING_STOP = 1.0       ; //EA04_DX_TRAILLING_STOP:% do DX1 para fazer o trailling stop
input double EA10_DX1               = 0.2       ; //EA10_DX1:Tamanho do DX em relacao a banda em %;
input int    EA08_MAGIC             = 2019110208; //EA08_MAGIC:Numero magico desse EA. yyyymmvvvv.
//---------------------------------------------------------------------------------------------
//  input double SPRED_MAXIMO      = 10 ; // Maior Spred permitido;
//  input int    DX_MIN            = 15 ; // DX mínimo para operar.
//---------------------------------------------------------------------------------------------
// configurando as bandas de bollinguer...
//input string S02               = ""; //==== BANDAS DE BOLLINGUER ====
//input int    BB_QTD_PERIODO_MA = 21; // Quantidade de periodos usados no calculo da media.
//input double BB_DESVIO_PADRAO  = 2 ; // Desvio padrao.
//---------------------------------------------------------------------------------------------
// configurando a feira...
input string S03                       = ""    ; //==== INDICADOR FEIRA ====
input bool   FEIRA01_DEBUG             = false ; // se true, grava informacoes de debug no log.
input bool   FEIRA02_GERAR_VOLUME      = false ; // se true, gera volume baseado nos ticks. Usa em papeis que nao informam volume, tais como o DJ30.
input bool   FEIRA03_GERAR_OFERTAS     = false ; // se true, gera ofertas baseadas nos ticks. Usa em papeis que nao informam o livro de ofertas.
input int    FEIRA04_QTD_BAR_PROC_HIST = 0     ; // Qtd barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
input double FEIRA05_BOOK_OUT          = 0     ; // Porcentagem das extremidades dos precos do book que serão desprezados.
input int    FEIRA06_QTD_PERIODOS      = 5     ; // Quantidade de barras que serao acumulads para calcular as medias.
input bool   FEIRA99_ADD_IND_2_CHART   = true  ; // Se true apresenta o idicador feira no grafico.
//---------------------------------------------------------------------------------------------
// configurando o horario de inicio e fim da operacao...
input string S04               = ""; //==== HORARIO DE OPERACAO ====
input int    HR_INI_OPERACAO   = 09; // Hora   de inicio da operacao;
input int    MI_INI_OPERACAO   = 15; // Minuto de inicio da operacao;
input int    HR_FIM_OPERACAO   = 17; // Hora   de fim    da operacao;
input int    MI_FIM_OPERACAO   = 50; // Minuto de fim    da operacao;
//---------------------------------------------------------------------------------------------

CiBands*      m_bb;
MqlDateTime   m_date;
string        m_name = "MINION-02-08-RAJADA-NA-TENDENCIA";
CSymbolInfo   m_symb                          ;
CPositionInfo m_posicao                       ;
CAccountInfo  m_cta                           ;
double        m_tick_size                     ;// alteracao minima de preco.
double        m_shift                         ;// valor do fastclose;
double        m_stopLoss                      ;// stop loss;
double        m_distMediasBook                ;// Distancia entre as medias Ask e Bid do book.

osc_minion_trade      m_trade;
osc_ind_minion_feira* m_feira;

int BB_SUPERIOR     =  1;
int BB_INFERIOR     = -1;
int BB_MEDIA        =  0;
int BB_DESCONHECIDA =  2;

int m_ult_toque     = BB_DESCONHECIDA; // indica em que banda foi o ultimo toque do preco.
int m_pri_toque     = BB_DESCONHECIDA; // indica em que banda estah o primeiro toque de preco; A operacao eh aberta no primeiro toque na banda;
int m_ult_oper      = BB_DESCONHECIDA; // indica em que banda foi a ultima operacao;

bool   m_cancelar_ordens = false;
bool   m_comprado      = false;
bool   m_vendido       = false;
double m_precoPosicao  = 0;
double m_volumePosicao = 0;    // volume da posicao atual
long   m_positionId    = 0;
double m_tstop         = 0;

//--- variaveis atualizadas pela funcao refreshMe...
double m_med           = 0;//normalizar( m_bb.Base(0)  ); // preco medio das bandas de bollinguer
double m_inf           = 0;//normalizar( m_bb.Lower(0) ); // preco da banda de bollinger inferior
double m_sup           = 0;//normalizar( m_bb.Upper(0) ); // preco da banda de bollinger superior
double m_bdx           = 0;//MathAbs   ( sup-med       ); // distancia entre as bandas de bollinger e a media, sem sinal;
double m_dx1           = 0;//normalizar( DX1*bdx       ); // normalmente 20% da distancia entre a media e uma das bandas.
int    m_qtdOrdens     = 0;
int    m_qtdPosicoes   = 0;
double m_posicaoProfit = 0;
double m_posicaoProfitAnt = 0;
int    m_min_ult_trade = 0;
double m_ask           = 0;
double m_bid           = 0;
double m_val_order_4_gain = 0;

//--precos medios do book e do timesAndTrades
double m_pmBid = 0;
double m_pmAsk = 0;
double m_pmBok = 0;
double m_pmBuy = 0;
double m_pmSel = 0;
double m_pmTra = 0;


//-- controle dos sinais
double m_sigBuy  = 0; //-- seta azul escura (para cima)
double m_sigSel  = 0; //-- seta vermelha    (para baixo)
double m_sigAsk  = 0; //-- seta rosa (pra cima)
double m_sigBid  = 0; //-- seta azul (pra baixo)

//-- controle das inclinacoes
double   m_inclSel    = 0;
double   m_inclBuy    = 0;
double   m_inclTra    = 0;
double   m_inclBok    = 0;
double   m_inclSelAbs = 0;
double   m_inclBuyAbs = 0;
double   m_inclTraAbs = 0;
double   m_inclEntrada= 0; // inclinacao usada na entrada da operacao.

string   m_apmb       = "APMB"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
MqlRates m_rates[1];

string   m_comment_fixo;
string   m_comment_var;

void refreshMe(){
    //m_bb.Refresh(-1);
    m_posicao.Select( m_symb.Name() );
    m_symb.RefreshRates();
    m_feira.Refresh();

    m_ask = m_symb.Ask();
    m_bid = m_symb.Bid();

    CopyRates(m_symb.Name(),_Period,0,1,m_rates);

    //m_med = normalizar( m_bb.Base(0)  ); // preco medio das bandas de bollinguer
    //m_inf = normalizar( m_bb.Lower(0) ); // preco da banda de bollinger inferior
    //m_sup = normalizar( m_bb.Upper(0) ); // preco da banda de bollinger superior
    //m_bdx = MathAbs   ( m_sup-m_med   ); // distancia entre as bandas de bollinger e a media, sem sinal;
    //m_dx1 = normalizar( EA10_DX1*m_bdx); // normalmente 20% da distancia entre a media e uma das bandas.

    m_qtdOrdens   = OrdersTotal();
    m_qtdPosicoes = PositionsTotal();

    // adminstrando posicao aberta...
    if( m_qtdPosicoes > 0 ){
        m_posicaoProfit = 0;
        if ( PositionSelect  (m_symb.Name()) ){ // soh funciona em contas hedge
      //if ( m_posicao.Select(m_symb.Name()) ){ // soh funciona em contas hedge
            if( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                setCompradoSoft();
            }else{
                setVendidoSoft();
            }
            m_posicaoProfit = PositionGetDouble (POSITION_PROFIT    );
            m_precoPosicao  = PositionGetDouble (POSITION_PRICE_OPEN);
            m_volumePosicao = PositionGetDouble (POSITION_VOLUME    );
            m_positionId    = PositionGetInteger(POSITION_IDENTIFIER);

        }
    }

     //-- precos medios do book
     //m_pmBid = m_symb.NormalizePrice( m_feira.getPrecoMedioTra(0) - EA09_LEN_BANDA_MED_TST );
     //m_pmAsk = m_symb.NormalizePrice( m_feira.getPrecoMedioTra(0) + EA09_LEN_BANDA_MED_TST );
     //m_pmBok = m_symb.NormalizePrice( m_feira.getPrecoMedioTra(0)                          );
   m_pmBid = normalizar( m_feira.getPrecoMedioBid(0) );
   m_pmAsk = normalizar( m_feira.getPrecoMedioAsk(0) );
   m_pmBok = normalizar( m_feira.getPrecoMedioBok(0) );
   m_pmSel = normalizar( m_feira.getPrecoMedioSel(0) );
   m_pmBuy = normalizar( m_feira.getPrecoMedioBuy(0) );
   m_pmTra = normalizar( m_feira.getPrecoMedioTra(0) );
   

   //--inclinacoes dos precos medios de compra e venda...
   m_inclSel    = m_feira.getInclinacaoSel(0);
   m_inclBuy    = m_feira.getInclinacaoBuy(0);
   m_inclTra    = m_feira.getInclinacaoTra(0);
   m_inclBok    = m_feira.getInclinacaoBok(0);
   m_inclSelAbs = MathAbs(m_inclSel);
   m_inclBuyAbs = MathAbs(m_inclBuy);
   m_inclTraAbs = MathAbs(m_inclTra);

   //-- sinais de compra e venda
   m_sigBuy = m_feira.getSinalDemandaBuy(0);
   m_sigSel = m_feira.getSinalDemandaSel(0);
   m_sigAsk = m_feira.getSinalOfertaAsk(0); //-- seta pra cima
   m_sigBid = m_feira.getSinalOfertaBid(0); //-- seta pra baixo
   
   m_comment_var = "CTA SLD: " + m_cta.Balance() + " CR: " + m_cta.Credit() + " PROFIT: " + m_cta.Profit() + " CAPLIQ: " + m_cta.Equity() + " MARGEM: " + m_cta.Margin() + " MARGEM LIVRE: " + m_cta.FreeMargin() + " NIVEL MARGEM: " + m_cta.FreeMargin() + "\n"
                   "VAL: " + m_posicaoProfit + " de " + EA07_STOP_LOSS + " VOL: " + m_volumePosicao +" de " + EA01_MAX_VOL_EM_RISCO + "\n"+
                   "INCLINACAO: " + DoubleToString(m_inclTra,2) + (estouComprado()?" COMPRADO":estouVendido()?" VENDIDO":" SEM POSICAO") +"\n" +
                   "VVOL/VMAX/VMIN: " + m_symb.Volume()+ "/"+  m_symb.VolumeHigh() + "/"+ m_symb.VolumeLow() +"\n"+
                   "SPREAD: " + m_symb.Spread() + "\n" + // STOPSLEVEL: " + m_symb.StopsLevel() + " FREEZELEVEL: " +  m_symb.FreezeLevel() + "\n" +
                   "BID/BHIGH/BLOW: " + m_symb.Bid()  + "/" + m_symb.BidHigh()  +"/"+m_symb.BidLow()  + "\n" +
                   "ASK/AHIGH/ALOW: " + m_symb.Ask()  + "/" + m_symb.AskHigh()  +"/"+m_symb.AskLow()  + "\n" +
                   "LAS/LHIGH/LLOW: " + m_symb.Last() + "/" + m_symb.LastHigh() +"/"+m_symb.LastLow() + "\n" +
                   ///////
                   //"SESSION \n" +
                   "QTD_OFERTAS: " + m_symb.SessionDeals()     + "\n" +
                   //"QTD_ORD_BUY: " + m_symb.SessionBuyOrders() + "\n" +
                   //"QTD_ORD_SEL: " + m_symb.SessionSellOrders()+ "\n" +
                   //"TURNOVER: "    + m_symb.SessionTurnover()  + "\n" +
                   //"INTEREST: "    + m_symb.SessionInterest()  + "\n" +
                   //"VOL_ORD_BUY: " + m_symb.SessionBuyOrdersVolume()  + "\n" +
                   //"VOL_ORD_SEL: " + m_symb.SessionSellOrdersVolume() + "\n" +
                   "OPEN: "        + m_symb.SessionOpen() + "\n" +
                   //"CLOSE: "       + m_symb.SessionClose() + "\n" +
                   "VWAP: "  + m_symb.SessionAW() + "\n" ;
                   //"PRECO_LIQ: "   + m_symb.SessionPriceSettlement() + "\n" +
                   //"PRECO_MIN: "   + m_symb.SessionPriceLimitMin() + "\n" +
                   //"PRECO_MAX: "   + m_symb.SessionPriceLimitMax() + "\n" ;
                    
   Comment(m_comment_fixo + m_comment_var);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()  {

    printf("***** Iniciando " + m_name + ":" + IntegerToString(EA08_MAGIC) + " as " + TimeToString( TimeCurrent() ) +"... ******");

    m_symb.Name                  ( Symbol() );
    m_symb.Refresh               (); // propriedades do simbolo. Basta executar uma vez.
    m_symb.RefreshRates          (); // valores do tick. execute uma vez por tick.
    m_tick_size = m_symb.TickSize(); //Obtem a alteracao minima de preco
    m_shift     = m_symb.NormalizePrice(EA02_QTD_TICKS_4_GAIN*m_tick_size);
    m_stopLoss  = m_symb.NormalizePrice(EA07_TICKS_STOP_LOSS *m_tick_size);
    m_trade.setMagic   (EA08_MAGIC);
    m_trade.setStopLoss(m_stopLoss);
    m_trade.setTakeProf(0);
    
    m_comment_fixo = "login:"       + m_cta.Login()                  + " trademode:" + m_cta.TradeModeDescription()   + "\n" 
                   //"alavancagem:" + m_cta.Leverage()               + "\n" +
                   //"stopoutmode:" + m_cta.StopoutModeDescription() + "\n" +
                   //"max_ord_pend:"+ m_cta.LimitOrders()            + "\n" + // max ordens pendentes permitidas
                   //"magin mode:"  + m_cta.MarginModeDescription()  + "\n" 
                   ;
    Comment(m_comment_fixo);
                         
    double lotes = EA05_VOLUME_LOTE < m_symb.LotsMin()? m_symb.LotsMin():
                   EA05_VOLUME_LOTE > m_symb.LotsMax()? m_symb.LotsMax():
                   EA05_VOLUME_LOTE;
    m_trade.setVolLote (lotes);

    // inicializando a banda de bolinguer...
    //m_bb = new CiBands();
    //if ( !m_bb.Create(_Symbol         , //string           string,        // Symbol
    //                 PERIOD_CURRENT   , //ENUM_TIMEFRAMES  period,        // Period
    //                 BB_QTD_PERIODO_MA, //int              ma_period,     // Averaging period
    //                 0                , //int              ma_shift,      // Horizontal shift
    //                 BB_DESVIO_PADRAO , //double           deviation      // Desvio
    //                 PRICE_MEDIAN       //int              applied        // (máximo + mínimo)/2 (see ENUM_APPLIED_PRICE)
    //                 )
    //    ){
    //    Print(m_name,": Erro inicializando o indicador BB :-(");
    //    return(1);
    //}

    // inicializando a feira...
    m_feira = new osc_ind_minion_feira();
    if( ! m_feira.Create(  m_symb.Name(),PERIOD_CURRENT           ,
                                         FEIRA01_DEBUG            ,
                                         FEIRA02_GERAR_VOLUME     ,
                                         FEIRA03_GERAR_OFERTAS    ,
                                         FEIRA04_QTD_BAR_PROC_HIST,
                                         FEIRA05_BOOK_OUT         ,
                                         FEIRA06_QTD_PERIODOS     ,
                                         IFEIRA_VERSAO_0203       )   ){
        Print(m_name,": Erro inicializando o indicador FEIRA :-( ", GetLastError() );
        return(1);
    }

    Print(m_name,": Expert ", m_name, " inicializado :-)" );

    // adicionando FEIRA ao grafico...
    if( FEIRA99_ADD_IND_2_CHART ){ m_feira.AddToChart(0,0); }

    return(0);
}

void fecharTudo(string descr){
      // se tem posicao ou ordem aberta, fecha.
      if( m_qtdPosicoes > 0 ){ fecharPosicao (descr); }
      Sleep(1000);
      if( m_qtdOrdens   > 0 ){ cancelarOrdens(descr); }
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
    refreshMe();

    if( !estah_no_intervalo_de_negociacao() ) { fecharTudo("INTERVALO"); return; }
    
    m_trade.setStopLoss( m_stopLoss        );
    m_trade.setVolLote ( m_symb.LotsMin()  );

    if ( m_qtdPosicoes > 0 ) {

         if( m_posicaoProfit < EA07_STOP_LOSS ){ 
             Print("Acionando STOPLOSS. Valor posicao=",m_posicaoProfit, " :-(");
             fecharTudo("STOP_LOSS"); 
             return;
         }else{
             if (m_posicaoProfit != m_posicaoProfitAnt){
               //Comment("VAL:" + m_posicaoProfit + " de ",EA07_STOP_LOSS + " VOL:" + m_volumePosicao +" de " + EA01_MAX_VOL_EM_RISCO);
                 
                 m_posicaoProfitAnt = m_posicaoProfit;
             }
         }
         // passo    : aumento de preco, em tick, na direcao contraria a posicao
         // volLimite: volume maximo em risco
         // volLote  : volume de ordem aberta na direcao contraria a posicao (usada pra fechar a posicao).
         // profit   : quantidade de ticks para o gain
         doOpenRajada(EA03_PASSO_RAJADA, EA01_MAX_VOL_EM_RISCO, EA05_VOLUME_LOTE, EA02_QTD_TICKS_4_GAIN); // acionando saida rapida...

    }else{
        // aqui neste bloco, estah garantido que nao ha posicao aberta...
        
        m_val_order_4_gain = 0; // zerando o valor da primeira prdem da posicao...

        if( m_qtdOrdens > 0 ){
         
           // se tiver um sinal pra cancelar todas as ordens, cancela agora e desfaz o sinal...
           //if( m_cancelar_ordens ) {
           //    m_trade.cancelarOrdens("SINAL CANCEL");
           //    Sleep(2000);
           //    m_cancelar_ordens = false;
           //    return;
           //}
           
           //apmb(nunca fechar), vazio(nunca fechar), numero(sempre fechar, pois soh pode ter ordem com comentario numerico se tiver posicao aberta)...
           m_trade.cancelarOrdensComComentarioNumerico(_Symbol);
           
           // se tiver ordens RAJADA sem posicao aberta e parametro manda fechar, fecha elas...
           if(EA03_FECHAR_RAJADA) m_trade.cancelarOrdensComentadas("RAJADA");
           
           Sleep(500); // Parada de meio segundo apos os cancelamentos visando evitar atropelos...
           
           // se tiver ordem sem stop, coloca agora...
           m_trade.colocarStopEmTodasAsOrdens(m_stopLoss);
        }
      
        if( EA07_FULL_AUTO ){ 
           abrirPosicaoNasMediasDoBook2();
         //abrirPosicaoNasMediasDoBook();
         //abrirPosicaoNosExtremosBB()   ;
         //abrirOrdemAlternadaPorMinuto();              // gerador de negociacoes pra testar o fastclose
         //abrirOrdemNoCloseDaBarraContraTendencia();   // tentativa de EA
         //abrirOrdemNoCloseDaBarraNaTendencia();       // tentativa de EA
         //abrirOrdemNoExtremoDaBarraContraTendencia(); // tentativa de EA
         //abrirOrdemNoPrecoAtualContraTendencia();     // tentativa de EA
         //abrirOrdemNoPrecoAtualNaTendencia();         // tentativa de EA
        }

        return;
    }

    return;
}//+------------------------------------------------------------------+

//----------------------------------------------------------------------------------------------------------------------------
// Esta funcao deve ser chamada sempre qua ha uma posicao aberta.
// Ela cria rajada de ordens no sentido da posicao, bem como as ordens de fechamento da posicao baseadas nas ordens da rajada.
// passo    : aumento de preco na direcao contraria a posicao
// volLimite: volume maximo em risco
// volLote  : volume de ordem aberta na direcao contraria a posicao
// profit   : quantidade de ticks para o gain
//----------------------------------------------------------------------------------------------------------------------------
bool doOpenRajada(double passo, double volLimite, double volLote, double profit){

   if( estouVendido() ){
   
        if( inclNoIntervaloParaSaidaDeVenda(m_inclTra) ){
        
            // reverter a posicao aqui...
            Print("Acionando STOP REVERSAO DA POSICAO VENDIDA. Valor posicao=",m_posicaoProfit," Inclinacao=", m_inclTra, " :-(");
            fecharTudo("STOP_REVERSAO"); 

        }else{
   
            // se nao tem ordem pendente acima do preco atual, abre uma...
            double precoOrdem = m_symb.NormalizePrice( m_ask+m_tick_size*passo );
            
            if( (precoOrdem > m_val_order_4_gain || m_val_order_4_gain==0 )                                   && // vender sempre acima da primeira ordem da posicao  
                !m_trade.tenhoOrdemLimitadaDeVenda ( precoOrdem                   , m_symb.Name(), "RAJADA" ) &&
                !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem-profit*m_tick_size, m_symb.Name(), "RAJADA" ) // se tiver a ordem de compra pendente,
                                                                                                              // significa que a ordem de venda foi
                                                                                                              // executada, entao nao abrimos nova
                                                                                                              // ordem de venda ateh que a compra,
                                                                                                              // que eh seu fechamento, seja executada.
              ){
               // se nao tiver, verifica o volume de ordens abertas de venda mais o volume da posicao (obs: a posicao deve ser vendedora)
               double vol = m_volumePosicao;// + m_trade.getVolOrdensPendentesDeVenda(_Symbol);
   
               // se o volume em risco for menor que o limite (ex: 10 lotes), abre ordem limitada acima do preco
               if( vol <= volLimite){
                   if( m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, volLote, "RAJADA") ){
                       if( m_val_order_4_gain==0 ){ m_val_order_4_gain = precoOrdem;}
                   }
               }
            }
            // abrindo ordens pra fechar a posicao
            return doCloseRajada(passo, volLote, profit, true);
        }
   }else{
   
        if( inclNoIntervaloParaSaidaDeCompra(m_inclTra) ){
            // reverter a posicao aqui...
            Print("Acionando STOP REVERSAO DA POSICAO COMPRADA. Valor posicao=",m_posicaoProfit, " Inclinacao= ", m_inclTra, " :-(");
            fecharTudo("STOP_REVERSAO"); 
        }else{
            // se nao tem ordem pendente abaixo do preco atual, abre uma...
            double precoOrdem = m_symb.NormalizePrice( m_bid-m_tick_size*passo );
            
            if( (precoOrdem < m_val_order_4_gain || m_val_order_4_gain==0 )                                   && // comprar sempre abaixo da primeira ordem da posicao  
                !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem                   , m_symb.Name(), "RAJADA" ) &&
                !m_trade.tenhoOrdemLimitadaDeVenda ( precoOrdem+profit*m_tick_size, m_symb.Name(), "RAJADA" ) // se tiver a ordem de venda pendente,
                                                                                                              // significa que a ordem de compra foi
                                                                                                              // executada, entao nao abrimos nova
                                                                                                              // ordem de compra ateh que a venda,
                                                                                                              // que eh seu fechamento, seja executada.
              ){
               // se nao tiver, verifica o volume de ordens abertas de compra mais o volume da posicao (obs: a posicao deve ser compradora)
               double vol = m_volumePosicao;// + m_trade.getVolOrdensPendentesDeCompra(_Symbol);
   
               // se o volume em risco for menor que o limite (ex: 10 lotes), abre ordem limitada acima do preco
               if( vol <= volLimite){
                   if( m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT, precoOrdem, volLote, "RAJADA") ){
                       if( m_val_order_4_gain==0 ){ m_val_order_4_gain = precoOrdem;}
                   }
               }
            }
            // abrindo ordens pra fechar a posicao
            return doCloseRajada(passo, volLote, profit, false);
        }
   }

   // nao deveria chegar aqui, a menos que esta funcao seja chamada sem uma posicao aberta.
   return false;
}
//----------------------------------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------------------
// Faz      : Abre as ordens de fechamento das posicoes abertas no doOpenRajada. As posicoes de fechamento sao
//            abertas sempre que as ordens da rejada sao executadas, ou seja, sempre que vao pra posicao.
//            Aqui vamos eliminar o bug da versao doCloseRajada, que estah duplicando as ordens de fechamento
//            da primeira ordem executada no fechamento da posicao.
//
// passo    : aumento de preco na direcao contraria a posicao
// volLote  : volume de ordem aberta na direcao contraria a posicao
// profit   : quantidade de ticks para o gain
// close_seel: true se estah fechando uma rajada de vendas e false se quer fechar uma rajada de compras.
//------------------------------------------------------------------------------------------------------------
bool doCloseRajada(double passo, double volLote, double profit, bool close_sell){

   // agora vamos processar as transacoes...
   ulong        deal_ticket; // ticket da transacao
   int          deal_type  ; // tipo de operação comercial
   CQueue<long> qDealSel   ; // fila de transacoes de venda  da posicao. Ao final do segundo laco, devem ficar na fila, as vendas cuja compra nao foi concretizada...
   CQueue<long> qDealBuy   ; // fila de transacoes de compra da posicao. Ao final do segundo laco, deve ficar vazia.

   // Faca assim:
   // 1. Coloque vendas e compras em filas separadas
   // 2. Percorra a fila de compras e, pra cada compra encontrada, busque a venda correspondente e retire-a da fila de vendas.
   // 3. Se sobraram vendas na fila de vendas, processe-a conforme abaixo.
   
   HistorySelectByPosition(m_positionId); // recuperando ordens e transacoes da posicao atual no historico...
   int deals = HistoryDealsTotal();
   for(int i=0;i<deals;i++) {  // selecionando as tranacoes (entradas e saidas) para processamento...

      deal_ticket =      HistoryDealGetTicket(i);
      deal_type   = (int)HistoryDealGetInteger(deal_ticket,DEAL_TYPE);

      // 1. Colocando vendas e compras em filas separadas...
      switch(deal_type){
         case DEAL_TYPE_SELL: qDealSel.Enqueue(deal_ticket); break;
         case DEAL_TYPE_BUY : qDealBuy.Enqueue(deal_ticket); break;
      }
   }

   // abrindo ordens de compra pra fechar uma rajada de vendas...
   if(close_sell){
      // 2. Percorra a fila de compras e, pra cada compra encontrada, busque a venda correspondente e retire-a da fila de vendas.
      int    qtd     = qDealBuy.Count();
      long   ticketSel;
      for(int i=0;i<qtd;i++) {
         deal_ticket = qDealBuy.Dequeue();
         ticketSel   = StringToInteger( HistoryDealGetString(deal_ticket,DEAL_COMMENT) ); // obtendo o ticket de venda no comentario da ordem de compra...
         qDealSel.Remove(ticketSel); // removendo a venda da fila de vendas pendentes de abrir posicao de compra...
      }

      // 3. Se sobraram vendas na fila de vendas, processe-a conforme abaixo.
      // se sobrou elemento na fila, checamos se jah tem a ordem de compra correspondente. Se nao tiver, criamos.
             qtd         = qDealSel.Count();
      double val         = 0               ;
      double precoProfit = 0               ;
      string idClose                       ;
      for(int i=0;i<qtd;i++) {
         deal_ticket = qDealSel.Dequeue();
         idClose = IntegerToString(deal_ticket); // colocando o ticket da venda na ordem de compra. Serah usado posteriormente
                                                 // para encontrar as compras que jah foram processadas.
         if( !m_trade.tenhoOrdemPendenteComComentario(_Symbol, idClose ) ){

             // se nao tem ordem de fechamento da posicao, criamos uma agora:
             precoProfit = m_symb.NormalizePrice( HistoryDealGetDouble(deal_ticket,DEAL_PRICE) - profit*m_tick_size );
             m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT,precoProfit, volLote, idClose);
         }
      }
   // abrindo ordens de venda pra fechar uma rajada de compras...
   }else{
      // 2. Percorra a fila de vendas e, pra cada venda encontrada, busque a compra correspondente e retire-a da fila de compras.
      int    qtd     = qDealSel.Count();
      long   ticketBuy;
      for(int i=0;i<qtd;i++) {
         deal_ticket = qDealSel.Dequeue();
         ticketBuy   = StringToInteger( HistoryDealGetString(deal_ticket,DEAL_COMMENT) ); // obtendo o ticket de compra no comentario da ordem de venda...
         qDealBuy.Remove(ticketBuy); // removendo a compra da fila de compras pendentes de abrir posicao de venda...
      }

      // 3. Se sobraram compras na fila de compras, processe-a conforme abaixo.
      // se sobrou elemento na fila, checamos se jah tem a ordem de venda correspondente. Se nao tiver, criamos.
             qtd         = qDealBuy.Count();
      double val         = 0               ;
      double precoProfit = 0               ;
      string idClose                       ;
      for(int i=0;i<qtd;i++) {
         deal_ticket = qDealBuy.Dequeue();
         idClose = IntegerToString(deal_ticket); // colocando o ticket da compra na ordem de venda. Serah usado posteriormente
                                                 // para encontrar as vendas que jah foram processadas.
         if( !m_trade.tenhoOrdemPendenteComComentario(_Symbol, idClose ) ){
             // se nao tem ordem de fechamento da posicao, criamos uma agora:
             precoProfit = m_symb.NormalizePrice( HistoryDealGetDouble(deal_ticket,DEAL_PRICE) + profit*m_tick_size );
             m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT,precoProfit, volLote, idClose);
         }
      }
   }

   return true;
}

// verifica se inclinacao estah no intervalo indicado.
bool inclNoIntervaloMinimo           ( double incl ){ return ( incl > -EA09_INCL_MAX && incl <  EA09_INCL_MAX       ); } 
bool inclNoIntervaloParaCompra       ( double incl ){ return ( incl >  EA09_INCL_MIN && incl <  EA09_INCL_MAX       ); } 
bool inclNoIntervaloParaVenda        ( double incl ){ return ( incl < -EA09_INCL_MIN && incl > -EA09_INCL_MAX       ); } 
bool inclNoIntervaloParaSaidaDeCompra( double incl ){ return (                          incl < -EA09_INCL_SAIDA ); } 
bool inclNoIntervaloParaSaidaDeVenda ( double incl ){ return (                          incl >  EA09_INCL_SAIDA ); } 

//------------------------------------------------------------------------------------------------------------
void abrirPosicaoNasMediasDoBook2(){

   double vol        = EA05_VOLUME_LOTE;
   double inclMinima = EA09_INCL_MAX;
   double precoOrdem = 0;

   // venda no preco mais caro.
   if(   m_bid     >  m_pmBid  &&
       //m_ask     >  m_pmTra  &&
       //m_inclTra < -inclMinima ){
        inclNoIntervaloParaVenda(m_inclTra) ){

        //precoOrdem = m_pmAsk; // venda no preco medio de compra
        precoOrdem = m_bid; // venda no preco medio de compra

        //verificando se tem ordens sell abertas (usando 1 tick de tolerancia)...
        if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size*1 ) ){
             if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb);
        }
        return; //<TODO> REVISAR ESTE RETURN
   }else{
        // compra no preco mais barato e com inclinacao pra cima.
        if(   m_ask     <  m_pmAsk  &&
            //m_bid     <  m_pmTra  &&
            //m_inclTra > inclMinima ){ 
             inclNoIntervaloParaCompra(m_inclTra) ){
         
             //precoOrdem = m_pmBid; // copmpra no preco medio de venda
             precoOrdem = m_ask; // copmpra no preco medio de venda
      
             //verificando se tem ordens buy abertas (usando 1 tick de tolerância)...
             if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size*1 ) ){
                  if(precoOrdem!=0) m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb);
             }
             return; //<TODO> REVISAR ESTE RETURN
        }
   }
   // chegou aqui, pode ser que existam ordens abertas que nao satisfacam as condicoes de entrada. Entao as cancelamos.
   m_trade.cancelarOrdensComentadas(m_apmb);
}
//------------------------------------------------------------------------------------------------------------



// venda: - setas do book  azul      (ask)  para baixo.
//        - setas do trade vermelhas (sell) para baixo.
//        - preco acima do ultimo DX superior da BB.
//
// alvo: - no DX imediatamente acima da média de ofertas de venda rosa(ask) do book.
// loss: - 1  DX acima do desvio padrão de 3 da BB.
//
//
// compra: - setas do book  rosa  (bid) para cima.
//         - setas do trade azuis (buy) para cima.
//         - preco abaixo do ultimo DX inferior da banda da BB.
//
// alvo: - no DX imediatamente abaixo da média de ofertas de compra azuis(bid) do book.
// loss: - 1  DX abaixo do desvio padrão de 3 da BB.
//
void abrirPosicaoNosExtremosBB(){

   double ask        = m_symb.Ask();
   double bid        = m_symb.Bid();
   //string name       = "APMB"; //Abre Posicao nas Medias do Book.
   double vol        = EA05_VOLUME_LOTE;
   double precoOrdem = 0;

   // venda: - setas do book  azul      (ask)  para baixo.
   //        - setas do trade vermelhas (sell) para baixo.
   //        - preco acima do ultimo DX superior da BB.   if( bid      > m_pmBok &&  // preco acima da media
   if(                       //setas do book  azul      (ask)  para baixo.
        m_sigSel > 0     &&  //setas do trade vermelhas (sell) para baixo.
        bid      > m_sup  ){ //preco acima do ultimo DX superior da BB.

       precoOrdem = bid; // vendendo um tick acima do preco de venda;

       //verificando se tem ordens sell abertas (usando 2 ticks de tolerancia)...
       if( !m_trade.tenhoOrdemLimitadaDeVenda( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size*2 ) ){
            m_trade.enviarOrdemPendente(ORDER_TYPE_SELL_LIMIT, precoOrdem, vol, m_apmb);
            setFastClose(); // desenvolver close na oferta de venda...
       }
   }

   // compra: - setas do book  rosa  (bid) para cima.
   //         - setas do trade azuis (buy) para cima.
   //         - preco abaixo do ultimo DX inferior da banda da BB.
   if(                   //setas do book  rosa  (bid) para cima.
       m_sigBuy > 0  &&  // setas do trade azuis (buy) para cima.
       ask < m_inf    ){ // preco abaixo do ultimo DX inferior da banda da BB.

       precoOrdem = ask; // comprando um tick abaixo do preco de compra;

       //verificando se tem ordens buy abertas (usando 2 ticks de tolerância)...
       if( !m_trade.tenhoOrdemLimitadaDeCompra( precoOrdem, m_symb.Name(), m_apmb, vol , true, m_tick_size*2 ) ){
            m_trade.enviarOrdemPendente(ORDER_TYPE_BUY_LIMIT , precoOrdem, vol, m_apmb);
            setFastClose(); // desenvolver close na oferta de venda...
       }
   }
}






  bool proibidoComprar(){ return ( m_inclTra < 0 && m_inclTraAbs > 0.15 ); }
  bool proibidoVender (){ return ( m_inclTra > 0 && m_inclTraAbs > 0.15 ); }

  bool proibidoPosicaoComprada(){ return ( m_inclTra < 0 && m_inclTraAbs > 0.25 ); }
  bool proibidoPosicaoVendida (){ return ( m_inclTra > 0 && m_inclTraAbs > 0.25 ); }

  bool podeComprarNaAgressao(){ return ( m_inclTra > 0 && m_inclTraAbs > 0.30 ); }
  bool podeVenderNaAgressao (){ return ( m_inclTra < 0 && m_inclTraAbs > 0.30 ); }


  double EA10_INCL_PROIB_ABRIR_POSICAO_FASTCLOSE = 0.15;
  double EA11_INCL_PROIB_POSICAO_FASTCLOSE       = 0.25;
  double EA12_INCL_PROIB_POSICAO_FASTCLOSE = 0.25;

bool m_fastClose     = true;
bool m_traillingStop = false;
void setFastClose()    { m_fastClose=true ; m_traillingStop=false; m_inclEntrada = m_inclTra;}
void setTraillingStop(){ m_fastClose=false; m_traillingStop=true ;}

// Mantem uma ordem limitada de compra no high da barra e uma ordem limitada de venda no low inferior da barra...
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
    //IndicatorRelease( m_bb.Handle()    );
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


