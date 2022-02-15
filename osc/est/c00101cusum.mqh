//+------------------------------------------------------------------+
//|                                                  c00101cusum.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+---------------------------------------------------------------------+
//| Implementacoes CUSUM - Cumulative Sum.                              |
//+---------------------------------------------------------------------+
#property description "Soma cumulativa."

#include <Object.mqh>
#include <oslib/osc/est/CStat.mqh>
#include <oslib/osc/osc-media.mqh>


class c00101cusum : public CObject{
private:
    double    m_c_mais , m_c_mais_ant ; // acumulacao acima da media
    double    m_c_menos, m_c_menos_ant; // acumulacao abaixo da media
    double    m_k                     ; // treshould; quantidade de desvios padrao alem da qual devera acumular X;
    double    m_h                     ; // strike   ; quantidade de desvios padrao alem do qual deverah disparar o alerta;
  //int       m_intervalo_acum        ; // intervalo de acumulacao em segundos;
    osc_media m_vet_x                 ; // vetor de ocorrencias para as quais a soma acumulada estah sendo calculada;
    osc_media m_vet_cmais             ; // vetor de ocorrencias de C+; usado pra saber a tendencia de C+;
    osc_media m_vet_cmenos            ; // vetor de ocorrencias de C-; usado pra saber a tendencia de C-
    double    m_dp                    ; // desvio padrao das ocorrencias de x.


    void calc_cusum(const double xi){
    
       // definindo o desvio padrao do vetor de ocorrencias e usando em seguida para determinar o treshould (K)...
       m_dp     = sqrt( m_vet_x.getVar() );
       double K = m_k * m_dp;   // treshould em unidades de desvio padrao.
    
        // acumulando C+ e C- ...
        m_c_mais  = MathMax(0,  xi - ( m_vet_x.getMed() + K ) + m_c_mais_ant  );
        m_c_menos = MathMax(0, -xi + ( m_vet_x.getMed() - K ) + m_c_menos_ant );
        
        // salvando para uso no proximo calculo...
        m_c_mais_ant  = m_c_mais ;
        m_c_menos_ant = m_c_menos;

        // adicionando  C+ e C- aos vetores. serve para calcular a tendencia de C+ e C- ...
        m_vet_cmais .add(m_c_mais ); //m_vet_cmais.print("cmais");
        m_vet_cmenos.add(m_c_menos); //m_vet_cmais.print("cmenos");
        
        // calculando a direcao da tendencia de C+ e C- ...
        //m_vet_cmais .regLinFit();
        //m_vet_cmenos.regLinFit();
    }

protected:
public:
    c00101cusum(void): m_c_mais       (0),
                       m_c_mais_ant   (0),
                       m_c_menos      (0),
                       m_c_menos_ant  (0){}

    //
    // Inicializa as variaveis e o vetor para o calculo da soma acumulada;
    //
    //double    k                     treshould; quantidade de desvios padrao alem da qual devera acumular X;
    //double    h                     strike   ; quantidade de desvios padrao alem do qual deverah disparar o alerta;
    //int       size_hist             tamanho do historico usado para calcular a media;
    //int       intervalo_acum        intervalo de acumulacao em segundos;
    //
    void initialize(double k=1, double h=5, int size_hist=72, int intervalo_acum=0){
    	m_k         = k;
        m_h         = h;
        m_vet_x     .initialize(size_hist,intervalo_acum);
        m_vet_cmais .initialize(size_hist,intervalo_acum);
        m_vet_cmenos.initialize(size_hist,intervalo_acum);
        
    }

    // adiciona uma ocorrencia (xi)...
    void add(double xi){
    
        // adicionando ao vetor de ocorrencias e jah deixa a variancia calculada (segundo parametro igual a true)...
        m_vet_x.add(xi,true); //m_vet_x.print("xi");

        // calculando C+ e C- ...
        calc_cusum(xi);
        //print();
    }

    // adiciona uma ocorrencia (xi) com timeframe. Como usa timeframe, deve informar a hora da ocorrencia (ti).
    //Se a adicao for antes de completar o timeframe, serah desprezada.
    void add(double xi, const datetime ti){
        
        // adicionando ao vetor de ocorrencias e jah deixa a variancia calculada (terceiro parametro igual a true)...
        // se jah adicionaou no timeframe parametrizado, nao adiciona e retorna false. Neste caso, nao acumulamos.
        if( !m_vet_x.add(xi,ti,true) ){ return;}
        
        // calculando C+ e C- ...
        calc_cusum(xi);
    }
    
    // resultado da ultima acumulacao...
    double getCmais (){return m_c_mais ;}
    double getCmenos(){return m_c_menos;}
    
    // coeficientes lineares dos vetores de acumulacao. servem para saber a tendencia do C+ e C- ...
    double get_slope_cmais (){ return m_vet_cmais .regLinGetSlope(); }
    double get_slope_cmenos(){ return m_vet_cmenos.regLinGetSlope(); }
    
    // print da situacao atual...
    void print(){
        Print(__FUNCTION__,      " xi:", m_vet_x.getXi(),
                              " cmais:", m_c_mais       , 
                             " cmenos:", m_c_menos      , 
                          " media(xi):", m_vet_x.getMed()
                          
                          );
    }

};
