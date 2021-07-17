//+------------------------------------------------------------------+
//|                                                      osc-mat.mqh |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//|                                                                  |
//| OPERACOES COM MATRIZES E MATEMATICAS DIVERSAS                    |
//|                                                                  |
//| ULT ERROR -0011                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "2021, Oficina de Software."
#property link      "http://www.os.net"

#include <Math\Stat\Math.mqh>
#include <Math\Alglib\dataanalysis.mqh>

// funcoes matematicas.
class osc_mat{
private:
public:

    // m1 e m2 devem ter o mesmo tamanho.
    // multiplica m1[i] * m2[i], soma os resultados e retorna em result.
    static double dot(double &m1[], double &m2[]){
    
        double result = 0;
        if( !dot(m1,m2,result) ) return EMPTY_VALUE;
        return result;
    }     

    // m1 e m2 devem ter o mesmo tamanho.
    // multiplica m1[i] * m2[i], soma os resultados e retorna em result.
    static bool dot(double &m1[], double &m2[], double &result){
        int nLinM1 = ArraySize(m1);
        int nLinM2 = ArraySize(m2);
        
        // se quantidade de colunas de m1 eh diferente da quantidade de linhas da m2, erro...            
        if( nLinM1 != nLinM2 ){ Print(__FUNCTION__," ERRO GRAVE -0002: m1 tem ",nLinM1, " linhas e m2 tem ",nLinM2,". Qtd lins m1 deve ser igual a qtd lins m2"); return false;}

        double soma = 0;
        for( int lin=0; lin<nLinM1; lin++){ soma += m1[lin] * m2[lin]; }
        result = soma;

        return true;
    }     

    // m1 e m2 devem ter o mesmo tamanho.
    // multiplica m1[i] * m2[i], colocando os resultados nas celulas correspondentes da matriz resultado.
    static bool dot(double &m1[], double &m2[], double &result[]){
        int nLinM1 = ArraySize(m1);
        int nLinM2 = ArraySize(m2);
        
        // se quantidade de colunas de m1 eh diferente da quantidade de linhas da m2, erro...            
        if( nLinM1 != nLinM2 ){ Print(__FUNCTION__," ERRO GRAVE -0003: vet m1 tem tamanho ",nLinM1, " e vet m2 tem ",nLinM2,". Tamanhos devem ser iguais."); return false;}

        ArrayResize(result,nLinM1);
        for( int lin=0; lin<nLinM1; lin++){ result[lin] = m1[lin] * m2[lin]; }

        return true;
    }     

    // multiplicacao matricial...
    static bool dot(double &m1[][], double &m2[][], double &result[][]){
        int nColM1 = ArrayRange(m1,1);
        int nLinM2 = ArrayRange(m2,0);

        int nColM2 = ArrayRange(m2,1);
        int nLinM1 = ArrayRange(m1,0);

        double soma = 0;

        // se quantidade de colunas de m1 eh diferente da quantidade de linhas da m2, erro...            
        if( nColM1 != nLinM2 ){ Print(__FUNCTION__," ERRO GRAVE -0004: m1 tem ",nColM1, " colunas e m2 tem ",nLinM2,". Qtd cols m1 deve ser igual a qtd lins m2"); return false;}

        // a matriz resultado tera dimensao nLinM1 x nColM2...
        for(int lin=0; lin<nLinM1; lin++){
            for(int col=0; col<nColM2; col++){
                
                //result[lin][col] =
                soma = 0;
                for(int i=0; i<nColM2; i++){ // linha de m1
                    for(int j=0; j<nLinM1; j++){
                        soma += m1[lin][i] * m2[j][col];
                    }
                }
                result[lin][col] = soma;
            
            }
        }
        
        return true;
    }     

    // multiplicacao matricial...
    // m1 eh uma matriz 2-D e m2 eh uma matriz 1-D...
    static bool dot(double &m1[][], double &m2[], double &result[]){
        int nLinM1 = ArrayRange(m1,0); // 4
        int nColM1 = ArrayRange(m1,1); // 2
        int nLinM2 = ArraySize (m2  ); // 2
        
        // se quantidade de colunas de m1 eh diferente da quantidade de linhas da m2, erro...            
        if( nColM1 != nLinM2 ){ Print(__FUNCTION__," ERRO GRAVE -0005: m1 tem ",nColM1, " colunas e m2 tem ",nLinM2,". Qtd cols m1 deve ser igual a qtd lins m2"); return false;}

       ArrayResize(result,nLinM1);
        double soma = 0;
        for( int lin=0; lin<nLinM1; lin++){
            
            // somado os valores de uma linha da matriz m1...
            soma = 0;
            for(int col=0; col<nColM1; col++){
                soma += m1[lin][col] * m2[col];
            }
            result[lin] = soma;
        }
        
        return true;
    }

    // soma um vetor a um numero. cada celula do vetor ficarah somada ao numero.
    static void sum(double &m1[], double num, double &result[], int size=0){
        if(size==0) size = ArraySize (m1);
        ArrayResize(result,size);

        for( int i=0; i<size; i++){ result[i] = m1[i]+num; }
    }

    // soma um vetor a um numero. cada celula do vetor ficarah somada ao numero.
    static void sub(double &m1[], double num, double &result[], int size=0){ sum(m1,-num,result,size); }

    // soma um vetor a um numero. cada celula do vetor ficarah somada ao numero.
    // coloca o resultado em m1.
    static void sum1(double &m1[], double num, int size=0){
        if(size==0) size = ArraySize (m1);
        for( int i=0; i<size; i++){ m1[i] = m1[i]+num; }
    }

    // subtrai um numero de um vetor. cada celula do vetor ficarah subtraida do numero.
    // coloca o resultado em m1.
    static void sub1(double &m1[], double num, int size=0){ sum1(m1,-num,size); }

    // subtrai um numero de um vetor. cada celula do vetor ficarah igual ao numero menos a celula.
    static void sub(double num, double &m1[], double &result[]){
        int size = ArraySize (m1);
        ArrayResize(result,size);

        for( int i=0; i<size; i++){ result[i] = num-m1[i]; }
    }
    
    // faz m1 mais m2 e coloca o resultado em m1.
    static bool sum1(double &m1[], double &m2[]){
        int size1 = ArraySize (m1);
        int size2 = ArraySize (m2);

        // se quantidade de colunas de m1 eh diferente da quantidade de linhas da m2, erro...            
        if( size1 != size2 ){ Print(__FUNCTION__," ERRO GRAVE -0009: m1 tem ",size1, " linhas e m2 tem ",size2,". Qtd lins m1 deve ser igual a qtd lins m2"); return false;}

        for( int i=0; i<size1; i++){ m1[i] = m1[i]+m2[i]; }
        return true;
    }
    
    // faz m1 menos m2 e coloca o resultado em result.
    static bool sub(double &m1[], double &m2[], double &result[]){
        int size1 = ArraySize (m1);
        int size2 = ArraySize (m2);

        // se quantidade de colunas de m1 eh diferente da quantidade de linhas da m2, erro...            
        if( size1 != size2 ){ Print(__FUNCTION__," ERRO GRAVE -0006: m1 tem ",size1, " linhas e m2 tem ",size2,". Qtd lins m1 deve ser igual a qtd lins m2"); return false;}

        ArrayResize(result,size1);
        for( int i=0; i<size1; i++){ result[i] = m1[i]-m2[i]; }
        return true;
    }
    
    // faz m1 menos m2 e coloca o resultado em m1.
    static bool sub1(double &m1[], double &m2[]){
        int size1 = ArraySize (m1);
        int size2 = ArraySize (m2);

        // se quantidade de colunas de m1 eh diferente da quantidade de linhas da m2, erro...            
        if( size1 != size2 ){ Print(__FUNCTION__," ERRO GRAVE -0010: m1 tem ",size1, " linhas e m2 tem ",size2,". Qtd lins m1 deve ser igual a qtd lins m2"); return false;}

        for( int i=0; i<size1; i++){ m1[i] = m1[i]-m2[i]; }
        return true;
    }
    
    // faz m1 menos m2 e coloca o resultado em m2.
    static bool sub2(double &m1[], double &m2[]){
        int size1 = ArraySize (m1);
        int size2 = ArraySize (m2);

        // se quantidade de colunas de m1 eh diferente da quantidade de linhas da m2, erro...            
        if( size1 != size2 ){ Print(__FUNCTION__," ERRO GRAVE -0011: m1 tem ",size1, " linhas e m2 tem ",size2,". Qtd lins m1 deve ser igual a qtd lins m2"); return false;}

        for( int i=0; i<size1; i++){ m2[i] = m1[i]-m2[i]; }
        return true;
    }
    
    // multiplica um vetor por um numero. cada celula do vetor ficarah pultiplicada pelo numero.
    static void times(double &m1[], double num, double &result[]){
        int size = ArraySize (m1);
        ArrayResize(result,size);

        for( int i=0; i<size; i++){ result[i] = m1[i]*num; }
    }

    // multiplica um vetor por um numero. armazena o resultado no vetor.
    static void mul1(double &m1[], double num){
        int size = ArraySize (m1);
        for( int i=0; i<size; i++){ m1[i] = m1[i]*num; }
    }

    // compara as celulas com um numero informado. cada celula do vetor ficarah com 1 se for maior que o numero e 0 se for menor.
    static void greatherthan(double &m1[], double num, double &result[]){
        int size = ArraySize (m1);
        ArrayResize(result,size);

        for( int i=0; i<size; i++){ result[i] = m1[i]>num; }
    }

    // faz m1 == m2 e coloca o resultado em result.
    static bool equals(double &m1[], double &m2[], double &result[]){
        int size1 = ArraySize (m1);
        int size2 = ArraySize (m2);

        // se quantidade de colunas de m1 eh diferente da quantidade de linhas da m2, erro...            
        if( size1 != size2 ){ Print(__FUNCTION__," ERRO GRAVE -0007: m1 tem ",size1, " linhas e m2 tem ",size2,". Qtd lins m1 deve ser igual a qtd lins m2"); return false;}

        ArrayResize(result,size1);
        for( int i=0; i<size1; i++){ result[i] = m1[i]==m2[i]; }
        return true;
    }
    
    // obtem a linha da matriz...
    static bool getline(double &m1[][], int lin, double &line[]){
        int nLinM1 = ArrayRange(m1,0);
        int nColM1 = ArrayRange(m1,1);
        ArrayResize(line,nColM1);
        
        // se a linha que se quer obter eh maior que a quantidade de linhas de m1, erro...            
        if( nLinM1 < lin ){ Print(__FUNCTION__," ERRO GRAVE -0008: m1 tem ",nLinM1, " linhas. Nao posso obter a linha ",lin,"..."); return false;}

        // somado os valores de uma linha da matriz m1...
        for(int col=0; col<nColM1; col++){ line[col] = m1[lin][col]; }
        return true;
    }
    
    // obtem a linha da matriz...
    static bool getline(CMatrixDouble &m1, int lin, double &line[]){
        int nLinM1 = m1   .Size();
        int nColM1 = m1[0].Size();
        ArrayResize(line,nColM1);
        
        // se a linha que se quer obter eh maior que a quantidade de linhas de m1, erro...            
        if( nLinM1 < lin ){ Print(__FUNCTION__," ERRO GRAVE -0008: m1 tem ",nLinM1, " linhas. Nao posso obter a linha ",lin,"..."); return false;}

        // somado os valores de uma linha da matriz m1...
        for(int col=0; col<nColM1; col++){ line[col] = m1[lin][col]; }
        return true;
    }
    
    // escala os valores de cada coluna dividindo cada celula pelo valor maximo na coluna.
    static void escalar_colunas_pelo_max(double &m1[][]){
        int nLin = ArrayRange(m1,0);
        int nCol = ArrayRange(m1,1);
        
        double max;
        for(int i=0; i<nCol; i++){
            // 1. descubra o maior valor da coluna...
            max = m1[0][i];
            for(int j=0; j<nLin; j++){ if( m1[j][i] > max ) max = m1[j][i]; }
                        
            // 2. divida o valor de cada elemento da coluna pelo maximo
            for(int j=0; j<nLin; j++){ m1[j][i] = m1[j][i] / max; }
        }
    }
    
    // padroniza os valores de cada coluna fazendo de_mean e depois re_scale. Resultado fica na matriz original.
    // m1           : matriz cujas colunas serao padronizadas
    // exceto =0    : quantidade de ultimas colunas que nao devem ser padronizadas
    // verbose=false: imprime resultado a padronizacao de cada coluna
    static void padronizar_colunas(CMatrixDouble &m1, int exceto=0, bool verbose=false){
        int nLin = m1   .Size();
        int nCol = m1[0].Size()-exceto;
        
        for(int col=0; col<nCol; col++){ padronizar_col(m1,col,nLin,verbose); }
    }
    
    // padroniza os valores de cada coluna fazendo de_mean e depois re_scale. Resultado fica na matriz m2. Nao altera m1.
    // m1           : matriz cujas colunas serao padronizadas
    // m2           : matriz resultado
    // exceto =0    : quantidade de ultimas colunas que nao devem ser padronizadas
    // verbose=false: imprime resultado a padronizacao de cada coluna
    static void padronizar_colunas(CMatrixDouble &m1, CMatrixDouble &m2, int exceto=0, bool verbose=false){
        copy(m1,m2); // copia m1 para m2
        padronizar_colunas(m2, exceto, verbose); //padroniza m2
    }
        
    // padroniza os valores de cada coluna fazendo de_mean e depois re_scale.
    // m1           : matriz cujas colunas serao padronizadas
    // exceto =0    : quantidade de ultimas colunas que nao devem ser padronizadas
    // verbose=false: imprime resultado a padronizacao de cada coluna
    static void padronizar_colunas(double &m1[][], int exceto=0, bool verbose=false){
        int nLin = ArrayRange(m1,0);
        int nCol = ArrayRange(m1,1)-exceto;
        
        for(int col=0; col<nCol; col++){ padronizar_col(m1,col,nLin,verbose); }
    }
    
    //
    // padroniza a linha em funcao dos dados da matriz. Os dados padronizados ficam gravados em line_dst.
    // mat     : matriz com os dados que serao usados para padronizacao
    // line_ori: linha com os dados a padronizar
    // line_dst: linha onde serao gravados os dados padronizados
    // verbose : 
    // 
    static void padronizar_linha(CMatrixDouble &mat, double &line_ori[], double &line_dst[], bool verbose=false){
        ArrayCopy(line_dst,line_ori);
        padronizar_linha(mat,line_dst,verbose);
    }

    //
    // padroniza a linha em funcao dos dados da matriz. Os dados padronizados sobrepoe o vetor line
    // mat     : matriz com os dados que serao usados para padronizacao
    // line_ori: linha com os dados a padronizar
    // line_dst: linha onde serao gravados os dados padronizados
    // verbose : 
    // 
    static void padronizar_linha(CMatrixDouble &mat, double &line[], bool verbose=false){
        int nColsPadronizar = ArraySize(line);
        int nColsMat        = mat[0].Size();
        int nColsDesprezar  = nColsMat-nColsPadronizar;
        
        // copiando a linha para a matriz de dados. Se a linha tiver menos colunas que a matriz de dados,
        // desprea colunas na matriz de dados, de forma que a matriz dst fique com a quantidade de
        // colunas igual ao tamanho da linha que serah padronizada.
        CMatrixDouble dst;
        copy(mat,dst,nColsDesprezar);
        
        // adicionando a linha a matriz de destino
        int posLine = addLine(dst,line);
        
        // padronizando a matriz destino
        padronizar_colunas(dst,0,verbose);
        
        // salvando os dados padronizados na linha
        for(int i=0; i<nColsPadronizar; i++){ line[i]=dst[posLine][i];}
    }
    
    // faz o de_mean de uma coluna da matriz.
    static void de_mean_col(CMatrixDouble &m1, int col, int nLin=0){
        if(nLin==0) nLin = m1.Size();
        double mean = mean_col(m1,col,nLin);
        for(int lin=0; lin<nLin; lin++){ m1[lin].Set(col, m1[lin][col] - mean); }
    }

    // faz o de_mean de uma coluna da matriz.
    static void de_mean_col(double &m1[][], int col, int nLin=0){
        if(nLin==0) nLin = ArrayRange(m1,0);
        double mean = mean_col(m1,col,nLin);
        for(int lin=0; lin<nLin; lin++){ m1[lin][col] -= mean;}
    }

    // para cada valor do vetor faz o valor menos a media do vetor
    static void de_mean(double &m1[], int size=0){
        if(size==0) size = ArraySize(m1);
        double mean = MathMean(m1);
        for(int i=0; i<size; i++){ m1[i] = m1[i]-mean;}
    }

    // faz o re_escale de uma coluna da matriz.
    static void re_scale_col(CMatrixDouble &m1, int col, int nLin=0){
        if(nLin==0) nLin = m1.Size();
        double lambda = sumabs_col(m1,col,nLin);
        for(int lin=0; lin<nLin; lin++){ m1[lin].Set(col, m1[lin][col] / lambda); }
    }

    // faz o re_escale de uma coluna da matriz.
    static void re_scale_col(double &m1[][], int col, int nLin=0){
        if(nLin==0) nLin = ArrayRange(m1,0);
        double lambda = sumabs_col(m1,col,nLin);
        for(int lin=0; lin<nLin; lin++){ m1[lin][col] /= lambda;}
    }

    // para cada valor do vetor faz o valor dividido pela soma dos valores absolutos do vetor
    static void re_scale(double &m1[], int size=0){
        if(size==0) size = ArraySize(m1);
        double lambda = sumabs(m1,size);
        for(int i=0; i<size; i++){ m1[i] = m1[i]/lambda;}
    }

    // faz de_mean e em seguida re_escale
    static void padronizar(double &m1[], int size=0){
        if(size==0) size = ArraySize(m1);
        de_mean (m1,size);
        re_scale(m1,size);
    }

    // faz de_mean e em seguida re_escale da coluna informada
    static void padronizar_col(double &m1[][], int col, int nLin=0, bool verbose=false){
        if(nLin==0) nLin = ArrayRange(m1,0);
        de_mean_col (m1,col,nLin);
        re_scale_col(m1,col,nLin);
        if(verbose){
            Print(__FUNCTION__," Media  da coluna ", col, " apos padronizacao eh:", DoubleToString(mean_col  (m1,col,nLin),4) );
            Print(__FUNCTION__," SumAbs da coluna ", col, " apos padronizacao eh:", DoubleToString(sumabs_col(m1,col,nLin),4) );
        }
    }

    // faz de_mean e em seguida re_escale da coluna informada
    static void padronizar_col(CMatrixDouble &m1, int col, int nLin=0, bool verbose=false){
        if(nLin==0) nLin = m1.Size();
        de_mean_col (m1,col,nLin);
        re_scale_col(m1,col,nLin);
        if(verbose){
            Print(__FUNCTION__," Media  da coluna ", col, " apos padronizacao eh:", DoubleToString(mean_col  (m1,col,nLin),4) );
            Print(__FUNCTION__," SumAbs da coluna ", col, " apos padronizacao eh:", DoubleToString(sumabs_col(m1,col,nLin),4) );
        }
    }

    // retorna a soma dos valores absolutos do vetor
    static double sumabs(double &m1[], int size=0){
        double lambda = 0;
        if(size==0) size = ArraySize(m1);
        
        for(int i=0; i<size; i++){ lambda += fabs(m1[i]);}
        
        return lambda;
    }

    // retorna a soma dos valores absolutos de uma coluna do vetor
    static double sumabs_col(CMatrixDouble &m1, int col, int nLin=0){
        if(nLin==0) nLin = m1.Size();
        double lambda = 0;
        
        for(int lin=0; lin<nLin; lin++){ lambda += fabs(m1[lin][col]); }
        return lambda;
    }

    // retorna a soma dos valores absolutos de uma coluna do vetor
    static double sumabs_col(double &m1[][], int col, int nLin=0){
        if(nLin==0) nLin = ArrayRange(m1,0);
        double lambda = 0;
        
        for(int lin=0; lin<nLin; lin++){ lambda += fabs(m1[lin][col]); }
        return lambda;
    }

    // calcula a media de uma coluna da matriz
    static double mean_col(CMatrixDouble &m1, int col, int nLin=0){
        if(nLin==0) nLin = m1.Size();
        double sum  = 0;
        
        for(int lin=0; lin<nLin; lin++){ sum += m1[lin][col]; }
        return sum/(double)nLin;
    }

    // calcula a media de uma coluna da matriz
    static double mean_col(double &m1[][], int col, int nLin=0){
        if(nLin==0) nLin = ArrayRange(m1,0);
        double sum  = 0;
        
        for(int lin=0; lin<nLin; lin++){ sum += m1[lin][col]; }
        return sum/(double)nLin;
    }
    
    // retorna a soma dos quadrados do vetor
    static double sumpow(double &m1[], int expoente, int size=0){
        double sum = 0;
        if(size==0) size = ArraySize(m1);
        
        for(int i=0; i<size; i++){ sum += pow(m1[i],expoente);}
        
        return sum;
    }
    
    static void matrix2CmatrixD(double &mat[][], CMatrixDouble &matd, int nLin=0, int nCol=0){
        if(nLin==0) nLin = ArrayRange(mat,0);
        if(nCol==0) nCol = ArrayRange(mat,1);
        matd.Resize(nLin,nCol);
        
        for( int lin=0; lin<nLin; lin++){
            for(int col=0; col<nCol; col++ ){
                matd[lin].Set(col,mat[lin][col]);
            }
        }
    }

    // cria uma string com o formato e os dados da matriz passada como parametro.
    static string toString(CMatrixDouble &matd, int dig){

        int nLin = matd.Size();
        int nCol = matd[0].Size();
        
        string str = "";
        
        for( int lin=0; lin<nLin; lin++){
            
            StringConcatenate(str, str, lin, "\t\t" );
            for(int col=0; col<nCol; col++ ){
               StringConcatenate(str, str, DoubleToString(matd[lin][col],dig),"\t\t" );
            }
            StringConcatenate(str, str, "\n" );
        }
        return str;
    }

    //
    // copia a matriz ori para a matriz dst
    // ori       : matriz origem
    // dst       : matriz destino
    // excetoCols: quantidade de ultimas colunas que nao sao copiadas para a matriz destino
    //
    static void copy(CMatrixDouble &ori, CMatrixDouble &dst, int excetoCols=0){

        int nLin = ori.Size();
        int nCol = ori[0].Size()-excetoCols;
        dst.Resize(nLin,nCol);
        
        for( int lin=0; lin<nLin; lin++){            
            for(int col=0; col<nCol; col++ ){
               dst[lin].Set(col, ori[lin][col]);
            }
        }
    }

    // adiciona uma linha ao final da matriz...
    // retorna a posicao em que a linha foi adicionada... 
    static int addLine(CMatrixDouble &mat, double &line[]){

        int nLin = mat.Size();
        int nCol = mat[0].Size();
        mat.Resize(nLin+1,nCol);
        
        for(int col=0; col<nCol; col++ ){ mat[nLin].Set(col, line[col]); }
        return nLin;
    }
    
    // se val eh zero, retorna x, senao, retorna val...
    static double x_if_zero(double val, double x){
        if(val==0) return x;
        return val;
    }
    
    // retorna o sinal de um numero. Pode ser 0,1 ou -1
    static int sinal(double x){
        if(x>0) return  1;
        if(x<0) return -1;
                return  0;
    }
    
    // preco eficiente em modelos de alta frequencia, segundo modelo de Roll
    // Plast = Peficiente + (1/2)spread * (+1 no lado bid, ou -1 no lado ask)
    // Peficiente = Plast + (1/2)spread * (+1 no lado bid, ou -1 no lado ask)
    // ref: 2017-Quantitative Trading_ Algorithms, Analytics, Data, Models, Optimization
    static double preco_eficiente_hft(double bid, double ask, double last){
        return last + ( (ask-bid)/2.0 ) * (last <= bid)?+1:-1;
    }

    // seja:
    // Yt o logaritimo do preco de mercado no instante t
    // Xt o logaritimo do preco eficiente  no instante t
    // A ampliacao do mdelo de Roll define:
    // Yt = Xt + vies
    // vies = Yt - Xt
    // ref: 2017-Quantitative Trading_ Algorithms, Analytics, Data, Models, Optimization
    static double vies_microestrutura_hft(double p_last, double p_eficiente){
        return log(p_last) - log(p_eficiente);
    }
};