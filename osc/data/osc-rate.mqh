//+------------------------------------------------------------------+
//|                                                     osc-rate.mqh |
//|                               Copyright 2020,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//+------------------------------------------------------------------+
#property copyright "2020, Oficina de Software."
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+---------------------------------------------------------------------+
//| Objeto rate usado para formar as diversas barras da biblioteca.     |
//+---------------------------------------------------------------------+
#property description "Objeto rate usado para formar as diversas barras da biblioteca."

#include <Object.mqh>

class osc_rate {//: public CObject{

private:
public:
    datetime time    ; // hora de abertura
    double   open    ; // preco medio na abertura
    double   high    ; // preco medio maximo
    double   low     ; // preco medio minimo
    double   close   ; // preco medio no fechamento
    double   vol     ; // volume total
    double   vol_sell; // volume de vendas
    double   vol_buy ; // volume de compras
    double   ret     ; // retorno

    void inicializar(){
        time     =0; // hora de abertura da barra
        open     =0; // preco medio na abertura
        high     =0; // preco medio maximo
        low      =0; // preco medio minimo
        close    =0; // preco medio no fechamento
        vol      =0; // volume total
        vol_sell =0; // volume de vendas
        vol_buy  =0; // volume de compras
        ret      =0; // retorno
    }
    
    //osc_rate();//:m_time(0);

//    virtual int Compare( const CObject*  outro,   // Node to compare with 
//                         const int       mode=0){// Compare mode 
//       if( this.m_close > ((osc_rate*)outro).m_close ) m_return  1;
//       if( this.m_close < ((osc_rate*)outro).m_close ) m_return -1;
//                                                   m_return  0;
//    }

    string toString(){
        string str;
        StringConcatenate(str
                             ,"|time "     ,time
                             ,"|open "     ,open
                             ,"|high "     ,high
                             ,"|low "      ,low
                             ,"|close "    ,close 
                             ,"|vol "      ,vol 
                             ,"|vol_sell " ,vol_sell 
                             ,"|vol_buy "  ,vol_buy 
                             ,"|ret "      ,ret 
                          );
        return str;
    }
    
};

