enum ENUM_BOOK_TYPE{
	BOOK_TYPE_SELL       , //Ordem de venda (Offer)
	BOOK_TYPE_BUY	     , //Ordem de compra (Bid)
	BOOK_TYPE_SELL_MARKET, //Ordem de venda (Offer)
	BOOK_TYPE_BUY_MARKET   //Ordem de venda (Offer)
};

struct MqlBookInfo{
   ENUM_BOOK_TYPE   type;            // Tipo de ordem proveniente da enumera��o ENUM_BOOK_TYPE 
   double           price;           // Pre�o 
   long             volume;          // Volume 
   double           volume_real;     // Volume com maior precis�o 
};

struct MqlTick{
   datetime     time;          // Hora da última atualização de preços
   double       bid;           // Preço corrente de venda
   double       ask;           // Preço corrente de compra
   double       last;          // Preço da última operação (preço último)
   ulong        volume;        // Volume para o preço último corrente
   long         time_msc;      // Tempo do "Last" preço atualizado em  milissegundos
   uint         flags;         // Flags de tick
   double       volume_real;   // Volume para o preço Last atual com maior precisão
};

//Retorna a última hora conhecida do servidor de negociacao.
datetime TimeCurrent();

// define um tamanho novo para a primeira dimensao
int  ArrayResize(
   void&  array[],              // array passado por referência
   int    new_size,             // novo tamanho de array
   int    reserve_size=0        // valor do tamanho de reserva (excesso)
);

//  preenche um array com o valor especificado.
void  ArrayFill(
   void&  array[],      // array
   int    start,        // índice de início
   int    count,        // número de elementos para preencher
   void   value         // valor
);

//Retorna um array de estruturas MqlBookInfo contendo registros da Profundidade de Mercado de um ativo especificado.
bool  MarketBookGet(
   string        symbol,     // ativo
   MqlBookInfo&  book[]      // referência para um array
);

//Entra uma mensagem no log do Expert Advisor. Parâmetros podem ser de qualquer tipo.
void Print(string argument1);
void Print(string argument1, string argumentn);

//Copia um array em um outro array.
int  ArrayCopy(
   void&        dst_array[],         // array de destino
   const void&  src_array[],         // array de origem
   int          dst_start=0,         // índice de início do array destino a partir do qual se escreve
   int          src_start=0,         // primeiro índice de um array de origem
   int          count=WHOLE_ARRAY    // número de elementos
);


#define WHOLE_ARRAY  //da posicao atual ateh o fim do array


