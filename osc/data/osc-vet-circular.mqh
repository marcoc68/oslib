//+------------------------------------------------------------------+
//|                                             osc-vet-circular.mqh |
//|                             Copyright 2022, Oficina de Software. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2022, Oficina de Software."
#property link      "http://www.os.net"

#include <oslib/osc/est/CStat.mqh>
#include <Math/Stat/Math.mqh>

// calculo de media simples baseada em quantidade fixa de elementos. A medida que o vetor de valores enche, despreza o valor mais antigo,
// adiciona o mais novo e reclacula a media.
template<typename T> class osc_vet_circular{

protected:
    int     m_ind     ;
    int     m_len_max ;
    int     m_len_atu ;
    T       m_vet[]   ;

    uint     m_tf        ; // time_frame
    datetime m_dt_ult_add; // data da ultima adiciao ao vetor
    
    //----------------------------------------------------------------------------------------------------
    // inicializa todas as variaveis usadas no calculo da media. Dimensiona o vetor para len_max( recebido por parametro).
    // Ateh que se adicione o len-ezimo valor ao calculo da media, ela serah influenciada por zeros que sao preenchidos no
    // vetor de valores da media. 
    //
    // in len_max: tamanho do vetor de media
    // in time_frame: se informada a data do item sendo adicionado,
    //    não adiciona ateh que se passe time_frame segundos desde a última adicao
    //----------------------------------------------------------------------------------------------------
    bool _initialize(int len_max, uint time_frame=0){

        if( len_max < 2 ) return false;
        m_len_max  = len_max;
        m_len_atu  = 0      ;
        m_ind      = 0      ;
        ArrayResize(m_vet,len_max);

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
    bool _add(T item, datetime time, bool calc_var=false){
        //Print("m_len:",m_len," ind:",m_ind," time:",time," val:",val," m_mean:",m_mean);
        // se nao passou o time_frame minimo para acumular, nao faz nada e retorna falso.
        if( (time - m_dt_ult_add) < m_tf ) return false;

        // atualizando a data da ultima adicao...
        m_dt_ult_add = time;

        // adicionando...
        return _add(item,calc_var);
    }

    //----------------------------------------------------------------------------------------------------
    // Adiciona um item a media, retira o mais antigo (se for maior que o tamanho do vetor de medias) e retorna o valor da media.
    //----------------------------------------------------------------------------------------------------
    bool _add(T item, bool calc_var=false){
    
        if( !pode_inserir_no_vetor(item) ) return false;

        //Print(__FUNCTION__,"  ANTES:", toString());
        if( m_len_atu < m_len_max ) m_len_atu++;

        incrementar_totalizadores(item);
        decrementar_totalizadores(m_vet[m_ind]);
        
        if(m_len_atu == m_len_max) delete(m_vet[m_ind]); //<TODO> se tiver de deletar o que sai da fila eh aqui...
        m_vet[m_ind] = item; // e colocando o ultimo valor calculado
        
        if( ++m_ind == m_len_max ){ m_ind=0; }   // atualizando o indice

        // acionando o evento on_window;
        on_window(m_vet[m_ind],item);
        
        //Print(__FUNCTION__," DEPOIS:", toString());
        
        return calcular_medias(calc_var);
    }
    virtual bool   pode_inserir_no_vetor    (   T item    ){return false;};
    virtual void   incrementar_totalizadores(   T item    ){return      ;};
    virtual void   decrementar_totalizadores(   T item    ){return      ;};
    virtual bool   calcular_medias          (bool calc_var){return true ;};
    virtual string toString()                              {return "implemente toString()";}      

    // o evento on window acontece sempre que um ciclo de preenchimento do vetor eh completado.
    // sao fornecidos o item mais antigo (first_item) e o mais novo (last_item);
    virtual void   on_window                (const T first_item, const T last_item) {}
public:    
    // retorna a quantidade de elementos no vetor circular.
    // Se encheu, retornarah o tamanho do tamanho do vetor, senao, retornarah um valor menor que seu tamanho.
    double count() { return m_len_atu; }
    
    // retorna o elemento mais antigo do vetor.
    T peek(){ return m_vet[m_ind]; }
    
};
