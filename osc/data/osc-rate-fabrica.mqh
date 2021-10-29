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

#include <oslib/osc/data/osc-rate.mqh>


class osc_rate_fabrica {//: public CObject{

private:
    MqlTick  m_tick, m_tick_ant;
    osc_rate m_rate, m_rate_ant;
    double   m_tamanho   ; // tamanho de cada barra.
    double   m_vol_usar  ; // volume que serah usado para acrescentar o tick na barra m_rate.
    double   m_vol_sobra ; // volume que sobrarah apos colocar este tick na barra m_rate.
    
    void inicializar(double tamanho = 200){
        m_rate.inicializar();
        m_tamanho   = tamanho;
        m_vol_usar  = 0; // volume a usar ao colocar o tick atual nesta barra
        m_vol_sobra = 0; // volume sobrando apos colocar o tick atual nesta barra
    }
    

    bool isTkBuy(const MqlTick& tick){ return ( (tick.flags&TICK_FLAG_BUY   )==TICK_FLAG_BUY    );} // Aconteceu uma compra
    bool isTkSel(const MqlTick& tick){ return ( (tick.flags&TICK_FLAG_SELL  )==TICK_FLAG_SELL   );} // Aconteceu uma venda
    bool isTkLas(const MqlTick& tick){ return ( (tick.flags&TICK_FLAG_LAST  )==TICK_FLAG_LAST   );} // Aconteceu uma alteracao no preco negociado
    bool isTkVol(const MqlTick& tick){ return ( (tick.flags&TICK_FLAG_VOLUME)==TICK_FLAG_VOLUME );} // Aconteceu uma alteracao no volume total negociado
    bool isTkTra(const MqlTick& tick){ return (  isTkVol(tick) || 
                                                 isTkLas(tick) ||
                                                 isTkBuy(tick) ||
                                                 isTkSel(tick)  ); } // Aconteceu uma compra ou uma venda

    double pmed(MqlTick &tick){ return (tick.ask + tick.bid) / 2.0;}

    // extrai o volume do tick.
    double get_vol(MqlTick &tick){
        return tick.volume_real != 0 ? tick.volume_real : tick.volume;
    }

    // retorna os volumes de vendas e compras do tick...
    void get_vol(MqlTick &tick, double &vol_sell, double &vol_buy){
        
        vol_buy  = 0;
        vol_sell = 0;
        
        // tick eh resultado de uma venda e de uma compra...
        if( isTkSel(tick) && isTkBuy(tick) ){
            vol_buy  = m_vol_usar/2.0;
            vol_sell = vol_buy;
            return;
        }
        
        // tick eh resultado de uma venda...
        if( isTkSel(tick) ){ vol_sell  = m_vol_usar; return; }
        
        // tick eh resultado de uma compra...
        if( isTkBuy(tick) ){ vol_buy   = m_vol_usar; return; }
        
        double pmedi     = pmed(tick      );
        double pmedi_ant = pmed(m_tick_ant);
        
        // preco medio baixou...
        if( pmedi < pmedi_ant ){ vol_sell  = m_vol_usar; return; }
        
        // preco medio subiu...
        if( pmedi > pmedi_ant ){ vol_buy   = m_vol_usar; return; }
        
        // preco medio nao mudou e tick anterior foi uma venda...
        if( isTkSel(m_tick_ant) ){ vol_sell  = m_vol_usar; return; }
        
        // preco medio nao mudou e tick anterior foi uma compra...
        if( isTkBuy(m_tick_ant) ){ vol_buy   = m_vol_usar; return; }
        
        return;
    }

    // recebe o volume do tick que serah incluido na barra
    // atualiza o volume que deverah ser colocado na barra (m_vol_usar) e o volume que nao poderah ser colocado na barra (m_vol_sobra).
    // o volume (m_vol_usar) eh ajustado para que fique apenas o suficiente para completar o tamanho da barra.   
    void atualizar_volumes(double vol_tick){

        // volume do tick eh maior do que o necessario para 
        if( vol_tick+m_rate.vol > m_tamanho ){
            m_vol_usar  = vol_tick+m_rate.vol-m_tamanho;
            m_vol_sobra = vol_tick-m_vol_usar;
            return;
        }
        m_vol_usar  = vol_tick;
        m_vol_sobra = 0;
        return;
    }
    
public:

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
                             ,"|time "     ,m_rate.time
                             ,"|open "     ,m_rate.open
                             ,"|high "     ,m_rate.high
                             ,"|low "      ,m_rate.low
                             ,"|close "    ,m_rate.close 
                             ,"|vol "      ,m_rate.vol 
                             ,"|vol_sell " ,m_rate.vol_sell 
                             ,"|vol_buy "  ,m_rate.vol_buy 
                             ,"|ret "      ,m_rate.ret 
                          );
        return str;
    }

    // adiciona 1 tick a esta barra, retorna o volume que nao pode ser adicionado a barra
    double add_tick(MqlTick &tick){
        
        // calculando o volume que pode ser colocado na barra...
        double vol_sell = 0;
        double vol_buy  = 0;
        
        // atualizando o volume que serah adicionado a barra
        atualizar_volumes( get_vol(tick) );
        
        // calculando preco medio...
        double pmed = pmed(tick);
        
        // obtendo os volumes de compra e venda...
        get_vol(tick, vol_sell, vol_buy);

        // primeiro tick da primeira barra...
        if( m_rate.open==0){
            m_rate.open     = pmed;
            m_rate.high     = pmed;
            m_rate.low      = pmed;
            m_rate.close    = pmed;
            m_rate.vol      = m_vol_usar;
            m_rate.vol_sell = vol_sell;
            m_rate.vol_buy  = vol_buy;
            m_rate.ret      = 0;
            
            m_tick_ant = tick;
            
            // se completou a barra...
            if(m_rate.vol >= m_tamanho){
                m_rate_ant = m_rate;
            }
            return m_vol_sobra;
        }

        // se chegou aqui, eh porque nao se trata mais do primeiro tick        
        if(pmed>m_rate.high) m_rate.high      = pmed;
        if(pmed<m_rate.low ) m_rate.low       = pmed;
                        m_rate.vol      += m_vol_usar;
                        m_rate.vol_sell += vol_sell;
                        m_rate.vol_buy  += vol_buy ;
        if(pmed != m_rate.close){
            m_rate.close = pmed;
            m_rate.ret   = log(pmed) - log(rate_ant.close);
        }

        m_tick_ant = tick;
        
        if(m_vol_sobra==0) m_rate_ant = m_rate;
        return m_vol_sobra;
    }
    
    
};

