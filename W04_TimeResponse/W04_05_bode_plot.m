clear all; close all;
s = tf('s');
G1 = 1/(s+1);
G2 = 1/(0.1*s+1);
options = bodeoptions;
options.FreqUnits = 'Hz'; % 'rad/second', 'Hz', 'rpm' 등 설정 가능
% 옵션을 적용하여 보드 선도 그리기
figure()
bode(G1, options); hold on;
bode(G2, options); hold on;
db2mag(-16.4)
%%
t = 0:0.001:5;
f = 1;
omega = 2*pi*f;

u = sin(omega*t);  % 입력
y = lsim(G1, u, t); % 출력

figure()
plot(t,u); hold on;
plot(t,y); grid on;
xlabel('time(s)'); ylabel('response');
legend('u(t)', 'y(t)');

%% 보드 plot에서 저주파, 중간 주파수, 고주파에서의 DB 값을 측정
%% DB 값을 크기로 변환하여 기록
%% 저주파, 중간주파수, 고주파에 해당 하는 sin (정현파를 입력하고)
%% 시간이 흐른 후 입력의 크기와 출력의 크기를 DB 값과 비교하여 확인
%% -> PPT에 코드와 결과 그래프를 캡처 
