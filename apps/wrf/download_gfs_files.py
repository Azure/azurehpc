#!/usr/bin/env python
#################################################################
# Python Script to retrieve 93 online Data files of 'ds084.1',
# total 20.11G. This script uses 'requests' to download data.
#
# Highlight this script by Select All, Copy and Paste it into a file;
# make the file executable and run it on command line.
#
# You need pass in your password as a parameter to execute
# this script; or you can set an environment variable RDAPSWD
# if your Operating System supports it.
#
# Contact rdahelp@ucar.edu (RDA help desk) for further assistance.
#################################################################


import sys, os
import requests

def check_file_status(filepath, filesize):
    sys.stdout.write('\r')
    sys.stdout.flush()
    size = int(os.stat(filepath).st_size)
    percent_complete = (size/filesize)*100
    sys.stdout.write('%.3f %s' % (percent_complete, '% Completed'))
    sys.stdout.flush()

# Try to get password
if len(sys.argv) < 2 and not 'RDAPSWD' in os.environ:
    try:
        import getpass
        input = getpass.getpass
    except:
        try:
            input = raw_input
        except:
            pass
    pswd = input('Password: ')
else:
    try:
        pswd = sys.argv[1]
    except:
        pswd = os.environ['RDAPSWD']

url = 'https://rda.ucar.edu/cgi-bin/login'
values = {'email' : 'enter-your-email-here@email.com', 'passwd' : pswd, 'action' : 'login'}
# Authenticate
ret = requests.post(url,data=values)
if ret.status_code != 200:
    print('Bad Authentication')
    print(ret.text)
    exit(1)
dspath = 'https://rda.ucar.edu/data/ds084.1/'
filelist = [
'2018/20180617/gfs.0p25.2018061700.f000.grib2',
'2018/20180617/gfs.0p25.2018061700.f003.grib2',
'2018/20180617/gfs.0p25.2018061700.f006.grib2',
'2018/20180617/gfs.0p25.2018061700.f009.grib2',
'2018/20180617/gfs.0p25.2018061700.f012.grib2',
'2018/20180617/gfs.0p25.2018061700.f015.grib2',
'2018/20180617/gfs.0p25.2018061700.f018.grib2',
'2018/20180617/gfs.0p25.2018061700.f021.grib2',
'2018/20180617/gfs.0p25.2018061700.f024.grib2',
'2018/20180617/gfs.0p25.2018061700.f027.grib2',
'2018/20180617/gfs.0p25.2018061700.f030.grib2',
'2018/20180617/gfs.0p25.2018061700.f033.grib2',
'2018/20180617/gfs.0p25.2018061700.f036.grib2',
'2018/20180617/gfs.0p25.2018061700.f039.grib2',
'2018/20180617/gfs.0p25.2018061700.f042.grib2',
'2018/20180617/gfs.0p25.2018061700.f045.grib2',
'2018/20180617/gfs.0p25.2018061700.f048.grib2',
'2018/20180617/gfs.0p25.2018061700.f051.grib2',
'2018/20180617/gfs.0p25.2018061700.f054.grib2',
'2018/20180617/gfs.0p25.2018061700.f057.grib2',
'2018/20180617/gfs.0p25.2018061700.f060.grib2',
'2018/20180617/gfs.0p25.2018061700.f063.grib2',
'2018/20180617/gfs.0p25.2018061700.f066.grib2',
'2018/20180617/gfs.0p25.2018061700.f069.grib2',
'2018/20180617/gfs.0p25.2018061700.f072.grib2',
'2018/20180617/gfs.0p25.2018061700.f075.grib2',
'2018/20180617/gfs.0p25.2018061700.f078.grib2',
'2018/20180617/gfs.0p25.2018061700.f081.grib2',
'2018/20180617/gfs.0p25.2018061700.f084.grib2',
'2018/20180617/gfs.0p25.2018061700.f087.grib2',
'2018/20180617/gfs.0p25.2018061700.f090.grib2',
'2018/20180617/gfs.0p25.2018061700.f093.grib2',
'2018/20180617/gfs.0p25.2018061700.f096.grib2',
'2018/20180617/gfs.0p25.2018061700.f099.grib2',
'2018/20180617/gfs.0p25.2018061700.f102.grib2',
'2018/20180617/gfs.0p25.2018061700.f105.grib2',
'2018/20180617/gfs.0p25.2018061700.f108.grib2',
'2018/20180617/gfs.0p25.2018061700.f111.grib2',
'2018/20180617/gfs.0p25.2018061700.f114.grib2',
'2018/20180617/gfs.0p25.2018061700.f117.grib2',
'2018/20180617/gfs.0p25.2018061700.f120.grib2',
'2018/20180617/gfs.0p25.2018061700.f123.grib2',
'2018/20180617/gfs.0p25.2018061700.f126.grib2',
'2018/20180617/gfs.0p25.2018061700.f129.grib2',
'2018/20180617/gfs.0p25.2018061700.f132.grib2',
'2018/20180617/gfs.0p25.2018061700.f135.grib2',
'2018/20180617/gfs.0p25.2018061700.f138.grib2',
'2018/20180617/gfs.0p25.2018061700.f141.grib2',
'2018/20180617/gfs.0p25.2018061700.f144.grib2',
'2018/20180617/gfs.0p25.2018061700.f147.grib2',
'2018/20180617/gfs.0p25.2018061700.f150.grib2',
'2018/20180617/gfs.0p25.2018061700.f153.grib2',
'2018/20180617/gfs.0p25.2018061700.f156.grib2',
'2018/20180617/gfs.0p25.2018061700.f159.grib2',
'2018/20180617/gfs.0p25.2018061700.f162.grib2',
'2018/20180617/gfs.0p25.2018061700.f165.grib2',
'2018/20180617/gfs.0p25.2018061700.f168.grib2',
'2018/20180617/gfs.0p25.2018061700.f171.grib2',
'2018/20180617/gfs.0p25.2018061700.f174.grib2',
'2018/20180617/gfs.0p25.2018061700.f177.grib2',
'2018/20180617/gfs.0p25.2018061700.f180.grib2',
'2018/20180617/gfs.0p25.2018061700.f183.grib2',
'2018/20180617/gfs.0p25.2018061700.f186.grib2',
'2018/20180617/gfs.0p25.2018061700.f189.grib2',
'2018/20180617/gfs.0p25.2018061700.f192.grib2',
'2018/20180617/gfs.0p25.2018061700.f195.grib2',
'2018/20180617/gfs.0p25.2018061700.f198.grib2',
'2018/20180617/gfs.0p25.2018061700.f201.grib2',
'2018/20180617/gfs.0p25.2018061700.f204.grib2',
'2018/20180617/gfs.0p25.2018061700.f207.grib2',
'2018/20180617/gfs.0p25.2018061700.f210.grib2',
'2018/20180617/gfs.0p25.2018061700.f213.grib2',
'2018/20180617/gfs.0p25.2018061700.f216.grib2',
'2018/20180617/gfs.0p25.2018061700.f219.grib2',
'2018/20180617/gfs.0p25.2018061700.f222.grib2',
'2018/20180617/gfs.0p25.2018061700.f225.grib2',
'2018/20180617/gfs.0p25.2018061700.f228.grib2',
'2018/20180617/gfs.0p25.2018061700.f231.grib2',
'2018/20180617/gfs.0p25.2018061700.f234.grib2',
'2018/20180617/gfs.0p25.2018061700.f237.grib2',
'2018/20180617/gfs.0p25.2018061700.f240.grib2',
'2018/20180617/gfs.0p25.2018061700.f252.grib2',
'2018/20180617/gfs.0p25.2018061700.f264.grib2',
'2018/20180617/gfs.0p25.2018061700.f276.grib2',
'2018/20180617/gfs.0p25.2018061700.f288.grib2',
'2018/20180617/gfs.0p25.2018061700.f300.grib2',
'2018/20180617/gfs.0p25.2018061700.f312.grib2',
'2018/20180617/gfs.0p25.2018061700.f324.grib2',
'2018/20180617/gfs.0p25.2018061700.f336.grib2',
'2018/20180617/gfs.0p25.2018061700.f348.grib2',
'2018/20180617/gfs.0p25.2018061700.f360.grib2',
'2018/20180617/gfs.0p25.2018061700.f372.grib2',
'2018/20180617/gfs.0p25.2018061700.f384.grib2']
for file in filelist:
    filename=dspath+file
    file_base = os.path.basename(file)
    print('Downloading',file_base)
    req = requests.get(filename, cookies = ret.cookies, allow_redirects=True, stream=True)
    filesize = int(req.headers['Content-length'])
    with open(file_base, 'wb') as outfile:
        chunk_size=1048576
        for chunk in req.iter_content(chunk_size=chunk_size):
            outfile.write(chunk)
            if chunk_size < filesize:
                check_file_status(file_base, filesize)
    check_file_status(file_base, filesize)
    print()
