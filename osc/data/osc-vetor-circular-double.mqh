//+------------------------------------------------------------------+
//|                                    osc-array-circular-double.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
// Vetor circular de double com tamanho fixo. Quando cheio, sobrescreve o elemento mais antigo.
class VetorCircularDouble{
private:
    vector m_buffer;
    uint    m_capacity;
    uint    m_head; // índice do elemento mais antigo
    uint    m_tail; // índice do próximo elemento a ser adicionado
    uint    m_size;

public:
    

    // Construtor define a capacidade máxima do vetor circular
    VetorCircularDouble(int capacity=100) {
        m_capacity = capacity;
        m_buffer = vector::Zeros(m_capacity); // Aloca o tamanho fixo do vector nativo
        m_head = 0;
        m_tail = 0;
        m_size = 0;
    }

    // Retorna a quantidade atual de elementos armazenados
    uint size() const { return m_size; }

    // Retorna a capacidade máxima
    uint capacity() const { return m_capacity; }

    // Adiciona um novo elemento (se cheio, sobrescreve o mais antigo)
    void add(double value) {
        m_buffer[m_tail] = value;
        m_tail = (m_tail + 1) % m_capacity;

        if(m_size < m_capacity) {
            m_size++;
        }else{
            m_head = (m_head + 1) % m_capacity; // Avança o 'head' descartando o elemento mais antigo
        }
    }

    // Substitui o elemento no índice lógico (0 = mais antigo, size()-1 = mais recente)
    void set(uint index, double value) {
        if(index >= m_size) return; // Índice fora do intervalo
        uint actualIndex = (m_head + index) % m_capacity;
        m_buffer[actualIndex] = value;
    }

    // Acessa o elemento por índice lógico (0 = mais antigo, size()-1 = mais recente)
    double at(uint index) const{
        if(index >= m_size) return 0.0;
        uint actualIndex = (m_head + index) % m_capacity;
        return m_buffer[actualIndex];
    }

    // Retorna um novo 'vector' ordenado do mais antigo para o mais recente
    // (útil caso queira aplicar funções estatísticas nativas do MQL5, como .Mean(), .Sum(), etc.)
    vector toVector() const {
        vector result;
        result.Resize(m_size);
        for(uint i = 0; i < m_size; i++){
            result[i] = at(i);
        }
        return result;
    }

    double calcVar() const{ return m_buffer.Var(); }

    // Limpa o buffer
    void Clear(){
        m_head = 0;
        m_tail = 0;
        m_size = 0;
    }

    string toString() const {
        string result = "VetorCircularDouble[";
        for(uint i = 0; i < m_size; i++){
            result += DoubleToString(at(i), 4);
            if(i < m_size - 1) result += ", ";
        }
        result += "]";
        return result;
    }
};