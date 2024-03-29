﻿//+------------------------------------------------------------------+
//|                                                      CBarTick.mqh|
//|                               Copyright 2020,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//+------------------------------------------------------------------+
#property copyright "2020, Oficina de Software."
#property link      "http://www.os.net"
//---

#include <oslib\osc-estatistic2.mqh>

struct OsRateTick{
   MqlRates rate          ;
   double   vol_buy       ;
   double   vol_sel       ;
   ulong    first_time_msc; // timestamp do primeiro tick da barra
   ulong    last_time_msc ; // timestamp do ultimo tick da barra
   
   double   ret           ; // retorno     =     closeAnt  -     close;
   double  lret           ; // log retorno = log(closeAnt) - log(close);
   int      pup           ; // 1 se preco subiu  x ticks en relacao ao fechamento da barra anterior
   int      pdw           ; // 1 se preco desceu x ticks en relacao ao fechamento da barra anterior
   
   double   vel_vol_buy   ; // velocidade do volume de compras
   double   vel_vol_sel   ; // velocidade do volume de vendas
   double   vel_vol_liq   ; // velocidade do volume liquido
   double   ace_vol_buy   ; // aceleracao da velocidade do volume de compra
   double   ace_vol_sel   ; // aceleracao da velocidade do volume de vendas
   double   ace_vol_liq   ; // aceleracao do volume liquido
};

// CBarTick representa uma barra formada por ticks.
//
// Como se usa:
//  Para formar a barra: 
//  1. inicialize a classe executando o metodo initialize onde se informe o timeframe 
//     da barra em segundos e o tamanho do tick em pontos.
//
//  2. obtenha uma fonte de ticks sequenciais e adicioneos a barra usando o medoto add. A cada adicao serah retornado:
//      0: nao eh um tick de trade                     (nao eh adicionado)
//     -1: time anterior  ao do primeiro tick da barra (nao eh adicionado)
//      2: time posterior ao do periodo da barra       (nao eh adicionado)
//                                                     (a barra estah concluida e jah pode ser obtida com metodo getRateTick)
//      1: tick adicionado a barra com sucesso
//
//  3. quando receber 2 no retorno de add, obtenha a barra formada. Para isso use o metodo getRateTick, que retornarah
//     um objeto do tipo OsRateTick por referência. Use o objeto OsRateTick e inicialize a CBarTick para comecar nova
//     acumulacao. 
//     
//     Veja exemplo de uso feito na classe CExport que leh fluxo de ticks e grava barras de ticks em arquivo 
//
//     for(int i=0; i<qtdTicks; i++) {
//         result = cBarTick.add(ticks[i]);
//         switch( result ){
//             case 2: {   qt++;
//                         cBarTick.getRateTick(rateTick);
//                         Print(":-| ", __FUNCTION__, ": Print Bartick: ",qt," :", rateTick.rate.time," ...");
//                         fileWriteRateTick (file,rateTick);
//                         cBarTick.initBarTick();
//                         cBarTick.add(ticks[i]);
//                         break;
//                     };
//             case -1:{   Print(":-( ", __FUNCTION__, ": ERRO: Tentativa de acrescentar um tick antigo em OsRateTick!"); 
//                         break;
//                     }  
//         }        
//     }
//     // escrevendo a ultima barra no arquivo...
//     cBarTick.getRateTick(rateTick);
//     fileWriteRateTick (file,rateTick);
//  
//------------------------------------------------------------------------------------------------------------
class CBarTick{
    private:
        bool isTkBuy(const MqlTick& tick){ return ( (tick.flags&TICK_FLAG_BUY   )==TICK_FLAG_BUY    );} // Aconteceu uma compra
        bool isTkSel(const MqlTick& tick){ return ( (tick.flags&TICK_FLAG_SELL  )==TICK_FLAG_SELL   );} // Aconteceu uma venda
        bool isTkLas(const MqlTick& tick){ return ( (tick.flags&TICK_FLAG_LAST  )==TICK_FLAG_LAST   );} // Aconteceu uma alteracao no preco negociado
        bool isTkVol(const MqlTick& tick){ return ( (tick.flags&TICK_FLAG_VOLUME)==TICK_FLAG_VOLUME );} // Aconteceu uma alteracao no volume total negociado
        bool isTkTra(const MqlTick& tick){ return (  isTkVol(tick) || 
                                                     isTkLas(tick) ||
                                                     isTkBuy(tick) ||
                                                     isTkSel(tick)  ); } // Aconteceu uma compra ou uma venda
    
        datetime   calcTimeBar(const MqlTick &tick){ return tick.time-tick.time%m_time_frame; }
        OsRateTick m_rate        , // barra em formacao
                   m_rate_formada; // ultima barra formada
        uint       m_time_frame  ; // periodo da barra em segundos.
        uint       m_vol_frame   ; // periodo da barra em volume.
        double     m_tick_size   ;
        double     m_close_ant   ; // para calculo do campo ret
        bool       m_bar_volume  ;
    protected:
    public:
        int add(const MqlTick &tick); // adiciona um tick a barra correspondente no vetor de barras. 
        
        //construtor default (timeframe=1seg e ticksize=5)
        CBarTick(){ initialize(1,5);
                    //m_time_frame    = 1;
                    //m_tick_size     = 5; 
                    //initBarTick(m_rate);
        }
        
        //construtor parametrico. recebe timeframe e ticksize
        void initialize (const uint _timeframe, const double _ticksize){ 
                    m_time_frame    = _timeframe;
                    m_tick_size     = _ticksize;
                    m_close_ant     = 0;    
                    initBarTick(m_rate);
        }
        
        void getRateTick( OsRateTick &rate ){ rate = m_rate; } // extrai a barra formada
        void initBarTick(){ initBarTick(m_rate); }
        void initBarTick( OsRateTick &rate );
        void setTickSize(double v){ m_tick_size=v; }
};

void CBarTick::initBarTick( OsRateTick &rt ){
   rt.rate.close       = 0;
   rt.rate.high        = 0;
   rt.rate.low         = 0;
   rt.rate.open        = 0;
   rt.rate.real_volume = 0;
   rt.rate.spread      = 0;
   rt.rate.tick_volume = 0;
   rt.rate.time        = 0;
   rt.first_time_msc   = 0;
   rt.last_time_msc    = 0;
   rt.vol_buy          = 0;
   rt.vol_sel          = 0;
      
   rt.ret              = 0; //     retorno;
   rt.lret             = 0; // log retorno;
   
   rt.pup            = 0;
   rt.pdw            = 0;
   
   rt.vel_vol_buy      = 0; // velocidade do volume de compras
   rt.vel_vol_sel      = 0; // velocidade do volume de vendas
   rt.vel_vol_liq      = 0; // velocidade do volume liquido
   rt.ace_vol_buy      = 0; // aceleracao da velocidade do volume de compra
   rt.ace_vol_sel      = 0; // aceleracao da velocidade do volume de vendas
   rt.ace_vol_liq      = 0; // aceleracao do volume liquido
}

// adiciona um tick a barra correspondente no vetor de barras. 
// retorna:
//  0: nao eh um tick de trade (nao adicionou a barra)
//  1: adicionou a barra
//  2: tick posterior ao periodo da barra(nao adicionou a barra)
// -1: tick anterior  ao periodo da barra(nao adicionou a barra)

int CBarTick::add(const MqlTick &tick){

    // 1. soh adiciona se houve negociacao...
    if( !isTkTra(tick) ) return 0;
    
    // 2. tick menor que o inicio do periodo eh erro...
    if( tick.time < m_rate.rate.time  ) return -1;
    
    // 3. tick maior que o fim do periodo informado 2
    if( m_rate.rate.time !=0 && tick.time >= m_rate.rate.time+m_time_frame ){ m_close_ant = m_rate.rate.close; return 2;};
    
    // 4. adicionar o primeiro tick a barra.
    if( m_rate.rate.open == 0 ){
        // campos originais da barra MqlRates...
        m_rate.rate.open        = tick.last;
        m_rate.rate.high        = tick.last;
        m_rate.rate.low         = tick.last;
        m_rate.rate.close       = tick.last;
        m_rate.rate.spread      = (int)((tick.ask-tick.bid)/m_tick_size);
        m_rate.rate.time        = calcTimeBar(tick);
        m_rate.rate.tick_volume = (long)tick.volume;
        m_rate.rate.real_volume = (long)tick.volume_real;
        
        // Campos exclusivos, presentes somente na barra de ticks...
        m_rate.first_time_msc = tick.time_msc; // timestamp do primeiro tick da barra
        m_rate.last_time_msc  = tick.time_msc; // timestamp do ultimo   tick da barra
        
        if( isTkBuy( tick ) ) m_rate.vol_buy = tick.volume_real;
        if( isTkSel( tick ) ) m_rate.vol_sel = tick.volume_real;
        
        m_rate.ret = m_close_ant==0?0:(log(tick.last)-log(m_close_ant));
        m_rate.ret = m_close_ant==0?0:(    tick.last -    m_close_ant );

        // marca se, durante a formacao desta barra, o preco subiu e/ou desceu em relacao ao fechamento da barra anterior.
        if( m_rate.ret> +10 ) m_rate.pup =1;
        if( m_rate.ret< -10 ) m_rate.pdw =1;
        
        return 1;
    }

    // 4. adicionar demais ticks a barra.
    if( m_rate.last_time_msc > (ulong)tick.time_msc ) return -1; // tick com timestamp menor que o ultimo adicionado...

                                       m_rate     .last_time_msc =         tick.time_msc;
    if( tick.last > m_rate.rate.high ) m_rate.rate.high          =         tick.last;
    if( tick.last < m_rate.rate.low  ) m_rate.rate.low           =         tick.last;
                                       m_rate.rate.close         =         tick.last;
                                       m_rate.rate.spread        = (int )((tick.ask-tick.bid)/m_tick_size);
                                       m_rate.rate.tick_volume  += (long)  tick.volume;
                                       m_rate.rate.real_volume  += (long)  tick.volume_real;
    if( isTkBuy( tick )              ) m_rate     .vol_buy      +=         tick.volume_real;
    if( isTkSel( tick )              ) m_rate     .vol_sel      +=         tick.volume_real;

    m_rate.lret = m_close_ant==0?0:(log(tick.last)-log(m_close_ant));
    m_rate. ret = m_close_ant==0?0:(    tick.last -    m_close_ant );

    // marca se, durante a formacao desta barra, o preco subiu e/ou desceu em relacao ao fechamento da barra anterior.
    if( m_rate.ret> +10 ) m_rate.pup =1;
    if( m_rate.ret< -10 ) m_rate.pdw =1;

    return 1;
}

