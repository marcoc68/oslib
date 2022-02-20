# oslib
 oslib mql5
 
 Projeto abriga Expert Advisors e Indicadores que funcionam na plataforma Metatrader 5.


## Obtenha os fontes do projeto.
1. Instale o git no computador ou baixe o projeto no gitHub.
2. Os comandos abaixo supõe que a pasta onde você guarda seus projetos do github é `c:\git\`
`c:`
`cd c:\git\`
`git clone https://github.com/marcoc68/oslib.git`

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

## Indicador Volume Profile.
Este indicador mostra 3 linhas no gráfico de preços:
1. **POC ou Point of Control:** Linha amarela com o maior volume negociado no periodo configurado. 
2. **VAH ou Value Area High:**  Linha verde definindo o limite superior de 68% do volume negociado no período configurado. 
3. **VAL ou Value Area Low:**   Linha vermelha definindo o limite inferior de 68% do volume negociado no período configurado. 
![image](https://user-images.githubusercontent.com/5843284/154157848-4298c217-b3a8-4717-9a7a-9e702c714f90.png)


### Preparando Volume Profile para execução:

1. No terminal metatrader, clique no icone do metaeditor na barra de tarefas:
![image](https://user-images.githubusercontent.com/5843284/154162731-d53b6284-7f81-4e35-8db6-3945bc0b8008.png).

2. No painel lateral esquerdo do Metaeditor, acesse a pasta `MQL5\Include\oslib\osi\`:
![image](https://user-images.githubusercontent.com/5843284/154161392-e9d7b7fb-8e91-473b-8ecf-7d50d4b6c01e.png)
 
3. Dentro da pasta `osi`, clique com o botão direito no arquivo `osi-03-22-00-vol-profile.mq5` e escolha a opção `Compilar`.
![image](https://user-images.githubusercontent.com/5843284/154162012-84c92a95-2824-4c2e-aaf4-e70bfd063e71.png)

4. O resultado esperado da 
![image](https://user-images.githubusercontent.com/5843284/154847012-14ceba48-e802-4449-b85d-dc96400f0d03.png)

