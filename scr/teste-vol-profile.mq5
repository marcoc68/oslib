//+------------------------------------------------------------------+
//|                                            teste-vol-profile.mq5 |
//|                                         Copyright 2022, OS Corp. |
//|                                                http://www.os.org |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, OS Corp."
#property link      "http://www.os.org"
#property version   "1.000"

//+------------------------------------------------------------------+
//| Teste da classe osc_vol_profile                                  |
//+------------------------------------------------------------------+

#include <oslib/osc/data/osc-vol-profile.mqh>

osc_vol_profile vprof;

void OnStart(){
    //osc_vol_profile vprof;
    //vprof.add(1000, 10);
    //vprof.add(1000, 05);
    //vprof.add(1010, 05);
    //vprof.add( 990, 20);
    //Print( vprof.toString() );

   vprof.m_param.qtd_seg_acum_vprof=20;
   vprof.m_param.porc_value_area   =68 ;
   
   datetime to;
   //while(true){
       to = TimeCurrent();
       to = D'2022.02.09 10:00:00';
       prepAndAnalizeRegres(  to-1000, to );
       //Sleep(50);
   //}
}

void prepAndAnalizeRegres(datetime dtFrom, datetime dtTo){
   MqlTick ticks[];
   int qtdTicks = 0;
   
   MqlDateTime dtFrom_, dtTo_;
   TimeToStruct(dtFrom,dtFrom_);
   TimeToStruct(dtTo  ,dtTo_  );
   
   //string desdeAte = dtFrom_.hour+":"+dtFrom_.min+":"+dtFrom_.sec+" a "+ 
   //                  dtTo_  .hour+":"+dtTo_  .min+":"+dtTo_  .sec      ;
   
   
     qtdTicks = CopyTicksRange(Symbol(),ticks,COPY_TICKS_TRADE ,dtFrom*1000, dtTo*1000 ); 

     for(int i=0; i<qtdTicks; i++){
         //vprof.add( ticks[i].last, ticks[i].volume_real, ticks[i].time_msc/1000 );
         //vprof.add( ticks[i].last, ticks[i].volume_real, ticks[i].time );
           vprof.add( ticks[i] );
     }
     
     vprof.calcular_area_de_valor();
     
     Print( vprof.toString() );
}

//+------------------------------------------------------------------+