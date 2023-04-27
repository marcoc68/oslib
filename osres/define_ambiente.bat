rem defina a variavel com a localizacaodo repositorio oslib
set REPOGIT_OSLIB=D:\repogit\oslib

rem defina a variavel com a instalacao do terminal de desenvolvimento do mt5
set TERMINAL=D:\programs\mt5\desen\MQL5

rem compilacao: execute este comando na pasta "include" do terminal onde ocorrerah a compilacao
cd %TERMINAL%\Include\
mklink /D oslib %REPOGIT_OSLIB%

rem experts: execute este comando na pasta "Experts" do terminal onde ocorrerah a compilacao
cd %TERMINAL%\Experts\
mklink /D oslib-ose %TERMINAL%\ose

rem indicadores: execute este comando na pasta "Indicators" do terminal onde ocorrerah a compilacao
cd %TERMINAL%\Indicators\
mklink /D oslib-osi %TERMINAL%\osi

rem scripts: execute este comando na pasta "Scripts" do terminal onde ocorrerah a compilacao
cd %TERMINAL%\Scripts\
mklink /D oslib-scr %TERMINAL%\scr
mklink /D oslib-tst %TERMINAL%\tst

rem scripts: execute este comando na pasta "Services" do terminal onde ocorrerah a compilacao
cd %TERMINAL%\Services\
mklink /D oslib-svc %TERMINAL%\svc
