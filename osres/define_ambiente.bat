rem defina a variavel com a localizacaodo repositorio oslib
set REPOGIT_OSLIB=D:\repogit\oslib

rem defina a variavel com a instalacao do terminal de desenvolvimento do mt5
set TERMINAL=D:\programs\mt5\desen\MQL5

rem compilacao: execute este comando na pasta "include" do terminal onde ocorrerah a compilacao
mklink /D %TERMINAL%\Include\oslib %REPOGIT_OSLIB%

rem experts: execute este comando na pasta "Experts" do terminal onde ocorrerah a compilacao
mklink /D %TERMINAL%\Experts\oslib-ose %REPOGIT_OSLIB%\ose

rem indicadores: execute este comando na pasta "Indicators" do terminal onde ocorrerah a compilacao
mklink /D %TERMINAL%\Indicators\oslib-osi %REPOGIT_OSLIB%\osi

rem scripts: execute este comando na pasta "Scripts" do terminal onde ocorrerah a compilacao
mklink /D %TERMINAL%\Scripts\oslib-scr %REPOGIT_OSLIB%\scr
mklink /D %TERMINAL%\Scripts\oslib-tst %REPOGIT_OSLIB%\tst

rem scripts: execute este comando na pasta "Services" do terminal onde ocorrerah a compilacao
mklink /D %TERMINAL%\Services\oslib-svc %REPOGIT_OSLIB%\svc
