clc; clear all; close all;
s = tf('s');
G = 1/(s*(s+2)*(s+5));
H = 1;
GH = G*H;

controlSystemDesigner(GH)



P_OS = 10; % 10% overshoot

zeta_min = -log(P_OS/100)/(sqrt(pi^2 + log(P_OS/100)^2))

ts = 2;

wn_min = 4/(zeta_min*ts);
% 
% figure()
% rlocus(GH);
% sgrid(zeta_min, wn_min)
% axis([-5 0 -7 7])
% 
% K = 8.2;
% G_cl = feedback(K*GH,1);
% info = stepinfo(G_cl);
% 
% t = 0:0.001:10;
% figure()
% y = step(G_cl, t);
% plot(t, y, 'LineWidth', 2);
% xlabel('time (s)');
% grid on;
% 
% fprintf('Overshoot:%f \n', info.Overshoot)
% fprintf('Settling time:%f \n', info.SettlingTime)
% 
% ((max(y) - y(end))/y(end))*100
