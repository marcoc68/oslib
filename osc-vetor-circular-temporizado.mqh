//+------------------------------------------------------------------+
//|                               osc-vetor-circular-temporizado.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+------------------------------------------------------------------------------+
//| Extensao da classe osc_vetor_circular visando rapido calculo de medias.      |
//| Acrescenta informacao de tempo decorrido entre as entradas iniciais e finais.|
//+------------------------------------------------------------------------------+
#property description "Extensao da classe osc_vetor_circular visando rapido calculo de medias."
#property description "Acrescenta informacao de tempo decorrido entre as entradas iniciais e finais."

#include <oslib/osc-vetor-circular-com-peso.mqh>
//#include <../Shared Projects/oslib/osc-vetor-circular.mqh>

class osc_vetor_circular_temporizado : public osc_vetor_circular_com_peso {
private:
   long m_vet[];
 //long m_time_decorrido; //uso pra calcular o tempo decorrido, em segundos desde a entrada mais antiga ateh a entrada atual.
   int  m_len;
   int  m_ind;
   osc_vetor_circular m_vetTimeDecorrido;
protected:

public:
   osc_vetor_circular_temporizado(){ initialize(OSC_VETOR_CIRCULAR_LEN_PADRAO); }

   int initialize(int len);//cria o vetor circular com o tamanho informado; retorna o tamanho do vetor criado.
   void add( datetime time, double val, double peso=1.0);//substitui a posicao mais antiga do vetor pelo valor recebido;
                                                         //alem disso preenche o vetor circular de tempo em que ocorrem
                                                         //os eventos possibilitando informar o tempo decorrido entre a
                                                         //entrada do elemento mais antigo e mais novo do vetor.

   long   getTempoDecorrido        (){return (long)m_vetTimeDecorrido.getDistancia();} // tempo, em segundos, desde a entrada mais antiga ateh a atual;
   long   getTempoDecorridoEmMinuto(){return getTempoDecorrido        ()/60         ;} // tempo, em minutos , desde a entrada mais antiga ateh a atual;
   long   getTempoDecorridoEmHora  (){return getTempoDecorridoEmMinuto()/60         ;} // tempo, em horas   , desde a entrada mais antiga ateh a atual;
   long   getTempoDecorridoEmDia   (){return getTempoDecorridoEmHora  ()/24         ;} // tempo, em dias    , desde a entrada mais antiga ateh a atual;
 //long   getTempoDecorrido        (){return m_time_decorrido                       ;} // tempo, em segundos, desde a entrada mais antiga ateh a atual;
   long   getTempoDecorridoMedio   (){return (long)m_vetTimeDecorrido.getMedia()    ;} // tempo medio, em segundos, desde a entrada mais antiga ateh a atual;
   double getCoefLinear            (){return getTempoDecorrido()!=0?getDistancia()/getTempoDecorrido():0 ;} // inclinacao da reta de variacao de valores ao longo do tempo;
//------------------------------------------------------
};

//+---------------------------------------------------------------------------------------+
//| inicializa vetor circular com vetor de tamanho len contendo 0.0 em todos os elementos.|
//+---------------------------------------------------------------------------------------+
int osc_vetor_circular_temporizado::initialize(int len){

    if( osc_vetor_circular_com_peso::initialize(len) == 0 ){ return 0; } // inicializando a superclasse...
    if(len < 1                                            ){ return 0; } // previnindo array com tamanho invalido...

    m_ind            = 0;
  //m_time_decorrido = 0;
    m_len            = ArrayResize(m_vet,len); // prevenindo para o caso do algoritimo Arrayresize
                                               // aumente mais que tamanho solicitado. Entao colocamos
                                               // o novo tamanho do vetor na variavem m_len.
    ArrayFill(m_vet,0,m_len ,0);
    return m_vetTimeDecorrido.initialize(len); // inicializando a vetor circular que calcularah o tempo decorrido medio;
}

//+-----------------------------------------------------------------------+
//| 0. adiciona o valor normal e depois o tempo.                          |
//| 1. substitui a posicao mais antiga do vetor pelo valor recebido.      |
//| 2. m_indtime fica apontado para o proximo valor que serah adionado ao |
//|    vetor circular.                                                    |
//| 3. Recalcula o tempo decorrido entre a entrada mais antiga e a atual. |
//+-----------------------------------------------------------------------+
void osc_vetor_circular_temporizado::add(datetime time, double val, double peso=1.0){
    if(peso==0) peso = 1;
    osc_vetor_circular_com_peso::add(val,peso);
  //m_time_decorrido = time - m_vet[m_ind]  ; // tempo decorrido, em segundos, entre a entrada mais antiga e a atual;
  //m_vetTimeDecorrido.add(m_time_decorrido); // vetor circular onde cada entrada eh o tempo, em segundos, entre a entrada mais antiga e a atual;
    m_vetTimeDecorrido.add(time)            ; // vetor circular onde cada entrada eh a hora da operacao em segundos;
    m_vet[m_ind++] = time;                    // atribuindo o novo valor ao vetor...
    if(m_ind==m_len){m_ind=0;}                // chegou o final do vetor, entao voltamos pro inicio...
}