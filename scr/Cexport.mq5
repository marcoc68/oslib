﻿//+------------------------------------------------------------------+
//|                                                      Cexport.mq5 |
//|                                         Copyright 2020, OS Corp. |
//|                                                http://www.os.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "1.001"

#include <Files\FileTxt.mqh>
#include <oslib\osc\data\CBarTick.mqh>
#include <oslib\osc-estatistic2.mqh>
#include <oslib\osc\est\C0001FuzzyModel.mqh>


//+------------------------------------------------------------------+
//| Script para exportar barras rate, ticks e barras de ticks.       |
//+------------------------------------------------------------------+
class Cexport{
    private:
        // aux var to determine nature os tick.
        bool   m_tbuy; 
        bool   m_tsel; 
        bool   m_task; 
        bool   m_tbid; 
        bool   m_tlas; 
        bool   m_tvol;

        // aux var to determine vel of tick volume.
        double m_vbuy,
               m_vsel,
               m_vliq,
               m_abuy,
               m_asel,
               m_aliq,
               m_rbuy,
               m_rsel;
        
        osc_estatistic2 m_est2;
        C0001FuzzyModel m_model_vol;
         
       
       int  openFileCSV2Write(datetime from, datetime to, string sufix); // create csv file to write.
       void closeFile        (int file)                                ; // close file

       struct Qtick{ uint tot;
                     uint buy; uint buyr;
                     uint sel; uint selr;
                     uint bid; uint bidr;
                     uint ask; uint askr;
                     uint las; uint lasr; 
                     uint vol; uint volr; };
       void initQtick(Qtick& qtick);

       int    analyseTicksInRate(string symbol, MqlRates &rate, Qtick &qtick);

        // used in exportTicks2CSV
       void initialize4TicksEstat(string _symbol, int _periodoEst, bool _corrigirTicks){
            m_est2.initialize(_periodoEst,_corrigirTicks); // quantidade de segundos que serao usados no calculo da velocidade do volume e flag indicando que deve consertar ticks sem flag.
            m_est2.setSymbolStr( _symbol );
            m_model_vol.initialize();
       };
       
       #define QTD_SEG_ESTAT 10
       
       string calcDirecaoPreco(int pup, int pdw);


    public:
       
       // ticks export...
       int  exportTicks2CSV    (datetime from, datetime to, string symbol, int periodoEst=QTD_SEG_ESTAT, bool corrigirTicks=false); // export ticks to csv file. File will be created in COMMON_FILE dir. 
       uint fileWriteTick      (int csvFile, MqlTick &tick) ; // write tick in csv tick file.
       uint fileWriteTickHeader(int csvFile, string symbol) ; // write header in csv tick file.

       // rates export...
       int  exportRates2CSV    (datetime from, datetime to, string symbol, ENUM_TIMEFRAMES timeFrame); // export rates to csv file. File will be created in COMMON_FILE dir. 
       uint fileWriteRate      (int csvFile, MqlRates &rate, Qtick &qtick) ; // write rate in csv rate file.
       uint fileWriteRateHeader(int csvFile, string symbol               ) ; // write header in csv rate file.

       // Barticks export...
       int  exportRatesTicks2CSV   (datetime from   , datetime    to   , string symbol, int timeFrame, int periodoEst=QTD_SEG_ESTAT, bool corrigirTicks=false, int qtdSegIniWrite=0); // export Barticks groupping in seconds to csv file. File will be created in COMMON_FILE dir. 
       uint fileWriteRateTick      (int      csvFile, OsRateTick& tick , bool write  ); // write Bartick in csv tick file.
       uint fileWriteRateTickHeader(int      csvFile, string      symbol); // write Barheader in csv tick file.

};

// export ticks to csv file. 
// The file wil be saved in COMMON_FILE dir. 
// Return qtd ticks exported.
int Cexport::exportTicks2CSV(datetime from,datetime to, string symbol, int periodoEst=QTD_SEG_ESTAT, bool corrigirTicks=false ){

    // getting the history ticks...    
    MqlTick ticks[];
    
    int qtdTicks = 0;
    Print(":-| ",__FUNCTION__,": Getting ticks for ", symbol," from ",from," to ", to,"...");   
    qtdTicks = CopyTicksRange(symbol,ticks,COPY_TICKS_ALL ,from*1000, to*1000 );
    Print(":-| ",__FUNCTION__,": Count ", qtdTicks, " ticks for ", symbol,".");   
   
    if(qtdTicks==0){ return 0;}
    
    // initializing estatistics and fuzzy model for veloc os volume...
    initialize4TicksEstat(symbol, periodoEst, corrigirTicks);
    
    // open ticks file to write...
    int file = openFileCSV2Write(from,to,symbol+"_ticks");

    // writting ticks into file...
    Print(":-| ",__FUNCTION__,": ", " saving ticks in file... ");
    fileWriteTickHeader(file,symbol);
    for(int i=0; i<qtdTicks; i++){ fileWriteTick( file, ticks[i] ); }

    Print(":-| ",__FUNCTION__,": ", "ticks saved. ");   
    
    // closing tick file...
    closeFile(file);    
    return qtdTicks;
}

// export rates to csv file. 
// The file wil be saved in COMMON_FILE dir. 
// Return qtd rates exported.
int Cexport::exportRates2CSV(datetime from,datetime to, string symbol, ENUM_TIMEFRAMES timeFrame ){

    // getting the history rates...    
    MqlRates rates[];
    Qtick    qtick;
    double sumLenPeriod = 0; 
    
    int qtdRates = 0;
    Print(":-| ",__FUNCTION__,": Getting rates for ", symbol," from ",from," to ", to,"...");   
    qtdRates = CopyRates(symbol, timeFrame, from, to, rates );
    Print(":-| ",__FUNCTION__,": Count ", qtdRates, " rates for ", symbol,".");   
   
    if(qtdRates==0){ return 0;}
    
    // open rates file to write...
    int file = openFileCSV2Write(from,to,symbol+"_rates");

    // writting rates into file... 
    Print(":-| ",__FUNCTION__,": ", " saving rates in file... ");
    fileWriteRateHeader(file, symbol);
    for(int i=0; i<qtdRates; i++){
        analyseTicksInRate(symbol, rates[i], qtick); 
        fileWriteRate( file, rates[i], qtick );
        sumLenPeriod += MathAbs( (rates[i].open - rates[i].close) );
    }
    Print(":-| ",__FUNCTION__,": ", "rates saved. ");   
    
    double lenMed = (sumLenPeriod/(double)qtdRates);
    Print(":-| ",__FUNCTION__,": Avg Len Period = ", NormalizeDouble(lenMed,2) );   
        
    // closing rates file...
    closeFile(file);    
    return qtdRates;
}
void Cexport::initQtick(Qtick &qtick){
    qtick.tot  = 0;
    qtick.buyr = 0;
    qtick.selr = 0;
    qtick.askr = 0;
    qtick.bidr = 0;
    qtick.lasr = 0;
    qtick.volr = 0;
    qtick.buy  = 0;
    qtick.sel  = 0;
    qtick.ask  = 0;
    qtick.bid  = 0;
    qtick.las  = 0;
    qtick.vol  = 0;
}
int Cexport::analyseTicksInRate(string symbol, MqlRates &rate, Qtick &qtick){
    MqlTick ticks[];
    
    
    // obtendo ticks desde o inicio ate o fim da barra recebida no parametro...
    Print(":-| ",__FUNCTION__,": Getting ticks for ", symbol," for ", rate.time, "...");   
    initQtick(qtick);
    qtick.tot = CopyTicksRange(symbol,ticks,COPY_TICKS_ALL , rate.time*1000, ((rate.time+60)*1000)-1 );
    
    for(uint i=0; i<qtick.tot; i++){
        m_tbuy=((ticks[i].flags&TICK_FLAG_BUY   )==TICK_FLAG_BUY   ); 
        m_tsel=((ticks[i].flags&TICK_FLAG_SELL  )==TICK_FLAG_SELL  ); 
        m_task=((ticks[i].flags&TICK_FLAG_ASK   )==TICK_FLAG_ASK   ); 
        m_tbid=((ticks[i].flags&TICK_FLAG_BID   )==TICK_FLAG_BID   ); 
        m_tlas=((ticks[i].flags&TICK_FLAG_LAST  )==TICK_FLAG_LAST  );
        m_tvol=((ticks[i].flags&TICK_FLAG_VOLUME)==TICK_FLAG_VOLUME);
        
        qtick.buyr += m_tbuy ? (uint)ticks[i].volume_real : 0;
        qtick.selr += m_tsel ? (uint)ticks[i].volume_real : 0;
        qtick.askr += m_task ? (uint)ticks[i].volume_real : 0;
        qtick.bidr += m_tbid ? (uint)ticks[i].volume_real : 0;
        qtick.lasr += m_tlas ? (uint)ticks[i].volume_real : 0;
        qtick.volr += m_tvol ? (uint)ticks[i].volume_real : 0;

        qtick.buy += m_tbuy ? (uint)ticks[i].volume : 0;
        qtick.sel += m_tsel ? (uint)ticks[i].volume : 0;
        qtick.ask += m_task ? (uint)ticks[i].volume : 0;
        qtick.bid += m_tbid ? (uint)ticks[i].volume : 0;
        qtick.las += m_tlas ? (uint)ticks[i].volume : 0;
        qtick.vol += m_tvol ? (uint)ticks[i].volume : 0;
    }
    return (int)qtick.tot;
}

// export ticks to csv file. 
// The file wil be saved in COMMON_FILE dir. 
// Return qtd ticks exported.
int Cexport::exportRatesTicks2CSV(datetime from, datetime to, string symbol, int timeFrame, int periodoEst=QTD_SEG_ESTAT, bool corrigirTicks=false, int qtdSegIniWrite=0) {

    // getting the history ticks...    
    MqlTick    ticks[];
    CBarTick   cBarTick;
    OsRateTick rateTick;

    int qtdTicks = 0;
    Print(":-| ", __FUNCTION__, ": Getting ticks for ", symbol, " from ", from, " to ", to, "...");
    qtdTicks = CopyTicksRange(symbol, ticks, COPY_TICKS_ALL, from * 1000, to * 1000);
    Print(":-| ", __FUNCTION__, ": Count ", qtdTicks, " ticks for ", symbol, ".");
    Print(":-| ", __FUNCTION__, ": Impressao iniciarah apos a barra: ", qtdSegIniWrite);

    if (qtdTicks == 0) { return 0; }

    // initializing estatistics and fuzzy model for veloc os volume...
    initialize4TicksEstat(symbol, periodoEst, corrigirTicks);

    // open ticks file to write...
    int file = openFileCSV2Write(from, to, symbol + "_" + IntegerToString(periodoEst) + "_ratestick");

    // writting ticks into file...
    int result, qt = 0;
    Print(":-| ", __FUNCTION__, ": saving Barticks in file... ");
    fileWriteRateTickHeader(file,symbol);
    for(int i=0; i<qtdTicks; i++) {
        result = cBarTick.add(ticks[i]);
        switch( result ){
            case 1: m_est2.addTick(ticks[i]); break;
            case 2: {   qt++;
                        cBarTick.getRateTick(rateTick);
                      //Print(":-| ", __FUNCTION__, ": Print Bartick: ",qt," :", rateTick.rate.time," ...");
                        fileWriteRateTick ( file, rateTick,(qt>qtdSegIniWrite) );
                        cBarTick.initBarTick();
                        cBarTick.add(ticks[i]);
                        m_est2.addTick(ticks[i]);
                        break;
                    };
            case -1:{   Print(":-( ", __FUNCTION__, ": ERRO: Tentativa de acrescentar um tick antigo em OsRateTick!"); 
                        break;
                    }  
        }        
    }
    
    // escrevendo a ultima barra no arquivo...
    cBarTick.getRateTick(rateTick);
    Print(":-| ", __FUNCTION__, ": Print Bartick: ",qt," :", rateTick.rate.time," ...");
    fileWriteRateTick (file,rateTick,true);
    
    // avisando o termino...
    Print(":-| ", __FUNCTION__, ": ", qt, " Barticks saved. ");

    // closing tick in minute file...
    closeFile(file);
    return qtdTicks;
}


// write header in csv tick file.
uint Cexport::fileWriteTickHeader(int csvFile, string symbol){
    return FileWrite(csvFile,         "time"    , 
                                      "time_msc",
                                      "msc"     ,
                                      "ask"     ,
                                      "bid"     ,
                                      "last"    ,
                                      "vol"     ,
                                      "vol_real",
                                      "tbuy","tsel","task","tbid","tlas","tvol","flags",
                                      "vbuy","vsel","vliq","abuy","asel","aliq","rbuy","rsel" );
}

// write header in csv rate file.
uint Cexport::fileWriteRateHeader(int csvFile, string symbol ){
    return FileWrite(csvFile, symbol +"_time"   , 
                                      "open"    ,
                                      "high"    ,
                                      "low"     ,
                                      "close"   ,
                                      "tick_vol",
                                      "real_vol",
                                      "spread"  ,
                                      "buyr"    ,
                                      "selr"    ,
                                      "lasr"    ,
                                      "askr"    ,
                                      "bidr"    ,
                                      "volr"    ,
                                      "buy"     ,
                                      "sel"     ,
                                      "las"     ,
                                      "ask"     ,
                                      "bid"     ,
                                      "vol"     ,
                                      "tot"     );
}

// write header in csv rate file.
uint Cexport::fileWriteRateTickHeader( int csvFile, string symbol ){
    return FileWrite(csvFile, symbol+"_time"         ,
                                     "open"          ,
                                     "high"          ,
                                     "low"           ,
                                     "close"         ,
                                     "tick_vol"      ,
                                     "real_vol"      ,
                                     "spread"        ,
                                     "first_time_msc",
                                     "last_time_msc" ,
                                     "vol_buy"       ,
                                     "vol_sel"       ,
                                     "ret" ,"lret"   ,
                                     "vbuy","vsel","vliq",
                                     "abuy","asel","aliq",
                                     "rbuy","rsel"       ,
                                     "pdir"              );
}



// write tick in csv tick file.
uint Cexport::fileWriteTick(int csvFile, MqlTick &tick){

    m_tbuy=((tick.flags&TICK_FLAG_BUY   )==TICK_FLAG_BUY   ); 
    m_tsel=((tick.flags&TICK_FLAG_SELL  )==TICK_FLAG_SELL  ); 
    m_task=((tick.flags&TICK_FLAG_ASK   )==TICK_FLAG_ASK   ); 
    m_tbid=((tick.flags&TICK_FLAG_BID   )==TICK_FLAG_BID   ); 
    m_tlas=((tick.flags&TICK_FLAG_LAST  )==TICK_FLAG_LAST  );
    m_tvol=((tick.flags&TICK_FLAG_VOLUME)==TICK_FLAG_VOLUME);

    string dt = TimeToString(tick.time,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
    StringReplace( dt,".","/" );
    

    m_est2.addTick(tick);
    m_vbuy = round(m_est2.getVolTradeBuyPorSeg());
    m_vsel = round(m_est2.getVolTradeSelPorSeg());
    m_vliq = round(m_est2.getVolTradeLiqPorSeg());
    m_abuy = round(m_est2.getAceVolBuy()        );
    m_asel = round(m_est2.getAceVolSel()        );
    m_aliq = round(m_abuy - m_asel              );
    
    m_model_vol.CalcularRisco(m_vliq,m_abuy,m_asel,m_rsel,m_rbuy);
    m_rbuy = round(m_rbuy*100);
    m_rsel = round(m_rsel*100);

    m_asel = round(m_asel*10);
    m_abuy = round(m_abuy*10);
    m_aliq = round(m_aliq*10);

    return FileWrite(   csvFile, 
                        dt,
                      //tick.time, 
                        tick.time_msc,
                        tick.time_msc%1000,
                        tick.ask,
                        tick.bid,
                        tick.last,
                        tick.volume,
                        tick.volume_real,
                        m_tbuy,m_tsel,m_task,m_tbid,m_tlas,m_tvol,tick.flags,
                        m_vbuy, m_vsel, m_vliq,
                        m_abuy, m_asel, m_aliq,
                        m_rbuy, m_rsel                                       );
}

// write rate in csv rate file.
uint Cexport::fileWriteRate(int csvFile, MqlRates &rate, Qtick &qtick){

    string dt = TimeToString(rate.time,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
    StringReplace( dt,".","/" );

    return FileWrite(csvFile,   dt              ,
                                rate.open       ,
                                rate.high       ,
                                rate.low        ,
                                rate.close      ,
                                rate.tick_volume,
                                rate.real_volume,
                                rate.spread     ,
                                qtick.buyr      ,
                                qtick.selr      ,
                                qtick.lasr      ,
                                qtick.askr      ,
                                qtick.bidr      ,
                                qtick.volr      ,
                                qtick.buy       ,
                                qtick.sel       ,
                                qtick.las       ,
                                qtick.ask       ,
                                qtick.bid       ,
                                qtick.vol       ,
                                qtick.tot       
                                );
}

// write ratetick in csv rate file.
uint Cexport::fileWriteRateTick(int csvFile,OsRateTick &rate_tick, bool write){

    string dt = TimeToString(rate_tick.rate.time,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
    StringReplace( dt,".","/" );
    
    //string ret = DoubleToString( rate_tick.ret );
    //StringReplace(ret,".",",");
    
    m_model_vol.CalcularRisco(m_est2,m_rsel,m_rbuy);

    if( !write ) return 0;

    return FileWrite(csvFile,   dt                        ,
                 DoubleToString(rate_tick.rate.open       ,2),
                 DoubleToString(rate_tick.rate.high       ,2),
                 DoubleToString(rate_tick.rate.low        ,2),
                 DoubleToString(rate_tick.rate.close      ,2),
                 DoubleToString(rate_tick.rate.tick_volume,2),
                 DoubleToString(rate_tick.rate.real_volume,2),
                 DoubleToString(rate_tick.rate.spread     ,2),
                                rate_tick.first_time_msc  ,
                                rate_tick.last_time_msc   ,
                 DoubleToString(rate_tick.vol_buy,2       ),
                 DoubleToString(rate_tick.vol_sel,2       ),
                 DoubleToString(rate_tick.ret    ,2       ),
                 DoubleToString(rate_tick.lret            ),
                              //          ret             ,
                       DoubleToString( m_est2.getVolTradeBuyPorSeg(),2), // velocidade do volume de compras
                       DoubleToString( m_est2.getVolTradeSelPorSeg(),2), // velocidade do volume de vendas
                       DoubleToString( m_est2.getVolTradeLiqPorSeg(),2), // velocidade do volume liquido
                       DoubleToString( m_est2.getAceVolBuy()        ,2), // aceleracao da velocidade do volume de compra
                       DoubleToString( m_est2.getAceVolSel()        ,2), // aceleracao da velocidade do volume de vendas
                       DoubleToString( m_est2.getAceVolLiq()        ,2), // aceleracao do volume liquido
                       DoubleToString( m_rbuy                       ,2), // risco posicao buy
                       DoubleToString( m_rsel                       ,2), // risco posicao sell
                       calcDirecaoPreco( rate_tick.pup              , // 1 se, durante a formacao da barra, o preco subiu  em relacao ao fechamento da barra anterior
                                         rate_tick.pdw              ) // 1 se, durante a formacao da barra, o preco desceu em relacao ao fechamento da barra anterior
                             // round( m_est2.getVolTradeBuyPorSeg()), // velocidade do volume de compras
                             // round( m_est2.getVolTradeSelPorSeg()), // velocidade do volume de vendas
                             // round( m_est2.getVolTradeLiqPorSeg()), // velocidade do volume liquido
                             // round( m_est2.getAceVolBuy()*10     ), // aceleracao da velocidade do volume de compra
                             // round( m_est2.getAceVolSel()*10     ), // aceleracao da velocidade do volume de vendas
                             // round((m_est2.getAceVolBuy() - 
                             //        m_est2.getAceVolSel()  )*10  ), // aceleracao do volume liquido
                             // round( m_rbuy*100 )                  , // risco posicao buy
                             // round( m_rsel*100 )                    // risco posicao sell
                                );
}

string Cexport::calcDirecaoPreco(int pup, int pdw){
    if( pup==1 ){
        if( pdw==1 ){
            return "p-updw";
        }else{
            return "p-up";
        }
    }else{
        if( pdw==1 ){
            return "p-dw";
        }else{
            return "p-nop";
        }
    }
    return "p-error";
}

int Cexport::openFileCSV2Write(datetime from, datetime to, string sufix){
    
    // data inicial. farah parte do nome do arquivo...
    string strFrom = TimeToString(from,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
    StringReplace(strFrom,".","" );
    StringReplace(strFrom," ","_");
    StringReplace(strFrom,":","_");

    // data final. farah parte do nome do arquivo...
    string strTo = TimeToString(to,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
    StringReplace(strTo,".",""  );
    StringReplace(strTo," ","_" );
    StringReplace(strTo,":","_" );

    string nameArqPos =   strFrom   + "_" +
                          strTo     + "_" + sufix + ".csv";

    Print(":-| ",__FUNCTION__,": Creating file ", nameArqPos, " in common file dir...");
    
    int file = FileOpen(nameArqPos, FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, ";");
    
    if( file<0 ){
        Print(":-( ",__FUNCTION__,": Error creating file: ", nameArqPos     );
        Print(":-( ",__FUNCTION__,": Erro code          : ", GetLastError() );
    }    
    return file;
}

void Cexport::closeFile(int file){ 
    Print(":-| ",__FUNCTION__,": Closing file ", file, " ...");
    FileClose(file); 
    Print(":-| ",__FUNCTION__,": File closed.");
}

enum ENUM_SCRIPT_TYPE{
    SCRIPT_TYPE_RATES      ,
    SCRIPT_TYPE_TICKS      ,
    SCRIPT_TYPE_RATES_TICKS
};

#property script_show_inputs
input ENUM_TIMEFRAMES  SCRIPT_RATES_TIME_FRAME = PERIOD_M1        ;
input int              QTD_SEG_ESTAT_VOLUME    = 5;
input int              QTD_SEG_INI_WRITE       = 6;
//input string           SCRIPT_SYMBOL         = "WIN$"   ;
input string           SCRIPT_SYMBOL           = "WINV20" ;
input datetime         DTINI = D'2020.08.27 09:06:00';
input datetime         DTFIM = D'2020.08.27 17:54:00';
input ENUM_SCRIPT_TYPE SCRIPT_TYPE             = SCRIPT_TYPE_RATES_TICKS;
void OnStart(){
    
    string symbol = SCRIPT_SYMBOL;
    if( symbol == NULL || symbol == "" ){
        symbol = Symbol();
    }
    
//  datetime dtIni = D'2020.08.27 09:06:00';
//  datetime dtFim = D'2020.08.27 17:54:00';
    datetime dtIni = DTINI;
    datetime dtFim = DTFIM;
    
    
    switch( SCRIPT_TYPE ){
        case SCRIPT_TYPE_RATES      : exportRates     (symbol, dtIni, dtFim); break;
        case SCRIPT_TYPE_TICKS      : exportTicks     (symbol, dtIni, dtFim); break;
        case SCRIPT_TYPE_RATES_TICKS: exportRatesTicks(symbol, dtIni, dtFim); break;
    }
}


void exportRates(string symbol, datetime dtIni, datetime dtFim){
    Print(":-| ",__FUNCTION__,": **** START RATES EXPORT FOR ",symbol," and period ",SCRIPT_RATES_TIME_FRAME," ****");

    int qtdRates = 0;
    Cexport expRates;
    qtdRates = expRates.exportRates2CSV(dtIni, dtFim, symbol,SCRIPT_RATES_TIME_FRAME);
    Print(":-| ",__FUNCTION__,": **** END RATES EXPORT ****\n");
}

void exportTicks(string symbol, datetime dtIni, datetime dtFim){
    Print(":-| ",__FUNCTION__,": **** START TICKS EXPORT FOR ",symbol," ****");


    int qtdTicks = 0;
    Cexport expTicks;
    qtdTicks = expTicks.exportTicks2CSV(dtIni, dtFim, symbol);
    Print(":-| ",__FUNCTION__,": **** END TICKS EXPORT ****\n");
}

void exportRatesTicks(string symbol, datetime dtIni, datetime dtFim ){
    Print(":-| ",__FUNCTION__,": **** START RATES_TICKS EXPORT FOR ",symbol," ****");

    int qtdTicks = 0;
    Cexport expTicks;
    qtdTicks = expTicks.exportRatesTicks2CSV(dtIni, dtFim, symbol              ,
                                                           1                   ,   // timeFrame em segundos
                                                           QTD_SEG_ESTAT_VOLUME,   // periodoEst
                                                           false               ,    // corrigirTicks=false
                                                           QTD_SEG_INI_WRITE   );  // qtdSegIniWrite=0
    Print(":-| ",__FUNCTION__,": **** END RATES_TICKS EXPORT ****\n");
}

//+------------------------------------------------------------------+

