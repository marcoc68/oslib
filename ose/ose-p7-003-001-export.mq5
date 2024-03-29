﻿//+------------------------------------------------------------------+
//|                                        ose-p7-003-001-export.mq5 |
//|                                          Copyright 2020, OS Corp |
//|                                                http://www.os.org |
//|                                                                  |
//| Versao p7-003-001                                                |
//| 1. Exporta ticks e book de ofertas para o arquivo de log.        |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, OS Corp."
#property link      "http://www.os.org"
#property version   "3.1"

#include <Trade\AccountInfo.mqh>

enum ENUM_TYPE_LINE {
    TYPE_LINE_SQL, // generetes sql lines
    TYPE_LINE_CSV  // generetes csv lines
};
enum ENUM_TYPE_ARQ {
    TYPE_ARQ_TERMINAL_LOGFILE, // write lines in terminal logfile
    TYPE_ARQ_NEW_FILE          // write lines in new file
};
enum ENUM_TYPE_EXPORT {
    TYPE_EXPORT_TICK, // exportacao de ticks
    TYPE_EXPORT_BOOK, // exportacao do book de ofertas
    TYPE_EXPORT_ALL   // exportacao de ticks e do book
};

input ENUM_TYPE_EXPORT EA_TYPE_EXPORT    = TYPE_EXPORT_ALL  ; // TYPE_EXPORT
input ENUM_TYPE_LINE   EA_TYPE_LINE      = TYPE_LINE_SQL    ; // TYPE_LINE
input string           EA_CSV_SEPARATOR  = ";"              ; // CSV_SEPARATOR
input ENUM_TYPE_ARQ    EA_TYPE_ARQ       = TYPE_ARQ_NEW_FILE; // TYPE_ARQ

// estrutura de tick com campos na mesma posicao gravada no arquivo.
struct st_tick {
    string microsec   ; // microsegundos
    string time       ; // timestamp ateh segundos
    string time_msc   ; // timestamp ateh milisegundos
    string ask        ; // melhor ask
    string bid        ; // melhor bid
    string last       ; // preco da ultima negociacao
    string volume     ; // volume de ticks
    string volume_real; // volume real
    string tbuy       ; // houve transacao se compra
    string tsel       ; // houve transacao de venda
    string task       ; // houve mudanca no melhor ask
    string tbid       ; // houve mudanca no melor bid
    string tlas       ; // houve mudanca no ultimo valor negociado
    string tvol       ; // houve mudanca no volume
    string flags      ; // flag resumida de mudancas
    string corretora  ; // corretora
};

int m_file_saida;

string  m_symb_str;
MqlTick m_tick;
string  m_server_str;
long    m_time_msc;    
bool    m_processar_book = false;
bool    m_processar_tick = false;
int OnInit(){
    m_symb_str=Symbol();
    
    m_processar_book = false;
    if( EA_TYPE_EXPORT == TYPE_EXPORT_BOOK || EA_TYPE_EXPORT == TYPE_EXPORT_ALL ){
        if( !MarketBookAdd(m_symb_str) ){
            Print(":-( NAO ADICIONOU ", m_symb_str, " PARA LEITURA DE BOOK. ERRO:", GetLastError() );
        }
        m_processar_book = true;
    }

    m_processar_tick = false;
    if( EA_TYPE_EXPORT == TYPE_EXPORT_TICK || EA_TYPE_EXPORT == TYPE_EXPORT_ALL ) m_processar_tick = true;


    CAccountInfo account;
    m_server_str = account.Server(); // nome do servidor de negociacao onde as cotacoes sao obtidas
    
    if(EA_TYPE_ARQ==TYPE_ARQ_NEW_FILE){
        m_file_saida = openFile2Write(TimeCurrent(),"sql");
    }
    
    m_time_msc = TimeCurrent()*1000;
    
    Sleep(1000);
    return(0);
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
datetime m_tctick ;
datetime m_ttstick;
string m_linha_tick;
void OnTick(){
    SymbolInfoTick(m_symb_str, m_tick);
    
    if( !m_processar_tick ) return;
    
    m_time_msc = m_tick.time_msc;
    
    montar_st_tick();

    if (EA_TYPE_LINE == TYPE_LINE_CSV) montar_str_tick_csv(m_linha_tick); else
    if (EA_TYPE_LINE == TYPE_LINE_SQL) montar_str_tick_sql(m_linha_tick);

    if (EA_TYPE_ARQ == TYPE_ARQ_TERMINAL_LOGFILE) Print    (              m_linha_tick); else
    if (EA_TYPE_ARQ == TYPE_ARQ_NEW_FILE        ) FileWrite(m_file_saida, m_linha_tick);
}

st_tick m_st_tick;
void montar_st_tick() { //
    m_st_tick.microsec    =   GetMicrosecondCount();
    m_st_tick.time        =   TimeToString(m_tick.time,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
    m_st_tick.time_msc    =   m_tick.time_msc      ;
    m_st_tick.ask         =   m_tick.ask           ;
    m_st_tick.bid         =   m_tick.bid           ;
    m_st_tick.last        =   m_tick.last          ;
    m_st_tick.volume      =   m_tick.volume_real   ;
    m_st_tick.tbuy        = ((m_tick.flags & TICK_FLAG_BUY   ) == TICK_FLAG_BUY   )?"1":"0";
    m_st_tick.tsel        = ((m_tick.flags & TICK_FLAG_SELL  ) == TICK_FLAG_SELL  )?"1":"0";
    m_st_tick.task        = ((m_tick.flags & TICK_FLAG_ASK   ) == TICK_FLAG_ASK   )?"1":"0";
    m_st_tick.tbid        = ((m_tick.flags & TICK_FLAG_BID   ) == TICK_FLAG_BID   )?"1":"0";
    m_st_tick.tlas        = ((m_tick.flags & TICK_FLAG_LAST  ) == TICK_FLAG_LAST  )?"1":"0";
    m_st_tick.tvol        = ((m_tick.flags & TICK_FLAG_VOLUME) == TICK_FLAG_VOLUME)?"1":"0";
    m_st_tick.flags       =   m_tick.flags         ;
  //m_st_tick.corretora   =   ""                   ;
}

void montar_str_tick_csv(string &linha_tick) {
    linha_tick =   ";tick;"                             +
                   m_st_tick.microsec + EA_CSV_SEPARATOR+
                   m_st_tick.time     + EA_CSV_SEPARATOR+
                   m_st_tick.time_msc + EA_CSV_SEPARATOR+
                   m_st_tick.ask      + EA_CSV_SEPARATOR+
                   m_st_tick.bid      + EA_CSV_SEPARATOR+
                   m_st_tick.last     + EA_CSV_SEPARATOR+
                   m_st_tick.volume   + EA_CSV_SEPARATOR+
                   m_st_tick.tbuy     + EA_CSV_SEPARATOR+
                   m_st_tick.tsel     + EA_CSV_SEPARATOR+
                   m_st_tick.task     + EA_CSV_SEPARATOR+
                   m_st_tick.tbid     + EA_CSV_SEPARATOR+
                   m_st_tick.tlas     + EA_CSV_SEPARATOR+
                   m_st_tick.tvol     + EA_CSV_SEPARATOR+
                   m_st_tick.flags                      ;
}

void montar_str_tick_sql(string &linha_tick){

    linha_tick = StringFormat( "insert "
                                 "into tick(ticker,microsec,dt,dt_msc,ask,bid,las,volume,tbuy,tsel,task,tbid,tlas,tvol,flags)"
                               "values('%s',%s,'%s',%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);",
                                m_symb_str           ,
                                m_st_tick.microsec   ,
                                m_st_tick.time       ,
                                m_st_tick.time_msc   ,
                                m_st_tick.ask        ,
                                m_st_tick.bid        ,
                                m_st_tick.last       ,
                                m_st_tick.volume     ,
                                m_st_tick.tbuy       ,
                                m_st_tick.tsel       ,
                                m_st_tick.task       ,
                                m_st_tick.tbid       ,
                                m_st_tick.tlas       ,
                                m_st_tick.tvol       ,
                                m_st_tick.flags      );
} 
//+------------------------------------------------------------------+

struct st_level_book {
    string      level   ; // nivel a partir do zero
    double      askp    ; // cotacao ask no nivel
    double      askv    ; // volume  ask no nivel
    double      bidp    ; // cotacao bid no nivel
    double      bidv    ; // volume  bid no nivel
    double      daskp   ; // cotacao ask no nivel
    double      daskv   ; // volume  ask no nivel
    double      dbidp   ; // cotacao bid no nivel
    double      dbidv   ; // volume  bid no nivel
};

// estrutura do book com campos na mesma posicao gravada no arquivo.
struct st_book {
    string      id2     ; // id de negocio da tabela book;
    string      microsec; // microsegundos
    string      time    ; // timestamp do servidor de negociacoes ateh segundos     em forma de data
    string      time_msc; // timestamp do servidor de negociacoes ateh milisegundos em forma de numero
  //MqlBookInfo book[]  ; // imagem do book de ofertas
    st_level_book book[]  ; // imagem do book de ofertas
};

st_book m_st_book;
ulong m_microsec_book;
//datetime m_timecurrent;
void montar_st_book( const MqlBookInfo& book[] ){
    m_microsec_book    = GetMicrosecondCount();
    m_st_book.time     = TimeToString(m_tick.time,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
    m_st_book.time_msc = m_time_msc; // coletado no ultimo tick processado
    m_st_book.id2      = IntegerToString(m_time_msc) + IntegerToString(m_microsec_book%1000000);
    m_st_book.microsec = m_microsec_book;
    //m_st_book.book     = book;
    for (int i = 0; book[i].type==BOOK_TYPE_SELL; i++) {
            m_st_book.book[i].level = i;
            
            // primeiros os deltas...
            m_st_book.book[i].daskp  = book[m_tamanhoBook/2-1 -i].price  - m_st_book.book[i].askp;
            m_st_book.book[i].daskv  = book[m_tamanhoBook/2-1 -i].volume - m_st_book.book[i].askv;
            m_st_book.book[i].dbidp  = book[m_tamanhoBook/2   +i].price  - m_st_book.book[i].bidp;
            m_st_book.book[i].dbidv  = book[m_tamanhoBook/2   +i].volume - m_st_book.book[i].bidv;
            // agora os precos e volumes...                            ;
            m_st_book.book[i].askp  = book[m_tamanhoBook/2-1 -i].price  ;
            m_st_book.book[i].askv  = book[m_tamanhoBook/2-1 -i].volume ;
            m_st_book.book[i].bidp  = book[m_tamanhoBook/2   +i].price  ;
            m_st_book.book[i].bidv  = book[m_tamanhoBook/2   +i].volume ;
    }
    
}

void montar_str_book_csv(const int tamanhoBook) {

    m_strbook = ";book;"           + EA_CSV_SEPARATOR +
                m_st_book.microsec + EA_CSV_SEPARATOR + 
                m_st_book.time                        ;

    for (int i = 0; i < m_tamanhoBook/2; i++) {
        m_strbook = m_strbook       + EA_CSV_SEPARATOR +
            m_st_book.book[i].level + EA_CSV_SEPARATOR +
            m_st_book.book[i].askp  + EA_CSV_SEPARATOR +
            m_st_book.book[i].askv  + EA_CSV_SEPARATOR +
            m_st_book.book[i].bidp  + EA_CSV_SEPARATOR +
            m_st_book.book[i].bidv                     ;
    }
    //for (int i = 0; i < tamanhoBook; i++) {
    //    m_strbook = m_strbook                     + EA_CSV_SEPARATOR +
    //                i                             + EA_CSV_SEPARATOR +
    //                m_st_book.book[i].type        + EA_CSV_SEPARATOR +
    //                m_st_book.book[i].price       + EA_CSV_SEPARATOR +
    //                m_st_book.book[i].volume_real                    ;
    ///}
}

void montar_str_book_sql(const int tamanhoBook) {
    m_strbook = StringFormat("insert into book(id2,ticker,microsec,dt,dt_msc)values(%s,'%s',%s,'%s',%s);",
                             m_st_book.id2     ,
                             m_symb_str        ,
                             m_st_book.microsec,
                             m_st_book.time    ,
                             m_st_book.time_msc);

    for (int i = 0; i < m_tamanhoBook/2; i++) {
        m_strbook = m_strbook + StringFormat("\ninsert into bookentry(id2,nivel,askp,askv,bidp,bidv,daskp,daskv,dbidp,dbidv)values(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);",
                                             m_st_book.id2          ,
                                             m_st_book.book[i].level,
                                             DoubleToString(m_st_book.book[i].askp ,_Digits) ,
                                             DoubleToString(m_st_book.book[i].askv ,_Digits) ,
                                             DoubleToString(m_st_book.book[i].bidp ,_Digits) ,
                                             DoubleToString(m_st_book.book[i].bidv ,_Digits) ,
                                             DoubleToString(m_st_book.book[i].daskp,_Digits) ,
                                             DoubleToString(m_st_book.book[i].daskv,_Digits) ,
                                             DoubleToString(m_st_book.book[i].dbidp,_Digits) ,
                                             DoubleToString(m_st_book.book[i].dbidv,_Digits) );
    }
    
    //for (int i = 0; m_st_book.book[i].type==m_st_book.book[i+1].type; i++) {
    //    m_strbook = m_strbook + "\ninsert into bookentry(book_id2,nivel,askp,askv,bidp,bidv)values(%s, '%s', %s, '%s');",
    //        i,
    //        m_st_book.book[i              ].price ,
    //        m_st_book.book[i              ].volume,
    //        m_st_book.book[i+tamanhoBook/2].price ,
    //        m_st_book.book[i+tamanhoBook/2].volume;
    //}
}


MqlBookInfo m_book[];
int         m_tamanhoBook = 0;
datetime    m_tcbook ;
datetime    m_ttsbook;
string      m_strbook;
void OnBookEvent(const string& symbol){
    if( !m_processar_book              ) return;
    if(  symbol != m_symb_str          ) return;
    if( !MarketBookGet(symbol, m_book) ) return;
    if( m_tamanhoBook==0 ){ 
        m_tamanhoBook = ArraySize(m_book);
        ArrayResize(m_st_book.book,m_tamanhoBook/2);
    }
    
    montar_st_book(m_book);
    if (EA_TYPE_LINE == TYPE_LINE_CSV) montar_str_book_csv(m_tamanhoBook); else
    if (EA_TYPE_LINE == TYPE_LINE_SQL) montar_str_book_sql(m_tamanhoBook);

    if (EA_TYPE_ARQ == TYPE_ARQ_TERMINAL_LOGFILE) Print    (              m_strbook); else
    if (EA_TYPE_ARQ == TYPE_ARQ_NEW_FILE        ) FileWrite(m_file_saida, m_strbook);    
}

void OnBookEventAntigo(const string& symbol){

    m_tcbook  = TimeCurrent()    ;
    m_ttsbook = TimeTradeServer();

    if( symbol != m_symb_str           ) return;
    if( !MarketBookGet(symbol, m_book) ) return;
    
    if( m_tamanhoBook==0 ) m_tamanhoBook = ArraySize(m_book);
    m_strbook = ";book;" + GetMicrosecondCount() + EA_CSV_SEPARATOR + 
                         + m_tcbook              + EA_CSV_SEPARATOR ;
    for( int i=0; i<m_tamanhoBook; i++ ){
        m_strbook = m_strbook + 
             //GetMicrosecondCount()                                           + EA_CSV_SEPARATOR+
               i                                                               + EA_CSV_SEPARATOR+
               m_book[i].type                                                  + EA_CSV_SEPARATOR+
               m_book[i].price                                                 + EA_CSV_SEPARATOR+
               m_book[i].volume                                                + EA_CSV_SEPARATOR+
               m_book[i].volume_real                                           + EA_CSV_SEPARATOR;
        //Print( GetMicrosecondCount()                                           , EA_CSV_SEPARATOR,
        //       i                                                               , EA_CSV_SEPARATOR,
        //       TimeToString(m_tcbook , TIME_DATE | TIME_MINUTES | TIME_SECONDS), EA_CSV_SEPARATOR,
        //     //TimeToString(m_ttsbook, TIME_DATE | TIME_MINUTES | TIME_SECONDS), EA_CSV_SEPARATOR,
        //       m_book[i].type                                                  , EA_CSV_SEPARATOR,
        //       m_book[i].price                                                 , EA_CSV_SEPARATOR,
        //       m_book[i].volume                                                , EA_CSV_SEPARATOR,
        //       m_book[i].volume_real                                                             );
    }
    if( EA_TYPE_ARQ == TYPE_ARQ_TERMINAL_LOGFILE ){
        Print(m_strbook);
    }else{
        // colocar aqui o codigo pra gravar em um arquivo csv
    }
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
      MarketBookRelease(m_symb_str);
    if(EA_TYPE_ARQ==TYPE_ARQ_NEW_FILE){
        closeFile( m_file_saida );
    }
      
}
  
int openFile2Write(datetime from, string sufix){
    
    // data inicial. farah parte do nome do arquivo...
    string strFrom = TimeToString(from,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
    StringReplace(strFrom,".","" );
    StringReplace(strFrom," ","_");
    StringReplace(strFrom,":","_");
    
    string texp = (EA_TYPE_EXPORT==TYPE_EXPORT_ALL )?"_all" :
                  (EA_TYPE_EXPORT==TYPE_EXPORT_TICK)?"_tick":
                  (EA_TYPE_EXPORT==TYPE_EXPORT_BOOK)?"_book":"_erro";

    string nameArqPos = strFrom + texp + "." + sufix;

    Print(":-| ",__FUNCTION__,": Creating file ", nameArqPos, " in common file dir...");
    
    int file = FileOpen(nameArqPos, FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON, ";");
    
    if( file<0 ){
        Print(":-( ",__FUNCTION__,": Error creating file: ", file        );
        Print(":-( ",__FUNCTION__,": Erro code          : ", GetLastError() );
    }    
    return file;
}

void closeFile(int file){
    Print(":-| ",__FUNCTION__,": Closing file ", file, " ...");
    FileClose(file); 
    Print(":-| ",__FUNCTION__,": File closed.");
}
