%% W11B_05 — 종합 설계 : DC 모터 위치제어를 다섯 단계로
% 제어시스템설계 · 충남대학교 자율운항시스템공학과
%
% 강의노트 8절 ~ 8-6절에 대응합니다.
%
% 이번 실습의 핵심 메시지
%
%     사양 네 개를 동시에 지키는 설계를 처음부터 끝까지 한 번 해 본다.
%     그 과정에서 두 가지를 배운다.
%       (1) 한 단으로 안 되면 두 단을 겹친다 (보드 선도는 덧셈이니까)
%       (2) 주파수영역 설계는 수송지연과 제어입력에 대해 아무 말도 안 해 준다.
%           둘 다 설계가 끝난 뒤에 **따로 재야** 한다
%
% 바꿔 볼 것
%   - 4절의 w_cap 을 16, 22, 28 로
%   - 5절의 Td_cap 을 0.01, 0.02, 0.05 로 (어디서 사양이 깨지나)
%   - 6절의 tau_cap 을 0.1, 0.3, 1.0 로 (제어전압이 어떻게 변하나)

clear; clc; close all;
s = tf('s');

%% 0. 경로 자동 등록
if isempty(which('plant_dcmotor'))
    p_ = pwd;
    if ~isempty(mfilename('fullpath')), p_ = fileparts(mfilename('fullpath')); end
    for k_ = 1:4
        if isfile(fullfile(p_,'setup_path.m')), run(fullfile(p_,'setup_path.m')); break; end
        p_ = fileparts(p_);
    end
    clear p_ k_
end

%% 1. 1단계 — 사양을 주파수 숫자로 번역한다
%  5주차부터 쓴 학기 플랜트, DC 모터의 위치제어입니다.
%
%  사양 네 개
%    (1) 0.2 rad/s 램프를 쫓을 때 정상상태오차 0.01 rad 이하
%    (2) 위상여유 50 도 이상
%    (3) 이득여유 6 dB 이상
%    (4) 제어전압 12 V 이하
%
%  (1) 의 번역 : ess = A/Kv 에서 A = 0.2, ess <= 0.01 이므로 Kv >= 20
%  (2) 의 번역 : 그대로 PM >= 50
%  (3) 의 번역 : 그대로 GM >= 6
%  (4) 는 주파수영역의 말로 **번역되지 않는다.** 6절에서 따로 잰다

G_m = plant_dcmotor('position');
G_m

table(pole(G_m), 'VariableNames', {'극점'})

% 읽는 법
%   - 극점이 0, -9.9975, -2.0025 다. 0 이 있으니 **형 1** 이다
%   - 형 1 이므로 계단 오차는 0, 램프 오차는 1/Kv 다 (1번 스크립트 참고)

ess_spec = 0.01;
A_ramp = 0.2;
Kv_need = A_ramp/ess_spec;
pm_spec = 50;
gm_spec = 6;
u_lim = 12;

fprintf('\n[사양 -> 숫자]\n');
fprintf('  Kv >= %.0f,  PM >= %.0f deg,  GM >= %.0f dB,  |u| <= %.0f V\n', ...
    Kv_need, pm_spec, gm_spec, u_lim);

%% 2. 2단계 — K 를 정한다. 그런데 불안정하다
%  Kv 를 손으로 계산합니다. L = K*G_m 이므로
%
%      Kv = lim s*K*G_m = K * 0.01/0.1001 = 0.0999*K
%
%  Kv >= 20 이려면 K >= 200.2 입니다. K = 200 을 씁니다.

Kv_per_K = dcgain(s*G_m);
Kpick = 200;

table(Kv_per_K, Kv_need/Kv_per_K, Kpick, Kpick*Kv_per_K, A_ramp/(Kpick*Kv_per_K), ...
    'VariableNames', {'Kv_단위이득당', '필요한_K', '고른_K', 'Kv', '램프오차'})

%  그 K 로 여유를 재 봅니다.

Kscan = [50; 100; 200; 400];
n2 = numel(Kscan);
pm2 = zeros(n2,1); gm2 = zeros(n2,1); wc2 = zeros(n2,1);

for k = 1:n2
    [g_, p_, ~, w_] = margin(Kscan(k)*G_m);
    gm2(k) = 20*log10(g_); pm2(k) = p_; wc2(k) = w_;
end

table(Kscan, Kscan*Kv_per_K, A_ramp./(Kscan*Kv_per_K), pm2, gm2, wc2, ...
    'VariableNames', {'K', 'Kv', '램프오차', 'PM_deg', 'GM_dB', 'wc'})

% 읽는 법
%   - 사양 (1) 과 사양 (2)(3) 이 **정면으로 충돌한다**
%   - 사양 (1) 이 요구하는 K = 200 에서 PM -10.5 도, GM -4.4 dB. **발산한다**
%   - 여유가 괜찮은 K = 50 은 램프오차 0.04 로 사양 (1) 을 어긴다
%   => K 하나로는 불가능하다. 위상을 올려야 한다

%% 3. 3단계 — 한 단 Lead 로는 모자란다
%  필요한 위상은 50 - (-10.5) = 60.5 도에 여유를 보태 65 도쯤입니다.
%  그런데 한 단은 55 도를 넘기지 말라고 했습니다 (2번 스크립트 5절).
%  일단 55 도로 해 보고, 놓을 자리 wmax 를 훑습니다.

phi_cap = 55;
al_cap = (1 - sind(phi_cap))/(1 + sind(phi_cap));

wscan = (4:1:24)';
n3 = numel(wscan);
pm3 = zeros(n3,1); gm3 = zeros(n3,1); wc3 = zeros(n3,1);

for k = 1:n3
    T_ = 1/(wscan(k)*sqrt(al_cap));
    Ck = Kpick*(T_*s + 1)/(al_cap*T_*s + 1);
    [g_, p_, ~, w_] = margin(Ck*G_m);
    pm3(k) = p_; gm3(k) = 20*log10(g_); wc3(k) = w_;
end

table(wscan, pm3, gm3, wc3, pm3 >= pm_spec, ...
    'VariableNames', {'wmax', 'PM_deg', 'GM_dB', 'wc', 'PM사양_통과'})

[pm_best, i_best] = max(pm3);
fprintf('\n가장 좋은 자리 : wmax = %g  =>  PM %.2f deg (사양 %d deg)\n', ...
    wscan(i_best), pm_best, pm_spec);
fprintf('  alpha = %.6f,  한 단이 주는 위상 = %.1f deg\n', al_cap, phi_cap);
fprintf('  어디에 놓아도 PM 이 27 도를 못 넘는다 => 한 단으로는 불가능\n');

% 읽는 법
%   - 통과 열이 전부 0 이다. **wmax 를 어디에 놓아도 안 된다**
%   - 왜 : 이 플랜트는 극점이 세 개라 위상이 -270 도까지 빠르게 내려간다.
%     Lead 가 크기를 올려 wc 를 오른쪽으로 밀면 플랜트가 그만큼 더 깎는다

%% 4. 4단계 — 두 단 Lead 로 합격
%  같은 Lead 를 두 번 곱합니다. 보드 선도는 덧셈이므로 위상 기여가 두 배입니다.
%  둘 다 같은 자리 wmax 에 놓는 것은 설계를 단순히 하려는 선택입니다.

w_cap = 22;                     % <-- 16, 22, 28 로 바꿔 보기
T_cap = 1/(w_cap*sqrt(al_cap));
C1_cap = (T_cap*s + 1)/(al_cap*T_cap*s + 1);
C_cap = minreal(Kpick*C1_cap*C1_cap);

table(al_cap, T_cap, 1/T_cap, 1/(al_cap*T_cap), -10*log10(al_cap), Kpick/al_cap^2, ...
    'VariableNames', {'alpha', 'T', '영점', '극점', '한단_올림_dB', 'C_고주파이득'})

[g_cap, p_cap, ~, wc_cap] = margin(C_cap*G_m);
T_cl = feedback(C_cap*G_m, 1);
s_cl = stepinfo(T_cl);

table(p_cap, 20*log10(g_cap), wc_cap, bandwidth(T_cl), s_cl.Overshoot, s_cl.SettlingTime, ...
    'VariableNames', {'PM_deg', 'GM_dB', 'wc', 'wb', 'OS_퍼센트', 'ts'})

% 읽는 법
%   - PM 60.6 도, GM 24.0 dB. **이상적인 플랜트에서는 넉넉히 통과한다**
%   - 영점 두 개가 6.94, 극점 두 개가 69.8 이다
%   - 아직 두 가지를 안 봤다 : 수송지연(5절) 과 제어입력(6절)

%% 5. 5단계 — 실제 플랜트로 검증한다 : 수송지연
%  센서가 값을 주기까지 0.02 초가 걸립니다. 라플라스에서는 exp(-s*Td) 입니다.
%
%      |exp(-j*w*Td)| = 1          크기는 하나도 안 바뀐다
%      angle(exp(-j*w*Td)) = -w*Td  위상만 깎인다. 그것도 w 에 비례해서
%
%  손계산 : wc = 8.588 에서 -8.588*0.02 = -0.1718 rad = -9.84 도
%  즉 PM 60.6 -> 50.7 도로 예상됩니다.
%
%  `pade` 로 유리함수로 바꿔 margin 에 넣습니다.
%    - 원리 : exp(-s*Td) 를 같은 차수의 유리함수로 근사. 1차는 (1-sTd/2)/(1+sTd/2)
%    - 입력 : [num, den] = pade(Td, n)
%    - 출력 : 분자·분모 계수. tf(num, den) 으로 만든다
%    - 주의 : 분자에 **불안정 영점**이 생긴다. 그것이 지연을 흉내 내는 방법이다.
%             n = 3 이면 w*Td < 2 쯤까지 믿을 수 있다

Td_cap = 0.02;                  % <-- 0.01, 0.02, 0.05 로 바꿔 보기

fprintf('\n[손계산] wc = %.4f 에서 깎이는 위상\n', wc_cap);
fprintf('  -wc*Td = %.6f rad = %.4f deg\n', -wc_cap*Td_cap, -wc_cap*Td_cap*180/pi);

[nd, dd] = pade(Td_cap, 3);
G_real = G_m*tf(nd, dd);

[g_r, p_r, ~, wc_r] = margin(C_cap*G_real);
T_r = feedback(C_cap*G_real, 1);
s_r = stepinfo(T_r);

nm5 = {'이상 플랜트'; '지연 포함'};
table(nm5, [p_cap; p_r], [20*log10(g_cap); 20*log10(g_r)], [wc_cap; wc_r], ...
    [s_cl.Overshoot; s_r.Overshoot], [s_cl.SettlingTime; s_r.SettlingTime], ...
    'VariableNames', {'플랜트', 'PM_deg', 'GM_dB', 'wc', 'OS_퍼센트', 'ts'})

fprintf('  실측 PM 감소 = %.4f deg  (손계산 %.4f deg)\n', p_cap - p_r, wc_cap*Td_cap*180/pi);

% 읽는 법
%   - 교차주파수가 **똑같다** (8.588). 지연이 크기를 안 건드렸으니까
%   - PM 이 손계산과 소수 둘째 자리까지 일치하게 떨어졌다
%   - GM 은 24.0 -> 13.5 dB 로 크게 떨어졌다
%   - 오버슈트 14.5 -> 20.5 %
%   => 앱에서 본 60.6 도는 **실제 여유가 아니었다.** 앱은 지연을 모른다

wd = logspace(-1, 3, 800);
tiledlayout(2, 1, 'TileSpacing', 'compact');

nexttile; hold on; grid on;
semilogx(wd, 20*log10(squeeze(abs(freqresp(C_cap*G_m, wd)))), 'LineWidth', 3);
semilogx(wd, 20*log10(squeeze(abs(freqresp(C_cap*G_real, wd)))), '--', 'LineWidth', 2);
set(gca, 'XScale', 'log');
yline(0, 'k--'); xline(wc_cap, 'k:', 'LineWidth', 1.5);
xlabel('주파수 [rad/s]'); ylabel('|L| [dB]');
legend('지연 없음', '지연 0.02 s', 'Location', 'southwest');
title('크기는 완전히 겹친다 — wc 가 안 변하는 이유');

nexttile; hold on; grid on;
semilogx(wd, squeeze(angle(freqresp(C_cap*G_m, wd)))*180/pi, 'LineWidth', 3);
semilogx(wd, squeeze(angle(freqresp(C_cap*G_real, wd)))*180/pi, '--', 'LineWidth', 2);
set(gca, 'XScale', 'log');
yline(-180, 'k--'); xline(wc_cap, 'k:', 'LineWidth', 1.5);
xlabel('주파수 [rad/s]'); ylabel('angle(L) [deg]');
title('위상만 깎인다 — 세로 점선에서의 간격이 잃는 PM 이다');

%% 6. 마지막 확인 — 제어입력
%  사양 (4) 가 남았습니다. 주파수영역 설계는 u 에 대해 아무 말도 안 해 줍니다.
%
%      u = C*e = C(r - y),   y = G*u   =>   (1 + C*G)u = C*r
%
%      u/r = C/(1 + C*G)
%
%  s -> inf 에서 G -> 0 이므로 이 값은 C(inf) = K/alpha^2 로 갑니다.
%  손계산 : 200/0.099413^2 = 20237. 계단 지령이면 첫 순간에 20237 V 가 필요합니다.

Gu_cap = minreal(C_cap/(1 + C_cap*G_real));
t_cap = (0:1e-4:4)';

u_step = lsim(Gu_cap, ones(size(t_cap)), t_cap);
table(Kpick/al_cap^2, max(abs(u_step)), u_lim, ...
    'VariableNames', {'공식_K_over_alpha2', '실측_umax_계단', '한계_V'})

%  그런데 사양 (1) 은 **램프** 지령이었습니다. 게다가 실제 장비는 지령을
%  갑자기 꺾지 않고 매끄럽게 올립니다. 그 지령으로 다시 잽니다.

tau_cap = 0.3;                  % <-- 0.1, 0.3, 1.0 로 바꿔 보기
r_cap = A_ramp*(t_cap - tau_cap*(1 - exp(-t_cap/tau_cap)));

u_cap = lsim(Gu_cap, r_cap, t_cap);
y_cap = lsim(feedback(C_cap*G_real, 1), r_cap, t_cap);

table(max(abs(u_cap)), u_lim, r_cap(end) - y_cap(end), ess_spec, ...
    'VariableNames', {'umax_V', '한계_V', '정상상태오차', '사양'})

% 읽는 법
%   - 계단은 20237 V. 공식과 실측이 정확히 같다. **이 설계로 계단은 불가능하다**
%   - 매끄러운 램프는 4.2 V. 한계 12 V 안에 들어온다
%   => 지령의 모양을 정하는 것도 설계의 일부다

figure;
tiledlayout(2, 1, 'TileSpacing', 'compact');

nexttile; hold on; grid on;
plot(t_cap, r_cap, '--', 'LineWidth', 2);
plot(t_cap, y_cap, 'LineWidth', 2.2);
xlabel('시간 [s]'); ylabel('위치 [rad]');
legend('지령 (매끄러운 램프)', '출력', 'Location', 'northwest');
title('사양 (1) — 간격이 0.01 rad');

nexttile; hold on; grid on;
plot(t_cap, u_cap, 'LineWidth', 2.2);
yline(u_lim, 'r--', 'LineWidth', 1.5);
yline(-u_lim, 'r--', 'LineWidth', 1.5);
xlabel('시간 [s]'); ylabel('제어전압 [V]'); ylim([-14 14]);
legend('u', '한계', 'Location', 'northeast');
title('사양 (4) — 한계 안에 들어온다');

%% 7. 사양 네 개 성적표
spec_nm = {'(1) 램프오차 <= 0.01 rad'; '(2) PM >= 50 deg'; ...
           '(3) GM >= 6 dB'; '(4) |u| <= 12 V'};
got = [r_cap(end) - y_cap(end); p_r; 20*log10(g_r); max(abs(u_cap))];
want = [ess_spec; pm_spec; gm_spec; u_lim];
pass = [got(1) <= want(1); got(2) >= want(2); got(3) >= want(3); got(4) <= want(4)];

table(spec_nm, got, want, pass, 'VariableNames', {'사양', '얻은값', '요구값', '통과'})

% 읽는 법
%   - (2)(3)(4) 는 통과다
%   - **(1) 이 간신히 불합격이다.** 0.01001 과 0.01 의 차이, 0.1 % 다
%     원인은 2절에서 K 를 200.2 에서 **200 으로 내린** 것이다
%   => 사양이 값을 정해 줄 때는 **올림**을 해야 한다. 아래에서 고친다

%% 7-1. 고치기 — K 를 올림한다
%  K 를 210 으로 올리고 같은 Lead 두 단을 그대로 씁니다.
%  Lead 는 비율만 정하므로 K 를 바꿔도 모양은 같습니다. 숫자만 다시 잽니다.

Kfix = 210;
C_fix = minreal(Kfix*C1_cap*C1_cap);

[g_f, p_f, ~, ~] = margin(C_fix*G_real);
Gu_fix = minreal(C_fix/(1 + C_fix*G_real));
u_fix = lsim(Gu_fix, r_cap, t_cap);
y_fix = lsim(feedback(C_fix*G_real, 1), r_cap, t_cap);

got_f = [r_cap(end) - y_fix(end); p_f; 20*log10(g_f); max(abs(u_fix))];
pass_f = [got_f(1) <= want(1); got_f(2) >= want(2); ...
          got_f(3) >= want(3); got_f(4) <= want(4)];

table(spec_nm, got, got_f, want, pass_f, ...
    'VariableNames', {'사양', 'K_200', 'K_210', '요구값', 'K_210_통과'})

% 읽는 법
%   - 램프오차 0.01001 -> 0.009533. **통과**
%   - 그 대가로 PM 50.73 -> 50.35 도, GM 13.47 -> 13.04 dB 로 조금 줄었다
%     K 를 올리면 wc 가 오른쪽으로 가고 지연이 그만큼 더 깎기 때문이다
%   - umax 4.20 -> 4.34 V. 여전히 한계 안
%   => **네 사양 전부 통과.** 여유가 빠듯하므로 실물에서는 재검증이 필요하다

fprintf('\n최종 제어기 (K = %d)\n', Kpick);
C_cap
fprintf('  = %.0f * [(%.5f s + 1)/(%.5f s + 1)]^2\n', Kpick, T_cap, al_cap*T_cap);
fprintf('  앱 형식으로는  %.1f * (s + %.4f)^2/(s + %.4f)^2\n', ...
    Kpick/al_cap^2, 1/T_cap, 1/(al_cap*T_cap));
fprintf('\n이 계수를 6번 스크립트의 Simulink 모델에 넣어 교차 검증한다.\n');

% 질문
%   - 5절의 Td_cap 을 0.05 로 올리면 PM 이 몇 도가 되나요. 사양이 깨지나요
%     손계산 -wc*Td 로 미리 예측한 뒤 확인해 보세요
%   - 4절의 w_cap 을 16 으로 내리면 PM 과 umax 가 어떻게 되나요
%     (위상을 덜 벌면 제어입력도 줄어듭니다. 그 교환이 보이나요)
%   - 6절의 tau_cap 을 0.1 로 줄이면 umax 가 몇 V 가 되나요
%     지령을 급하게 꺾을수록 전압이 더 필요한 이유를 말로 설명해 보세요
