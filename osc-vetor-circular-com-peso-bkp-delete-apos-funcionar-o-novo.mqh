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

//#include <../Shared Projects/oslib/osc-padrao.mqh>
#include <../Shared Projects/oslib/osc-vetor-circular.mqh>
//#define OSC_VETOR_CIRCULAR_LEN_PADRAO 21

class osc_vetor_circular_com_peso : public osc_vetor_circular {
private:
   double m_vet         []    ; //vetor com                  item para o qual serao calculadas as medias;
   double m_vetPeso     []    ; //vetor com  peso         do item para o qual serao calculadas as medias;
   double m_vetPesoXitem[]    ; //vetor com [peso x item] do item para o qual serao calculadas as medias;
   int    m_len           ; //tamanho dos vetores;
   int    m_ind           ; //indice atual dos vetores;
   double m_media         ; //ultima media calculada;
   double m_soma          ; //ultima soma total calculada do vetor de itens;
   double m_somaPeso      ; //ultima soma total calculada do vetor de pesos;
   double m_somaPesoXitem ; //ultima soma total calculada do vetor de pesos x itens;


public:
   osc_vetor_circular_com_peso(){ initialize(OSC_VETOR_CIRCULAR_LEN_PADRAO); }

   int  initialize(int    len             );            //cria o vetor circular com o tamanho informado;
   void add       (double val, double peso);            //substitui a posicao mais antiga do vetor pelo valor recebido (usando peso);
   void add       (double val             ){add(val,1);}//substitui a posicao mais antiga do vetor pelo valor recebido;

   double getMedia(){return m_media;} //Media dos elementos do vetor;
   double getSoma (){return m_soma ;} //Soma  dos elementos do vetor;
//------------------------------------------------------
};

//+---------------------------------------------------------------------------------------+
//| inicializa vetor circular com vetor de tamanho len contendo 0.0 em todos os elementos.|
//+---------------------------------------------------------------------------------------+
int osc_vetor_circular_com_peso::initialize(int len){
    if(len < 1) return 0; // previnindo array com tamanho invalido;

    m_ind = 0; m_media = 0; m_soma  = 0; m_somaPeso = 0; m_somaPesoXitem = 0;

            ArrayResize(m_vetPeso     ,len);
            ArrayResize(m_vetPesoXitem,len);
    m_len = ArrayResize(m_vet         ,len); // prevenindo para o caso do algoritimo Arrayresize aumente mais que tamanho solicitado. Entao colocamos o novo tamanho do vetor na variavem m_len.
    ArrayFill(m_vet          ,0,m_len,0.0);
    ArrayFill(m_vetPeso      ,0,m_len,1.0);
    ArrayFill(m_vetPesoXitem ,0,m_len,0.0);
    return m_len;
}

//+-------------------------------------------------------------------+
//| 1. substitui a posicao mais antiga do vetor pelo valor recebido.  |
//| 2. m_ind fica apontado para o proximo valor que serah adionado ao |
//|    vetor circular.                                                |
//| 3. Recalcula soma e media de valores do vetor.                    |
//+-------------------------------------------------------------------+
void osc_vetor_circular_com_peso::add(double val, double peso){
    m_soma          -= m_vet         [m_ind]; // retirando o elemento que estah sendo subtituido, da soma de itens...
    m_somaPeso      -= m_vetPeso     [m_ind]; // retirando o elemento que estah sendo subtituido, da soma de pesos...
    m_somaPesoXitem -= m_vetPesoXitem[m_ind]; // retirando o elemento que estah sendo subtituido, da soma de peses x itens...

    m_soma          += val     ; // adicionando novo valor a soma de elementos do vetor de itens...
    m_somaPeso      += peso    ; // adicionando novo valor a soma de elementos do vetor de pesos...
    m_somaPesoXitem += peso*val; // adicionando novo valor a soma de elementos do vetor de pesos x itens ...

    m_vet         [m_ind  ] = val;      // atribuindo o novo valor ao vetor de itens...
    m_vetPeso     [m_ind  ] = peso;     // atribuindo o novo valor ao vetor de pesos...
    m_vetPesoXitem[m_ind++] = peso*val; // atribuindo o novo valor ao vetor de itens x pesos...

    m_media = m_somaPesoXitem/m_somaPeso; // recalculando a media...
    if(m_ind==m_len){m_ind=0;}            // chegou o final do vetor, entao voltamos pro inicio...
}
