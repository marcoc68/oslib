# oslib
 oslib mql5
 
 Projeto abriga Expert Advisors e Indicadores que funcionam na plataforma Metatrader 5.


## Obtenha os fontes do projeto.
1. Instale o git no computador ou baixe o projeto no gitHub.
2. Os comandos abaixo supõe que a pasta onde você guarda seus projetos do github é `c:\git\`. Execute-os nesta sequência:
<pre><code>
    c:
    cd c:\git\
    git clone https://github.com/marcoc68/oslib.git
</code></pre>

## Como configurar o projeto.
1. **Compilação**: execute este comando na pasta `Include` do terminal metatrader.
   
    `mklink /D oslib c:\git\oslib`

2. **Experts**: execute este comando na pasta `Experts` do terminal.
   
   `mklink /D oslib-ose c:\git\oslib\ose`

3. **Indicadores**: execute este comando na pasta `Indicators` do terminal.
   
   `mklink /D oslib-osi c:\git\oslib\osi`

4. **Services**: execute este comando na pasta `Services` do terminal.
   
   `mklink /D oslib-svc c:\git\oslib\svc`

5. **Scripts**: execute estes comandos na pasta `Scripts` do terminal.
   
   `mklink /D oslib-scr c:\git\oslib\scr`
   
   `mklink /D oslib-tst c:\git\oslib\tst`

## Documentação
### Indicadores
[Indicador Volume Profile.](https://github.com/marcoc68/oslib/blob/sprint-202202/doc/indicador-volume-profile.pdf)







Este indicador mostra 3 linhas no gráfico de preços:
1. **POC ou Point of Control:** Linha amarela com o maior volume negociado no periodo configurado. 
2. **VAH ou Value Area High:**  Linha verde definindo o limite superior de 68% do volume negociado no período configurado. 
3. **VAL ou Value Area Low:**   Linha vermelha definindo o limite inferior de 68% do volume negociado no período configurado. 
![image](https://user-images.githubusercontent.com/5843284/154157848-4298c217-b3a8-4717-9a7a-9e702c714f90.png)


## Preparando Volume Profile para execução:

### Primeiro Passo:  Compilar
1. No terminal `Metatrader`, clique no icone do `Metaeditor` na barra de tarefas:![image](https://user-images.githubusercontent.com/5843284/154847431-6bfd8cd1-0ca5-45a8-8305-17df764f3d9e.png)

2. No painel lateral esquerdo do Metaeditor, acesse a pasta `MQL5\Include\oslib\osi\`:
![image](https://user-images.githubusercontent.com/5843284/154162731-d53b6284-7f81-4e35-8db6-3945bc0b8008.png).
 
3. Dentro da pasta `osi`, clique com o botão direito no arquivo `osi-03-22-00-vol-profile.mq5` e escolha a opção `Compilar`.
![image](https://user-images.githubusercontent.com/5843284/154162012-84c92a95-2824-4c2e-aaf4-e70bfd063e71.png)

4. O resultado esperado da compilação é zero erros e zero warnings.
![image](https://user-images.githubusercontent.com/5843284/154847012-14ceba48-e802-4449-b85d-dc96400f0d03.png)

### Segundo Passo: Executar
Após a compilação ter ocorrido com sucesso, o indicador estará disponível para execução pelo terminal Metatrader e não será necessário compilar novamente, bastando executar pelo terminal conforme os passos abaixo:

1. No painel `Navegador` vá em `Indicadores/oslib-osi`. Localize o indicador `osi-03-22-00-vol-profile` e dê duplo clique no mesmo. **Atenção**: deverá haver um gráfico aberto antes de executar esta ação.

![image](https://user-images.githubusercontent.com/5843284/154868091-beae65c2-bc18-42fa-aca5-8eb39b01f497.png)


2. Abaixo aparece a lista de parâmetros que podem ser modificados.
![image](https://user-images.githubusercontent.com/5843284/154869292-0c10eb46-9021-46cf-b89f-ead30818ba33.png)

**Qtd barras historicas a processar:** Até que a performance do indicador seja melhorada, rcomendamos não usar valores maiores que 60 neste parâmetro.

**Qtd barras acumuladas usadas no calculo do volume profile:** O cálculo do volume profile de cada barra é feito sobre esta quantidade de barras anteriores.
