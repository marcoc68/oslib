//+------------------------------------------------------------------+
//|                                         osc-vol-profile-item.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+---------------------------------------------------------------------+
//| Itens usados no processamento do volume profile.                    |
//| Um Item representa uma linha do volume profile.                     |
//+---------------------------------------------------------------------+
#include <Object.mqh>

class volume_profile_item : public CObject{

public:
    double price; // preco
    double vol  ; // volume
    long   time ; // data da ultima adicao de volume

    virtual int Compare( const CObject*  node,   // Node to compare with 
                         const int       mode=0){// Compare mode 
       if( this.time > ((volume_profile_item*)node).time ) return  1;
       if( this.time < ((volume_profile_item*)node).time ) return -1;
                                            return  0;
    }
    
    string toString(){
        string str;
        StringConcatenate(str
                             ,"|p " , price
                             ,"|v " , vol
                             ,"|t " , TimeToString( time, TIME_SECONDS )
                          );
        return str;
    }
};
