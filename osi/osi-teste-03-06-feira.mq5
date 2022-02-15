//+------------------------------------------------------------------+
//|                                        osi-teste-03-06-feira.mq5 |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, OS Corp."
#property link      "http://www.os.org"
#property version   "3.006"

// Alteracoes em relacao a versao 02-03
// Eliminar sinais de reversao pois nao sao boons e acrescentam processamento no objeto estatistico.
// Acrescentar VWAP e Preco de Abertura da sessao

// Alteracoes em relacao a versao 02-05
// Informar volume

#include <Trade\SymbolInfo.mqh>
#include <Files\FileTxt.mqh>
#include <oslib\osc-util.mqh>
#include <oslib\os-lib.mq5>
#include <oslib\osc-estatistic2.mqh>
#include <oslib\osc-tick-util.mqh>
#include <oslib\osc\data\osc_db.mqh>

input bool   DEBUG                 = false ; // se true, grava informacoes de debug no log.
input bool   GERAR_VOLUME          = false ; // se true, gera volume baseado nos ticks. Usa em papeis que nao informam volume, tais como o DJ30.
input bool   GERAR_OFERTAS         = false ; // se true, gera ofertas baseadas nos ticks. Usa em papeis que nao informam o livro de ofertas.
input int    QTD_BAR_PROC_HIST     = 0     ; // Quantidade de barras historicas a processar. Em modo DEBUG, convem deixar este valor baixo pra nao sobrecarregar o arquivo de log.
input double BOOK_OUT              = 0     ; // Porcentagem das extremidades dos precos do book que serão desprezados.
input int    QTD_PERIOD_CALC_MEDIA = 1     ; // qtd de periodos usados no processamento estatistico.


#define LOG(txt)        if(DEBUG){Print("DEBUGINDICATOR:",__FUNCTION__,":linha ",__LINE__,":",(txt));}
//#define LOG_ONCALC      LOG("RatesTot:"+IntegerToString(  rates_total)+" PrevCalc:"+IntegerToString(  prev_calculated) );
//#define LOG_ONCALC_HIST LOG("RatesTot:"+IntegerToString(p_rates_total)+" PrevCalc:"+IntegerToString(p_prev_calculated) );

#define OSI_FEIRA_SHORT_NAME "osi-03-06-feira"

#define DEBUG_TICK     false
#define GERAR_SQL_BOOK true

//#define LOG_DEBUG_ONCALC                if(DEBUG){Print("DEBUGINDICATOR:",__FUNCTION__,":linha:",__LINE__,": ratesTot:",rates_total," prevCalc:",prev_calculated);}
//#define LOG_DEBUG_RESULT_REGISTRO_BOOK  if(DEBUG){Print("DEBUGINDICATOR:Resultado registro book "+m_symb.Name()+":", m_tembook);}

#property description "Indicador que considera a bolsa como uma feira, com barracas"
#property description "de vendedores e compradores."
//#property description "---------------"
#property description "osi-02-01-feira: Passa a acumular por quantidade de periodos. As versões 01-0X acumulavam por quantidade de ticks."
#property description "osi-02-02-feira: Sinais de tendencia e reversao baseados no canal das ofertas."
#property description "osi-02-03-feira: Expor inclinacoes das medias do book e dos precos."
//#property description "osi-02-04-feira: Eliminar sinais de reversao. Acrescentar VWAP e PRECO DE ABERTURA"
//#property description "osi-02-05-feira: Trocar ??? por dados do candle no periodo sendo processado."
#property description "osi-02-06-feira: Informar volume."
#property description "osi-03-06-feira: Tirar tranqueiras do 02-06 pra operar em producao."
//#property description "---------------"

#property indicator_chart_window
#property indicator_buffers 28
#property indicator_plots   28

//---- plotar linha com o preco medio de vendas
#property indicator_label1  "pm_sell"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrFireBrick
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3

//---- plotar linha com preco medio de compras
#property indicator_label2  "pm_buy"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrMediumBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  3

//---- plotar linha com o preco medio de ofertas de venda (ask)
#property indicator_label3  "pm_ask"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrMagenta
#property indicator_style3  STYLE_SOLID
#property indicator_width3  3

//---- plotar linha com o preco medio de ofertas de compra (bid)
#property indicator_label4  "pm_bid"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrDeepSkyBlue
#property indicator_style4  STYLE_SOLID
#property indicator_width4  3

//---- plotar seta forca ask
#property indicator_label5  "sig_ask"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrMagenta
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1

//---- plotar seta forca bid
#property indicator_label6  "sig_bid"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrDeepSkyBlue
#property indicator_style6  STYLE_SOLID
#property indicator_width6  1

//---- plotar seta forca buy
#property indicator_label7  "high"
#property indicator_type7   DRAW_ARROW
#property indicator_color7  clrMediumBlue
#property indicator_style7  STYLE_SOLID
#property indicator_width7  1

//---- plotar seta forca sel
#property indicator_label8  "low"
#property indicator_type8   DRAW_ARROW
#property indicator_color8  clrFireBrick
#property indicator_style8  STYLE_SOLID
#property indicator_width8  1

//---- plotar seta forca up1
#property indicator_label9  "up1"
#property indicator_type9   DRAW_ARROW
#property indicator_color9  clrDeepSkyBlue
#property indicator_style9  STYLE_SOLID
#property indicator_width9  3

//---- plotar seta forca up2
#property indicator_label10  "up2"
#property indicator_type10   DRAW_ARROW
#property indicator_color10  clrDeepSkyBlue
#property indicator_style10  STYLE_SOLID
#property indicator_width10  3

//---- plotar seta forca down1
#property indicator_label11  "down1"
#property indicator_type11   DRAW_ARROW
#property indicator_color11  clrFireBrick
#property indicator_style11  STYLE_SOLID
#property indicator_width11  3

//---- plotar seta forca down2
#property indicator_label12  "down2"
#property indicator_type12   DRAW_ARROW
#property indicator_color12  clrFireBrick
#property indicator_style12  STYLE_SOLID
#property indicator_width12  3

//---- plotar linha preco medio do trade
#property indicator_label13  "pm_trade"
#property indicator_type13   DRAW_LINE
#property indicator_color13  clrDarkViolet  // clrDarkOrchid
#property indicator_style13  STYLE_DASH
#property indicator_width13  3

//---- plotar linha preco medio do book de ofertas
#property indicator_label14  "pm_book"
#property indicator_type14   DRAW_LINE
#property indicator_color14  clrGold //clrDarkOrange //clrOrangeRed
#property indicator_style14  STYLE_DASH
#property indicator_width14  3

//---- plotar seta inclinacao do trade para cima
#property indicator_label15  "sinal_incl_alta"
#property indicator_type15   DRAW_ARROW
#property indicator_color15  clrMediumBlue
#property indicator_style15  STYLE_SOLID
#property indicator_width15  1

//---- plotar seta inclinacao do trade para baixo
#property indicator_label16  "sinal_incl_baixa"
#property indicator_type16   DRAW_ARROW
#property indicator_color16  clrFireBrick
#property indicator_style16  STYLE_SOLID
#property indicator_width16  1

//---- plotar sinal de comprometimento para aumentar o preco
#property indicator_label17  "sinal_comp_alta"
#property indicator_type17   DRAW_ARROW
#property indicator_color17  clrMediumBlue
#property indicator_style17  STYLE_SOLID
#property indicator_width17  1

//---- plotar sinal de comprometimento para baixar o preco
#property indicator_label18  "sinal_comp_baixa"
#property indicator_type18   DRAW_ARROW
#property indicator_color18  clrFireBrick
#property indicator_style18  STYLE_SOLID
#property indicator_width18  1

//---- armazenar dados da tendencia
#property indicator_label19  "tend"
#property indicator_type19   DRAW_NONE
//#property indicator_color19  clrFireBrick
//#property indicator_style19  STYLE_SOLID
//#property indicator_width19  1

//---- armazenar dados da reversao
#property indicator_label20  "reve"
#property indicator_type20   DRAW_NONE
//#property indicator_color19  clrFireBrick
//#property indicator_style19  STYLE_SOLID
//#property indicator_width19  1

//---- armazenar inclinacao da linha de venda media
#property indicator_label21  "incl_sel"
#property indicator_type21   DRAW_NONE
//#property indicator_color21  clrFireBrick
//#property indicator_style21  STYLE_SOLID
//#property indicator_width21  1

//---- armazenar inclinacao da linha de compra media
#property indicator_label22  "incl_buy"
#property indicator_type22   DRAW_NONE
//#property indicator_color22  clrFireBrick
//#property indicator_style22  STYLE_SOLID
//#property indicator_width22  1

//---- armazenar inclinacao da linha de media de trades
#property indicator_label23  "incl_trade"
#property indicator_type23   DRAW_NONE

//---- armazenar inclinacao da linha oferts de venda
#property indicator_label24  "incl_ask"
#property indicator_type24   DRAW_NONE

//---- armazenar inclinacao da linha de ofertas de compra
#property indicator_label25  "incl_bid"
#property indicator_type25   DRAW_NONE

//---- armazenar inclinacao da linha de ofertas gerais
#property indicator_label26  "incl_bok"
#property indicator_type26   DRAW_NONE

//---- armazenar volume
#property indicator_label27  "vol"
#property indicator_type27   DRAW_NONE

//--- buffers do indicador
double m_bufPsel            []; // preco medio de compras                         :1
double m_bufPbuy            []; // preco medio de vendas                          :2
double m_bufPask            []; // preco medio de ofertas de venda                :3
double m_bufPbid            []; // preco medio de ofertas de compra               :4
double m_bufPaskArrow       []; // forca do preco medio de ofertas de venda       :5
double m_bufPbidArrow       []; // forca do preco medio de ofertas de compra      :6
double m_bufPHigArrow       []; // maior preco negociado no periodo               :7
double m_bufPLowArrow       []; // menor preco negociado no periodo               :8
double m_bufPup1Arrow       []; // forca acima 1                                  :9
double m_bufPup2Arrow       []; // forca acima 2                                  :10
double m_bufPdw1Arrow       []; // forca acima 1                                  :11
double m_bufPdw2Arrow       []; // forca acima 2                                  :12
double m_bufPtra            []; // preco medio de trades (buy/sel)                :13
double m_bufPbok            []; // preco medio de ofertas(ask/bid)                :14
double m_bufSinalCompUpArrow[]; // sinal de comprometimento de compra(up)         :15
double m_bufSinalCompDwArrow[]; // sinal de comprometimento de venda (dw)         :16
double m_bufSinalInclUpArrow[]; // sinal de inclinacao para cima(up)              :17
double m_bufSinalInclDwArrow[]; // sinal de inclinacao para baixo(dw)             :18
//double m_bufTend          []; // tendencia                                      :19
//double m_bufReve          []; // reversao                                       :20
double m_bufDesbN0          []; // debalanceamento na primeira fila de ofertas    :19
double m_bufDesbN1          []; // debalanceamento na segunda  fila de ofertas    :20
double m_bufInclSel         []; // inclinacao do preco medio de compras           :21
double m_bufInclBuy         []; // inclinacao do preco medio de vendas            :22
double m_bufInclTra         []; // inclinacao do preco medio de trades (buy/sel)  :23
double m_bufInclAsk         []; // inclinacao do preco medio de ofertas de venda  :24
double m_bufInclBid         []; // inclinacao do preco medio de ofertas de compra :25
double m_bufInclBok         []; // inclinacao do preco medio de ofertas(ask/bid)  :26
double m_bufVol             []; // volume                                         :27

// variaveis para controle do livro de ofertas
//MqlBookInfo m_book[];
double      m_pmask      = 0;
double      m_pmbid      = 0;
double      m_pmbok      = 0; //preco medio do book
uint        m_qtdWinAsk  = 0;
uint        m_qtdWinBid  = 0;
uint        m_qtdEmpate  = 0;
double      m_dask       = 0;
double      m_dbid       = 0;
bool        m_tembook    = false;
uint        m_id_oferta  = 0;

// variaveis para controle dos ticks
osc_estatistic2 m_minion   ; // estatisticas de ticks e book de ofertas
osc_tick_util   m_tick_util; // para simular ticks de trade em bolsas que nao informam last/volume.
CSymbolInfo     m_symb     ;
bool            m_prochist ; // para nao reprocessar o historico sempre que mudar de barra;

double m_vbuy    = 0;
double m_vsel    = 0;
double m_tickvol = 0;

// apresentacao de depuracao
string m_dom_txt     ;
string m_dom_previsao;
string m_tick_txt    ;

// variaveis para controle do arquivo de log
int  m_log_book         ; // descarreganto book de ofetas em arquivo de log (debug)
int  m_log_tick         ; // descarreganto ticks         em arquivo de log (debug)

//=================================================================================================
// Indicador demanda e oferta...
// Oferta media ask(book) maior que demanda buy(tick) médio --> força pra cima
// Oferta media bid(book) menor que demanda sel(tick) médio --> força pra baixo
//
// Oferta media ask(book) maior          que demanda buy(tick) médio e
// Oferta media bid(book) maior ou igual a   demanda sel(tick) médio --> força pra cima  maior ainda
//
// Oferta media bid(book) menor          que demanda sel(tick) médio e
// Oferta media ask(book) menor ou igual a   demanda buy(tick) médio --> força pra baixo maior ainda
//=================================================================================================
// variaveis para controle das forças liquidas
double m_ofertaAsk = 0; // oferta  media ask (oferta  de venda )...
double m_ofertaBid = 0; // oferta  media bid (oferta  de compra)...
double m_demandBuy = 0; // demanda media buy (demanda de compra)...
double m_demandSel = 0; // demanda media sel (demanda de venda )...

bool m_forcaAcima1 ;// Oferta media ask(book) maior que demanda buy(tick) médio --> força pra cima
bool m_forcaAbaix1 ;// Oferta media bid(book) menor que demanda sel(tick) médio --> força pra baixo
bool m_forcaAcima2 ;// força pra cima  maior ainda
bool m_forcaAbaix2 ;// força pra baixo maior ainda
//=================================================================================================

uint       m_qtd_sec_periodo;// qtd de segundos que tem o periodo grafico atual.
uint       m_sec_barra   ; // segundos na barra atual
datetime   m_sec_barraAnt; // segundos na barra atual
datetime   m_sec_barraAtu; // segundos na barra atual
osc_db     m_mydb;
//+------------------------------------------------------------------+
//| Função de inicialização do indicador customizado                 |
//+------------------------------------------------------------------+
int OnInit() {
   //PRINT_DEBUG_INIT_INI
   LOG("=======================================");
   m_symb.Name        ( Symbol() );
   m_symb.Refresh     ();
   m_symb.RefreshRates();

   Print(OSI_FEIRA_SHORT_NAME," [",__FUNCTION__,"]","[DEBUG                =", DEBUG                , "]");
   Print(OSI_FEIRA_SHORT_NAME," [",__FUNCTION__,"]","[GERAR_VOLUME         =", GERAR_VOLUME         , "]");
   Print(OSI_FEIRA_SHORT_NAME," [",__FUNCTION__,"]","[GERAR_OFERTAS        =", GERAR_OFERTAS        , "]");
   Print(OSI_FEIRA_SHORT_NAME," [",__FUNCTION__,"]","[QTD_BAR_PROC_HIST    =", QTD_BAR_PROC_HIST    , "]");
   Print(OSI_FEIRA_SHORT_NAME," [",__FUNCTION__,"]","[BOOK_OUT             =", BOOK_OUT             , "]");
   Print(OSI_FEIRA_SHORT_NAME," [",__FUNCTION__,"]","[QTD_PERIOD_CALC_MEDIA=", QTD_PERIOD_CALC_MEDIA, "]");
   Print(OSI_FEIRA_SHORT_NAME," [",__FUNCTION__,"]","[GERAR_SQL_BOOK       =", GERAR_SQL_BOOK       , "]");
   
   

   m_qtd_sec_periodo = PeriodSeconds();

   m_tembook = MarketBookAdd( m_symb.Name() );
   LOG("Resultado registro book "+m_symb.Name()+":"+IntegerToString(m_tembook) );

   if ( !m_tembook || GERAR_OFERTAS ){
     Print("DOM INDISPONIVEL ou GERACAO DE OFERTAS ativada para: "+m_symb.Name()+". Verifique!! :-(");
     m_tembook     = false; // forcando um book mesmo que a corretora nao disponibilize.
     
     if( GERAR_VOLUME ){
       Print("Simulacao de VOLUME ativada! Seguiremos gerando ofertas e demandas a partir dos Ticks :-)" );
     }else if(GERAR_OFERTAS){
       Print("Simulacao de OFERTAS ativada! Seguiremos gerando ofertas e demandas a partir dos Ticks :-)" );
       m_tembook = false;
     }else{
      //Print("Para processar sem book de ofertas disponibilizado pela corretora, ative o parametro GERAR_VOLUME e serah feita a simulacao do book.");
        Print("Book sendo simulado com tamanho do canal igual a 88.");
        //return (INIT_FAILED);
     }
   }else{Print("Book de ofertas disponibilizado pela corretora :-)");};
   //m_tembook = false; // soh pra testar os minicontratos.

   setAsSeries(true);

   Print("Definindo buffers do indicador...");
   SetIndexBuffer(0 ,m_bufPsel       , INDICATOR_DATA  );
   SetIndexBuffer(1 ,m_bufPbuy       , INDICATOR_DATA  );
   SetIndexBuffer(2 ,m_bufPask       , INDICATOR_DATA  );
   SetIndexBuffer(3 ,m_bufPbid       , INDICATOR_DATA  );
   SetIndexBuffer(4 ,m_bufPaskArrow  , INDICATOR_DATA  );
   SetIndexBuffer(5 ,m_bufPbidArrow  , INDICATOR_DATA  );
   SetIndexBuffer(6 ,m_bufPHigArrow  , INDICATOR_DATA  );
   SetIndexBuffer(7 ,m_bufPLowArrow  , INDICATOR_DATA  );
   SetIndexBuffer(8 ,m_bufPup1Arrow  , INDICATOR_DATA  );
   SetIndexBuffer(9 ,m_bufPup2Arrow  , INDICATOR_DATA  );
   SetIndexBuffer(10,m_bufPdw1Arrow  , INDICATOR_DATA  );
   SetIndexBuffer(11,m_bufPdw2Arrow  , INDICATOR_DATA  );
   SetIndexBuffer(12,m_bufPtra       , INDICATOR_DATA  );
   SetIndexBuffer(13,m_bufPbok       , INDICATOR_DATA  );
   SetIndexBuffer(14,m_bufSinalCompUpArrow, INDICATOR_DATA  );
   SetIndexBuffer(15,m_bufSinalCompDwArrow, INDICATOR_DATA  );
   SetIndexBuffer(16,m_bufSinalInclUpArrow, INDICATOR_DATA  );
   SetIndexBuffer(17,m_bufSinalInclDwArrow, INDICATOR_DATA  );
   SetIndexBuffer(18,m_bufDesbN0     , INDICATOR_DATA  );
   SetIndexBuffer(19,m_bufDesbN1     , INDICATOR_DATA  );
   SetIndexBuffer(20,m_bufInclSel    , INDICATOR_DATA  );
   SetIndexBuffer(21,m_bufInclBuy    , INDICATOR_DATA  );
   SetIndexBuffer(22,m_bufInclTra    , INDICATOR_DATA  );
   SetIndexBuffer(23,m_bufInclAsk    , INDICATOR_DATA  );
   SetIndexBuffer(24,m_bufInclBid    , INDICATOR_DATA  );
   SetIndexBuffer(25,m_bufInclBok    , INDICATOR_DATA  );
   SetIndexBuffer(26,m_bufVol        , INDICATOR_DATA  );

//--- Definir um valor vazio
   PlotIndexSetDouble(0 ,PLOT_EMPTY_VALUE,0); // m_bufPsel
   PlotIndexSetDouble(1 ,PLOT_EMPTY_VALUE,0); // m_bufPbuy
   PlotIndexSetDouble(2 ,PLOT_EMPTY_VALUE,0); // m_bufPask
   PlotIndexSetDouble(3 ,PLOT_EMPTY_VALUE,0); // m_bufPbid
   PlotIndexSetDouble(4 ,PLOT_EMPTY_VALUE,0); // m_bufPaskArrow
   PlotIndexSetDouble(5 ,PLOT_EMPTY_VALUE,0); // m_bufPbidArrow
   PlotIndexSetDouble(6 ,PLOT_EMPTY_VALUE,0); // m_bufPHigArrow
   PlotIndexSetDouble(7 ,PLOT_EMPTY_VALUE,0); // m_bufPLowArrow
   PlotIndexSetDouble(8 ,PLOT_EMPTY_VALUE,0); // m_bufPup1Arrow
   PlotIndexSetDouble(9 ,PLOT_EMPTY_VALUE,0); // m_bufPup2Arrow
   PlotIndexSetDouble(10,PLOT_EMPTY_VALUE,0); // m_bufPdw1Arrow
   PlotIndexSetDouble(11,PLOT_EMPTY_VALUE,0); // m_bufPdw2Arrow
   PlotIndexSetDouble(12,PLOT_EMPTY_VALUE,0); // m_bufPtra
   PlotIndexSetDouble(13,PLOT_EMPTY_VALUE,0); // m_bufPbok
   PlotIndexSetDouble(14,PLOT_EMPTY_VALUE,0); // m_bufSinalCompUpArrow
   PlotIndexSetDouble(15,PLOT_EMPTY_VALUE,0); // m_bufSinalCompDwArrow
   PlotIndexSetDouble(16,PLOT_EMPTY_VALUE,0); // m_bufSinalInclUpArrow
   PlotIndexSetDouble(17,PLOT_EMPTY_VALUE,0); // m_bufSinalInclDwArrow
//   PlotIndexSetDouble(18,PLOT_EMPTY_VALUE,0); // m_bufDesbN0  nao eh plotado
//   PlotIndexSetDouble(19,PLOT_EMPTY_VALUE,0); // m_bufDesbN1  nao eh plotado
//   PlotIndexSetDouble(20,PLOT_EMPTY_VALUE,0); // m_bufInclSel nao eh plotado
//   PlotIndexSetDouble(21,PLOT_EMPTY_VALUE,0); // m_bufInclBuy nao eh plotado
//   PlotIndexSetDouble(22,PLOT_EMPTY_VALUE,0); // m_bufInclTra nao eh plotado
//   PlotIndexSetDouble(23,PLOT_EMPTY_VALUE,0); // m_bufInclAsk nao eh plotado
//   PlotIndexSetDouble(24,PLOT_EMPTY_VALUE,0); // m_bufInclBid nao eh plotado
//   PlotIndexSetDouble(25,PLOT_EMPTY_VALUE,0); // m_bufInclBok nao eh plotado
//   PlotIndexSetDouble(26,PLOT_EMPTY_VALUE,0); // m_bufVol     nao eh plotado

//--- Definir o código símbolo para desenho em PLOT_ARROW
   //PlotIndexSetInteger(4,PLOT_ARROW,225);  //ask setinha rosa clara acima  da linha ask
   //PlotIndexSetInteger(5,PLOT_ARROW,226);  //bid setinha azul clara abaixo da linha bid

   PlotIndexSetInteger(6,PLOT_ARROW,231);  //high setinha horizontal
   PlotIndexSetInteger(7,PLOT_ARROW,231);  //low  setinha horizontal
   //PlotIndexSetInteger(6,PLOT_ARROW,159);  //high bolinha 
   //PlotIndexSetInteger(7,PLOT_ARROW,159);  //low  bolinha

   //PlotIndexSetInteger(8 ,PLOT_ARROW,217);//241);  //up1 217
   //PlotIndexSetInteger(9 ,PLOT_ARROW,217);//241);  //up2 217
   //PlotIndexSetInteger(10,PLOT_ARROW,218);//242);  //dw1 218
   //PlotIndexSetInteger(11,PLOT_ARROW,218);//242);  //dw2 218

 //PlotIndexSetInteger(14,PLOT_ARROW,236); //tup
 //PlotIndexSetInteger(15,PLOT_ARROW,238); //tdw
   PlotIndexSetInteger(14,PLOT_ARROW,77 ); //compromisso na compra (agressoes de compra mais fortes que as ofertas de venda ). 77 eh a bombinha.
   PlotIndexSetInteger(15,PLOT_ARROW,77 ); //compromisso na venda  (agressoes de venda  mais fortes que as ofertas de compra). 77 eh a bombinha.
 
 //PlotIndexSetInteger(16,PLOT_ARROW,235); //rup
 //PlotIndexSetInteger(17,PLOT_ARROW,237); //rdw
   PlotIndexSetInteger(16,PLOT_ARROW,228); //rup
   PlotIndexSetInteger(17,PLOT_ARROW,230); //rdw


//--- Definindo o deslocamento vertical das setas em pixels...
   //PlotIndexSetInteger(4,PLOT_ARROW_SHIFT,-10); // seta ask
   //PlotIndexSetInteger(5,PLOT_ARROW_SHIFT,+10); // seta bid
   PlotIndexSetInteger(6,PLOT_ARROW_SHIFT,-0); // seta high
   PlotIndexSetInteger(7,PLOT_ARROW_SHIFT,+0); // seta low
   //PlotIndexSetInteger(6,PLOT_SHIFT,1); // seta high
   //PlotIndexSetInteger(7,PLOT_SHIFT,1); // seta low

   PlotIndexSetInteger(8 ,PLOT_ARROW_SHIFT,-20); //up1
   PlotIndexSetInteger(9 ,PLOT_ARROW_SHIFT,-30); //up2
   PlotIndexSetInteger(10,PLOT_ARROW_SHIFT,+20); //dw1
   PlotIndexSetInteger(11,PLOT_ARROW_SHIFT,+30); //dw2

   PlotIndexSetInteger(14,PLOT_ARROW_SHIFT,-40); //seta compromisso na compra up
   PlotIndexSetInteger(15,PLOT_ARROW_SHIFT,+40); //seta compromisso na venda  dw
   PlotIndexSetInteger(16,PLOT_ARROW_SHIFT,-50); //seta inclinacao  dw
   PlotIndexSetInteger(17,PLOT_ARROW_SHIFT,+50); //seta inclinacao  up

//---- o nome do indicador a ser exibido na DataWindow e na subjanela
   IndicatorSetString(INDICATOR_SHORTNAME,OSI_FEIRA_SHORT_NAME);

//--- ticks
 //m_minion.setModoHibrido(GERAR_VOLUME)    ; //se opcao eh true, gera volume baseado nos ticks. Usado em papeis que nao informam volume.
   m_minion.initialize(QTD_PERIOD_CALC_MEDIA*m_qtd_sec_periodo); // quantidade de segundos que serao usados no calculo das medias.
   m_minion.setSymbolStr( m_symb.Name() );
   m_minion.setFlagGerarSqlInsertBook(GERAR_SQL_BOOK); // definindo se gera sqlinsert do book no log do terminal.

   
   m_prochist = false; // indica se deve reprocessar o historico.
   m_tick_util.setTickSize(m_symb.TickSize(), m_symb.Digits() );

//--- debug
   if( DEBUG ){
      string dt = TimeToString( TimeCurrent(),TIME_DATE|TIME_MINUTES|TIME_SECONDS );
      StringReplace ( dt, ".", ""  );
      StringReplace ( dt, ":", ""  );
      StringReplace ( dt, " ", "_" );
      openLogFileBook(OSI_FEIRA_SHORT_NAME + "_" + m_symb.Name() + IntegerToString(_Period) + "_" + dt + "_book.csv" );
      openLogFileTick(OSI_FEIRA_SHORT_NAME + "_" + m_symb.Name() + IntegerToString(_Period) + "_" + dt + "_tick.csv" );
      //if( !m_mydb.create_or_open_mydb() ) return (INIT_FAILED);
   }

   if( DEBUG_TICK ){
      string dt = TimeToString( TimeCurrent(),TIME_DATE|TIME_MINUTES|TIME_SECONDS );
      StringReplace ( dt, ".", ""  );
      StringReplace ( dt, ":", ""  );
      StringReplace ( dt, " ", "_" );
      openLogFileTick(OSI_FEIRA_SHORT_NAME + "_" + m_symb.Name() + IntegerToString(_Period) + "_" + dt + "_tick.csv" );
   }

//---
   return(INIT_SUCCEEDED);
}


// transforma o tick informativo em tick de trade. Usamos em mercados que nao informam volume ou last nos ticks.
void normalizar2trade(MqlTick& tick){
   if(GERAR_VOLUME){
      writeDetLogTick( "ANT" );
      m_tick_util.normalizar2trade(tick);
      writeDetLogTick( "POS" );
   }
}

void OnDeinit(const int i){
  LOG("Executando OnDeinit...");
  MarketBookRelease( m_symb.Name() );
  delete(&m_symb  );
  //delete(&m_minion);
  //delete(&m_book);
  FileClose( m_log_book );
  FileClose( m_log_tick );
  //m_mydb.close();
  LOG("OnDeinit Finalizado!");
}

//+------------------------------------------------------------------+
//| Atualizando os volumes de bid e oferta                           |
//+------------------------------------------------------------------+
int OnCalculate(const int        rates_total,
                const int        prev_calculated,
                const datetime&  time[],
                const double&    open[],
                const double&    high[],
                const double&    low[],
                const double&    close[],
                const long&      tick_volume[],
                const long&      volume[]     ,
                const int&       spread[]     ) {

    //===============================================================================================
    // Processamentos dos ticks (demanda)
    //===============================================================================================
    //m_minion.refresh();
    //m_minion.logWrite( "PC:"+IntegerToString(prev_calculated) + "/RT:" + IntegerToString(rates_total) );
    //m_lineBuffer1[0] = (double)m_minion.getVolSell0();

    MqlTick tick   ;
    //double dxSel   = 0;
    //double dxBuy   = 0;
    //double medTick = 0;
    //---------
  //LOG_ONCALC;
    if( !m_prochist ){ // para nao reprocessar a ultima barra sempre que mudar de barra.
         setAsSeries(false);
         doOnCalculateHistorico(rates_total, prev_calculated,time);
         setAsSeries(true);
    }
  //LOG_ONCALC;

    //===============================================================================================
    // Processamento o tick da barra atual...
    //===============================================================================================
    //processando o evento atual...
    SymbolInfoTick(_Symbol,tick);// um tick por chamada a oncalculate
    normalizar2trade(tick); // soh normaliza se a opcao GERAR_VOLUME estiver ativa
    m_minion.addTick(tick);
    if( m_tembook ){
        doOnBookEvent(_Symbol); // processando o book somente uma vez a cada chamada a OnCalculate.
                                // Obs: OnBookEvent deve estar comentada para que nao seja processado o
                                //      evento do book.
    }else{
        //Nao tem book, simulamos com os ticks...
        doOnBookEvent(tick);
    }

    //dxSel             = m_minion.getDxSel();
    //dxBuy             = m_minion.getDxBuy();
    
    m_bufDesbN0   [0] = m_minion.getDesbalanceamentoUP0();
    m_bufDesbN1   [0] = m_minion.getDesbalanceamentoUP1();

    m_bufInclBuy  [0] = m_minion.getInclinacaoTradeBuy();
    m_bufInclSel  [0] = m_minion.getInclinacaoTradeSel();
    m_bufInclTra  [0] = m_minion.getInclinacaoTrade();

    m_bufPbuy     [0] = m_minion.getPrecoMedTradeBuy();
    m_bufPsel     [0] = m_minion.getPrecoMedTradeSel();
    m_bufPtra     [0] = m_minion.getPrecoMedTrade();
    m_bufPHigArrow[0] = m_minion.getTradeHigh();
    m_bufPLowArrow[0] = m_minion.getTradeLow();
    m_bufVol      [0] = m_minion.getVolTrade();

   //calcSinalReversao (m_bufPtra, high, low);
   // calculando tendencia com minion...
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low , true);   
   calcSinalInclinacao(0);
   calcSinalComprometimento(0, high[0], low[0]);
 //calcSinalTendenciaReversao(0);
   //===============================================================================================

    // Nao tem book, simulamos com os ticks...
    //if( !m_tembook ){ doOnBookEvent(tick); }

    // processando book no oncalculate...
    //if( OSI_FEIRA_BOOK_ON_CALCULATE ) doOnBookEvent(_Symbol);

     //===============================================================================================
     // plotando as ofertas do book na barra atual, e tambem salvando as inclinacoes...
     //===============================================================================================
    if( rates_total >= prev_calculated && m_pmask>0 && m_pmbid>0 && m_pmbok>0 ){

        m_bufDesbN0 [0] = m_minion.getDesbalanceamentoUP0();
        m_bufDesbN1 [0] = m_minion.getDesbalanceamentoUP1();

        m_bufVol    [0] = m_minion.getVolTrade();
        
        m_bufInclAsk[0] = m_minion.getInclinacaoBookAsk();
        m_bufInclBid[0] = m_minion.getInclinacaoBookBid();
        m_bufInclBok[0] = m_minion.getInclinacaoBook   ();

        m_bufPask   [0] = m_minion.getPrecoMedBookAsk();
        m_bufPbid   [0] = m_minion.getPrecoMedBookBid();
        m_bufPbok   [0] = m_minion.getPrecoMedBook   ();
        //calcSinalComprometimento(0, high[0], low[0]);

        if( m_dbid >  m_dask ){ m_bufPbidArrow[0] = m_minion.getPrecoMedBookBid(); m_bufPaskArrow[0] = 0; }
        if( m_dbid <  m_dask ){ m_bufPaskArrow[0] = m_minion.getPrecoMedBookAsk(); m_bufPbidArrow[0] = 0; }
        if( m_dbid == m_dask ){ m_bufPaskArrow[0] = 0                            ; m_bufPbidArrow[0] = 0; }

        //=================================================================================================
        // Indicador demanda e oferta...
        // Oferta media ask(book) maior[menor] que demanda buy(tick) médio --> força pra cima
        // Oferta media bid(book) menor que demanda sel(tick) médio --> força pra baixo
        //
        // Oferta media ask(book) maior          que demanda buy(tick) médio e
        // Oferta media bid(book) maior ou igual a   demanda sel(tick) médio --> força pra cima  maior ainda
        //
        // Oferta media bid(book) menor          que demanda sel(tick) médio e
        // Oferta media ask(book) menor ou igual a   demanda buy(tick) médio --> força pra baixo maior ainda
        //=================================================================================================
        m_ofertaAsk   = m_bufPask[0]; // oferta  media ask (oferta  de venda )...
        m_ofertaBid   = m_bufPbid[0]; // oferta  media bid (oferta  de compra)...
        m_demandBuy   = m_bufPbuy[0]; // demanda media buy (demanda de compra)...
        m_demandSel   = m_bufPsel[0]; // demanda media sel (demanda de venda )...

        m_forcaAcima1 = (m_ofertaAsk < m_demandBuy);// Oferta media ask(book) maior[menor] que demanda buy(tick) médio --> força pra cima
        m_forcaAbaix1 = (m_ofertaBid > m_demandSel);// Oferta media bid(book) menor[maior] que demanda sel(tick) médio --> força pra baixo
        m_forcaAcima2 = ( m_forcaAcima1 && (m_ofertaBid < m_demandSel) );// força pra cima  maior ainda
        m_forcaAbaix2 = ( m_forcaAbaix1 && (m_ofertaAsk > m_demandBuy) );// força pra baixo maior ainda

        m_bufPup1Arrow[0] = m_forcaAcima1 ? m_ofertaAsk : 0;
        m_bufPup2Arrow[0] = m_forcaAcima2 ? m_ofertaAsk : 0;
        m_bufPdw1Arrow[0] = m_forcaAbaix1 ? m_ofertaBid : 0;
        m_bufPdw2Arrow[0] = m_forcaAbaix2 ? m_ofertaBid : 0;

      //calcSinalTendencia(m_bufPtra, high, low); // calculando tendencia sem o minion...
      //   calcSinalReversao (m_bufPtra, high, low);
      //   calcSinalTendencia(); // calculando tendencia com minion...
      //   m_bufPup1Arrow[0] = m_tendencia_acima    ? m_ofertaAsk : 0;
      //   m_bufPup2Arrow[0] = m_reversao_vai_subir ? m_ofertaAsk : 0;
      //   m_bufPdw1Arrow[0] = m_tendencia_abaixo   ? m_ofertaBid : 0;
      //   m_bufPdw2Arrow[0] = m_reversao_vai_cair  ? m_ofertaBid : 0;
     }

     // mudou a barra, entao verificamos se eh necessario alterar o tamanho dos vetores de acumulacao de medias...
     //if( rates_total > prev_calculated ){ m_minion.checkResize(0.3); }

     //===============================================================================================
     calcTempoBarraAtual(time); // segundos na barra atual...
     //===============================================================================================
     // Imprimindo dados de depuracao...
     //===============================================================================================
     //imprimirComment();

     return(rates_total);
}

/*
void calcSinalReversao( const double& vpm[], const double& vpmax[], const double& vpmin[] ){

   double acima  = 0;
   double abaixo = 0;
   double ant    = 0;
   double atu    = 0;

   ArraySetAsSeries(vpm  ,true);
   ArraySetAsSeries(vpmax,true);
   ArraySetAsSeries(vpmin,true);

   //analisando as barras do quadrante anterior...
   acima  = calcPrecoAcima(vpm[2],vpmax[2],vpmin[2]);
   acima += calcPrecoAcima(vpm[1],vpmax[1],vpmin[1]);

   abaixo  = calcPrecoAbaixo(vpm[2],vpmax[2],vpmin[2]);
   abaixo += calcPrecoAbaixo(vpm[1],vpmax[1],vpmin[1]);

   ant = acima-abaixo; // se ant for negativo, a anterior era de baixa;

   //analisando as barras do quadrante anterior...
   acima  = calcPrecoAcima(vpm[1],vpmax[1],vpmin[1]);
   acima += calcPrecoAcima(vpm[0],vpmax[0],vpmin[0]);

   abaixo  = calcPrecoAbaixo(vpm[1],vpmax[1],vpmin[1]);
   abaixo += calcPrecoAbaixo(vpm[0],vpmax[0],vpmin[0]);

   atu     = acima-abaixo; // se atu for negativo, a anterior era de baixa;

   m_reversao_vai_cair =0;
   m_reversao_vai_subir=0;
   //m_tendencia_acima   =0;
   //m_tendencia_abaixo  =0;

   if( ant>0 && atu<0  ){ m_reversao_vai_cair  = atu; }
   if( ant<0 && atu>0  ){ m_reversao_vai_subir = atu; }
   //if( ant>0 && atu>0  ){ m_tendencia_acima    = atu; }
   //if( ant<0 && atu<0  ){ m_tendencia_abaixo   = atu; }
}
*/

/*
double m_tendencia_acima    = 0;
double m_tendencia_abaixo   = 0;
double m_reversao_vai_cair  = 0;
double m_reversao_vai_subir = 0;
void calcSinalTendenciaReversao(int i){
   // zerando os buffers e as variaveis de tendencia e reversao...
   zerarBufTendenciaReversao(i);
   m_tendencia_acima=0; m_tendencia_abaixo=0; m_reversao_vai_subir=0;m_reversao_vai_cair=0;

   // definindo a tendencia
   m_bufTend[i]     = m_minion.getTendencia();
   double tendencia = m_minion.getTendencia();
   if     (tendencia>0){ m_tendencia_acima =tendencia; m_bufSinalCompUpArrow[i] = m_minion.getPrecoMedTrade()+tendencia; }
   else if(tendencia<0){ m_tendencia_abaixo=tendencia; m_bufSinalCompDwArrow[i] = m_minion.getPrecoMedTrade()+tendencia; }

   // definindo a reversao...
   //m_bufReve[i]    = m_minion.getReversao();
   //double reversao = m_minion.getReversao();
   //if     (tendencia<0 && reversao>0 ){ m_reversao_vai_subir=reversao; m_bufSinalInclUpArrow[i] = m_minion.getPrecoMedTrade()+reversao;}
   //else if(tendencia>0 && reversao<0 ){ m_reversao_vai_cair =reversao; m_bufSinalInclDwArrow[i] = m_minion.getPrecoMedTrade()+reversao;}
   
   // temporariamente usamos o buffer de reversao para apresentar a inclinacao
   //if(m_minion.getInclinacaoTrade() >  0.05 ){m_bufSinalInclUpArrow[i]= m_minion.getPrecoMedTrade(); m_bufSinalInclDwArrow[i]= 0                         ;}else{
   //if(m_minion.getInclinacaoTrade() < -0.05 ){m_bufSinalInclUpArrow[i]= 0                          ; m_bufSinalInclDwArrow[i]=m_minion.getPrecoMedTrade();}else{
   //                                           m_bufSinalInclUpArrow[i]= 0                          ; m_bufSinalInclDwArrow[i]=0                          ;}}   
}
*/
// O sinal de comprometimento indica provaveis pontos de compromisso institucional.
// Sao pontos em que o preco maximo eh maior que o preco medio de ofertas. Eh calculado assim:
// Em uma vela de alta , com inclinacao positiva, o preco maximo da vela eh maior ou igual a media das ofertas de venda  (ask).
// Em uma vela de baixa, com inclinacao negativa, o preco minimo da vela eh menor ou igual a media das ofertas de compra (bid).
// Como a forca necessaria para conseguir ultrapassar a as media de ofertas eh alta, espera-se um retorno do preco nas velas seguintes.
// Nao eh necessario que o retorno seja uma reversao, embora seja possivel, mas ha boa propabilidade de um retorno do preco mesmo que
// nao aconteca a reversao. 
void calcSinalComprometimento(int i, double high, double low){
   
   // considerando comprometimento se chegar a 10% do distancia entre das medias do book.
 //double shift = ( m_minion.getPrecoMedBookAsk() - m_minion.getPrecoMedBookBid() )*0.1;
   double shift = 0;
   
   
   if( high >= m_minion.getPrecoMedBookAsk()-shift ){ m_bufSinalCompUpArrow[i] = high; }else{ m_bufSinalCompUpArrow[i] = 0; }
   if( low  <= m_minion.getPrecoMedBookBid()+shift ){ m_bufSinalCompDwArrow[i] = low ; }else{ m_bufSinalCompDwArrow[i] = 0; }
}


// sinal que indica se a inclinacao da media do trade estah para cima ou para baixo.
void calcSinalInclinacao(int i){
   zerarBufInclinacao(i);
   if(m_minion.getInclinacaoTrade() >  0.1 ){m_bufSinalInclUpArrow[i]= m_minion.getPrecoMedTrade(); m_bufSinalInclDwArrow[i]= 0                         ;}else{
   if(m_minion.getInclinacaoTrade() < -0.1 ){m_bufSinalInclUpArrow[i]= 0                          ; m_bufSinalInclDwArrow[i]=m_minion.getPrecoMedTrade();}else{
                                              m_bufSinalInclUpArrow[i]= 0                          ; m_bufSinalInclDwArrow[i]=0                          ;}}   
}

/*
void calcSinalTendencia( const double& vpm[], const double& vpmax[], const double& vpmin[] ){

   double acima     = 0;
   double abaixo    = 0;
   double tendencia = 0;

   ArraySetAsSeries(vpm  ,true);
   ArraySetAsSeries(vpmax,true);
   ArraySetAsSeries(vpmin,true);

   for(int i=0; i<QTD_PERIOD_CALC_MEDIA; i++ ){
      acima  += calcPrecoAcima (vpm[i],vpmax[i],vpmin[i]);
      abaixo += calcPrecoAbaixo(vpm[i],vpmax[i],vpmin[i]);
   }
   tendencia = acima-abaixo; // se tendencia for negativa, eh de baixa;

   m_tendencia_acima =0;
   m_tendencia_abaixo=0;

   if( tendencia>0 ){ m_tendencia_acima  = (tendencia*100) /(acima+abaixo); return;}//tendencia; return; }
   if( tendencia<0 ){ m_tendencia_abaixo = (tendencia*100) /(acima+abaixo); return;}//tendencia; return; }
}
*/
double calcPrecoAcima(double pm, double max, double min){
    if( pm < min ){ return max-pm; } // barra totalmente acima no preco medio
    if( pm > max ){ return 0;      } // barra totalmente abaixo no preco medio
    return max-pm; // se chegou aqui eh porque barra passa pela linha do preco medio
}
double calcPrecoAbaixo(double pm, double max, double min){
    if( pm < min ){ return 0     ; } // barra totalmente acima no preco medio
    if( pm > max ){ return pm-min; } // barra totalmente abaixo no preco medio
    return pm-min; // se chegou aqui eh porque barra passa pela linha do preco medio
}

//===============================================================================================
// Processando o historico de ticks no oncalculate...
//===============================================================================================
void doOnCalculateHistorico(const int        p_rates_total    ,
                            const int        p_prev_calculated,
                            const datetime&  p_time[]         ){
   MqlTick ticks[];
   int     qtdTicks;
 //LOG_ONCALC_HIST;
   setAsSeries(false);
   zerarBufAll(p_prev_calculated);

   // zerando lixo do historico...
   for( int i=p_prev_calculated; i<p_rates_total; i++ ){zerarBufAll(i);}
   Print("Feita a limpeza do historico desde a barra:"                   , p_prev_calculated              , " ateh a barra:", p_rates_total, "...");
   Print("Iniciando processamento dos dados do historico, desde a barra:", p_rates_total-QTD_BAR_PROC_HIST, " ateh a barra:", p_rates_total, "...");

   // processando o historico...
   for( int i=p_prev_calculated; i<p_rates_total; i++ ){ // O -1 eh pra nao processar o periodo atual dentro do laco.

      // durante os testes, seguimos somente com as ultimas n barras
      // se prev_calculated eh zero, acontece erro ao buscar o tempo de fechamento da barra anterior
      if( (p_rates_total-i) > QTD_BAR_PROC_HIST || i==0 ){
         //zerarBufAll(p_prev_calculated); continue;
         continue;
      }

      ///m_minion.fecharPeriodo(); // fechando o periodo anterior de coleta de estatisticas
      qtdTicks = CopyTicksRange( _Symbol         , //const string     symbol_name,          // nome do símbolo
                                 ticks           , //MqlTick&         ticks_array[],        // matriz para recebimento de ticks
                                 COPY_TICKS_ALL  , //uint             flags=COPY_TICKS_ALL, // sinalizador que define o tipo de ticks obtidos
                                 p_time[i-1]*1000, //ulong            from_msc=0,           // data a partir da qual são solicitados os ticks
                                 p_time[i  ]*1000  //ulong            to_msc=0              // data ate a qual são solicitados os ticks
                 );
      for(int ind=0; ind<qtdTicks; ind++){
         normalizar2trade(ticks[ind]);
         m_minion.addTick(ticks[ind]);
         doOnBookEvent(ticks[ind])   ;// simulando o book de ofertas durante o processamento do historico...
         m_bufPbuy     [i] = m_minion.getPrecoMedTradeBuy  ();
         m_bufPsel     [i] = m_minion.getPrecoMedTradeSel  ();
         m_bufPtra     [i] = m_minion.getPrecoMedTrade     ();
         m_bufInclBuy  [i] = m_minion.getInclinacaoTradeBuy();
         m_bufInclSel  [i] = m_minion.getInclinacaoTradeSel();
         m_bufInclTra  [i] = m_minion.getInclinacaoTrade();

         m_bufPHigArrow[i] = m_minion.getTradeHigh();
         m_bufPLowArrow[i] = m_minion.getTradeLow ();

         m_bufPask     [i] = m_minion.getPrecoMedBookAsk  ();
         m_bufPbid     [i] = m_minion.getPrecoMedBookBid  ();
         m_bufPbok     [i] = m_minion.getPrecoMedBook     ();
         m_bufInclAsk  [i] = m_minion.getInclinacaoBookAsk();
         m_bufInclBid  [i] = m_minion.getInclinacaoBookBid();
         m_bufInclBok  [i] = m_minion.getInclinacaoBook   ();
         m_bufPaskArrow[i] = m_minion.getDxAsk() < m_minion.getDxBid() ? m_minion.getPrecoMedBookAsk():0;// verifique.
         m_bufPbidArrow[i] = m_minion.getDxBid() < m_minion.getDxAsk() ? m_minion.getPrecoMedBookBid():0;// verifique
         m_bufPup1Arrow[i] = 0;
         m_bufPup2Arrow[i] = 0;
         m_bufPdw1Arrow[i] = 0;
         m_bufPdw2Arrow[i] = 0;
         calcSinalInclinacao(i);         
         m_bufSinalCompUpArrow[i] = 0; // nao calculamos o sinal de comprometimento nos dados historicos.
         m_bufSinalCompDwArrow[i] = 0; // nao calculamos o sinal de comprometimento nos dados historicos.
         m_bufVol             [i] = m_minion.getVolTrade();

       //calcSinalTendenciaReversao(i);

        //===============================================================================================
        // Imprimindo dados de depuracao...
        //===============================================================================================
       //imprimirComment();
      }// final for processamento dos ticks

      // mudou a barra, entao verificamos se eh necessario alterar o tamanho dos vetores de acumulacao de medias...
      //m_minion.checkResize(0.3);

   }// final for do processamento das barras

   m_prochist = true; Print( "Historico processado :-)" );

}//doOnCalculateHistorico.

string m_deslocamento = "                                                                   "+
                        "                                                                   "+
                        "                                                                   "+
//                      "                                                                   "+
                        "                                                                   ";
int m_qtdImpressao = 0;                        
void imprimirComment(){

  // imprimir a cada 2 ticks...
  if( m_qtdImpressao++ > 2 ){ m_qtdImpressao = 0; return; }

  //===============================================================================================
  // Imprimindo dados de depuracao...
  //===============================================================================================
   m_tick_txt =
//         m_deslocamento+"PMEDBUY: " + DoubleToString (m_minion.getPrecoMedTradeBuy()   ,_Digits )+ "\n" +
//         m_deslocamento+"PMEDSEL: " + DoubleToString (m_minion.getPrecoMedTradeSel()   ,_Digits )+ "\n" +
//         m_deslocamento+"PMED===: " + DoubleToString (m_minion.getPrecoMedTrade()      ,_Digits )+ "\n" +
//
     "\n" +m_deslocamento+"=== VOL/VOL MEDIO/ACEL VOL ====\n" +
           m_deslocamento+"TOT: " + DoubleToString(m_minion.getVolTrade      ()    ,_Digits)+ "/"+
                                    DoubleToString(m_bufVol[0]                     ,_Digits)+ "/"+
//                                  DoubleToString(m_minion.getVolMedTrade   ()    ,1      )+ "/"+
//                                  DoubleToString(m_minion.getAceVol        ()    ,3      )+ "\n"+
//         m_deslocamento+"BUY: " + DoubleToString(m_minion.getVolTradeBuy   ()    ,_Digits)+ "/"+
//                                  DoubleToString(m_minion.getVolMedTradeBuy()    ,1      )+ "/"+
//                                  DoubleToString(m_minion.getAceVolBuy     ()    ,3      )+ "\n"+
//         m_deslocamento+"SEL: " + DoubleToString(m_minion.getVolTradeSel   ()    ,_Digits)+ "/"+
//                                  DoubleToString(m_minion.getVolMedTradeSel()    ,1      )+ "/"+
//                                  DoubleToString(m_minion.getAceVolSel     ()    ,3      )+ "\n"+
//
   "\n"+ m_deslocamento+"=== INCLINACOES  E  DX ========================\n"                                           +
         m_deslocamento+"BUY: " + DoubleToString (m_minion.getInclinacaoTradeBuy() ,2 )+ " / DX: " + DoubleToString (m_minion.getDxBuy() ,2 ) + "\n"+
         m_deslocamento+"SEL: " + DoubleToString (m_minion.getInclinacaoTradeSel() ,2 )+ " / DX: " + DoubleToString (m_minion.getDxSel() ,2 ) + "\n"+
         m_deslocamento+"TRA: " + DoubleToString (m_minion.getInclinacaoTrade()    ,2 )+ "\n" +
      //m_deslocamento+"===========================\n"                                           +
         m_deslocamento+"ASK: " + DoubleToString (m_minion.getInclinacaoBookAsk() ,2 )+ " / DX: " + DoubleToString (m_minion.getDxAsk() ,2 ) + "\n"+
         m_deslocamento+"BID: " + DoubleToString (m_minion.getInclinacaoBookBid() ,2 )+ " / DX: " + DoubleToString (m_minion.getDxBid() ,2 ) + "\n"+
         m_deslocamento+"BOK: " + DoubleToString (m_minion.getInclinacaoBook()    ,2 )+ "\n" +

   "\n"+ m_deslocamento+"=== BARRAS ACUMULADAS ========================\n"                                           +
         m_deslocamento+"TOT/BUY/SEL====:"+ DoubleToString(double(m_minion.getTempoAcumTrade     ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumTradeBuy  ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumTradeSel  ())/(double)m_qtd_sec_periodo, 2 )+ "\n"+
         m_deslocamento+"TOT/ASK/BID====:"+ DoubleToString(double(m_minion.getTempoAcumBook      ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumBookAsk   ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumBookBid   ())/(double)m_qtd_sec_periodo, 2 )+ "\n"+
         m_deslocamento+"ACE TOT/BUY/SEL:"+ DoubleToString(double(m_minion.getTempoAcumAceVol    ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumAceVolBuy ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumAceVolSel ())/(double)m_qtd_sec_periodo, 2 )+ "\n"+
         m_deslocamento+"TEND/REV=======:"+ DoubleToString(double(m_minion.getTempoAcumTendencia ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                                            DoubleToString(double(m_minion.getTempoAcumRversao   ())/(double)m_qtd_sec_periodo, 2 )+ "\n"+
         m_deslocamento+"TATU/BAR: "      + DoubleToString (m_sec_barra                    ,0 ) + "/"  +
                                            DoubleToString (m_qtd_sec_periodo              ,0 ) + "\n" +

   "\n"+ m_deslocamento+"======= TAMANHO DOS VETORES DE MEDIAS ========\n"+
         m_deslocamento+"TRADE TOT/BUY/SEL:" + IntegerToString(m_minion.getLenVetAcumTrade    ()) + "/"  +
                                               IntegerToString(m_minion.getLenVetAcumTradeBuy ()) + "/"  +
                                               IntegerToString(m_minion.getLenVetAcumTradeSel ()) + "\n" +
         m_deslocamento+"BOOK TOT/ASK/BID=:" + IntegerToString(m_minion.getLenVetAcumBook     ()) + "/"  +
                                               IntegerToString(m_minion.getLenVetAcumBookAsk  ()) + "/"  +
                                               IntegerToString(m_minion.getLenVetAcumBookBid  ()) + "\n" +
         m_deslocamento+"ACEVO TOT/BUY/SEL:" + IntegerToString(m_minion.getLenVetAcumAceVol   ()) + "/"  +
                                               IntegerToString(m_minion.getLenVetAcumAceVolBuy()) + "/"  +
                                               IntegerToString(m_minion.getLenVetAcumAceVolSel()) + "\n" ;

 //"\n"+m_deslocamento+"=== FORCA TEND/REVER =================\n"+
      //m_deslocamento+"TEN/REV UP:" + DoubleToString(m_tendencia_acima ,_Digits) +"/"+ DoubleToString(m_reversao_vai_subir,_Digits)+"\n"+
      //m_deslocamento+"TEN/REV DW:" + DoubleToString(m_tendencia_abaixo,_Digits) + "/"+DoubleToString(m_reversao_vai_cair ,_Digits)+"\n";

   // string terminal_txt =
   //              m_deslocamento+"MEM_FIS(MB):" + osc_util::getTermMemFisicaStr      () + "\n" +
   //              m_deslocamento+"MEM_TOT(MB):" + osc_util::getTermMemTotalStr       () + "\n" +
   //              m_deslocamento+"MEM_USA(MB):" + osc_util::getTermMemUsadaStr       () + "\n" +
   //              m_deslocamento+"MEM_DIS(MB):" + osc_util::getTermMemDispStr        () + "\n" +
   //       "\n" + m_deslocamento+"CPU_64==:"    + osc_util::getTermCpuX64Str         () + "\n" +
   //              m_deslocamento+"CPU_COR=:"    + osc_util::getTermCpuCoresStr       () + "\n" +
   //              m_deslocamento+"CPU_OPCL:"    + osc_util::getTermCpuOpenClSuportStr() + "\n" +
   //       "\n" + m_deslocamento+"DSK_DISP:"    + osc_util::getTermDiskSpaceStr      () + "\n" ;

   Comment(       m_deslocamento+"DOM PREVISAO ============================\n"+
                  m_dom_previsao +
          //"DOM TXT ===========================\n"+
           //m_dom_txt +
           "\n" + m_deslocamento+"TICK ===========================\n"+
                  m_tick_txt+

         //   "\n" + m_deslocamento+"TERMINAL ===============================\n"+
         //          terminal_txt+

           "\n" + m_deslocamento+"FIM ================================"  );
  //===============================================================================================
}


// gerado pelo sistema...
void OnBookEvent(const string &symbol){

   if(symbol!=_Symbol)             return; // garantindo que nao estamos processando o book de outro simbolo,
   m_tempoOnBook = GetMicrosecondCount() - m_tempoOnBook;

   //if(OSI_FEIRA_BOOK_ON_CALCULATE) return; // se processa o book somente no oncalculate, volta daqui...

   //MqlBookInfo book[];
   //MarketBookGet(symbol, book);
   //doOnBookEvent2(book,BOOK_OUT, TimeCurrent());
   doOnBookEvent(symbol);
}


// chamado no oncalculate quando queremos processar book na mesma velocidade dos ticks. Um book pra cada oncalculate.
void doOnBookEvent(const string &symbol){
   MqlBookInfo book[];
   MarketBookGet(symbol, book);
   doOnBookEvent2(book,BOOK_OUT, TimeCurrent());
}

// chamado quando nao tem book disponivel
void doOnBookEvent(MqlTick& tick){
   MqlBookInfo book[2];
   book[0].price       = tick.ask>0 ? tick.ask+44 : tick.ask ;
   book[0].type        = BOOK_TYPE_SELL;
   book[0].volume      = 1             ;
   book[0].volume_real = 1             ;
   book[1].price       = tick.bid>0 ?  tick.bid-44 : tick.bid ;
   book[1].type        = BOOK_TYPE_BUY ;
   book[1].volume      = 1             ;
   book[1].volume_real = 1             ;
 //doOnBookEvent (book,0);
   doOnBookEvent2(book,0, tick.time); // aqui pode ser processamento de historico, entao usamos a hora do tick e nao a hora atual do servidor.
}


// acumulacao do book de ofertas baseado no minion de estatisticas...
void doOnBookEvent2(MqlBookInfo& book[], double book_out, datetime pTime){
   int tamanhoBook = ArraySize(book);
   if(tamanhoBook == 0) { Print(":-( Falha carregando livro de ofertas. Motivo: ", GetLastError()); return; }

   // em processamento historico ou de mercados sem DOM, recebo a hora para usar na estatistisca do book...
   // em processamento online, usamos a hora da ultima cotacao recebida.
   // datetime dth = (pTime==0)? TimeCurrent() : pTime;
   if (pTime==0) pTime = TimeCurrent();

 //m_minion.addBook( dth  , book, tamanhoBook,book_out, m_symb.TickSize() );
   m_minion.addBook( pTime, book, tamanhoBook,book_out, m_symb.TickSize() );
   writeDetLogBook(book);

   m_pmask = m_minion.getPrecoMedBookAsk();
   m_pmbid = m_minion.getPrecoMedBookBid();
   m_pmbok = m_minion.getPrecoMedBook();
   
   //ArrayPrint(book);

   

   /*
   string bolinha_ask    = "";
   string bolinha_bid    = "";
   string bolinha_empate = "";

   if(m_minion.getDxBid()  < m_minion.getDxAsk()){ m_qtdWinBid++; m_dbid += (m_minion.getDxAsk()-m_minion.getDxBid()); bolinha_bid    = " *";}
   if(m_minion.getDxBid()  > m_minion.getDxAsk()){ m_qtdWinAsk++; m_dask += (m_minion.getDxBid()-m_minion.getDxAsk()); bolinha_ask    = " *";}
   if(m_minion.getDxBid() == m_minion.getDxAsk()){ m_qtdEmpate++;                                                      bolinha_empate = " *";}

   m_dom_previsao = m_deslocamento+"FORCA EMPATE             :" + IntegerToString(m_qtdEmpate   ,0)  + "    :" +                                   bolinha_empate +"\n"+
                    m_deslocamento+"FORCA OFER VEN(ASK) SOBE :" + IntegerToString(m_qtdWinAsk   ,0)  + "    :" +  DoubleToString(m_dask,_Digits) + bolinha_ask    +"\n"+
                    m_deslocamento+"FORCA OFER COM(BID) DESCE:" + IntegerToString(m_qtdWinBid   ,0)  + "    :" +  DoubleToString(m_dbid,_Digits) + bolinha_bid    +"\n"+
                    m_deslocamento+"VOL TOT/VEN(ASK)/COM(BID):" + DoubleToString (m_minion.getVolBook()   , _Digits )  +"/"+
                                                                  DoubleToString (m_minion.getVolBookAsk(), _Digits )  +"/"+
                                                                  DoubleToString (m_minion.getVolBookBid(), _Digits )  +"\n"+

                  //m_deslocamento+"DXASK/DXBID : "             + DoubleToString (m_minion.getDxAsk()     , _Digits )  +"/" +
                  //                                              DoubleToString (m_minion.getDxBid()     , _Digits )  +"\n"  +

                    m_deslocamento+"PRECO MED ASK/BID:" + DoubleToString (m_minion.getPrecoMedBookAsk(), _Digits )  +"/" +
                                                          DoubleToString (m_minion.getPrecoMedBookBid(), _Digits )  +"\n"+
                   //m_deslocamento+"IND TOT/BUY/SEL: " + IntegerToString(m_minion.getIndBook   ()      )+ "/" +
                   //                                     IntegerToString(m_minion.getIndBookAsk()      )+ "/" +
                   //                                     IntegerToString(m_minion.getIndBookBid()      )+ "\n"  +
                   //m_deslocamento+"=======\n"                                                          +
                   //m_deslocamento+"BAR TOT/ASK/BID: " + DoubleToString(double(m_minion.getTempoAcumBook   ())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                   //                                     DoubleToString(double(m_minion.getTempoAcumBookAsk())/(double)m_qtd_sec_periodo, 2 )+ "/" +
                   //                                     DoubleToString(double(m_minion.getTempoAcumBookBid())/(double)m_qtd_sec_periodo, 2 )+ "\n"
                   m_deslocamento+"=======FIM\n";
                   
  */
}

void setAsSeries(bool modo){
   ArraySetAsSeries(m_bufPsel            , modo );
   ArraySetAsSeries(m_bufPbuy            , modo );
   ArraySetAsSeries(m_bufPask            , modo );
   ArraySetAsSeries(m_bufPbid            , modo );
   ArraySetAsSeries(m_bufPaskArrow       , modo );
   ArraySetAsSeries(m_bufPbidArrow       , modo );
   ArraySetAsSeries(m_bufPHigArrow       , modo );
   ArraySetAsSeries(m_bufPLowArrow       , modo );
   ArraySetAsSeries(m_bufPup1Arrow       , modo );
   ArraySetAsSeries(m_bufPup2Arrow       , modo );
   ArraySetAsSeries(m_bufPdw1Arrow       , modo );
   ArraySetAsSeries(m_bufPdw2Arrow       , modo );
   ArraySetAsSeries(m_bufPtra            , modo );
   ArraySetAsSeries(m_bufPbok            , modo );
   ArraySetAsSeries(m_bufSinalCompUpArrow, modo );
   ArraySetAsSeries(m_bufSinalCompDwArrow, modo );
   ArraySetAsSeries(m_bufSinalInclUpArrow, modo );
   ArraySetAsSeries(m_bufSinalInclDwArrow, modo );
   ArraySetAsSeries(m_bufDesbN0          , modo );
   ArraySetAsSeries(m_bufDesbN1          , modo );
   ArraySetAsSeries(m_bufInclSel         , modo );
   ArraySetAsSeries(m_bufInclBuy         , modo );
   ArraySetAsSeries(m_bufInclTra         , modo );
   ArraySetAsSeries(m_bufInclAsk         , modo );
   ArraySetAsSeries(m_bufInclBid         , modo );
   ArraySetAsSeries(m_bufInclBok         , modo );
   ArraySetAsSeries(m_bufVol             , modo );
}
void zerarBufDemanda(uint i){
   m_bufInclSel  [i] = 0;
   m_bufInclBuy  [i] = 0;
   m_bufInclTra  [i] = 0;
   m_bufPbuy     [i] = 0;
   m_bufPsel     [i] = 0;
   m_bufPtra     [i] = 0;
   m_bufPHigArrow[i] = 0;
   m_bufPLowArrow[i] = 0;
}
void zerarBufOferta(uint i){
   m_bufInclAsk  [i] = 0;
   m_bufInclBid  [i] = 0;
   m_bufInclBok  [i] = 0;
   m_bufPask     [i] = 0;
   m_bufPbid     [i] = 0;
   m_bufPbok     [i] = 0;
   m_bufPaskArrow[i] = 0;
   m_bufPbidArrow[i] = 0;
}
void zerarBufForca(uint i){
   m_bufPup1Arrow[i] = 0;
   m_bufPup2Arrow[i] = 0;
   m_bufPdw1Arrow[i] = 0;
   m_bufPdw2Arrow[i] = 0;
   m_bufVol      [i] = 0;
}
//void zerarBufTendenciaReversao(uint i){
//   m_bufTend        [i] = 0;
//   m_bufReve        [i] = 0;
//}

void zerarBufDesbalanceamento(uint i){
   m_bufDesbN0[i] = 0;
   m_bufDesbN1[i] = 0;
}
void zerarBufComprometimento(uint i){
   m_bufSinalCompUpArrow[i] = 0;
   m_bufSinalCompDwArrow[i] = 0;
}
void zerarBufInclinacao(uint i){
   m_bufSinalInclUpArrow[i] = 0;
   m_bufSinalInclDwArrow[i] = 0;
}
void zerarBufAll(uint i){
   zerarBufOferta           (i);
   zerarBufDemanda          (i);
   zerarBufForca            (i);
 //zerarBufTendenciaReversao(i);
   zerarBufDesbalanceamento (i);
   zerarBufComprometimento  (i);
   zerarBufInclinacao       (i);
}

// calcula a quantidade de segundos da barra atual e bem como a % de tempo decorrido...
uint   m_sec_barra_pro_fim        ;
double m_porcTempoDesdeInicioBarra;
double m_porcTempoToFimBarra      ;
void calcTempoBarraAtual(const datetime&  time[]){
    // segundos na barra atual...
     bool tipo = ArrayIsSeries(time);
     ArraySetAsSeries(time,true);
     m_sec_barraAtu =   TimeCurrent();
     m_sec_barraAnt =   time[0];
     m_sec_barra            =   (int)(m_sec_barraAtu    - m_sec_barraAnt);
     m_sec_barra_pro_fim    =   (int)(m_qtd_sec_periodo - m_sec_barra   );
     ArraySetAsSeries(time,tipo);
     m_porcTempoDesdeInicioBarra = (m_sec_barra        /m_qtd_sec_periodo)*100.0;
     m_porcTempoToFimBarra       = (m_sec_barra_pro_fim/m_qtd_sec_periodo)*100.0;

}

void openLogFileBook(string arqLog){m_log_book=FileOpen(arqLog, FILE_WRITE|FILE_CSV,';'); writeHeaderLogBook();}
void openLogFileTick(string arqLog){m_log_tick=FileOpen(arqLog, FILE_WRITE             );                      }

void writeHeaderLogBook(){
   if( !DEBUG ){ return; }

/*   FileWrite( m_log_book ,
              "SYMB"     ,
              "DATA"     ,
              "ID"       ,
              "I"        ,
              "TP"       ,
              "VOLR"     ,
              "PRICE"    ,
              "DIST"     ,
              "volXdist" ,
              "priceXvolXdistACUM" );
*/
   FileWrite( m_log_book ,
              "ID"       ,
              "TIMECUR"  ,
            //"TTS"      ,
              "TMPONBOOK",
            //"TWULTLINHA",
              "TATU"      ,
            //"TMPLOG"   ,
            //"I"        ,
              "FILA"     ,
              "TP"       ,
              "PRICE"    ,
              "VOL"      );
}

int   m_tamanhoBook = 0;
ulong m_id_dbbook   = 1;
ulong m_tatu           = GetMicrosecondCount();
ulong m_tempoOnBook    = m_tatu;
ulong m_tdecorrLog     = m_tatu;
ulong m_tWriteUltlinha = m_tatu;
ost_book m_book;

void writeDetLogBook( MqlBookInfo& book[] ){

   if( !DEBUG ){ return; }
 //m_tdecorrLog = GetMicrosecondCount();
   datetime tc  = TimeCurrent();
 //datetime tts = TimeTradeServer();
   int tamanhoBook = ArraySize(book);
   int metadeBook = tamanhoBook/2;
   
   for(int i=0; i<tamanhoBook; i++){
       if( i>metadeBook-10 && i<metadeBook+9){
         //m_tWriteUltlinha = GetMicrosecondCount()-m_tWriteUltlinha;
           m_book.book_id   = m_id_dbbook  ;
           m_book.timecurr  = tc           ;
           m_book.tmponbook = m_tempoOnBook;
           m_book.tatu      = GetMicrosecondCount();
           m_book.fila      = book[i].type == BOOK_TYPE_SELL? MathAbs(i-metadeBook) : i+1-metadeBook;
           m_book.tipo      = book[i].type;
           m_book.preco     = book[i].price;
           m_book.vol       = book[i].volume;
           
           FileWrite( m_log_book           ,
                      m_book.book_id       , //m_id_dbbook          ,
                      m_book.timecurr      , //tc                   ,
                                             //tts                  ,
                      m_book.tmponbook     , //m_tempoOnBook        ,
                                             //m_tWriteUltlinha     ,
                      m_book.tatu          , //GetMicrosecondCount(),
                                             //m_tdecorrLog         ,
                                             //m_id_dbbook++        ,
                                             //i                    ,
                      m_book.fila          , //book[i].type == BOOK_TYPE_SELL? MathAbs(i-metadeBook) : i+1-metadeBook , // posicao na fila
                      m_book.tipo          , //book[i].type         ,
                      m_book.preco         , //book[i].price        ,
                      m_book.vol             //book[i].volume       
                                             //book[i].volume_real                
                    );
           //m_mydb.insert_table_book( m_book );                    
       }
   }//laco for
   m_id_dbbook++;
   //m_tdecorrLog = GetMicrosecondCount() - m_tdecorrLog;
}



void writeDetLogBook(uint id, int i, string tp, double volr, double price, double distPrice, double volXdist, double priceXvolXdist ){

  if( !DEBUG ){ return; }

  string dt = TimeToString(  m_symb.Time(),TIME_DATE|TIME_MINUTES|TIME_SECONDS );
  StringReplace ( dt, ".", "-" );
  FileWrite( m_log_book                      ,
             m_symb.Name()                   ,
             dt                              ,
             IntegerToString( id            ),
             IntegerToString( i             ),
             tp                              ,
             DoubleToString ( volr           ,_Digits ),
             DoubleToString ( price          ,_Digits ),
             DoubleToString ( distPrice      ,_Digits ),
             DoubleToString ( volXdist       ,_Digits ),
             DoubleToString ( priceXvolXdist ,_Digits )
           );
}

void flushLogBook()                 { if( DEBUG               ){ FileFlush(m_log_book                                   ); } }
void flushLogTick()                 { if( DEBUG || DEBUG_TICK ){ FileFlush(m_log_tick                                   ); } }
void writeDetLogTick(string comment){ if( DEBUG || DEBUG_TICK ){ FileWrite(m_log_tick, m_tick_util.toStringCSV(comment) ); } } // escrevendo o log de ticks...

//+------------------------------------------------------------------+
