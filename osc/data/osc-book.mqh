//+------------------------------------------------------------------+
//|                                                     osc-book.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"

  #include <oslib\osc\data\osc_db.mqh>
//+-----------------------------------------------------------------------------------------------+
//| Processa OnBookEvent                                                                          |
//|                                                                                               |
//| - 28/03/2021                                                                                  |
//| - Versao Inicial                                                                              |
//| - Calcula Deep Inbalance em ateh 4 niveis de precos.                                          |
//|                                                                                               |
//+-----------------------------------------------------------------------------------------------+

// posicao do preco e volume nos arrays do book...
#define      ASK 0 // cotacao ask
#define     VASK 1 // volume  ask
#define VACUMASK 2 // volume  acumulado ask
#define      BID 3 // cotacao bid
#define     VBID 4 // volume  bid
#define VACUMBID 5 // volume  acumulado bid
#define      IMB 6 // probabilidade imbalance
#define     IWFV 7 //  Inverse size weighted fair value (IWFV) price
#define     TLFV 8 //  Threshold liquidity   fair value (TLFV) price
#define COLS_VET_BOOK 9
#define BOOK_DEEP_STD 4
#define BOOK_DEEP_MAX 32
class osc_book{
private:
    double m_pesos    [BOOK_DEEP_MAX];// usado para ponderar o volume de ordens pendentes no nivel, pela sua respectiva probabilidade de execucao. 
    double m_vetBook[][COLS_VET_BOOK];// 0=prob imbalance, 1=cotacao ask, 2=cotacao bid 
    int    m_deep                    ;// profundidade do book;
    int    m_ind                     ;// posicao do primeiro bid no book;
    double m_vol_ask, m_vol_bid      ;// auxiliares para calculo do deep imbalance;
    double m_limiar_imbalance        ;// porcentagem, a partir da qual, considero o book desbalanceado.
    
  //int m_tamanho_book;
    MqlBookInfo m_book[];
    
    string m_symb_str;
    
    // registro do book em banco de dados
    bool      m_registrar_db; // se registra refresh do book em banco de dados
    ost_bookh m_tbook       ; // tabela do banco de dados onde sao registradas as ocorrencias do book
    osc_db    m_db          ; // banco de dados
    
    // passa os dados do book pra dentro deste objeto.
    int setBookInterno(){
        
        m_ind    =0;
        m_vol_ask=0;
        m_vol_bid=0;
        
        double m_preco_x_volume_acumulado_ask = 0;
        double m_preco_x_volume_acumulado_bid = 0;
        
        // descobrindo a posicao do primeiro bid...
        // ao final deste laco m_ind contem a posicao do best-bid;
        while( m_book[m_ind].type == BOOK_TYPE_SELL ){ m_ind++; }
        if(m_deep > m_ind){
            Print(__FUNCTION__, " ATENCAO: deep book corrigido de ", m_deep, " para ", m_ind, ". Tamanho do book: ", ArraySize(m_book)  );
             m_deep = m_ind; // corrigindo m_deep nos casos em que ele muito grande...
        }
        
        for(int i=0; i<m_deep && (m_ind)-i-1 >= 0; i++){
            // armazenando cotacoes e volumes...
            m_vetBook[i][ ASK] = m_book[(m_ind)-i-1].price                 ;
            m_vetBook[i][VASK] = m_book[(m_ind)-i-1].volume_real*m_pesos[i];
            m_vetBook[i][ BID] = m_book[(m_ind)+i  ].price                 ;
            m_vetBook[i][VBID] = m_book[(m_ind)+i  ].volume_real*m_pesos[i];
    
            // volume acumulado
            m_vol_ask += m_vetBook[i][VASK];
            m_vol_bid += m_vetBook[i][VBID];
            m_vetBook[i][VACUMASK] = m_vol_ask;
            m_vetBook[i][VACUMBID] = m_vol_bid;

            // somatorio de preco vezes o volume acumulado ateh o nivel
            m_preco_x_volume_acumulado_ask += m_vetBook[i][ASK] * m_vetBook[i][VASK];
            m_preco_x_volume_acumulado_bid += m_vetBook[i][BID] * m_vetBook[i][VBID];
            
            // calculando e armazenando o deep imbalance por nivel
            m_vetBook[i][IMB] = (m_vol_bid - m_vol_ask)/
                                (m_vol_bid + m_vol_ask);
                                
            // iwfv - preco justo ponderado pelo volume
            m_vetBook[i][IWFV] = ( m_vetBook[i][BID]*m_vol_ask + m_vetBook[i][ASK]*m_vol_bid )/
                                 (m_vol_bid + m_vol_ask);
            
            // tlfv - Threshold liquidity fair value (TLFV) price
            m_vetBook[i][TLFV] = ( m_preco_x_volume_acumulado_ask + m_preco_x_volume_acumulado_bid )/
                                 (m_vol_bid + m_vol_ask);
                                 
        }
        
        if( m_registrar_db ) salvar_book();
        
        return m_ind;
    }
    
    void salvar_book(){
        //m_tbook.tatu  = time_msc; //TimeCurrent();
        if(m_deep>00){m_tbook.bp01=getBid(01); m_tbook.bv01=getBidV(01); m_tbook.bv01a=getBidVa(01); m_tbook.ap01=getAsk(01); m_tbook.av01=getAskV(01); m_tbook.av01a=getAskVa(01); m_tbook.imb01=getImbalance(01); m_tbook.iwfv01=getIWFV(01); m_tbook.tlfv01=getTLFV(01);}
        if(m_deep>01){m_tbook.bp02=getBid(02); m_tbook.bv02=getBidV(02); m_tbook.bv02a=getBidVa(02); m_tbook.ap02=getAsk(02); m_tbook.av02=getAskV(02); m_tbook.av02a=getAskVa(02); m_tbook.imb02=getImbalance(02); m_tbook.iwfv02=getIWFV(02); m_tbook.tlfv02=getTLFV(02);}
        if(m_deep>02){m_tbook.bp03=getBid(03); m_tbook.bv03=getBidV(03); m_tbook.bv03a=getBidVa(03); m_tbook.ap03=getAsk(03); m_tbook.av03=getAskV(03); m_tbook.av03a=getAskVa(03); m_tbook.imb03=getImbalance(03); m_tbook.iwfv03=getIWFV(03); m_tbook.tlfv03=getTLFV(03);}
        if(m_deep>03){m_tbook.bp04=getBid(04); m_tbook.bv04=getBidV(04); m_tbook.bv04a=getBidVa(04); m_tbook.ap04=getAsk(04); m_tbook.av04=getAskV(04); m_tbook.av04a=getAskVa(04); m_tbook.imb04=getImbalance(04); m_tbook.iwfv04=getIWFV(04); m_tbook.tlfv04=getTLFV(04);}
        if(m_deep>04){m_tbook.bp05=getBid(05); m_tbook.bv05=getBidV(05); m_tbook.bv05a=getBidVa(05); m_tbook.ap05=getAsk(05); m_tbook.av05=getAskV(05); m_tbook.av05a=getAskVa(05); m_tbook.imb05=getImbalance(05); m_tbook.iwfv05=getIWFV(05); m_tbook.tlfv05=getTLFV(05);}
        if(m_deep>05){m_tbook.bp06=getBid(06); m_tbook.bv06=getBidV(06); m_tbook.bv06a=getBidVa(06); m_tbook.ap06=getAsk(06); m_tbook.av06=getAskV(06); m_tbook.av06a=getAskVa(06); m_tbook.imb06=getImbalance(06); m_tbook.iwfv06=getIWFV(06); m_tbook.tlfv06=getTLFV(06);}
        if(m_deep>06){m_tbook.bp07=getBid(07); m_tbook.bv07=getBidV(07); m_tbook.bv07a=getBidVa(07); m_tbook.ap07=getAsk(07); m_tbook.av07=getAskV(07); m_tbook.av07a=getAskVa(07); m_tbook.imb07=getImbalance(07); m_tbook.iwfv07=getIWFV(07); m_tbook.tlfv07=getTLFV(07);}
        if(m_deep>07){m_tbook.bp08=getBid(08); m_tbook.bv08=getBidV(08); m_tbook.bv08a=getBidVa(08); m_tbook.ap08=getAsk(08); m_tbook.av08=getAskV(08); m_tbook.av08a=getAskVa(08); m_tbook.imb08=getImbalance(08); m_tbook.iwfv08=getIWFV(08); m_tbook.tlfv08=getTLFV(08);}
        if(m_deep>08){m_tbook.bp09=getBid(09); m_tbook.bv09=getBidV(09); m_tbook.bv09a=getBidVa(09); m_tbook.ap09=getAsk(09); m_tbook.av09=getAskV(09); m_tbook.av09a=getAskVa(09); m_tbook.imb09=getImbalance(09); m_tbook.iwfv09=getIWFV(09); m_tbook.tlfv09=getTLFV(09);}
        if(m_deep>09){m_tbook.bp10=getBid(10); m_tbook.bv10=getBidV(10); m_tbook.bv10a=getBidVa(10); m_tbook.ap10=getAsk(10); m_tbook.av10=getAskV(10); m_tbook.av10a=getAskVa(10); m_tbook.imb10=getImbalance(10); m_tbook.iwfv10=getIWFV(10); m_tbook.tlfv10=getTLFV(10);}
        if(m_deep>10){m_tbook.bp11=getBid(11); m_tbook.bv11=getBidV(11); m_tbook.bv11a=getBidVa(11); m_tbook.ap11=getAsk(11); m_tbook.av11=getAskV(11); m_tbook.av11a=getAskVa(11); m_tbook.imb11=getImbalance(11); m_tbook.iwfv11=getIWFV(11); m_tbook.tlfv11=getTLFV(11);}
        if(m_deep>11){m_tbook.bp12=getBid(12); m_tbook.bv12=getBidV(12); m_tbook.bv12a=getBidVa(12); m_tbook.ap12=getAsk(12); m_tbook.av12=getAskV(12); m_tbook.av12a=getAskVa(12); m_tbook.imb12=getImbalance(12); m_tbook.iwfv12=getIWFV(12); m_tbook.tlfv12=getTLFV(12);}
        if(m_deep>12){m_tbook.bp13=getBid(13); m_tbook.bv13=getBidV(13); m_tbook.bv13a=getBidVa(13); m_tbook.ap13=getAsk(13); m_tbook.av13=getAskV(13); m_tbook.av13a=getAskVa(13); m_tbook.imb13=getImbalance(13); m_tbook.iwfv13=getIWFV(13); m_tbook.tlfv13=getTLFV(13);}
        if(m_deep>13){m_tbook.bp14=getBid(14); m_tbook.bv14=getBidV(14); m_tbook.bv14a=getBidVa(14); m_tbook.ap14=getAsk(14); m_tbook.av14=getAskV(14); m_tbook.av14a=getAskVa(14); m_tbook.imb14=getImbalance(14); m_tbook.iwfv14=getIWFV(14); m_tbook.tlfv14=getTLFV(14);}
        if(m_deep>14){m_tbook.bp15=getBid(15); m_tbook.bv15=getBidV(15); m_tbook.bv15a=getBidVa(15); m_tbook.ap15=getAsk(15); m_tbook.av15=getAskV(15); m_tbook.av15a=getAskVa(15); m_tbook.imb15=getImbalance(15); m_tbook.iwfv15=getIWFV(15); m_tbook.tlfv15=getTLFV(15);}
        if(m_deep>15){m_tbook.bp16=getBid(16); m_tbook.bv16=getBidV(16); m_tbook.bv16a=getBidVa(16); m_tbook.ap16=getAsk(16); m_tbook.av16=getAskV(16); m_tbook.av16a=getAskVa(16); m_tbook.imb16=getImbalance(16); m_tbook.iwfv16=getIWFV(16); m_tbook.tlfv16=getTLFV(16);}

        m_db.insert_table_bookh(m_tbook);
    }

public:

    void set_db          ( osc_db &db          ){ m_db           = db          ;}
    void set_registrar_db( bool    registrar_db){ m_registrar_db = registrar_db;}
    
    // symb_str        : ticker
    // deep            : profundidade do mercado a ser tratada
    // limiar_imbalance: porcentagem acima/abaixo da qual o book eh considerado desbalanceado.
    bool initialize(string symb_str, int deep=BOOK_DEEP_STD, double limiar_imbalance=0.1){ 
        m_symb_str         = symb_str;
        m_tbook.symbol     = symb_str;
        m_deep             = deep; if(m_deep>BOOK_DEEP_MAX) m_deep = BOOK_DEEP_MAX;
        m_limiar_imbalance = limiar_imbalance;
        
        ArrayResize(m_vetBook,  m_deep     );
        ArrayFill  (m_vetBook,0,m_deep*COLS_VET_BOOK, 0);
        
        if(m_deep>00) m_pesos[00] = 0.98;
        if(m_deep>01) m_pesos[01] = 0.89;
        if(m_deep>02) m_pesos[02] = 0.82;
        if(m_deep>03) m_pesos[03] = 0.78;
        if(m_deep>04) m_pesos[04] = 0.73;
        if(m_deep>05) m_pesos[05] = 0.71;
        if(m_deep>06) m_pesos[06] = 0.70;
        if(m_deep>07) m_pesos[07] = 0.65;
        if(m_deep>08) m_pesos[08] = 0.60;
        if(m_deep>09) m_pesos[09] = 0.55;
        if(m_deep>10) m_pesos[10] = 0.50;
        if(m_deep>11) m_pesos[11] = 0.45;
        if(m_deep>12) m_pesos[12] = 0.40;
        if(m_deep>13) m_pesos[13] = 0.35;
        if(m_deep>14) m_pesos[14] = 0.30;
        if(m_deep>15) m_pesos[15] = 0.25;

        if(m_deep>16) m_pesos[16] = 0.24;
        if(m_deep>17) m_pesos[17] = 0.24;
        if(m_deep>18) m_pesos[18] = 0.23;
        if(m_deep>19) m_pesos[19] = 0.23;
        if(m_deep>20) m_pesos[20] = 0.22;
        if(m_deep>21) m_pesos[21] = 0.22;
        if(m_deep>22) m_pesos[22] = 0.21;
        if(m_deep>23) m_pesos[23] = 0.21;
        if(m_deep>24) m_pesos[24] = 0.20;
        if(m_deep>25) m_pesos[25] = 0.20;
        if(m_deep>26) m_pesos[26] = 0.19;
        if(m_deep>27) m_pesos[27] = 0.19;
        if(m_deep>28) m_pesos[28] = 0.18;
        if(m_deep>29) m_pesos[29] = 0.18;
        if(m_deep>30) m_pesos[30] = 0.17;
        if(m_deep>31) m_pesos[31] = 0.17;

        if(m_deep>32) m_pesos[32] = 0.16;
        if(m_deep>33) m_pesos[33] = 0.16;
        if(m_deep>34) m_pesos[34] = 0.15;
        if(m_deep>35) m_pesos[35] = 0.15;
        if(m_deep>36) m_pesos[36] = 0.14;
        if(m_deep>37) m_pesos[37] = 0.14;
        if(m_deep>38) m_pesos[38] = 0.13;
        if(m_deep>39) m_pesos[39] = 0.13;
        
        return true;
    }

    //retorna: +1 se o imbalance for maior que o +limiar;
    //         -1 se o imbalance for menor que o -limiar;
    //          0 se estiver entre o -limiar e +limiar; [sem direcao definida]
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
    
    double getImbalance(int deep){ return m_vetBook[(deep>m_deep?m_deep:deep)-1][ IMB    ]; } // imbalance
    double getAsk      (int deep){ return m_vetBook[(deep>m_deep?m_deep:deep)-1][ ASK    ]; } // preco
    double getBid      (int deep){ return m_vetBook[(deep>m_deep?m_deep:deep)-1][ BID    ]; } // preco
    double getAskV     (int deep){ return m_vetBook[(deep>m_deep?m_deep:deep)-1][VASK    ]; } // volume
    double getBidV     (int deep){ return m_vetBook[(deep>m_deep?m_deep:deep)-1][VBID    ]; } // volume
    double getAskVa    (int deep){ return m_vetBook[(deep>m_deep?m_deep:deep)-1][VACUMASK]; } // volume acumulado
    double getBidVa    (int deep){ return m_vetBook[(deep>m_deep?m_deep:deep)-1][VACUMBID]; } // volume acumulado
    double getIWFV     (int deep){ return m_vetBook[(deep>m_deep?m_deep:deep)-1][IWFV    ]; } // inverse size weighted fair value price
    double getTLFV     (int deep){ return m_vetBook[(deep>m_deep?m_deep:deep)-1][TLFV    ]; } // Liquidity Threshould fair value price

    double getImbalance(){ return getImbalance(m_deep); }
    double getAsk      (){ return getAsk      (m_deep); }
    double getBid      (){ return getBid      (m_deep); }
    int    getDeep     (){ return m_deep;               } // profundidade que estah sendo operada no book agora...

    int setBook(){
        if( !MarketBookGet(m_symb_str, m_book) ) return -1;
        return setBookInterno();
    }

    int setBook(const MqlBookInfo &book[]){
        ArrayCopy(m_book,book);
        return setBookInterno();
    }
    
}; // fim do corpo da classe
//---------------------------------------------------------------------------------------------------

