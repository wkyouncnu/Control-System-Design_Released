%% W11A_03 — 위상여유와 감쇠비, 그리고 공명첨두
% 제어시스템설계 · 충남대학교 자율운항시스템공학과
%
% 강의노트 3-4절 ~ 3-4-2절에 대응합니다.
%
% 바꿔 볼 것
%   - 1절의 PM_target 을 20, 45, 70 도로
%   - 3절에서 지배 극점이 아닌 경우를 만들어 어림셈이 깨지는 것 보기

clear; clc; close all;
s = tf('s');

%% 1. 위상여유를 정해 놓고 루프를 만든다
% 2차 표준루프 L = wn^2/(s*(s+2*zeta*wn)) 에서
% zeta 를 PM/100 으로 잡으면 PM 이 대략 목표대로 나옵니다.

PM_target = 45;                 % <-- 20, 45, 70 으로 바꿔 보기
wn = 10;

zeta = PM_target/100;           % 어림셈
L = wn^2/(s*(s + 2*zeta*wn));
T = feedback(L, 1);

[~, PM_actual, ~, wc] = margin(L);
si = stepinfo(T);

fprintf('목표 PM = %g 도\n', PM_target);
fprintf('  zeta = PM/100 = %.3f 로 설계\n', zeta);
fprintf('  실제 PM = %.2f 도   (목표와 %.2f 도 차이)\n', ...
    PM_actual, PM_actual - PM_target);
fprintf('  오버슈트 = %.1f %%\n', si.Overshoot);
fprintf('  wc = %.2f,  wb = %.2f rad/s\n', wc, bandwidth(T));

%% 2. 전 구간에서 어림셈이 얼마나 맞는가
% zeta 를 0.05 부터 1 까지 훑으며 PM 을 재고 PM/100 과 비교합니다.

zv = (0.05:0.05:1.0)';
m = numel(zv);
pmv = zeros(m,1); osv = zeros(m,1); Mrv = zeros(m,1);

for k = 1:m
    Lk = 1/(s*(s + 2*zv(k)));            % wn = 1
    [~, pmv(k)] = margin(Lk);
    Tk = feedback(Lk, 1);
    osv(k) = stepinfo(Tk).Overshoot;
    Mrv(k) = getPeakGain(Tk);
end

rule = pmv/100;                           % 어림셈 결과
err  = rule - zv;                         % 오차

table(zv, pmv, rule, err, osv, Mrv, ...
    'VariableNames', {'zeta_실제', 'PM_deg', 'PM_나누기100', '오차', 'OS_퍼센트', 'Mr'})

tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile; hold on; grid on;
plot(pmv, zv, 'LineWidth', 2.5, 'DisplayName', '실제 관계');
plot(pmv, pmv/100, '--', 'LineWidth', 2, 'DisplayName', 'zeta = PM/100');
xlabel('위상여유 [도]'); ylabel('감쇠비 zeta');
legend('Location', 'southeast');
title('거의 직선 — 그래서 어림셈이 통한다');

nexttile; hold on; grid on;
plot(pmv, err, 'LineWidth', 2.5);
yline(0, 'k--');
yline(0.05, 'k:'); yline(-0.05, 'k:');
xlabel('위상여유 [도]'); ylabel('어림셈 오차');
title('오차가 +-0.05 안에 들어온다');

%% 3. 어림셈이 깨지는 경우 — 지배 극점이 뚜렷하지 않으면
% 폐루프 극점이 비슷한 거리에 둘 이상 있으면 2차 근사가 안 맞습니다.

L_good = 100/(s*(s + 20));              % 지배 극점 쌍이 뚜렷
L_bad  = 100/(s*(s + 2)*(s/12 + 1));    % 세 극점이 섞여 있다

names = {'지배 극점 뚜렷'; '극점이 섞임'};
Ls = {L_good, L_bad};
pm3 = zeros(2,1); os3 = zeros(2,1); z_rule = zeros(2,1); z_real = zeros(2,1);

for k = 1:2
    [~, pm3(k)] = margin(Ls{k});
    Tk = feedback(Ls{k}, 1);
    os3(k) = stepinfo(Tk).Overshoot;
    z_rule(k) = pm3(k)/100;
    % 실제 오버슈트에서 거꾸로 구한 감쇠비
    lo = log(os3(k)/100);
    z_real(k) = -lo/sqrt(pi^2 + lo^2);
end

table(names, pm3, z_rule, z_real, os3, ...
    'VariableNames', {'경우', 'PM_deg', 'zeta_어림셈', 'zeta_실제응답', 'OS_퍼센트'})

% 두 경우의 계단응답을 비교
t = linspace(0, 3, 500)';
hold on; grid on;
plot(t, step(feedback(L_good,1), t), 'LineWidth', 2.5, ...
    'DisplayName', sprintf('지배 극점 뚜렷 (PM %.0f 도)', pm3(1)));
plot(t, step(feedback(L_bad,1), t), 'LineWidth', 2.5, ...
    'DisplayName', sprintf('극점 섞임 (PM %.0f 도)', pm3(2)));
yline(1, 'k:');
xlabel('시간 [s]'); ylabel('출력');
legend('Location', 'southeast');
title('PM 이 비슷해도 응답 모양이 다를 수 있다');

%% 4. 공명첨두 Mr — 주파수영역에서 보는 날카로움
%   Mr = 1/(2*zeta*sqrt(1-zeta^2)),   wr = wn*sqrt(1-2*zeta^2)
% zeta >= 0.707 이면 봉우리가 없다 (Mr = 1).

zr = [0.1 0.2 0.3 0.4 0.5 0.6 0.707 0.8]';
p = numel(zr);
Mr_f = 1./(2*zr.*sqrt(1 - zr.^2));
wr_f = real(sqrt(1 - 2*zr.^2));          % 음수면 봉우리 없음
Mr_m = zeros(p,1); wr_m = zeros(p,1);

for k = 1:p
    Tk = feedback(1/(s*(s + 2*zr(k))), 1);
    [Mr_m(k), wr_m(k)] = getPeakGain(Tk);
end

table(zr, Mr_f, Mr_m, 20*log10(Mr_m), wr_f, wr_m, ...
    'VariableNames', {'zeta', 'Mr_식', 'Mr_실측', 'Mr_dB', 'wr_식', 'wr_실측'})

% zeta = 0.707 을 넘으면 식이 깨지는 것을 그림으로
w = logspace(-1, 1, 400);
hold on; grid on;
for z = [0.2 0.4 0.707 1.0]
    Tz = feedback(1/(s*(s + 2*z)), 1);
    semilogx(w, 20*log10(squeeze(abs(freqresp(Tz, w)))), 'LineWidth', 2, ...
        'DisplayName', sprintf('zeta = %.3f', z));
end
set(gca, 'XScale', 'log');
yline(0, 'k--'); yline(-3, 'k:');
xlabel('주파수 [rad/s]'); ylabel('|T| [dB]');
legend('Location', 'southwest');
title('zeta 0.707 이상에서는 봉우리가 없다');

%% 5. 세 날카로움 지표를 한 표로
% 오버슈트, 공명첨두, 위상여유는 전부 같은 것을 다르게 본 것입니다.

PM_pick = [30 45 60 75]';
q = numel(PM_pick);
z_pick = PM_pick/100;
os_pick = zeros(q,1); Mr_pick = zeros(q,1);

for k = 1:q
    Lk = 1/(s*(s + 2*z_pick(k)));
    Tk = feedback(Lk, 1);
    os_pick(k) = stepinfo(Tk).Overshoot;
    Mr_pick(k) = getPeakGain(Tk);
end

table(PM_pick, z_pick, os_pick, Mr_pick, 20*log10(Mr_pick), ...
    'VariableNames', {'PM_deg', 'zeta', 'OS_퍼센트', 'Mr', 'Mr_dB'})

% 질문
%   - PM 45 도의 오버슈트가 약 20 % 인 것을 확인하세요
%   - Mr <= 2 (6 dB) 조건은 PM 몇 도에 해당하나요
%   - PM 을 75 도로 올리면 무엇을 잃게 되나요 (힌트 : W11A_02 의 2절)
