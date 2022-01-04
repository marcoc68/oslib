//+------------------------------------------------------------------+
//|                                                    osc-media.mqh |
//|                             Copyright 2020, Oficina de Software. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2020, Oficina de Software."
#property link      "http://www.os.net"

#include <oslib/osc/est/CStat.mqh>
#include <Math/Stat/Math.mqh>

// calculo de media simples baseada em quantidade fixa de elementos. A medida que o vetor de valores enche, despreza o valor mais antigo,
// adiciona o mais novo e reclacula a media.
class osc_media{

private:
    int    m_ind   ;
    double m_tot   ;
    int    m_len   ;
    int    m_len_calc;
    double m_mean  ; // media: recalcula sempre que executa o metodo add...
    double m_var   ; // variancia: recalcula a pedido com a chamada ao medtodo calVar.
    double m_vet[] ;

    uint     m_tf        ; // time_frame
    datetime m_dt_ult_add; // data da ultima adiciao ao vetor
    CStat m_stat   ;   
public:
    
    //----------------------------------------------------------------------------------------------------
    // inicializa todas as variaveis usadas no calculo da media. Dimensiona o vetor para len( recebido por parametro).
    // Ateh que se adicione o len-ezimo valor ao calculo da media, ela serah influenciada por zeros que sao preenchidos no
    // vetor de valores da media. 
    //
    // in len: tamanho do vetor de media
    // in time_frame: se informada a data do item sendo adicionado,
    //    não adiciona ateh que se passe time_frame segundos desde a última adicao
    //----------------------------------------------------------------------------------------------------
    bool initialize(int len, uint time_frame=0){
        if( len < 2 ) return false;
        m_len  = len;
        m_len_calc = 0;
        m_ind  = 0  ;
        m_tot  = 0  ;
        m_mean = 0  ;
        m_var  = 0  ;
        ArrayResize(m_vet,len);
        ArrayFill(m_vet,0,len,0);

        //----------------------
        m_tf         = time_frame;
        m_dt_ult_add = 0;
        //----------------------
        
        return true;
    }

    //----------------------------------------------------------------------------------------------------
    // Adiciona um item a media, retira o mais antigo (se for maior que o tamanho do vetor de medias) e retorna o valor da media.
    // Se nao tiver passado o time_frame informado na inicializacao, nao adiciona e retorna falso.
    //----------------------------------------------------------------------------------------------------
    bool add(const double val, datetime time, bool calc_var=false){
         //Print("m_len:",m_len," ind:",m_ind," time:",time," val:",val," m_mean:",m_mean);
         // se nao passou o time_frame minimo para acumular, nao faz nada e retorna falso.
         if( (time - m_dt_ult_add) < m_tf ) return false;
         
         // atualizando a data da ultima adicao...
         m_dt_ult_add = time;
         
         // adicionando...
         add(val);
         
         if(calc_var){ calcVar(); }
         
         return true;
    }
    
    //----------------------------------------------------------------------------------------------------
    // Adiciona um item a media, retira o mais antigo (se for maior que o tamanho do vetor de medias) e retorna o valor da media.
    //----------------------------------------------------------------------------------------------------
    double add(const double val, bool calc_var=false){
    
        if( m_len_calc < m_len ) m_len_calc++;
         
        m_tot       += val         ; // adicionando o valor atual a media/;
        m_tot       -= m_vet[m_ind]; // retirando o que estava na posicao atual do vetor
        m_vet[m_ind] = val         ; // e colocando o ultimo valor calculado
         
        if( ++m_ind == m_len_calc ){ m_ind=0; }   // atualizando o indice
         
        m_mean = ( m_tot/(double)m_len_calc );       
        
        if(calc_var){ calcVar(); }

        return m_mean;
    }

    //----------------------------------------------------------------------------------------------------
    // Calcula e retorna a variancia sobre o conjunto atual.
    //----------------------------------------------------------------------------------------------------
    double calcVar(bool full=false){
        m_var=0.0;
        if( m_len_calc < 2 ) return m_var;
        
        for(int i=0; i<m_len_calc; i++) m_var+=MathPow(m_vet[i]-m_mean,2);
        m_var=m_var/(m_len_calc-1);
        
        if(full) return getVarFull();
        return getVar(); 
    }
    
    
    //------------------------
    double m_vetTendencia[];
    double m_slope; // coeficiente linear dos dados do vetor.
    double regLinGetSlope(){return m_slope;}
    //------------------------
    double regLinFit(){
        if(m_len_calc < m_len){
            return 0;
            //ArrayResize(m_vetTendencia,m_len_calc);
            //ArrayCopy  (m_vetTendencia,m_vet,0,0,m_len_calc);
          //MathSequence(0,m_len_calc,1,x); 
        }else{
          //ArrayResize(vetTendencia,m_len);
            ArrayCopy  (m_vetTendencia,m_vet,0            ,m_ind,WHOLE_ARRAY);
            ArrayCopy  (m_vetTendencia,m_vet,(m_len-m_ind),0    ,m_ind      );
          //MathSequence(0,m_len,1,x); 
        }
    
        double b0,b1,r2;
        string msg;
        double x[];
        ArrayResize(x, m_len);
        MathSequence(0,m_len,1,x); 
        m_stat.calcRegLin(m_vetTendencia, x, b0, b1, r2, msg);
        
        m_slope = b1;
        return b1;    
    }
    //------------------------
    
    double getMed(){ return m_mean; } // retorna a ultima media calculada
    double getVar(){ return m_var ; } // retorna a ultima variancia calculada
    double getVarFull(){ 
        if(m_len_calc < m_len) return 0;
        return m_var;
    } // retorna a ultima variancia calculada somente se o buffer jah encheu

};
