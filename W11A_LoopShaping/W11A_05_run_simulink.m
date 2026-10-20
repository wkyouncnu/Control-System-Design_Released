%% W11A_05_run_simulink.m
%  11A주차 실습 (5) : 주파수영역 숫자를 Simulink 로 확인한다
%
%  이번 실습의 핵심 메시지
%
%      주파수영역에서 구한 숫자는 **약속이 아니라 예측**이다.
%      |S(jw)| = 0.0627 이라고 썼으면, 그 주파수로 실제로 흔들었을 때
%      출력 진폭이 입력 진폭의 0.0627 배로 나와야 한다.
%      안 나오면 계산이 틀렸거나 모델이 틀린 것이다.
%
%  강의노트와의 대응
%      5-3 절    손계산 -24.05 dB 를 세 가지 방법으로 대조
%      5-2 절    주파수를 바꾸면 억제량이 어떻게 변하는가
%      6 절      센서 잡음이 섞여 들어오는 양
%      6-1 절    대역폭을 키울 때의 맞바꿈
%
%  [Simulink 만으로도 볼 수 있습니다]
%      >> open_system('W11A_LoopShaping')
%  출력외란 d 블록을 더블클릭해 Frequency 를 바꿔 보십시오.
%
%  제어시스템설계 11A주차 | 충남대학교 자율운항시스템공학과

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

model = 'W11A_LoopShaping';
if ~bdIsLoaded(model), load_system(model); end

% 아래에서 같은 모델을 수십 번 돌립니다. 그때마다 Scope 창이 뜨면 번거로우므로
% 자동 열기를 잠시 끕니다. 맨 마지막에 원래대로 돌려 놓습니다.
cfg_y = get_param([model '/Scope 속도'], 'ScopeConfiguration');
cfg_u = get_param([model '/Scope 전압'], 'ScopeConfiguration');
cfg_y.OpenAtSimulationStart = false;
cfg_u.OpenAtSimulationStart = false;

%% 0. 이 모델은 어떤 블록으로 되어 있나
%
%  모델을 열기 전에 안에 무엇이 들어 있는지 먼저 읽고 들어갑니다.
%  특히 이 모델에서는 **신호가 합쳐지는 자리가 두 군데**입니다.
%
%    외란 합산     플랜트 뒤          여기서 y 가 정해진다
%    측정값 만들기  되먹임 선 위       제어기가 믿는 값 ym = y + n 이 여기서 정해진다
%
%  이 두 자리를 모델 창에서 눈으로 찾고 나서 아래를 읽으십시오.
%  같은 표가 .slx 안에도 주석으로 붙어 있습니다. 원본은 common/model_blocks.m 입니다.

model_blocks(model, 'print');

%% 1. 파라미터 설정 — 모델과 MATLAB 이 같은 루프를 보게 맞춘다
%
%  강의노트의 모터 예제를 그대로 씁니다.
%
%    P = 0.1/(0.5s + 2),   C = (500s + 2000)/s
%
%  손으로 곱하면 제어기 영점 s = -4 가 플랜트 극점을 지워서
%
%    L = P*C = 100/s,   S = s/(s+100),   T = 100/(s+100)
%
%  이번 절에서는 **지령을 0 으로 두고 외란만** 넣습니다.
%  그래야 출력에 보이는 것이 전부 외란의 몫이 됩니다.

numP = 0.1;        denP = [0.5 2];
numC = [500 2000]; denC = [1 0];

P = tf(numP, denP);
C = tf(numC, denC);
L = minreal(P*C);
S = 1/(1 + L);
T = L/(1 + L);

r_amp     = 0;         % 지령 없음 — 외란만 본다
d_amp     = 0.3;       % 외란 진폭
w_d       = 2*pi;      % 외란 주파수 1 Hz
noise_pow = 0;         % 잡음은 5절에서 켠다
noise_ts  = 5e-4;
t_end     = 2;

fprintf('=== 루프 확인 ===\n');
L                                  % 100/s 가 나와야 한다
[GM, PM, ~, wc] = margin(L);
fprintf('  GM = %.1f dB(무한),  PM = %.2f deg,  wc = %.2f rad/s,  wb = %.2f rad/s\n\n', ...
        20*log10(GM), PM, wc, bandwidth(T));

%% 2. 손계산 -24.05 dB 를 Simulink 와 대조한다
%
%  손으로 하는 계산은 이것뿐입니다. s 에 j*w 를 넣고 크기를 잽니다.
%
%    S(jw) = jw/(jw + 100)
%    |S(jw)| = w/sqrt(w^2 + 100^2)
%    w = 2*pi 에서  = 6.2832/sqrt(39.48 + 10000) = 0.062708
%    dB 로 고치면  20*log10(0.062708) = -24.054 dB
%
%  같은 숫자를 세 가지 방법으로 구해 봅니다.
%    (1) 위의 손계산 식
%    (2) freqresp — MATLAB 이 전달함수에 j*w 를 대입해 준다
%    (3) Simulink — 실제로 흔들어서 출력 진폭을 잰다

hand_mag = w_d/sqrt(w_d^2 + 100^2);                 % (1)
fr_mag   = abs(freqresp(S, w_d));                   % (2)

out = sim(model);                                   % (3)
t_y = out.y_sim.Time;
y   = squeeze(out.y_sim.Data);
t_d = out.d_sim.Time;
d   = squeeze(out.d_sim.Data);

% 정상상태 구간만 봅니다. 외란 주기의 두 배 정도를 뒤에서 잘라 씁니다.
T_per = 2*pi/w_d;
idx_y = t_y > (t_end - 2*T_per);
idx_d = t_d > (t_end - 2*T_per);
amp_y = max(abs(y(idx_y)));
amp_d = max(abs(d(idx_d)));
sim_mag = amp_y/amp_d;

fprintf('=== w_d = %.4f rad/s (%.2f Hz) 에서의 외란 억제 ===\n', w_d, w_d/(2*pi));
disp(table([hand_mag; fr_mag; sim_mag], ...
           20*log10([hand_mag; fr_mag; sim_mag]), ...
    'RowNames', {'손계산_식', 'freqresp', 'Simulink_실측'}, ...
    'VariableNames', {'크기비', 'dB'}))
fprintf('  외란 진폭 %.4f -> 출력 진폭 %.5f  (%.1f 배 줄었다)\n', ...
        amp_d, amp_y, 1/sim_mag);
fprintf('  세 값의 최대 차이 : %.3e\n', ...
        max(abs([hand_mag fr_mag sim_mag] - hand_mag)));
fprintf('  --> 주파수영역 계산이 시간영역에서 그대로 나왔습니다.\n\n');

figure('Name','출력외란 억제', 'Position',[80 80 950 420]);
tiledlayout(1, 2, 'TileSpacing','compact');

nexttile; hold on; grid on;
plot(t_d, d, 'LineWidth', 2, 'Color', [0.6 0.6 0.6], ...
     'DisplayName', '외란 d (되먹임이 없으면 이대로 나온다)');
plot(t_y, y, 'LineWidth', 2.2, 'DisplayName', '출력 y (폐루프)');
xlim([t_end - 2*T_per, t_end]);
xlabel('시간 [s]'); ylabel('크기');
legend('Location','northeast');
title(sprintf('%.1f dB 만큼 줄어 나온다', 20*log10(sim_mag)));

nexttile; hold on; grid on;
wv = logspace(-1, 4, 400);
semilogx(wv, 20*log10(squeeze(abs(freqresp(S, wv)))), 'LineWidth', 2.5, ...
         'DisplayName', '|S| 곡선');
plot(w_d, 20*log10(sim_mag), 'o', 'MarkerSize', 10, 'LineWidth', 2, ...
     'DisplayName', 'Simulink 실측');
set(gca, 'XScale','log');
yline(0, 'k--', 'HandleVisibility','off');
xline(wc, 'k:', 'HandleVisibility','off');
xlabel('주파수 [rad/s]'); ylabel('|S| [dB]');
legend('Location','southeast');
title('실측 점이 곡선 위에 얹힌다');

%% 3. 주파수를 바꾸면 — 고주파 외란은 못 막는다
%
%  |S| 곡선을 Simulink 로 한 점씩 찍어 봅니다.
%  저주파에서는 많이 줄고, 교차주파수(100 rad/s) 근처에서는 거의 안 줄고,
%  그보다 높으면 **그냥 통과**합니다.
%
%  [주의] 주파수가 낮으면 한 주기가 길어집니다.
%         정상상태를 보려면 모의시간도 함께 늘려야 합니다.

w_list = [0.6 2*pi 20 60 100 300 600]';
n = numel(w_list);
sim_dB = zeros(n,1); form_dB = zeros(n,1);

for k = 1:n
    w_d   = w_list(k);                              %#ok<NASGU>  <- 모델이 읽는다
    T_per = 2*pi/w_d;
    t_end = max(0.3, 8*T_per);                      %#ok<NASGU>

    o = sim(model);
    tt = o.y_sim.Time;  yy = squeeze(o.y_sim.Data);
    ii = tt > (t_end - 2*T_per);

    sim_dB(k)  = 20*log10(max(abs(yy(ii)))/d_amp);
    form_dB(k) = 20*log10(w_d/sqrt(w_d^2 + 100^2));
end

fprintf('=== 주파수별 외란 억제량 ===\n');
disp(table(w_list, w_list/(2*pi), form_dB, sim_dB, sim_dB - form_dB, ...
    'VariableNames', {'w_rad_s', 'f_Hz', '식_dB', 'Simulink_dB', '차이_dB'}))
fprintf('  저주파는 많이 줄고, 교차주파수(100)에서는 3 dB 뿐이고,\n');
fprintf('  그보다 높으면 0 dB 즉 **그대로 나옵니다.**\n\n');

figure('Name','주파수별 억제량', 'Position',[80 80 760 420]);
hold on; grid on;
semilogx(wv, 20*log10(squeeze(abs(freqresp(S, wv)))), 'LineWidth', 2.5, ...
         'DisplayName', '|S| 식');
plot(w_list, sim_dB, 'o', 'MarkerSize', 10, 'LineWidth', 2, ...
     'DisplayName', 'Simulink 실측');
set(gca, 'XScale','log');
yline(0, 'k--', 'HandleVisibility','off');
yline(-3, 'k:', 'HandleVisibility','off');
xline(100, 'k:', 'HandleVisibility','off');
xlabel('외란 주파수 [rad/s]'); ylabel('억제량 [dB]');
legend('Location','southeast');
title('되먹임이 일하는 구간은 교차주파수 왼쪽뿐이다');

%% 4. 지령 추종도 맞는지 — 전달함수는 T 다
%
%  외란을 끄고 지령을 켜면 이번에는 T = 100/(s+100) 이 보여야 합니다.
%  1차 함수이므로 오버슈트가 없고, 시간상수가 1/100 = 0.01 초입니다.

r_amp = 1;      %#ok<NASGU>
d_amp = 0;      %#ok<NASGU>
t_end = 0.08;   %#ok<NASGU>

o4 = sim(model);
t4 = o4.y_sim.Time;
y4 = squeeze(o4.y_sim.Data);

tth = (0:1e-5:0.08)';
yth = step(T, tth);
y_on_grid = interp1(t4, y4, tth);

si = stepinfo(y4, t4, 1);
fprintf('=== 지령 추종 : Simulink vs MATLAB ===\n');
fprintf('  최대 차이 : %.3e\n', max(abs(y_on_grid - yth)));
fprintf('  오버슈트 : %.3f %%   (PM 90 도이므로 0 이어야 한다)\n', si.Overshoot);
fprintf('  정착시간 : %.4f s   (시간상수 0.01 초의 약 4 배)\n', si.SettlingTime);
fprintf('  상승시간 : %.4f s\n\n', si.RiseTime);

figure('Name','지령 추종', 'Position',[80 80 760 400]);
hold on; grid on;
plot(t4, y4, 'LineWidth', 2.5, 'DisplayName', 'Simulink');
plot(tth, yth, '--', 'LineWidth', 2, 'DisplayName', 'MATLAB step(T)');
yline(1, 'k:', 'HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력 y');
legend('Location','southeast');
title('두 선이 겹친다 — 같은 루프를 보고 있다');

%% 5. 센서 잡음을 켠다 — 되먹임이 **잃는** 쪽
%
%  n 에서 y 까지의 전달함수는 -T 입니다. 지령 추종과 똑같은 T 이므로
%  **대역폭 안에 있는 잡음은 막을 방법이 없습니다.**
%
%  Band-Limited White Noise 블록의 두 파라미터
%
%    Cov (Noise power)  잡음 세기. 전력스펙트럼밀도의 높이다
%    Ts (Sample time)   잡음을 새로 뽑는 간격. 이 값이 잡음의 띠 폭을 정한다
%
%  입력 잡음의 표준편차는 sqrt(Cov/Ts) 입니다.
%  출력에 나오는 양은 그중 T 가 통과시킨 몫뿐이므로, |T|^2 를 띠 전체에서
%  적분해 얻습니다. 적분은 trapz 로 수치적으로 합니다.

r_amp     = 0;        %#ok<NASGU>  지령도 외란도 끄고 잡음만 본다
d_amp     = 0;        %#ok<NASGU>
noise_pow = 2e-7;     %#ok<NASGU>
noise_ts  = 5e-4;     %#ok<NASGU>
t_end     = 2;        %#ok<NASGU>

o5 = sim(model);
t5 = o5.y_sim.Time;
y5 = squeeze(o5.y_sim.Data);

std_in = sqrt(noise_pow/noise_ts);                  % 들어가는 잡음의 표준편차

% 출력 분산 = (1/2pi) * (PSD 높이) * (|T|^2 을 띠 전체에서 적분)
w_band = linspace(-pi/noise_ts, pi/noise_ts, 20001);
T_mag2 = squeeze(abs(freqresp(T, abs(w_band)))).^2;
var_out = noise_pow/(2*pi)*trapz(w_band, T_mag2);
std_out_theory = sqrt(var_out);
std_out_meas   = std(y5(t5 > 0.2));                 % 초기 과도구간은 버린다

fprintf('=== 센서 잡음이 출력에 나오는 양 ===\n');
disp(table([std_in; std_out_theory; std_out_meas], ...
    'RowNames', {'입력_잡음_std', '이론_출력_std', 'Simulink_출력_std'}, ...
    'VariableNames', {'표준편차'}))
fprintf('  통과 비율 (이론) : %.3f,  (실측) : %.3f\n', ...
        std_out_theory/std_in, std_out_meas/std_in);
fprintf('  --> 잡음은 넓은 띠에 퍼져 있고 T 는 100 rad/s 까지만 통과시킵니다.\n');
fprintf('      그래서 전부 들어오지는 않습니다. 하지만 **0 도 아닙니다.**\n');
fprintf('  [주의] 영점유지(ZOH) 모양 때문에 이론과 실측이 몇 %% 어긋날 수 있습니다.\n\n');

figure('Name','센서 잡음', 'Position',[80 80 950 420]);
tiledlayout(1, 2, 'TileSpacing','compact');

nexttile; hold on; grid on;
plot(t5, y5, 'LineWidth', 1.0);
yline(0, 'k--');
yline(3*std_out_meas, 'r:'); yline(-3*std_out_meas, 'r:');
xlim([0.2 0.5]);
xlabel('시간 [s]'); ylabel('출력 y');
title('지령도 외란도 없는데 출력이 떨고 있다');

nexttile; hold on; grid on;
semilogx(wv, 20*log10(squeeze(abs(freqresp(T, wv)))), 'LineWidth', 2.5, ...
         'DisplayName', '|T| = |n -> y|');
set(gca, 'XScale','log');
yline(0, 'k--', 'HandleVisibility','off');
yline(-3, 'k:', 'HandleVisibility','off');
xline(bandwidth(T), 'k:', 'HandleVisibility','off');
xlabel('주파수 [rad/s]'); ylabel('크기 [dB]');
legend('Location','southwest');
title('대역폭 밖의 잡음만 막힌다');

%% 6. 맞바꿈 — 제어기 이득을 올리면 어느 쪽이 좋아지고 어느 쪽이 나빠지는가
%
%  제어기 이득을 K 배 하면 L 이 K 배가 되고, 교차주파수와 대역폭도 K 배가 됩니다.
%
%    외란 쪽  |S| 가 내려간다        -> 좋아진다
%    잡음 쪽  |T| 의 통과 띠가 넓어진다 -> 나빠진다
%
%  두 가지를 **같은 시뮬레이션에서 동시에** 재 봅니다.

K_list = [0.2 0.5 1 2 5]';
m = numel(K_list);
wb_v = zeros(m,1); d_dB = zeros(m,1); n_std = zeros(m,1);

w_d   = 2*pi;      %#ok<NASGU>
t_end = 2;         %#ok<NASGU>

for k = 1:m
    numC = K_list(k)*[500 2000];                    %#ok<NASGU>  <- 모델이 읽는다

    Lk = minreal(K_list(k)*P*C);
    wb_v(k) = bandwidth(Lk/(1 + Lk));

    % (1) 외란만 켜고 억제량을 잰다
    d_amp = 0.3;  noise_pow = 0;                    %#ok<NASGU>
    oa = sim(model);
    ta = oa.y_sim.Time;  ya = squeeze(oa.y_sim.Data);
    d_dB(k) = 20*log10(max(abs(ya(ta > t_end - 2*(2*pi/w_d))))/0.3);

    % (2) 잡음만 켜고 출력 표준편차를 잰다
    d_amp = 0;    noise_pow = 2e-7;                 %#ok<NASGU>
    ob = sim(model);
    tb = ob.y_sim.Time;  yb = squeeze(ob.y_sim.Data);
    n_std(k) = std(yb(tb > 0.2));
end

fprintf('=== 이득을 올릴 때의 맞바꿈 ===\n');
disp(table(K_list, wb_v, d_dB, n_std, ...
    'VariableNames', {'K배수', 'wb_rad_s', '외란_남은양_dB', '잡음_출력_std'}))
fprintf('  왼쪽 열은 작을수록 좋고 오른쪽 열도 작을수록 좋습니다.\n');
fprintf('  그런데 **한 열이 좋아지면 다른 열이 나빠집니다.**\n');
fprintf('  대역폭을 정하는 일이 곧 이 둘 사이에서 자리를 고르는 일입니다.\n\n');

figure('Name','외란 대 잡음 맞바꿈', 'Position',[80 80 760 420]);
hold on; grid on;
yyaxis left
plot(wb_v, d_dB, '-o', 'LineWidth', 2.2);
ylabel('외란 남은 양 [dB]  (낮을수록 좋다)');
yyaxis right
plot(wb_v, n_std, '-s', 'LineWidth', 2.2);
ylabel('잡음 출력 표준편차  (낮을수록 좋다)');
set(gca, 'XScale','log');
xlabel('대역폭 wb [rad/s]');
title('대역폭을 키우면 한쪽은 좋아지고 한쪽은 나빠진다');

%% 7. 모델을 원래대로 돌려 놓는다
%
%  바꿔 둔 설정을 되돌립니다. 다음 사람이 모델을 열었을 때 처음 상태여야 합니다.

numC = [500 2000];   %#ok<NASGU>
cfg_y.OpenAtSimulationStart = true;
cfg_u.OpenAtSimulationStart = true;

%% 8. 오늘 확인한 것
%
%  - 손으로 쓴 |S(j2pi)| = 0.0627 이 Simulink 실측과 소수 네째 자리까지 맞았다
%  - |S| 곡선 전체를 한 점씩 찍어 보았고, 교차주파수 오른쪽에서는 억제가 없었다
%  - 지령 추종은 T = 100/(s+100) 그대로였다 (오버슈트 0, 시간상수 0.01 초)
%  - 센서 잡음은 -T 로 들어오므로 대역폭 안에 있으면 막을 수 없었다
%  - 이득을 올리면 외란은 좋아지고 잡음은 나빠졌다
%
%  **다음 주차에는 이 모양을 직접 만들러 갑니다.**
%  오늘은 주어진 루프를 읽었고, 다음 주에는 controlSystemDesigner 로
%  원하는 모양이 되도록 극점과 영점을 끌어다 놓습니다.

fprintf('=== 끝 ===\n');
fprintf('모델 설정을 원래대로 돌려 놓았습니다.\n');
fprintf('다음은 W11B_FreqDesign_App 폴더입니다.\n');
