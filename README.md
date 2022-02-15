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
1. **Compilação**: execute este comando na pasta `include` do terminal metatrader.
   
    `mklink /D oslib c:\git\oslib`

2. **Experts**: execute este comando na pasta "Experts" do terminal.
   
   `mklink /D oslib-ose c:\git\oslib\ose`

3. **Indicadores**: execute este comando na pasta "Indicators" do terminal.
   
   `mklink /D oslib-osi c:\git\oslib\osi`

4. **Services**: execute este comando na pasta "Services" do terminal.
   
   `mklink /D oslib-svc c:\git\oslib\svc`

5. **Scripts**: execute estes comandos na pasta "Scripts" do terminal.
   
   `mklink /D oslib-scr c:\git\oslib\scr`
   
   `mklink /D oslib-tst c:\git\oslib\tst`

## Indicador Volume Profile.
Este inficador mostra 3 linhas no gráfico de preços:
1. **POC ou Point of Control:** Linha amarela com o maior volume negociado no periodo configurado. 
2. **VAH ou Value Area High:**  Linha verde definindo o limite superior de 68% do volume negociado no período configurado. 
3. **VAL ou Value Area Low:**   Linha vermelha definindo o limite inferior de 68% do volume negociado no período configurado. 
![image](https://user-images.githubusercontent.com/5843284/154153485-43d439f7-da55-4506-93db-109c9c63f9cd.png)


Para compilar o indicador Volume 
