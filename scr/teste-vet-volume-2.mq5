//+------------------------------------------------------------------+
//|                                             teste-vet-volume.mq5 |
//|                                         Copyright 2022, OS Corp. |
//|                                                http://www.os.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, OS Corp."
#property link      "http://www.os.org"
#property version   "1.000"

//#property script_show_inputs
//input double  INI   = 0;  
//input double  FATOR = 1;
//input int     QTD   = 40;

#include <oslib/osc/data/osc-vet-circular-volume.mqh>

#define EA_QTD_TIK_VOL_IMBALANCE 300
//+------------------------------------------------------------------+
//| Teste de comportamento de vetores e matrizes                     |
//+------------------------------------------------------------------+

void OnStart(){

    osc_vet_circular_volume m_vet_vol             ; // vetor circular para acumulacao de volumes
    m_vet_vol.initialize(EA_QTD_TIK_VOL_IMBALANCE);

    // carregando a ultima hora de ticks...
    //datetime from = (TimeCurrent()-(60*60) ) ; // minutos atras
    //datetime to   = TimeCurrent()             ; // agora
    datetime from = D'2022.06.23 09:05:00';
    datetime to   = D'2022.06.23 17:50:00';
    
    MqlTick ticks1[];
    int qtdTicks1 = 0;
    string m_symb_str1 = _Symbol;
    double m_vol_imb = 0;
    
    
    Print( __FUNCTION__,": Copiando ticks do ativo ",m_symb_str1, " desde ",from , " até ", to, " ...");
    qtdTicks1 = CopyTicksRange( m_symb_str1     , //const string     symbol_name,          // nome do símbolo
                                ticks1          , //MqlTick&         ticks_array[],        // matriz para recebimento de ticks
                                COPY_TICKS_TRADE, //uint             flags=COPY_TICKS_ALL, // sinalizador que define o tipo de ticks obtidos
                                from*1000       , //ulong            from_msc=0,           // data a partir da qual são solicitados os ticks
                                to*1000           //ulong            to_msc=0              // data ate a qual são solicitados os ticks
                              );
    Print( __FUNCTION__,": Ticks copiados do ativo ",m_symb_str1,":",qtdTicks1);
    if(qtdTicks1>0){
        Print(__FUNCTION__,":-| Processando ", qtdTicks1, " historicos... Mais antigo eh:", ticks1[0].time );
        for(int i=0; i<qtdTicks1; i++){
            //normalizar2trade(ticks1[i]);
            if( osc_padrao::isTkVol(ticks1[i]) ){
                m_vet_vol.add(ticks1[i]);// adicionando o tick ao vetor de volumes
                m_vol_imb = m_vet_vol.get_desbalanceamento(); // obtendo o desbalancemento do volume;
                Print("i:",i, " imb:", m_vol_imb," dt:", ticks1[i].time, " vol:", ticks1[i].volume, " buy:", osc_padrao::isTkBuy(ticks1[i]),
                                                                                                    " sel:", osc_padrao::isTkSel(ticks1[i]) );
                
                if(i>1000) break;
            }
        }
        Print(__FUNCTION__,":-| teste-vet-volume ",qtdTicks1, " historicos ",m_symb_str1  ," processados... Mais novo eh:", ticks1[qtdTicks1-1].time );
    }
    
}
//+------------------------------------------------------------------+