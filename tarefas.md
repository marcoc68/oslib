  755 ganhos
 -531 perdas
= 224
- 560 tarifas
=-336 liquido

- aumentar em 1 real o valor das tarifas (teste) OK
- resolver o erro que quebra o EA                OK
- resolver as ordens duplicadas                  OK
  - parece que, apos a concretizacao da ordem de abertura, é feito novo pedido de abertura achando que nao ha posicao aberta.
- resolver o cancelamento de ordens de entrada (ordens estao ficando sem cancelar)          OK
- transforme EA_TOLERANCIA_ENTRADA em parametro. Veja se pode usar, nivel entrada mais 1;   OK


commit 20220607
os-lib: acrescentada a função TimeMscToString
oslib-include: acrescentadas funcoes e constantes
osc-minion-trade-03: acrscentado o metodo manterOrdemLimitadaNoRoom
osc-book: acrescentado suporte para usar ateh 32 niveis do book de ofertas
C0004GerentePosicao: passa a salvar o ticket da ordem de abertura no comentario da ordem de fechamento (doCloseOposite)
ose-p7-004-003-06-ns: usando velocidade do volume; usando doCloseOposite somente quando é o fechamento de uma posicao;


### ose-p8-001-000-pairs-spread.mq5
#### FASE 2
1. Acrescente opção de saida (stop) qd o spread médio alcançar o (spread + desvio padrão) registrado na abertura da posição.
2. Acrescente opção de abertura/fechamento de posição ao pressionar conjunto de teclas. Ex: CTRL+ALT+A / CTRL+ALT+F.
3. Acrescente opção de fechamento de posição antes do spred atual alcançar o spread médio. Ex: Abre posição a 2dp de distância e fecha a 0,5dp de distância.
4. Acrescente opção para não operar automaticamente. Nesse caso não deve abrir nem fechar posição automática, mas deve permanecer abrindo/fechando posição por pressionamento de tclas(item 2). Também deve logar que ação faria se estivesse operando automaticamente.
5. Acrescente opção para calcular o volume mínimo ideal que deve ser operado em cada par para que aconteça o equilíbrio financeiro. Esse volume mínimo será apenas uma sugestão e deve ser descrito no log, na execução do OnInit.
6. Construa uma arquivo mqh com funções utilitárias, que podem ser usadas em outros EAs. Ex: normalizarVolume, digitosDoPasso, etc. Passe as funções deste tipo para este arquivo de funções utilitárias.

#### FASE 3
1. Acrescentar opção para informar o volume de cada ativo separadamente. ok
2. Acrescentar opção para informar a correção e a cointegração do par sendo negociado.
3. Nas entradas após um nível de desvio padrão, caso o spread vá pra dentro do desvio padrão anterior e depois volte a cruzar o ponto de entrada, deve abrir nova posição, até um máximo de X vezes informado em parãmetro.
   1. Essas posições, abertas manualmente, devem ser fechadas automaticamente, junto com as demais, quando o spread voltar a média dos spreads.
   2. Nesse caso, o novo spred médio da entrada na posição deve ser a média entre o spread médio de entrada anterior e o atual.
========================================================================================================================

SUPORTE A ATIVOS INVERSAMENTE CORRELACIONADOS (ver estudo abaixo)
=================================================================
Na negociação por pares (*pairs trading*) com **correlação inversa** (negativa), a lógica operacional e a formulação matemática do *spread* mudam em comparação aos ativos diretamente correlacionados.

Enquanto na correlação direta os ativos tendem a caminhar juntos (o que nos leva a usar a **diferença** de preços), na correlação inversa os ativos tendem a se mover em **direções opostas**. Portanto, o equilíbrio de longo prazo é modelado por meio da **soma** ponderada dos preços, e não pela subtração.

Abaixo está o detalhamento de como funciona a lógica operacional e como você deve operar nesse cenário:

---

### 1. A Formulação do *Spread* Inverso

Para ativos com correlação positiva, o *spread* clássico é dado por $S = Ativo_A - (\beta \times Ativo_B)$.

Para ativos com **correlação inversa**, a relação de cointegração que permanece estacionária ao redor de uma média é a **soma** dos ativos:


$$\text{Spread} = Ativo_A + (\beta \times Ativo_B)$$


*Se um ativo sobe, o outro historicamente cai na proporção $\beta$, mantendo a soma estável.*

---

### 2. Regras de Operação quando há Correlação Inversa

Como o parâmetro de monitoramento é a soma dos ativos, os desvios em relação à média indicam comportamentos anômalos onde ambos subiram ou caíram juntos, violando a correlação inversa temporariamente.

#### A. Spread Abaixo da Média (Ambos deprimidos conjuntamente)

* **O que significa:** O valor combinado dos dois ativos caiu abaixo da média histórica. Isso acontece quando ambos os ativos perderam valor ao mesmo tempo, ou um caiu muito e o outro não subiu o suficiente para compensar.
* **Como operar:** A expectativa da reversão à média indica que a soma deve subir novamente.
* **Ação:** **Comprar ambos os ativos** (montar uma posição *long* combinada na cesta) e aguardar o reajuste para fechar a posição com lucro quando o *spread* retornar à média.

#### B. Spread Acima da Média (Ambos inflados conjuntamente)

* **O que significa:** O valor combinado dos dois ativos disparou acima da média histórica. Isso ocorre quando ambos subiram simultaneamente, violando a regra de que deveriam se mover em direções opostas.
* **Como operar:** A expectativa é que a exuberância conjunta se dissipe e a soma retorne ao patamar de equilíbrio.
* **Ação:** **Vender a descoberto ambos os ativos** (montar uma posição *short* combinada na cesta) e recomprá-los mais baratos quando o *spread* convergir.

---

### Resumo Comparativo

| Tipo de Correlação | Equação do *Spread* | Spread Acima da Média | Spread Abaixo da Média |
| --- | --- | --- | --- |
| **Direta** ($r \approx +1$) | Diferença ($A - \beta B$) | Vender $A$ / Comprar $B$ | Comprar $A$ / Vender $B$ |
| **Inversa** ($r \approx -1$) | Soma ($A + \beta B$) | Vender ambos ($Short$) | Comprar ambos ($Long$) |
