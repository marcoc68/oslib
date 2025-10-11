# oslib
 oslib mql5
 
 Projeto abriga Expert Advisors e Indicadores que funcionam na plataforma Metatrader 5.


## Obtendo os fontes do projeto.
1. Instale o git no computador ou baixe o projeto no gitHub.
2. Os comandos abaixo supõe que a pasta onde guarda seus projetos do git é `c:\git\`. Caso use outra pasta, substitua `c:\git\` pela pasta onde estão seus projetos do git. Execute-os nesta sequência:
<pre><code>
    c:
    cd c:\git\
    git clone https://github.com/marcoc68/oslib.git
</code></pre>

## Configurando.
Vamos configurar o projeto.
Após estes passos abaixo, você poderá compilar e executar os Indicadores, Expert Advisors, Serviços e Scripts.

Abra um terminal `cmd`. Navegue até a pasta onde fica sua instalação do Metatrader.
Vá até a pasta `MQL5` e siga os passos abaixo. Lembre-se: troque `c:\git\` pela pasta onde você guarda seus projetos git.
 
1. **Bibliotecas**: execute este comando na pasta `Include` da instalação do seu terminal metatrader.
   
    `mklink /D oslib c:\git\oslib`


2. **Experts**: execute este comando na pasta `Experts` da instalação do seu terminal metatrader.
   
   `mklink /D oslib-ose c:\git\oslib\ose`


3. **Indicadores**: execute este comando na pasta `Indicators` da instalação do seu terminal metatrader.
   
   `mklink /D oslib-osi c:\git\oslib\osi`


4. **Services**: execute este comando na pasta `Services` da instalação do seu terminal metatrader.
   
   `mklink /D oslib-svc c:\git\oslib\svc`


5. **Scripts**: execute estes comandos na pasta `Scripts` da instalação do seu terminal metatrader.
   
   `mklink /D oslib-scr c:\git\oslib\scr`   
   `mklink /D oslib-tst c:\git\oslib\tst`

## Compilando um indicador.

## Documentação
### Indicadores
[Indicador Volume Profile.](https://github.com/marcoc68/oslib/blob/master/doc/indicador-volume-profile.pdf)
