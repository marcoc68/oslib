//+------------------------------------------------------------------+
//|                                              osc-vol-profile.mqh |
//|                               Copyright 2022,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//+------------------------------------------------------------------+
#property copyright "2022, Oficina de Software."
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+---------------------------------------------------------------------+
//| Volume profile.                                                     |
//| Estrutura para acumulacao de volume profile em uma janela de tempo  |
//| ou de volume.                                                       |
//+---------------------------------------------------------------------+

#include <Object.mqh>
#include <Generic\SortedMap.mqh>
#include <Generic\Queue.mqh>
#include <oslib/osc/data/osc-vol-profile-item.mqh>
#include <oslib/osc/data/osc-vol-profile-map-itens.mqh>
#include <oslib/osc/data/osc-vol-profile-fila-itens.mqh>
#include <oslib/osc/data/osc-vol-profile-vprof.mqh>

class osc_vol_profile: public CObject{
private:
    Vprof m_vprof;
    
    void inicializa_volume_vprof(){
        double upre = m_vprof.upre;
        m_vprof.initialize();
        m_vprof.upre = upre;
    }

public:
    volume_profile_map_itens  m_map_itens ; // HashMap com itens de precos e volumes
    volume_profile_fila_itens m_fila_itens; // Fila    com itens de precos e volume

    // adicionando volume a um preco. Se o preco existir, adiciona o volume, senao cria novo Item.
    bool   add(double price, double vol, long time=0){ 
        // atualizando o ultimo preco...
        m_vprof.upre = price;
        
        // adicionando a fila de itens...
        m_fila_itens.Add()
        return m_map_itens.add(price, vol, time); 
    }

    // subtraindo volume de um preco. Se o volume do preco zerar, adiciona o volume, senao cria novo Item.
    bool   sub(double price, double vol ){ return m_map_itens.sub(price, vol); }
    
    // 
    string toString(){ return m_map_itens.toString(m_vprof); }
    
    // 
    void calcular_area_de_valor(){
    
        double chave[]; volume_profile_item* item[];
        int   qtd = m_map_itens.CopyTo(chave,item);
        int   imax = qtd-1;
        
        Print(__FUNCTION__, " Calculando VA (value area) em ", qtd, " itens..." );
        
        // determinando o preco com o maior volume...
        inicializa_volume_vprof();
        for(int i=0; i<qtd; i++){
            
            // maior volume e preco com maior volume ppoc
            if(item[i].vol > m_vprof.vpoc){ 
                m_vprof.vpoc=item[i].vol; 
                m_vprof.ppoc=item[i].price;
                m_vprof.ipoc=     i       ;
            }
            
            // volume total
            m_vprof.vtot += item[i].vol;
            
            // maior e menor precos...
            if(item[i].price > m_vprof.pmax)                       m_vprof.pmax = item[i].price;
            if(item[i].price < m_vprof.pmin || m_vprof.pmin == 0 ) m_vprof.pmin = item[i].price;
        }
        
        // 68% do volume total
        m_vprof.vtot = ( m_vprof.vtot * 68.0 ) / 100.0;
        
        if( m_vprof.ipoc + 1  > imax ){
            m_vprof.pvah = item[ m_vprof.ipoc + 0 ].price;
            m_vprof.vvah = 0                             ;
            m_vprof.ivah =       m_vprof.ipoc + 0        ;
        }else if( m_vprof.ipoc + 2  > imax ){
            m_vprof.pvah = item[ m_vprof.ipoc + 1 ].price;
            m_vprof.vvah = item[ m_vprof.ipoc + 1 ].vol  ; 
            m_vprof.ivah =       m_vprof.ipoc + 1        ;
        }else{
            m_vprof.pvah = item[ m_vprof.ipoc + 2 ].price;
            m_vprof.vvah = item[ m_vprof.ipoc + 1 ].vol + item[ m_vprof.ipoc + 2 ].vol  ; 
            m_vprof.ivah =       m_vprof.ipoc + 2        ;
        }

        if( m_vprof.ipoc - 1  < 0 ){
            m_vprof.pval = item[ m_vprof.ipoc - 0 ].price;
            m_vprof.vval = 0                             ;
            m_vprof.ival =       m_vprof.ipoc - 0        ;
        }else if( m_vprof.ipoc - 2  < 0 ){
            m_vprof.pval = item[ m_vprof.ipoc - 1 ].price;
            m_vprof.vval = item[ m_vprof.ipoc - 1 ].vol  ;
            m_vprof.ival =       m_vprof.ipoc - 1        ;
        }else{
            m_vprof.pval = item[ m_vprof.ipoc - 2 ].price;
            m_vprof.vval = item[ m_vprof.ipoc - 1 ].vol + item[ m_vprof.ipoc - 2 ].vol  ; 
            m_vprof.ival =       m_vprof.ipoc - 2        ;
        }
        m_vprof.toString();
        
        double v = m_vprof.vpoc;
        while( v < m_vprof.vtot || (m_vprof.vvah==0 && m_vprof.vval==0) ){

            if( m_vprof.vvah > m_vprof.vval ){

                v += m_vprof.vvah;
                if( m_vprof.ivah + 1  > imax ){
                    m_vprof.pvah = item[ m_vprof.ivah + 0 ].price;
                    m_vprof.vvah = 0                             ;
                    m_vprof.ivah =       m_vprof.ivah + 0        ;
                }else if( m_vprof.ivah + 2  > imax ){
                    m_vprof.pvah = item[ m_vprof.ivah + 1 ].price;
                    m_vprof.vvah = item[ m_vprof.ivah + 1 ].vol  ; 
                    m_vprof.ivah =       m_vprof.ivah + 1        ;
                }else{
                    m_vprof.pvah = item[ m_vprof.ivah + 2 ].price;
                    m_vprof.vvah = item[ m_vprof.ivah + 1 ].vol + item[ m_vprof.ivah + 2 ].vol  ; 
                    m_vprof.ivah =       m_vprof.ivah + 2        ;
                }
            }else{
                v += m_vprof.vval;
                if( m_vprof.ival - 1  < 0 ){
                    m_vprof.pval = item[ m_vprof.ival - 0 ].price;
                    m_vprof.vval = 0                             ;
                    m_vprof.ival =       m_vprof.ival - 0        ;
                }else if( m_vprof.ival - 2  < 0 ){
                    m_vprof.pval = item[ m_vprof.ival - 1 ].price;
                    m_vprof.vval = item[ m_vprof.ival - 1 ].vol  ;
                    m_vprof.ival =       m_vprof.ival - 1        ;
                }else{
                    m_vprof.pval = item[ m_vprof.ival - 2 ].price;
                    m_vprof.vval = item[ m_vprof.ival - 1 ].vol + item[ m_vprof.ival - 2 ].vol  ; 
                    m_vprof.ival =       m_vprof.ival - 2        ;
                }
            }
            //Print( m_vprof.toString(), " V70%=",m_vprof.vtot, " VCALC=", v );
        }
    }
    
};

