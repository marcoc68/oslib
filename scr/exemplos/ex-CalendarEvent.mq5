﻿//+------------------------------------------------------------------+
//|                                       ex-HistorySelectOrders.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"


class CCalendar{

private:
    MqlCalendarValue m_values[]; // array de eventos no calendario. 
    ulong            m_chage_id ; // id da ultima publicacao no banco de dados de evento que foi processada.
protected:
public:
    
    void printEventosPorMoeda( string moeda, int qtd_eventos_to_print );
    void printPaises();
    
    bool initOnPublication()    ; // inicializa o ouvinte de novas publicacoes no calendario de eventos; 
    bool dispararOnPublication(); // processa nova publicacao no calendario.
    void onPublication(const MqlCalendarValue& val[]);
};

bool CCalendar::initOnPublication(){     
    m_chage_id = 0;
    CalendarValueLast(m_chage_id,m_values);
    int erro = GetLastError();
    if( erro == 0 ) return true;
     
    Print(":-( ", __FUNCTION__, ": Erro inicializando ouvinte do calendario de eventos:", erro);
    return false;
}

bool CCalendar::dispararOnPublication(){
    if( CalendarValueLast(m_chage_id,m_values)<0 ){
        int erro = GetLastError();
        if( erro == 0 ) return true; // sem erros e sem novas publicacoes.

        Print(":-( ", __FUNCTION__, ": Erro disparando evento do calendario de eventos:", erro);
        return false;
    }

    onPublication(m_values); // disparando evento de publicacao no calendario.
    return true;
}

void CCalendar::onPublication(const MqlCalendarValue& val[]){
    ArrayPrint(val);
}


void CCalendar::printEventosPorMoeda( string moeda, int qtd_eventos_to_print ){
//--- declare um array para receber eventos do Calendário Econômico 
    MqlCalendarEvent events[]; 

//--- obtenha eventos para a moeda informada       
    int count = CalendarEventByCurrency(moeda,events); 
    Print("Qtd eventos para a moeda ",moeda, " = ", count); 

//--- por exemplo, 10 eventos são suficientes para nós 
    if(count>qtd_eventos_to_print) ArrayResize(events,qtd_eventos_to_print); 

//--- imprima eventos no Diário         
    ArrayPrint(events); 
}

void CCalendar::printPaises() {
 
//--- obtenha a lista de países do Calendario Economico 
    MqlCalendarCountry countries[]; 
    int count=CalendarCountries(countries); 
   
//--- quantidad de paises retornados pela funcao...
    Print("Qtd paises = ", count); 

//--- imprima eventos no Diário         
    ArrayPrint(countries);    
}


//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {

    CCalendar ce;
    
    ce.printEventosPorMoeda("BRL",55);
    ce.printPaises();
    
    ce.initOnPublication();
    
    while(true){
       ce.dispararOnPublication();
       Sleep(5000);
    }

}
