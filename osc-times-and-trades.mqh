﻿//+------------------------------------------------------------------+
//|                                              osc-estatistic2.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"

#include "osc-padrao.mqh"
//+-----------------------------------------------------------------------------------------------+
//| Classe que representa o times and trades.                                                     |
//| Versao inicial.                                                                               |
//+-----------------------------------------------------------------------------------------------+

class osc_times_and_trades:public osc_padrao{
private:

  double m_volBuy;
  double m_volSel;

public:
   osc_times_and_trades(){Print(__FUNCTION__,":compilado em:",__DATETIME__);}
  ~osc_times_and_trades(){Print(__FUNCTION__,":finalizado!"               );}// {delete(&m_aceVolTot);}
  
  void initialize(){ m_volBuy = 0; m_volSel = 0; } 
  void addTick( MqlTick& tick );

  //--- dados de tendencia e reversao (agressoes ao book)
  double getVolBuy(){ return m_volBuy; } // volume acumulado de compras
  double getVolSel(){ return m_volSel; } // volume acumulado de vendas


}; // fim do corpo da classe

void osc_times_and_trades::addTick( MqlTick& tick ){

  if( isTkSel(tick) ) { m_volSel += tick.volume_real; }
  if( isTkBuy(tick) ) { m_volBuy += tick.volume_real; }

}
