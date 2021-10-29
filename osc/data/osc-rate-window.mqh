//+------------------------------------------------------------------+
//|                                               osc-rate-window.mqh|
//|                               Copyright 2020,oficina de software.|
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "2021, Oficina de Software."
#property link      "https://www.mql5.com/pt/users/marcoc"
//---
#include <oslib/osc/data/osc-rate-queue.mqh>
#include <oslib/osc/data/osc-rate.mqh>

class osc_rate_window{
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

        osc_rate       m_rate;
        osc_rate_queue m_rate_queue;
        double         m_vol;
        
    protected:
    public:
    
        int add(const MqlTick &tick){
            
        }
        
        //construtor default (timeframe=1seg e ticksize=5)
        osc_rate_window(){ initialize(1,5);
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

void osc_rate_window::initBarTick( OsRateTick &rt ){
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

int osc_rate_window::add(const MqlTick &tick){

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

