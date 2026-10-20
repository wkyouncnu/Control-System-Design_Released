%% W11B_01 — 설계의 1단계는 항상 K : 정상상태 오차로 K 를 정한다
% 제어시스템설계 · 충남대학교 자율운항시스템공학과
%
% 강의노트 2절 ~ 2-3절에 대응합니다.
%
% 이번 실습의 핵심 메시지
%
%     주파수영역 설계는 "모양을 그린다" 가 아니라
%     "사양이 K 를 정해 주고, 그 K 가 만든 문제를 제어기로 고친다" 는 순서다.
%     그래서 1단계는 언제나 K 다.
%
% 바꿔 볼 것
%   - 1절의 ess_spec 을 0.1, 0.01, 0.001 로
%   - 3절의 Kv_list 에 다른 K 를 넣어 보기
%   - 4절의 램프 기울기 slope 를 2 로 (오차가 두 배가 되는지 확인)

clear; clc; close all;
s = tf('s');

%% 0. 경로 자동 등록
%  (실습 내용과 상관없습니다. 지우지 마십시오.)
if isempty(which('plant_msd'))
    p_ = pwd;
    if ~isempty(mfilename('fullpath')), p_ = fileparts(mfilename('fullpath')); end
    for k_ = 1:4
        if isfile(fullfile(p_,'setup_path.m')), run(fullfile(p_,'setup_path.m')); break; end
        p_ = fileparts(p_);
    end
    clear p_ k_
end

%% 1. 사양 하나가 K 를 정해 버린다
%  오늘의 플랜트입니다. 형(type) 이 1 이므로 계단 오차는 0, 램프 오차는 1/Kv 입니다.
%
%      G(s) = 1/(s(s+1))
%
%  램프 지령에 대한 오차를 ess_spec 이하로 만들고 싶습니다.
%  Kv = lim s*K*G(s) = K 이므로 K >= 1/ess_spec 입니다.

G = 1/(s*(s+1));

ess_spec = 0.01;                % <-- 0.1, 0.01, 0.001 로 바꿔 보기

Kv_per_K = dcgain(s*G);         % K = 1 일 때의 Kv
K_need = 1/(ess_spec*Kv_per_K);

fprintf('플랜트 G = 1/(s(s+1))\n');
fprintf('  K = 1 일 때 Kv = %.4f\n', Kv_per_K);
fprintf('  램프 오차 %.4f 이하를 원하면  K >= %.2f\n', ess_spec, K_need);
fprintf('  => K = %.0f 으로 정한다 (더 쓸 이유가 없다)\n', ceil(K_need));

K = ceil(K_need);

%% 2. 왜 lim s*G 가 Kv 인가 — 손으로 한 번
%  최종값 정리로 오차를 구합니다. 램프 지령은 R(s) = 1/s^2 입니다.
%
%      E(s) = R(s)/(1 + KG(s)) = (1/s^2)/(1 + KG(s))
%
%      ess = lim_{s->0} s*E(s) = lim_{s->0} 1/(s*(1 + KG(s)))
%          = lim_{s->0} 1/(s + s*K*G(s))
%
%  s -> 0 에서 s 는 사라지고 s*K*G(s) -> Kv 만 남습니다. 그래서 ess = 1/Kv 입니다.
%  이 유도에서 **s 를 곱하는 까닭**이 보입니다. 램프의 1/s^2 중 하나를 없애는 것입니다.

L = K*G;
Kv = dcgain(s*L);

fprintf('\n[검산] K = %d 일 때\n', K);
fprintf('  Kv = lim s*L = %.4f\n', Kv);
fprintf('  공식 오차 1/Kv = %.6f  (사양 %.6f)\n', 1/Kv, ess_spec);

%% 3. K 를 바꿔 가며 네 가지를 한꺼번에 본다
%  정상상태는 좋아지는데 과도응답이 나빠지는 것을 한 표에서 봅니다.

Kv_list = [1; 10; 100]';        % <-- 다른 K 를 넣어 보기
n = numel(Kv_list);

ess_v = zeros(n,1); pm_v = zeros(n,1); wc_v = zeros(n,1);
os_v = zeros(n,1); wb_v = zeros(n,1);

for k = 1:n
    Lk = Kv_list(k)*G;
    ess_v(k) = 1/dcgain(s*Lk);
    [~, pm_v(k), ~, wc_v(k)] = margin(Lk);
    Tk = feedback(Lk, 1);
    os_v(k) = stepinfo(Tk).Overshoot;
    wb_v(k) = bandwidth(Tk);
end

table(Kv_list', ess_v, pm_v, wc_v, wb_v, os_v, ...
    'VariableNames', {'K', '램프오차', 'PM_deg', 'wc', 'wb', 'OS_퍼센트'})

% 읽는 법
%   - 램프오차는 K 에 **반비례**한다. K 를 10 배 하면 오차가 1/10
%   - PM 은 K 를 10 배 하면 **3 분의 1** 로 줄어든다 (51.8 -> 18.0 -> 5.7)
%   - 오버슈트는 16 % -> 60 % -> 85 % 로 커진다
%   - wc 와 wb 는 커진다. 빨라지기는 한다
%   그래서 K 는 "정확도를 사는 값" 이고, "안정성으로 지불" 한다.

%% 4. 램프를 실제로 넣어 본다 — 공식과 실측 대조
%  공식만 믿지 않습니다. lsim 으로 램프를 넣고 마지막 오차를 재서 비교합니다.

slope = 1;                      % <-- 2 로 바꿔 보기 (오차가 두 배가 되는지)
t = (0:0.01:20)';
r = slope*t;

e_last = zeros(n,1);
for k = 1:n
    Tk = feedback(Kv_list(k)*G, 1);
    y = lsim(Tk, r, t);
    e = r - y;
    e_last(k) = e(end);
end

table(Kv_list', slope*ess_v, e_last, ...
    'VariableNames', {'K', '공식_slope_over_Kv', '실측_마지막오차'})

tiledlayout(2, 1, 'TileSpacing', 'compact');

nexttile; hold on; grid on;
plot(t, r, 'k--', 'LineWidth', 2, 'DisplayName', '지령 r = t');
for k = 1:n
    Tk = feedback(Kv_list(k)*G, 1);
    plot(t, lsim(Tk, r, t), 'LineWidth', 2, ...
        'DisplayName', sprintf('K = %g', Kv_list(k)));
end
xlabel('시간 [s]'); ylabel('출력');
legend('Location', 'northwest');
title('램프 지령 — 나란히 가지만 간격이 남는다');

nexttile; hold on; grid on;
for k = 1:n
    Tk = feedback(Kv_list(k)*G, 1);
    plot(t, r - lsim(Tk, r, t), 'LineWidth', 2, ...
        'DisplayName', sprintf('K = %g', Kv_list(k)));
end
yline(ess_spec, 'r--', 'LineWidth', 1.5, 'DisplayName', '사양');
xlabel('시간 [s]'); ylabel('오차 r - y'); ylim([-0.2 1.2]);
legend('Location', 'northeast');
title('그 간격이 바로 1/Kv 다');

%% 5. 형(type) 이 하나 낮으면 어떻게 되는가
%  형 0 플랜트와 비교합니다. 같은 K = 100 인데 결과가 다릅니다.

G0 = 1/((s+1)*(s/5+1));         % 형 0 (적분기가 없다)

L1 = 100*G;                     % 형 1
L0 = 100*G0;                    % 형 0

nm = {'형 1 : 1/(s(s+1))'; '형 0 : 1/((s+1)(s/5+1))'};
Kp_v = [dcgain(L1); dcgain(L0)];
Kv_v = [dcgain(s*L1); dcgain(s*L0)];
e_step = 1./(1 + Kp_v);
e_ramp = 1./Kv_v;

table(nm, Kp_v, Kv_v, e_step, e_ramp, ...
    'VariableNames', {'플랜트', 'Kp', 'Kv', '계단오차', '램프오차'})

% 읽는 법
%   - 형 1 은 계단 오차가 0 이다 (Kp = Inf). 적분기가 하나 있으니까
%   - 형 0 은 계단 오차가 1/(1+Kp) = 0.0099 로 **남는다**
%   - 형 0 은 램프를 아예 못 따라간다 (Kv = 0 이므로 오차가 Inf)
%   그래서 형 0 플랜트에서 계단 오차를 0 으로 만들려면
%   **제어기가 적분기를 가져야** 한다. 그것이 PI 다 (강의노트 5절).

%% 6. 그래서 2단계가 필요하다
%  K = 100 으로 사양 하나는 지켰습니다. 그 결과를 봅니다.

L_pick = 100*G;
T_pick = feedback(L_pick, 1);
[gm, pm, ~, wc] = margin(L_pick);
si = stepinfo(T_pick);

fprintf('\n[K = 100 의 성적표]\n');
fprintf('  램프 오차 : %.4f   (사양 0.01 — 합격)\n', 1/dcgain(s*L_pick));
fprintf('  PM        : %.2f 도  (보통 45 도 이상을 원한다 — 불합격)\n', pm);
fprintf('  GM        : %.2f dB\n', 20*log10(gm));
fprintf('  오버슈트  : %.1f %%  (보통 20 %% 이하를 원한다 — 불합격)\n', si.Overshoot);
fprintf('  정착시간  : %.2f s\n', si.SettlingTime);
fprintf('  wc        : %.2f rad/s\n', wc);
fprintf('\n  => K 는 못 건드린다 (사양이 정했다). 모양을 바꿀 수단이 필요하다.\n');

% 질문
%   - ess_spec 을 0.001 로 하면 K 가 1000 이 됩니다. PM 은 몇 도가 되나요
%   - 5절의 형 0 플랜트에서 K 를 1000 으로 올리면 계단 오차가 0 이 되나요
%   - 3절 표에서 "K 를 10 배 하면 PM 이 3 분의 1" 이라는 규칙이
%     왜 성립하는지 보드 선도의 기울기로 설명해 보세요 (힌트 : -40 dB/dec 구간)
