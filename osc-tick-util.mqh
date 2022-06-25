//+------------------------------------------------------------------+
//|                                                osc-tick-util.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"

#include "osc-padrao.mqh"
//+-----------------------------------------------------------------------------------------------+
//| Metodos utilitarios para lidar com ticks.                                                     |
//+-----------------------------------------------------------------------------------------------+

class osc_tick_util : public osc_padrao{
private:
   double  m_tickSize;
   int     m_tickDig ;
   MqlTick m_tickAnt ;
   bool    m_primTick;
   bool    m_gerou_title;
   
   // -- usados na normalizacao de ticks 
   double  m_vol_tmp;
   double  m_sel_tmp;
   double  m_buy_tmp;
   // -- usados na normalizacao de ticks 

   void setTickAnt(MqlTick& tick){
      m_tickAnt.ask=tick.ask;
      m_tickAnt.bid=tick.bid;
      m_primTick=false;
   }

public:
         osc_tick_util(){m_primTick = true;}

  void   normalizar2trade( MqlTick& tick                               );
//void   normalizar2Book ( MqlTick& tick     , MqlBookInfo[]& pBook    );
  void   setTickSize     ( double   pTickSize, int            pDigitos );


         string toString()                                { return toString   (m_tickAnt, ""      ); }
         string toString(                string msgDebug ){ return toString   (m_tickAnt, msgDebug); }
         string toString( MqlTick& tick, string msgDebug );
  static string toString( MqlTick& tick, const int dig);
  string toStringCSV()                                { return toStringCSV(m_tickAnt, ""      ); }
  string toStringCSV(                string msgDebug ){ return toStringCSV(m_tickAnt, msgDebug); }
  string toStringCSV( MqlTick& tick, string msgDebug );
};

void osc_tick_util::setTickSize( double pTickSize, int pDigitos ){
  m_tickDig = pDigitos;

  if(pTickSize==0){
     if(pDigitos==0){
       m_tickSize=1;
     }else{
       m_tickSize= ( 1/MathPow(10,pDigitos) );
     }
     return;
  }
  m_tickSize = pTickSize;
}

//+------------------------------------------------------------------+
//| Transforma ticks sem volume em ticks de trade.                   |
//| Usado para simular trades em corretoras que nao informam ticks   |
//| de trade.                                                        |
//+------------------------------------------------------------------+
void osc_tick_util::normalizar2trade(MqlTick& tick){
     // jah eh um tick de trade, entao consertamos o volume (se necessario) e saimos...
    if( isTkTra(tick) ){
        //Print(__FUNCSIG__, " EH UM TICK TRADE");
        if(tick.volume > 0){ setTickAnt(tick); return; } // eh um tick trade completo. saimos sem alterar o tick.
        if( isTkSel(tick) ){ tick.volume++; tick.volume_real++; tick.flags = tick.flags|TICK_FLAG_VOLUME;}
        if( isTkBuy(tick) ){ tick.volume++; tick.volume_real++; tick.flags = tick.flags|TICK_FLAG_VOLUME;}
        setTickAnt(tick); return;
    }

     m_sel_tmp = 0;
     m_buy_tmp = 0;

     // pra nao termos problemas nas comparacoes mais a frente
     if( m_primTick ){ setTickAnt(tick); }

     // se chegou aqui, nao eh um tick trade. Vamos transformar geral...
     if( isTkAsk(tick) ){

        // subiu o preco ask no book, entao injetamos a agressao de compra que subiu o ask...
        if( tick.ask > m_tickAnt.ask ){
           //Print(__FUNCSIG__, " ASK SUBIU");

            m_buy_tmp = tick.ask - m_tickSize; // compra que fez aumentar o ask foi um tick abaixo do preco oferta ask.

            m_vol_tmp = (tick.ask-m_tickAnt.ask)/m_tickSize; // Maior variacao do preco, simulamos volume maior (pode causar distorsao).
            tick.volume_real +=           m_vol_tmp ;
            tick.volume      += (int)ceil(m_vol_tmp);
            tick.flags        = tick.flags|TICK_FLAG_BUY|TICK_FLAG_LAST|TICK_FLAG_VOLUME;
        }
     }

     if( isTkBid(tick) ){

        // baixou o preco bid no book, entao injetamos a agressao de venda que baixou o bid...
        if( tick.bid < m_tickAnt.bid    ){
            //Print(__FUNCSIG__, " BID DESCEU");

            m_sel_tmp = tick.bid + m_tickSize; // venda que fez diminuir o bid foi um tick acima do preco de oferta bid.

            m_vol_tmp = (m_tickAnt.bid-tick.bid)/m_tickSize; // Maior variacao do preco, simulamos volume maior (pode causar distorsao).
            tick.volume_real +=           m_vol_tmp ;
            tick.volume      += (int)ceil(m_vol_tmp);
            tick.flags        = tick.flags|TICK_FLAG_SELL|TICK_FLAG_LAST|TICK_FLAG_VOLUME;
        }
     }

     //Print(osc_tick_util::toString(tick,1));
     if( m_buy_tmp > 0 && m_sel_tmp > 0 ){ tick.last = (m_buy_tmp+m_sel_tmp)/2; setTickAnt(tick); return;}
     if( m_buy_tmp > 0                  ){ tick.last =  m_buy_tmp             ; setTickAnt(tick); return;}
     if( m_sel_tmp > 0                  ){ tick.last =  m_sel_tmp             ; setTickAnt(tick); return;}
                                                                                setTickAnt(tick); return;

    //  if( buy > 0 && sel > 0 ){ tick.last = (buy+sel)/2; Print(toString("ANT"));setTickAnt(tick); Print(toString("BUY/SEL")); return;}
    //  if( buy > 0            ){ tick.last =  buy       ; Print(toString("ANT"));setTickAnt(tick); Print(toString("BUY"    )); return;}
    //  if( sel > 0            ){ tick.last =  sel       ; Print(toString("ANT"));setTickAnt(tick); Print(toString("SEL"    )); return;}
    //                                                                            setTickAnt(tick);                             return;
}


// //+------------------------------------------------------------------+
// //| Cria uma estrutura de book a partir de um tick.                  |
// //| Usado para simular trades em corretoras que nao informam o DOM.  |
// //+------------------------------------------------------------------+
// void osc_tick_util::normalizar2Book(MqlTick& tick, MqlBookInfo[]& pBook ){
//    MqlBookInfo book[2];
//    book[0].price       = tick.ask      ;
//    book[0].type        = BOOK_TYPE_SELL;
//    book[0].volume      = 1             ;
//    book[0].volume_real = 1             ;
//    book[1].price       = tick.bid      ;
//    book[1].type        = BOOK_TYPE_BUY ;
//    book[1].volume      = 1             ;
//    book[1].volume_real = 1             ;
//    pBook = book;
// }

static string osc_tick_util::toString(MqlTick& tick, const int dig){
   return
          "[time:"       + TimeToString   (tick.time       ) + "]" +  //datetime time;        // Hora da ultima atualizacao de precos
          "[bd:"         + DoubleToString (tick.bid        ,dig) + "]" +  //double   bid;         // Preco corrente de venda
          "[ak:"         + DoubleToString (tick.ask        ,dig) + "]" +  //double   ask;         // Preco corrente de compra
          "[ls:"         + DoubleToString (tick.last       ,dig) + "]" +  //double   last;        // Preco da última operação (preço ultimo)
          "[vl:"         + IntegerToString(tick.volume     ) + "]" +  //ulong    volume;      // Volume para o preco último corrente
        //"[time_msc:"   + IntegerToString(tick.time_msc   ) + "]" +  //long     time_msc;    // Tempo do "Last" preço atualizado em  milissegundos
          "[vlr:"        + DoubleToString (tick.volume_real,dig) + "]" +  //double   volume_real; // Volume para o preco Last atual com maior precisao
          "[flg:"        + IntegerToString(tick.flags      ) + "]" +  //uint     flags;       // Flags de tick
          "[Ask:"        + IntegerToString(isTkAsk(tick)   ) + "]" +
          "[Bid:"        + IntegerToString(isTkBid(tick)   ) + "]" +
          "[Buy:"        + IntegerToString(isTkBuy(tick)   ) + "]" +
          "[Sel:"        + IntegerToString(isTkSel(tick)   ) + "]" +
          "[Las:"        + IntegerToString(isTkLas(tick)   ) + "]" ;
}

string osc_tick_util::toString(MqlTick& tick,string msgDebug){
   return
          "[time:"       + TimeToString   (tick.time                 ) + "]" +  //datetime time;        // Hora da última atualização de preços
          "[bd:"         + DoubleToString (tick.bid        ,m_tickDig) + "]" +  //double   bid;         // Preço corrente de venda
          "[ak:"         + DoubleToString (tick.ask        ,m_tickDig) + "]" +  //double   ask;         // Preço corrente de compra
          "[ls:"         + DoubleToString (tick.last       ,m_tickDig) + "]" +  //double   last;        // Preço da última operação (preço último)
          "[vl:"         + IntegerToString(tick.volume               ) + "]" +  //ulong    volume;      // Volume para o preço último corrente
        //"[time_msc:"   + IntegerToString(tick.time_msc             ) + "]" +  //long     time_msc;    // Tempo do "Last" preço atualizado em  milissegundos
          "[vlr:"        + DoubleToString (tick.volume_real,m_tickDig) + "]" +  //double   volume_real; // Volume para o preço Last atual com maior precisão
          "[flg:"        + IntegerToString(tick.flags                ) + "]" +  //uint     flags;       // Flags de tick
          "[Ask:"        + IntegerToString(isTkAsk(tick)             ) + "]" +
          "[Bid:"        + IntegerToString(isTkBid(tick)             ) + "]" +
          "[Buy:"        + IntegerToString(isTkBuy(tick)             ) + "]" +
          "[Sel:"        + IntegerToString(isTkSel(tick)             ) + "]" +
          "[Las:"        + IntegerToString(isTkLas(tick)             ) + "]" +
          "[Dbg:"        + msgDebug                                    + "]" ;
}

string osc_tick_util::toStringCSV(MqlTick& tick,string msgDebug){

  string linhacsv = "";

  if(!m_gerou_title){
    m_gerou_title = true;
    linhacsv = "time;bid;ask;las;vol;vlr;flg;EAsk;EBid;EBuy;ESel;ELas;Dbg;\n";
  }

   linhacsv = linhacsv +
          TimeToString   (tick.time                 ) + ";" +  //datetime time;        // Hora da última atualização de preços
          DoubleToString (tick.bid        ,m_tickDig) + ";" +  //double   bid;         // Preço corrente de venda
          DoubleToString (tick.ask        ,m_tickDig) + ";" +  //double   ask;         // Preço corrente de compra
          DoubleToString (tick.last       ,m_tickDig) + ";" +  //double   last;        // Preço da última operação (preço último)
          IntegerToString(tick.volume               ) + ";" +  //ulong    volume;      // Volume para o preço último corrente
        //IntegerToString(tick.time_msc             ) + ";" +  //long     time_msc;    // Tempo do "Last" preço atualizado em  milissegundos
          DoubleToString (tick.volume_real,m_tickDig) + ";" +  //double   volume_real; // Volume para o preço Last atual com maior precisão
          IntegerToString(tick.flags                ) + ";" +  //uint     flags;       // Flags de tick
          IntegerToString(isTkAsk(tick)             ) + ";" +  //         EHAsk
          IntegerToString(isTkBid(tick)             ) + ";" +  //         EHBid
          IntegerToString(isTkBuy(tick)             ) + ";" +  //         EHBuy
          IntegerToString(isTkSel(tick)             ) + ";" +  //         EHSel
          IntegerToString(isTkLas(tick)             ) + ";" +  //         EHLas
          msgDebug                                    + ";" ;  //         Dbg
   return linhacsv;
}

