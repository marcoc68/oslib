﻿//+------------------------------------------------------------------+
//|                                               logbook2sql-01.mq5 |
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
 //string nameLogFile = "20200107-modal-prod-experts.log";  // ok
 //string nameSqlFile = "20200107-modal-prod-experts.sql";  // ok
 //string nameLogFile = "20200108-modal-prod-experts.log";  // ok modal prod VPS
 //string nameSqlFile = "20200108-modal-prod-experts.sql";  // ok modal prod VPS
   string nameLogFile = "20200109-modal-prod-experts.log";
   string nameSqlFile = "20200109-modal-prod-experts.sql";

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
    string result[];
    ushort sep = StringGetCharacter("	",0);
    string sqlCommand;
    int    qtd  = 0;
    int    pos1 = 0;
    
    Print("Lendo arquivo log ", logFile, " e criando comandos sql no arquivo", sqlFile," ...");
  //while( !FileIsEnding(logFile) && qtd++ < 5){
    while( !FileIsEnding(logFile)               ){

        // lendo a linha do log...
        line     = FileReadString(logFile);

        // colocando os campos do log em um array...
        StringSplit( line  , // A string que será pesquisada 
                     sep   , // Um separador usado para buscar substrings 
                     result  // Um array passado por referencia para obter as substrings encontradas 
        );

        //nivel    = result[1];
        //data     = result[2];
        //origem   = result[3];
        //dados    = result[4];
        sqlCommand = result[4];
        
        pos1   = StringFind(sqlCommand,"insert");
        if( pos1 > -1 ){
            FileWrite(sqlFile,sqlCommand);
        }
        
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
    Print("Arquivo log fechado!!!");
}
void closeSqlFile(int sqlFile){ 
    Print("Fechando arquivo sql", sqlFile, " ...");
    FileClose(sqlFile); 
    Print("Arquivo sql fechado!!!");
}