clc; clear all; close all;
s = tf('s');

G = 1/((s+1)*(s+4));
H = 1;
C1 = (s+1);
C2 = (s+3);
C3 = (s+6);

POS0 = 10;  ts0 = 2.5;
[zeta0, wn0] = spec2pole(POS0, ts0);

L1 = C1*G*H;
L2 = C2*G*H;
L3 = C3*G*H;


figure()
subplot(131)
rlocus(L1); sgrid(zeta0, wn0); 
subplot(132)
rlocus(L2);sgrid(zeta0, wn0);
subplot(133)
rlocus(L3); sgrid(zeta0, wn0);

C_final = 1.74*(s+6);

T = feedback(C_final*G, 1);
stepinfo(T)



%% 
1) 요구조건
%OS
%ts
%ess 
%Tp

rlocus
sgrid
feedback
stepinfo
dcgain
---------------
제어 출력을 10 이하로 사용하시오. 

----------------
CSD --> matlab, simulink





% 
% T = feedback(C*G,H);
% t = 0:0.01:1000;
% 
% dcgain(T)
% 
% y = step(T, t);
% figure()
% plot(t, y); grid on;

pole(T)

figure()
rlocus(G)


controlSystemDesigner(G)

C_2 = zpk(C.Z, C.P, C.K)

T = feedback(C_2*G,H);
t = 0:0.01:10;
y = step(T, t);
figure()
plot(t, y); grid on;

dcgain(T)

T
L = C_2*G

L_2 = 38*G