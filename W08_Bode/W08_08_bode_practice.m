clc; clear all; close all;

s = tf('s');

C1 = 1;
C2 = 10;
G = 1/s;

L1 = C1*G; % 개루프 전달함수 (게인이 1일 때)
T1 = L1/(1+L1); % 폐루프 전달함수 (게인이 1일 때)

L2 = C2*G; % 개루프 전달함수 (게인이 5일 때)
T2 = L2/(1+L2); % 폐루프 전달함수  (게인이 5일 때)

opts = bodeoptions;
opts.FreqUnits = 'Hz';

figure()
bode(L1, T1, L2, T2, opts)

w_bw1 = bandwidth(T1); % bandwidth 각 주파수
f_bw1 = w_bw1/(2*pi) % "  주파수 

w_bw2 = bandwidth(T2);
f_bw2 = w_bw2/(2*pi)  % "  주파수 

t = 0:0.01: 10;
y1 = step(T1, t);
y2 = step(T2, t);

figure()
plot(t,y1, t, y2);
grid on;
legend('T1','T2')

