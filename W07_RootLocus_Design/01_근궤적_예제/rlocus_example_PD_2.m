clc; clear all; close all;
s = tf('s');
G = 1/(s*(s+2)*(s+5));
H = 1;
P_OS = 10; % 10% overshoot
% zeta_min = -log(P_OS/100)/(sqrt(pi^2 + log(P_OS/100)^2));
zeta_min = 0.5;
ts = 3;
wn_min = 4/(zeta_min*ts);

z = 3;
D = (s+z);

GH = D*G*H;

figure()
rlocus(GH);
sgrid(zeta_min, wn_min);

% K = 12.3;
K = 9.49;
G_cl = feedback(K*GH,1);
info = stepinfo(G_cl);

t = 0:0.001:10;
figure()
y = step(G_cl, t);
plot(t, y, 'LineWidth', 2);
xlabel('time (s)');
grid on;

fprintf('Overshoot:%f \n', info.Overshoot)
fprintf('Settling time:%f \n', info.SettlingTime)

((max(y) - y(end))/y(end))*100

zeta = -log(info.Overshoot/100)/(sqrt(pi^2 + log(info.Overshoot/100)^2))
