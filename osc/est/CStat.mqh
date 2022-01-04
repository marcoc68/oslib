//+------------------------------------------------------------------+
//|                                                         CStat.mqh|
//|                               Copyright 2020,oficina de software.|
//|                                 https://www.metaquotes.net/marcoc.|
//+------------------------------------------------------------------+
//#property copyright "2020, Oficina de Software."
//#property link      "https://www.os.net"
//---

class CStat{

    private:
    protected:
    public:
  //bool calcCoefKelly(const double _payOut  , const double _probWin, double &_coefKelly);
  //bool calcCoefKelly(const double _qtdLoss , const double _qtdWin ,
  //                   const double _lossAcum, const double _winAcum, double &_coefKelly);

  //bool calcPayOut   (const double _lossAcum, const double _winAcum, double &_payOut   );
  //bool calcProbWin  (const double _qtdLoss , const double _qtdWin , double &_pWin     );
  //double calcEntropiaCruzada(double &_distFact[] , double &_distPrevisao[]);

    //
    // recebe:
    // v   in  vetor de valores               (price)
    // vol in  vetor de pesos                 (volume)
    // dy  out vetor com os valores do eixo y  (nivel de soma dos pesos) volumes de cada preco
    // dx  out vetor com os valores do eixo x  (nivel dos valores)       precos
    //
    bool calcDist(const double &v[], const double &vol[], double &dy[], double &dx[], int tick=5){

          int lenV = ArraySize(v); // tamanho do vetor de valores
        //int lenD = ArraySize(d); // tamanho do vetor de ocorrencias

//      Print(":-| ",__FUNCTION__,": Encontrando o menor elemento...");
        int min = (int)v[ArrayMinimum(v)];
//      Print(":-| ",__FUNCTION__,": Encontrando o maior elemento...");
        int max = (int)v[ArrayMaximum(v)];

//      Print(":-| ",__FUNCTION__,": Redefinindo o tamanho do array da distribuicao...");
        ArrayResize(dy,max-min+tick+1);
        ArrayResize(dx,max-min+tick+1);
//      Print(":-| ",__FUNCTION__,": Inicializando o array da distribuicao...");
        ArrayInitialize(dy,0);
        ArrayInitialize(dx,0);

//      Print(":-| ",__FUNCTION__,": Calculando e alocando no array da distribuicao (eixo y)...");
        for( int i=0; i<lenV; i++ ){
            //Print("i:",i," v[i]:",v[i]," max:",max);
            // contabilizando somente quando altera o dado
            //if( v[i] != v[i-1] ){
                dy[ (int)(v[i]-min) ] += vol[i] ;
            //}
        }

//      Print(":-| ",__FUNCTION__,": Preenchendo o array com os valores a apresentar no eixo x...");
        int lenX = ArraySize(dx);
        for(int i=0; i<lenX; i++ ){
            dx[i] = i+min-tick ;
        }

        return true;
    }



    // retorna o indice da primeira ocorrencia de V no array A ou -1 se não encontrar.
    int ArraySearchSerial(const double &a[], const double v, const int sizeA){
        for(int i=0; i<sizeA; i++){ if(a[i]==v) return i;                   }
        return -1;
    }

    //
    // recebe:
    // v    in  vetor de valores               (price)
    // freq in  vetor de frequencias           (volume)
    // dy   out vetor com os valores do eixo y  (nivel de soma dos pesos) volumes de cada preco
    // dx   out vetor com os valores do eixo x  (nivel dos valores)       precos
    //
    bool calcDist2(const double &v[], const double &freq[], double &dy[], double &dx[]){

        int lenV = ArraySize(v); // tamanho do vetor de valores
        ArrayInitialize(dy,0);
        ArrayInitialize(dx,0);

        int posicao = 0;
        int lenDx   = ArraySize(dx);
        for( int i=0; i<lenV; i++ ){
            //if(v[i] == 0.0) continue;
            posicao = ArraySearchSerial(dx,v[i],lenDx);
            if(posicao == -1){
                ArrayResize(dx,++lenDx);
                ArrayResize(dy,  lenDx);
                dx[lenDx-1]  = v   [i]; // valor  acumulado pela primeira vez
                dy[lenDx-1]  = freq[i]; // volume acumulado pela primeira vez
            }else{
                dy[posicao] += freq[i]; // volume aumentando
            }
        }
        return true;
    }

    // v   in  vetor de valores
    // p   in  vetor de pesos
    // med out media                   momento 1
    // var out variancia               momento 2
    // sim out simetria (skewness)     momento 3
    // kur out kurtose                 momento 4
    // dp  out desvio padrao
    // cv  out coeficiente de variacao
    bool describe(double &v[], double &p[], double &med, double &var,double &sim, double &kur, double &dp, double &cv ){

        //1. calculando a media e a soma dos pesos...
        int len = ArraySize(v);
        double spv = 0; // soma dos pesos com os valores
        double sp  = 0; // soma dos pesos
        for(int i=0; i<len; i++){
            spv += v[i]*p[i];
             sp +=      p[i];
        }
        med = spv/sp;

        //2. calculando a soma dos desvios observados em relacao a media...
        double se2 = 0; // soma dos erros quadrados
        double se3 = 0; // soma dos erros cubicos
        double se4 = 0; // soma dos erros quartos
        for(int i=0; i<len; i++){
            se2 += pow( (v[i]-med), 2 )*p[i];
            se3 += pow( (v[i]-med), 3 )*p[i];
            se4 += pow( (v[i]-med), 4 )*p[i];
        }

        //3. calculando a variancia...
        var = se2/(sp-1.0);

        //4. calculando o desvio padrao...
        dp = sqrt(var);

        //5. calculando o coeficiente de variacao
        if(med==0)cv=0; else cv = dp/med;

        //6. calculando a simetria...
        sim = se3/(pow(dp,3)*sp);

        //7. calculando a kurtose...
        kur = se4/(pow(var,2)*sp);

        return true;
    }

    //-----------------------------------------------------------------------------
    // calcula o coefiente linear usando o metodo do minimos quadrados ordinarios
    // entrada:
    //-----------------------------------------------------------------------------
    // y : in  vetor de valores no eixo y
    // x : in  vetor de valores no eixo x
    // b0: out eh o b0 na funcao y(i)=b0 + b1x(i) - eh o intercepto
    // b1: out eh o b0 na funcao y(i)=b0 + b1x(i) - eh o coeficiente linear
    // r2: out eh o coeficiente de determinacao da regressao: eh a proporcao da
    //            variabilidade de y que eh explicada pela variabilidade de x.
    //            varia de zero a 1 e quanto mais proximo de 1, melhor eh o ajuste
    //            do modelo aos dados.
    //-----------------------------------------------------------------------------
    bool calcRegLin(double& y[], double& x[], double& b0, double& b1, double& r2, string& msg){

        // validando entrada...
        int len  = ArraySize(y);
        int lenX = ArraySize(x);
        if(len<3            ){msg=":-( modelo necessita mais de 2 eventos."; return false;}
        if(len>lenX         ){msg=":-( tamanho do eixo X:"+IntegerToString(lenX)+
                                  " nao corresponde ao tamanho do eixo Y:"+IntegerToString(len);
                              return false;}

        //MQO - minimos quadrados ordinarios
        //SQT - soma dos quadrados totais
        //SQE - soma dos quadrados estimados
        //SQR - soma dos quadrados dos residuos
        //SQT = SQE + SQR
        double sxy  = 0; // somatorio de x vezes y
        double sx   = 0; // somatorio de x
        double sy   = 0; // somatorio de y
        double sx2  = 0; // somatorio do quadrado de x
        double xbarra = 0;
        double ybarra = 0;
        for(int i=0; i<len; i++){
            sxy += (x[i]*y[i]);
            sx  += x[i];
            sy  += y[i];
            sx2 += pow(x[i],2);
        }

        if(sx2==0){msg=":-( somatorio de x2 eh zero. Nao eh possivel estimar a regressao";
                   Print(msg);
                   Print("Eixo Y"); ArrayPrint(y);
                   Print("Eixo X"); ArrayPrint(x);
                   return false;}

     // if(sx2==pow(sx,2)){msg=":-( somatorio de x2:"+ DoubleToString(sx)
     //                       +" eh igual ao quadrado do somatorio de x:"+ DoubleToString(pow(sx2,2))
     //                       +". Nao eh possivel estimar a regressao";
     //            Print("Eixo Y"); ArrayPrint(y);
     //            Print("Eixo X"); ArrayPrint(x);
     //            return false;}


        // calculando o b1...
        b1 = ( (len*sxy) - (sx*sy) )/( (len*sx2) - pow(sx,2) );

        // calculando a media de x e y...
        xbarra = sx/len;
        ybarra = sy/len;

        // calculando o b0...
        b0 = ybarra - (b1*xbarra);

        //calculando a soma dos quadrados...
        double sqt = 0;//soma dos quadrados totais
        double sqe = 0;//soma dos quadrados estimados
        double sqr = 0;//soma dos quadrados dos residuos
        for(int i=0; i<len; i++){
            sqt += pow(y[i]       - ybarra, 2);
            sqe += pow(b0+b1*x[i] - ybarra, 2);
            sqr += pow(y[i] - b0+b1*x[i]  , 2);
        }

        if(sqt==0){msg=":-( SQT eh zero. Nao eh possivel calcular r2";
                   Print(msg);
                   Print("Eixo Y"); ArrayPrint(y);
                   Print("Eixo X"); ArrayPrint(x);
                   return false;}

        // calculando r2...
        r2 = sqe/sqt;

        return true;
    }
    //-----------------------------------------------------------------------------

    //void calcCorrel(double& v1[], double& v2[]){ }


    bool testeNormal(const int n, const int pile, const int rep, double &v[]){
        // 1. gerar pile numeros aleatorios no intervalo 0...n
        // 2. calcular a media dos 5 e ordenar no vetor de tamanho rep
        // 3. apresentar o histograma do vetor rep

        ArrayResize(v,n); ArrayInitialize(v,0);
        int acum = 0;
        int med  = 0;
        //MathSrand( GetTickCount() );
        MathSrand( n/2 );

        for(int i=0; i<rep; i++ ){

            // gerando pile numeros aleatorios no intervalo 0..n
            acum = 0;
            for(int j=0; j<pile; j++){
                acum += ( rand()%n );
            }

            med = acum/pile;  // calculando a media.
            v[med]++;         // acumulando a quantidade na posicao da media
        }

        return true;
    }
    double calcZscore(double &X[]){
        int    len    = ArraySize(X); if(len==0) return 0;
        double media  = calcMedia(X);
        double std    = sqrt( calcVariancia(X) ); if(std==0) return 0;
        int    i      = ArraySize(X)-1; 
        double zscore = (X[i]-media)/std; // calcula o zscore do ultimo elemento do vetor X
        return zscore;
    }

    double calcVariancia(double &X[]){
        int    len   = ArraySize(X); if(len==0) return 0;
        double media = calcMedia(X);

        // soma dos desvios quadrados...
        double sd2 = 0;
        for (int i = 0; i < len; i++) { sd2 = pow((X[i] - media), 2); }

        return sd2/len;
    }

    double calcMedia(double &X[]){
        int    len   = ArraySize(X); if(len==0) return 0;
        double media = sum(X)/len;
        return media;
    }

    double sum(double &X[]){
        int    len  = ArraySize(X);
        double soma = 0;
        for(int i=0; i<len; i++){soma+=X[i];}
        return soma;
    }


    //+---------------------------------------------------------------------------------------+
    //|                                                                                       |
    //| Calcula o Payout baseado no total acumulado de perdas e total acumuldo de ganhos.     |
    //|                                                                                       |
    //+---------------------------------------------------------------------------------------+
    bool calcPayOut(const double _lossAcum, const double _winAcum, double &_payOut){
        // calculando o Payout...
        if( _lossAcum != 0 ){
            _payOut = _winAcum/MathAbs(_lossAcum);
        }else{
            _payOut = 1; // Quando ainda nao tem perda no dia, fica em 100% por enquanto ateh eu melhorar o entendimento.
        }
        return true;
    }

    //+------------------------------------------------------------------+
    //|                                                                  |
    //| Calcula a probabilidade de acertos, baseado na quantidade de     |
    //| transacoes vencedoras a perdedoras.                              |
    //|                                                                  |
    //+------------------------------------------------------------------+
    bool calcProbWin(const double _qtdLoss, const double _qtdWin, double &_pWin){
        if( _qtdWin>0 ){
            _pWin = _qtdWin / (_qtdWin+_qtdLoss);
        }else{
            _pWin = 0;
        }
        return true;
    }


    //+------------------------------------------------------------------+
    //|                                                                  |
    //| Calcula o coeficiente de Kelly.                                  |
    //|                                                                  |
    //| Definicao: Percentual maximo de capital a ser alocado a cada     |
    //|            trade.                                                |
    //|                                                                  |
    //| Forrmula:                                                        |
    //| K = ( P.B - (1-P) ) / B                                          |
    //|                                                                  |
    //| sendo:                                                           |
    //| K = Coefiente de Kelly.                                          |
    //| P = Probabilidade de acerto.                                     |
    //| B = Payout.                                                      |
    //|                                                                  |
    //+------------------------------------------------------------------+
    bool calcCoefKelly(const double _payOut, const double _probWin, double &_coefKelly){

       if( _payOut != 0 ){
           _coefKelly = ( (_probWin*_payOut) - (1-_probWin) ) / _payOut;
       }else{
           _coefKelly = 0;
       }
       return true;
    }

    bool calcCoefKelly(const double _qtdLoss , const double _qtdWin ,
                              const double _lossAcum, const double _winAcum, double &_coefKelly){

        double payOut;
        calcPayOut(_lossAcum,_winAcum,payOut);

        double probWin;
        calcProbWin(_qtdLoss,_qtdWin,probWin);

        return calcCoefKelly(payOut,probWin,_coefKelly);
    }


    double calcEntropiaCruzada(double &_distFact[] , double &_distPrevisao[]){

        int len = ArraySize(_distFact);
        double H = 0;

        for( int i=0; i<len; i++ ){ H += _distFact[i]*log(_distPrevisao[i]); }

        return -H;
    }


};