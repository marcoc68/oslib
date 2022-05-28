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

set TERMINAL_CLEAR=D:\programs\metatrader\clear
set TERMINAL_CLDES=D:\programs\metatrader\clear-desen
set TERMINAL_MODAL=D:\programs\metatrader\modal
set TERMINAL_DESEN=D:\programs\metatrader\desen
set TERMINAL_MODES=D:\programs\metatrader\modal-desen

@echo on

call :copy-ind
call :copy-exp
call :copy-scr
call :copy-svc
goto :EOF

rem copiando indicadores
:copy-ind
cd %TERMINAL_DESEN%\MQL5\Indicators
xcopy /s /d /y "oslib-osi" "%TERMINAL_CLEAR%\MQL5\Indicators\"
xcopy /s /d /y "oslib-osi" "%TERMINAL_CLDES%\MQL5\Indicators\"
xcopy /s /d /y "oslib-osi" "%TERMINAL_MODAL%\MQL5\Indicators\"
xcopy /s /d /y "oslib-osi" "%TERMINAL_MODES%\MQL5\Indicators\"


rem copiando experts
:copy-exp
cd %TERMINAL_DESEN%\MQL5\Experts
xcopy /s /d /y "oslib-ose" "%TERMINAL_CLEAR%\MQL5\Experts\"
xcopy /s /d /y "oslib-ose" "%TERMINAL_CLDES%\MQL5\Experts\"
xcopy /s /d /y "oslib-ose" "%TERMINAL_MODAL%\MQL5\Experts\"
xcopy /s /d /y "oslib-ose" "%TERMINAL_MODES%\MQL5\Experts\"

rem copiando scripts
:copy-scr
cd %TERMINAL_DESEN%\MQL5\Scripts
xcopy /s /d /y "oslib-scr" "%TERMINAL_CLEAR%\MQL5\Scripts\"
xcopy /s /d /y "oslib-scr" "%TERMINAL_CLDES%\MQL5\Scripts\"
xcopy /s /d /y "oslib-scr" "%TERMINAL_MODAL%\MQL5\Scripts\"
xcopy /s /d /y "oslib-scr" "%TERMINAL_MODES%\MQL5\Scripts\"

xcopy /s /d /y "oslib-tst" "%TERMINAL_CLEAR%\MQL5\Scripts\"
xcopy /s /d /y "oslib-tst" "%TERMINAL_CLDES%\MQL5\Scripts\"
xcopy /s /d /y "oslib-tst" "%TERMINAL_MODAL%\MQL5\Scripts\"
xcopy /s /d /y "oslib-tst" "%TERMINAL_MODES%\MQL5\Scripts\"

rem copiando servicos
:copy-svc
cd %TERMINAL_DESEN%\MQL5\Services
xcopy /s /d /y "oslib-svc" "%TERMINAL_CLEAR%\MQL5\Services\"
xcopy /s /d /y "oslib-svc" "%TERMINAL_CLDES%\MQL5\Services\"
xcopy /s /d /y "oslib-svc" "%TERMINAL_MODAL%\MQL5\Services\"
xcopy /s /d /y "oslib-svc" "%TERMINAL_MODES%\MQL5\Services\"

rem copiando templates...
:copy-templates
xcopy /d /y %TERMINAL_DESEN%\MQL5\Profiles\Templates\my*.tpl %TERMINAL_CLEAR%\MQL5\Profiles\Templates\
xcopy /d /y %TERMINAL_DESEN%\MQL5\Profiles\Templates\my*.tpl %TERMINAL_CLDES%\MQL5\Profiles\Templates\
xcopy /d /y %TERMINAL_DESEN%\MQL5\Profiles\Templates\my*.tpl %TERMINAL_MODAL%\MQL5\Profiles\Templates\
xcopy /d /y %TERMINAL_DESEN%\MQL5\Profiles\Templates\my*.tpl %TERMINAL_MODES%\MQL5\Profiles\Templates\

rem copiando configuracoes de EA...
:copy-ea-config
xcopy /d /y %TERMINAL_DESEN%\MQL5\Presets\*.set %TERMINAL_CLEAR%\MQL5\Presets\
xcopy /d /y %TERMINAL_DESEN%\MQL5\Presets\*.set %TERMINAL_CLDES%\MQL5\Presets\
xcopy /d /y %TERMINAL_DESEN%\MQL5\Presets\*.set %TERMINAL_MODAL%\MQL5\Presets\
xcopy /d /y %TERMINAL_DESEN%\MQL5\Presets\*.set %TERMINAL_MODES%\MQL5\Presets\
xcopy /d /y %TERMINAL_DESEN%\MQL5\Presets\*.set %TERMINAL_ACDES%\MQL5\Presets\

cd %TERMINAL_DESEN%\MQL5\include\oslib\osres

:EOF