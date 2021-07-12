//+------------------------------------------------------------------+
//|                                                         mydb.mqh |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |

struct ost_book{
   string   symbol   ;
   ulong    book_id  ;
   datetime timecurr ;
   ulong    tmponbook;
   int      tatu     ;
   int      fila     ;
   int      tipo     ;
   int      preco    ;
   int      vol      ;
};

struct ost_acum_feature{
   ulong    id        ;
   string   config    ;
   ulong    grupo     ;
   datetime hora      ;
   double   rms_error ;
   double   y         ;
   double   yhat      ;
   int      resul     ;
   double   loss      ;
   double   loss_dut  ;
   long     time_train;
};


class osc_db{

private:

    int m_db;
    bool create_table_book(){
    
    //--- check if the table exists 
       if(!DatabaseTableExists(m_db, "BOOK")){
          //--- create the table 
          if(!DatabaseExecute(m_db, "CREATE TABLE BOOK(" 
                              "SYMBOL      CHAR(10)        ,"
                              "BOOK_ID     INT             ," 
                              "TIMECURR    INT             ,"
                              "TMPONBOOK   INT             ," 
                              "TATU        INT             ," 
                              "FILA        INT             ," 
                              "TIPO        INT             ," 
                              "PRICE       REAL            ," 
                              "VOL         REAL            );")) { 
             Print("DB: create the BOOK table  failed with code ", GetLastError()); 
             return(false); 
          }
          return true;
       }
       return true; 
    }
  
    bool create_table_acum_feature(){
    
    //--- check if the table exists 
       if(!DatabaseTableExists(m_db, "acum_feature")){
          //--- create the table 
          if(!DatabaseExecute(m_db, "CREATE TABLE acum_feature(" 
                              "id          INT     primary key ," 
                              "config      TEXT                ,"
                              "grupo       INT                 ,"
                              "hora        INT                 ," 
                              "rms_error   REAL                ," 
                              "y           REAL                ," 
                              "yhat        REAL                ," 
                              "resul       INT                 ," 
                              "loss        REAL                ," 
                              "loss_dut    REAL                ," 
                              "time_train  INT                 );")) { 
             Print(__FUNCTION__, " DBERROR: create the BOOK table  failed with code ", GetLastError()); 
             return(false); 
          }
          return true;
       }
       return true; 
    }
  
public:
    void close(){ DatabaseClose(m_db); }

    bool create_or_open_mydb(){
    //--- create the file name 
       string filename="mydb.sqlite"; 
    
    //--- open/create the database in the common terminal folder 
       Print(__FUNCTION__, " Abrindo o banco de dados ",filename, "...");
       m_db=DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON); 
       if(m_db==INVALID_HANDLE) { 
          Print(__FUNCTION__," DB: ", filename, " open failed with code ", GetLastError()); 
          return false; 
       } 
       Print(__FUNCTION__, " Banco de dados ",filename, " aberto sucesso!! manipulador eh:",m_db, "...");

    //--- create the BOOK table 
       Print(__FUNCTION__, " Criando a tabela book caso ainda nao exista...");
       if(!create_table_book()) { 
          Print(__FUNCTION__, " Erro criando a tabela book:", GetLastError() );
          DatabaseClose(m_db); 
          return false; 
       }
       
    //--- create the BOOK table 
       Print(__FUNCTION__, " Criando a tabela acum_feature caso ainda nao exista...");
       if(!create_table_acum_feature()) { 
          Print(__FUNCTION__, " Erro criando a tabela acum_feature:", GetLastError() );
          DatabaseClose(m_db); 
          return false; 
       }
       
       return true; 
    }

    bool insert_table_book( ost_book& book ){
    
       string request_text=StringFormat("INSERT INTO book (SYMBOL,BOOK_ID,TIMECURR,TMPONBOOK,TATU,FILA,TIPO,PRICE,VOL)"+
                                           "VALUES (%s, %d, %d, %d, %d, %d, '%d', %d, %d)", 
                                           book.symbol,
                                           book.book_id,
                                           book.timecurr,
                                           book.tmponbook, 
                                           book.tatu, 
                                           book.fila, 
                                           book.tipo, 
                                           book.preco,
                                           book.vol  ); 
       if(!DatabaseExecute(m_db, request_text)) { 
          PrintFormat("%s: failed to insert book #%d with code %d", __FUNCTION__, book.book_id, GetLastError()); 
          return false; 
       } 
       return true; 
    }
    
    bool insert_table_acum_featute( ost_acum_feature &acum_feature ){
    
       datetime dt = acum_feature.hora;
       string request_text=StringFormat("INSERT INTO acum_feature (config,grupo,hora,rms_error,y,yhat,resul,loss,loss_dut,time_train)"+
                                           "VALUES ('%s', %d, '%s', %e, %e, %e, %d, %e, %e, %d);", 
                                           acum_feature.config    ,
                                           acum_feature.grupo     ,
                              TimeToString(acum_feature.hora      , TIME_DATE|TIME_MINUTES|TIME_SECONDS),
                                           acum_feature.rms_error ,
                                           acum_feature.y         ,
                                           acum_feature.yhat      , 
                                           acum_feature.resul     , 
                                           acum_feature.loss      ,
                                           acum_feature.loss_dut  ,
                                           acum_feature.time_train);
       if(!DatabaseExecute(m_db, request_text)) { 
          PrintFormat("%s: failed to insert acum_feature with code %d", __FUNCTION__, GetLastError()); 
          return false; 
       } 
       return true; 
    }
    

};

