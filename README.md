# oslib
 oslib mql5
 
 Projeto abriga Expert Advisors e Indicadores que funcionam na plataforma Metatrader 5.


## Como configurar o projeto.
1. Compilação: execute este comando na pasta "include" do terminal.
   `mklink /D oslib <PASTA_OSLIB-MQL>\oslib`
    
    Por exemplo, 
    supondo que eu tenha colocado a pasta `oslib-mql` em `c:\github\oblib-mql`, o comando seria `mklink /D oslib c:\github\oblib-mql\oslib`

2. Experts: execute este comando na pasta "Experts" do terminal.
   `mklink /D oslib-ose <PASTA_OSLIB-MQL>\oslib\ose`

3. Indicadores: execute este comando na pasta "Indicators" do terminal.
   `mklink /D oslib-osi <PASTA_OSLIB-MQL>\oslib\osi`

4. Services: execute este comando na pasta "Services" do terminal.
   `mklink /D oslib-svc <PASTA_OSLIB-MQL>\oslib\svc`

5. Scripts: execute estes comandos na pasta "Scripts" do terminal.
   `mklink /D oslib-scr <PASTA_OSLIB-MQL>\oslib\scr`
   `mklink /D oslib-tst <PASTA_OSLIB-MQL>\oslib\tst`

