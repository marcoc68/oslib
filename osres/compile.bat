@echo off
rem este script windows recebe o nome de programa mql5 como parametro, o compila e a ultima linha do log na tela
rem D:\Programs\mt5\desen\MetaEditor64.exe /compile:osi-03-14-myPair-006.mq5 /log

@echo on
del %1.log
D:\Programs\mt5\desen\MetaEditor64.exe /compile:%1.mq5 /log

@echo off
type %1.log
