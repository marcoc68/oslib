//+------------------------------------------------------------------+
//|                                                    create_db.mq5 |
//|                                         Copyright 2020, OS Corp. |
//|                                                http://www.os.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "1.001"

#property script_show_inputs

//+------------------------------------------------------------------+
//| cria e mantem o banco de dados mydb                              |
//+------------------------------------------------------------------+

#include  <oslib\osc\osc_db.mqh>
osc_db db;

void OnStart(){
   db.create_or_open_mydb();
   insert_acum_feature();
}
//+------------------------------------------------------------------+

void insert_acum_feature(){
   Print(__FUNCTION__," Inserindo na tabela acum_feature...");
   ost_acum_feature dado;
   dado.id   = TimeCurrent();
   dado.hor  = TimeCurrent();
   dado.y    = 123;
   dado.yhat = 123.34;
   db.insert_table_acum_featute( dado );
}