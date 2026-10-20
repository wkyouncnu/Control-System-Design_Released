%% W11A_02 — 네 숫자 : 교차주파수, 이득여유, 위상여유, 대역폭
% 제어시스템설계 · 충남대학교 자율운항시스템공학과
%
% 강의노트 3절 ~ 3-3-1절에 대응합니다.
%
% 바꿔 볼 것
%   - 1절의 K 를 올려 가며 PM 이 줄어드는 것을 보기
%   - 3절의 zeta_list 에 다른 값 넣기
%   - 4절의 사양(OS, ts)을 바꿔 목표 wc 가 어떻게 변하는지 보기

clear; clc; close all;
s = tf('s');

%% 1. margin 으로 세 숫자를 한 번에 읽는다
% margin 은 [GM, PM, w180, wc] 를 돌려줍니다.
%   GM 은 배수(dB 아님). dB 로 보려면 20*log10(GM)
%   w180 은 위상이 -180 도가 되는 주파수
%   wc 는 크기가 0 dB 가 되는 주파수

K = 1;                          % <-- 1, 5, 20, 50 으로 바꿔 보기

G = 100/(s*(s + 2)*(s + 10));   % 극점 셋 (적분기 포함)
L = K*G;

[GM, PM, w180, wc] = margin(L);

fprintf('K = %g\n', K);
fprintf('  GM    = %.3f 배 = %.2f dB\n', GM, 20*log10(GM));
fprintf('  w180  = %.3f rad/s   (위상이 -180 도인 곳)\n', w180);
fprintf('  PM    = %.2f deg\n', PM);
fprintf('  wc    = %.3f rad/s   (크기가 0 dB 인 곳)\n', wc);

% 정의대로 손으로 확인합니다.
mag_at_w180 = abs(freqresp(L, w180));
pha_at_wc   = rad2deg(angle(freqresp(L, wc)));

table([20*log10(GM); PM], [-20*log10(mag_at_w180); 180 + pha_at_wc], ...
    'RowNames', {'GM_dB', 'PM_deg'}, ...
    'VariableNames', {'margin_값', '정의대로_계산'})

%% 2. 이득을 올리면 네 숫자가 어떻게 변하는가
% 이득을 올리면 곡선 전체가 위로 올라갑니다.
%   -> wc 가 오른쪽으로 간다 (빨라진다)
%   -> 그 자리의 위상이 더 깎여 있으므로 PM 이 줄어든다
%   -> GM 도 줄어든다

K_list = [1 2 5 10 20 50]';
n = numel(K_list);
GMv = zeros(n,1); PMv = zeros(n,1); wcv = zeros(n,1);
wbv = zeros(n,1); OSv = zeros(n,1);

for k = 1:n
    Lk = K_list(k)*G;
    [g, p, ~, c] = margin(Lk);
    Tk = feedback(Lk, 1);
    GMv(k) = 20*log10(g);  PMv(k) = p;  wcv(k) = c;
    wbv(k) = bandwidth(Tk);
    OSv(k) = stepinfo(Tk).Overshoot;
end

table(K_list, GMv, PMv, wcv, wbv, wbv./wcv, OSv, ...
    'VariableNames', {'K', 'GM_dB', 'PM_deg', 'wc', 'wb', '비율', 'OS_퍼센트'})

% 그림으로
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile; hold on; grid on;
plot(K_list, PMv, '-o', 'LineWidth', 2, 'DisplayName', 'PM [도]');
plot(K_list, GMv, '-s', 'LineWidth', 2, 'DisplayName', 'GM [dB]');
yline(45, 'k:', 'PM 45 도');
yline(6, 'k--', 'GM 6 dB');
xlabel('이득 K'); ylabel('여유');
legend('Location', 'northeast');
title('이득을 올리면 두 여유가 함께 줄어든다');

nexttile; hold on; grid on;
plot(K_list, wcv, '-o', 'LineWidth', 2, 'DisplayName', 'wc (개루프)');
plot(K_list, wbv, '-s', 'LineWidth', 2, 'DisplayName', 'wb (폐루프)');
xlabel('이득 K'); ylabel('주파수 [rad/s]');
legend('Location', 'southeast');
title('둘 다 오른쪽으로 — 빨라진다');

%% 3. 2차 표준루프 — 손유도한 두 공식을 실측과 대조한다
%   wc = wn * sqrt(sqrt(1+4*z^4) - 2*z^2)
%   wb = wn * sqrt(1 - 2*z^2 + sqrt(2 - 4*z^2 + 4*z^4))
% wn = 1 로 두면 비율이 그대로 보입니다.

zeta_list = (0.1:0.1:1.0)';     % <-- 값을 추가해 보기
m = numel(zeta_list);
wc_f = sqrt(sqrt(1 + 4*zeta_list.^4) - 2*zeta_list.^2);
wb_f = sqrt(1 - 2*zeta_list.^2 + sqrt(2 - 4*zeta_list.^2 + 4*zeta_list.^4));

wc_m = zeros(m,1); wb_m = zeros(m,1); pm_m = zeros(m,1);
for k = 1:m
    z = zeta_list(k);
    Lk = 1/(s*(s + 2*z));        % wn = 1 인 2차 표준루프
    [~, pm_m(k), ~, wc_m(k)] = margin(Lk);
    wb_m(k) = bandwidth(feedback(Lk, 1));
end

table(zeta_list, wc_f, wc_m, wb_f, wb_m, wb_f./wc_f, pm_m, ...
    'VariableNames', {'zeta', 'wc_식', 'wc_실측', 'wb_식', 'wb_실측', '비율', 'PM_deg'})

hold on; grid on;
plot(zeta_list, wc_f, 'LineWidth', 2.5, 'DisplayName', 'wc 공식');
plot(zeta_list, wc_m, 'o', 'MarkerSize', 8, 'DisplayName', 'wc 실측');
plot(zeta_list, wb_f, 'LineWidth', 2.5, 'DisplayName', 'wb 공식');
plot(zeta_list, wb_m, 's', 'MarkerSize', 8, 'DisplayName', 'wb 실측');
xlabel('감쇠비 zeta'); ylabel('주파수 / wn');
legend('Location', 'northeast');
title('식과 실측이 겹친다 — 유도가 맞았다');

% zeta = 0.7071 에서 wb 가 정확히 wn 이 되는 것을 확인
z0 = 1/sqrt(2);
fprintf('\nzeta = 0.7071 일 때 wb/wn = %.6f  (정확히 1 이어야 한다)\n', ...
    sqrt(1 - 2*z0^2 + sqrt(2 - 4*z0^2 + 4*z0^4)));

%% 4. 사양을 주파수 목표로 번역한다
% 오버슈트와 정착시간 사양 -> zeta, wn -> PM, wc 목표

OS_req = 10;                    % <-- 오버슈트 사양 [%]
ts_req = 0.5;                   % <-- 정착시간 사양 [s]

lnOS   = log(OS_req/100);
z_req  = -lnOS/sqrt(pi^2 + lnOS^2);
PM_req = 100*z_req;                       % 어림셈 zeta = PM/100
wn_req = 4/(z_req*ts_req);                % 2 % 기준
wc_req = wn_req*sqrt(sqrt(1 + 4*z_req^4) - 2*z_req^2);
wb_req = wn_req*sqrt(1 - 2*z_req^2 + sqrt(2 - 4*z_req^2 + 4*z_req^4));

fprintf('\n사양 : OS <= %g %%, ts <= %g s\n', OS_req, ts_req);
fprintf('  -> zeta >= %.4f\n', z_req);
fprintf('  -> PM   >= %.1f deg   (설계 목표)\n', PM_req);
fprintf('  -> wn   >= %.2f rad/s\n', wn_req);
fprintf('  -> wc   >= %.2f rad/s  (설계 목표)\n', wc_req);
fprintf('  -> wb      %.2f rad/s  (예상)\n', wb_req);

% 거꾸로 확인 : 이 zeta, wn 으로 만든 루프가 정말 사양을 만족하는가
Lreq = wn_req^2/(s*(s + 2*z_req*wn_req));
Treq = feedback(Lreq, 1);
si = stepinfo(Treq);
[~, pmc, ~, wcc] = margin(Lreq);

table(si.Overshoot, si.SettlingTime, si.RiseTime, pmc, wcc, ...
    'VariableNames', {'OS_퍼센트', 'ts_초', 'tr_초', 'PM_deg', 'wc'})

%% 5. bandwidth 를 잘못 쓰는 흔한 실수
% 개루프를 넣으면 전혀 다른 숫자가 나옵니다. 반드시 폐루프를 넣습니다.

L5 = 100/(s*(s + 10));
T5 = feedback(L5, 1);

fprintf('\n옳은 사용 : bandwidth(폐루프) = %.3f rad/s\n', bandwidth(T5));
fprintf('잘못된 사용 : bandwidth(개루프) = %.3f rad/s  <- 의미 없는 값\n', ...
    bandwidth(L5));
[~, ~, ~, wc5] = margin(L5);
fprintf('참고 : margin 의 wc = %.3f rad/s\n', wc5);

% DC 이득이 1 이 아닌 경우도 봅니다.
T6 = 5*100/(s^2 + 10*s + 100);          % DC 이득 5
fprintf('\nDC 이득 %g 인 폐루프\n', dcgain(T6));
fprintf('  bandwidth 기본 (DC 대비 -3 dB) : %.3f rad/s\n', bandwidth(T6));
fprintf('  절대 -3 dB 기준으로 하려면 둘째 인수를 준다\n');
