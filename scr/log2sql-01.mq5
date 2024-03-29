﻿//+------------------------------------------------------------------+
//|                                                   log2sql-01.mq5 |
//|                                         Copyright 2020, OS Corp. |
//|                                                http://www.os.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "1.001"

#include <Files\FileTxt.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

void OnStart(){
   string nameLogFile = "20191227-modal-prod-diario-v1.log";
   string nameSqlFile = "20191227-modal-prod-diario-v1.sql";

   //Print("Abrindo arquivo ", nameLogFile, " no diretorio comum de arquivos...");
   int logFile = openLogFile(nameLogFile);
   int sqlFile = openSqlFile(nameSqlFile);

   readLogFileAndWriteSqlFile(logFile, sqlFile);

   closeLogFile(logFile);
   closeSqlFile(sqlFile);
}
//+------------------------------------------------------------------+

void readLogFileAndWriteSqlFile(int logFile, int sqlFile){
    string line;
    string nivel;
    string data;
    string origem;
    string dados;
    string conta;
    string oper;
    string valor;
    string timecorr; // tempo informado pela corretora
    string tipo;
    string fase;
    string order,deal;
    int    qtd = 0;
    int    pos1 = 0;
    int    pos2 = 0;
    string result[];
    ushort sep = StringGetCharacter("	",0);
    string sqlCommand;

    Print("Lendo arquivo log ", logFile, " e criando comandos sql no arquivo", sqlFile," ...");
  //while( !FileIsEnding(logFile) && qtd++ < 500){
    while( !FileIsEnding(logFile)               ){

        // lendo a linha do log...
        line     = FileReadString(logFile);

        // colocando os campos do log em um array...
        StringSplit( line  , // A string que será pesquisada
                     sep   , // Um separador usado para buscar substrings
                     result  // Um array passado por referencia para obter as substrings encontradas
           );

        nivel    = result[1];
        data     = result[2];
        origem   = result[3];
        dados    = result[4];

      //data     = StringSubstr(line,5,12);
      //origem   = StringSubstr(line,18,12);

        conta = "null";
        if( StringSubstr(dados,0,1)=="'" ){ // condicao para que a linha comece com uma conta
            conta = StringSubstr(dados,1, StringFind(dados,"'",1)-1 );
        }

        oper     = StringFind(dados,"sell"                )>-1?"sell limit"          :
                   StringFind(dados,"buy"                 )>-1?"buy limit"           :"";

        fase = "";
        if( oper=="sell limit" || oper=="buy limit" ){
            fase     = StringFind(dados,"accepted"            )>-1?"accepted"            :
                       StringFind(dados,"rejected"            )>-1?"rejected"            :
                       StringFind(dados,"placed for execution")>-1?"placed for execution":
                       StringFind(dados,"deal"                )>-1?"deal"                :
                       StringFind(dados,"done"                )>-1?"done"                :
                       StringFind(dados,"failed"              )>-1?"failed"              :"pedido";
        }

        tipo     = StringFind(dados,"cancel"                 )>-1?"CAN"                 :"";

        order = "0";
        pos1   = StringFind(dados,"order #");
        if( pos1 > -1 ){
            order = StringSubstr(dados,pos1+7,8);
        }

        deal = "0";
        pos1   = StringFind(dados,"deal #");
        if( pos1 > -1 ){
            deal = StringSubstr(dados,pos1+6,8);
        }

        valor = "null";
        pos1   = StringFind(dados,"at ");
        if( pos1 > -1 ){
            valor = StringSubstr(dados,pos1+3,6);
            if( valor=="market") valor = "null";
        }

        timecorr = "null";
        pos1   = StringFind(dados,"done in ");
        pos2   = StringFind(dados," ms"     );
        if( pos1 > -1 && pos2 > -1 ){
            timecorr = StringSubstr(dados,pos1+8,pos2-pos1-8);
            StringReplace(timecorr,".","");
        }



        //Print( "insert into log_diario values('2019-12-27 ",data ,"','",
        //                                                    oper ,"','",
        //                                                    fase ,"','",
        //                                                    tipo ,"','",
        //                                                    order,",'" ,
        //                                                    line ,"');");

        StringReplace(line,"'","");
        sqlCommand = StringFormat( "insert "
                                     "into log_diario (niv,dt,timecorr,origem,conta,oper,valor,fase,tipo,ordem,deal,linhalog) "
                                   "values(%s,'2019-12-27 %s',%s,'%s',%s,'%s',%s,'%s','%s',%s,%s,'%s');",
                                    nivel   ,
                                    data    ,
                                    timecorr,
                                    origem  ,
                                    conta   ,
                                    oper    ,
                                    valor   ,
                                    fase    ,
                                    tipo    ,
                                    order   ,
                                    deal    ,
                                    line    );
        FileWrite(sqlFile,sqlCommand);

    }

}



int openLogFile(string arqLog){

    Print("Abrindo arquivo log ", arqLog, " no diretorio comum de arquivos...");
    //return FileOpen(arqLog, FILE_READ|FILE_TXT|FILE_COMMON);
    int file = FileOpen(arqLog, FILE_READ|FILE_TXT|FILE_COMMON);

    if( file<0 ){
        Print("Falha para abrir o arquivo: ", arqLog         );
        Print("Codigo de erro: "            , GetLastError() );
    }
    return file;
}
int openSqlFile(string arqSql){

    Print("Criando arquivo sql ", arqSql, " no diretorio comum de arquivos...");
    //return FileOpen(arqLog, FILE_READ|FILE_TXT|FILE_COMMON);
    int file = FileOpen(arqSql, FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);

    if( file<0 ){
        Print("Falha para abrir o arquivo sql: ", arqSql         );
        Print("Codigo de erro: "                , GetLastError() );
    }
    return file;
}


void closeLogFile(int logFile){
    Print("Fechando arquivo log", logFile, " ...");
    FileClose(logFile);
}
void closeSqlFile(int sqlFile){
    Print("Fechando arquivo sql", sqlFile, " ...");
    FileClose(sqlFile);
}