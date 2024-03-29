﻿//+------------------------------------------------------------------+
//|                                               teste-hash-map.mq5 |
//|                                         Copyright 2020, OS Corp. |
//|                                                http://www.os.org |
//+------------------------------------------------------------------+

//
//
// EXEMPLO DE USO DE COLECOES GENERICAS USANDO OBJETOS.
//
//
#property copyright "Copyright 2020, OS Corp."
#property link      "http://www.os.org"
#property version   "1.001"

#include <Object.mqh>
#include <Generic\HashMap.mqh>

class OsOrdem : public CObject{
public:
    ulong msec    ; // microsegundos desde o ultimo evento (somente pra teste)
    ulong idOrd   ; // ticket da ordem
    ulong idDea   ; // ticket da negociacao;
    ulong idPos   ; // ticket da posicao a qual pertence a ordem;
    
    int mag       ; // numero magico desta ordem;
    int magMeClose; // numero magico da ordem de fechamento dessa ordem;
    int magToClose; // numero magico da ordem que esta ordem estah fechando;
    
    string symbol ; // ticker
    int    direcao; // direcao da ordem (compra ou venda)
    double price  ; // preco
    double vol    ; // volume
    
    ENUM_TRADE_TRANSACTION_TYPE typTra; // ultimo tipo de transacao (evento) informado para a ordem
    ENUM_DEAL_TYPE              typDea; 
    ENUM_ORDER_TYPE             typOrd;
    ENUM_ORDER_STATE            status;

    

    virtual int Compare( const CObject*  node,   // Node to compare with 
                         const int       mode=0){// Compare mode 
       if( this.mag > ((OsOrdem*)node).mag ) return  1;
       if( this.mag < ((OsOrdem*)node).mag ) return -1;
                                             return  0;
    }
    
    string toString(){
        string str;
        StringConcatenate(str
                             ,"|ms " ,msec
                             ,"|ttr ",EnumToString(typTra)
                             ,"|ord ",idOrd
                             ,"|dea ",idDea
                             ,"|pos ",idPos
                             ,"|mag ",mag
                             ,"|mml ",magMeClose
                             ,"|mtc ",magToClose
                             ,"|sym ",symbol
                             ,"|dir ",direcao
                             ,"|prc ",price
                             ,"|vol ",vol
                             ,"|tor ",EnumToString(typOrd)
                             ,"|tde ",EnumToString(typDea)
                             ,"|stt ",EnumToString(status) 
                          );
        return str;
    }
};



void OnStart(){


    // Primeiro o exemplo com inteiros...
    CHashMap<int, int> ordens;    
    ordens.Add(10 ,4);
    ordens.Add(100,5);
    int valor;
    ordens.TryGetValue(10 ,valor); Print(valor);
    ordens.TryGetValue(100,valor); Print(valor);
    
    
    // agora o exemplo com objetos
    OsOrdem*        ord1 = new OsOrdem;
    OsOrdem*        ord2 = new OsOrdem;
    ord1.price = 31.111;    
    ord2.price = 32.222;    

    CHashMap<int, OsOrdem*> ordens2;
    ordens2.Add(10 ,ord1);
    ordens2.Add(100,ord2);
    
    OsOrdem* ord;
    ordens2.TryGetValue(10 ,ord); Print(ord.toString());
    ordens2.TryGetValue(100,ord); Print(ord.toString());
}
//+------------------------------------------------------------------+