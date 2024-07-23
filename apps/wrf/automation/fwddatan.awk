{ data = $1;
  hplus = $2;
  len = length(data);
  res = len - 6;
  dias_mes = "31,28,31,30,31,30,31,31,30,31,30,31"
  ano = substr(data,1,4);
  mes = substr(data,5,2);
  dia = substr(data,7,2);
  resto = substr(data,9,res);
  fs=","
  a=split(dias_mes,dias,fs);
#  an1 = (1900+ano)/4.0;
  an1 = ano/4.0;
  bix = substr(an1,1,3);

  if (bix == an1){
     dias_mes = "31,29,31,30,31,30,31,31,30,31,30,31";
     split(dias_mes,dias,fs);}

  diao = dia
  if(diao<10) { diao= substr(data,8,1) + 1 - 1};

  hres = resto + hplus;
  ndia = hres/24.0;
  diai = int (ndia)

  if(diai >= 1)
  {
   hres = hres - (diai*24)
   diao = dia + diai;
  };

    if(mes<10) {mes = substr(data,6,1) + 1 - 1};

    if(diao > dias[mes])
    {
      diao = diao - dias[mes];
      mes=mes+1;
      if(mes > 12)
      {
        mes=1;
        anoteste=ano;
        ano = ano +1;
        if(ano==100)
        {
          ano="0";
        };

      };
    };


  if(hres < 0)
  {
   diai = diai - 1
   hres = hres - (diai*24)
   if(hres == 24)
   {
     hres=0;
     diai = diai + 1;
   };
   diao = dia + diai;
  };

    if(diao<1)
    {
      mes=mes-1;

      if(mes<1)
      {
        mes=12;
        ano = ano -1;
        if(ano<0)
        {
          ano=99;
        };
      };
      diao = dias[mes] + diao ;
    }


  if(diao<10) {diao="0"diao};
  if(ano<10) {ano="0"ano};
  if(mes<10) {mes="0"mes};
  if(hres<10) {hres="0"hres};

  print ano mes diao hres;
}
