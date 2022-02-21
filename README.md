# oslib
 oslib mql5
 
 Projeto abriga Expert Advisors e Indicadores que funcionam na plataforma Metatrader 5.


## Obtenha os fontes do projeto.
1. Instale o git no computador ou baixe o projeto no gitHub.
2. Os comandos abaixo supõe que a pasta onde você guarda seus projetos do github é `c:\git\`. Execute-os nesta sequência:
<pre><code>
    c:
    cd c:\git\
    git clone https://github.com/marcoc68/oslib.git
</code></pre>

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

## Documentação
### Indicadores
[Indicador Volume Profile.](https://github.com/marcoc68/oslib/blob/sprint-202202/doc/indicador-volume-profile.pdf)
