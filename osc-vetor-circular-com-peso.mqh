//+------------------------------------------------------------------+
//|                                           osc-vetor-circular.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"
//+---------------------------------------------------------------------+
//| Vetor circular de tamaho fixo visando rapido calculo de medias.     |
//+---------------------------------------------------------------------+
#property description "Vetor circular de tamaho fixo visando rapido calculo de medias, com suporte a pesos."

#include <oslib/osc-vetor-circular.mqh>

class osc_vetor_circular_com_peso : public osc_vetor_circular {
private:
   osc_vetor_circular m_vetPeso     ; //vetor com  peso         do item para o qual serao calculadas as medias;
   osc_vetor_circular m_vetPesoXitem; //vetor com [peso x item] do item para o qual serao calculadas as medias;
   double m_mediaPonderada          ; //ultima media ponderada calculada;


public:
   osc_vetor_circular_com_peso(){ initialize(OSC_VETOR_CIRCULAR_LEN_PADRAO); }

   int  initialize(int    len                 ); //cria o vetor circular com o tamanho informado;
   void add       (double val, double peso=1.0); //substitui a posicao mais antiga do vetor pelo valor recebido (usando peso);

   double getMedia    (){return m_mediaPonderada    ;} //Media do valor principal ponderada;
   double getSomaPeso (){return m_vetPeso.getSoma() ;} //Soma  dos pesos;
   double getMediaPeso(){return m_vetPeso.getMedia();} //Media dos pesos;
//------------------------------------------------------
};

//+---------------------------------------------------------------------------------------+
//| inicializa vetor circular com vetor de tamanho len contendo 0.0 em todos os elementos.|
//+---------------------------------------------------------------------------------------+
int osc_vetor_circular_com_peso::initialize(int len){
           osc_vetor_circular::initialize(len);
           m_vetPeso          .initialize(len);
    return m_vetPesoXitem     .initialize(len);
}

//+-------------------------------------------------------------------+
//| 1. substitui a posicao mais antiga do vetor pelo valor recebido.  |
//| 2. m_ind fica apontado para o proximo valor que serah adionado ao |
//|    vetor circular.                                                |
//| 3. Recalcula soma e media de valores do vetor.                    |
//+-------------------------------------------------------------------+
void osc_vetor_circular_com_peso::add(double val, double peso=1.0){

     // peso nao pode ser zero
     if(peso==0)peso=1;

     //Print("VCP:","adicionando val:",val," ao vetor de valor...");
     osc_vetor_circular::add(val);

     //Print("VCP:","adicionando pes:",peso," ao vetor de peso...");
     m_vetPeso.add(peso);

     //Print("VCP:","adicionando pes*val:",peso*val," ao vetor pesoXval...");
     m_vetPesoXitem.add(peso*val);

     //Print("VCP:","Calculando mediaPond com m_vetPesoXitem.getSoma():",m_vetPesoXitem.getSoma()," dividido por m_vetPeso.getSoma():",m_vetPeso.getSoma(), " ..." );
     m_mediaPonderada = m_vetPesoXitem.getSoma() / m_vetPeso.getSoma();

     //Print("VCP:","Calc MediaPond OK:",m_mediaPonderada, " :-)" );
}
