clc; clear all;
mu=1.327*10^11;
re=1.496*10^8;
rm= 2.279*10^8;
a = (re+rm)/2;

T = 2*pi*sqrt(a^3)/sqrt(mu);
Td=T/(3600*24*2);

Tm=2*pi*sqrt(rm^3)/sqrt(mu);
Tmd = Tm/(3600*24);
TmTd=Td/Tmd

TmTdeg=TmTd*360
alfa = 180-TmTdeg