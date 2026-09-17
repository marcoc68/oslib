rem
rem Use este script para copiar executaveis do terminal de desenvolvimento para outro terminal
rem

@echo off
rem terminal-clear: novo:3BA9A43D10A400EE3A5C25C340D7DDC6 antigo:EA37C0754F237DDDDEF8384B5002F42E
rem terminal-modal: novo:8204B85248FF5705904F2EEC17F50E0C antigo:EA13603EB37E6287EDEEDAA079727CB2
rem terminal-desen: novo:1359089FFD8DE572A105C49A845B99B2 antigo:995BCF30F4F7DC34883107ECA947C5D7 
rem terminal-activ: novo:FE0E65DDB0B7B40DE125080872C34D61 
rem
rem execute este comando em "Shared Projects" apos colocar oslib na pasta include do terminal de desenvolvimento.
rem serah criada a juncao de diretorio oslib dentro da pasta "Shared Projects"
rem mklink /j oslib ..\..\MQL5\Include\oslib

rem coloque oslib na pasta D:\marcoc68\github\oslib-mql\oslib
rem 
rem compilacao: execute este comando na pasta "include" do terminal onde ocorrerah a compilacao
rem mklink /D oslib D:\marcoc68\github\oslib-mql\oslib
rem
rem experts: execute este comando na pasta "Experts" do terminal onde ocorrerah a compilacao
rem mklink /D oslib-ose D:\marcoc68\github\oslib-mql\oslib\ose
rem
rem indicadores: execute este comando na pasta "Indicators" do terminal onde ocorrerah a compilacao
rem mklink /D oslib-osi D:\marcoc68\github\oslib-mql\oslib\osi
rem
rem scripts: execute este comando na pasta "Scripts" do terminal onde ocorrerah a compilacao
rem mklink /D oslib-scr D:\marcoc68\github\oslib-mql\oslib\scr
rem mklink /D oslib-tst D:\marcoc68\github\oslib-mql\oslib\tst
rem
rem scripts: execute este comando na pasta "Services" do terminal onde ocorrerah a compilacao
rem mklink /D oslib-svc D:\marcoc68\github\oslib-mql\oslib\svc

rem
rem comando para buscar arquivos binarios que deveria ser utf8 (execute no shell do git)
rem  find $PWD -type f | grep -E 'py|mq5|mqh'  | xargs file -i * | grep -v -E 'utf-8|ascii|directo|pyc'
rem

set TERMINAL_MODAL=D:\programs\mt5\modal
set TERMINAL_DESEN=D:\programs\mt5\desen

@echo on

call :copy-ind
call :copy-exp
call :copy-scr
call :copy-svc
goto :EOF

rem copiando indicadores
:copy-ind
cd "%TERMINAL_DESEN%\MQL5\Indicators"
robocopy "oslib-osi\" "%TERMINAL_MODAL%\MQL5\Indicators\" *.ex5 /S

D:\programs\mt5\desen\MQL5\Experts>robocopy "oslib-ose\" "D:\programs\mt5\modal\MQL5\Experts\" *.ex5 /S
D:\programs\mt5\desen\MQL5\Experts>robocopy "oslib-ose\" "D:\programs\mt5\modal\MQL5\Experts\" *.ex5 /S


rem copiando experts
:copy-exp
cd "%TERMINAL_DESEN%\MQL5\Experts"
robocopy "oslib-ose\" "%TERMINAL_MODAL%\MQL5\Experts\" *.ex5 /S

rem copiando scripts
:copy-scr
cd "%TERMINAL_DESEN%\MQL5\Scripts"
robocopy "oslib-scr\" "%TERMINAL_MODAL%\MQL5\Scripts\" *.ex5 /S
robocopy "oslib-tst\" "%TERMINAL_MODAL%\MQL5\Scripts\" *.ex5 /S

rem copiando servicos
:copy-svc
cd "%TERMINAL_DESEN%\MQL5\Services"
robocopy "oslib-svc\" "%TERMINAL_MODAL%\MQL5\Services\" *.ex5 /S

rem copiando templates...
:copy-templates
robocopy "%TERMINAL_DESEN%\MQL5\Profiles\Templates\" "%TERMINAL_MODAL%\MQL5\Profiles\Templates\" my*.tpl /S

rem copiando configuracoes de EA...
:copy-ea-config
robocopy "%TERMINAL_DESEN%\MQL5\Presets\" "%TERMINAL_MODAL%\MQL5\Presets\" *.set /S

cd "%TERMINAL_DESEN%\MQL5\include\oslib\osres"

:EOF