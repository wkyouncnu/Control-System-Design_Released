%% W07_06_run_simulink.m
%  7주차 실습 (6) : Simulink 로 확인하기 - 잡음과 포화
%
%  W07_05 에서 PD 는 고주파 이득이 무한히 커진다는 것을 계산으로 봤습니다.
%  심지어 MATLAB 은 PD 의 제어입력을 계산조차 하지 못했습니다.
%
%  Simulink 의 Derivative 블록은 수치미분으로 근사하므로 돌아가기는 합니다.
%  그런데 바로 그 때문에 잡음 문제가 그대로 드러납니다.
%
%  이 스크립트는 모델 두 개를 다룹니다.
%
%    W07_PD_Noise.slx       PD 의 잡음 증폭      -> 1~6 절
%    W07_Design_Verify.slx  포화와 설계 검증     -> 7 절
%
%  [Simulink 만으로도 볼 수 있습니다]
%      >> open_system('W07_PD_Noise')
%  열고 Ctrl+T 를 누르면 Scope 두 개가 열립니다.
%  아래쪽 제어입력 Scope 를 보십시오. PD 만 요동칩니다.
%
%  제어시스템설계 7주차 | 충남대학교 자율운항시스템공학과

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

model = 'W07_PD_Noise';

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

%% 1. 두 제어기 준비
%
%  W07_02 와 W07_05 에서 설계한 것을 그대로 씁니다.
%
%      PD   : C(s) = 18.9*(s + 3)  = 18.9*s + 56.7
%      Lead : C(s) = 265*(s + 2)/(s + 15)
%
%  Lead 는 제어입력이 지나치게 크지 않도록 p = 15 인 것을 골랐습니다.

[G, p] = plant_dcmotor('position');
[numG, denG] = tfdata(G, 'v');       %#ok<ASGLU>

Kd_pd = 18.9;  z_pd = 3;
Kp_pd = Kd_pd * z_pd;                %#ok<NASGU>

Kc_ld = 265;  z_ld = 2;  p_ld = 15;
C_lead = Kc_ld*(s + z_ld)/(s + p_ld);
[numC, denC] = tfdata(C_lead, 'v');  %#ok<ASGLU>

r_amp = 1;
t_end = 4;
noise_ts = 0.001;
t = (0:0.001:t_end)';

fprintf('=== 두 제어기 ===\n');
fprintf('  PD   : %.1f*s + %.1f\n', Kd_pd, Kp_pd);
fprintf('  Lead : %.0f*(s + %d)/(s + %d)\n', Kc_ld, z_ld, p_ld);
fprintf('\n');
fprintf('  1000 rad/s 에서의 이득\n');
fprintf('    PD   : %10.1f\n', abs(evalfr(Kd_pd*(s+z_pd), 1j*1000)));
fprintf('    Lead : %10.1f\n\n', abs(evalfr(C_lead, 1j*1000)));

%% 2. 잡음이 없을 때
%
%  먼저 잡음을 끄고 돌립니다. 두 제어기 모두 잘 동작해야 합니다.

noise_pow = 0;                       %#ok<NASGU>
out0 = sim(model);

y_pd0 = interp1(out0.y_pd.Time,   squeeze(out0.y_pd.Data),   t);
y_ld0 = interp1(out0.y_lead.Time, squeeze(out0.y_lead.Data), t);
u_pd0 = interp1(out0.u_pd.Time,   squeeze(out0.u_pd.Data),   t);
u_ld0 = interp1(out0.u_lead.Time, squeeze(out0.u_lead.Data), t);

fprintf('=== 잡음이 없을 때 ===\n');
fprintf('  제어기   오버슈트[%%]  정착시간[s]  최대 제어입력[V]\n');
fprintf('  ------  ----------  -----------  ----------------\n');
i1 = stepinfo(y_pd0, t, r_amp);
i2 = stepinfo(y_ld0, t, r_amp);
fprintf('  PD      %10.1f  %11.3f  %16.1f\n', i1.Overshoot, i1.SettlingTime, max(abs(u_pd0)));
fprintf('  Lead    %10.1f  %11.3f  %16.1f\n', i2.Overshoot, i2.SettlingTime, max(abs(u_ld0)));
fprintf('  --> 잡음이 없으면 둘 다 멀쩡합니다. 여기까지는 차이가 안 보입니다.\n\n');

%% 3. 잡음을 넣으면
%
%  아주 작은 측정 잡음을 넣습니다.
%  잡음 세기는 Band-Limited White Noise 블록의 Noise power 로 정합니다.
%
%  현실에서 엔코더나 퍼텐쇼미터에는 항상 이 정도 잡음이 있습니다.

noise_pow = 1e-8;                    %#ok<NASGU>
out1 = sim(model);

y_pd1 = interp1(out1.y_pd.Time,   squeeze(out1.y_pd.Data),   t);
y_ld1 = interp1(out1.y_lead.Time, squeeze(out1.y_lead.Data), t);
u_pd1 = interp1(out1.u_pd.Time,   squeeze(out1.u_pd.Data),   t);
u_ld1 = interp1(out1.u_lead.Time, squeeze(out1.u_lead.Data), t);

fprintf('=== 잡음을 넣으면 ===\n');
fprintf('  제어기   최대 제어입력[V]  제어입력의 표준편차   잡음 없을 때 대비\n');
fprintf('  ------  ----------------  -------------------  ----------------\n');

% 정상상태 구간(뒤쪽 절반)에서 제어입력이 얼마나 요동치는지 봅니다
half = t > t_end/2;
sd_pd = std(u_pd1(half));  sd_ld = std(u_ld1(half));
sd_pd0 = std(u_pd0(half)); sd_ld0 = std(u_ld0(half));

fprintf('  PD      %16.1f  %19.3f  %16.1f 배\n', ...
        max(abs(u_pd1)), sd_pd, sd_pd/max(sd_pd0, 1e-12));
fprintf('  Lead    %16.1f  %19.3f  %16.1f 배\n', ...
        max(abs(u_ld1)), sd_ld, sd_ld/max(sd_ld0, 1e-12));
fprintf('\n');
fprintf('  --> PD 의 제어입력이 Lead 보다 %.0f 배 더 요동칩니다.\n', sd_pd/sd_ld);
fprintf('      출력(각도)은 둘 다 비슷해 보이는데 제어입력만 다릅니다.\n');
fprintf('      그래서 출력만 보고 판단하면 이 문제를 놓칩니다.\n\n');

figure('Name','PD 의 잡음 증폭');
tiledlayout(2,1,'TileSpacing','compact');

nexttile
plot(t, y_pd1, 'LineWidth', 1.5); hold on;
plot(t, y_ld1, 'LineWidth', 1.5);
yline(r_amp, 'k--', 'LineWidth', 1.5); grid on;
ylabel('각도 [rad]');
title('출력만 보면 둘이 비슷하다');
legend('PD', 'Lead', '목표값', 'Location','southeast');

nexttile
plot(t, u_pd1, 'LineWidth', 1); hold on;
plot(t, u_ld1, 'LineWidth', 1.5);
grid on; xlabel('시간 [s]'); ylabel('제어입력 u [V]');
title('제어입력을 보면 PD 만 요동친다');
legend('PD', 'Lead', 'Location','northeast');

%% 4. 이것이 왜 심각한 문제인가
%
%  제어입력이 요동치면 실제로 이런 일이 생깁니다.
%
%      (1) 모터가 떨리고 소음이 난다
%      (2) 기어와 베어링이 빨리 마모된다
%      (3) 전력 소비가 커지고 드라이버가 발열한다
%      (4) 구동기가 계속 포화 근처를 오가며 수명이 준다
%
%  출력 그래프만 보면 아무 문제가 없어 보입니다.
%  그래서 **제어입력을 반드시 함께 봐야 합니다.**
%
%  이 과목에서 계속 강조하는 이유가 이것입니다.
%      6주차 : 제어입력이 구동기 한계를 넘는지 확인하라
%      7주차 : 제어입력이 잡음으로 요동치는지 확인하라

%% 5. 잡음 세기를 바꿔 가며
%
%  잡음이 커지면 얼마나 나빠지는지 봅니다.

pow_list = [0 1e-9 1e-8 1e-7];

fprintf('=== 잡음 세기별 제어입력 요동 (표준편차) ===\n');
fprintf('  잡음 세기      PD        Lead     PD~Lead 비\n');
fprintf('  ----------  --------  --------  -----------\n');
for pw = pow_list
    noise_pow = pw;                  %#ok<NASGU>
    o = sim(model);
    up = interp1(o.u_pd.Time,   squeeze(o.u_pd.Data),   t);
    ul = interp1(o.u_lead.Time, squeeze(o.u_lead.Data), t);
    sp1 = std(up(half));  sl1 = std(ul(half));
    fprintf('  %10.0e  %8.2f  %8.4f  %11.0f\n', pw, sp1, sl1, sp1/max(sl1,1e-12));
end
fprintf('\n');
fprintf('  --> 잡음이 커질수록 PD 쪽만 급격히 나빠집니다.\n');
fprintf('      Lead 는 고주파 이득이 제한되어 있어 거의 영향을 받지 않습니다.\n\n');

%% 6. 실무에서 쓰는 또 하나의 방법 : 유사미분
%
%  Lead 보상기 말고도 미분항을 안전하게 쓰는 방법이 있습니다.
%
%      순수 미분   : Kd*s              <- 고주파 이득 무한대
%      유사미분    : Kd*s/(tau*s + 1)  <- 고주파 이득이 Kd/tau 로 제한
%
%  분모에 1차 필터를 붙인 것입니다.
%  tau 를 작게 하면 미분에 가까워지고, 크게 하면 잡음에 강해집니다.
%
%  사실 유사미분을 쓴 PD 는 Lead 보상기와 **같은 꼴**입니다.
%
%      Kp + Kd*s/(tau*s+1) = (Kp*tau*s + Kp + Kd*s)/(tau*s+1)
%
%  분자와 분모가 모두 1차인 전달함수, 즉 Lead 입니다.
%  이름만 다를 뿐 같은 것을 하고 있는 셈입니다.
%
%  Simulink 의 PID Controller 블록도 내부적으로 이 방식을 씁니다.
%  블록을 열어 보면 "Filter coefficient N" 이라는 값이 있는데,
%  그것이 바로 tau = 1/N 입니다. 11주차에서 다시 만납니다.

tau_list = [0.01 0.05 0.2];
fprintf('=== 유사미분의 고주파 이득 ===\n');
fprintf('  방식              1000 rad~s 이득\n');
fprintf('  ----------------  ---------------\n');
fprintf('  순수 미분 Kd*s    %15.1f\n', abs(evalfr(Kd_pd*s, 1j*1000)));
for tau = tau_list
    Cd = Kd_pd*s/(tau*s + 1);
    fprintf('  유사미분 tau=%.2f  %15.1f\n', tau, abs(evalfr(Cd, 1j*1000)));
end
fprintf('  --> tau 가 클수록 잡음에 강하지만 미분 효과는 약해집니다.\n\n');

%% 7. 두 번째 모델 - 제어입력 한계까지 넣은 설계의 검증
%
%  모델 : W07_Design_Verify.slx
%
%  W07_04 에서 이렇게 설계했습니다.
%
%      G(s) = 1/(s(s+2)(s+5)) ,  비례제어
%      사양 : Ts < 5.2 s , Mp < 1 % , |u| <= 5
%      결과 : K* = 4.79
%
%  이 설계가 실제 구동기에서도 맞는지 확인합니다.
%  모델은 같은 루프를 두 개 갖고 있습니다.
%
%      위   : 포화 없음 (설계할 때 가정한 세상)
%      아래 : Saturation 블록으로 +-u_lim 제한 (실제 세상)
%
%  설계를 제대로 했다면 두 응답이 겹쳐야 합니다.

model2 = 'W07_Design_Verify';

%  이 두 번째 모델도 블록부터 읽고 들어갑니다.
%  앞의 W07_PD_Noise 와 달리 제어기는 비례이득 하나뿐입니다.
%  대신 똑같은 루프가 위아래로 두 벌 있고, 아래쪽에만 Saturation 이 있습니다.
%  즉 두 루프의 차이는 그 블록 하나뿐입니다. 표를 읽으며 확인해 보십시오.

model_blocks(model2, 'print');

K_des  = 4.79;
u_lim  = 5;
numG2  = 1;
denG2  = [1 7 10 0];
t_end2 = 12;

assignin('base','K_des',K_des);   assignin('base','u_lim',u_lim);
assignin('base','numG2',numG2);   assignin('base','denG2',denG2);
assignin('base','t_end2',t_end2);

%  가변 스텝 솔버는 시간 간격이 일정하지 않습니다.
%  MATLAB 의 step 과 비교하려면 균일한 시간 격자로 옮겨 놓아야 합니다.
t_i = (0:0.01:t_end2)';

out2 = sim(model2);
y_i = interp1(out2.y_ideal.Time, squeeze(out2.y_ideal.Data), t_i);
y_r = interp1(out2.y_real.Time,  squeeze(out2.y_real.Data),  t_i);
u_i = interp1(out2.u_ideal.Time, squeeze(out2.u_ideal.Data), t_i);
u_r = interp1(out2.u_real.Time,  squeeze(out2.u_real.Data),  t_i);

G2  = tf(numG2, denG2);
y_m = step(feedback(K_des*G2, 1), t_i);

fprintf('=== 설계값 K = %.2f 로 검증 ===\n', K_des);
fprintf('  Simulink(포화 없음) vs MATLAB 계산 : 최대 차이 %.2e\n', max(abs(y_i - y_m)));
fprintf('  포화 없음 vs 포화 있음            : 최대 차이 %.2e\n', max(abs(y_i - y_r)));
fprintf('  최대 제어입력 %.3f  (한계 %.1f)\n', max(abs(u_i)), u_lim);
fprintf('  --> 한계에 닿지 않으므로 포화가 작동하지 않았습니다.\n');
fprintf('      설계할 때 제어입력을 사양에 넣은 보람이 여기 있습니다.\n\n');

%% 7-1. 제어입력을 사양에서 빼면 어떻게 되는가
%
%  같은 사양을 출력만 보고 설계했다면 이득을 더 크게 잡았을 것입니다.
%  이득을 키워 가며 포화가 얼마나 망치는지 봅니다.

fprintf('=== 이득을 키우면 (제어입력 사양을 무시하면) ===\n');
fprintf('     K     max|u| 요구   실제 낸 값   출력 최대 차이   오버슈트[%%]\n');
fprintf('   -----  -----------  -----------  --------------  ------------\n');

Ktest = [4.79 10 20 40];
store = cell(numel(Ktest), 3);
for i = 1:numel(Ktest)
    assignin('base','K_des',Ktest(i));
    oi  = sim(model2);
    ti  = t_i;
    yi  = interp1(oi.y_ideal.Time, squeeze(oi.y_ideal.Data), ti);
    yr  = interp1(oi.y_real.Time,  squeeze(oi.y_real.Data),  ti);
    ui  = interp1(oi.u_ideal.Time, squeeze(oi.u_ideal.Data), ti);
    ur  = interp1(oi.u_real.Time,  squeeze(oi.u_real.Data),  ti);
    ov  = 100*(max(yr) - 1);
    fprintf('   %5.1f  %11.2f  %11.2f  %14.4f  %12.2f\n', ...
            Ktest(i), max(abs(ui)), max(abs(ur)), max(abs(yi-yr)), ov);
    store{i,1} = ti; store{i,2} = yr; store{i,3} = ur;
end
assignin('base','K_des',K_des);

fprintf('\n  읽는 법\n');
fprintf('    - K 가 커질수록 제어기가 요구하는 값과 실제 낸 값이 벌어집니다\n');
fprintf('    - 벌어지는 순간부터 응답이 설계와 달라집니다\n');
fprintf('    - 근궤적은 이 현상을 전혀 모릅니다. 포화는 비선형이기 때문입니다\n\n');

figure('Name','포화가 설계를 망치는 과정','Position',[140 140 1000 400]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile
hold on; grid on;
for i = 1:numel(Ktest)
    plot(store{i,1}, store{i,2}, 'LineWidth', 2, ...
         'DisplayName', sprintf('K = %.2f', Ktest(i)));
end
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력'); title('포화가 있는 실제 응답');
legend('Location','southeast');

nexttile
hold on; grid on;
for i = 1:numel(Ktest)
    plot(store{i,1}, store{i,3}, 'LineWidth', 2, ...
         'DisplayName', sprintf('K = %.2f', Ktest(i)));
end
yline(u_lim,'r--','DisplayName','구동기 한계');
xlabel('시간 [s]'); ylabel('실제 제어입력'); title('한계에 붙어 버린다');
legend('Location','northeast');

%% 8. 이번 실습의 정리
%
%  1) 잡음이 없으면 PD 와 Lead 는 구별되지 않는다.
%
%  2) 잡음을 넣으면 PD 의 제어입력만 심하게 요동친다.
%     출력은 비슷해 보이므로 출력만 보면 이 문제를 놓친다.
%
%  3) 제어입력이 요동치면 소음, 마모, 발열, 수명 단축으로 이어진다.
%     실무에서 매우 중요한 문제다.
%
%  4) 해결책은 두 가지이고 사실 같은 것이다.
%       Lead 보상기를 쓴다
%       PD 의 미분항에 필터를 붙인다 (유사미분)
%     둘 다 분모를 만들어 고주파 이득을 제한하는 것이다.
%
%  5) 두 번째 모델에서는 제어입력 한계까지 넣고 설계한 결과를 확인했다.
%     제대로 설계했으면 포화가 작동하지 않아 두 응답이 겹친다.
%     이득을 키우면 포화가 걸리고 근궤적 예측이 무너진다.
%
%  6) 이 과목의 반복되는 교훈: **출력만 보지 말고 제어입력도 보라.**
%
%  다음 주 예고
%      8주차는 중간고사입니다.
%      9주차부터는 같은 문제를 주파수영역에서 다시 봅니다.
%      오늘 "고주파 이득" 이라고 부른 것이 그때 Bode 선도로 정확히 그려집니다.
