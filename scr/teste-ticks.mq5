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

#include <oslib/osc-tick-util.mqh>

//+------------------------------------------------------------------+
//| Teste de comportamento de vetores e matrizes                     |
//+------------------------------------------------------------------+

void OnStart(){

    osc_tick_util m_tick_utl;

    // carregando a ultima hora de ticks...
  //datetime from = (TimeCurrent()-(60*700) ) ; // minutos atras
  //datetime to   = TimeCurrent()             ; // agora
  
    datetime from = D'2022.06.23 09:00:00';
    datetime to   = D'2022.06.23 17:50:00';
    
  //datetime from = D'2022.06.24 09:00:00';
  //datetime to   = D'2022.06.24 17:50:00';
    
  //datetime from = D'2022.06.24 10:00:00';
  //datetime to   = D'2022.06.24 10:36:00';
    
  //datetime from = D'2022.06.24 10:48:00';
  //datetime to   = D'2022.06.24 11:19:00';
    
  //datetime from = D'2022.06.24 11:27:00';
  //datetime to   = D'2022.06.24 12:51:00';
    
    MqlTick ticks1[];
    int qtdTicks1 = 0;
    string m_symb_str1 = _Symbol;
    double m_vol_imb = 0;
    
    
    Print( __FUNCTION__,": Copiando ticks do ativo ",m_symb_str1, " desde ",from , " até ", to, " ...");
    qtdTicks1 = CopyTicksRange( m_symb_str1     , //const string     symbol_name,          // nome do símbolo
                                ticks1          , //MqlTick&         ticks_array[],        // matriz para recebimento de ticks
                                COPY_TICKS_ALL  , //uint             flags=COPY_TICKS_ALL, // sinalizador que define o tipo de ticks obtidos
                                from*1000       , //ulong            from_msc=0,           // data a partir da qual são solicitados os ticks
                                to*1000           //ulong            to_msc=0              // data ate a qual são solicitados os ticks
                              );
    Print( __FUNCTION__,": Ticks copiados do ativo ",m_symb_str1,":",qtdTicks1);
    if(qtdTicks1>0){
        int qtd=0;
        double volbuy=0; double volsel=0; double voltot=0;
        int    qtdbuy=0; int    qtdsel=0; int    qtdtot=0;
        datetime dt_pri_tick = 0;
        datetime dt_ult_tick = 0;

        Print(__FUNCTION__,":-| Processando ", qtdTicks1, " historicos... Mais antigo eh:", ticks1[0].time );
        for(int i=0; i<qtdTicks1; i++){
            //normalizar2trade(ticks1[i]);
            if( osc_padrao::isTkVol(ticks1[i]) ){
                //if( m_tick_utl.isTkBuy(ticks1[i]) && m_tick_utl.isTkSel(ticks1[i]) ){
                //    Print( m_tick_utl.toString(ticks1[i],0) );
                //    qtd++;
                //}
                                   dt_ult_tick=ticks1[i].time;
                if(dt_pri_tick==0) dt_pri_tick=ticks1[i].time;
                                   
                                   
                                                    voltot+=ticks1[i].volume_real; qtdtot++;
                if( m_tick_utl.isTkBuy(ticks1[i]) ){volbuy+=ticks1[i].volume_real; qtdbuy++;}
                if( m_tick_utl.isTkSel(ticks1[i]) ){volsel+=ticks1[i].volume_real; qtdsel++;}
                
            }    
            //if(qtd>1000) break;
        }
        
        string medsel = DoubleToString( volsel/qtdsel                  , 3);
        string medbuy = DoubleToString( volbuy/qtdbuy                  , 3);
        string medtot = DoubleToString( voltot/qtdtot                  , 3);
        string imb    = DoubleToString( (volbuy-volsel)/(volbuy+volsel), 3);
        
        Print(__FUNCTION__, " voltot=",voltot, " volbuy=",volbuy, " volsel=",volsel);
        Print(__FUNCTION__, " qtdtot=",qtdtot, " qtdbuy=",qtdbuy, " qtdsel=",qtdsel);
        Print(__FUNCTION__, " medtot=",medtot, " medbuy=",medbuy, " medsel=",medsel);
        Print(__FUNCTION__, " imbala=",imb);
        
        //datetime dt_pri_tick = ticks1[0          ].time;
        //datetime dt_ult_tick = ticks1[qtdTicks1-1].time;
        double   qtdseg      = (double)( dt_ult_tick-dt_pri_tick);
        double   qtdmin      = qtdseg/60;
        double   qtdhor      = qtdmin/60;
        Print(__FUNCTION__, " qtdseg=",qtdseg, " qtdmin=",qtdmin, " qtdhor=",qtdhor);
        
        double      ticks4seg = (double)(qtdtot/qtdseg);
        double      ticks4min = (double)(qtdtot/qtdmin);
        double      ticks4hor = (double)(qtdtot/qtdhor);
        
        Print(__FUNCTION__, " ticks4seg=",ticks4seg, " ticks4min=",ticks4min, " ticks4hor=",ticks4hor);
        

        Print(__FUNCTION__,":-| teste-vol-profile ",qtdTicks1, " historicos ",m_symb_str1  ," processados... Mais antigo é:", dt_pri_tick, " Mais novo é:",dt_ult_tick );
    }
    
}
//+------------------------------------------------------------------+