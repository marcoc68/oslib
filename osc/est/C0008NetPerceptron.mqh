﻿//+------------------------------------------------------------------+
//|                                            C0008NetPerceptron.mqh|
//|                               Copyright 2021,oficina de software.|
//|                                 http://www.metaquotes.net/marcoc.|
//|                                                                  |
//|   Perceptron.                                                    |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "2020, Oficina de Software."
#property link      "http://www.os.net"

//#include <Math\Alglib\dataanalysis.mqh>
#include <Math\Stat\Normal.mqh> 
#include <oslib\osc\osc-mat.mqh>

class C0008NetPerceptron{

private:
protected:
public:

    // sigmoid / activation function
    double sigmoid(double x){ return 1/(1+exp(-x)); }

    // sigmoid / activation function
    void sigmoid(double &X[], double &SIG[]){ 
        int size = ArraySize(X);
        ArrayResize(SIG,size);        
        for( int i=0; i<size; i++){ SIG[i]=sigmoid(X[i]); }
    }
    
    //def sigmoid_prime(x):
    //    return sigmoid(x) * (1-sigmoid(x))
    double sigmoid_prime(double x){ return sigmoid(x) * (1-sigmoid(x)); }

    void sigmoid_prime(double &X[], double &SIG[]){
        int size = ArraySize(X);
        ArrayResize(SIG,size);
        for( int i=0; i<size; i++){ SIG[i]=sigmoid_prime(X[i]); }
    }
    
    
    //+-------------------------------------------------------------------------------------+
    //|   Neuron calculation function                                                       |
    //|   recebe:                                                                           |
    //|   X[] : vetor de features(termos X da funcao de entrada).                           |
    //|   W[] : vetor de pesos W para cada feature de entrada x.                            |
    //|   bias: termo constante da funcao de entrada.                                       |
    //|                                                                                     |
    //|   faz:                                                                              |
    //|   calcula a previsao do perceptron como  sigmoid ( x1w1 + x2w2 +...+ xnwn + bias )  |
    //|                                                                                     |
    //+-------------------------------------------------------------------------------------+
    double fnet(double &X[],double &W[], double bias){
        //--- variable for storing the weighted sum of inputs
        double y_hat=0.0;
        int nfeatures = ArraySize(X);
        
        //--- Using a loop we obtain the weighted sum of inputs based on the number of inputs
        for(int n=0;n<nfeatures;n++){ y_hat+=X[n]*W[n]; }
        
        //--- add bias to prediction
        y_hat += bias;
        
        //--- send the weighted sum of inputs to the activation function and return its value
        return sigmoid(y_hat);
    }

    //+-------------------------------------------------------------------------------------+
    //|   Neuron calculation function                                                       |
    //|   recebe:                                                                           |
    //|   X[][] : matriz de features(termos X da funcao de entrada). Cada linha eh um vetor |
    //|           de features.                                                              |
    //|   W[]   : vetor de pesos W para cada feature de entrada x.                          |
    //|   bias  : termo constante da funcao de entrada.                                     |
    //|                                                                                     |
    //|   faz:                                                                              |
    //|   calcula a previsao do perceptron como sigmoid ( x1w1 + x2w2 +...+ xnwn + bias )   |
    //|   para cada linha do vetor de features. Grava o resultado no vetor yhat.            |
    //|                                                                                     |
    //+-------------------------------------------------------------------------------------+
    void fnet(double &X[][],double &W[], double bias, double &yhat[]){
        //--- variable for storing the weighted sum of inputs
        double y_hat=0.0;
        int nfeatures = ArrayRange(X,1); // qtd de colunas na matriz de features
        int npoints   = ArrayRange(X,0); // qtd de linhas  na matriz de features
        
        ArrayResize(yhat,npoints); ArrayInitialize(yhat,0);

        for(int lin=0; lin<npoints; lin++){
            //--- Using a loop we obtain the weighted sum of inputs based on the number of inputs
            y_hat = 0;
            for(int n=0;n<nfeatures;n++){ y_hat+=X[lin][n]*W[n]; }
            //--- add bias to prediction
            y_hat += bias;
            
            //--- send the weighted sum of inputs to the activation function and return its value
            yhat[lin] = sigmoid(y_hat);
        }
        
    }
    
    //+-------------------------------------------------------------------------------------+
    //|   Error function                                                                    |
    //|   recebe:                                                                           |
    //|   y   : valor de fato (alvo).                                                       |
    //|   y_hat:valor previsto pelo perceptron.                                             |
    //|                                                                                     |
    //|   faz:                                                                              |
    //|   calcula e retorna o erro segundo a formula: -y*log(y_hat)-(1-y)*log(1-y_hat)      |
    //|                                                                                     |
    //+-------------------------------------------------------------------------------------+
    double ferror(double y, double y_hat){ return -y*log(y_hat)-(1-y)*log(1-y_hat); }
    
    //+-------------------------------------------------------------------------------------+
    //|   Error function with L1 regularization                                             |
    //|   recebe:                                                                           |
    //|   y   : valor de fato (alvo).                                                       |
    //|   y_hat:valor previsto pelo perceptron.                                             |
    //|                                                                                     |
    //|   faz:                                                                              |
    //|   calcula e retorna o erro segundo a formula:                                       |
    //|   -y*log(y_hat)-(1-y)*log(1-y_hat)- lambda(|W1|+...+|Wn|)                           |
    //|                                                                                     |
    //+-------------------------------------------------------------------------------------+
    double ferror_L1(double y, double y_hat, double lambda, double &W[]){
        return ferror(y,y_hat) - lambda*osc_mat::sumabs(W);
    }
    
    //+-------------------------------------------------------------------------------------+
    //|   Error function with L2 regularization                                             |
    //|   recebe:                                                                           |
    //|   y   : valor de fato (alvo).                                                       |
    //|   y_hat:valor previsto pelo perceptron.                                             |
    //|                                                                                     |
    //|   faz:                                                                              |
    //|   calcula e retorna o erro segundo a formula:                                       |
    //|   -y*log(y_hat)-(1-y)*log(1-y_hat)- lambda(W1(2)+...+Wn(2) )                        |
    //|                                                                                     |
    //+-------------------------------------------------------------------------------------+
    double ferror_L2(double y, double y_hat, double lambda, double &W[]){
        return ferror(y,y_hat) - lambda*osc_mat::sumpow(W,2);
    }
    
    //+-------------------------------------------------------------------------------------+
    //|   Error function                                                                    |
    //|   recebe:                                                                           |
    //|   Y[] : vetor de valores de fato (alvo).                                            |
    //|   YHAT: vetor de valores previstos pelo perceptron.                                 |
    //|                                                                                     |
    //|   faz:                                                                              |
    //|   calcula e retorna o erro segundo a formula: -y*log(y_hat)-(1-y)*log(1-y_hat)      |
    //|                                                                                     |
    //+-------------------------------------------------------------------------------------+
    void ferror(double &Y[], double &YHAT[], double &RESULT[]){
        double ONE_MINUS_Y     []; osc_mat::sub  (1,Y   ,ONE_MINUS_Y   );
        double ONE_MINUS_YHAT  []; osc_mat::sub  (1,YHAT,ONE_MINUS_YHAT);
        double     MINUS_Y     []; osc_mat::times(Y,-1  ,    MINUS_Y   );
        
        double LOG_YHAT        []; MathLog(YHAT          ,LOG_YHAT        );
        double LOG_1_MINUS_YHAT[]; MathLog(ONE_MINUS_YHAT,LOG_1_MINUS_YHAT);
        
        double PRIM_VET[]; if(!osc_mat::dot(MINUS_Y    ,LOG_YHAT        ,PRIM_VET)) Print(":( ERRO GRAVE -0001");
        
        //Print("Y:");
        //ArrayPrint(Y,3);
        //Print("ONE_MINUS_Y:");
        //ArrayPrint(ONE_MINUS_Y,3);
        //Print("YHAT:");
        //ArrayPrint(YHAT,3);
        //Print("\nLOG_1_MINUS_YHAT:");
        //ArrayPrint(LOG_1_MINUS_YHAT,3);
        
        double SEC_VET []; if(!osc_mat::dot(ONE_MINUS_Y,LOG_1_MINUS_YHAT,SEC_VET )) Print(":( ERRO GRAVE -0002");
        
        osc_mat::sub(PRIM_VET,SEC_VET, RESULT);
        
        //return -y*log(y_hat)-(1-y)*log(1-y_hat);
    }

    //+-------------------------------------------------------------------------------------+
    //|   Error function with L1 regularization                                             |
    //|   recebe:                                                                           |
    //|   Y[] : vetor de valores de fato (alvo).                                            |
    //|   YHAT: vetor de valores previstos pelo perceptron.                                 |
    //|                                                                                     |
    //|   faz:                                                                              |
    //|   calcula e retorna o erro segundo a formula:                                       |
    //|   -y*log(y_hat)-(1-y)*log(1-y_hat) -lambda(|W1|+...+|Wn|)                           |
    //|                                                                                     |
    //+-------------------------------------------------------------------------------------+
    void ferror_L1(double &Y[], double &YHAT[], double lambda, double &W[], double &RESULT[]){
        ferror(Y,YHAT,RESULT);
        double l1 = lambda * osc_mat::sumabs(W);
        osc_mat::sub1(RESULT,l1);
    }

    //+-------------------------------------------------------------------------------------+
    //|   Error function with L2 regularization                                             |
    //|   recebe:                                                                           |
    //|   Y[] : vetor de valores de fato (alvo).                                            |
    //|   YHAT: vetor de valores previstos pelo perceptron.                                 |
    //|                                                                                     |
    //|   faz:                                                                              |
    //|   calcula e retorna o erro segundo a formula:                                       |
    //|   -y*log(y_hat)-(1-y)*log(1-y_hat) -lambda(W1(2)+...+Wn(2) )                        |
    //|                                                                                     |
    //+-------------------------------------------------------------------------------------+
    void ferror_L2(double &Y[], double &YHAT[], double lambda, double &W[], double &RESULT[]){
        ferror(Y,YHAT,RESULT);
        double l2 = lambda * osc_mat::sumpow(W,2);
        osc_mat::sub1(RESULT,l2);
    }

    //# TODO: Write the error term formula
    //def error_term_formula(x, y, output):
    //    #for binary cross entropy loss
    //    #return (y - output)*x
    //    
    //    #for mean square error
    //    return (y - output)*sigmoid_prime(x)
    //+-------------------------------------------------------------------------------------+
    //|   Error function                                                                    |
    //|   recebe:                                                                           |
    //|   X   : vetro de features.                                                          |
    //|   y   : valor do alvo.                                                              |
    //|   yhat: valor da previsao.                                                          |
    //|   ERROR_TERM: vetor que conterah os erros de cada termo calculado                   |
    //|   faz:                                                                              |
    //|   calcula e retorna o erro segundo a formula: (y - yhat)*sigmoid_prime(X)           |
    //|                                                                                     |
    //+-------------------------------------------------------------------------------------+
    void ferror_term(double &X[], double y, double yhat, double &ERROR_TERM[]){ 
        int size = ArraySize(X);
        sigmoid_prime(X,ERROR_TERM);
        double erro = y-yhat;
        for(int i=0; i<size; i++){ ERROR_TERM[i] = erro*ERROR_TERM[i]; }
    }
    
    //+-------------------------------------------------------------------------------------+
    //|   Atualiza os pesos em funcao do erro.                                              |
    //|   recebe:                                                                           |
    //|   X[] : vetor de features(termos X da funcao de entrada).                           |
    //|   W[] : vetor de pesos W para cada feature de entrada x. Serah atualizado aqui.     |
    //|   bias: termo constante da funcao de entrada.            Serah atualizado aqui.     |
    //|   y   : alvo.                                                                       |
    //|   learnrate: taxa de aprendizado.                                                   |
    //|                                                                                     |
    //|   faz:                                                                              |
    //|   calcula e atualiza novos pesos e novo bias. Usa as formulas:                      |
    //|   Wi --->  Wi   + alfa*(y-y_hat)*Xi                                                 |
    //|   bias-->  bias + alfa*(y-y_hat)                                                    |
    //|                                                                                     |
    //+-------------------------------------------------------------------------------------+
    void update_weights(double &X[], double &W[], double &bias, double y, double learnrate){

        // calculando a diferenca entre o alvo e a previsao de fnet...
        double y_minus_y_hat = y-fnet(X,W,bias);
        
        // atualizando os pesos das features em funcao do erro e da taxa de aprendizado...
        for(int i=0; i<ArraySize(W); i++){ W[i] = W[i] + learnrate*y_minus_y_hat*X[i]; }
        
        // atualizando o bias...
        bias = bias + learnrate*y_minus_y_hat;
        
    }
    
    //+-------------------------------------------------------------------------------------+
    //|   Treinamento do perceptron.                                                        |
    //|   recebe:                                                                           |
    //|   FEATURES[][]:vetor de features. Cada coluna eh uma feature.                       |
    //|   Y[]        : vetor de alvos.                                                      |
    //|   epochs     : quantidade de jobs de treinamento.                                   |
    //|   learnrate  : taxa de aprendizado                                                  |
    //|   graph_lines: se plota grafico com o resultado do aprendizado.                     |
    //|                                                                                     |
    //|   faz:                                                                              |
    //|   calcula e atualiza novos pesos e novo bias. Usa as formulas:                      |
    //|   Wi --->  Wi   + alfa*(y-y_hat)*Xi                                                 |
    //|   bias-->  bias + alfa*(y-y_hat)                                                    |
    //|                                                                                     |
    //+-------------------------------------------------------------------------------------+
    //def train(features, targets, epochs, learnrate, graph_lines=False):
    bool train(double &FEATURES[][], double &Y[], int epochs=100, double learnrate=0.1, bool graph_lines=false){

        // determinando a quantidade de pontos e a quantidade de features...
        //n_records, n_features = features.shape
        int    npoints   = ArrayRange(FEATURES,0); // cada linha  eh um  ponto (exemplo)
        int    nfeatures = ArrayRange(FEATURES,1); // cada coluna eh uma feature
        
        // matriz com os erros...
        double ERRORS[]; ArrayResize(ERRORS,epochs);

        // matriz com as features de uma linha...
        double X[]; ArrayResize(X,nfeatures);
        
        double last_loss = 0;
        
        // inicializando o vetor de pesos...
        // scale: desvio padrao
        // size : tamanho da distribuicao (do vetor de saida)
        //weights = np.random.normal(scale=1 / n_features**.5, size=n_features)
        double WEIGHTS[]; ArrayResize(WEIGHTS,nfeatures);
        if( !MathRandomNormal(0,1/pow(nfeatures,0.5),nfeatures,WEIGHTS) ){Print(__FUNCTION__," :ERRO INESPERADO -0001"); return false;}
        
        // iniciando com bias zero...
        double bias = 0;
        //double y_hat,error;
        double OUT[];
        double LOSS[], loss;
        double PREDICTIONS[];
        double ACCURACY[], accuracy;
        //double X[];
        //for e in range(epochs):
        for(int e=1; e<=epochs; e++){ // uma passada para cada epoca do treinamento...
            //del_w = np.zeros(weights.shape) // nao estah sendo usado...
            //for x, y in zip(features, targets):
            for(int i=0; i<npoints; i++){ // uma passada pra cada linha do conjunto de treinamento...
                //output = output_formula(x, weights, bias)

                osc_mat::getline(FEATURES,i,X);
                //y_hat = fnet(X,WEIGHTS,bias); // nao estah sendo usado...
                
                //error = error_formula(y, output)
                //error = ferror(Y[i],y_hat);             // nao estah sendo usado...
                
                //weights, bias = update_weights(x, y, weights, bias, learnrate)
                update_weights(X,WEIGHTS,bias,Y[i],learnrate);
            }
            //# Printing out the log-loss error on the training set
            //out = output_formula(features, weights, bias)
            fnet(FEATURES,WEIGHTS,bias,OUT); // aplicando fnet a toda base de features. Atualiza OUT que eh um vetor de yhats...
            
            //loss = np.mean(error_formula(targets, out))
            ferror(Y, OUT, LOSS); loss = MathMean(LOSS);
            
            //errors.append(loss);
            ERRORS[e-1] = loss;
            
            //if e % (epochs / 10) == 0:
            if(e % (epochs / 10) == 0){
                Print("\n========== Epoch", e,"==========");
                
                if( last_loss!=0 && last_loss < loss ){
                    Print("Train loss: ", loss, "  WARNING - Loss Increasing");
                }else{
                    Print("Train loss: ", loss);
                }
                last_loss = loss;
                
                //predictions = out > 0.5
                osc_mat::greatherthan(OUT,0.5,PREDICTIONS);
                
                //accuracy = np.mean(predictions == targets)
                osc_mat::equals(PREDICTIONS,Y,ACCURACY); accuracy = MathMean(ACCURACY);
                
                Print("Accuracy: ", accuracy);

                Print("YHAT:");
                ArrayPrint(OUT,2);
                            
            }
            
            //if graph_lines and e % (epochs / 100) == 0:
            //    display(-weights[0]/weights[1], -bias/weights[1])
        }        
    
        //# Plotting the solution boundary
        //plt.title("Solution boundary")
        //display(-weights[0]/weights[1], -bias/weights[1], 'black')
    
        //# Plotting the data
        //plot_points(features, targets)
        //plt.show()
    
        //# Plotting the error
        //plt.title("Error Plot")
        //plt.xlabel('Number of epochs')
        //plt.ylabel('Error')
        //plt.plot(errors)
        //plt.show()       
        
        return true; 
    }
    
    //+-------------------------------------------------------------------------------------+
    //|   Treinamento do perceptron.                                                        |
    //|   recebe:                                                                           |
    //|   FEATURES[][]:vetor de features. Cada coluna eh uma feature.                       |
    //|   Y[]        : vetor de alvos.                                                      |
    //|   epochs     : quantidade de jobs de treinamento.                                   |
    //|   learnrate  : taxa de aprendizado                                                  |
    //|   graph_lines: se plota grafico com o resultado do aprendizado.                     |
    //|                                                                                     |
    //|   faz:                                                                              |
    //|   calcula e atualiza novos pesos e novo bias. Usa as formulas:                      |
    //|   Wi --->  Wi   + alfa*(y-y_hat)*Xi                                                 |
    //|   bias-->  bias + alfa*(y-y_hat)                                                    |
    //|                                                                                     |
    //|   Retorna:                                                                          |
    //|   WEIGHTS[] vetor de pesos da rede treinada.                                        |
    //+-------------------------------------------------------------------------------------+
    //def train(features, targets, epochs, learnrate, graph_lines=False):
    bool train_nn(double &FEATURES[][], double &Y[], double &WEIGHTS[], int epochs=100, double learnrate=0.1){
    //def train_nn(features, targets, epochs, learnrate):
        
        // determinando a quantidade de pontos e a quantidade de features...
        //n_records, n_features = features.shape
        int npoints   = ArrayRange(FEATURES,0); // cada linha  eh um  ponto (exemplo)
        int nfeatures = ArrayRange(FEATURES,1); // cada coluna eh uma feature
        
        // inicializando o vetor de pesos...
        // scale: desvio padrao
        // size : tamanho da distribuicao (do vetor de saida)
        //# Use to same seed to make debugging easier
        //np.random.seed(42)
        //# Initialize weights
        //weights = np.random.normal(scale=1 / n_features**.5, size=n_features)
                          ArrayResize(WEIGHTS,nfeatures);
        double DEL_W  []; ArrayResize(DEL_W  ,nfeatures);
        if( !MathRandomNormal(0,1/pow(nfeatures,0.5),nfeatures,WEIGHTS) ){Print(__FUNCTION__," :ERRO INESPERADO -0001"); return false;}

        //last_loss = None
        double last_loss = 0;
        double      loss = 0;

        // matriz com os erros...
        double ERROR[];
        double ERROR_TERM[];
        double ERROR_TERM_TIMES_X[];
        double TMP[], YHAT[];

        // matriz com as features de uma linha...
        double X[]; ArrayResize(X,nfeatures);

        double yhat,error;


        double PREDICTIONS[];
        double ACCURACY[], accuracy;
                
        //for e in range(epochs):
        for(int e=1; e<=epochs; e++){ // uma passada para cada epoca do treinamento...
            //del_w = np.zeros(weights.shape)
            ArrayInitialize(DEL_W,0); 
            
            //for x, y in zip(features.values, targets):
            //    # Loop through all records, x is the input, y is the target
            for(int i=0; i<npoints; i++){ // uma passada pra cada linha do conjunto de treinamento...
                osc_mat::getline(FEATURES,i,X);

                //# Activation of the output unit
                //#   Notice we multiply the inputs and the weights here 
                //#   rather than storing h as a separate variable 
                //output = sigmoid(np.dot(x, weights))
                yhat = sigmoid( osc_mat::dot(X,WEIGHTS) );
    
                //# The error, the target minus the network output
                //error = error_formula(y, output)
                //error = ferror(Y[i],yhat);
                error = ferror_L2(Y[i],yhat,learnrate,WEIGHTS);
    
                //# The error term
                //error_term = error_term_formula(x, y, output)
                //#print("error_term:",error_term)
                ferror_term(X,Y[i],yhat,ERROR_TERM);
    
                //# The gradient descent step, the error times the gradient times the inputs
                //del_w += error_term * x
                osc_mat::dot(ERROR_TERM,X,ERROR_TERM_TIMES_X);
                osc_mat::sum1(DEL_W,ERROR_TERM_TIMES_X);
                
            }
            //# Update the weights here. The learning rate times the 
            //# change in weights, divided by the number of records to average
            //weights += learnrate * del_w / n_records
            osc_mat::mul1(DEL_W,npoints/learnrate);
            osc_mat::sum1(WEIGHTS,DEL_W);
    
            //# Printing out the mean square error on the training set
            //if e % (epochs / 10) == 0:
            if(e % (epochs / 10) == 0){
                //out = sigmoid(np.dot(features, weights))
                osc_mat::dot(FEATURES,WEIGHTS,TMP);
                sigmoid(TMP,YHAT);
                
                //loss = np.mean((out - targets) ** 2)
                osc_mat::sub(Y,YHAT,ERROR);
                MathPow(ERROR,2);
                loss = MathMean(ERROR);
                
                Print("Epoch:", e);
                if (last_loss!=0 && last_loss < loss){
                    Print("Train loss: ", loss, "  WARNING - Loss Increasing");
                }else{
                    Print("Train loss: ", loss);
                }
                last_loss = loss;

                //predictions = out > 0.5
                osc_mat::greatherthan(YHAT,0.5,PREDICTIONS);
                
                //accuracy = np.mean(predictions == targets)
                osc_mat::equals(PREDICTIONS,Y,ACCURACY); accuracy = MathMean(ACCURACY);
                
                Print("Accuracy: ", accuracy);

                Print("YHAT:");
                ArrayPrint(YHAT,2);
                Print("PREDICTIONS:");
                ArrayPrint(PREDICTIONS,2);

                Print("=========");
            }
        }
        
        Print("Finished training!");
        return true;
        //return weights
    }
  
};