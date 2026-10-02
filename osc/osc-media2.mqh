//+------------------------------------------------------------------+
//|                                                    osc-media.mqh |
//|                             Copyright 2020, Oficina de Software. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2020, Oficina de Software."
#property link      "http://www.os.net"

#include <oslib/osc/est/CStat.mqh>
#include <Math/Stat/Math.mqh>
#include <oslib/osc/data/osc-vetor-circular-double.mqh>


// calculo de media simples baseada em quantidade fixa de elementos. A medida que o vetor de valores enche, despreza o valor mais antigo,
// adiciona o mais novo e recalcula a media.
class osc_media{

private:
    uint   m_ind   ;
    double m_tot   ;
    uint   m_len   ;
    uint   m_len_calc;
    double m_mean  ; // media: recalcula sempre que executa o metodo add...
    double m_var   ; // variancia: recalcula a pedido com a chamada ao metodo calVar.
    VetorCircularDouble m_vet;

    uint     m_tf        ; // time_frame
    datetime m_dt_ult_add; // data da ultima adicao ao vetor
    CStat m_stat   ;   
public:
    
    //----------------------------------------------------------------------------------------------------
    // inicializa todas as variaveis usadas no calculo da media. Dimensiona o vetor para len( recebido por parametro).
    // Ate que se adicione o len-ezimo valor ao calculo da media, ela serah influenciada por zeros que sao preenchidos no
    // vetor de valores da media. 
    //
    // in len: tamanho do vetor de media
    // in time_frame: se informada a data do item sendo adicionado,
    //    não adiciona ateh que se passe time_frame segundos desde a última adicao
    //----------------------------------------------------------------------------------------------------

    bool initialize(int len, ENUM_TIMEFRAMES TIME_FRAME=PERIOD_M1){
        return initialize(len, PeriodSeconds(TIME_FRAME));
    }

    bool initialize(int len, uint time_frame=0){
        if( len < 2 ) return false;
        m_len  = len;
        m_len_calc = 0;
        m_tot  = 0  ;
        m_mean = 0  ;
        m_var  = 0  ;
        m_vet = VetorCircularDouble(len);

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
    bool add(const double val, datetime dt, bool calc_var=false){
         //Print("m_len:",m_len," ind:",m_ind," time:",time," val:",val," m_mean:",m_mean);
         // se nao passou o time_frame minimo para acumular, nao faz nada e retorna falso.
         if( (dt - m_dt_ult_add) < m_tf ) return false;
         
         // atualizando a data da ultima adicao...
         m_dt_ult_add = dt;
         
         // adicionando...
         add(val);
         if(calc_var){ calcVar(); }
         return true;
    }
    
    //----------------------------------------------------------------------------------------------------
    // Adiciona um item a media, retira o mais antigo (se for maior que o tamanho do vetor de medias) e retorna o valor da media.
    //----------------------------------------------------------------------------------------------------
    double add(const double val, bool calc_var=false){
    
        m_tot += val; // adicionando o valor atual a media;
        if(++m_len_calc > m_len){
            m_tot -= m_vet.at(0); // retirando o valor do elemento mais antigo do calculo da media
            m_len_calc = m_len;   // ajustando o tamanho calculado para o tamanho máximo
        }
        m_vet.add(val)      ; // e adicionando o novo valor

        m_mean = ( m_tot/(double)m_len_calc ); // recalculando  a media
        if(calc_var){ calcVar(); } // recalcula a variancia se solicitado
        return m_mean;
    }
    
    //----------------------------------------------------------------------------------------------------
    // Muda um item no vetor de médias, e retorna o novo valor da media.
    //----------------------------------------------------------------------------------------------------
    double set(uint ind, const double val, bool calc_var=false){

        if( m_len_calc < m_len && ind >= m_len_calc ) return m_mean; // nao faz nada se o indice for maior que a quantidade de elementos ja adicionados.

        m_tot += val          ; // adicionando o valor atual a media/;
        m_tot -= m_vet.at(ind); // retirando o valor do elemento que serah substituido
        m_vet.set(ind, val)   ; // e colocando o novo valor

        m_mean = ( m_tot/(double)m_len_calc ); // recalculando  a media
        if(calc_var){ calcVar(); }             // recalcula a variancia se solicitado
        return m_mean;
    }

    // muda o valor do ultimo elemento do vetor de medias, e retorna o novo valor da media.
    double setLast(const double val, bool calc_var=false){
        return set(m_len_calc-1, val, calc_var);
    }

    // metodo print util para debug;
    void print(string nome=""){
        Print(__FUNCTION__, " :-| Logando vetor ", nome, ": media:", DoubleToString(m_mean, 4), " var:", DoubleToString(getVar(), 4), " ind=", m_ind, " len_calc=",m_len_calc, " tot=", DoubleToString(m_tot, 4) );
        Print(m_vet.toString());
    }

    //----------------------------------------------------------------------------------------------------
    // Calcula e retorna a variancia sobre o conjunto atual.
    //----------------------------------------------------------------------------------------------------
    double calcVar(){
        m_var=0.0;

        if(m_len_calc >= m_len){
            m_var = m_vet.calcVar();
            return m_var;
        }

        if( m_len_calc < 2 ) return m_var;

        for(uint i=0; i<m_vet.size(); i++) m_var+=MathPow(m_vet.at(i)-m_mean,2);
        m_var=m_var/(m_vet.size()-1);
        return m_var;
    }
    
    //------------------------
    double m_vetTendencia[];
    double m_slope; // coeficiente linear dos dados do vetor.
    double regLinGetSlope(){return m_slope;}
    //------------------------
    double regLinFit(){
        if(m_len_calc < 2){
            return 0;
        }else{
            ArrayResize(m_vetTendencia,(int)m_vet.size());
            for(int i=0; i<(int)m_vet.size(); i++){m_vetTendencia[i] = m_vet.at(i);}
        }
    
        double b0,b1,r2;
        string msg;
        double x[];
        ArrayResize(x, m_len_calc);
        MathSequence(0,m_len_calc,1,x);
        m_stat.calcRegLin(m_vetTendencia, x, b0, b1, r2, msg);
        
        m_slope = b1;
        return b1;    
    }
    //------------------------
    
    // Coeficiente de correlacao de pearson
    double calcCoefCorr(vector <double> &vet2){
        vector vet1 = m_vet.toVector(); 
        return vet1.CorrCoef(vet2); 
    }
    
    double calcCoefCorr(osc_media &vetor_de_media){
        vector vet2 = vetor_de_media.toVector();
        return calcCoefCorr(vet2); 
    }

    // Teste de cointegração de Engle-Granger / ADF
    bool ehCointegradoCom(vector <double> &vet2){
        vector vet1 = m_vet.toVector();
        return CStat::parEhCointegrado(vet1, vet2);
    }

    bool ehCointegradoCom(osc_media &vetor_de_media){
        vector vet2 = vetor_de_media.toVector();
        return ehCointegradoCom(vet2);
    }
    
    vector toVector(){ return m_vet.toVector();}
    
    //------------------------
    double getMed(){ return m_mean; } // retorna a ultima media calculada
    double getVar(){ return m_var ; } // retorna a ultima variancia calculada
};
