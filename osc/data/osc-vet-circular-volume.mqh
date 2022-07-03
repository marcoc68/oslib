//+------------------------------------------------------------------+
//|                                      osc-vet-circular-volume.mqh |
//|                             Copyright 2022, Oficina de Software. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2022, Oficina de Software."
#property link      "http://www.os.net"

#include <oslib/osc-padrao.mqh>
#include <oslib/osc/est/CStat.mqh>
#include <Math/Stat/Math.mqh>
#include <oslib/osc/data/osc-vet-circular.mqh>

#define VETVOL_TAMANHO_PADRAO 1000

class ItemVol{

public:
    ulong    id      ;
    double   volsel  ; // volume de agressoes de vendas
    double   volbuy  ; // volume de agressoes de compras

    ItemVol():id(0),volsel(0),volbuy(0){}
    ItemVol(MqlTick &tick){
    	id     = tick.time_msc; // usando o horario em milissegundos como id do item da fila.
    	if(osc_padrao::isTkVol(tick)){
        	volsel = (osc_padrao::isTkSel(tick))?tick.volume_real:0;
        	volbuy = (osc_padrao::isTkBuy(tick))?tick.volume_real:0;
    	}else{
    	    volsel=0; volbuy=0;
    	}
    }

    bool tem_volume(){ return (volsel>0 || volbuy>0); }

//    virtual int Compare( const CObject*  node,   // Node to compare with
//                         const int       mode=0){// Compare mode
//       if( this.id > ((ItemVol*)node).id ) return  1;
//       if( this.id < ((ItemVol*)node).id ) return -1;
//                                           return  0;
//    }

    string toString(){
        string str;
        StringConcatenate(str
                             ,"|id "     ,(datetime)id/1000, ",",id%1000
                             ,"|volsel " ,volsel
                             ,"|volbuy " ,volbuy
                          );
        return str;
    }
};

// calculo de media simples baseada em quantidade fixa de elementos. A medida que o vetor de valores enche, despreza o valor mais antigo,
// adiciona o mais novo e reclacula a media.
class osc_vet_circular_volume : public osc_vet_circular<ItemVol*>{

protected:
    double   m_totbuy  ;
    double   m_totsel  ;
    double   m_desb    ; // desbalanceamento: recalculo sempre que executa o metodo add...
    //double   m_mean    ; // media: recalcula sempre que executa o metodo add...
    double   m_var     ; // variancia: recalcula a pedido com a chamada ao medtodo calVar.
    ItemVol* m_item_vazio;
public:
    
    string toString(){
        string str;

        // variaveis da classe...
        StringConcatenate(str
                             ,"|m_ind "     ,m_ind
                             ,"|m_len_max " ,m_len_max
                             ,"|m_len_atu " ,m_len_atu
                             ,"|m_totbuy "  ,m_totbuy
                             ,"|m_totsel "  ,m_totsel
                             ,"|m_desb "    ,m_desb
                          );

        // vetor de itens de volume... 
        for(int i=0; i<m_len_max; i++){
            StringConcatenate(str, str
                                 ,"\n|vet[", i,"] ", m_vet[i].toString());
        }
        return str;
    }
    
    //----------------------------------------------------------------------------------------------------
    // inicializa todas as variaveis usadas no calculo da media. Dimensiona o vetor para len_max( recebido por parametro).
    // Ateh que se adicione o len-ezimo valor ao calculo da media, ela serah influenciada por zeros que sao preenchidos no
    // vetor de valores da media. 
    //
    // in len_max: tamanho do vetor de media
    // in time_frame: se informada a data do item sendo adicionado,
    //    não adiciona ateh que se passe time_frame segundos desde a última adicao
    //----------------------------------------------------------------------------------------------------
    bool initialize(int len_max=VETVOL_TAMANHO_PADRAO, uint time_frame=0){

        if( !_initialize(len_max,time_frame) ) return false;

        // inicializando o array de ItemVol...                
        m_item_vazio = new ItemVol();
        for(int i=0; i<len_max; i++){ m_vet[i]=m_item_vazio; }

        m_totbuy   = 0  ;
        m_totsel   = 0  ;
        m_desb     = 0  ;
      //m_mean     = 0  ;
        m_var      = 0  ;
        //Print( toString() );
        return true;
    }

    //----------------------------------------------------------------------------------------------------
    // Adiciona um item a media, retira o mais antigo (se for maior que o tamanho do vetor de medias) e retorna o valor da media.
    //----------------------------------------------------------------------------------------------------
    bool add(MqlTick &tick){

    	ItemVol *item = new ItemVol(tick);

    	// adicionando...
        if( !_add(item) ){
        	delete(item);
        	return false;
        }
        //Print(__FUNCTION__, "|executando toString()...");
        //Print(__FUNCTION__, toString());
        return true;
    }

    bool pode_inserir_no_vetor(ItemVol *item){ return item.volbuy!=0 || item.volsel!=0; }

    void incrementar_totalizadores(ItemVol *item){
        if( CheckPointer(item)== POINTER_INVALID ) Print(__FUNCTION__, " ANTES ", item.toString(), "|m_totsel ", m_totsel, "|m_totbuy ", m_totbuy );
        m_totbuy += item.volbuy;
        m_totsel += item.volsel;
        if( CheckPointer(item)== POINTER_INVALID ) Print(__FUNCTION__, " DEPOIS",item.toString(), "|m_totsel ", m_totsel, "|m_totbuy ", m_totbuy );
    }

    void decrementar_totalizadores(ItemVol *item){
        if( CheckPointer(item)== POINTER_INVALID ) Print(__FUNCTION__, " ANTES ", item.toString(), "|m_totsel ", m_totsel, "|m_totbuy ", m_totbuy );
        m_totbuy -= item.volbuy;
        m_totsel -= item.volsel;
        if( CheckPointer(item)== POINTER_INVALID ) Print(__FUNCTION__, " DEPOIS",item.toString(), "|m_totsel ", m_totsel, "|m_totbuy ", m_totbuy );
    }

    bool calcular_medias(bool calc_var){
        m_desb=calc_desbalanceamento();
        return true;
    }
    
    // retorna o ultimo valor adicionado ao vetor;
    //double get_volbuy(){ return m_vet[m_ind].volbuy; }
    //double get_volsel(){ return m_vet[m_ind].volsel; }

    // calcula e retorn o desbalanceamento atual.
    double calc_desbalanceamento(){
    	if(  m_len_atu < m_len_max   ){ //Print("vetor pequeno\n",toString() ); 
    	                                return 0; }
        if( (m_totbuy+m_totsel) == 0 ){ //Print("sem volume acumulado\n",toString() ); 
                                        return 0; }
        return (m_totbuy-m_totsel)/(m_totbuy+m_totsel);
    }
    
    int    get_tamanho()         { return m_len_atu; }
    double get_desbalanceamento(){ return m_desb; }
    double get_totbuy(){ return m_totbuy; }
    double get_totsel(){ return m_totsel; }
    datetime dt_tick_mais_antigo(){ 
        ItemVol *item = peek();
        return (datetime)item.id/1000;
    }
    // metodo print util para debug;
//    void print(string nome=""){
//        Print(__FUNCTION__, " :-| Logando vetor ", nome, " var:", getVar(), " ind=", m_ind, " len_calc=",m_len_atu, " tot=", m_tot );
//        ArrayPrint(m_vet);
//    }
};
