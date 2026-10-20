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

%% 3. 어림셈이 깨지는 경우 — 세 가지
% 2절에서 본 어림셈은 루프가 **2차 표준형에 가까울 때만** 맞습니다.
% 어긋나는 방식이 세 가지 있고, 셋 다 PM 은 비슷하게 좋아 보입니다.
%
%   (가) 2차에 가깝다        — 어림셈이 맞는다 (비교 기준)
%   (나) 폐루프 영점이 있다   — 오버슈트가 예측보다 **커진다**
%   (다) 공진이 숨어 있다     — 오버슈트는 0 인데 **끝없이 흔들린다**
%
% 비교 방법 : PM 에서 zeta = PM/100 을 얻고, 그 zeta 로 오버슈트를 예측해
%             실제 오버슈트와 맞대 봅니다. 예측식은 4주차의 그 식입니다.
%
%   OS = 100*exp(-pi*zeta/sqrt(1-zeta^2))

L_a = 100/(s*(s + 10));                     % (가) 극점 두 개, 2차 표준형
L_b = 40*(s + 2)/(s^2*(s + 10));            % (나) 영점 s=-2 가 폐루프에 남는다
L_c = 5*(s + 1)/(s*(s^2 + 0.4*s + 100));    % (다) 플랜트에 공진 (wn=10, zeta=0.02)

names = {'(가) 2차에 가깝다'; '(나) 폐루프 영점'; '(다) 숨은 공진'};
Ls    = {L_a, L_b, L_c};
t_end = [2 3 40];                           % 경우마다 볼 시간이 다르다

pm3 = zeros(3,1); zr3 = zeros(3,1);
os_pred = zeros(3,1); os_meas = zeros(3,1); z_min = zeros(3,1);

for k = 1:3
    [~, pm3(k)] = margin(Ls{k});
    Tk = feedback(Ls{k}, 1);

    zr3(k) = pm3(k)/100;                                        % 어림셈
    os_pred(k) = 100*exp(-pi*zr3(k)/sqrt(1 - zr3(k)^2));        % 그 zeta 의 예측

    tk = linspace(0, t_end(k), 4000)';
    yk = step(Tk, tk);
    os_meas(k) = (max(yk)/yk(end) - 1)*100;                     % 실측

    [~, zk] = damp(Tk);
    z_min(k) = min(zk);                                         % 가장 약하게 감쇠된 극점
end

table(names, pm3, zr3, os_pred, os_meas, z_min, ...
    'VariableNames', {'경우', 'PM_deg', 'zeta_어림셈', ...
                      'OS_예측_퍼센트', 'OS_실측_퍼센트', 'zeta_폐루프_최소'})

% 읽는 법
%   (가) 예측 14.9 % 대 실측 16.3 %  -> 어림셈이 쓸 만하다
%   (나) 예측 23.7 % 대 실측 37.3 %  -> 영점 때문에 1.6 배 커졌다
%   (다) 예측 17.7 % 대 실측  0.0 %  -> 오버슈트는 없는데 마지막 열이 0.017 이다
%        즉 PM 48 도를 믿고 "잘 설계했다" 고 하면 안 된다.
%        PM 은 교차주파수 한 점만 보기 때문에 공진을 못 본다.

tiledlayout(1, 3, 'TileSpacing', 'compact');

for k = 1:3
    nexttile; hold on; grid on;
    tk = linspace(0, t_end(k), 4000)';
    plot(tk, step(feedback(Ls{k},1), tk), 'LineWidth', 2.2);
    yline(1, 'k:');
    xlabel('시간 [s]'); ylabel('출력');
    title(sprintf('%s\nPM %.0f 도 · 예측 %.0f %% · 실측 %.0f %%', ...
        names{k}, pm3(k), os_pred(k), os_meas(k)));
end

% 오른쪽 그림의 잔물결 주기가 0.62 초인 것을 확인하세요.
% 공진 주파수 10.2 rad/s 가 그대로 출력에 남아 있다는 뜻입니다.

%% 4. 공명첨두 Mr — 주파수영역에서 보는 날카로움
%   Mr = 1/(2*zeta*sqrt(1-zeta^2)),   wr = wn*sqrt(1-2*zeta^2)
% zeta >= 0.707 이면 봉우리가 없다 (Mr = 1).

zr = [0.1 0.2 0.3 0.4 0.5 0.6 0.707 0.8]';
p = numel(zr);

% [주의] 두 식은 zeta < 1/sqrt(2) = 0.7071 에서만 뜻이 있습니다.
%        그 위에서는 봉우리가 아예 없어서 "봉우리 위치" 를 물을 수 없습니다.
%        식을 그냥 계산하면 Mr 이 1 보다 큰 값으로 나와 실측과 어긋납니다.
%        그래서 유효 구간 밖은 NaN 으로 비워 둡니다.
yes = zr < 1/sqrt(2);

Mr_f = nan(p,1); wr_f = nan(p,1);
Mr_f(yes) = 1./(2*zr(yes).*sqrt(1 - zr(yes).^2));
wr_f(yes) = sqrt(1 - 2*zr(yes).^2);     % wn = 1 로 두었으므로 그대로 wr

Mr_m = zeros(p,1); wr_m = zeros(p,1);

for k = 1:p
    Tk = feedback(1/(s*(s + 2*zr(k))), 1);
    [Mr_m(k), wr_m(k)] = getPeakGain(Tk);
end

table(zr, Mr_f, Mr_m, 20*log10(Mr_m), wr_f, wr_m, ...
    'VariableNames', {'zeta', 'Mr_식', 'Mr_실측', 'Mr_dB', 'wr_식', 'wr_실측'})

% 읽는 법
%   - zeta 0.6 까지는 식과 실측이 소수 넷째 자리까지 같다
%   - zeta = 0.707 은 경계다. 식은 wr = 0.0174 라는 아주 작은 값을 주고
%     실측은 0 을 준다. 봉우리가 막 사라지는 지점이라 그렇다
%   - zeta = 0.8 은 NaN 이다. 봉우리가 없으니 Mr 은 그냥 1 (0 dB) 이다

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
