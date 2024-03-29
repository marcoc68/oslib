﻿//+------------------------------------------------------------------+
//|                                                       osc_db.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
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

// book com estrutura horizontal
struct ost_bookh{
   ulong    id       ;
   string   symbol   ;
   datetime tatu     ;
   //
   double   bp01     ;
   double   bv01     ;
   double   bv01a    ;
   double   bp02     ;
   double   bv02     ;
   double   bv02a    ;
   double   bp03     ;
   double   bv03     ;
   double   bv03a    ;
   double   bp04     ;
   double   bv04     ;
   double   bv04a    ;
   double   bp05     ;
   double   bv05     ;
   double   bv05a    ;
   double   bp06     ;
   double   bv06     ;
   double   bv06a    ;
   double   bp07     ;
   double   bv07     ;
   double   bv07a    ;
   double   bp08     ;
   double   bv08     ;
   double   bv08a    ;
   double   bp09     ;
   double   bv09     ;
   double   bv09a    ;
   double   bp10     ;
   double   bv10     ;
   double   bv10a    ;
   double   bp11     ;
   double   bv11     ;
   double   bv11a    ;
   double   bp12     ;
   double   bv12     ;
   double   bv12a    ;
   double   bp13     ;
   double   bv13     ;
   double   bv13a    ;
   double   bp14     ;
   double   bv14     ;
   double   bv14a    ;
   double   bp15     ;
   double   bv15     ;
   double   bv15a    ;
   double   bp16     ;
   double   bv16     ;
   double   bv16a    ;
   //
   double   ap01     ;
   double   av01     ;
   double   av01a    ;
   double   ap02     ;
   double   av02     ;
   double   av02a    ;
   double   ap03     ;
   double   av03     ;
   double   av03a    ;
   double   ap04     ;
   double   av04     ;
   double   av04a    ;
   double   ap05     ;
   double   av05     ;
   double   av05a    ;
   double   ap06     ;
   double   av06     ;
   double   av06a    ;
   double   ap07     ;
   double   av07     ;
   double   av07a    ;
   double   ap08     ;
   double   av08     ;
   double   av08a    ;
   double   ap09     ;
   double   av09     ;
   double   av09a    ;
   double   ap10     ;
   double   av10     ;
   double   av10a    ;
   double   ap11     ;
   double   av11     ;
   double   av11a    ;
   double   ap12     ;
   double   av12     ;
   double   av12a    ;
   double   ap13     ;
   double   av13     ;
   double   av13a    ;
   double   ap14     ;
   double   av14     ;
   double   av14a    ;
   double   ap15     ;
   double   av15     ;
   double   av15a    ;
   double   ap16     ;
   double   av16     ;
   double   av16a    ;
   //
   double   imb01,iwfv01,tlfv01;
   double   imb02,iwfv02,tlfv02;
   double   imb03,iwfv03,tlfv03;
   double   imb04,iwfv04,tlfv04;
   double   imb05,iwfv05,tlfv05;
   double   imb06,iwfv06,tlfv06;
   double   imb07,iwfv07,tlfv07;
   double   imb08,iwfv08,tlfv08;
   double   imb09,iwfv09,tlfv09;
   double   imb10,iwfv10,tlfv10;
   double   imb11,iwfv11,tlfv11;
   double   imb12,iwfv12,tlfv12;
   double   imb13,iwfv13,tlfv13;
   double   imb14,iwfv14,tlfv14;
   double   imb15,iwfv15,tlfv15;
   double   imb16,iwfv16,tlfv16;
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

    ulong m_seq;   // gerador de sequencias
    int   m_db ;   // descritor do banco de dados
    
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
  
    bool create_table_bookh(){ // book horizontal
    
    //--- check if the table exists 
       if(!DatabaseTableExists(m_db, "bookh")){
          //--- create the table 
          if(!DatabaseExecute(m_db, "create table bookh(" 
                              "id          int             primary key," 
                              "symbol      char(10)        ,"
                              "tatu        int             ,"
                              //
                              "bp01        real            ," 
                              "bv01        real            ," 
                              "bv01a       real            ," 
                              "bp02        real            ," 
                              "bv02        real            ,"
                              "bv02a       real            ,"
                              "bp03        real            ," 
                              "bv03        real            ," 
                              "bv03a       real            ,"
                              "bp04        real            ," 
                              "bv04        real            ," 
                              "bv04a       real            ,"
                              "bp05        real            ," 
                              "bv05        real            ," 
                              "bv05a       real            ,"
                              "bp06        real            ," 
                              "bv06        real            ," 
                              "bv06a       real            ,"
                              "bp07        real            ," 
                              "bv07        real            ," 
                              "bv07a       real            ,"
                              "bp08        real            ," 
                              "bv08        real            ," 
                              "bv08a       real            ,"
                              "bp09        real            ," 
                              "bv09        real            ," 
                              "bv09a       real            ,"
                              "bp10        real            ," 
                              "bv10        real            ," 
                              "bv10a       real            ,"
                              "bp11        real            ," 
                              "bv11        real            ," 
                              "bv11a       real            ,"
                              "bp12        real            ," 
                              "bv12        real            ," 
                              "bv12a       real            ,"
                              "bp13        real            ," 
                              "bv13        real            ," 
                              "bv13a       real            ,"
                              "bp14        real            ," 
                              "bv14        real            ," 
                              "bv14a       real            ,"
                              "bp15        real            ," 
                              "bv15        real            ," 
                              "bv15a       real            ,"
                              "bp16        real            ," 
                              "bv16        real            ," 
                              "bv16a       real            ,"
                              //
                              "ap01        real            ," 
                              "av01        real            ," 
                              "av01a       real            ," 
                              "ap02        real            ," 
                              "av02        real            ," 
                              "av02a       real            ,"
                              "ap03        real            ," 
                              "av03        real            ," 
                              "av03a       real            ,"
                              "ap04        real            ," 
                              "av04        real            ," 
                              "av04a       real            ,"
                              "ap05        real            ," 
                              "av05        real            ," 
                              "av05a       real            ,"
                              "ap06        real            ," 
                              "av06        real            ," 
                              "av06a       real            ,"
                              "ap07        real            ," 
                              "av07        real            ," 
                              "av07a       real            ,"
                              "ap08        real            ," 
                              "av08        real            ," 
                              "av08a       real            ,"
                              "ap09        real            ," 
                              "av09        real            ," 
                              "av09a       real            ,"
                              "ap10        real            ," 
                              "av10        real            ," 
                              "av10a       real            ,"
                              "ap11        real            ," 
                              "av11        real            ," 
                              "av11a       real            ,"
                              "ap12        real            ," 
                              "av12        real            ," 
                              "av12a       real            ,"
                              "ap13        real            ," 
                              "av13        real            ," 
                              "av13a       real            ,"
                              "ap14        real            ," 
                              "av14        real            ," 
                              "av14a       real            ,"
                              "ap15        real            ," 
                              "av15        real            ," 
                              "av15a       real            ,"
                              "ap16        real            ," 
                              "av16        real            ," 
                              "av16a       real            ,"
                              //
                              "imb01       real            ,"
                              "iwfv01      real            ,"
                              "tlfv01      real            ,"
                              "imb02       real            ,"
                              "iwfv02      real            ,"
                              "tlfv02      real            ,"
                              "imb03       real            ,"
                              "iwfv03      real            ,"
                              "tlfv03      real            ,"
                              "imb04       real            ,"
                              "iwfv04      real            ,"
                              "tlfv04      real            ,"
                              "imb05       real            ,"
                              "iwfv05      real            ,"
                              "tlfv05      real            ,"
                              "imb06       real            ,"
                              "iwfv06      real            ,"
                              "tlfv06      real            ,"
                              "imb07       real            ,"
                              "iwfv07      real            ,"
                              "tlfv07      real            ,"
                              "imb08       real            ,"
                              "iwfv08      real            ,"
                              "tlfv08      real            ,"
                              "imb09       real            ,"
                              "iwfv09      real            ,"
                              "tlfv09      real            ,"
                              "imb10       real            ,"
                              "iwfv10      real            ,"
                              "tlfv10      real            ,"
                              "imb11       real            ,"
                              "iwfv11      real            ,"
                              "tlfv11      real            ,"
                              "imb12       real            ,"
                              "iwfv12      real            ,"
                              "tlfv12      real            ,"
                              "imb13       real            ,"
                              "iwfv13      real            ,"
                              "tlfv13      real            ,"
                              "imb14       real            ,"
                              "iwfv14      real            ,"
                              "tlfv14      real            ,"
                              "imb15       real            ,"
                              "iwfv15      real            ,"
                              "tlfv15      real            ,"
                              "imb16       real            ,"
                              "iwfv16      real            ,"
                              "tlfv16      real             "
                              ");")){
             Print(__FUNCTION__, " DBERROR: create the BOOKH table failed with code ", GetLastError()); 
             return(false); 
          }
          return true;
       }
       return true; 
    }

    bool create_table_acum_feature(){
    
    //--- check if the table exists 1
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
             Print(__FUNCTION__, " DBERROR: create the ACUM_FEATURE table failed with code ", GetLastError()); 
             return(false); 
          }
          return true;
       }
       return true; 
    }
  
public:
    void close(){ DatabaseClose(m_db); }

    //|+--------------------------------------------------------------------+|
    //| Abre o banco de dados...                                             |
    //| Tabelas ainda nao criadas, sao criadas automaticamente na abertura.  |
    //|+--------------------------------------------------------------------+|
    //bool create_or_open_mydb(string dbname="D:\\programs\\metatrader\\desen\\MQL5\\Files\\oslib.db"){
    bool create_or_open_mydb(string dbname="oslib.db"){
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

    //--- create the BOOK table... 
       Print(__FUNCTION__, " Criando a tabela BOOK caso ainda nao exista...");
       if(!create_table_book()) { 
          Print(__FUNCTION__, " Erro criando a tabela BOOK:", GetLastError() );
          DatabaseClose(m_db); 
          return false; 
       }
       
    //--- create the BOOKH table... 
       Print(__FUNCTION__, " Criando a tabela BOOKH caso ainda nao exista...");
       if(!create_table_bookh()) { 
          Print(__FUNCTION__, " Erro criando a tabela BOOKH:", GetLastError() );
          DatabaseClose(m_db); 
          return false; 
       }
       
    //--- create the ACUM_FEATURE table...
       Print(__FUNCTION__, " Criando a tabela ACUM_FEATURE caso ainda nao exista...");
       if(!create_table_acum_feature()) { 
          Print(__FUNCTION__, " Erro criando a tabela ACUM_FEATURE:", GetLastError() );
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
          PrintFormat("%s: failed to insert BOOK #%d with code %d", __FUNCTION__, book.book_id, GetLastError()); 
          return false; 
       } 
       return true; 
    }

    bool insert_table_bookh( ost_bookh &bookh ){
    
      bookh.id = m_seq++; // chave primaria
      string request_text="INSERT INTO bookh VALUES(" +
                   IntegerToString(bookh.id) +","+
                   "'"+bookh.symbol+"',"+
                   "strftime('%Y-%m-%d %H:%M:%f', 'now'),"+
                   // bid
                   DoubleToString(bookh.bp01)+","+ DoubleToString(bookh.bv01)+","+ DoubleToString(bookh.bv01a)+","+
                   DoubleToString(bookh.bp02)+","+ DoubleToString(bookh.bv02)+","+ DoubleToString(bookh.bv02a)+","+
                   DoubleToString(bookh.bp03)+","+ DoubleToString(bookh.bv03)+","+ DoubleToString(bookh.bv03a)+","+
                   DoubleToString(bookh.bp04)+","+ DoubleToString(bookh.bv04)+","+ DoubleToString(bookh.bv04a)+","+
                   DoubleToString(bookh.bp05)+","+ DoubleToString(bookh.bv05)+","+ DoubleToString(bookh.bv05a)+","+
                   DoubleToString(bookh.bp06)+","+ DoubleToString(bookh.bv06)+","+ DoubleToString(bookh.bv06a)+","+
                   DoubleToString(bookh.bp07)+","+ DoubleToString(bookh.bv07)+","+ DoubleToString(bookh.bv07a)+","+
                   DoubleToString(bookh.bp08)+","+ DoubleToString(bookh.bv08)+","+ DoubleToString(bookh.bv08a)+","+
                   DoubleToString(bookh.bp09)+","+ DoubleToString(bookh.bv09)+","+ DoubleToString(bookh.bv09a)+","+
                   DoubleToString(bookh.bp10)+","+ DoubleToString(bookh.bv10)+","+ DoubleToString(bookh.bv10a)+","+
                   DoubleToString(bookh.bp11)+","+ DoubleToString(bookh.bv11)+","+ DoubleToString(bookh.bv11a)+","+
                   DoubleToString(bookh.bp12)+","+ DoubleToString(bookh.bv12)+","+ DoubleToString(bookh.bv12a)+","+
                   DoubleToString(bookh.bp13)+","+ DoubleToString(bookh.bv13)+","+ DoubleToString(bookh.bv13a)+","+
                   DoubleToString(bookh.bp14)+","+ DoubleToString(bookh.bv14)+","+ DoubleToString(bookh.bv14a)+","+
                   DoubleToString(bookh.bp15)+","+ DoubleToString(bookh.bv15)+","+ DoubleToString(bookh.bv15a)+","+
                   DoubleToString(bookh.bp16)+","+ DoubleToString(bookh.bv16)+","+ DoubleToString(bookh.bv16a)+","+
                   // ask
                   DoubleToString(bookh.ap01)+","+ DoubleToString(bookh.av01)+","+ DoubleToString(bookh.av01a)+","+
                   DoubleToString(bookh.ap02)+","+ DoubleToString(bookh.av02)+","+ DoubleToString(bookh.av02a)+","+
                   DoubleToString(bookh.ap03)+","+ DoubleToString(bookh.av03)+","+ DoubleToString(bookh.av03a)+","+
                   DoubleToString(bookh.ap04)+","+ DoubleToString(bookh.av04)+","+ DoubleToString(bookh.av04a)+","+
                   DoubleToString(bookh.ap05)+","+ DoubleToString(bookh.av05)+","+ DoubleToString(bookh.av05a)+","+
                   DoubleToString(bookh.ap06)+","+ DoubleToString(bookh.av06)+","+ DoubleToString(bookh.av06a)+","+
                   DoubleToString(bookh.ap07)+","+ DoubleToString(bookh.av07)+","+ DoubleToString(bookh.av07a)+","+
                   DoubleToString(bookh.ap08)+","+ DoubleToString(bookh.av08)+","+ DoubleToString(bookh.av08a)+","+
                   DoubleToString(bookh.ap09)+","+ DoubleToString(bookh.av09)+","+ DoubleToString(bookh.av09a)+","+
                   DoubleToString(bookh.ap10)+","+ DoubleToString(bookh.av10)+","+ DoubleToString(bookh.av10a)+","+
                   DoubleToString(bookh.ap11)+","+ DoubleToString(bookh.av11)+","+ DoubleToString(bookh.av11a)+","+
                   DoubleToString(bookh.ap12)+","+ DoubleToString(bookh.av12)+","+ DoubleToString(bookh.av12a)+","+
                   DoubleToString(bookh.ap13)+","+ DoubleToString(bookh.av13)+","+ DoubleToString(bookh.av13a)+","+
                   DoubleToString(bookh.ap14)+","+ DoubleToString(bookh.av14)+","+ DoubleToString(bookh.av14a)+","+
                   DoubleToString(bookh.ap15)+","+ DoubleToString(bookh.av15)+","+ DoubleToString(bookh.av15a)+","+
                   DoubleToString(bookh.ap16)+","+ DoubleToString(bookh.av16)+","+ DoubleToString(bookh.av16a)+","+
                   // indicadores
                   DoubleToString(bookh.imb01)+","+ DoubleToString(bookh.iwfv01)+","+ DoubleToString(bookh.tlfv01)+","+
                   DoubleToString(bookh.imb02)+","+ DoubleToString(bookh.iwfv02)+","+ DoubleToString(bookh.tlfv02)+","+
                   DoubleToString(bookh.imb03)+","+ DoubleToString(bookh.iwfv03)+","+ DoubleToString(bookh.tlfv03)+","+
                   DoubleToString(bookh.imb04)+","+ DoubleToString(bookh.iwfv04)+","+ DoubleToString(bookh.tlfv04)+","+
                   DoubleToString(bookh.imb05)+","+ DoubleToString(bookh.iwfv05)+","+ DoubleToString(bookh.tlfv05)+","+
                   DoubleToString(bookh.imb06)+","+ DoubleToString(bookh.iwfv06)+","+ DoubleToString(bookh.tlfv06)+","+
                   DoubleToString(bookh.imb07)+","+ DoubleToString(bookh.iwfv07)+","+ DoubleToString(bookh.tlfv07)+","+
                   DoubleToString(bookh.imb08)+","+ DoubleToString(bookh.iwfv08)+","+ DoubleToString(bookh.tlfv08)+","+
                   DoubleToString(bookh.imb09)+","+ DoubleToString(bookh.iwfv09)+","+ DoubleToString(bookh.tlfv09)+","+
                   DoubleToString(bookh.imb10)+","+ DoubleToString(bookh.iwfv10)+","+ DoubleToString(bookh.tlfv10)+","+
                   DoubleToString(bookh.imb11)+","+ DoubleToString(bookh.iwfv11)+","+ DoubleToString(bookh.tlfv11)+","+
                   DoubleToString(bookh.imb12)+","+ DoubleToString(bookh.iwfv12)+","+ DoubleToString(bookh.tlfv12)+","+
                   DoubleToString(bookh.imb13)+","+ DoubleToString(bookh.iwfv13)+","+ DoubleToString(bookh.tlfv13)+","+
                   DoubleToString(bookh.imb14)+","+ DoubleToString(bookh.iwfv14)+","+ DoubleToString(bookh.tlfv14)+","+
                   DoubleToString(bookh.imb15)+","+ DoubleToString(bookh.iwfv15)+","+ DoubleToString(bookh.tlfv15)+","+
                   DoubleToString(bookh.imb16)+","+ DoubleToString(bookh.iwfv16)+","+ DoubleToString(bookh.tlfv16)+");";
                   
        if(!DatabaseExecute(m_db, request_text)) { 
            PrintFormat("%s: failed to insert BOOKH with code %d", __FUNCTION__, GetLastError());
            Print(__FUNCTION__, " SQL_TEXT: ",request_text);
            return false; 
        } 
        return true; 
    }
    
    bool insert_table_acum_featute( ost_acum_feature &acum_feature ){
    
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
            PrintFormat("%s: failed to insert ACUM_FEATURE with code %d", __FUNCTION__, GetLastError()); 
            return false; 
        } 
        return true; 
    }
    
};

