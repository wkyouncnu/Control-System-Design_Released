%% W11B_03 — 저주파를 올리는 두 제어기 : PI 와 Lag
% 제어시스템설계 · 충남대학교 자율운항시스템공학과
%
% 강의노트 5절 ~ 6-3절에 대응합니다.
%
% 이번 실습의 핵심 메시지
%
%     PD 와 Lead 가 "오른쪽(고주파) 을 올려 위상을 버는" 제어기였다면
%     PI 와 Lag 는 "왼쪽(저주파) 을 올려 정확도를 버는" 제어기다.
%     둘 다 위상을 깎으므로, 교차주파수에서 멀리 떨어뜨려 놓는 것이 설계의 전부다.
%
% 바꿔 볼 것
%   - 2절의 inv_Ti 를 0.6, 3, 6 으로 (꺾이는 자리를 wc 에 가까이 가져가면)
%   - 4절의 drop_dB 를 10, 18.8, 25 로
%   - 4절의 wc_new 를 5, 6.75, 10 으로

clear; clc; close all;
s = tf('s');

%% 0. 경로 자동 등록
if isempty(which('plant_msd'))
    p_ = pwd;
    if ~isempty(mfilename('fullpath')), p_ = fileparts(mfilename('fullpath')); end
    for k_ = 1:4
        if isfile(fullfile(p_,'setup_path.m')), run(fullfile(p_,'setup_path.m')); break; end
        p_ = fileparts(p_);
    end
    clear p_ k_
end

%% 1. 오늘의 플랜트는 형 0 — 계단 오차가 남는다
%  적분기가 없으므로 계단 지령에도 오차가 남습니다.
%  K 를 올리면 줄기는 하지만, 0 은 되지 않습니다.

G = 1/((s+1)*(s/5+1));          % 형 0, DC 이득 1

K_list = [1; 10; 100];
n = numel(K_list);

Kp_v = zeros(n,1); es_v = zeros(n,1);
pm_v = zeros(n,1); wc_v = zeros(n,1); os_v = zeros(n,1);

for k = 1:n
    Lk = K_list(k)*G;
    Kp_v(k) = dcgain(Lk);
    es_v(k) = 1/(1 + Kp_v(k));
    [~, pm_v(k), ~, wc_v(k)] = margin(Lk);
    Tk = feedback(Lk, 1);
    os_v(k) = stepinfo(Tk).Overshoot;
end

table(K_list, Kp_v, es_v, 100*es_v, pm_v, wc_v, os_v, ...
    'VariableNames', {'K', 'Kp', '계단오차', '오차_퍼센트', 'PM_deg', 'wc', 'OS_퍼센트'})

% 읽는 법
%   - K = 1 의 PM 이 -180 도, wc 가 0 으로 나온다. **계산이 틀린 것이 아니다.**
%     |L(0)| = 1 = 0 dB 라서 margin 이 교차점을 0 rad/s 로 보는 것이다.
%     이 플랜트에서 K = 1 은 쓰지 않는다
%   - K = 10 은 오차 9.1 %, PM 48 도. 여유는 좋은데 오차가 크다
%   - K = 100 은 오차 0.99 %, PM 15 도. 오차는 좋은데 여유가 없다
%   => 둘 다 가지려면 저주파만 올려야 한다. 그것이 PI 와 Lag 다.

%% 2. PI — 저주파를 무한으로 올린다
%  담당교수 강의자료의 표기를 그대로 씁니다.
%
%      C(s) = K(1 + a/s),    a = 1/Ti,    Ki = K*a
%
%  분자를 묶으면 C(s) = K(s + a)/s 입니다. 영점이 s = -a, 극점이 s = 0 입니다.
%  s = 0 의 극점이 저주파 이득을 무한으로 올립니다 (= 계단 오차 0).
%
%  대가는 위상입니다. 적분기 하나가 -90 도를 깔아 놓고,
%  영점이 그것을 다시 0 도로 되돌립니다. 그 중간에 손실이 생깁니다.
%
%      angle(C) = atan(w*Ti) - 90   [deg]
%
%  꺾이는 자리에서 **얼마나 떨어지면 손실이 얼마인지**를 외워 두면 설계가 끝납니다.

K_pi = 10;
inv_Ti = 0.6;                   % <-- 0.6, 3, 6 으로 바꿔 보기
Ti = 1/inv_Ti;
C_pi = K_pi*(Ti*s + 1)/(Ti*s);  % = K(1 + a/s) 와 같은 식

ratio = [1; 2; 5; 10; 20];
w_pi = ratio*inv_Ti;

table(w_pi, ratio, atand(w_pi*Ti) - 90, ...
    squeeze(angle(freqresp(C_pi, w_pi)))*180/pi, ...
    20*log10(squeeze(abs(freqresp(C_pi, w_pi)))), ...
    'VariableNames', {'w_rad_s', '꺾임의_몇배', '위상_공식', '위상_실측', '크기_dB'})

% 읽는 법
%   - 꺾이는 자리 바로 위(1배) 에서는 -45 도를 잃는다
%   - 10 배 떨어지면 -5.7 도, 20 배면 -2.9 도밖에 안 잃는다
%   - 크기는 그 자리에서 거의 K (20 dB) 로 돌아온다
%   => 실무 규칙 : 1/Ti 를 wc 의 1/10 쯤에 놓는다

%% 3. PI 두 가지를 비교 — 꺾는 자리를 어디에 둘 것인가
%  wc 가 약 6.2 rad/s 이므로 1/Ti = 0.6 이면 열 배 아래, 3 이면 두 배 아래입니다.

a_list = [0.6; 3];
m = numel(a_list);

pm_p = zeros(m,1); wc_p = zeros(m,1); os_p = zeros(m,1);
ts_p = zeros(m,1); es_p = zeros(m,1);

for k = 1:m
    Ck = K_pi*(s + a_list(k))/s;
    [~, pm_p(k), ~, wc_p(k)] = margin(Ck*G);
    Tk = feedback(Ck*G, 1);
    si = stepinfo(Tk);
    os_p(k) = si.Overshoot;
    ts_p(k) = si.SettlingTime;
    es_p(k) = 1 - dcgain(Tk);        % 계단 오차
end

table(a_list, K_pi*a_list, pm_p, wc_p, os_p, ts_p, es_p, ...
    'VariableNames', {'꺾이는자리_a', 'Ki', 'PM_deg', 'wc', 'OS_퍼센트', 'ts', '계단오차'})

% 읽는 법
%   - 둘 다 계단 오차가 0 이다. 적분기가 있으니까
%   - a = 0.6 은 PM 42 도. K = 10 만 쓸 때(48 도) 보다 6 도 잃었다
%   - a = 3 은 PM 21 도. 27 도를 잃었다. ts 도 1.23 -> 2.90 초로 나빠졌다
%   => 꺾이는 자리를 wc 에 가까이 가져가면 손실이 커진다

%% 4. Lag — 오차를 "유한하게" 줄이는 대신 적분기를 안 쓴다
%  Lag 의 설계 순서는 Lead 와 정반대입니다.
%
%  (1) 정확도가 필요한 만큼 K 를 **먼저 크게** 잡는다 (여기서는 K = 100)
%  (2) 그러면 wc 가 너무 오른쪽으로 가서 PM 이 없다
%  (3) 그래서 고주파를 **내려서** wc 를 원하는 자리로 끌어온다
%  (4) 저주파는 그대로 두므로 정확도는 지켜진다
%
%      C(s) = K(1+Ts)/(1 + alpha*T*s),   alpha > 1
%      DC 이득 = K,   고주파 이득 = K/alpha,   내리는 양 = 20*log10(alpha) [dB]
%      1/T = wc_new/10   (위상 손실을 5.7 도로 묶기 위해)

K_lag = 100;
wc_new = 6.75;                  % <-- 5, 6.75, 10 으로 바꿔 보기
drop_dB = 18.8;                 % <-- 10, 18.8, 25 로 바꿔 보기

alpha_g = 10^(drop_dB/20);
T_g = 10/wc_new;                % 1/T = wc_new/10
C_lag = K_lag*(T_g*s + 1)/(alpha_g*T_g*s + 1);

fprintf('[Lag 설계값]\n');
fprintf('  내릴 양   = %.2f dB  =>  alpha = %.4f\n', drop_dB, alpha_g);
fprintf('  1/T       = %.4f  (wc_new 의 1/10)\n', 1/T_g);
fprintf('  1/(alpha*T) = %.4f  (극점. 영점보다 왼쪽에 있다)\n', 1/(alpha_g*T_g));
fprintf('  DC 이득   = %.1f  (K 그대로 — 정확도가 지켜진다)\n', dcgain(C_lag));
fprintf('  고주파 이득 = %.3f  (= K/alpha)\n', K_lag/alpha_g);

%% 5. 세 설계를 한 표로 — 무엇을 사고 무엇을 팔았나
nm3 = {'K = 10 만'; 'K = 100 만'; 'K = 100 + Lag'};
Cs = {10; 100; C_lag};

pm3 = zeros(3,1); wc3 = zeros(3,1); os3 = zeros(3,1);
es3 = zeros(3,1); ts3 = zeros(3,1);

for k = 1:3
    Lk = Cs{k}*G;
    [~, pm3(k), ~, wc3(k)] = margin(Lk);
    Tk = feedback(Lk, 1);
    si = stepinfo(Tk);
    os3(k) = si.Overshoot;
    ts3(k) = si.SettlingTime;
    es3(k) = 1 - dcgain(Tk);
end

table(nm3, pm3, wc3, os3, ts3, es3, 100*es3, ...
    'VariableNames', {'설계', 'PM_deg', 'wc', 'OS_퍼센트', 'ts', '계단오차', '오차_퍼센트'})

% 읽는 법
%   - Lag 설계가 **K = 100 의 정확도(0.99 %) 를 K = 10 의 여유(약 40 도) 로** 가졌다
%   - wc 는 22.1 에서 6.78 로 내려왔다. 그래서 여유가 생긴 것이다
%   - 공짜는 아니다. wc 가 작아진 만큼 **느려진다**

%% 6. PI 와 Lag 를 보드 선도로 나란히
Cpi_plot = 10*(s + 0.6)/s;
wplot = logspace(-3, 3, 800);

tiledlayout(2, 1, 'TileSpacing', 'compact');

nexttile; hold on; grid on;
semilogx(wplot, 20*log10(squeeze(abs(freqresp(Cpi_plot, wplot)))), ...
    'LineWidth', 2.5, 'DisplayName', 'PI : 10(s+0.6)/s');
semilogx(wplot, 20*log10(squeeze(abs(freqresp(C_lag, wplot)))), ...
    'LineWidth', 2.5, 'DisplayName', 'Lag');
set(gca, 'XScale', 'log');
xlabel('주파수 [rad/s]'); ylabel('|C| [dB]');
legend('Location', 'southwest');
title('왼쪽을 올린다 — PI 는 무한히, Lag 는 alpha 배만');

nexttile; hold on; grid on;
semilogx(wplot, squeeze(angle(freqresp(Cpi_plot, wplot)))*180/pi, 'LineWidth', 2.5);
semilogx(wplot, squeeze(angle(freqresp(C_lag, wplot)))*180/pi, 'LineWidth', 2.5);
set(gca, 'XScale', 'log');
yline(0, 'k--'); yline(-90, 'k:');
xlabel('주파수 [rad/s]'); ylabel('angle(C) [deg]');
title('둘 다 위상을 깎는다 — PI 는 -90 에서 출발, Lag 는 골을 만든다');

% 질문
%   - 2절에서 inv_Ti 를 6 으로 하면 위상 손실이 몇 도가 되나요
%     그 손실이 PM 에 그대로 나타나는지 3절 방식으로 확인해 보세요
%   - 4절에서 drop_dB 를 25 로 올리면 wc 와 PM 이 어떻게 되나요
%   - "계단 오차가 정확히 0 이어야 한다" 는 사양이면 PI 와 Lag 중 무엇을 골라야 하나요
%     반대로 적분 포화(integrator windup) 가 걱정되면 무엇을 고르나요
