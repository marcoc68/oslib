﻿//+------------------------------------------------------------------+
//|                                                 C0600Strategy.mqh|
//|                               Copyright 2021,oficina de software.|
//|                                https://www.metaquotes.net/marcoc.|
//|                                                                  |
//| CLASSE BASE PARA CLASSES QUE IMPLEMENTAM ESTRATEGIAS DE TRADE.   |
//|                                                                  |
//|                                                                  |
//|                                                                  --------------------------------------------|
//|                                                                                                              |
//+--------------------------------------------------------------------------------------------------------------+
#property copyright "2021, Oficina de Software."
#property link      "httpS://www.os.net"

class C0600Strategy{
private:
protected:
string m_apmb_man ;//= "INM"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string m_apmb     ;//= "IN" ; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string m_apmb_sel ;//= "INS"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string m_apmb_buy ;//= "INB"; //string que identifica ordens de abertura de posicoes na media das ofertas do book.
string m_strRajada;//= "RJ" ; //string que identifica rajadas de abertura de novas posicoes.
public:
      C0600Strategy(): 
                    m_apmb_man ("INM"), //string que identifica ordens de abertura de posicoes na media das ofertas do book.
                    m_apmb     ("IN" ), //string que identifica ordens de abertura de posicoes na media das ofertas do book.
                    m_apmb_sel ("INS"), //string que identifica ordens de abertura de posicoes na media das ofertas do book.
                    m_apmb_buy ("INB"), //string que identifica ordens de abertura de posicoes na media das ofertas do book.
                    m_strRajada("RJ" )  //string que identifica rajadas de abertura de novas posicoes.
                    {}
};