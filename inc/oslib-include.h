// outras constantes
#define CHARTS_MAX       100     // O número possível máximo de gráficos abertos simultaneamente em um terminal
#define clrNONE         -1       // Ausência de cor
#define EMPTY_VALUE      DBL_MAX // Valor vazio em um buffer de indicador
#define INVALID_HANDLE  -1       // Manipulador incorreto
#define IS_DEBUG_MODE    0       // Flag que indica que um programa MQL5 opera em modo de depuração [não-zero para modo de depuração, zero caso contrário]
#define IS_PROFILE_MODE  0       // Flag que indica que um programa MQL5 opera em modo de profiling [não-zero para modo de profiling, zero caso contrário]
#define NULL             0       // Zero para quaisquer tipos
#define WHOLE_ARRAY     -1       // Significa o número de itens restantes até o final do array, isto é, o array inteiro será processado
#define WRONG_VALUE     -1       // A constante pode ser implicitamente convertido para qualquer tipo de enumeração. [da posicao atual ateh o fim do array]

// Códigos de Retorno do Servidor de Negociação
#define TRADE_RETCODE_PLACED         10008 // Ordem colocada
#define TRADE_RETCODE_DONE           10009 // Solicitação concluída
#define TRADE_RETCODE_INVALID        10013 // Solicitação inválida
#define TRADE_RETCODE_INVALID_PRICE  10015 // Preço inválido na solicitação
#define TRADE_RETCODE_TRADE_DISABLED 10017 // Negociação está desabilitada

// sinalizador que define o tipo de ticks obtidos na funcao CopyTicks
#define COPY_TICKS_INFO   0
#define COPY_TICKS_TRADE  1
#define COPY_TICKS_ALL    2


#define __FUNCTION__ ""
#define __MQLBUILD__ ""

#define input
#define group
#define datetime long
#define ulong    long
#define uint     int
#define ushort   short
#define string   void

enum ENUM_BOOK_TYPE{
	BOOK_TYPE_SELL       ,//Ordem de venda (Offer)
	BOOK_TYPE_BUY	     ,//Ordem de compra (Bid)
	BOOK_TYPE_SELL_MARKET,//Ordem de venda (Offer)
	BOOK_TYPE_BUY_MARKET  //Ordem de venda (Offer)
};

enum ENUM_TRADE_TRANSACTION_TYPE{
	TRADE_TRANSACTION_ORDER_ADD     ,// Adição de uma nova ordem de abertura.
	TRADE_TRANSACTION_ORDER_UPDATE  ,// Atualização de uma ordem de aberturar. As atualizações incluem não somente mudanças evidentes provenientes do terminal cliente ou do lado de um servidor de negociação, mas também alterações de estado de uma ordem ao configurá-lo (por exemplo, transição de ORDER_STATE_STARTED para ORDER_STATE_PLACED ou de ORDER_STATE_PLACED para ORDER_STATE_PARTIAL, etc.).
	TRADE_TRANSACTION_ORDER_DELETE  ,// Remoção de uma ordem da lista de ordens em aberto. Uma ordem pode ser excluída da lista de ordens em aberto como resultado da configuração de um solicitação apropriada ou execução (preenchimento) ou movimentação para o histórico.
	TRADE_TRANSACTION_DEAL_ADD      ,// Adição de uma operação (deal) para o histórico. A ação é realizada como resultado de uma execução de uma ordem ou realização de operações com o saldo da conta.
	TRADE_TRANSACTION_DEAL_UPDATE   ,// Atualização de uma operação (deal) no histórico. Pode haver caso quando uma operação (deal) executada previamente é alterada em um servidor. Por exemplo, uma operação (deal) foi alterada em um sistema de negociação externo (exchange) onde ela foi transferida anteriormente por uma corretora (broker).
	TRADE_TRANSACTION_DEAL_DELETE   ,// Exclusão de uma operação (deal) do histórico. Pode haver casos quando uma operação (deal) executada anteriormente é excluída de um servidor. Por exemplo, uma operação (deal) foi excluída de um sistema de negociação externo (exchange) onde ela foi transferida anteriormente por uma corretora (broker).
	TRADE_TRANSACTION_HISTORY_ADD   ,// Adição de uma ordem no histórico como resultado de uma execução ou cancelamento.
	TRADE_TRANSACTION_HISTORY_UPDATE,// Alteração de uma ordem localizada no histórico de ordens. Este tipo é fornecido para aumentar a funcionalidade no lado de um servidor de negociação.
	TRADE_TRANSACTION_HISTORY_DELETE,// Exclusão de uma ordem do histórico de ordens. Este tipo é fornecido para aumentar a funcionalidade no lado de um servidor de negociação.
	TRADE_TRANSACTION_POSITION      ,// Alteração de uma posição não relacionada com a execução de uma operação (deal). Este tipo de transação mostra que uma posição foi alterada pelo lado de um servidor de negociação. O volume de uma posição, o preço de abertura, os níveis de Stop Loss e Take Profit podem ter sido alterados. Dados sobre alteração são submetidos na estrutura MqlTradeTransaction via o handler OnTradeTransaction. Alterações de posição (adição, alteração ou encerramento), como resultado de uma execução de operação (deal), não levam a ocorrência de uma transação TRADE_TRANSACTION_POSITION.
	TRADE_TRANSACTION_REQUEST        // Notificação do fato de que uma solicitação de negociação foi processada por um servidor e o resultado processado foi recebido. Apenas o campo type (tipo de transação de negociação) deve ser analisado em tais transações na estrutura MqlTradeTransaction. O segundo e terceiro parâmetros de OnTradeTransaction (request e result) devem ser analisados para dados adicionais.
};

enum ENUM_ORDER_TYPE{ // Tipo de ordem
	ORDER_TYPE_BUY            ,// Ordem de Comprar a Mercado
	ORDER_TYPE_SELL           ,// Ordem de Vender a Mercado
	ORDER_TYPE_BUY_LIMIT      ,// Ordem pendente Buy Limit
	ORDER_TYPE_SELL_LIMIT     ,// Ordem pendente Sell Limit
	ORDER_TYPE_BUY_STOP       ,// Ordem pendente Buy Stop
	ORDER_TYPE_SELL_STOP      ,// Ordem pendente Sell Stop
	ORDER_TYPE_BUY_STOP_LIMIT ,// Ao alcançar o preço da ordem, uma ordem pendente Buy Limit é colocada no preço StopLimit
	ORDER_TYPE_SELL_STOP_LIMIT,// Ao alcançar o preço da ordem, uma ordem pendente Sell Limit é colocada no preço StopLimit
	ORDER_TYPE_CLOSE_BY        // Ordem de fechamento da posição oposta
};

enum ENUM_ORDER_STATE{ // Estado da ordem
	ORDER_STATE_STARTED       ,// Ordem verificada, mas ainda não aceita pela corretora (broker)
	ORDER_STATE_PLACED        ,// Ordem aceita
	ORDER_STATE_CANCELED      ,// Ordem cancelada pelo cliente
	ORDER_STATE_PARTIAL       ,// Ordem executada parcialmente
	ORDER_STATE_FILLED        ,// Ordem executada completamente
	ORDER_STATE_REJECTED      ,// Ordem rejeitada
	ORDER_STATE_EXPIRED       ,// Ordem expirada
	ORDER_STATE_REQUEST_ADD   ,// Ordem está sendo registrada (aplicação para o sistema de negociação)
	ORDER_STATE_REQUEST_MODIFY,// Ordem está sendo modificada (alterando seus parâmetros)
	ORDER_STATE_REQUEST_CANCEL // Ordem está sendo excluída (excluindo a partir do sistema de negociação)
};

enum ENUM_ORDER_TYPE_TIME{ // Tipo de ordem por período de ação
	ORDER_TIME_GTC          ,//	Ordem válida até cancelamento
	ORDER_TIME_DAY          ,//	Ordem válida até o final do dia corrente de negociação
	ORDER_TIME_SPECIFIED    ,//	Ordem válida até expiração
	ORDER_TIME_SPECIFIED_DAY //	A ordem permanecerá efetiva até 23:59:59 do dia especificado. Se esta hora está fora de uma sessão de negociação, a ordem expira na hora de negociação mais próxima.
};

enum ENUM_ORDER_PROPERTY_STRING{
	ORDER_SYMBOL , // Ativo (symbol) de uma ordem (string)
	ORDER_COMMENT  // Comentário sobre a ordem (string)
};

// Para as funções OrderGetInteger() e HistoryOrderGetInteger()
enum ENUM_ORDER_PROPERTY_INTEGER{
	ORDER_TICKET         , // Bilhete da ordem. Um número exclusivo atribuído a cada ordem (long)
	ORDER_TIME_SETUP     , // Hora de configuração de uma ordem (datetime)
	ORDER_TYPE           , // Tipo de ordem (ENUM_ORDER_TYPE)
	ORDER_STATE          , // Estado de uma ordem (ENUM_ORDER_STATE)
	ORDER_TIME_EXPIRATION, // Hora de expiração de uma ordem (datetime)
	ORDER_TIME_DONE      , // Hora de execução ou cancelamento de uma ordem (datetime)
	ORDER_TIME_SETUP_MSC , // O tempo para colocar uma ordem de execução em milissegundos desde 01.01.1970 (long)
	ORDER_TIME_DONE_MSC  , // Tempo de execução e cancelamento de ordens em milissegundos desde 01.01.1970 (long)
	ORDER_TYPE_FILLING   , // Type de preenchimento de uma ordem (ENUM_ORDER_TYPE_FILLING)
	ORDER_TYPE_TIME      , // tempo de duração de uma ordem (ENUM_ORDER_TYPE_TIME)
	ORDER_MAGIC          , // ID de um Expert Advisor que colocou a ordem (projetado para garantir que cada Expert Advisor coloque seu próprio número único) (long)
	ORDER_REASON         , // Razão ou origem para a colocação da ordem (ENUM_ORDER_REASON)
	ORDER_POSITION_ID    , // Identificador de posição que é definido para uma ordem tão logo ela é executada. Cada ordem executada resulta em uma operação que abre ou modifica uma posição já existente. O identificador desta exata posição é atribuída à ordem executada neste momento.(long)
	ORDER_POSITION_BY_ID   // Identificador da posição oposta para as ordens do tipo (long)
};

//Para as funções OrderGetDouble() e HistoryOrderGetDouble()
enum ENUM_ORDER_PROPERTY_DOUBLE{
	ORDER_VOLUME_INITIAL , // Volume inicial de uma ordem (double)
	ORDER_VOLUME_CURRENT , // Volume corrente de uma ordem (double)
	ORDER_PRICE_OPEN     , // Preço especificado na ordem (double)
	ORDER_SL             , // Valor de Stop Loss (double)
	ORDER_TP             , // Valor de Take Profit (double)
	ORDER_PRICE_CURRENT  , // O preço corrente do ativo de uma ordem (double)
	ORDER_PRICE_STOPLIMIT  // O preço de ordem Limit para uma ordem StopLimit (double)
};

enum ENUM_DEAL_TYPE{ // Tipo de operação (deal)
	DEAL_TYPE_BUY                     ,//	Compra
	DEAL_TYPE_SELL                    ,//	Venda
	DEAL_TYPE_BALANCE                 ,//	Saldo
	DEAL_TYPE_CREDIT                  ,//	Crédito
	DEAL_TYPE_CHARGE                  ,//	Cobrança adicional
	DEAL_TYPE_CORRECTION              ,//	Correção
	DEAL_TYPE_BONUS                   ,//	Bonus
	DEAL_TYPE_COMMISSION              ,//	Comissão adicional
	DEAL_TYPE_COMMISSION_DAILY        ,//	Comissão diária
	DEAL_TYPE_COMMISSION_MONTHLY      ,//	Comissão mensal
	DEAL_TYPE_COMMISSION_AGENT_DAILY  ,//	Comissão de agente diário
	DEAL_TYPE_COMMISSION_AGENT_MONTHLY,//	Comissão de agente mensal
	DEAL_TYPE_INTEREST                ,//	Taxa de juros
	DEAL_TYPE_BUY_CANCELED            ,//	Operação de compra cancelada. Pode haver uma situação quando uma operação de compra executada anteriormente é cancelada. Neste caso, o tipo de transação executada anteriormente (DEAL_TYPE_BUY) é alterada para DEAL_TYPE_BUY_CANCELED, e seu lucro/prejuízo é zerado Lucro/prejuízo obtido anteriormente é cobrado/sacado usando uma operação de saldo separada
	DEAL_TYPE_SELL_CANCELED           ,//	Operação de venda cancelada. Pode haver uma situação quando uma operação de venda executada anteriormente é cancelada. Neste caso, o tipo da operação executada anteriormente (DEAL_TYPE_SELL) é alterada para DEAL_TYPE_SELL_CANCELED, e seu lucro/prejuízo é zerado. Lucro/prejuízo obtido anteriormente é cobrado/sacado usando uma operação de saldo separada
	DEAL_DIVIDEND                     ,//	Operação de dividendos
	DEAL_DIVIDEND_FRANKED             ,//	Operação de dividendos franqueados (não tributáveis)
	DEAL_TAX	                       //	Cálculo do imposto
};


struct MqlDateTime{
   int year;           // Ano
   int mon;            // Mês
   int day;            // Dia
   int hour;           // Hora
   int min;            // Minutos
   int sec;            // Segundos
   int day_of_week;    // Dia da semana (0-domingo, 1-segunda, ... ,6-sábado)
   int day_of_year;    // Número do dia do ano (1 de Janeiro é atribuído o valor 0)
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

struct MqlTradeTransaction{
   ulong                         deal;             // Bilhetagem da operação (deal)
   ulong                         order;            // Bilhetagem da ordem
   string                        symbol;           // Nome do ativo da negociação
   ENUM_TRADE_TRANSACTION_TYPE   type;             // Tipo de transação da negociação
   ENUM_ORDER_TYPE               order_type;       // Tipo de ordem
   ENUM_ORDER_STATE              order_state;      // Estado da ordem
   ENUM_DEAL_TYPE                deal_type;        // Tipo de operação (deal)
   ENUM_ORDER_TYPE_TIME          time_type;        // Tipo de ordem por período de ação
   datetime                      time_expiration;  // Hora de expiração da ordem
   double                        price;            // Preço
   double                        price_trigger;    // Preço de ativação de ordem tipo Stop limit
   double                        price_sl;         // Nível de Stop Loss
   double                        price_tp;         // Nível de Take Profit
   double                        volume;           // Volume em lotes
   ulong                         position;         // Position ticket
   ulong                         position_by;      // Ticket of an opposite position
};

//Como resultado de uma solicitação de negociação, um servidor de negociação retorna dados sobre o resultado do processamento da solicitação de negociação na forma de uma estrutura predefinida especial de tipo MqlTradeResult.
struct MqlTradeResult{
   uint     retcode;          // Código de retorno da operação
   ulong    deal;             // Bilhetagem (ticket) da operação (deal),se ela for realizada
   ulong    order;            // Bilhetagem (ticket) da ordem, se ela for colocada
   double   volume;           // Volume da operação (deal), confirmada pela corretora
   double   price;            // Preço da operação (deal), se confirmada pela corretora
   double   bid;              // Preço de Venda corrente
   double   ask;              // Preço de Compra corrente
   string   comment;          // Comentário da corretora para a operação (por default, ele é preenchido com a descrição código de retorno de um servidor de negociação)
   uint     request_id;       // Identificador da solicitação definida pelo terminal durante o despacho
   uint     retcode_external; // Código de resposta do sistema de negociação exterior
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
//void Print(string arg1);
//void Print(string arg1, string arg2);
//void Print(string arg1, string arg2, string arg3);
  void Print(string arg1, string arg2, string arg3, string arg4);
//void Print(string arg1, string arg2="", string arg3="", string arg4="");
//void Print(string arg1, string arg2   , string arg3   , datetime arg4);

//Copia um array em um outro array.
int  ArrayCopy(
   void&        dst_array[],         // array de destino
   const void&  src_array[],         // array de origem
   int          dst_start=0,         // índice de início do array destino a partir do qual se escreve
   int          src_start=0,         // primeiro índice de um array de origem
   int          count=WHOLE_ARRAY    // número de elementos
);

bool  SymbolInfoTick(
   string    symbol,     // nome do ativo
   MqlTick&  tick        // referencia a uma estrutura
);

//string  EnumToString(
//   any_enum  value      // qualquer tipo de valor de enumeração
//);

string  IntegerToString(
   long    number,              // número
   int     str_len=0,           // comprimento da string resultado
   ushort  fill_symbol=' '      // símbolo de preenchimento
);

// retorna o numero de ordens.
int  OrdersTotal();

// Retorna a propriedade solicitada de uma ordem, pré-selecionado usando OrderGetTicket ou OrderSelect.
//A propriedade da ordem deve ser do tipo string. Existem 2 variantes da função:
// 1. Imediatamente retorna o valor da propriedade.
string  OrderGetString(
   ENUM_ORDER_PROPERTY_STRING  property_id        // Identificador de propriedade
);

//2. Retorna true ou false dependendo do sucesso da função. Se for bem sucedido, o valor da propriedade está situada dentro de uma variável de destino passado por referência pelo último parâmetro.
bool  OrderGetString(
   ENUM_ORDER_PROPERTY_STRING  property_id,       // Identificador de propriedade
   string&                     string_var         // Aqui nós aceitamos o valor de propriedade
);

//Retorna a propriedade solicitada de uma ordem, pré-selecionado usando OrderGetTicket ou OrderSelect. Propriedade de uma Ordem deve ser da tipo datetime, int. Existem 2 variantes da função.
//1. Imediatamente retorna o valor da propriedade.
long  OrderGetInteger(
   ENUM_ORDER_PROPERTY_INTEGER  property_id        // Identificador de propriedade
);

//2. Retorna true ou false dependendo do sucesso da função. Se for bem sucedido, o valor da propriedade está situada dentro de uma variável de destino passado por referência pelo último parâmetro.
bool  OrderGetInteger(
   ENUM_ORDER_PROPERTY_INTEGER  property_id,       // Identificador de propriedade
   long&                        long_var           // Aqui nós aceitamos o valor da propriedade
);

//Retorna a propriedade solicitada de uma ordem, pré-selecionado usando OrderGetTicket ou OrderSelect. A propriedade da ordem deve ser do tipo double. Existem 2 variantes da função.
//1. Imediatamente retorna o valor da propriedade.
double  OrderGetDouble(
   ENUM_ORDER_PROPERTY_DOUBLE  property_id        // Identificador de propriedade
);

//2. Retorna true ou false, dependendo do sucesso na execução da função. Se for bem sucedido, o valor da propriedade é colocado em uma variável alvo passado por referência até ao último parâmetro.
bool  OrderGetDouble(
   ENUM_ORDER_PROPERTY_DOUBLE  property_id,       // Identificador de propriedade
   double&                        double_var         // Aqui nós aceitamos o valor da propriedade
);

//Retorna o ticket de uma ordem correspondente, selecionando automaticamente a ordem para trabalhos posteriores usando funções.
ulong  OrderGetTicket(
   int  index      // Número na lista de posições
);

//A função recebe, na matriz ticks_array, ticks em formato MqlTick, no intervalo de datas especificado.
//Além disso, a indexação é realizada do passado para o presente, ou seja, o tick com índice 0 é o mais antigo na matriz.
//Para analisar o tick, é necessário verificar o campo flags, ele notifica sobre as alterações levadas a cabo.
int  CopyTicksRange(
   const string     symbol_name,           // nome do símbolo
   MqlTick&         ticks_array[],         // matriz para recebimento de ticks
   uint             flags=COPY_TICKS_ALL,  // sinalizador que define o tipo de ticks obtidos
   ulong            from_msc=0,            // data a partir da qual são solicitados os ticks
   ulong            to_msc=0               // data em que são solicitados os ticks
);

