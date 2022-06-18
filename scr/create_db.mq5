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

#include  <oslib\osc\data\osc_db.mqh>
osc_db db;

void OnStart(){
   verificar_pastas();
   db.create_or_open_mydb();
   insert_acum_feature();
   db.close();
}
//+------------------------------------------------------------------+


void insert_acum_feature(){
   Print(__FUNCTION__," Inserindo na tabela acum_feature...");
   ost_acum_feature dado;
   dado.id   = TimeCurrent();
   dado.hora = TimeCurrent();
   dado.y    = 123;
   dado.yhat = 123.34;
   db.insert_table_acum_featute( dado );
}

//O terminal soh permite criar arquivos nas pastas listadas por esta funcao
void verificar_pastas(){
//--- Pasta que armazena os dados do terminal 
   string terminal_data_path=TerminalInfoString(TERMINAL_DATA_PATH); 

//--- Pasta comum para todos os terminais de clientes 
   string common_data_path=TerminalInfoString(TERMINAL_COMMONDATA_PATH);
   
   Print(__FUNCTION__,"terminal_data_path:", terminal_data_path);
   Print(__FUNCTION__,"common_data_path  :",   common_data_path);
}
