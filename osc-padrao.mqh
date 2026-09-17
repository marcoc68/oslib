//+------------------------------------------------------------------+
//|                                                   osc-padrao.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|  Classe padrao OS                                                |
//+------------------------------------------------------------------+
class osc_padrao {
private:
  static int     s_id_gen; // semente geradora de ID pra todas as instancias.
         int     m_id    ; // id da  instancia.
         
         MqlTick m_tick_ant_padrao;
         uint    m_qtd_tick_consertado;
  
  void setId(){m_id = s_id_gen++;} // define ID unico dentre as demais instancias de osc_padrao;
  

protected:
         int    getId   (){return m_id                    ;} // retorna ID unico dentre as demais instancias de osc_padrao;
         string getIdStr(){return IntegerToString(getId());} // retorna ID unico dentre as demais instancias de osc_padrao em formato String;
         
         void   initQtdTickConsertado(){m_qtd_tick_consertado=0;}
public:
         osc_padrao(){setId(); }
  double oneIfZero (double p          ) {return (p==0.0)?1.0:p;}
  double   xIfZero (double p, double x) {return (p==0.0)?x  :p;}

  static bool isTkBuy(MqlTick& tick){ return ( (tick.flags&TICK_FLAG_BUY   )==TICK_FLAG_BUY    );} // Aconteceu uma compra
  static bool isTkSel(MqlTick& tick){ return ( (tick.flags&TICK_FLAG_SELL  )==TICK_FLAG_SELL   );} // Aconteceu uma venda
  static bool isTkAsk(MqlTick& tick){ return ( (tick.flags&TICK_FLAG_ASK   )==TICK_FLAG_ASK    );} // Aconteceu uma alteracao no preco de compra
  static bool isTkBid(MqlTick& tick){ return ( (tick.flags&TICK_FLAG_BID   )==TICK_FLAG_BID    );} // Aconteceu uma alteracao no preco de venda
  static bool isTkLas(MqlTick& tick){ return ( (tick.flags&TICK_FLAG_LAST  )==TICK_FLAG_LAST   );} // Aconteceu uma alteracao no preco negociado
  static bool isTkVol(MqlTick& tick){ return ( (tick.flags&TICK_FLAG_VOLUME)==TICK_FLAG_VOLUME );} // Aconteceu uma alteracao no volume total negociado
//static bool isTkTra(MqlTick& tick){ return (  isTkBuy(tick) || isTkSel(tick)                 );} // Aconteceu uma compra ou uma venda
  static bool isTkTra(MqlTick& tick){ return (  isTkVol(tick) || isTkLas(tick) ||
                                                isTkBuy(tick) || isTkSel(tick)                 );} // Aconteceu uma compra ou uma venda

  uint getQtdTicksConsertados(){return m_qtd_tick_consertado;}

  string strTick(MqlTick& tick){
    return " ask:"   + tick.ask      +
           " bid:"   + tick.bid      +
           " last:"  + tick.last     +
           " vol:"   + tick.volume   +
           " isBuy:" + isTkBuy(tick) +
           " isSel:" + isTkSel(tick) +
           " isAsk:" + isTkAsk(tick) +
           " isBid:" + isTkBid(tick) +
           " isLas:" + isTkLas(tick) +
           " isVol:" + isTkVol(tick);
  }
  
  void consertarTickSemFlag(MqlTick& tick){
      // tick tem flag. atualizo tick anterior e termino...
      if( tick.flags!=0 ){
          m_tick_ant_padrao = tick;
          return;
      }
            
      // tem last diferente do tick anterior...
      if(tick.last != m_tick_ant_padrao.last){
          if( tick.last == tick.bid ){
                  tick.flags = tick.flags|TICK_FLAG_SELL|TICK_FLAG_LAST|TICK_FLAG_VOLUME;
                  if(tick.volume     ==0) tick.volume     ++;
                  if(tick.volume_real==0) tick.volume_real++;
                  m_qtd_tick_consertado++;
          }else{
              if(tick.last == tick.ask){
                  tick.flags = tick.flags|TICK_FLAG_BUY|TICK_FLAG_LAST|TICK_FLAG_VOLUME;
                  if(tick.volume     ==0) tick.volume     ++;
                  if(tick.volume_real==0) tick.volume_real++;
                  m_qtd_tick_consertado++;
              }
          }
      }else{
      
          // tem volume e eh diferente do volume do tick anterior
          if(tick.volume != m_tick_ant_padrao.volume && tick.volume != 0){
              if( tick.last == tick.bid ){
                  tick.flags = tick.flags|TICK_FLAG_SELL|TICK_FLAG_VOLUME;
                  m_qtd_tick_consertado++;
              }else{
                  if(tick.last == tick.ask){
                      tick.flags = tick.flags|TICK_FLAG_BUY|TICK_FLAG_VOLUME;
                      m_qtd_tick_consertado++;
                  }
              }
          }
      }
      
      // atualizando o tick anterior...
      m_tick_ant_padrao = tick;

  }
};

int osc_padrao::s_id_gen = 1;
