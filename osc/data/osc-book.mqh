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
#define BOOK_DEEP_MAX 16
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
        m_tbook.bp01  = getBid  (1); m_tbook.bv01  = getBidV (1); m_tbook.bv01a = getBidVa(1);
        m_tbook.ap01  = getAsk  (1); m_tbook.av01  = getAskV (1); m_tbook.av01a = getAskVa(1);
        
        m_tbook.bp02  = getBid  (2); m_tbook.bv02  = getBidV (2); m_tbook.bv02a = getBidVa(2);
        m_tbook.ap02  = getAsk  (2); m_tbook.av02  = getAskV (2); m_tbook.av02a = getAskVa(2);
        
        m_tbook.bp03  = getBid  (3); m_tbook.bv03  = getBidV (3); m_tbook.bv03a = getBidVa(3);
        m_tbook.ap03  = getAsk  (3); m_tbook.av03  = getAskV (3); m_tbook.av03a = getAskVa(3);
        
        m_tbook.bp04  = getBid  (4); m_tbook.bv04  = getBidV (4); m_tbook.bv04a = getBidVa(4);
        m_tbook.ap04  = getAsk  (4); m_tbook.av04  = getAskV (4); m_tbook.av04a = getAskVa(4);
        
        m_tbook.bp05  = getBid  (5); m_tbook.bv05  = getBidV (5); m_tbook.bv05a = getBidVa(5);
        m_tbook.ap05  = getAsk  (5); m_tbook.av05  = getAskV (5); m_tbook.av05a = getAskVa(5);
        
        m_tbook.bp06  = getBid  (6); m_tbook.bv06  = getBidV (6); m_tbook.bv06a = getBidVa(6);
        m_tbook.ap06  = getAsk  (6); m_tbook.av06  = getAskV (6); m_tbook.av06a = getAskVa(6);
        
        m_tbook.bp07  = getBid  (7); m_tbook.bv07  = getBidV (7); m_tbook.bv07a = getBidVa(7);
        m_tbook.ap07  = getAsk  (7); m_tbook.av07  = getAskV (7); m_tbook.av07a = getAskVa(7);
        
        m_tbook.bp08  = getBid  (8); m_tbook.bv08  = getBidV (8); m_tbook.bv08a = getBidVa(8);
        m_tbook.ap08  = getAsk  (8); m_tbook.av08  = getAskV (8); m_tbook.av08a = getAskVa(8);
        
        m_tbook.bp09  = getBid  (9); m_tbook.bv09  = getBidV (9); m_tbook.bv09a = getBidVa(9);
        m_tbook.ap09  = getAsk  (9); m_tbook.av09  = getAskV (9); m_tbook.av09a = getAskVa(9);
 /*       
        m_tbook.bp10  = getBid  (10); m_tbook.bv10  = getBidV (10); m_tbook.bv10a = getBidVa(10);
        m_tbook.ap10  = getAsk  (10); m_tbook.av10  = getAskV (10); m_tbook.av10a = getAskVa(10);
        
        m_tbook.bp11  = getBid  (11); m_tbook.bv11  = getBidV (11); m_tbook.bv11a = getBidVa(11);
        m_tbook.ap11  = getAsk  (11); m_tbook.av11  = getAskV (11); m_tbook.av11a = getAskVa(11);
        
        m_tbook.bp12  = getBid  (12); m_tbook.bv12  = getBidV (12); m_tbook.bv12a = getBidVa(12);
        m_tbook.ap12  = getAsk  (12); m_tbook.av12  = getAskV (12); m_tbook.av12a = getAskVa(12);
        
        m_tbook.bp13  = getBid  (13); m_tbook.bv13  = getBidV (13); m_tbook.bv13a = getBidVa(13);
        m_tbook.ap13  = getAsk  (13); m_tbook.av13  = getAskV (13); m_tbook.av13a = getAskVa(13);
        
        m_tbook.bp14  = getBid  (14); m_tbook.bv14  = getBidV (14); m_tbook.bv14a = getBidVa(14);
        m_tbook.ap14  = getAsk  (14); m_tbook.av14  = getAskV (14); m_tbook.av14a = getAskVa(14);
        
        m_tbook.bp15  = getBid  (15); m_tbook.bv15  = getBidV (15); m_tbook.bv15a = getBidVa(15);
        m_tbook.ap15  = getAsk  (15); m_tbook.av15  = getAskV (15); m_tbook.av15a = getAskVa(15);
        
        m_tbook.bp16  = getBid  (16); m_tbook.bv16  = getBidV (16); m_tbook.bv16a = getBidVa(16);
        m_tbook.ap16  = getAsk  (16); m_tbook.av16  = getAskV (16); m_tbook.av16a = getAskVa(16);
   */     
        m_tbook.imb01 = getImbalance(01); m_tbook.iwfv01 = getIWFV(01); m_tbook.tlfv01 = getTLFV(01);
        m_tbook.imb02 = getImbalance(02); m_tbook.iwfv02 = getIWFV(02); m_tbook.tlfv02 = getTLFV(02);
        m_tbook.imb03 = getImbalance(03); m_tbook.iwfv03 = getIWFV(03); m_tbook.tlfv03 = getTLFV(03);
        m_tbook.imb04 = getImbalance(04); m_tbook.iwfv04 = getIWFV(04); m_tbook.tlfv04 = getTLFV(04);
        m_tbook.imb05 = getImbalance(05); m_tbook.iwfv05 = getIWFV(05); m_tbook.tlfv05 = getTLFV(05);
        m_tbook.imb06 = getImbalance(06); m_tbook.iwfv06 = getIWFV(06); m_tbook.tlfv06 = getTLFV(06);
        m_tbook.imb07 = getImbalance(07); m_tbook.iwfv07 = getIWFV(07); m_tbook.tlfv07 = getTLFV(07);
        m_tbook.imb08 = getImbalance(08); m_tbook.iwfv08 = getIWFV(08); m_tbook.tlfv08 = getTLFV(08);
        m_tbook.imb09 = getImbalance(09); m_tbook.iwfv09 = getIWFV(09); m_tbook.tlfv09 = getTLFV(09);
 /*     m_tbook.imb10 = getImbalance(10); m_tbook.iwfv10 = getIWFV(10); m_tbook.tlfv10 = getTLFV(10);
        m_tbook.imb11 = getImbalance(11); m_tbook.iwfv11 = getIWFV(11); m_tbook.tlfv11 = getTLFV(11);
        m_tbook.imb12 = getImbalance(12); m_tbook.iwfv12 = getIWFV(12); m_tbook.tlfv12 = getTLFV(12);
        m_tbook.imb13 = getImbalance(13); m_tbook.iwfv13 = getIWFV(13); m_tbook.tlfv13 = getTLFV(13);
        m_tbook.imb14 = getImbalance(14); m_tbook.iwfv14 = getIWFV(14); m_tbook.tlfv14 = getTLFV(14);
        m_tbook.imb15 = getImbalance(15); m_tbook.iwfv15 = getIWFV(15); m_tbook.tlfv15 = getTLFV(15);
        m_tbook.imb16 = getImbalance(16); m_tbook.iwfv16 = getIWFV(16); m_tbook.tlfv16 = getTLFV(16);
*/
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
        
        m_pesos[00] = 0.98;
        m_pesos[01] = 0.89;
        m_pesos[02] = 0.82;
        m_pesos[03] = 0.78;
        m_pesos[04] = 0.73;
        m_pesos[05] = 0.71;
        m_pesos[06] = 0.70;
        m_pesos[07] = 0.65;
        m_pesos[08] = 0.60;
        m_pesos[09] = 0.55;
        m_pesos[10] = 0.50;
        m_pesos[11] = 0.45;
        m_pesos[12] = 0.40;
        m_pesos[13] = 0.35;
        m_pesos[14] = 0.30;
        m_pesos[15] = 0.25;
        
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
    
    double getImbalance(int deep){ return m_vetBook[deep-1][ IMB    ]; } // imbalance
    double getAsk      (int deep){ return m_vetBook[deep-1][ ASK    ]; } // preco
    double getBid      (int deep){ return m_vetBook[deep-1][ BID    ]; } // preco
    double getAskV     (int deep){ return m_vetBook[deep-1][VASK    ]; } // volume
    double getBidV     (int deep){ return m_vetBook[deep-1][VBID    ]; } // volume
    double getAskVa    (int deep){ return m_vetBook[deep-1][VACUMASK]; } // volume acumulado
    double getBidVa    (int deep){ return m_vetBook[deep-1][VACUMBID]; } // volume acumulado
    double getIWFV     (int deep){ return m_vetBook[deep-1][IWFV    ]; } // inverse size weighted fair value price
    double getTLFV     (int deep){ return m_vetBook[deep-1][TLFV    ]; } // Liquidity Threshould fair value price

    double getImbalance(){ return getImbalance(m_deep); }
    double getAsk      (){ return getAsk      (m_deep); }
    double getBid      (){ return getBid      (m_deep); }
  
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

