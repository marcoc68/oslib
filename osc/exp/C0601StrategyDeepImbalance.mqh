﻿//+------------------------------------------------------------------+
//|                                    C0601StrategyDeepImbalance.mqh|
//|                               Copyright 2021,oficina de software.|
//|                                https://www.metaquotes.net/marcoc.|
//|                                                                  |
//| CLASSE A ESTRATEGIA HFT DE DESBALANCEAMANETO DO BOOK.            |
//|                                                                  |
//|                                                                  |
//|                                                                  --------------------------------------------|
//|                                                                                                              |
//+--------------------------------------------------------------------------------------------------------------+
#property copyright "2021, Oficina de Software."
#property link      "httpS://www.os.net"

#include <oslib/osc/exp/C0600Strategy.mqh>
#include <oslib/osc/exp/C0004GerentePosicao.mqh>
#include <oslib/osc/data/osc-book.mqh>


class C0601StrategyDeepImbalance: public C0600Strategy{
private:
    //string& symb_str, 
    osc_book*           m_book          ; 
    C004GerentePosicao* m_gerPos        ;
    int                 m_tamanho_rajada;
    int                 m_lag_rajada    ;
    int                 m_book_queu_in  ; // fila do book onde considera-se que a 
                                          // ordem limitada terah execucao instantanea.
                                          // A titulo de exemplo, estou testando a fila 1 para win
                                          // e a fila 2 para wdo.
protected:
public:
    void inicializar(
                   //string&             symb_str      , 
                     osc_book*           book          , 
                   //MqlTick&            tick          , 
                     C004GerentePosicao* gerPos        , 
                   //osc_minion_trade&   trade         , 
                     int                 tamanho_rajada, 
                     int                 lag_rajada    ,
                     int                 book_queu_in
                     ){
        m_book           = book          ;
        m_gerPos         = gerPos        ;
        m_tamanho_rajada = tamanho_rajada;
        m_lag_rajada     = lag_rajada    ;
        m_book_queu_in   = book_queu_in  ;
    }


    // Abre posicao se houver desbalanceamento de ofertas nas primeiras filas do book...
    // Esta opcao nao se importa se a volatilidade estiver alta
    // HFT_DESBALANC_BOOK
    void gerenciarPosicao(){
    
        if( m_gerPos.positioned() ){
            //1. se tiver ordens de saida no lado espesso do book, feche a posicao...
         
            // aqui, as ordens de saida estao no lado ralo do book, entao saio pra respeitar 
            // as ordens de saida colocadas pelo firenortesul (que estao no lado ralo do book)
            if( m_gerPos.getSignal() > 0 && m_book.getDirecaoImbalance() > 0 ) return;
            if( m_gerPos.getSignal() < 0 && m_book.getDirecaoImbalance() < 0 ) return;
            
    //      // Se chegou ateh aqui e o deep imbalance estah direcional, 
    //      // eh porque as ordens de saida estao no lado espesso do book.
    //      // Entao fechamos a posicao.
    //      if( m_book.getDirecaoImbalance() != 0 ){
    //          Print( __FUNCTION__, ":", m_gerPos.getAnimal() ,":", m_book.getDirecaoImbalance(),": fechando posicao..." );
    //          m_gerPos.fecharPosicao();
    //      }


            // 2. cancelando ordens de entrada no lado ralo do book mesmo que eu esteja posicionado... 
            //    Por enquanto cancela win assim que chega na fila 2 porque a fila 1 concorre com robos muito rapidos...
            //    wdo estah cancelando na fila 1 mesmo... 
            if( m_gerPos.getSignal() < 0 && m_book.getDirecaoImbalance() > 0 ) m_gerPos.cancelarOrdensMenoresOuIguaisA( ORDER_TYPE_SELL_LIMIT, m_book.getAsk(m_book_queu_in) );
            if( m_gerPos.getSignal() > 0 && m_book.getDirecaoImbalance() < 0 ) m_gerPos.cancelarOrdensMaioresOuIguaisA( ORDER_TYPE_BUY_LIMIT , m_book.getBid(m_book_queu_in) );

        
        }else{
            // 1. cancelando ordens de entrada no lado ralo do book... 
            //    Por enquanto cancela win assim que chega na fila 2 porque a fila 1 concorre com robos muito rapidos...
            //    wdo estah cancelando na fila 1 mesmo... 
            if( m_book.getDirecaoImbalance() > 0 ) m_gerPos.cancelarOrdensMenoresOuIguaisA( ORDER_TYPE_SELL_LIMIT, m_book.getAsk(m_book_queu_in) );
            if( m_book.getDirecaoImbalance() < 0 ) m_gerPos.cancelarOrdensMaioresOuIguaisA( ORDER_TYPE_BUY_LIMIT , m_book.getBid(m_book_queu_in) );
            
            // 2. colocando ordens de entrada longe do preco a fim de chegarem com prioridade na fila 1...
            m_gerPos.preencherOrdensLimitadasDeCompraAbaixoComLag2(m_book.getBid(),m_tamanho_rajada,m_apmb_buy,m_lag_rajada);
            m_gerPos.preencherOrdensLimitadasDeVendaAcimaComLag2  (m_book.getAsk(),m_tamanho_rajada,m_apmb_sel,m_lag_rajada);
        }

        // 2. colocando ordens de entrada longe do preco a fim de chegarem com prioridade na fila 1...
        //m_gerPos.preencherOrdensLimitadasDeCompraAbaixoComLag2(m_book.getBid(),m_tamanho_rajada,m_apmb_buy,m_lag_rajada);
        //m_gerPos.preencherOrdensLimitadasDeVendaAcimaComLag2  (m_book.getAsk(),m_tamanho_rajada,m_apmb_sel,m_lag_rajada);
        
    }// fim gerenciarPosicao

};


