rem
rem Use este script para linkar a pasta do github a pasta do terminal
rem

rem copie os dois arquivos de chaves do github para a pasta .ssh do computador
rem clone o projeto oslib                           
set GIT_OSLIB=C:\Users\LVTYG7631\git\marcoc68\oslib
set TERMINAL=C:\Users\LVTYG7631\AppData\Roaming\MetaQuotes\Terminal\D242E06D38EE35CB8B09E08E7961ED5C\MQL5
                           
rem compilacao: execute este comando na pasta "include" do terminal onde ocorrerah a compilacao
cd %TERMINAL%\Include
mklink /D oslib %GIT_OSLIB%

rem experts: execute este comando na pasta "Experts" do terminal onde ocorrerah a compilacao
cd %TERMINAL%\Experts
mklink /D oslib-ose %GIT_OSLIB%\ose

rem indicadores: execute este comando na pasta "Indicators" do terminal onde ocorrerah a compilacao
cd %TERMINAL%\Indicators
mklink /D oslib-ose %GIT_OSLIB%\osi

rem scripts: execute este comando na pasta "Scripts" do terminal onde ocorrerah a compilacao
cd %TERMINAL%\Scripts
mklink /D oslib-ose %GIT_OSLIB%\scr
mklink /D oslib-ose %GIT_OSLIB%\tst

rem Services: execute este comando na pasta "Services" do terminal onde ocorrerah a compilacao
cd %TERMINAL%\Services
mklink /D oslib-ose %GIT_OSLIB%\svc
