//+------------------------------------------------------------------+
//|                                                         mydb.mqh |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

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


class osc_db{

private:

  int m_db;
  bool create_table_book();
  
public:
  bool create_or_open_mydb();
  bool insert_table_book( ost_book& book );
  void close(){ DatabaseClose(m_db); }

};

bool osc_db::create_or_open_mydb(){
//--- create the file name 
   string filename="mydb.sqlite"; 

//--- open/create the database in the common terminal folder 
   m_db=DatabaseOpen(filename, DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON); 
   if(m_db==INVALID_HANDLE) { 
      Print("DB: ", filename, " open failed with code ", GetLastError()); 
      return false; 
   } 
//--- create the BOOK table 
   if(!create_table_book()) { 
      DatabaseClose(m_db); 
      return false; 
   }
   
   return true; 
}

bool osc_db::create_table_book(){

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

bool osc_db::insert_table_book( ost_book& book ){

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


