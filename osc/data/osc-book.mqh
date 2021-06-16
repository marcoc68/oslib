//+------------------------------------------------------------------+
//|                                                     osc-book.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"

//#include <oslib\osc\data\osc-vetor-circular3.mqh>
//#include <oslib\osc\est\CStat.mqh>
//#include <oslib\osc\est\C0003ModelRegLin.mqh>
//+-----------------------------------------------------------------------------------------------+
//| Processa OnBookEvent                                                                          |
//|                                                                                               |
//| - 28/03/2021                                                                                  |
//| - Versao Inicial                                                                              |
//| - Calcula Deep Inbalance em ateh 4 niveis de precos.                                          |
//|                                                                                               |
//+-----------------------------------------------------------------------------------------------+

// posicao do preco e volume nos arrays do book...
#define  ASK 0 // cotacao ask
#define VASK 1 // volume  ask
#define  BID 2 // cotacao bid
#define VBID 3 // volume  bid
#define  IMB 4 // probabilidade imbalance
#define COLS_VET_BOOK 5
#define BOOK_DEEP_STD 4
class osc_book{
private:
   
    //double m_bs0 ;
    //double m_bs1 ;
    //double m_bs2 ;
    //double m_bs3 ;
    //double m_as0 ;
    //double m_as1 ;
    //double m_as2 ;
    //double m_as3 ;
    //double m_p0  ;// probabilidade dos best bid-ask (fila 0). Vai de -1 a +1. Negativo eh provavel que o preco desca e vice-versa.
    //double m_p1  ;// probabilidade na                fila 1 . Vai de -1 a +1. Negativo eh provavel que o preco desca e vice-versa.
    //double m_p2  ;// probabilidade na                fila 2 . Vai de -1 a +1. Negativo eh provavel que o preco desca e vice-versa.
    //double m_p3  ;// probabilidade na                fila 3 . Vai de -1 a +1. Negativo eh provavel que o preco desca e vice-versa.

    double m_vetBook[][COLS_VET_BOOK];// 0=prob imbalance, 1=cotacao ask, 2=cotacao bid 
    int    m_deep                    ;// profundidade do book;
    int    m_ind                     ;// posicao do primeiro bid no book;
    double m_vol_ask, m_vol_bid      ;// auxiliares para calculo do deep imbalance;
    double m_limiar_imbalance        ;// porcentagem, a partir da qual, considero o book desbalanceado.
    
  //int m_tamanho_book;
    MqlBookInfo m_book[];
    
    string m_symb_str;
    
public:
    int setBook();
    
    // symb_str: ticker
    // deep    : profundidade do mercado a ser tratada
    bool initialize(string symb_str, int deep=BOOK_DEEP_STD, double limiar_imbalance=0.1){ 
        m_symb_str         = symb_str;
        m_deep             = deep;
        m_limiar_imbalance = limiar_imbalance;
        
        ArrayResize(m_vetBook,  deep     );
        ArrayFill  (m_vetBook,0,deep*COLS_VET_BOOK, 0);
        
        return true;
    }

    //retorna:  +1 se o imbalance for maior que o +limiar;
    //          -1 se o imbalance for menor que o -limiar;
    //           0 se estiver entre o -limiar e +limiar; [sem direcao definida]
    int getDirecaoImbalance(int deep){ 
        if( getImbalance(deep) > +m_limiar_imbalance ) return +1;
        if( getImbalance(deep) < -m_limiar_imbalance ) return -1;
                                                       return  0;
    }
    int getDirecaoImbalance(){ return getDirecaoImbalance(m_deep); } 
    
    string getDirecaoImbalanceStr(){ 
        if( getDirecaoImbalance() > 0 ) return "BUY"    ;
        if( getDirecaoImbalance() < 0 ) return "SELL"   ;
                                        return "NEUTRAL";
    }
    
    double getImbalance(int deep){ return m_vetBook[deep-1][IMB]; }
    double getAsk      (int deep){ return m_vetBook[deep-1][ASK]; }
    double getBid      (int deep){ return m_vetBook[deep-1][BID]; }

    double getImbalance(){ return getImbalance(m_deep); }
    double getAsk      (){ return getAsk      (m_deep); }
    double getBid      (){ return getBid      (m_deep); }
  
}; // fim do corpo da classe

int osc_book::setBook(){
    
    if( !MarketBookGet(m_symb_str,m_book) ) return -1;
    
    m_ind    =0;
    m_vol_ask=0;
    m_vol_bid=0;
    
    // descobrindo a posicao do primeiro bid...
    // ao final deste laco m_ind contem a posicao do best-bid;
    while( m_book[m_ind].type == BOOK_TYPE_SELL ){ m_ind++; }
    
        
    for(int i=0; i<m_deep && (m_ind)-i-1 >= 0; i++){
        // armazenando cotacoes e volumes...
        m_vetBook[i][ ASK] = m_book[(m_ind)-i-1].price      ;
        m_vetBook[i][VASK] = m_book[(m_ind)-i-1].volume_real;
        m_vetBook[i][ BID] = m_book[(m_ind)+i  ].price      ;
        m_vetBook[i][VBID] = m_book[(m_ind)+i  ].volume_real;

        // calculando e armazenando o deep imbalance
        m_vol_ask += m_vetBook[i][VASK];
        m_vol_bid += m_vetBook[i][VBID];
        m_vetBook[i][IMB] = (m_vol_bid - m_vol_ask)/
                            (m_vol_bid + m_vol_ask);
    }
    return m_ind;
    
    //if( m_ind > 3){
    //     m_as3 = m_book[(m_ind)-4].volume_real;// volume quarta   fila ask
    //     m_as2 = m_book[(m_ind)-3].volume_real;// volume terceira fila ask
    //     m_as1 = m_book[(m_ind)-2].volume_real;// volume segunda  fila ask
    //     m_as0 = m_book[(m_ind)-1].volume_real;// volume primeira fila ask
    //     m_bs0 = m_book[(m_ind)  ].volume_real;// volume primeira fila bid
    //     m_bs1 = m_book[(m_ind)+1].volume_real;// volume segunda  fila bid
    //     m_bs2 = m_book[(m_ind)+2].volume_real;// volume terceira fila bid
    //     m_bs3 = m_book[(m_ind)+3].volume_real;// volume quarta   fila bid
    //     m_p0 =  m_bs0                   /(m_bs0+                  m_as0                  );
    //     m_p1 = (m_bs0+m_bs1            )/(m_bs0+m_bs1+            m_as0+m_as1            );
    //     m_p2 = (m_bs0+m_bs1+m_bs2      )/(m_bs0+m_bs1+m_bs2+      m_as0+m_as1+m_as2      );
    //     m_p3 = (m_bs0+m_bs1+m_bs2+m_bs3)/(m_bs0+m_bs1+m_bs2+m_bs3+m_as0+m_as1+m_as2+m_as3);
    //     return true;
    //}
    //return false;    
}
//---------------------------------------------------------------------------------------------------

