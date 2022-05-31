//+------------------------------------------------------------------+
//|                                     osc_minion_trade_estatistica.|
//|                               Copyright 2020,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//+------------------------------------------------------------------+
#property copyright "2020, Oficina de Software."
#property link      "http://www.os.net"
//---
#include <Trade\DealInfo.mqh>
#include <Trade\SymbolInfo.mqh>


class osc_minion_trade_estatistica{

private:
    CDealInfo   m_deal             ;
    CSymbolInfo m_symbol           ;

    double    m_profitDiaLiquido   ;
    double    m_profitDiaLiquidoWDO;
    double    m_profitDiaLiquidoWIN;

    double    m_profitPorContratoWDO;
    double    m_profitPorContratoWIN;
    double    m_profitPorContrato   ;

    double    m_profitDia         ;
    double    m_profitDiaWDO      ;
    double    m_profitDiaWIN      ;

    double    m_volumeDia         ;
    double    m_volumeDiaWDO      ;
    double    m_volumeDiaWIN      ;

    double    m_tarifaDia         ;
    double    m_tarifaDiaWDO      ;
    double    m_tarifaDiaWIN      ;

    double    m_cotacaoMoedaTarifa   ;
    double    m_cotacaoMoedaTarifaWDO;
    double    m_cotacaoMoedaTarifaWIN;

    double    m_taxaLiqWIN;
    double    m_taxaLiqWDO;


  //string    m_str_symbol        ;

    double    m_valWinsDia; // valor bruto das vitorias no dia
    double    m_valLossDia; // valor bruto das perdas no dia
    double    m_payOut;     // fator de lucro no dia
    double    m_qtdWinsDia; // quantidade de trades vencedores no dia;
    double    m_qtdLossDia; // quantidade de trades perdedores no dia;
    double    m_probAcerto; // probabilidade de acertos, baseada no historico de transacoes;
    double    m_coefKelly ; // coeficente de Kelly;

    double    m_rebaixamentoSld; // rebaixamento de saldo ao final do dia.

 //string getSymbol           (){ return m_str_symbol        ;}
   double calcTarifaWIN       (const double pVolume);
   double calcTarifaWDO       (const double pVolume);
   double calcTarifa          (const double pVolume);

   bool ehMiniDolar (const string pSymbol){ return (StringFind(pSymbol,"WDO") > -1); }
   bool ehMiniIndice(const string pSymbol){ return (StringFind(pSymbol,"WIN") > -1); }

   void calcPayOut     ();
   void calcProbAcertos();
   void calcCoefKelly  ();

protected:
   double extrair_var_independente( const string comentario, const string letra_var );

public:
   void osc_minion_trade_estatistica();
 //void setStrSymbol            (const string   strSymbol ){ m_str_symbol         = strSymbol; }
   void initialize(){ m_rebaixamentoSld=0; m_taxaLiqWIN=0.0; m_taxaLiqWDO=0.12; m_symbol.Name(_Symbol); }
   void setCotacaoMoedaTarifaWDO(const double   cotacao   )  { m_cotacaoMoedaTarifa = cotacao  ; }
   void refresh       (const datetime from, const datetime to, double tarifa_teste=0);
   void print_posicoes(const datetime from, const datetime to);
   
   double getProfitDia           (){ return m_profitDia            ;}
   double getProfitDiaWDO        (){ return m_profitDiaWDO         ;}
   double getProfitDiaWIN        (){ return m_profitDiaWIN         ;}

   double getTarifaDia           (){ return m_tarifaDia            ;}
   double getTarifaDiaWDO        (){ return m_tarifaDiaWDO         ;}
   double getTarifaDiaWIN        (){ return m_tarifaDiaWIN         ;}

   double getProfitDiaLiquido    (){ return m_profitDiaLiquido     ;}
   double getProfitDiaLiquidoWDO (){ return m_profitDiaLiquidoWDO  ;}
   double getProfitDiaLiquidoWIN (){ return m_profitDiaLiquidoWIN  ;}

   double getProfitPorContrato   (){ return m_profitPorContrato    ;}
   double getProfitPorContratoWDO(){ return m_profitPorContratoWDO ;}
   double getProfitPorContratoWIN(){ return m_profitPorContratoWIN ;}

   double getVolumeDia           (){ return m_volumeDia            ;}
   double getVolumeDiaWDO        (){ return m_volumeDiaWDO         ;}
   double getVolumeDiaWIN        (){ return m_volumeDiaWIN         ;}

   double getProbAcerto          (){ return m_probAcerto           ;}
   double getPayOut              (){ return m_payOut               ;}
   double getCoefKelly           (){ return m_coefKelly            ;}

   double getRebaixamentoSld     (){ return m_rebaixamentoSld      ;}
};

void osc_minion_trade_estatistica::osc_minion_trade_estatistica(){
    m_profitDiaLiquido      = 0;
    m_profitDiaLiquidoWDO   = 0;
    m_profitDiaLiquidoWIN   = 0;
    m_profitPorContrato     = 0;
    m_profitPorContratoWDO  = 0;
    m_profitPorContratoWIN  = 0;
    m_volumeDia             = 0;
    m_volumeDiaWDO          = 0;
    m_volumeDiaWIN          = 0;
    m_cotacaoMoedaTarifa    = 0;
    m_cotacaoMoedaTarifaWDO = 5;
    m_cotacaoMoedaTarifaWIN = 1;
}


double osc_minion_trade_estatistica::extrair_var_independente( const string comentario, const string letra_var ){
    string var_independente[];
    
    int    pos1    = 0;
    double retorno = 0;
    ushort sep     = StringGetCharacter(" ",0);    
    int    qtd_var = StringSplit( comentario, sep, var_independente );
    
    if( qtd_var == 0 ){
        Print(__FUNCTION__, ":Caractere separador nao encontrado na string:", comentario);
        return 0;
    }
    if( qtd_var < 0 ){
        Print(__FUNCTION__, ":Erro ", GetLastError()," extraindo variavel independente da string:", comentario);
        return 0;
    }
    
    for( int i=1; i<qtd_var; i++ ){
        
        if( StringFind(var_independente[i],letra_var) > -1 ) return StringToDouble( StringSubstr(var_independente[i],1) );
    }
    return 0;
}


int openArqPosicoes(datetime from, datetime to){
    
    // data inicial. farah parte do nome do arquivo...
    string strFrom = TimeToString(from,TIME_DATE);
    StringReplace(strFrom,".","");

    // data final. farah parte do nome do arquivo...
    string strTo = TimeToString(to,TIME_DATE);
    StringReplace(strTo,".","");

    string nameArqPos =   strFrom   + "-" +
                          strTo     + "-" + "posicoes.csv";

    Print("Criando arquivo de posicoes ", nameArqPos, " no diretorio comum de arquivos...");
    
    int file = FileOpen(nameArqPos, FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
    
    if( file<0 ){
        Print("Falha para abrir o arquivo de posicoes: ", file        );
        Print("Codigo de erro: "                        , GetLastError() );
    }    
    return file;
}
void closeArqPosicoes(int arqPos){ 
    Print("Fechando arquivo de posicoes", arqPos, " ...");
    FileClose(arqPos); 
    Print("Arquivo de posicoes fechado!!!");
}


//+------------------------------------------------------------------+
//|                                                                  |
//| Escreve o resumo de cada posicao no arquivo de posicoes.                         |
//|                                                                  |
//+------------------------------------------------------------------+
void osc_minion_trade_estatistica::print_posicoes(const datetime from, const datetime to){

    Print(":-| Montando historico de posicoes...");
    
    int posFile = openArqPosicoes(from,to);
    
    HistorySelect(from,to);

    uint totalDeals=HistoryDealsTotal(); // quantidade de ofertas no historico...

    datetime time_ini=0,time_fim=0        ;
    string   time_ini_str, time_fim_str   ;
    long     tempo_posicao_em_segundos = 0;
    long     posicao_ant               = 0;
    double   posicao_profit            = 0;
    double   posicao_volume            = 0;
    int      posicao_tipo_buy_sell     = 0;
    double   posicao_draw_down         = 0;
    string   comentario                   ;

    double probabilidade_updw           = 0; //p
    double entrelacamento_coef          = 0; //e
    double entrelacamento_canal         = 0; //d
    double entrelacamento_regiao_compra = 0; //c
    double volatilidade_4_seg_media     = 0; //t
    double GMMAInst                     = 0; //i
    double GMMATrader                   = 0; //r
    
    double va                           = 0;
    double vb                           = 0;
    double vc                           = 0;
    double vd                           = 0;
    double ve                           = 0;
    

    Print(":-| Processando ofertas do historico...");

    // cabecalho do arquivo
    string linhaArq = "inicio"                  +";"+
                      "fim"                     +";"+
                      "seg"                     +";"+ // duracao da posicao em segundos
                      "id"                      +";"+ // id da posicao (eh igual em todos os deals da posicao
                      "buysell"                 +";"+ // buy eh 0, sell eh 1
                      "vol"                     +";"+ // volume da posicao
                      "pft"                     +";"+ // profit da posicao
                      "drawd"                   +";"+ // draw down da posicao
                      "comentario"              +";"+
                      "a"                       +";"+ // GMMA institucional
                      "b"                       +";"+ // GMMA trader
                      "c"                       +";"+ // volatilidade por segundo media
                      "d"                       +";"+ // probabilidade do preco subir ou descer
                      "e"                         ;   // coeficiente de entrelacamento
                    //"canal_e"                 +";"+ // canal de entrelacamento
                    //"rcmp_e"                  +";"+ // regiao de compra no canal de entrelacamento
                    //"rvnd_e"                    ;   // regiao de venda no canal de entrelacamento
    
    FileWrite(posFile,linhaArq);


    for(uint i=0;i<totalDeals;i++) {
        if( m_deal.SelectByIndex(i) ){
        
            if( m_deal.PositionId() != posicao_ant ){
            
                if( posicao_ant != 0 ){
                    time_ini_str = TimeToString(time_ini,TIME_DATE|TIME_MINUTES|TIME_SECONDS); StringReplace( time_ini_str,".","/" );
                    time_fim_str = TimeToString(time_fim,TIME_DATE|TIME_MINUTES|TIME_SECONDS); StringReplace( time_fim_str,".","/" );
                    linhaArq =                     time_ini_str            +";"+
                                                   time_fim_str            +";"+
                            IntegerToString(      (time_fim-time_ini)    ) +";"+
                            IntegerToString(       posicao_ant           ) +";"+
                            IntegerToString(       posicao_tipo_buy_sell ) +";"+
                            DoubleToString (posicao_volume             ,0) +";"+
                            DoubleToString (posicao_profit             ,0) +";"+
                            DoubleToString (posicao_draw_down          ,0) +";"+
                                            comentario                     +";"+
                            DoubleToString(va                          ,0) +";"+
                            DoubleToString(vb                          ,0) +";"+
                            DoubleToString(vc                          ,0) +";"+
                            DoubleToString(vd                          ,0) +";"+
                            DoubleToString(ve                          ,0) ;    
                        FileWrite(posFile,linhaArq);
                }
                
                // zerando e inicializando variaveis da posicao...
                time_ini              = m_deal.Time()      ;
                posicao_ant           = m_deal.PositionId();
                posicao_tipo_buy_sell = m_deal.DealType()  ;
                comentario            = m_deal.Comment()   ;
                posicao_profit        = 0                  ;
                posicao_volume        = 0                  ;
                posicao_draw_down     = 0                  ;
            
                va                           = extrair_var_independente(comentario,"a");
                vb                           = extrair_var_independente(comentario,"b");
                vc                           = extrair_var_independente(comentario,"c");
                vd                           = extrair_var_independente(comentario,"d");
                ve                           = extrair_var_independente(comentario,"e");
            }
            
            // acumulando...
          //if( m_deal.Entry() ==DEAL_ENTRY_OUT){
            if( m_deal.Profit()!=0.0           ){
                time_fim               = m_deal.Time()  ;
                posicao_volume        += m_deal.Volume();
                posicao_profit        += m_deal.Profit();
                if( posicao_profit < posicao_draw_down ) posicao_draw_down = posicao_profit;
            }
        }
        
    }// final do laco for com as transacoes do dia...

    // gravando a ultima posicao no arquivo...
    if( posicao_ant != 0 ){
        time_ini_str = TimeToString(time_ini,TIME_DATE|TIME_MINUTES|TIME_SECONDS); StringReplace( time_ini_str,".","/" );
        time_fim_str = TimeToString(time_fim,TIME_DATE|TIME_MINUTES|TIME_SECONDS); StringReplace( time_fim_str,".","/" );
        linhaArq =                     time_ini_str            +";"+
                                       time_fim_str            +";"+
                IntegerToString(      (time_fim-time_ini)    ) +";"+
                IntegerToString(       posicao_ant           ) +";"+
                IntegerToString(       posicao_tipo_buy_sell ) +";"+
                DoubleToString (posicao_volume             ,0) +";"+
                DoubleToString (posicao_profit             ,0) +";"+
                DoubleToString (posicao_draw_down          ,0) +";"+
                                comentario                     +";"+
                DoubleToString(va                          ,0) +";"+
                DoubleToString(vb                          ,0) +";"+
                DoubleToString(vc                          ,0) +";"+
                DoubleToString(vd                          ,0) +";"+
                DoubleToString(ve                          ,0) ;    
            FileWrite(posFile,linhaArq);
    }

    
    closeArqPosicoes(posFile);
}


//+------------------------------------------------------------------+
//|                                                                  |
//| Varre o historico de trades efetuados no periodo informado,      |
//| calcula as tarifas aplicadas pela B3 por transacao, mantendo o   |
//| resultado nas variaveis usadas para posterior consulta.          |
//|                                                                  |
//+------------------------------------------------------------------+
void osc_minion_trade_estatistica::refresh(datetime from, datetime to, double tarifa_teste=0){

    //Print(":-| Obtendo historico de ofertas...");
    HistorySelect(from,to);

    uint totalDeals=HistoryDealsTotal(); // quantidade de ofertas no historico...

    double volumeDia    = 0;
    double volumeDiaWDO = 0;
    double volumeDiaWIN = 0;

    double profitDia    = 0;
    double profitDiaWDO = 0;
    double profitDiaWIN = 0;
    
    // usadas no calculo do rebaixamento de saldo.
    double sldAtu          = 0;
    double maiorSldAtu     = 0;
    double rebaixamentoSld = 0;

    string symbol       = "";
    
    m_valWinsDia = 0; // valor acumulado de das vitorias no dia
    m_valLossDia = 0; // valor acumulado de perdas no dia
    m_qtdWinsDia = 0; // qtd   acumulada de das vitorias no dia
    m_qtdLossDia = 0; // qtd   acumulada de perdas no dia

    //Print(":-| Processando ofertas do historico...");
    for(uint i=0;i<totalDeals;i++) {
      //if( m_deal.SelectByIndex(i) && m_deal.Entry()  ==DEAL_ENTRY_OUT){
        if( m_deal.SelectByIndex(i) && m_deal.Profit() != 0            ){
            
            // acumulando variaveis para calculo das tarifas sobre transacoes...
            symbol     = m_deal.Symbol();
            if( ehMiniDolar(symbol) ){
                volumeDiaWDO +=  m_deal.Volume();
                profitDiaWDO +=  m_deal.Profit();
            }else if( ehMiniIndice(symbol) ){
                volumeDiaWIN +=  m_deal.Volume();
                profitDiaWIN +=  m_deal.Profit();
                
                // aplicando a tarifa de teste. Ela retira seu valor por volume nas transacoes vencedoras
                if( tarifa_teste>0 && m_deal.Profit()>=0 ) profitDiaWIN -= m_deal.Volume()*tarifa_teste; 
            }else{
                volumeDia    +=  m_deal.Volume();
                profitDia    +=  m_deal.Profit();
            }
            
            // acumulando variaveis para calculo do Payout...
            if( m_deal.Profit() > 0 ){
                m_valWinsDia += m_deal.Profit();
                m_qtdWinsDia++;
            }else{
                m_valLossDia += m_deal.Profit();
                m_qtdLossDia++; // se o resultado da transacao for zero, ainda assim considera loss, pois paga as tarifas.
            }
            
            // calculando o rebaixamento de saldo...
            sldAtu += m_deal.Profit();
            if( sldAtu > maiorSldAtu ) maiorSldAtu     = sldAtu;
            if( sldAtu < maiorSldAtu ) rebaixamentoSld = maiorSldAtu-sldAtu;

        }
    }// final do laco for com as transacoes do dia...
    
    // atualizando o rebaixamento de saldo calculado acima...
    m_rebaixamentoSld = rebaixamentoSld;
    
    // calculando o Payout...
    if( m_valLossDia != 0 ){
        m_payOut = m_valWinsDia/MathAbs(m_valLossDia);
    }else{
        m_payOut = 1; // Quando ainda nao tem perda no dia, fica em 100% por enquanto ateh eu melhorar o entendimento.
    }
    
    // calculando a probabilidade de acertos, baseado no historico de transacoes do periodo...
    calcProbAcertos();
    
    // calculando o coeficiente de Kelly, baseado no historico de transacoes do periodo...
    calcCoefKelly();
    

    m_profitDiaWDO        = profitDiaWDO  ;
    m_volumeDiaWDO        = volumeDiaWDO  ;
    m_tarifaDiaWDO        = calcTarifaWDO(m_volumeDiaWDO)*m_volumeDiaWDO;
    m_profitDiaLiquidoWDO = profitDiaWDO - m_tarifaDiaWDO;

    m_profitDiaWIN        = profitDiaWIN  ;
    m_volumeDiaWIN        = volumeDiaWIN  ;
    m_tarifaDiaWIN        = calcTarifaWIN(m_volumeDiaWIN)*m_volumeDiaWIN;
    m_profitDiaLiquidoWIN = profitDiaWIN - m_tarifaDiaWIN;

    m_profitDia        = profitDia+profitDiaWIN+profitDiaWDO  ; // ok
    m_volumeDia        = volumeDia+volumeDiaWIN+volumeDiaWDO  ; // ok
  //m_tarifaDia        = calcTarifa(m_volumeDia);
    m_tarifaDia        = 0 + m_tarifaDiaWIN + m_tarifaDiaWDO;
    m_profitDiaLiquido = m_profitDia - m_tarifaDia;



    if( m_volumeDia    > 0 ) m_profitPorContrato    = m_profitDiaLiquido   /(m_volumeDia/m_symbol.LotsStep())   ;
    if( m_volumeDiaWDO > 0 ) m_profitPorContratoWDO = m_profitDiaLiquidoWDO/m_volumeDiaWDO;
    if( m_volumeDiaWIN > 0 ) m_profitPorContratoWIN = m_profitDiaLiquidoWIN/m_volumeDiaWIN;
}

//double osc_minion_trade_estatistica::calcTarifa(const double pVolume){
//
//    if      ( StringFind(m_str_symbol,"WDO") > -1 ){
//        return calcTarifaWDO(m_volumeDia)*m_volumeDia;
//    }else if( StringFind(m_str_symbol,"WIN") > -1 ){
//        return calcTarifaWIN(m_volumeDia)*m_volumeDia;
//    }else{
//        return 0;
//    }
//}

double osc_minion_trade_estatistica::calcTarifaWDO(const double pVolume){
       if( pVolume <    21) return 1.00*m_cotacaoMoedaTarifaWDO+m_taxaLiqWDO;
       if( pVolume <   251) return 0.89*m_cotacaoMoedaTarifaWDO+m_taxaLiqWDO;
       if( pVolume <   601) return 0.62*m_cotacaoMoedaTarifaWDO+m_taxaLiqWDO;
       if( pVolume <  1001) return 0.52*m_cotacaoMoedaTarifaWDO+m_taxaLiqWDO;
       if( pVolume <  2001) return 0.49*m_cotacaoMoedaTarifaWDO+m_taxaLiqWDO;
       if( pVolume <  2501) return 0.45*m_cotacaoMoedaTarifaWDO+m_taxaLiqWDO;
       if( pVolume <  5001) return 0.42*m_cotacaoMoedaTarifaWDO+m_taxaLiqWDO;
       if( pVolume <  6001) return 0.37*m_cotacaoMoedaTarifaWDO+m_taxaLiqWDO;
       if( pVolume < 10001) return 0.35*m_cotacaoMoedaTarifaWDO+m_taxaLiqWDO;
       if( pVolume < 15001) return 0.31*m_cotacaoMoedaTarifaWDO+m_taxaLiqWDO;
       if( pVolume < 20001) return 0.30*m_cotacaoMoedaTarifaWDO+m_taxaLiqWDO;
       if( pVolume < 25001) return 0.28*m_cotacaoMoedaTarifaWDO+m_taxaLiqWDO;
       if( pVolume < 35001) return 0.26*m_cotacaoMoedaTarifaWDO+m_taxaLiqWDO;
       if( pVolume < 45001) return 0.25*m_cotacaoMoedaTarifaWDO+m_taxaLiqWDO;
       if( pVolume < 60001) return 0.23*m_cotacaoMoedaTarifaWDO+m_taxaLiqWDO;
       if( pVolume < 80001) return 0.22*m_cotacaoMoedaTarifaWDO+m_taxaLiqWDO;
                            return 0.20*m_cotacaoMoedaTarifaWDO+m_taxaLiqWDO;
}

double osc_minion_trade_estatistica::calcTarifaWIN(const double pVolume){
      
       if( pVolume <    21) return 1.48+m_taxaLiqWIN;
       if( pVolume <   251) return 1.11+m_taxaLiqWIN;
       if( pVolume <   751) return 0.77+m_taxaLiqWIN;
       if( pVolume <  2501) return 0.48+m_taxaLiqWIN;
       if( pVolume <  7501) return 0.44+m_taxaLiqWIN;
       if( pVolume < 17501) return 0.33+m_taxaLiqWIN;
       if( pVolume < 37501) return 0.29+m_taxaLiqWIN;
       if( pVolume < 75001) return 0.26+m_taxaLiqWIN;
                            return 0.24+m_taxaLiqWIN;
}

//+------------------------------------------------------------------+
//|                                                                  |
//| Calcula o Payout baseado no historico de transacoes do dia.      |
//|                                                                  |
//+------------------------------------------------------------------+
void osc_minion_trade_estatistica::calcPayOut(){
    // calculando o Payout...
    if( m_valLossDia != 0 ){
        m_payOut = m_valWinsDia/MathAbs(m_valLossDia);
    }else{
        m_payOut = 1; // Quando ainda nao tem perda no dia, fica em 100% por enquanto ateh eu melhorar o entendimento.
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//| Calcula a probabilidade de acertos, baseado no historico de      |
//| transacoes do periodo.                                           |
//|                                                                  |
//+------------------------------------------------------------------+
void osc_minion_trade_estatistica::calcProbAcertos(){
    if( m_qtdWinsDia>0 ){
        m_probAcerto = m_qtdWinsDia / (m_qtdWinsDia+m_qtdLossDia);
    }else{
        m_probAcerto = 0;
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//| Calcula o coeficiente de Kelly.                                  |
//|                                                                  |
//| Definicao: Percentual maximo de capital a ser alocado a cada     |
//|            trade.                                                |
//|                                                                  |
//| Forrmula:                                                        |
//| K = ( P.B - (1-P) ) / B                                          |
//|                                                                  |
//| sendo:                                                           |
//| K = Coefiente de Kelly.                                          |
//| P = Probabilidade de acerto.                                     |
//| B = Payout.                                                      |
//|                                                                  |
//+------------------------------------------------------------------+
void osc_minion_trade_estatistica::calcCoefKelly(){

   if( m_payOut != 0 ){
       m_coefKelly = ( (m_probAcerto*m_payOut) - (1-m_probAcerto) ) / m_payOut;
   }else{
       m_coefKelly = 0;
   }
}