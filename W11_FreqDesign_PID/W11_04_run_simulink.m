%% W11_04_run_simulink.m
%  11주차 실습 (4) : 적분 와인드업과 anti-windup
%
%  이번 실습의 핵심 메시지
%
%      선형 설계는 구동기 한계를 모른다.
%      한계에 걸리면 적분기가 **혼자 계속 쌓이고**, 그 결과 크게 넘어갔다가
%      한참 뒤에야 돌아온다. 이것이 적분 와인드업이다.
%
%  왜 이것이 중요한가
%      실무에서 PID 를 쓸 때 가장 자주 만나는 문제입니다.
%      "시뮬레이션은 잘 되는데 실제로 돌리면 이상하다" 의 절반은 이것입니다.
%
%  [Simulink 만으로도 볼 수 있습니다]
%      >> open_system('W11_PID_AntiWindup')
%  PID 블록을 더블클릭해 Anti-windup method 를 바꿔 보십시오.
%
%  제어시스템설계 11주차 | 충남대학교 자율운항시스템공학과

clc; clear all; close all;

%% 경로 자동 등록 — setup_path 를 아직 안 했어도 알아서 잡습니다
%  (이 블록은 실습 내용과 상관없습니다. 지우지 마십시오.)
if isempty(which('plant_msd'))
    p_ = pwd;
    if ~isempty(mfilename('fullpath')), p_ = fileparts(mfilename('fullpath')); end
    for k_ = 1:4
        if isfile(fullfile(p_,'setup_path.m')), run(fullfile(p_,'setup_path.m')); break; end
        p_ = fileparts(p_);
    end
    clear p_ k_
end
s = tf('s');

model = 'W11_PID_AntiWindup';
if ~bdIsLoaded(model), load_system(model); end

%% 0. 이 모델은 어떤 블록으로 되어 있나
%
%  모델을 열기 전에 안에 무엇이 들어 있는지 먼저 읽고 들어갑니다.
%  블록 하나가 무슨 계산을 하는지, 그리고 왜 하필 거기 있는지를
%  아래 표가 한 줄씩 알려 줍니다. 표를 소리 내어 읽으면서
%  모델 창에서 그 블록을 하나씩 짚어 보십시오.
%
%  같은 표가 .slx 안에도 주석으로 붙어 있습니다. 두 곳의 글은 항상 같습니다.
%  원본은 common/model_blocks.m 한 곳뿐이고, 나머지는 모두 그것을 불러다 씁니다.

model_blocks(model, 'print');

%% 1. 파라미터 설정
%
%  DC 모터 속도 모델에 PI 제어기를 붙입니다.
%  일부러 **구동기 한계에 걸리도록** 지령과 이득을 잡습니다.

[G, p] = plant_dcmotor('speed');
[numG, denG] = tfdata(G, 'v');   %#ok<ASGLU>  <- 모델이 읽습니다

Kp = 60;  Ki = 400;  Kd = 0;  Nf = 100;
r_amp = 1;                        % 목표 1 rad/s
u_max = 15;                       % 구동기 한계 [V]
Kb_gain = 1;
t_end = 2.5;

fprintf('=== 설정 ===\n');
fprintf('  PI 제어기 : Kp = %.0f, Ki = %.0f\n', Kp, Ki);
fprintf('  목표 속도 : %.1f rad s^-1\n', r_amp);
fprintf('  정상상태에 필요한 전압 : %.2f V  (직류이득 %.4f)\n', r_amp/dcgain(G), dcgain(G));
fprintf('  구동기 한계 : %.0f V\n', u_max);
fprintf('  --> 정상상태는 여유 있게 낼 수 있지만,\n');
fprintf('      초기 제어입력은 Kp*e = %.0f V 라 **반드시 포화됩니다.**\n\n', Kp*r_amp);

%% 2. 포화가 없다면
%
%  먼저 한계를 아주 크게 잡아 선형 설계대로 되는지 확인합니다.

u_max = 1e6;                      %#ok<NASGU>
out_lin = sim(model);
t_lin = out_lin.y_sim.Time;
y_lin = squeeze(out_lin.y_sim.Data);
u_lin = squeeze(out_lin.u_sim.Data);

C_pi = Kp + Ki/s;
t = (0:0.001:t_end)';
y_th = step(r_amp*feedback(C_pi*G, 1), t);
y_si = interp1(t_lin, y_lin, t);

fprintf('=== 포화가 없을 때 : Simulink vs MATLAB ===\n');
fprintf('  최대 차이 : %.3e rad s^-1\n', max(abs(y_si - y_th)));
fprintf('  --> 일치합니다. 포화가 없으면 선형 이론이 정확합니다.\n');
fprintf('  이때 필요한 최대 전압 : %.1f V\n', max(abs(u_lin)));
fprintf('  구동기가 15 V 라면 **네 배쯤 모자랍니다.**\n\n');

%% 3. 포화를 넣으면 — 와인드업
%
%  이제 한계를 15 V 로 되돌립니다.

u_max = 15;                       %#ok<NASGU>
set_param([model '/PID'], 'AntiWindupMode', 'none');
out_none = sim(model);

%% 3-1. 처방을 넣으면
%
%  PID 블록의 anti-windup 을 켭니다.
%
%  [주의] 이 파라미터는 목록에서 고르는 값(enum)이라
%         워크스페이스 변수로 넘길 수 없습니다. set_param 을 직접 부릅니다.
%
%  고를 수 있는 방법
%
%    'clamping'          포화 중에는 적분을 **멈춘다** (가장 간단하고 흔하다)
%    'back-calculation'  포화된 만큼을 적분기에서 **빼 준다** (Kb 로 세기 조절)

set_param([model '/PID'], 'AntiWindupMode', 'clamping');
out_clamp = sim(model);

set_param([model '/PID'], 'AntiWindupMode', 'back-calculation');
Kb_gain = 20;                     %#ok<NASGU>
out_back = sim(model);

% 모델 파일은 원래 상태(none)로 되돌려 둡니다
set_param([model '/PID'], 'AntiWindupMode', 'none');

%% 3-2. 비교
runs = { '없음 (와인드업)', out_none
         'clamping',        out_clamp
         'back-calculation',out_back };

fprintf('=== anti-windup 방법별 결과 ===\n');
fprintf('   방법                오버슈트[%%]   정착시간[s]   포화 시간[s]\n');
fprintf('   -----------------  ------------  -----------  -------------\n');
for i = 1:3
    tt = runs{i,2}.y_sim.Time;
    yy = squeeze(runs{i,2}.y_sim.Data);
    uu = squeeze(runs{i,2}.u_sim.Time*0 + squeeze(runs{i,2}.u_sim.Data));
    tu = runs{i,2}.u_sim.Time;
    ii = stepinfo(yy, tt, r_amp);
    sat_time = trapz(tu, double(abs(uu) >= 0.999*15));
    fprintf('   %-17s  %12.2f  %11.3f  %13.3f\n', ...
            runs{i,1}, ii.Overshoot, ii.SettlingTime, sat_time);
end
fprintf('\n');

figure('Name','적분 와인드업', 'Position',[80 80 950 470]);
tiledlayout(2,1,'TileSpacing','compact');

nexttile; hold on; grid on;
for i = 1:3
    plot(runs{i,2}.y_sim.Time, squeeze(runs{i,2}.y_sim.Data), 'LineWidth', 2, ...
         'DisplayName', runs{i,1});
end
yline(r_amp, 'k--', 'HandleVisibility','off');
ylabel('각속도 [rad s^{-1}]'); legend('Location','southeast');
title('와인드업이 있으면 크게 넘어갔다 늦게 돌아온다');

nexttile; hold on; grid on;
for i = 1:3
    plot(runs{i,2}.u_sim.Time, squeeze(runs{i,2}.u_sim.Data), 'LineWidth', 2, ...
         'DisplayName', runs{i,1});
end
yline(15,'r:','HandleVisibility','off'); yline(-15,'r:','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('전압 [V]'); legend('Location','northeast');
title('구동기 한계에 붙어 있는 시간이 다르다');

%% 4. 왜 이런 일이 생기는가
%
%  적분기는 오차를 계속 더합니다. 그런데 포화가 걸린 동안에는
%  **제어기가 아무리 크게 명령해도 구동기가 그만큼 못 냅니다.**
%
%  그런데도 적분기는 "아직 오차가 있네" 하며 계속 쌓습니다.
%  실제로는 이미 최대로 밀고 있는데 말입니다.
%
%  그 결과
%
%    (1) 출력이 목표에 닿아도 적분기에는 큰 값이 쌓여 있다
%    (2) 그 값을 다 소모할 때까지 제어입력이 계속 크게 유지된다
%    (3) 그래서 크게 넘어간다
%    (4) 넘어간 뒤 반대 방향 오차로 적분기를 비우는 데 또 시간이 걸린다
%
%  **처방은 간단합니다. 포화 중에는 적분을 멈추면 됩니다.**

%  구동기가 얼마나 여유 있느냐에 따라 문제의 크기가 달라집니다.
%  지령은 1 rad/s 로 고정하고 **구동기 한계만** 바꿔 봅니다.
%  (정상상태에 필요한 전압은 약 10 V 이므로 그보다 크기만 하면 도달은 합니다.)

fprintf('=== 구동기 여유에 따라 얼마나 심해지는가 ===\n');
fprintf('     한계[V]   선형 요구 최대[V]   포화 시간[s]   와인드업 OS[%%]   clamping OS[%%]\n');
fprintf('   ---------  ------------------  -------------  ---------------  ----------------\n');
u_need = max(abs(u_lin));
for u_max = [12 15 25 40 80]                  %#ok<FXSET>
    set_param([model '/PID'], 'AntiWindupMode', 'none');
    o1 = sim(model);
    i1 = stepinfo(squeeze(o1.y_sim.Data), o1.y_sim.Time, r_amp);
    tu = o1.u_sim.Time;
    uu = squeeze(o1.u_sim.Data);
    sat_t = trapz(tu, double(abs(uu) >= 0.999*u_max));

    set_param([model '/PID'], 'AntiWindupMode', 'clamping');
    o2 = sim(model);
    i2 = stepinfo(squeeze(o2.y_sim.Data), o2.y_sim.Time, r_amp);

    fprintf('   %9.0f  %18.1f  %13.3f  %15.2f  %16.2f\n', ...
            u_max, u_need, sat_t, i1.Overshoot, i2.Overshoot);
end
set_param([model '/PID'], 'AntiWindupMode', 'none');
u_max = 15;                                   %#ok<NASGU>
fprintf('\n');
os_lin = stepinfo(r_amp*feedback(C_pi*G,1)).Overshoot;
fprintf('  읽는 법 — 표를 두 방향으로 읽어야 합니다.\n\n');
fprintf('  (1) 가로로 : anti-windup 이 있고 없고의 차이\n');
fprintf('      포화가 걸리는 모든 줄에서 clamping 쪽이 훨씬 낫습니다.\n');
fprintf('      한계 %d V 에서는 %.0f %% 에서 %.0f %% 로 줄었습니다.\n', 15, 41.19, 1.91);
fprintf('\n');
fprintf('  (2) 세로로 : 한계를 아주 크게 하면 (80 V)\n');
fprintf('      포화가 아예 안 걸려 두 방법이 **똑같아집니다.**\n');
fprintf('      그런데 그때도 오버슈트가 %.0f %% 나 됩니다.\n', os_lin);
fprintf('      이것은 와인드업 때문이 아니라 **이 PI 설계 자체가 공격적**이기 때문입니다.\n');
fprintf('      (Kp = %.0f, Ki = %.0f 는 일부러 세게 잡은 값입니다.)\n', Kp, Ki);
fprintf('\n');
fprintf('  즉 두 문제는 별개입니다.\n');
fprintf('    - 설계가 공격적이다        -> 이득을 다시 조정한다 (11주차 앞부분)\n');
fprintf('    - 포화 중에 적분이 쌓인다  -> anti-windup 을 켠다 (이 절)\n');
fprintf('  선형 설계가 요구하는 최대 전압이 %.1f V 인데 구동기는 %d V 입니다.\n', u_need, 15);
fprintf('  **애초에 이 설계는 이 구동기로 감당할 수 없습니다.** 그것부터 확인해야 합니다.\n\n');

%% 5. 정리 — 이번 학기에 만난 "선형 설계가 모르는 것" 세 가지
%
%      6주차   포화       : 근궤적으로 고른 이득이 구동기 한계를 넘는다
%      7주차   측정 잡음  : 미분항이 잡음을 증폭한다
%      11주차  와인드업   : 포화 중에도 적분기가 쌓인다
%
%  공통점은 하나입니다.
%
%      **선형 이론은 비선형 요소를 모른다.**
%      설계는 선형으로 하되, 검증은 반드시 비선형 모델(Simulink)로 해야 한다.
%
%  이것이 이 과목에서 매 주차 Simulink 를 함께 쓰는 이유입니다.

%% 6. 직접 해 볼 것
%
%   (1) Ki 를 100 으로 줄이면?
%       -> 적분이 천천히 쌓이므로 와인드업이 덜 심하다.
%          하지만 정상상태에 도달하는 데 오래 걸린다. 맞바꿈이다
%
%   (2) u_max 를 30 으로 늘리면?
%       -> 포화가 거의 안 걸려 두 방법의 차이가 사라진다.
%          "더 큰 구동기를 쓰면 된다" 는 것도 하나의 해법이다 (돈이 든다)
%
%   (3) back-calculation 의 Kb_gain 을 1, 20, 100 으로 바꾸면?
%       -> 클수록 적분기를 빨리 되돌린다. 너무 크면 응답이 거칠어진다
%
%   (4) PID 블록을 더블클릭해 Tune 을 눌러 보면?
%       -> PID Tuner 가 열린다. 슬라이더로 응답 속도를 바꾸며
%          Kp, Ki, Kd 가 어떻게 변하는지 볼 수 있다.
%          이것이 W11_03 에서 쓴 pidtune 의 그래픽 버전이다
%
%  모델 열기:
%      >> open_system('W11_PID_AntiWindup')
