#from wget import download
import wget
import datetime as dt
import os, subprocess
import sys
from time import time as timer
from multiprocessing.pool import ThreadPool
#import requests
year = int(sys.argv[1])
month = int(sys.argv[2])
day = int(sys.argv[3])

##dia = dt.date.today()
#dia = dt.datetime(dia.year,dia.month,dia.day,12)
dia = dt.datetime(year,month,day,12)
print(dia)
inicio = 00
##fim = 28         ## Dados para 1 dia
fim = 135      ## Dados para 5 dias

data_sys = dia.strftime("%Y%m%d%H")
data_gfs = dia.strftime("%Y%m%d")

##path_home = "/data/wrfdata/itv-data/"
path_home = "/data/wrfdata/gfs_data/"


#### CASO O DIRETORIO PARA O DOWNLOAD NAO EXISTE, ELE SERA CRIADO ####

if not os.path.isdir(path_home + "/" + data_sys ):
        os.system("mkdir -p " + path_home + data_sys )

#### URL (http://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod)
#### Alteracao realizada em 10 / set / 2020
#### URL (ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod)

#### DOWNLOAD DOS ARQUIVOS #####
args_inputs = []
j=0
for i in range(inicio,fim,3):
        k = str(i)
        if i < 10 :
                k = ('00' + k)
        if i >= 10 and i < 100 :
                k = ('0' + k)

        gfs = "gfs.t12z.pgrb2.0p25.f" + k
        print(gfs)

        if not os.path.isfile(path_home + "/" + data_sys + "/" + gfs):
                f_out = path_home + "/" + data_sys + '/' + gfs

####            url = ('http://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.' + data_gfs + '/12/' + gfs)
####            url = ('ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.' + data_gfs + '/12/' + gfs)
####            url = ('ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.' + data_gfs + '/12/atmos/' + gfs)
                url = ('https://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.' + data_gfs + '/12/atmos/' + gfs)

                args_inputs.append ((f_out, url))
                j=j+1

def fetch_url(entry):
        path, uri = entry
        print ("Downloading...", path)
        filename = wget.download(uri,path_home + data_sys)
        return path

start=timer()
results = ThreadPool(6).imap_unordered(fetch_url, args_inputs)

for path in results:
        print(path)

print("Elapsed Time: ", timer() - start)
