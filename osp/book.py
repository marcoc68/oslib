import MetaTrader5 as mt5
import numpy as np
import pandas as pd 
import time

class book:

    '''
    Imagem do book de ofertas.
    
    '''
    def __init__(self, symb=None):
        self.symb         = symb   # ativo objeto do book de ofertas
        self.bookts_price = None   # serie de ocorrencias de precos  do book de ofertas
        self.bookts_vol   = None   # serie de ocorrencias de volumes do book de ofertas
        self.book_mercado = None   # ultima ocorrencia do book obtida no mercado 
        self.ask0 = 15 # posicao do primeiro nivel ask no book
        self.bid0 = 16 # posicao do primeiro nivel bid no book
        
        if symb != None:
            self.refresh_book_mercado()
            self.bookts_price = self.get_book_mercado_price()
            self.bookts_vol   = self.get_book_mercado_vol()
            
    def refresh_book_mercado(self):
        '''Obtem, no mercado, os dados imagem de cada nivel do book de ofertas. Salva na variável "book_mercado",
        cujo formato é:
        linha 0: tipo  : a primeira metade são as filas ask e em seguida as filas bid
        linha 1: precos: ordenados, sendo o primeiro o mais alto ask e o ultimo o mais baixo bid
        linha 2: volume: volume da fila nos respectivos niveis do book de ofertas
        '''
        self.book_mercado = pd.DataFrame( mt5.market_book_get(self.symb) ).T

    def get_book_mercado_price(self):
        '''retorna a linha dos precos da imagem atual da última ocorrência do book.'''
        return self.book_mercado[1:2]

    def get_book_mercado_vol(self):
        '''retorna a linha dos voumes da imagem atual da última ocorrêecia do book.'''
        return self.book_mercado[2:3]

    def __concat(self):
        self.bookts_price = pd.concat([self.bookts_price, self.get_book_mercado_price()] )
        self.bookts_vol   = pd.concat([self.bookts_vol  , self.get_book_mercado_vol()  ] )
        
    def refresh(self):
        self.refresh_book_mercado()
        self.__concat()
        #self.bookts_price
    
    def add(self, qtd, sleep=0.1, verbose=True):
        for i in range(qtd):
            self.refresh()
            time.sleep(sleep)
            if verbose: print(i,end="|")
        if verbose: print("processados ",qtd,"registros...")    

    def price(self):
        '''retorna toda a time series de precos.'''
        return self.bookts_price
    
    def price_level(self, level=0): 
        '''retorna toda a time series de precos no nivel informado em level. A primeira coluna é o ask e a segunda é o bid.'''
        return pd.concat( [ self.bookts_price[self.ask0-level] , self.bookts_price[self.bid0+level] ], axis=1 )
    
    def vol(self): 
        '''retorna toda a time series de volumes.'''
        return self.bookts_vol
    
    def vol_level(self, level=0): 
        '''retorna toda a time series de volumes no nivel informado em level. o volume de um nivel eh igual a soma dos volumes desde o nivel zero.'''
        df = pd.concat( [ self.bookts_vol[self.ask0-level] , self.bookts_vol[self.bid0+level] ], axis=1 )

        #ask = self.bookts_vol[self.ask0]
        #bid = self.bookts_vol[self.bid0]
        for i in range(level): 
            if i>0:
                df[self.ask0-level] = df[self.ask0-level] + self.bookts_vol[self.ask0+i]
                df[self.bid0+level] = df[self.bid0+level] + self.bookts_vol[self.bid0-i]
            
        return df
    
    def pmed(self):
        '''preco medio'''
        pask = np.array(self.bookts_price[self.ask0])
        pbid = np.array(self.bookts_price[self.bid0])

        return (pask+pbid)/2

    def pmed_demean(self):
        '''preco medio após retirar a média'''
        pmed = self.pmed()
        return pmed - pmed.mean()

    def iwfv(self, level=0):
        '''Inverse Size Weighted Fair Value'''
        pask = np.array(self.bookts_price[self.ask0-level])
        pbid = np.array(self.bookts_price[self.bid0+level])

        vol = self.vol_level(level)

        vask = np.array(vol[self.ask0-level])
        vbid = np.array(vol[self.bid0+level])
        
        
        return (pask*vbid + pbid*vask) / (vask+vbid)

    def iwfv_demean(self, level=0):
        '''Inverse Size Weighted Fair Value após retirar a média.'''
        iwfv = self.iwfv(level)
        return iwfv - iwfv.mean()

    def vimbalance(self, level=0):
        '''Volume imbalance'''
        pask = np.array(self.bookts_price[self.ask0-level])
        pbid = np.array(self.bookts_price[self.bid0+level])

        vol = self.vol_level(level)

        vask = np.array(vol[self.ask0-level])
        vbid = np.array(vol[self.bid0+level])
        
        
        return (vbid-vask) / (vask+vbid)