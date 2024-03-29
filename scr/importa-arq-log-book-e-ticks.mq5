﻿//+------------------------------------------------------------------+
//|                                  importa-arq-log-book-e-tick.mq5 |
//|                                         Copyright 2020, OS Corp. |
//|                                                http://www.os.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "1.001"

#include <Files\FileTxt.mqh>
//+------------------------------------------------------------------------+
//| Importa log do terminal mql com string csv referente ao ticks e ao book|
//+------------------------------------------------------------------------+

// estrutura com campos na mesma posicao gravada no arquivo.
struct st_tick{
   string tick       ; //constante "tick"
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
   string flags      ; // flas resumida de mudancas
   string corretora  ; // corretora
};
enum POSICAO_CAMPOS_BOOK{
   DT_SESSAO = 0,
   SYMBOL    = 1,
   SENTIDO   = 2,
   SEQ       = 3,
   GEN_ID    = 4,
   COD_EVT   = 5,
   HR_PRIOR  = 6,
   IND_PRIOR = 7,
   PRECO     = 8,
   QTD_TOT   = 9,
   QTD_NEG   =10,
   DT_OFERTA =11,
   DT_ENTRADA=12,
   ESTADO    =13,
   CONDICAO  =14,
   CORRETORA =15,
};

void OnStart(){
   string nameArqBookBuy  = "OFER_CPA_BMF_20191211_WDO.TXT";
   string nameArqSqlBuy   = "OFER_CPA_BMF_20191211_WDO.SQL";

   string nameArqBookSel  = "OFER_VDA_BMF_20191211_WDO.TXT";
   string nameArqSqlSel   = "OFER_VDA_BMF_20191211_WDO.SQL";


   //int bookFile = openReadFile (nameArqBookBuy);
   //int sqlFile  = openWriteFile(nameArqSqlBuy );
   //importarArquivo(bookFile,sqlFile);
   //closeFile(bookFile);   
   //closeFile(sqlFile);   

   int bookFile = openReadFile (nameArqBookSel);
   int sqlFile  = openWriteFile(nameArqSqlSel );
   importarArquivo(bookFile,sqlFile);
   closeFile(bookFile);   
   closeFile(sqlFile);   

}
//+------------------------------------------------------------------+

void importarArquivo(int bookFile, int sqlFile){
    string  line;
    ushort  sep = StringGetCharacter(";",0);
    string  result[];
    st_book book;
    int     qtd = 0;
    
    Print("Lendo arquivo ", bookFile, " ...");
  //while( !FileIsEnding(bookFile) && qtd++ < 10){
    while( !FileIsEnding(bookFile)              ){

        // lendo a linha ...
        //Print("lendo linha ", qtd,"...");
        line     = FileReadString(bookFile);
        //Print("lida linha ", qtd,":", line);

        // colocando os campos do log em um array...
        StringSplit( line  ,  // A string que será pesquisada 
                     sep   ,  // Um separador usado para buscar substrings 
                     result); // Um array passado por referencia para obter as substrings encontradas 
/*
        book.dt_sessao  = StringToTime   ( result[DT_SESSAO ] );
        book.symbol     =                  result[SYMBOL    ]  ; StringTrimRight(book.symbol);
        book.sentido    = StringToInteger( result[SENTIDO   ] );
        book.seq        = StringToInteger( result[SEQ       ] );
        book.gen_id     = StringToInteger( result[GEN_ID    ] );
        book.cod_evt    = StringToInteger( result[COD_EVT   ] );
        book.hr_prior   = StringToTime   ( StringSubstr( result[DT_SESSAO ], 0,10 )+ " " + 
                                           StringSubstr( result[HR_PRIOR  ], 0, 8 )      ); //09:00:50.092000
        book.ms_prior   = StringToInteger( StringSubstr( result[HR_PRIOR  ], 9, 6 )      ); //09:00:50.092000
        book.ind_prior  = StringToInteger( result[IND_PRIOR ] );
        book.preco      = StringToDouble ( result[PRECO     ] );
        book.qtd_tot    = StringToInteger( result[QTD_TOT   ] );
        book.qtd_neg    = StringToInteger( result[QTD_NEG   ] );
        book.dt_oferta  = StringToTime   ( result[DT_OFERTA ] );
        book.dt_entrada = StringToTime   ( result[DT_ENTRADA] );
        book.estado     = StringToInteger( result[ESTADO    ] );
        book.condicao   = StringToInteger( result[CONDICAO  ] );
        book.corretora  = StringToInteger( result[CORRETORA ] );
*/        
        book.dt_sessao  =                  result[DT_SESSAO ]  ;
        book.symbol     =                  result[SYMBOL    ]  ; StringTrimRight(book.symbol);
        book.sentido    =                  result[SENTIDO   ]  ;
        book.seq        =                  result[SEQ       ]  ;
        book.gen_id     =                  result[GEN_ID    ]  ;
        book.cod_evt    =                  result[COD_EVT   ]  ;
        book.hr_prior   =                  StringSubstr( result[DT_SESSAO ], 0,10 )+ " " + 
                                           StringSubstr( result[HR_PRIOR  ], 0, 8 )       ; //09:00:50.092000
        book.ms_prior   =                  StringSubstr( result[HR_PRIOR  ], 9, 6 )       ; //09:00:50.092000
        book.ind_prior  =                  result[IND_PRIOR ]  ;
        book.preco      =                  result[PRECO     ]  ;
        book.qtd_tot    =                  result[QTD_TOT   ]  ;
        book.qtd_neg    =                  result[QTD_NEG   ]  ;
        book.dt_oferta  =                  result[DT_OFERTA ]  ;
        book.dt_entrada =                  result[DT_ENTRADA]  ;
        book.estado     =                  result[ESTADO    ]  ;
        book.condicao   =                  result[CONDICAO  ]  ;
        book.corretora  =                  result[CORRETORA ]  ;
        
        gravarSql(book, sqlFile);

/*      
        Print(book.dt_sessao ,"|",
              book.symbol    ,"|",
              book.sentido   ,"|",
              book.seq       ,"|",
              book.gen_id    ,"|",
              book.cod_evt   ,"|",
              book.hr_prior  ,"|",
              book.ms_prior  ,"|",
              book.ind_prior ,"|",
              book.preco     ,"|",
              book.qtd_tot   ,"|",
              book.qtd_neg   ,"|",
              book.dt_oferta ,"|",
              book.dt_entrada,"|",
              book.estado    ,"|",
              book.condicao  ,"|",
              book.corretora ,"|");
*/
//2019.12.11 00:00:00|WDOF20|2|743788788920|87601574 |2 |1576055094|390000|733659552|4164.0|5|0|2019.12.11 00:00:00|2019.12.11 09:04:54|5|0|3|
//2019.12.11 00:00:00|WDOF20|2|743788788920|98139628 |2 |1576063373|820000|822348016|4160.0|5|0|2019.12.11 00:00:00|2019.12.11 11:22:53|5|0|3|
//2019.12.11 00:00:00|WDOF20|2|743788788920|133314369|11|1576092600|22000 |822348016|4160.0|5|0|2019.12.11 00:00:00|2019.12.11 19:30:00|0|0|3|
              
//2019.12.11 00:00:00|WDOF20|2|743788788920|87601574 |2 |1576055094|390000|733659552|4164.0|5|0|2019.12.11 00:00:00|2019.12.11 09:04:54|5|0|3|
//2019.12.11 00:00:00|WDOF20|2|743788788920|98139628 |2 |1576063373|820000|822348016|4160.0|5|0|2019.12.11 00:00:00|2019.12.11 11:22:53|5|0|3|
//2019.12.11 00:00:00|WDOF20|2|743788788920|133314369|11|1576092600|22000|822348016|4160.0|5|0|2019.12.11 00:00:00|2019.12.11 19:30:00|0|0|3|
    }
}

void gravarSql(st_book& book, int sqlFile){

   string sqlCommand = 
   StringFormat( "insert "
                   "into b3_book (dt_sessao, symbol, sentido, seq, gen_id, id_evt, prior_hr, prior_ms, prior_in, price, qtd_tot, qtd_neg, dt_incl, dt_entrada, estado_id, condicao_id, corretora_id) "
                 "values('%s','%s',%s,%s,%s,%s,'%s',%s,%s,%s,%s,%s,'%s','%s','%s',%s,%s);",
                  book.dt_sessao ,
                  book.symbol    ,
                  book.sentido   ,
                  book.seq       ,
                  book.gen_id    ,
                  book.cod_evt   ,
                  book.hr_prior  ,
                  book.ms_prior  ,
                  book.ind_prior ,
                  book.preco     ,
                  book.qtd_tot   ,
                  book.qtd_neg   ,
                  book.dt_oferta ,
                  book.dt_entrada,
                  book.estado    ,
                  book.condicao  ,
                  book.corretora );
//VALUES('', '', 0, 0, 0, 0, '', 0, 0, 0, 0, 0, '', '', 0, 0, 0);
   FileWrite(sqlFile,sqlCommand);

}

int openReadFile(string arq){
    
    Print("Abrindo arquivo ", arq, " no diretorio comum de arquivos...");
  //int file = FileOpen(arq, FILE_READ|FILE_TXT|FILE_COMMON        );
  //int file = FileOpen(arq, FILE_READ|FILE_TXT|FILE_COMMON,CP_UTF8);
  //int file = FileOpen(arq, FILE_READ|FILE_TXT|FILE_COMMON,';');
  //int file = FileOpen(arq, FILE_READ|FILE_TXT|FILE_COMMON,';',CP_UTF8);
  //int file = FileOpen(arq, FILE_READ|FILE_TXT|FILE_COMMON,StringGetCharacter(";",0),CP_UTF8);
  //int file = FileOpen(arq, FILE_READ|FILE_TXT|FILE_ANSI        );
    int file = FileOpen(arq, FILE_READ|FILE_TXT|FILE_COMMON|FILE_ANSI);
    
    if( file<0 ){
        Print("Falha para abrir o arquivo: ", arq            );
        Print("Codigo de erro: "            , GetLastError() );
    }    
    return file;
}

int openWriteFile(string arq){    
    Print("Criando arquivo ", arq, " no diretorio comum de arquivos...");
      int file = FileOpen(arq, FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
    //int file = FileOpen(arq, FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON,'\t',CP_UTF8);
    if( file<0 ){
        Print("Falha para abrir o arquivo : ", arq            );
        Print("Codigo de erro: "             , GetLastError() );
    }
    return file;
}


void closeFile(int file){ 
    Print("Fechando arquivo ", file, " ...");
    FileClose(file); 
}
