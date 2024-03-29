﻿//+------------------------------------------------------------------+
//|                               exporta_ordens_e_ofertas_2_sql.mq5 |
//|                                         Copyright 2020, OS Corp. |
//|                                                http://www.os.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "1.001"

#include <Files\FileTxt.mqh>
#include <Trade\HistoryOrderInfo.mqh>
#include <Trade\DealInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <oslib\osc\osc-minion-trade-estatistica.mqh>

CAccountInfo       m_account      ;
CHistoryOrderInfo  m_order        ;
CDealInfo          m_deal         ;
string             m_strAspa = "'";


//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart(){
   datetime from = D'2020.07.03';
   datetime to   = D'2020.07.04'; //TimeCurrent();

   Print(from,to);

   // data inicial. farah parte do nome do arquivo...
   string strFrom = TimeToString(from,TIME_DATE);
   StringReplace(strFrom,".","");

   // data final. farah parte do nome do arquivo...
   string strTo = TimeToString(to,TIME_DATE);
   StringReplace(strTo,".","");

   // obtendo o primeiro nome da corretora (farah parte do nome do arquivo)...
   string company = m_account.Company();
   company = StringSubstr(company,0,StringFind(company," "));
   //company =

   // obtendo o primeiro nome do trademode (deve ser "Demo" ou "Real" e farah parte do nome do arquivo)...
   string trademode = m_account.TradeModeDescription();
   trademode = StringSubstr(trademode,0,StringFind(trademode," "));

   string   nameSqlFile = strFrom   + "-" +
                          strTo     + "-" +
                          company   + "-" +
                          trademode + "-ordens-ofertas.sql";
                          
   int sqlFile = openSqlFile(nameSqlFile);

   // 1. gravamos as ordens no arquivo sql...
   readOrdersAndWriteSqlFile(sqlFile,from,to);

   // 2. gravamos as ofertas (deals)...
   readDealsAndWriteSqlFile(sqlFile,from,to);
   
   // 3. gravamos os comandos sql que transferem os comentarios para colunas especificas...
   writeSqlUpdateDeals(sqlFile);
   writeSqlUpdateOrdens(sqlFile);
   
   // 4. fechamos o arquivo...
   closeSqlFile(sqlFile);
   
   // 5. montando arquivo de posicoes...
   osc_minion_trade_estatistica m_trade_estatistica;   
   m_trade_estatistica.print_posicoes(from, to);

}
//+------------------------------------------------------------------+

void readOrdersAndWriteSqlFile(int sqlFile, datetime from, datetime to){
    string sqlCommand;
    string strVirgula = "," ;

    Print(":-| Obtendo historico de ordens...");
    HistorySelect(from,to);

    uint totalOrders=HistoryOrdersTotal(); //quantidade de ordens no historico...

    Print(":-| Processando ordens do historico...");
    for(uint i=0;i<totalOrders;i++) {
       if( m_order.SelectByIndex(i) ){
           sqlCommand = "insert into ordem(cta,dtabert,ordem,idpos,ativo,tipo,volstr,preco,sl,tp,dtestado,estado,coment,externalid,typefilling,typetime,magic,pricecurrent,pricestoplimit,sl,tp,timedone,timeexpiration,volumecurrent)values("+
                        m_account.Login()                 + strVirgula + //conta
     to_strSqlTimestamp(m_order.TimeSetupMsc())           + strVirgula + //dtabert  '2020.01.28 12:39:09.832'
                        m_order.Ticket()                  + strVirgula + //ordem    96349103
                        m_order.PositionId()              + strVirgula + //
              to_strSql(m_order.Symbol         ())        + strVirgula + //ativo    'WING20'
              to_strSql(m_order.TypeDescription())        + strVirgula + //tipo     'sell limit'
                        m_order.VolumeInitial()           + strVirgula + //volstr   '1.00 / 0.00'
                        m_order.PriceOpen()               + strVirgula + //preco    '116075'
                        m_order.StopLoss()                + strVirgula + //sl       '116275'
                        m_order.TakeProfit()              + strVirgula + //tp       '115075'
     to_strSqlTimestamp(m_order.TimeDoneMsc())            + strVirgula + //dtestado '2020.01.28 12:39:09.943'
              to_strSql(m_order.StateDescription())       + strVirgula + //estado   'canceled'
              to_strSql(m_order.Comment())                + strVirgula +//coment   'INS v0 d-100 a0 t0 i0 b19 b36'
              //--------------------------------------------------------
              to_strSql(m_order.ExternalId())             + strVirgula +//
              to_strSql(m_order.TypeFillingDescription()) + strVirgula +//
              to_strSql(m_order.TypeTimeDescription())    + strVirgula +//
                        m_order.Magic()                   + strVirgula +//
                        m_order.PriceCurrent()            + strVirgula +//
                        m_order.PriceStopLimit()          + strVirgula +//
                        m_order.StopLoss()                + strVirgula +//
                        m_order.TakeProfit()              + strVirgula +//
     to_strSqlTimestamp(m_order.TimeDoneMsc()    )        + strVirgula +//
     to_strSqlTimestamp(m_order.TimeExpiration() )        + strVirgula +//
                        m_order.VolumeCurrent()           +             //
                                                          ");";
                                                          
         FileWrite(sqlFile,sqlCommand);
       }
    }
    Print(":-| ORDENS do historico processadas!");
}

void readDealsAndWriteSqlFile(int sqlFile, datetime from, datetime to){
    string sqlCommand;
    string strVirgula = "," ;

    Print(":-| Obtendo historico de ofertas...");
    HistorySelect(from,to);

    uint totalDeals=HistoryDealsTotal(); // quantidade de ofertas no historico...

    Print(":-| Processando ofertas do historico...");
    for(uint i=0;i<totalDeals;i++) {
       if( m_deal.SelectByIndex(i) ){
           sqlCommand = "insert into deal(cta,dt,deal,idpos,ativo,tipo,direcao,vol,preco,ordem,lucro,coment,deal_type,commission,externalid,magic,swap)values(" +
                        m_account.Login()                + strVirgula + //conta
     to_strSqlTimestamp(m_deal.TimeMsc())                + strVirgula + //dt      '2020.01.28 12:39:09.832'
                        m_deal.Ticket()                  + strVirgula + //deal     95106702
                        m_deal.PositionId()              + strVirgula + //
              to_strSql(m_deal.Symbol          ())       + strVirgula + //ativo    'WING20'
              to_strSql(m_deal.TypeDescription ())       + strVirgula + //tipo     'sell'
              to_strSql(m_deal.EntryDescription())       + strVirgula + //direcao  'in'
                        m_deal.Volume()                  + strVirgula + //vol      1.0
                        m_deal.Price()                   + strVirgula + //preco    116275
                        m_deal.Order()                   + strVirgula + //ordem    96413465
                        m_deal.Profit()                  + strVirgula + //lucro    6
              to_strSql(m_deal.Comment())                + strVirgula + //coment   'INS v0 d-100 a0 t0 i0 b19 b36'
              //-------------------------------------------------------
                        m_deal.DealType()                + strVirgula +
                        m_deal.Commission()              + strVirgula +
                        m_deal.ExternalId()              + strVirgula +
                        m_deal.Magic()                   + strVirgula +
                        m_deal.Swap()                    + 
                        ");";

         FileWrite(sqlFile,sqlCommand);
       }
    }
    Print(":-| OFERTAS do historico processadas!");
}

void writeSqlUpdateDeals(int sqlFile){
    string sqlCommand =
                        "update deal d                                         "+"\n"+
                        "   set tpmov    = fextract_tipo            (d.coment),"+"\n"+
                        "       vvol     = fextract_veloc_vol       (d.coment),"+"\n"+
                        "       vvoldelta= fextract_veloc_vol_delta (d.coment),"+"\n"+
                        "       aceldelta= fextract_aceleracao_delta(d.coment),"+"\n"+
                        "       volat    = fextract_volatilidade    (d.coment),"+"\n"+
                        "       inclina  = fextract_inclinacao      (d.coment),"+"\n"+
                        "       desbUp0  = fextract_desb_up0        (d.coment),"+"\n"+
                        "       desbUp1  = fextract_desb_up1        (d.coment) "+"\n"+
                        " where tpmov is null and coment not ilike 'deleted%';" +"\n";
    FileWrite(sqlFile,sqlCommand);
}

void writeSqlUpdateOrdens(int sqlFile){
    string sqlCommand =
                        "update ordem d                                        "+"\n"+
                        "   set tpmov    = fextract_tipo            (d.coment),"+"\n"+
                        "       vvol     = fextract_veloc_vol       (d.coment),"+"\n"+
                        "       vvoldelta= fextract_veloc_vol_delta (d.coment),"+"\n"+
                        "       aceldelta= fextract_aceleracao_delta(d.coment),"+"\n"+
                        "       volat    = fextract_volatilidade    (d.coment),"+"\n"+
                        "       inclina  = fextract_inclinacao      (d.coment),"+"\n"+
                        "       desbUp0  = fextract_desb_up0        (d.coment),"+"\n"+
                        "       desbUp1  = fextract_desb_up1        (d.coment) "+"\n"+
                        " where tpmov is null and coment not ilike 'deleted%';" +"\n";
    FileWrite(sqlFile,sqlCommand);
}

string to_strSqlTimestamp(ulong dt){
   return  m_strAspa + TimeToString(dt/1000,TIME_DATE|TIME_SECONDS) + "." + dt%1000 + m_strAspa;
}

string to_strSql(string str){
   return  m_strAspa + str + m_strAspa;
}

int openSqlFile(string arqSql){

    Print(":-| Criando arquivo sql ", arqSql, " no diretorio comum de arquivos...");
    //return FileOpen(arqLog, FILE_READ|FILE_TXT|FILE_COMMON);
    int file = FileOpen(arqSql, FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);

    if( file<0 ){
        Print(":-( Falha para abrir o arquivo sql: ", arqSql         );
        Print(":-( Codigo de erro: "                , GetLastError() );
    }
    return file;
}

void closeSqlFile(int sqlFile){
    Print(":-| Fechando arquivo sql", sqlFile, " ...");
    FileClose(sqlFile);
    Print(":-| Arquivo sql fechado!!!");
}