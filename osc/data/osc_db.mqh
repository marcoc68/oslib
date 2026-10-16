//+------------------------------------------------------------------+
//|                                                       osc_db.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
#include <oslib/osc/Log.mqh>

class osc_db{

private:
protected:
    ulong m_seq;   // gerador de sequencias
    int   m_db ;   // descritor do banco de dados

public:
    void close(){ DatabaseClose(m_db); }

    //|+--------------------------------------------------------------------+|
    //| Abre o banco de dados...                                             |
    //|+--------------------------------------------------------------------+|
    //bool create_or_open_mydb(string dbname="D:\\programs\\metatrader\\desen\\MQL5\\Files\\oslib.db"){
    bool create_or_open(string dbname){
    //--- create the file name 
     //string filename="mydb.sqlite"; 
       string filename=dbname;
       m_seq = TimeCurrent()*1000; // timecurrent em microsegundos
    
    //--- open/create the database in the common terminal folder... 
       Print(__FUNCTION__, " Abrindo o banco de dados ",filename, "...");
       m_db=DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON); 
       if(m_db==INVALID_HANDLE) { 
          Print(__FUNCTION__," DBERROR: ", filename, " open failed with code ", GetLastError()); 
          return false; 
       } 
       Print(__FUNCTION__, " Banco de dados ",filename, " aberto com sucesso!! manipulador eh:",m_db, "...");

       return true;
    }
};

