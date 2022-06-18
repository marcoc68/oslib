//+------------------------------------------------------------------+
//|                                                      osc-csv.mqh |
//|                                                           marcoc |
//|                             https://www.mql5.com/pt/users/marcoc |
//+------------------------------------------------------------------+
#property copyright "marcoc"
#property link      "https://www.mql5.com/pt/users/marcoc"
#property version   "1.00"

//+-----------------------------------------------------------------------------------------------+
//| Manioulacao de arquuivos CSV                                                                  |
//|                                                                                               |
//| - 24/06/2021                                                                                  |
//| - Versao Inicial                                                                              |
//| - Leitura de arquivos CSV                                                                     |
//|                                                                                               |
//+-----------------------------------------------------------------------------------------------+

class osc_csv{

private:
    ushort m_delimiter;
    int    m_file_handle;
    string m_name_file;
    string m_line;
    int    m_qtd_lines, m_ult_linha_lida;
    
    bool   m_tem_cabec;
    string m_cabec[];

    // contas as linhas do arquivo, exceto o cabecalho. Uso interno...
    void count_lines_internal(){
        while(!fim_de_arquivo() ){ m_qtd_lines++; FileReadString(m_file_handle); }
    }

public:

    // abre um arquivo CSV no diretorio comum com o nome e delimitador de campos informados
    // retorna o descritor do arquivo
    int open( string name, ushort delimiter=',', bool tem_cabec=true){
        m_delimiter      = delimiter;
        m_name_file      = name;
        m_tem_cabec      = tem_cabec;
        m_qtd_lines      = 0;
        Print("Abrindo arquivo CSV ", m_name_file, " no diretorio comum de arquivos...");
      //m_file_handle = FileOpen(m_name_file, FILE_READ|FILE_CSV|FILE_COMMON|FILE_ANSI,m_delimiter);
        m_file_handle = FileOpen(m_name_file, FILE_SHARE_READ|FILE_TXT|FILE_COMMON|FILE_ANSI            );
    
        if( m_file_handle<0 ){ Print(__FUNCTION__,": Falha para abrir o arquivo: ", m_name_file, " ERRO: " , GetLastError() ); }

        if(m_tem_cabec) read_line(m_cabec);        
        m_ult_linha_lida = 0; // tem de ficar apos a leitura do cabecalho pois ele nao conta.
        
        return m_file_handle;
    }

    void close(){ 
        Print("Fechando arquivo CSV", m_name_file, "...");
        FileClose(m_file_handle); 
    }
    

    bool fim_de_arquivo(){ return FileIsEnding(m_file_handle); }
    
    // retorna um vetor com os campo de cabecalho do arquivo    
    void get_cabec(string &cabec[]){
        int size = ArraySize(m_cabec);
        ArrayResize(cabec, size );
        for(int i=0; i<size; i++){cabec[i]=m_cabec[i]; }
    }
    
    // leh uma linha do arquivo e coloca o resultado no vetor de campos informado
    bool read_line(string &vetline[]){
    
        if( fim_de_arquivo() ) return false;
        
         m_line = FileReadString(m_file_handle);
        // colocando os campos do log em um array...
        StringSplit( m_line     , // A string que será pesquisada 
                     m_delimiter, // Um separador usado para buscar substrings 
                     vetline   ); // Um array passado por referencia para obter as substrings encontradas 
        
        m_ult_linha_lida++; // incrementando a quantidade de linhas lidas...
        return true;
    }

    // quantidade de linhas do arquivo.
    int get_qtd_lines(){ return m_qtd_lines; }
    
    // contas as linhas do arquivo, exceto o cabecalho. Uso publico...
    void count_lines(){
        // abrindo outra instancia do arquivo para nao desposicionar esta instancia...
        osc_csv arq;  
        arq.open( m_name_file,m_delimiter,m_tem_cabec);
        
        // contando as linhas da segunda instancia aberta e passando o numero de linhas para a variavel que guarda a quantidade de linhas deste arquivo... 
        arq.count_lines_internal();
        m_qtd_lines = arq.get_qtd_lines();
        
        // fechando a segunda instancia
        arq.close();
    }    
};
//---------------------------------------------------------------------------------------------------

