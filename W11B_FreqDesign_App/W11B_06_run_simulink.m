%% W11B_06_run_simulink.m
%  11B주차 실습 (6) : 앱에서 설계한 제어기를 Simulink 로 검증한다
%
%  이번 실습의 핵심 메시지
%
%      controlSystemDesigner 앱은 **유리함수만** 다루고, 화면에 u 가 없다.
%      그래서 앱에서 "통과" 가 떠도 아직 두 가지를 모른다.
%          (가) 진짜 수송지연 e^(-s*Td) 를 넣으면 여유가 얼마나 깎이는가
%          (나) 제어입력 u 가 모터 전압 한계를 넘지 않는가
%      이 두 가지를 확인하는 자리가 Simulink 다.
%
%  강의노트와의 대응
%      9 절      모델의 블록 구성과 세 가지 대조
%      8-4 절    이상 플랜트에서의 여유 (지연을 끄면 여기로 돌아온다)
%      8-5 절    지연 0.02 초 — pade 예측과 진짜 지연의 비교
%      8-6 절    매끄러운 램프의 umax = 4.2 V, 계단은 20237 V 라서 불가능
%
%  바꿔 볼 것
%      Td        0 으로 두면 앱의 결과와 정확히 같아진다
%      tau       지령의 완만함. 0.3 -> 0.01 로 줄이면 포화가 걸린다
%      u_sat     구동기 한계. 1e9 로 두면 사실상 포화를 끈 것이다
%      r_slope   지령 속도 [rad/s]. 사양은 0.2 였다
%
%  [Simulink 만으로도 볼 수 있습니다]
%      >> open_system('W11B_FreqDesign')
%  지령 완만화 필터를 더블클릭해 분모의 tau 를 바꿔 보십시오.
%
%  제어시스템설계 11B주차 | 충남대학교 자율운항시스템공학과

clc; clear all; close all;

%% 0. 경로 자동 등록 — setup_path 를 아직 안 했어도 알아서 잡습니다
%  (이 블록은 실습 내용과 상관없습니다. 지우지 마십시오.)
if isempty(which('plant_dcmotor'))
    p_ = pwd;
    if ~isempty(mfilename('fullpath')), p_ = fileparts(mfilename('fullpath')); end
    for k_ = 1:4
        if isfile(fullfile(p_,'setup_path.m')), run(fullfile(p_,'setup_path.m')); break; end
        p_ = fileparts(p_);
    end
    clear p_ k_
end
s = tf('s');

model = 'W11B_FreqDesign';
if ~bdIsLoaded(model), load_system(model); end

% 아래에서 같은 모델을 여러 번 돌립니다. 그때마다 Scope 창이 뜨면 번거로우므로
% 자동 열기를 잠시 끕니다. 맨 마지막에 원래대로 돌려 놓습니다.
cfg_y = get_param([model '/Scope 위치'], 'ScopeConfiguration');
cfg_u = get_param([model '/Scope 전압'], 'ScopeConfiguration');
cfg_y.OpenAtSimulationStart = false;
cfg_u.OpenAtSimulationStart = false;

% Td 를 0 으로 두면 Transport Delay 가 "직접 피드스루" 로 바뀐다는 경고가 뜹니다.
% 플랜트 G 가 엄격 진유리(분모 차수가 더 큼)이므로 실제 대수 루프는 생기지 않습니다.
% 경고만 조용히 끕니다.
warning('off', 'Simulink:blocks:TDelayDirectThroughAutoSet');

%% 1. 이 모델은 어떤 블록으로 되어 있나
%
%  모델을 열기 전에 안에 무엇이 들어 있는지 먼저 읽고 들어갑니다.
%  이 모델에서 눈으로 찾아야 할 자리가 세 군데입니다.
%
%    지령 완만화 필터   맨 앞         여기서 지령의 **모양**이 정해진다
%    구동기 한계        제어기 뒤     여기서 u 가 잘린다
%    수송지연           구동기 앞     여기서 위상이 깎인다
%
%  같은 표가 .slx 안에도 주석으로 붙어 있습니다. 원본은 common/model_blocks.m 입니다.

model_blocks(model, 'print');

%% 2. 파라미터 설정 — 모델과 MATLAB 이 같은 루프를 보게 맞춘다
%
%  강의노트 8절의 종합 설계를 그대로 씁니다.
%
%    G = 0.01/(0.005s^3 + 0.06s^2 + 0.1001s)        DC 모터 위치
%    C = 200 * [(0.14416s + 1)/(0.01433s + 1)]^2    K + 앞선보상 두 단
%
%  지령은 **계단이 아니라 매끄러운 램프**입니다. Ramp 를 1/(tau*s+1) 에
%  통과시키면 정확히 이 모양이 나옵니다 (강의노트 8-6절).
%
%    r(t) = A*(t - tau*(1 - exp(-t/tau))),   A = 0.2,  tau = 0.3
%
%  계단을 주면 첫 순간에 u = K/alpha^2 = 20237 V 가 필요합니다. 모터는 12 V 입니다.

numG = 0.01;  denG = [0.005 0.06 0.1001 0];
numC = 200*conv([0.144164 1], [0.144164 1]);
denC = conv([0.014334 1], [0.014334 1]);

r_slope = 0.2;      % 지령 속도 [rad/s]  — 사양 1번
tau     = 0.3;      % 지령 완만화 시간상수 [s]
Td      = 0.02;     % 수송지연 [s]       — 사양에 주어진 값
u_lim   = 12;       % 모터 전압 한계 [V] — 사양 4번
u_sat   = 12;       % Saturation 블록이 실제로 쓰는 값
t_end   = 4;        % 모의시간 [s]

G = tf(numG, denG);
C = tf(numC, denC);

[nd, dd] = pade(Td, 3);         % 지연의 유리함수 근사 (8-5절)
G_real   = G*tf(nd, dd);

[g_i, p_i, ~, wc_i] = margin(C*G);          % 이상 플랜트
[g_r, p_r, ~, wc_r] = margin(C*G_real);     % 지연 포함

fprintf('=== 설계한 루프 확인 (MATLAB) ===\n');
disp(table({'이상 플랜트'; '지연 0.02 s 포함'}, [p_i; p_r], ...
    20*log10([g_i; g_r]), [wc_i; wc_r], ...
    'VariableNames', {'플랜트', 'PM_deg', 'GM_dB', 'wc'}))

% 읽는 법
%   - 지연이 PM 을 60.6 -> 50.7 도로 깎았다. 손계산 -wc*Td = -9.84 도와 같다
%   - 교차주파수는 안 변했다. 지연은 **크기를 안 건드린다**
%   - 사양 2번(PM >= 50)을 간신히 지킨다. 이것을 이제 시간영역에서 확인한다

%% 3. 대조 1 — 지연과 포화를 모두 끄면 앱의 결과로 돌아온다
%
%  왜 이것을 먼저 하는가 — Simulink 모델이 **앱에서 설계한 그 루프와
%  같은 루프인지** 부터 확인해야 합니다. 여기서 안 맞으면 뒤의 모든 비교가
%  의미가 없습니다. 지연을 0, 포화를 사실상 무한대로 두고 돌립니다.
%
%  MATLAB 쪽 비교 대상은 두 개입니다.
%
%    지령 -> 출력      feedback(C*G, 1)
%    지령 -> 제어입력  C/(1 + C*G)      <- 앱 화면에는 없는 그 전달함수
%
%  lsim 은 **균일한 시간 간격**만 받습니다. 그래서 모델의 기록 간격을
%  0.001 초로 고정해 두었습니다 (W11B_build_model.m 의 OutputTimes).

Td    = 0;       % <-- 0.02 로 바꿔 보기 (그러면 4절과 같아진다)
u_sat = 1e9;     % <-- 12 로 바꿔 보기 (그러면 포화가 켜진다)

o1 = sim(model);
t1 = o1.y_sim.Time;
r1 = o1.r_sim.Data;
y1 = o1.y_sim.Data;
u1 = o1.u_sim.Data;

y1_mat = lsim(feedback(C*G, 1),        r1, t1);
u1_mat = lsim(minreal(C/(1 + C*G)),    r1, t1);

fprintf('\n=== 대조 1 : Td = 0, 포화 끔 ===\n');
disp(table([max(abs(u1));      max(abs(u1_mat))], ...
           [r1(end) - y1(end); r1(end) - y1_mat(end)], ...
    'RowNames', {'Simulink', 'MATLAB_lsim'}, ...
    'VariableNames', {'umax_V', '램프오차_rad'}))
fprintf('  y 의 최대 차이 : %.3e rad\n', max(abs(y1 - y1_mat)));
fprintf('  u 의 최대 차이 : %.3e V\n',   max(abs(u1 - u1_mat)));

% 읽는 법
%   - y 가 소수 일곱째 자리까지 같다. **같은 루프를 보고 있다**
%   - u 의 차이가 y 보다 큰 것은 당연하다. C 는 미분에 가까운 동작을 하므로
%     솔버의 작은 오차가 u 에서 확대된다. 그래도 1e-3 V 수준이다
%   - 램프오차 0.01001 rad. 8-2절에서 K = 200 을 쓴 결과가 그대로 나왔다

figure('Name','대조 1 — 지연도 포화도 없을 때', 'Position',[80 80 950 420]);
tiledlayout(1, 2, 'TileSpacing','compact');

nexttile; hold on; grid on;
plot(t1, r1, 'k--', 'LineWidth', 1.8, 'DisplayName', '지령 r');
plot(t1, y1, 'LineWidth', 2.4, 'DisplayName', 'Simulink y');
plot(t1, y1_mat, ':', 'LineWidth', 2.4, 'DisplayName', 'MATLAB lsim');
xlabel('시간 [s]'); ylabel('위치 [rad]');
legend('Location','southeast');
title('두 선이 겹친다');

nexttile; hold on; grid on;
plot(t1, u1, 'LineWidth', 2.4, 'DisplayName', 'Simulink u');
plot(t1, u1_mat, ':', 'LineWidth', 2.4, 'DisplayName', 'MATLAB lsim');
yline(u_lim, 'r--', 'HandleVisibility','off');
xlabel('시간 [s]'); ylabel('제어입력 u [V]');
legend('Location','northeast');
title(sprintf('umax = %.3f V (한계 12 V)', max(abs(u1))));

%% 4. 대조 2 — 진짜 지연을 켠다. pade 예측이 맞았나
%
%  왜 이것이 중요한가 — 8-5절의 PM 50.7 도는 `pade` 로 **근사한** 숫자입니다.
%  진짜 지연은 무한 차수입니다. 근사가 쓸 만했는지 확인해야 합니다.
%
%  Simulink 의 Transport Delay 는 근사가 아니라 **지난 값을 저장해 두고
%  꺼내 주는** 블록입니다. 즉 진짜 e^(-s*Td) 입니다.
%
%  포화는 아직 끈 상태로 둡니다. 한 번에 한 가지만 바꾸는 것이 원칙입니다.

Td    = 0.02;    % <-- 0.04 로 바꿔 보기 (PM 이 더 깎여 응답이 출렁인다)
u_sat = 1e9;

o2 = sim(model);
t2 = o2.y_sim.Time;
r2 = o2.r_sim.Data;
y2 = o2.y_sim.Data;
u2 = o2.u_sim.Data;

y2_mat = lsim(feedback(C*G_real, 1),      r2, t2);
u2_mat = lsim(minreal(C/(1 + C*G_real)),  r2, t2);

fprintf('\n=== 대조 2 : Td = 0.02 (진짜 지연), 포화 끔 ===\n');
disp(table([max(abs(u2));      max(abs(u2_mat))], ...
           [r2(end) - y2(end); r2(end) - y2_mat(end)], ...
           [max(y2);           max(y2_mat)], ...
    'RowNames', {'Simulink_진짜지연', 'MATLAB_pade_3차'}, ...
    'VariableNames', {'umax_V', '램프오차_rad', 'y최대_rad'}))
fprintf('  y 의 최대 차이 : %.3e rad\n', max(abs(y2 - y2_mat)));
fprintf('  지연을 켜서 늘어난 umax : %.4f -> %.4f V\n', max(abs(u1)), max(abs(u2)));

% 읽는 법
%   - 진짜 지연과 pade 3차가 거의 그대로 겹친다. **이 지령에서는 근사가 충분하다**
%     지령이 완만해서 높은 주파수 성분이 적기 때문이다. 급한 지령이면 벌어진다
%   - 지연이 u 를 3.65 -> 4.20 V 로 키웠다. 늦게 알면 더 세게 밀어야 한다
%   - 램프오차는 안 변했다. 지연은 **정상상태 오차와 무관**하다
%     (크기가 1 이고 s = 0 에서 위상도 0 이므로 Kv 가 그대로다)

figure('Name','대조 2 — 진짜 지연 대 pade 근사', 'Position',[80 80 950 420]);
tiledlayout(1, 2, 'TileSpacing','compact');

nexttile; hold on; grid on;
plot(t2, r2, 'k--', 'LineWidth', 1.8, 'DisplayName', '지령 r');
plot(t2, y2, 'LineWidth', 2.4, 'DisplayName', 'Simulink (진짜 지연)');
plot(t2, y2_mat, ':', 'LineWidth', 2.4, 'DisplayName', 'MATLAB (pade 3차)');
plot(t1, y1, '-.', 'LineWidth', 1.4, 'DisplayName', '지연 없을 때');
xlim([0 1.5]);
xlabel('시간 [s]'); ylabel('위치 [rad]');
legend('Location','southeast');
title('지연이 있으면 출발이 출렁인다');

nexttile; hold on; grid on;
plot(t2, u2, 'LineWidth', 2.4, 'DisplayName', 'Simulink (진짜 지연)');
plot(t2, u2_mat, ':', 'LineWidth', 2.4, 'DisplayName', 'MATLAB (pade 3차)');
plot(t1, u1, '-.', 'LineWidth', 1.4, 'DisplayName', '지연 없을 때');
yline(u_lim, 'r--', 'HandleVisibility','off');
xlim([0 1.5]);
xlabel('시간 [s]'); ylabel('제어입력 u [V]');
legend('Location','northeast');
title(sprintf('지연이 umax 를 %.2f V 로 올렸다', max(abs(u2))));

%% 5. 대조 3 — 포화를 켠다. 설계가 실물에서 살아남는가
%
%  왜 이것이 마지막인가 — 여기까지는 전부 선형입니다. 포화는 **비선형**이므로
%  전달함수로 계산할 수 없습니다. 주파수영역 설계가 끝나는 자리가 여기입니다.
%
%  두 가지만 봅니다.
%
%    (1) u 가 12 V 선에 닿는가          닿지 않으면 포화는 아무 일도 안 한다
%    (2) 닿지 않았다면 응답이 그대로인가  그대로여야 설계가 유효하다

Td    = 0.02;
u_sat = 12;      % <-- 3 으로 바꿔 보기 (한계를 낮추면 포화가 걸린다)

o3 = sim(model);
t3 = o3.y_sim.Time;
r3 = o3.r_sim.Data;
y3 = o3.y_sim.Data;
u3 = o3.u_sim.Data;

n_hit = sum(abs(u3) >= u_sat - 1e-9);

fprintf('\n=== 대조 3 : Td = 0.02, 포화 %g V 켬 ===\n', u_sat);
disp(table([max(abs(u2));      max(abs(u3))], ...
           [r2(end) - y2(end); r3(end) - y3(end)], ...
           [0;                 n_hit], ...
    'RowNames', {'포화_끔', '포화_켬'}, ...
    'VariableNames', {'umax_V', '램프오차_rad', '한계에_닿은_표본수'}))
fprintf('  포화를 켜도 응답의 최대 차이 : %.3e rad\n', max(abs(y3 - y2)));

% 읽는 법
%   - umax 4.20 V 는 한계 12 V 의 35 퍼센트다. **포화에 한 번도 닿지 않았다**
%   - 그래서 포화를 켜도 응답이 똑같다. 차이가 0 이다
%   - 이것이 "설계가 통과했다" 의 진짜 뜻이다. 선형 계산이 그대로 성립한다

figure('Name','대조 3 — 포화를 켜도 같다', 'Position',[80 80 760 420]);
hold on; grid on;
plot(t3, u3, 'LineWidth', 2.6, 'DisplayName', '포화 켬');
plot(t2, u2, ':', 'LineWidth', 2.2, 'DisplayName', '포화 끔');
yline(u_lim, 'r--', 'LineWidth', 1.8, 'DisplayName', '한계 12 V');
yline(-u_lim, 'r--', 'HandleVisibility','off');
ylim([-14 14]);
xlabel('시간 [s]'); ylabel('제어입력 u [V]');
legend('Location','northeast');
title('여유가 이만큼 남았다');

%% 6. 지령의 출발을 급하게 하면 — 지령의 모양도 설계다
%
%  왜 이 절이 있는가 — 8-6절에서 지령을 **일부러 완만하게** 만들어 설계를
%  살렸습니다. 그 tau 가 얼마나 중요했는지 확인합니다.
%
%  tau 는 지령의 **출발이 얼마나 급한가**를 정합니다. 줄이면 출발이 날카로워지고
%  제어기가 더 센 전압을 요구합니다. 포화를 켜 두고 돌려 실물에서 무슨 일이
%  벌어지는지 봅니다.
%
%  [계단 지령은 또 다른 이야기입니다] tau 를 0 으로 보내면 **순수한 램프**가
%  됩니다. 계단이 되는 것이 아닙니다. 계단은 처음부터 값이 뛰는 지령이고,
%  그때 필요한 전압은 제어기의 고주파 이득 그 자체입니다.
%
%      u(0+) = K/alpha^2 = 20237 V      (8-6절, 아래에서 숫자로 확인)
%
%  그래서 이 설계로는 계단을 **아예 줄 수 없습니다.** 사양 1번이 램프였던 것이
%  운이 좋았던 것이 아니라, 램프여야 이 설계가 성립합니다.
%
%  [주의] tau 를 0.01 보다 더 줄이면 솔버의 MaxStep(0.001 초)이 지령의
%         출발을 못 따라갑니다. 숫자가 솔버 설정에 좌우되므로 그 아래는 믿지 마십시오.

tau_list = [0.3 0.2 0.1 0.05 0.02 0.01]';
m = numel(tau_list);
umax_sat = zeros(m,1); umax_lin = zeros(m,1);
hit = zeros(m,1); dy = zeros(m,1); ess = zeros(m,1);

Td = 0.02;
for k = 1:m
    tau = tau_list(k);          %#ok<NASGU>  <- 모델이 읽는다

    u_sat = 12;                 %#ok<NASGU>  포화 켬
    oa = sim(model);
    ua = oa.u_sim.Data; ya = oa.y_sim.Data; ra = oa.r_sim.Data;
    umax_sat(k) = max(abs(ua));
    hit(k)      = sum(abs(ua) >= 12 - 1e-9);
    ess(k)      = ra(end) - ya(end);

    u_sat = 1e9;                %#ok<NASGU>  포화 끔 — 진짜 필요한 전압
    ob = sim(model);
    umax_lin(k) = max(abs(ob.u_sim.Data));

    % 포화가 응답을 얼마나 틀어 놓았나 — 선형 계산과의 최대 차이
    dy(k) = max(abs(ya - ob.y_sim.Data));
end

fprintf('\n=== 지령을 급하게 줄 때 필요한 전압 ===\n');
disp(table(tau_list, umax_lin, umax_sat, hit, dy, ess, ...
    'VariableNames', {'tau_s', '필요한_umax_V', '실제_umax_V', ...
                      '한계에_닿은_표본수', '선형계산과_y차이', '램프오차_rad'}))

% 읽는 법
%   - tau 를 줄이면 **필요한 전압이 끝없이 커진다.** tau -> 0 이 계단이다
%   - tau = 0.05 부터 12 V 를 넘는다. 그때부터 포화가 일을 시작한다
%   - 포화가 걸리면 **선형 계산이 더 이상 맞지 않는다.** y 차이 열이 0 에서
%     벗어나는 순간이 그 경계다. 전달함수로 예측한 응답을 믿을 수 없게 된다
%   - 램프오차는 끝에서 다시 0.01001 로 돌아온다. 적분기가 있으니 **시간을 주면**
%     따라잡는다. 망가지는 것은 **출발 부분**이다. 끝 숫자만 보면 속는다
%   - 그래서 8-6절에서 **지령을 매끄럽게 만들어** 설계를 살렸다
%     제어기를 바꾸는 것만이 설계가 아니다. 지령의 모양도 설계다

figure('Name','지령을 급하게 주면', 'Position',[80 80 950 420]);
tiledlayout(1, 2, 'TileSpacing','compact');

nexttile; hold on; grid on;
plot(tau_list, umax_lin, '-o', 'LineWidth', 2.4, 'DisplayName', '필요한 전압');
plot(tau_list, umax_sat, '-s', 'LineWidth', 2.0, 'DisplayName', '실제로 걸린 전압');
yline(12, 'r--', 'LineWidth', 1.8, 'DisplayName', '한계 12 V');
set(gca, 'XScale','log', 'YScale','log', 'XDir','reverse');
xlabel('tau [s]  (왼쪽으로 갈수록 급한 지령)'); ylabel('umax [V]');
legend('Location','northwest');
title('tau 를 줄이면 전압이 끝없이 필요하다');

nexttile; hold on; grid on;
tau = 0.01; u_sat = 12;  oc = sim(model);
tau = 0.01; u_sat = 1e9; od = sim(model);
plot(oc.r_sim.Time, oc.r_sim.Data, 'k--', 'LineWidth', 1.8, 'DisplayName', '지령 r');
plot(od.y_sim.Time, od.y_sim.Data, ':', 'LineWidth', 2.4, ...
     'DisplayName', '포화 끔 (선형 계산이 맞는 경우)');
plot(oc.y_sim.Time, oc.y_sim.Data, 'LineWidth', 2.4, ...
     'DisplayName', '포화 켬 (실물)');
xlim([0 1]);
xlabel('시간 [s]'); ylabel('위치 [rad]');
legend('Location','southeast');
title('tau = 0.01 — 포화가 출발을 틀어 놓는다');

%% 7. 모델을 원래대로 돌려 놓는다
%
%  바꿔 둔 설정을 되돌립니다. 다음 사람이 모델을 열었을 때 처음 상태여야 합니다.

tau   = 0.3;     %#ok<NASGU>
Td    = 0.02;    %#ok<NASGU>
u_sat = 12;      %#ok<NASGU>
cfg_y.OpenAtSimulationStart = true;
cfg_u.OpenAtSimulationStart = true;
warning('on', 'Simulink:blocks:TDelayDirectThroughAutoSet');

%% 8. 오늘 확인한 것
%
%  - 지연과 포화를 끄면 Simulink 가 앱의 루프와 소수 일곱째 자리까지 같았다
%  - 진짜 지연과 pade 3차 근사가 이 지령에서는 거의 같았다.
%    즉 8-5절의 PM 50.7 도를 믿어도 된다
%  - 지연이 umax 를 3.65 -> 4.20 V 로 키웠다. 늦게 알면 더 세게 밀어야 한다
%  - 포화는 한 번도 닿지 않았다. 그래서 선형 설계가 그대로 성립했다
%  - tau 를 줄이면 필요한 전압이 끝없이 커졌다. **계단 지령은 불가능하다**
%
%  질문
%
%  - Td 를 0.04 로 올리면 PM 이 얼마가 될까. 손으로 먼저 계산하고 돌려 보십시오
%  - u_sat 를 3 V 로 낮추면 응답이 어떻게 망가지는가. 그때 설계를 어떻게 고쳐야 하나
%  - 지령 완만화 필터를 2차 1/(tau*s+1)^2 로 바꾸면 umax 가 더 줄어들까

fprintf('\n=== W11B_06 OK ===\n');
fprintf('모델 설정을 원래대로 돌려 놓았습니다.\n');
