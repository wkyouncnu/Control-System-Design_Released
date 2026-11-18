
clear all; close all; clc;

s = tf('s');

G1 = 1/(s+1);
G2 = 1/(0.1*s+1);
G3 = 1/(0.01*s+1);

opts = bodeoptions;
opts.FreqUnits = 'Hz';

figure()
bode(G1, G2, G3, opts);

%% Next class
% lsim 이용해서 사인파 줬을 때, bode plot에서 파악한 크기 변화와 맞는지 확인하기
f = 1; %  주파수 (Hz = 1/sec)
w = 2*pi*f; % 각 주파수 (rad/s)   w (rad/s) = 2pi*f (Hz = 1/s), f: 주파수
T = 1/f; % 주기 = 1/주파수 
t = (0:T/100:100*T)';
u = sin(w*t);


abs(freqresp(G1, w))

db2mag(-16.4)

y = lsim(G1, u, t);

figure()
plot(t, u, 'LineWidth', 2); hold on;
plot(t, y, 'LineWidth', 2); grid on;
xlabel('시간 [s]'); ylabel('신호');
legend('입력 사인','출력');
% db를 크기로 변화시키는 함수도 확인해봅시다.

% Wc <-> Wb <-> time constant <-> 반응속도

% PM <-> damping ratio 비례
%% 왜? DB 을 쓰는지? K 만큼 곱했을때 bode plot 의 모양 변화를 살펴봅시다.

