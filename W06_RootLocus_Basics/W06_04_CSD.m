clc; clear all; close all;
s = tf('s');
Gpd  = 1/(s*(s+4));
% POS0 = 16;  ts0 = 1;
% [zeta0, wn0] = spec2pole(POS0, ts0);
% 
% figure()
% rlocus(Gpd)
% sgrid(zeta0, wn0)
% axis([-10 0.5 -10 10])
% 
% %% PD 제어기
% z1 = 1; C1 = (s+z1); 
% z2 = 3; C2 = (s+z2);
% z3 = 5; C3 = (s+z3);
% z4 = 10; C4 = (s+z4);
% 
% figure()
% subplot(221)
% rlocus(Gpd)
% sgrid(zeta0, wn0)
% axis([-10 0.5 -10 10])
% 
% subplot(222)
% rlocus(C1*Gpd)
% sgrid(zeta0, wn0)
% axis([-10 0.5 -10 10])
% subtitle('(s + 1)')
% 
% subplot(223)
% rlocus(C2*Gpd)
% sgrid(zeta0, wn0)
% axis([-10 0.5 -10 10])
% subtitle('(s + 3)')
% 
% subplot(224)
% rlocus(C3*Gpd)
% sgrid(zeta0, wn0)
% axis([-10 0.5 -10 10])
% subtitle('(s + 5)')
% 
% figure()
% rlocus(C4*Gpd)
% sgrid(zeta0, wn0)
% axis([-10 0.5 -10 10])
% subtitle('(s + 10)')
% 
% T = feedback(7.72*C4*Gpd, 1);
% t = 0:0.001:10;
% 
% y = step(T, t);
% 
% figure()
% plot(t, y); grid on;
% 
% stepinfo(T)
% 

%%

controlSystemDesigner(Gpd)