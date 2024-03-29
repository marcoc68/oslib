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


input string S01                    = ""      ; //==== PARAMETROS GERAIS ====
input bool   EA01_DEBUG             = false   ; // EA01_DEBUG:se true, grava informacoes de debug no log do EA.
input bool   EA02_ADD_IND_2_CHART   = true    ; // EA02_ADD_IND_2_CHART:se true, adiciona ind feira ao grafico.
input double DX1                    = 0.2     ; // DX1:Tamanho do DX em relacao a banda em %;
input double EA04_DX_TRAILLING_STOP = 1.0     ; // EA04_DX_TRAILLING_STOP:% do DX1 para fazer o para fazer o trailling stop
//input double DX_TP                  = 10      ; // multiplica por DX para determinar o ponto de saida com lucro. Se colocar , o ponto de saida eh a media.
//input double DX_SL                  = 2       ; // multiplica por DX para determinar o ponto de saida com perda.
input double VOLUME_LOTE            = 01      ; // Tamanho do lote de negociação;
input int    MAGIC                  = 2020200 ; // Numero magico desse EA.
input string S02                    = ""      ; //==== PARAMETROS GERAIS ====

//  input double TP                = 20 ; // Take Profit da operacao em pontos.
//  input double SL                = 150; // Stop Loss da operacao em pontos.
//  input double SPRED_MAXIMO      = 10 ; // Maior Spred permitido;
//  input int    DX_MIN            = 15 ; // DX mínimo para operar.
//---------------------------------------------------------------------------------------------
// configurando a feira...
input string S03                       = ""    ; //==== INDICADOR FEIRA ====
input bool   FEIRA01_DEBUG             = false ; // se true, grava informacoes de debug no log.
input bool   FEIRA02_GERAR_VOLUME      = false ; // se true, gera volume baseado nos ticks. Usa em papeis que nao informam volume, tais como o DJ30.
//  input bool   FEIRA03_GERAR_OFERTAS     = false ; // se true, gera ofertas baseadas nos ticks. Usa em papeis que nao informam o livro de ofertas.
input int    FEIRA04_QTD_BAR_PROC_HIST = 10    ; // Quantidade de barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
input double FEIRA05_BOOK_OUT          = 0.4   ; // Porcentagem das extremidades dos precos do book que serão desprezados.
input int    FEIRA06_QTD_PERIODOS      = 10    ; // Quantidade de barras que serao acumulads para calcular as medias.
input string S04                       = ""    ; //==== FIM PARAM INDICADOR FEIRA ====;
//---------------------------------------------------------------------------------------------
// configurando a rede ...
input string S05     = ""    ; //==== NETNEU ====
input double NET_W0  =  1.0  ; // Peso dos ultimos 10 periodos
input double NET_W1  =  2.0  ; // Peso dos ultimos 10 periodos
input double NET_W2  =  3.0  ; // Peso dos ultimos 10 periodos
input double NET_W3  =  4.0  ; // Peso dos ultimos 10 periodos
input double NET_W4  =  5.0  ; // Peso dos ultimos 10 periodos
input double NET_W5  =  6.0  ; // Peso dos ultimos 10 periodos
input double NET_W6  =  7.0  ; // Peso dos ultimos 10 periodos
input double NET_W7  =  8.0  ; // Peso dos ultimos 10 periodos
input double NET_W8  =  9.0  ; // Peso dos ultimos 10 periodos
input double NET_W9  = 10.0  ; // Peso dos ultimos 10 periodos
input string S06     = ""    ; //==== NETNEU ====
//---------------------------------------------------------------------------------------------
// configurando as bandas de bollinguer...
input string S07               = ""; //==== BANDAS DE BOLLINGUER ====
input int    BB_QTD_PERIODO_MA = 21; // Quantidade de periodos usados no calculo da media.
input double BB_DESVIO_PADRAO  = 2 ; // Desvio padrao.
input string S08               = ""; //==== BANDAS DE BOLLINGUER ====

// configurando o horario de inicio e fim da operacao...
input string S09               = ""; //==== HORARIO DE OPERACAO ====
input int    HR_INI_OPERACAO   = 09; // Hora   de inicio da operacao;
input int    MI_INI_OPERACAO   = 15; // Minuto de inicio da operacao;
input int    HR_FIM_OPERACAO   = 17; // Hora   de fim    da operacao;
input int    MI_FIM_OPERACAO   = 30; // Minuto de fim    da operacao;
input string S10               = ""; //==== HORARIO DE OPERACAO ====
//---------------------------------------------------------------------------------------------

CiBands*    m_bb;
MqlDateTime m_date;
string      m_estrategia = "NEUROFEIRATEND"                 ;
string      m_name       = "MINION-02-02-00-" + m_estrategia;
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

//--- variaveis usadas pelas funcoes neuro...
double m_net_w0         = NET_W0   ; // Peso dos ultimos 10 periodos
double m_net_w1         = NET_W1   ; // Peso dos ultimos 10 periodos
double m_net_w2         = NET_W2   ; // Peso dos ultimos 10 periodos
double m_net_w3         = NET_W3   ; // Peso dos ultimos 10 periodos
double m_net_w4         = NET_W4   ; // Peso dos ultimos 10 periodos
double m_net_w5         = NET_W5   ; // Peso dos ultimos 10 periodos
double m_net_w6         = NET_W6   ; // Peso dos ultimos 10 periodos
double m_net_w7         = NET_W7   ; // Peso dos ultimos 10 periodos
double m_net_w8         = NET_W8   ; // Peso dos ultimos 10 periodos
double m_net_w9         = NET_W9   ; // Peso dos ultimos 10 periodos
double m_net_inputs        [10]    ; // array for storing inputs
double m_net_weight        [10]    ; // array for storing weights
double m_net_feira_buf_data[10]    ; // coleta dados do indicador feira

//double m_net_out        = 0        ; // variable for storing the output of the neuron
//--- fim variaveis usadas pelas funcoes neuro...

double m_posicaoProfit = 0;
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

    // adminstrando posicao aberta...
    if( m_qtdPosicoes > 0 ){
        m_posicaoProfit = 0;
        if ( PositionSelect(m_symb.Name()) ){
            if( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                setCompradoSoft();
            }else{
                setVendidoSoft();
            }
            m_posicaoProfit = PositionGetDouble(POSITION_PROFIT    );
            m_precoPosicao  = PositionGetDouble(POSITION_PRICE_OPEN);
        }
    }

    // administrando ordens abertas...
    if( m_qtdOrdens > 0 ){
        if (OrderSelect(m_symb.Name()) ){
            // cancelando ordens abertas a mais de 1 minuto...
            if( OrderGetInteger(ORDER_TIME_SETUP) > (TimeCurrent()-60) ){ cancelarOrdens("TMPLIMITE"); }
        }
    }
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

    // inicializando a feira...
    if( ! m_feira.Create(  m_symb.Name(),PERIOD_CURRENT           ,
                                         FEIRA01_DEBUG            ,
                                         FEIRA02_GERAR_VOLUME     ,
                                         false                    , // nao se usa, FEIRA03_GERAR_OFERTAS    ,
                                         FEIRA04_QTD_BAR_PROC_HIST,
                                         FEIRA05_BOOK_OUT         ,
                                         FEIRA06_QTD_PERIODOS     ,
                                         IFEIRA_VERSAO_0202       )   ){
        Print(m_name,": Erro inicializando o indicador FEIRA :-( ", GetLastError() );
        return(1);
    }
    Print(m_name,": Expert ", m_name, " inicializado :-)" );

    // adicionando FEIRA ao grafico...
    if( EA02_ADD_IND_2_CHART ){ m_feira.AddToChart(0,0); }

    // NEURO::preenchendo vetor de pesos com os parametros recebidos...
    neuroSetPesosNeuron();

    if( EA01_DEBUG ){
        string dt = TimeToString( TimeCurrent(),TIME_DATE|TIME_MINUTES|TIME_SECONDS );
        StringReplace ( dt, ".", ""  );
        StringReplace ( dt, ":", ""  );
        StringReplace ( dt, " ", "_" );

        Print(m_name,": ATENCAO:Em modo DEBUG! Abrindo LOG...");
        m_minion.setLogFileName(m_name +"-"+m_symb.Name() + "-" + dt + "-ticks.csv");
    }
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
    //if( m_qtdOrdens == 0 && m_qtdPosicoes == 0 ){ doEstrategiaTendencia_01(); return; }
    if( m_qtdOrdens == 0 && m_qtdPosicoes == 0 ){ doEstrategiaTendencia_02(); return; }

    return;
}//+------------------------------------------------------------------+

//+-------------------------------------+
//| comprando e vendendo na tendencia...|
//+-------------------------------------+
void doEstrategiaTendencia_01(){

    double outTenUp=neuroCalcSaidaNeuron(IFEIRA_BUF_SINAL_TEND_UP);
    double outTenDw=neuroCalcSaidaNeuron(IFEIRA_BUF_SINAL_TEND_DW);
    double outRevUp=neuroCalcSaidaNeuron(IFEIRA_BUF_SINAL_REVR_UP);
    double outRevDw=neuroCalcSaidaNeuron(IFEIRA_BUF_SINAL_REVR_DW);

    m_trade.setStopLoss( m_dx1 * EA04_DX_TRAILLING_STOP ); // dx1 normalmente eh 20% da distância entre banda e media.
    m_trade.setTakeProf( 0     ); // com zero para trabalhar com trailling stop..

    Print(m_name, "[outTenUp ",outTenUp,"][outTenDw ",outTenDw,"][outRevUp ",outRevUp,"][outRevDw ",outRevDw,"]");

    if     (outTenUp > 0.5 ){ comprar("TST1");}
    else if(outTenDw > 0.5 ){ vender ("TST1");}

    // demonstrando caso tenha acontecido erro...
    if(outTenUp==-9.0){Print(m_name,":Erro calculando tendencia de alta :-(");}
    if(outTenDw==-9.0){Print(m_name,":Erro calculando tendencia de baix :-(");}
    if(outRevUp==-9.0){Print(m_name,":Erro calculando reversao  de alta :-(");}
    if(outRevDw==-9.0){Print(m_name,":Erro calculando reversao  de baix :-(");}
}

//+-------------------------------------+
//| comprando e vendendo na tendencia...|
//+-------------------------------------+
void doEstrategiaTendencia_02(bool print=false){
    int result = getEstrategiaTendencia_02(print);
    if     (result ==  1 && m_dx1 > 60 ){ Print("Comprando..."); comprar("TST2");}
    else if(result == -1 && m_dx1 > 60 ){ Print("Vendendo..." ); vender ("TST2");}
}

int getEstrategiaTendencia_02(bool print=false){
    double outTen  =neuroCalcSaidaNeuron(IFEIRA_BUF_TENDENCIA, print);
    //double outRev  =neuroCalcSaidaNeuron(IFEIRA_BUF_REVERSAO , print);
    //ArrayPrint(m_net_weight        );

    //double outRev  =0;

    m_trade.setStopLoss( m_dx1 * EA04_DX_TRAILLING_STOP ); // dx1 normalmente eh 20% da distância entre banda e media.
    m_trade.setTakeProf( 0     ); // dx1 normalmente eh 20% da distância entre banda e media.

    // demonstrando caso tenha acontecido erro...
    if(print) Print(m_name, "[outTen ",DoubleToString(outTen,_Digits),"]");
  //if(print) Print(m_name, "[outTen ",DoubleToString(outTen,_Digits),"][outRev ",DoubleToString(outRev,_Digits),"]");
    if(outTen==-9.0){Print(m_name,":Erro calculando tendencia :-("); return 0;}
  //if(outRev==-9.0){Print(m_name,":Erro calculando reversao  :-("); return 0;}


    if     (outTen > 0.5                ){ return  1;}
    else if(outTen < 0.5                ){ return -1;}
    //if     (outTen > 0.6 && outRev > 0.6){ return  1;}
    //else if(outTen < 0.4 && outRev < 0.4){ return -1;}
    return 0;
}

//+----------------------------------------------------------+
//| comprando e vendendo na feira segundo oferta e demanda...|
//+----------------------------------------------------------+
void doEstrategiaNegociarOfertaDemanda(){

    m_trade.setStopLoss( m_dx1 * EA04_DX_TRAILLING_STOP ); // dx1 normalmente eh 20% da distância entre banda e media.
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
}

// verifica se o preco estah na banda superior. Recebe um parametro de distancia da banda e da media visando
// sinalizar quando preco estiver mais interno a banda.
bool precoNaBandaSuperior(double dx ){ return m_symb.Last() > m_bb.Base(0)+dx; }

// verifica se o preco estah na banda inferior. Recebe um parametro de distancia da banda e da media visando
// sinalizar quando preco estiver mais interno a banda.
bool precoNaBandaInferior(double dx ){ return m_symb.Last() < m_bb.Base(0)-dx; }

// corrige ordem de entrada na banda superior se necessario
void ajustarPontoEntradaNaBandaSuperior(){
   double sup   = normalizar( m_bb.Upper(0) ); // preco na banda superior

   // ordem ficou fora da bandasuperior, altero a ordem para ficar na banda.
   if( m_trade.getPrice() < sup || m_trade.getPrice() > (sup+m_tick_size) ) {

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

      if( m_trade.alterarOrdem( ORDER_TYPE_BUY_LIMIT, inf ) ) return;
      // falhou a alteracao da ordem, entao deletamos e aguardamos a execucao do proximo ciclo,
      // onde serah aberta nova ordem caso a anterior nao foi ainda executada.
      m_trade.cancelarOrdens("CANCELANDO APOS FALHA NA ALTERACAO.");
   }
}


void doMoverPontoEntradaSeNecessario(){
   double med   = normalizar( m_bb.Base(0) )    ; // preco medio das bandas de bollinguer
   // o preco da ordem ficou maior que o da media, altero a ordem para ficar na media.
   if( m_trade.getPrice() < (med-m_tick_size) || m_trade.getPrice() > (med+m_tick_size) ) {

       m_trade.alterarPrecoOrdem( med );
   }
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

   double last = m_symb.Last();// m_minion.last(); // preco do ultimo tick;
   double bid  = m_symb.Bid ();
   double ask  = m_symb.Ask ();

   double dxsl  = m_dx1 * EA04_DX_TRAILLING_STOP;
   double   sl  = 0;
   //string m_line_tstop = "linha_stoploss";
   int tendencia = getEstrategiaTendencia_02();
   string strTendencia = tendencia == 1?"UP":(tendencia==-1?"DW":"ST");

   // calculando o trailling stop...
   if( estouComprado() ){
    //sl = last - dxsl;
      sl = ask - dxsl;
      if ( m_tstop < sl || m_tstop == 0 ) {
           m_tstop = sl;
           Print(m_name,": [m_precoPosicao ",m_precoPosicao,"][m_tstop ",m_tstop,"][profit ",m_posicaoProfit,"][sldstop ",m_tstop-m_precoPosicao,"][TEND ",strTendencia,"]");
           //if( !HLineMove(0,m_line_tstop,m_tstop) ){ HLineCreate(0,m_line_tstop,0,m_tstop,clrBlack,STYLE_SOLID,1,false,true,false,0);}
           //ChartRedraw(0);
      }
   }else{
      if( estouVendido() ){
         //sl = last + dxsl;
         sl = bid + dxsl;
         if ( m_tstop > sl || m_tstop == 0 ) {
              m_tstop = sl;
              Print(m_name,": [m_precoPosicao ",m_precoPosicao,"][m_tstop ",m_tstop,"][profit ",m_posicaoProfit,"][sldstop ",m_precoPosicao-m_tstop,"][TEND ",strTendencia,"]");
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
       ( ( last < m_tstop && last > m_precoPosicao ) || tendencia == -1 )
     ){
       Print("TSTOP COMPRADO: last:"+DoubleToString(last,2)+" m_tstop:"+DoubleToString(m_tstop,2),"[profit ",m_posicaoProfit,"][TEND ",strTendencia,"]" );
       fecharPosicao("TRLSTP");

       //ObjectDelete(0,"linha_stoploss");
       //HLineDelete(0,m_line_tstop);
       //ChartRedraw(0);

       return true;
   }
   if( ( estouVendido() && m_tstop != 0 ) &&
       ( ( last > m_tstop && last < m_precoPosicao ) || tendencia == 1 )
     ){
       Print("TSTOP COMPRADO: last:"+DoubleToString(last,2)+" m_tstop:"+DoubleToString(m_tstop,2),"[profit ",m_posicaoProfit,"][TEND ",strTendencia,"]" );
       fecharPosicao("TRLSTP");

       //ObjectDelete(0,"linha_stoploss");
       //HLineDelete(0,m_line_tstop);
       //ChartRedraw(0);

       return true;
   }
   return false;
}

double normalizar(double preco){  return m_symb.NormalizePrice(preco); }


bool precoPosicaoAbaixoDaMedia() { return m_precoPosicao < m_bb.Base(0) ;}
bool precoPosicaoAcimaDaMedia () { return m_precoPosicao > m_bb.Base(0) ;}

bool precoNaMedia             () { return m_symb.Last() < m_bb.Base(0) + m_tick_size &&
                                          m_symb.Last() > m_bb.Base(0) - m_tick_size    ;}

bool precoNaBandaInferior     (){ return m_symb.Ask() < m_bb.Lower(0) + m_tick_size &&
                                         m_symb.Ask() > m_bb.Lower(0) - m_tick_size    ;}

bool precoAbaixoBandaInferior (){ return m_symb.Ask() < m_bb.Lower(0) + m_tick_size;}

bool precoNaBandaSuperior     (){ return m_symb.Bid() < m_bb.Upper(0) + m_tick_size &&
                                         m_symb.Bid() > m_bb.Upper(0) - m_tick_size    ;}

bool precoAcimaBandaSuperior  (){ return m_symb.Bid() > m_bb.Upper(0) - m_tick_size;}

void comprar(string comentario){ escreverLog("COMPR"); m_trade.comprar(m_minion.getTick(), comentario ); setComprado(); }
void vender (string comentario){ escreverLog("VENDA"); m_trade.vender (m_minion.getTick(), comentario ); setVendido (); }

void comprarStop(int offset){ escreverLog("COMST"); m_trade.comprarStop( offset,status() ); setComprado(); }
void venderStop (int offset){ escreverLog("VENST"); m_trade.venderStop ( offset,status() ); setVendido (); }

void comprarLimit(double valor, string obs){ escreverLog("COMLM"); m_trade.comprarLimit( valor,status() ); setComprado(); }
void venderLimit (double valor, string obs){ escreverLog("VENLM"); m_trade.venderLimit ( valor,status() ); setVendido (); }

void fecharPosicao (string comentario){ m_trade.fecharPosicao (comentario); setSemPosicao(); }
void cancelarOrdens(string comentario){ m_trade.cancelarOrdens(comentario); setSemPosicao(); }

void setCompradoSoft(){ m_comprado = true ; m_vendido = false; m_precoPosicao = m_symb.Ask();}
void setVendidoSoft() { m_comprado = false; m_vendido = true ; m_precoPosicao = m_symb.Bid();}
void setComprado()    { m_comprado = true ; m_vendido = false; m_precoPosicao = m_symb.Ask(); m_tstop = 0;}
void setVendido()     { m_comprado = false; m_vendido = true ; m_precoPosicao = m_symb.Bid(); m_tstop = 0;}
void setSemPosicao()  { m_comprado = false; m_vendido = false; m_precoPosicao = 0           ; m_tstop = 0;}

bool estouComprado(){ return m_comprado; }
bool estouVendido (){ return m_vendido ; }

string status(){
   string obs =
         m_estrategia
         +
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
//  TimeToStruct(TimeLocal(),m_date);

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
    //Print(m_name,": ACCOUNT_BALANCE    = ",AccountInfoDouble(ACCOUNT_BALANCE));
    //Print(m_name,": ACCOUNT_PROFIT     = ",AccountInfoDouble(ACCOUNT_PROFIT));
    //Print(m_name,": ACCOUNT_EQUITY     = ",AccountInfoDouble(ACCOUNT_EQUITY));
}

// pesos sinapticos
void neuroSetPesosNeuron(){
    //--- place weights into the array
   m_net_weight[0]=m_net_w0;
   m_net_weight[1]=m_net_w1;
   m_net_weight[2]=m_net_w2;
   m_net_weight[3]=m_net_w3;
   m_net_weight[4]=m_net_w4;
   m_net_weight[5]=m_net_w5;
   m_net_weight[6]=m_net_w6;
   m_net_weight[7]=m_net_w7;
   m_net_weight[8]=m_net_w8;
   m_net_weight[9]=m_net_w9;
}

double neuroCalcSaidaNeuron(ifeiraBuf bufIndicador, bool print=false){
    //--- variable for storing the results of working with the indicator buffer
    int err1=0;

    //--- copy data from the indicator array to the iRSI_buf dynamic array for further work with them
    err1=m_feira.GetData(0,10,bufIndicador,m_net_feira_buf_data);

    //--- in case of errors, print the relevant error message into the log file and exit the function
    if(err1<0) { Print(m_name, ": Failed to copy data from the indicator buffer :-("); return -9.0; }

    //ArrayPrint(m_net_feira_buf_data);

    // normalizando o buffer do indicador(m_net_feira_buf_data). resultado fica em m_net_inputs.
    neuroNormalizarNeuron(-1.0, 1.0, m_net_feira_buf_data, m_net_inputs );
    if( print )ArrayPrint(m_net_feira_buf_data,_Digits);
    //if( print )ArrayPrint(m_net_inputs        ,3);

    //--- store the neuron calculation result in the out variable
    double out = neuroCalculateNeuron(m_net_inputs,m_net_weight);
    //Print(m_name," [out ", out,"]");
    return out;
}

// double &desn[] --> sinais de entrada
// double &norm[] --> sinais de entrada normalizados
// limInf,limSup  --> intervalo de normalizacao
void neuroNormalizarNeuron(const double limInf, const double limSup, const double &desn[], double &norm[] ){

    double x_min=desn[ArrayMinimum(desn)]; //minimum value over the range
    double x_max=desn[ArrayMaximum(desn)]; //maximum value over the range

    //--- In the loop, fill in the array of inputs with the pre-normalized indicator values
    if((x_max-x_min)==0.0){
        ArrayFill(norm,0,ArraySize(norm),0.0);
    }else{
        for(int i=0;i<ArraySize(norm);i++){
            norm[i]=(((desn[i]-x_min)*(limSup-limInf))/(x_max-x_min)) + limInf;
        }
    }
}

//+----------------------------------------------------------------------------------------------+
//| Neuron calculation function                                                                  |
//| Combinador Linear                                                                            |
//|                                                                                              |
//| Verifique o conceito de:                                                                     |
//|   Limiar de ativacao { Θ }: Especifica qual será o patamar apropriado para que o resultado   |
//|                             produzido pelo combinador linear possa gerar um valor de disparo |
//|                             de ativacao.                                                     |
//|                                                                                              |
//|   Potencial de ativacao { u }: É o resultado obtido pela diferenca do valor produzido entre o|
//|                                combinador linear e o limiar de ativacao. Se o valor for      |
//|                                positivo, ou seja, se u ≥ 0 então o neuronio produz um        |
//|                                potencial excitatorio; caso contrario, o potencial serah      |
//|                                inibitorio.                                                   |
//+----------------------------------------------------------------------------------------------+
double neuroCalculateNeuron(double &x[],double &w[]) {
    //--- variable for storing the weighted sum of inputs
    double NET=0.0;

    //--- Using a loop we obtain the weighted sum of inputs based on the number of inputs
    for(int n=0;n<ArraySize(x);n++){
      NET+=x[n]*w[n];
    }

    //--- multiply the weighted sum of inputs by the additional coefficient
    NET*=0.08;
    //--- send the weighted sum of inputs to the activation function and return its value
    return(neuroActivateNeuron(NET));
}

//+------------------------------------------------------------------+
//|   Activation function                                            |
//|   Funcao de ativacao                                             |
//+------------------------------------------------------------------+
double neuroActivateNeuron(double x){
    //--- variable for storing the activation function results
    double Out;
    //--- sigmoid
    Out=1/(1+exp(-x));
    //--- return the activation function value
    return(Out);
}