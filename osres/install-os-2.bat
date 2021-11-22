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

set TERMINAL_CLEAR=3BA9A43D10A400EE3A5C25C340D7DDC6
set TERMINAL_CLDES=F2736DC84E60965E8E88F26409B862DA
set TERMINAL_MODAL=8204B85248FF5705904F2EEC17F50E0C
set TERMINAL_DESEN=1359089FFD8DE572A105C49A845B99B2
set TERMINAL_MODES=43E4454D6B6E5524BFF7C681126AD41E
set TERMINAL_ACDES=FE0E65DDB0B7B40DE125080872C34D61



rem cd C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Projects\projetcts\os-ea

rem copy ea*.ex5 ..\..\..\Experts\os\
rem copy ea*.ex5 ..\..\..\..\..\%TERMINAL_CLEAR%\MQL5\Experts\os\
rem copy ea*.ex5 ..\..\..\..\..\%TERMINAL_CLDES%\MQL5\Experts\os\
rem copy ea*.ex5 ..\..\..\..\..\%TERMINAL_MODAL%\MQL5\Experts\os\
rem copy ea*.ex5 ..\..\..\..\..\%TERMINAL_MODES%\MQL5\Experts\os\
rem copy ea*.ex5 ..\..\..\..\..\%TERMINAL_ACDES%\MQL5\Experts\os\

rem copy ..\..\..\Indicators\os\osi-teste-01-03-feira\*.ex5 ..\..\..\..\..\%TERMINAL_CLEAR%\MQL5\Indicators\os\
rem copy ..\..\..\Indicators\os\osi-teste-01-03-feira\*.ex5 ..\..\..\..\..\%TERMINAL_CLDES%\MQL5\Indicators\os\
rem copy ..\..\..\Indicators\os\osi-teste-01-03-feira\*.ex5 ..\..\..\..\..\%TERMINAL_MODAL%\MQL5\Indicators\os\
rem copy ..\..\..\Indicators\os\osi-teste-01-03-feira\*.ex5 ..\..\..\..\..\%TERMINAL_MODES%\MQL5\Indicators\os\
rem copy ..\..\..\Indicators\os\osi-teste-01-03-feira\*.ex5 ..\..\..\..\..\%TERMINAL_ACDES%\MQL5\Indicators\os\

@echo on

rem copiando indicadores
cd C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Indicators
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_CLEAR%\MQL5\Indicators\"
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_CLDES%\MQL5\Indicators\"
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_MODAL%\MQL5\Indicators\"
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_MODES%\MQL5\Indicators\"
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_ACDES%\MQL5\Indicators\"

rem copiando experts
cd C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Experts
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_CLEAR%\MQL5\Experts\"
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_CLDES%\MQL5\Experts\"
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_MODAL%\MQL5\Experts\"
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_MODES%\MQL5\Experts\"
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_ACDES%\MQL5\Experts\"

rem copiando scripts
cd C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Scripts
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_CLEAR%\MQL5\Scripts\"
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_CLDES%\MQL5\Scripts\"
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_MODAL%\MQL5\Scripts\"
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_MODES%\MQL5\Scripts\"
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_ACDES%\MQL5\Scripts\"

rem copiando servicos
cd C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Services
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_CLEAR%\MQL5\Services\"
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_CLDES%\MQL5\Services\"
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_MODAL%\MQL5\Services\"
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_MODES%\MQL5\Services\"
xcopy /s /d /y "Shared Projects" "..\..\..\%TERMINAL_ACDES%\MQL5\Services\"


rem cd C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Indicators\Shared Projects
rem copy .\oslib\osi\*.ex5 "..\..\..\..\%TERMINAL_CLEAR%\MQL5\Indicators\Shared Projects\oslib\osi\"
rem copy .\oslib\osi\*.ex5 "..\..\..\..\%TERMINAL_CLDES%\MQL5\Indicators\Shared Projects\oslib\osi\"
rem copy .\oslib\osi\*.ex5 "..\..\..\..\%TERMINAL_MODAL%\MQL5\Indicators\Shared Projects\oslib\osi\"
rem copy .\oslib\osi\*.ex5 "..\..\..\..\%TERMINAL_MODES%\MQL5\Indicators\Shared Projects\oslib\osi\"
rem copy .\oslib\osi\*.ex5 "..\..\..\..\%TERMINAL_ACDES%\MQL5\Indicators\Shared Projects\oslib\osi\"

rem cd C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Indicators
rem copy .\Market\*.ex5 "..\..\%TERMINAL_CLEAR%\MQL5\Indicators\Market\"
rem copy .\Market\*.ex5 "..\..\%TERMINAL_CLDES%\MQL5\Indicators\Market\"
rem copy .\Market\*.ex5 "..\..\%TERMINAL_MODAL%\MQL5\Indicators\Market\"
rem copy .\Market\*.ex5 "..\..\%TERMINAL_MODES%\MQL5\Indicators\Market\"
rem copy .\Market\*.ex5 "..\..\%TERMINAL_ACDES%\MQL5\Indicators\Market\"
rem 
rem copy tst "..\..\%TERMINAL_CLEAR%\MQL5\Indicators\"
rem copy tst "..\..\%TERMINAL_CLDES%\MQL5\Indicators\"
rem copy tst "..\..\%TERMINAL_MODAL%\MQL5\Indicators\"
rem copy tst "..\..\%TERMINAL_MODES%\MQL5\Indicators\"
rem copy tst "..\..\%TERMINAL_ACDES%\MQL5\Indicators\"

rem C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\1359089FFD8DE572A105C49A845B99B2\MQL5\Indicators>copy tst "..\..\3BA9A43D10A400EE3A5C25C340D7DDC6\MQL5\Indicators\"

rem cd C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Experts\\Shared Projects
rem copy .\oslib\ose\*.ex5 "..\..\..\..\%TERMINAL_CLEAR%\MQL5\Experts\Shared Projects\oslib\ose\"
rem copy .\oslib\ose\*.ex5 "..\..\..\..\%TERMINAL_CLDES%\MQL5\Experts\Shared Projects\oslib\ose\"
rem copy .\oslib\ose\*.ex5 "..\..\..\..\%TERMINAL_MODAL%\MQL5\Experts\Shared Projects\oslib\ose\"
rem copy .\oslib\ose\*.ex5 "..\..\..\..\%TERMINAL_MODES%\MQL5\Experts\Shared Projects\oslib\ose\"
rem copy .\oslib\ose\*.ex5 "..\..\..\..\%TERMINAL_ACDES%\MQL5\Experts\Shared Projects\oslib\ose\"
rem 
rem cd C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Experts
rem copy "Shared Projects" "..\..\..\%TERMINAL_CLEAR%\MQL5\Experts\"

rem copiando scripts...
rem cd C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Scripts\\Shared Projects
rem copy .\oslib\scr\*.ex5 "..\..\..\..\%TERMINAL_CLEAR%\MQL5\Scripts\Shared Projects\oslib\scr\"
rem copy .\oslib\scr\*.ex5 "..\..\..\..\%TERMINAL_CLDES%\MQL5\Scripts\Shared Projects\oslib\scr\"
rem copy .\oslib\scr\*.ex5 "..\..\..\..\%TERMINAL_MODAL%\MQL5\Scripts\Shared Projects\oslib\scr\"
rem copy .\oslib\scr\*.ex5 "..\..\..\..\%TERMINAL_MODES%\MQL5\Scripts\Shared Projects\oslib\scr\"
rem copy .\oslib\scr\*.ex5 "..\..\..\..\%TERMINAL_ACDES%\MQL5\Scripts\Shared Projects\oslib\scr\"
rem 
rem rem copiando servicos...
rem cd C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Services\\Shared Projects
rem copy .\oslib\svc\*.ex5 "..\..\..\..\%TERMINAL_CLEAR%\MQL5\Services\Shared Projects\oslib\svc\"
rem copy .\oslib\svc\*.ex5 "..\..\..\..\%TERMINAL_CLDES%\MQL5\Services\Shared Projects\oslib\svc\"
rem copy .\oslib\svc\*.ex5 "..\..\..\..\%TERMINAL_MODAL%\MQL5\Services\Shared Projects\oslib\svc\"
rem copy .\oslib\svc\*.ex5 "..\..\..\..\%TERMINAL_MODES%\MQL5\Services\Shared Projects\oslib\svc\"
rem copy .\oslib\svc\*.ex5 "..\..\..\..\%TERMINAL_ACDES%\MQL5\Services\Shared Projects\oslib\svc\"

rem copiando templates...
xcopy /d /y C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Profiles\Templates\my*.tpl C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_CLEAR%\MQL5\Profiles\Templates
xcopy /d /y C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Profiles\Templates\my*.tpl C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_CLDES%\MQL5\Profiles\Templates
xcopy /d /y C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Profiles\Templates\my*.tpl C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_MODAL%\MQL5\Profiles\Templates
xcopy /d /y C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Profiles\Templates\my*.tpl C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_MODES%\MQL5\Profiles\Templates
xcopy /d /y C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Profiles\Templates\my*.tpl C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_ACDES%\MQL5\Profiles\Templates

rem copiando configuracoes de EA...
xcopy /d /y C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Presets\*.set C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_CLEAR%\MQL5\Presets
xcopy /d /y C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Presets\*.set C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_CLDES%\MQL5\Presets
xcopy /d /y C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Presets\*.set C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_MODAL%\MQL5\Presets
xcopy /d /y C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Presets\*.set C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_MODES%\MQL5\Presets
xcopy /d /y C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\Presets\*.set C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_ACDES%\MQL5\Presets

cd C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\%TERMINAL_DESEN%\MQL5\\Shared Projects\oslib\osres

