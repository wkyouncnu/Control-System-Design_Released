%% W11B_02 — 위상을 올리는 두 제어기 : PD 와 Lead
% 제어시스템설계 · 충남대학교 자율운항시스템공학과
%
% 강의노트 3절 ~ 4-5절에 대응합니다.
%
% 이번 실습의 핵심 메시지
%
%     PD 는 위상을 올려 주지만 고주파 이득이 무한이라 실물에 못 쓴다.
%     분모에 극점 하나를 넣어 "어느 주파수부터 다시 평평하게" 만든 것이 Lead 다.
%     그 극점 하나가 Lead 의 전부다.
%
% 바꿔 볼 것
%   - 2절의 Tdv 에 더 큰 값을 넣어 보기 (고주파 이득이 어디까지 가는가)
%   - 3절의 tau 를 0.01 로 (제어입력이 다섯 배가 되는지)
%   - 5절의 phi_max 를 30, 50, 65 도로
%   - 6절의 w_max 를 10, 16.7, 30 으로 (어디에 놓는 것이 좋은가)

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

G = 1/(s*(s+1));                % W11B_01 에서 쓴 그 플랜트
K = 100;                        % 사양이 정해 준 이득 (W11B_01 1절)

%% 1. PD 의 보드 모양 — 손계산과 대조
%  PD 제어기는 C(s) = K(1 + Td*s) 입니다. 꺾이는 자리는 1/Td 입니다.
%
%  주파수응답을 손으로 적으면
%
%      C(jw) = K(1 + j*w*Td)
%      |C| = K*sqrt(1 + (w*Td)^2),   angle(C) = atan(w*Td)
%
%  세 자리만 외우면 됩니다.
%
%      w << 1/Td : 크기 K,          위상 0 도
%      w == 1/Td : 크기 K*sqrt(2),  위상 45 도   (= +3.01 dB)
%      w >> 1/Td : 크기 K*w*Td,     위상 90 도

Td = 0.1;
C_pd = K*(1 + Td*s);

w_chk = [1; 1/Td; 100];
mag_hand = 20*log10(K*sqrt(1 + (w_chk*Td).^2)) - 20*log10(K);   % K 를 뺀 상대 크기
ang_hand = atand(w_chk*Td);

mag_mat = 20*log10(squeeze(abs(freqresp(C_pd, w_chk)))) - 20*log10(K);
ang_mat = squeeze(angle(freqresp(C_pd, w_chk)))*180/pi;

table(w_chk, ang_hand, ang_mat, mag_hand, mag_mat, ...
    'VariableNames', {'w_rad_s', '위상_손', '위상_MATLAB', '크기_손_dB', '크기_MATLAB_dB'})

% 읽는 법 : 꺾이는 자리 w = 1/Td = 10 에서 위상 45 도, 크기 +3.01 dB.
%            이 두 숫자가 PD 의 서명이다.

%% 2. Td 를 바꿔 가며 — 좋아지는 것과 나빠지는 것
%  위상여유는 좋아지는데 교차주파수와 고주파 이득이 끝없이 커집니다.

Tdv = [0.05; 0.1; 0.2; 1];      % <-- 더 큰 값을 넣어 보기
n = numel(Tdv);

pm_v = zeros(n,1); wc_v = zeros(n,1); os_v = zeros(n,1);
ts_v = zeros(n,1); hf_v = zeros(n,1);

for k = 1:n
    Ck = K*(1 + Tdv(k)*s);
    [~, pm_v(k), ~, wc_v(k)] = margin(Ck*G);
    Tk = feedback(Ck*G, 1);
    si = stepinfo(Tk);
    os_v(k) = si.Overshoot;
    ts_v(k) = si.SettlingTime;
    hf_v(k) = 20*log10(abs(evalfr(Ck, 1000i)));     % w = 1000 에서의 제어기 크기
end

table(Tdv, 1./Tdv, pm_v, wc_v, os_v, ts_v, hf_v, ...
    'VariableNames', {'Td', '꺾이는자리', 'PM_deg', 'wc', 'OS_퍼센트', 'ts', 'C크기_w1000_dB'})

% 읽는 법
%   - Td 를 키우면 PM 이 33 -> 56 -> 79 -> 90 도로 좋아진다
%   - 그런데 wc 가 10.6 -> 12.7 -> 20.6 -> 100 으로 **끝없이** 커진다
%   - w = 1000 에서의 제어기 크기도 74 -> 80 -> 86 -> 100 dB 로 커진다
%   Td = 1 은 PM 90 도를 주지만, 그 대가를 3절에서 확인한다.

%% 3. PD 의 대가 — 제어입력
%  진짜 계단 지령으로는 계산 자체가 안 됩니다. u/r = C/(1+CG) 가
%  s -> Inf 에서 발산하기 때문입니다 (비적정, improper).
%  그래서 지령을 tau 초에 올라가게 조금 부드럽게 만들어 넣습니다.

tau = 0.05;                     % <-- 0.01 로 바꿔 보기
R_smooth = tf(1, [tau 1]);
t2 = (0:1e-4:1)';

umax_v = zeros(n,1);
for k = 1:n
    Ck = K*(1 + Tdv(k)*s);
    Gu = minreal(Ck/(1 + Ck*G));                % r -> u
    u = lsim(minreal(Gu*R_smooth), ones(size(t2)), t2);
    umax_v(k) = max(abs(u));
end

table(Tdv, K*Tdv/tau, umax_v, ...
    'VariableNames', {'Td', '공식_K_Td_over_tau', 'umax_실측'})

% 읽는 법
%   - 공식과 실측이 정확히 같다. umax = K*Td/tau
%   - 미분항이 지령의 기울기(1/tau)를 그대로 받기 때문이다
%   - tau -> 0 (진짜 계단) 이면 umax -> Inf. 그래서 PD 는 못 쓴다

%% 4. Lead 가 PD 와 다른 점은 극점 하나뿐
%  Lead 는 C(s) = K(1+Ts)/(1 + alpha*T*s), 0 < alpha < 1 입니다.
%  alpha = 0 으로 두면 분모가 1 이 되어 그대로 PD 입니다.
%  alpha 가 PD 와 Lead 를 잇는 다이얼입니다.

T_fix = 0.1;
al_list = [0; 0.05; 0.1325; 0.5];
wplot = logspace(-1, 4, 600);

tiledlayout(2, 1, 'TileSpacing', 'compact');

nexttile; hold on; grid on;
for k = 1:numel(al_list)
    if al_list(k) == 0
        Ck = K*(1 + T_fix*s);
        nm = 'alpha = 0 (PD)';
    else
        Ck = K*(T_fix*s + 1)/(al_list(k)*T_fix*s + 1);
        nm = sprintf('alpha = %.4g', al_list(k));
    end
    semilogx(wplot, 20*log10(squeeze(abs(freqresp(Ck, wplot)))), ...
        'LineWidth', 2.2, 'DisplayName', nm);
end
set(gca, 'XScale', 'log');
xlabel('주파수 [rad/s]'); ylabel('|C| [dB]');
legend('Location', 'northwest');
title('alpha 가 고주파를 멈춰 세운다');

nexttile; hold on; grid on;
for k = 1:numel(al_list)
    if al_list(k) == 0
        Ck = K*(1 + T_fix*s);
    else
        Ck = K*(T_fix*s + 1)/(al_list(k)*T_fix*s + 1);
    end
    semilogx(wplot, squeeze(angle(freqresp(Ck, wplot)))*180/pi, 'LineWidth', 2.2);
end
set(gca, 'XScale', 'log');
yline(90, 'k:'); yline(0, 'k--');
xlabel('주파수 [rad/s]'); ylabel('angle(C) [deg]'); ylim([-5 95]);
title('그 대신 위상도 봉우리가 되어 다시 내려온다');

%% 5. 최대 위상과 alpha — 공식을 숫자로 확인
%  유도 결과는 두 줄입니다.
%
%      sin(phi_max) = (1 - alpha)/(1 + alpha)
%      alpha = (1 - sin(phi_max))/(1 + sin(phi_max))
%
%  그리고 봉우리는 두 꺾임점의 **기하평균** 자리에 옵니다.
%
%      w_max = 1/(T*sqrt(alpha))      크기 올림 = -10*log10(alpha) [dB]

phi_list = [20; 35; 50; 65]';   % <-- 다른 각도를 넣어 보기
m = numel(phi_list);

al_v = zeros(m,1); phi_meas = zeros(m,1);
wmx_f = zeros(m,1); wmx_meas = zeros(m,1);
db_f = zeros(m,1); db_meas = zeros(m,1);

for k = 1:m
    al_v(k) = (1 - sind(phi_list(k)))/(1 + sind(phi_list(k)));
    Tk = 1;                                  % T = 1 로 고정하고 성질만 본다
    Ck = (Tk*s + 1)/(al_v(k)*Tk*s + 1);
    wmx_f(k) = 1/(Tk*sqrt(al_v(k)));
    db_f(k) = -10*log10(al_v(k));

    wscan = logspace(-2, 3, 20001);
    ph = squeeze(angle(freqresp(Ck, wscan)))*180/pi;
    [phi_meas(k), iw] = max(ph);
    wmx_meas(k) = wscan(iw);
    db_meas(k) = 20*log10(abs(evalfr(Ck, 1i*wmx_meas(k))));
end

table(phi_list', al_v, phi_meas, wmx_f, wmx_meas, db_f, db_meas, ...
    'VariableNames', {'phi_목표', 'alpha', 'phi_실측', 'wmax_공식', 'wmax_실측', ...
                      'dB_공식', 'dB_실측'})

% 읽는 법
%   - 공식과 실측이 전부 일치한다
%   - alpha 가 0.49 -> 0.27 -> 0.13 -> 0.049 로 **급격히** 작아진다
%   - 1/alpha 가 고주파 이득 배율이다. 65 도면 18 배, 70 도면 32 배
%   => 한 단에서 55 도를 넘기지 않는다. 더 필요하면 두 단으로 (7절)

%% 6. Lead 설계 다섯 단계 — 손으로 전부 따라간다
%  (1) K 를 정한다               : W11B_01 에서 K = 100
%  (2) 현재 PM 을 잰다
%  (3) 필요한 위상을 정한다       : 목표 PM - 현재 PM + 여유
%  (4) alpha 와 T 를 구한다
%  (5) 결과를 확인한다

phi_max = 50;                   % <-- 30, 50, 65 로 바꿔 보기
w_max = 16.7;                   % <-- 10, 16.7, 30 으로 바꿔 보기

% (2) 현재 PM
[~, pm0, ~, wc0] = margin(K*G);
fprintf('(2) K = %d 만 쓸 때 : PM = %.2f 도, wc = %.3f rad/s\n', K, pm0, wc0);

% (3) 필요한 위상
fprintf('(3) 목표 PM 50 도 - 현재 %.1f 도 + 여유 => phi_max = %g 도\n', pm0, phi_max);

% (4) alpha, T
alpha = (1 - sind(phi_max))/(1 + sind(phi_max));
boost = -10*log10(alpha);
T = 1/(w_max*sqrt(alpha));

fprintf('(4) alpha = %.5f,  1/alpha = %.4f,  올림 = %.4f dB\n', alpha, 1/alpha, boost);
fprintf('    T = 1/(w_max*sqrt(alpha)) = %.5f\n', T);
fprintf('    영점 1/T = %.4f,  극점 1/(alpha*T) = %.4f\n', 1/T, 1/(alpha*T));

% (5) 결과
C_lead = K*(T*s + 1)/(alpha*T*s + 1);
[gm, pm, ~, wc] = margin(C_lead*G);
T_cl = feedback(C_lead*G, 1);
si = stepinfo(T_cl);

table(alpha, T, 1/T, 1/(alpha*T), pm, 20*log10(gm), wc, si.Overshoot, si.SettlingTime, ...
    'VariableNames', {'alpha', 'T', '영점', '극점', 'PM_deg', 'GM_dB', 'wc', ...
                      'OS_퍼센트', 'ts'})

%% 7. 앱이 보여 주는 숫자와 손으로 쓴 숫자가 같은 것임을 확인
%  controlSystemDesigner 는 Lead 를 "영점·극점" 꼴로 보여 줍니다.
%
%      K*(T*s+1)/(alpha*T*s+1) = (K/alpha) * (s + 1/T)/(s + 1/(alpha*T))
%
%  겉모습이 달라서 "앱이 다른 걸 설계했다" 고 오해하기 쉽습니다. 같습니다.

C_app = (K/alpha)*(s + 1/T)/(s + 1/(alpha*T));

fprintf('\n[두 표기가 같은가]\n');
fprintf('  손으로 쓴 꼴    : K=%g, T=%.5f, alpha=%.5f\n', K, T, alpha);
fprintf('  앱이 보여 줄 꼴 : %.2f * (s + %.4f)/(s + %.4f)\n', K/alpha, 1/T, 1/(alpha*T));
fprintf('  두 전달함수의 차이 norm = %.3e  (0 이면 같다)\n', ...
    norm(minreal(C_lead - C_app), Inf));

w_cmp = [0.1; 1; w_max; 100; 1000];
table(w_cmp, 20*log10(squeeze(abs(freqresp(C_lead, w_cmp)))), ...
    20*log10(squeeze(abs(freqresp(C_app, w_cmp)))), ...
    squeeze(angle(freqresp(C_lead, w_cmp)))*180/pi, ...
    squeeze(angle(freqresp(C_app, w_cmp)))*180/pi, ...
    'VariableNames', {'w_rad_s', '손_크기_dB', '앱_크기_dB', '손_위상', '앱_위상'})

%% 8. 한 단으로 안 되는 플랜트 — 두 단 Lead
%  극점이 세 개인 플랜트는 위상이 빠르게 내려갑니다.
%  Lead 가 wc 를 오른쪽으로 밀면 플랜트가 그만큼 더 깎아 버립니다.

G3 = 10/(s*(s+1)*(s/5+1));

[gm0, pm0b, ~, wc0b] = margin(G3);
fprintf('\n[맨몸] PM = %.2f 도 (불안정), GM = %.2f dB, wc = %.3f\n', ...
    pm0b, 20*log10(gm0), wc0b);

% 1단 : alpha = 0.1 (phi_max 약 54.9 도), w_max = 4.72
al1 = 0.1;  T1 = 1/(4.72*sqrt(al1));
Cl1 = (T1*s + 1)/(al1*T1*s + 1);

% 2단 : alpha = 0.3 (phi_max 약 32.6 도), w_max = 6.76 — 조금 오른쪽에
al2 = 0.3;  T2 = 1/(6.76*sqrt(al2));
Cl2 = (T2*s + 1)/(al2*T2*s + 1);

nm3 = {'맨몸'; '1단 Lead'; '2단 Lead'};
Ls = {G3; minreal(Cl1*G3); minreal(Cl1*Cl2*G3)};
pm3 = zeros(3,1); gm3 = zeros(3,1); wc3 = zeros(3,1); os3 = zeros(3,1);

for k = 1:3
    [g_, p_, ~, w_] = margin(Ls{k});
    pm3(k) = p_; gm3(k) = 20*log10(g_); wc3(k) = w_;
    if p_ > 0
        os3(k) = stepinfo(feedback(Ls{k}, 1)).Overshoot;
    else
        os3(k) = NaN;          % 불안정하면 오버슈트가 뜻이 없다
    end
end

table(nm3, pm3, gm3, wc3, os3, ...
    'VariableNames', {'제어기', 'PM_deg', 'GM_dB', 'wc', 'OS_퍼센트'})

% 읽는 법
%   - 맨몸은 PM 이 음수 (불안정)
%   - 1단으로 PM 23 도까지 올라오지만 아직 모자라다
%   - 2단을 조금 오른쪽에 놓아 PM 41 도, GM 10.6 dB 로 합격
%   보드 선도는 **덧셈**이므로 Lead 를 겹치면 위상 기여도 더해진다.

% 질문
%   - 6절에서 w_max 를 30 으로 올리면 PM 이 어떻게 되나요. 왜 그런가요
%   - 5절에서 phi_max = 70 도를 쓰면 1/alpha 가 몇 배가 되나요
%     그 배율이 센서 잡음에 어떤 뜻인지 11A주차 6절과 연결해 보세요
%   - 8절에서 2단의 w_max 를 1단과 같은 4.72 로 놓으면 결과가 어떻게 달라지나요
