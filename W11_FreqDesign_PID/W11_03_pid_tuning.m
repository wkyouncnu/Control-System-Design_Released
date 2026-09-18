%% W11_03_pid_tuning.m
%  11주차 실습 (3) : PID 와 자동 튜닝
%
%  이 스크립트에서 답할 질문
%    Q1. P, I, D 는 각각 무슨 일을 하는가?          -> 1절
%    Q2. 미분항은 왜 그대로 쓰면 안 되는가?         -> 2절
%    Q3. 지글러-니콜스 방법은 무엇인가?             -> 3절
%    Q4. pidtune 은 무엇을 해 주는가?               -> 4절
%    Q5. 자동 튜닝을 믿어도 되는가?                 -> 5절
%    Q6. PID 와 Lead-Lag 는 무슨 관계인가?          -> 6절
%
%  대응하는 강의노트 : W11_LectureNote.mlx
%  대응하는 Simulink : W11_PID_AntiWindup.slx
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

%% 1. P, I, D 는 각각 무슨 일을 하는가
%
%      u(t) = Kp*e + Ki*(적분 e) + Kd*(de/dt)
%
%  세 항의 역할을 한 줄로 적으면
%
%      P : **지금** 오차가 얼마나 큰가
%      I : **지금까지** 오차가 얼마나 쌓였는가
%      D : 오차가 **어느 쪽으로 가고 있는가**
%
%  주파수영역으로 옮기면 이렇게 됩니다.
%
%      I : 저주파 이득을 올린다 (타입 상승) -> 정상상태 오차
%      D : 위상을 올린다                     -> 안정도와 과도응답
%      P : 전체를 위아래로 옮긴다            -> 빠르기
%
%  즉 **I 는 Lag 계열, D 는 Lead 계열**입니다. 이름만 다릅니다.

[G, p] = plant_dcmotor('speed');
t = (0:0.005:4)';

fprintf('=== 오늘의 플랜트 : DC 모터 속도 모델 ===\n');
G
fprintf('  직류이득 %.4f (1 V 를 넣으면 %.3f rad s^-1)\n', dcgain(G), dcgain(G));
fprintf('  극점 %s\n\n', mat2str(round(pole(G).',3)));

Kp = 100;  Ki = 200;  Kd = 10;  Nf = 100;
C_p   = Kp;
C_pi  = Kp + Ki/s;
C_pd  = Kp + Kd*s/(s/Nf + 1);
C_pid = Kp + Ki/s + Kd*s/(s/Nf + 1);

fprintf('=== 항을 하나씩 더해 가며 ===\n');
fprintf('   제어기   정상상태 오차   오버슈트[%%]   정착시간[s]   위상여유[도]\n');
fprintf('   ------  --------------  ------------  -----------  ------------\n');
ctrls = { 'P', C_p; 'PI', C_pi; 'PD', C_pd; 'PID', C_pid };
for i = 1:4
    Ci = ctrls{i,2};
    Ti = feedback(Ci*G, 1);
    ii = stepinfo(Ti);
    [~, pmi] = margin(Ci*G);
    fprintf('   %-6s  %14.5f  %12.2f  %11.3f  %12.2f\n', ...
            ctrls{i,1}, 1-dcgain(Ti), ii.Overshoot, ii.SettlingTime, pmi);
end
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    I 를 넣으면 정상상태 오차가 0 이 됩니다.\n');
fprintf('    D 를 넣으면 오버슈트가 줄고 위상여유가 커집니다.\n');
fprintf('    둘 다 넣은 것이 PID 입니다.\n\n');

figure('Name','P, PI, PD, PID', 'Position',[80 80 950 400]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile; hold on; grid on;
for i = 1:4
    plot(t, step(feedback(ctrls{i,2}*G,1), t), 'LineWidth', 2, 'DisplayName', ctrls{i,1});
end
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('각속도 [rad s^{-1}]'); legend('Location','southeast');
title('I 는 오차를 없애고 D 는 진동을 잡는다');
nexttile; hold on; grid on;
for i = 1:4
    plot(t, step(feedback(ctrls{i,2}, G), t), 'LineWidth', 2, 'DisplayName', ctrls{i,1});
end
xlabel('시간 [s]'); ylabel('제어입력 [V]'); legend('Location','northeast');
title('공짜가 아니다 — 제어입력도 함께 본다');

%% 2. 미분항은 그대로 쓰면 안 된다
%
%  이상적인 미분기 Kd*s 는 두 가지 문제가 있습니다.
%
%    (1) **부적절(improper)** 하다. 분자 차수가 분모보다 높아 실제로 만들 수 없다
%    (2) 고주파 이득이 무한대라 **잡음을 무한히 증폭**한다
%
%  그래서 실제로는 필터를 붙입니다.
%
%      Kd*s  ->  Kd*s/(s/N + 1)
%
%  N 이 필터의 세기입니다. 크면 이상적 미분기에 가깝고, 작으면 순해집니다.
%  실무에서는 N = 10 ~ 100 을 씁니다.
%
%  이것이 7주차에서 배운 **Lead 보상기와 정확히 같은 구조**입니다.
%  이름만 다릅니다.

fprintf('=== 미분 필터 N 의 영향 ===\n');
fprintf('       N     w = 1000 에서의 제어기 크기[dB]   위상여유[도]   오버슈트[%%]\n');
fprintf('   -------  -------------------------------  ------------  ------------\n');
for N = [5 20 100 1000]
    Cn = Kp + Ki/s + Kd*s/(s/N + 1);
    [~, pmn] = margin(Cn*G);
    iin = stepinfo(feedback(Cn*G,1));
    fprintf('   %7.0f  %31.2f  %12.2f  %12.2f\n', ...
            N, 20*log10(abs(freqresp(Cn, 1000))), pmn, iin.Overshoot);
end
fprintf('   --> N 이 커질수록 고주파 이득이 커집니다. 잡음에 그만큼 약해집니다.\n');
fprintf('       성능은 N = 20 이나 1000 이나 큰 차이가 없습니다.\n');
fprintf('       그러면 **작은 N 을 쓰는 것이 이득**입니다.\n\n');

w = logspace(-1, 4, 600);
figure('Name','미분 필터', 'Position',[80 80 880 400]);
semilogx(w, 20*log10(squeeze(abs(freqresp(Kp + Ki/s + Kd*s, w)))), 'k--', 'LineWidth', 2);
hold on; grid on;
for N = [5 20 100]
    Cn = Kp + Ki/s + Kd*s/(s/N + 1);
    semilogx(w, 20*log10(squeeze(abs(freqresp(Cn, w)))), 'LineWidth', 2);
end
xlabel('주파수 [rad s^{-1}]'); ylabel('제어기 크기 [dB]');
legend('필터 없음 (이상적 미분)','N = 5','N = 20','N = 100','Location','northwest');
title('필터가 고주파 이득을 막아 준다');

%% 3. 지글러-니콜스 방법
%
%  모델을 잘 모를 때 쓰는 고전적인 경험식입니다.
%
%  절차
%    (1) I 와 D 를 끄고 P 만으로 이득을 올린다
%    (2) 지속진동이 시작되는 이득을 Ku (임계이득), 그 진동 주기를 Tu 라 한다
%    (3) 표에서 값을 읽는다
%
%       제어기    Kp          Ti         Td
%       -------  ----------  ---------  ---------
%       P        0.5*Ku       -          -
%       PI       0.45*Ku     Tu/1.2      -
%       PID      0.6*Ku      Tu/2       Tu/8
%
%  **Ku 와 Tu 는 주파수영역 개념 그 자체입니다.**
%    Ku = 이득여유가 1 이 되는 이득  -> margin 으로 바로 구할 수 있다
%    Tu = 2*pi/wcg                  -> 위상이 -180도인 주파수의 주기
%
%  즉 지글러-니콜스는 **주파수영역 정보를 실험으로 얻는 방법**입니다.
%
%  주의 — 이 플랜트(DC 모터 속도)는 2차라 비례제어로 아무리 이득을 키워도
%  불안정해지지 않습니다. 그래서 Ku 가 존재하지 않습니다.
%  적분기가 있는 위치 모델로 해 봅니다.

Gpos = plant_dcmotor('position');
[gm_u, ~, wcg_u] = margin(Gpos);

fprintf('=== 지글러-니콜스 (DC 모터 위치 모델) ===\n');
if isfinite(gm_u)
    Ku = gm_u;                 % 이득이 1 일 때의 이득여유 = 임계이득
    Tu = 2*pi/wcg_u;
    fprintf('  임계이득 Ku = %.2f  (margin 의 이득여유)\n', Ku);
    fprintf('  임계주기 Tu = %.4f s  (= 2*pi/wcg, wcg = %.3f)\n\n', Tu, wcg_u);

    zn = { 'P',   0.5*Ku,   Inf,      0
           'PI',  0.45*Ku,  Tu/1.2,   0
           'PID', 0.6*Ku,   Tu/2,     Tu/8 };

    fprintf('   제어기     Kp        Ki        Kd     오버슈트[%%]   정착시간[s]   위상여유[도]\n');
    fprintf('   ------  --------  --------  --------  ------------  -----------  ------------\n');
    tz = (0:0.002:3)';
    figure('Name','지글러-니콜스', 'Position',[80 80 880 400]);
    hold on; grid on;
    for i = 1:3
        kp = zn{i,2};
        ki = kp/zn{i,3};
        kd = kp*zn{i,4};
        Cz = kp + ki/s + kd*s/(s/Nf + 1);
        Tz = feedback(Cz*Gpos, 1);
        iz = stepinfo(Tz);
        [~, pmz] = margin(Cz*Gpos);
        fprintf('   %-6s  %8.2f  %8.2f  %8.3f  %12.2f  %11.3f  %12.2f\n', ...
                zn{i,1}, kp, ki, kd, iz.Overshoot, iz.SettlingTime, pmz);
        plot(tz, step(Tz, tz), 'LineWidth', 2, 'DisplayName', zn{i,1});
    end
    yline(1,'k--','HandleVisibility','off');
    xlabel('시간 [s]'); ylabel('각도 [rad]'); legend('Location','southeast');
    title('지글러-니콜스 : 빠르지만 오버슈트가 크다');
    fprintf('\n');
    fprintf('  읽는 법\n');
    fprintf('    지글러-니콜스는 **빠르지만 오버슈트가 큽니다** (보통 25 %% 안팎).\n');
    fprintf('    원래 화학공정의 외란 억제를 목표로 만든 규칙이라 그렇습니다.\n');
    fprintf('    지령추종이 목적이면 그대로 쓰면 안 되고 손을 봐야 합니다.\n');
    fprintf('    특히 PI 행을 보십시오. 이 플랜트는 이미 적분기를 하나 가진 타입 1 인데\n');
    fprintf('    적분기를 하나 더 얹었으니 위상여유가 1 도까지 떨어집니다.\n');
    fprintf('    **지글러-니콜스 표는 타입 0 공정을 전제로 만든 것**이라 그렇습니다.\n');
    fprintf('    표를 외워 쓰지 말고 왜 그런 값인지 알고 써야 합니다.\n');
    fprintf('    **출발점으로만 쓰십시오.**\n\n');
else
    fprintf('  이 플랜트는 비례제어로 불안정해지지 않아 Ku 가 없습니다.\n\n');
end

%% 4. `pidtune` — 자동 튜닝
%
%  **오늘의 새 명령입니다.**
%
%  명령 정리
%
%    - **원리** : 목표 교차주파수를 정하고, 그 주파수에서 위상여유가 약 60도가
%                 되도록 Kp, Ki, Kd 를 최적화한다. 즉 **주파수영역 설계**다
%    - **입력** : pidtune(G, type) 또는 pidtune(G, type, wc)
%                 type 은 'P','PI','PID','PIDF' 등
%    - **출력** : pid 객체와 정보 구조체
%
%  주의 세 가지
%
%    (1) 모델이 **정확해야** 한다. pidtune 은 모델을 그대로 믿는다
%    (2) 기본 목표는 위상여유 60도다. 바꾸려면 pidtuneOptions 를 쓴다
%    (3) 결과를 **반드시 검증**해야 한다. 특히 제어입력과 포화

[C_auto, info_auto] = pidtune(G, 'PIDF');

fprintf('=== pidtune 기본 설정 ===\n');
C_auto
fprintf('  교차주파수 %.3f rad s^-1, 위상여유 %.2f 도\n', ...
        info_auto.CrossoverFrequency, info_auto.PhaseMargin);
ii_auto = stepinfo(feedback(C_auto*G, 1));
fprintf('  오버슈트 %.2f %%, 정착시간 %.3f s\n\n', ii_auto.Overshoot, ii_auto.SettlingTime);

%% 4-1. 교차주파수를 지정하면
%
%  pidtune 의 세 번째 인자로 목표 교차주파수를 줄 수 있습니다.
%  이것이 곧 **얼마나 빠르게 만들 것인가** 입니다.

wc_list = [2 5 10 20 50];
fprintf('=== 목표 교차주파수를 바꿔 가며 ===\n');
fprintf('    wc 목표    실제 wc    위상여유[도]   오버슈트[%%]   정착시간[s]   최대 |u|[V]\n');
fprintf('   ---------  ---------  ------------  ------------  -----------  ------------\n');

tp = (0:0.002:3)';
figure('Name','pidtune 교차주파수 스윕', 'Position',[80 80 950 400]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile; hold on; grid on;
Us = zeros(numel(tp), numel(wc_list));
for i = 1:numel(wc_list)
    [Ci, infoi] = pidtune(G, 'PIDF', wc_list(i));
    Ti = feedback(Ci*G, 1);
    ji = stepinfo(Ti);
    ui = step(feedback(Ci, G), tp);
    Us(:,i) = ui;
    fprintf('   %9.1f  %9.3f  %12.2f  %12.2f  %11.3f  %12.1f\n', ...
            wc_list(i), infoi.CrossoverFrequency, infoi.PhaseMargin, ...
            ji.Overshoot, ji.SettlingTime, max(abs(ui)));
    plot(tp, step(Ti, tp), 'LineWidth', 2, ...
         'DisplayName', sprintf('\\omega_c = %d', wc_list(i)));
end
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('각속도 [rad s^{-1}]'); legend('Location','southeast');
title('교차주파수를 올리면 빨라진다');

nexttile; hold on; grid on;
for i = 1:numel(wc_list)
    plot(tp, Us(:,i), 'LineWidth', 2, 'DisplayName', sprintf('\\omega_c = %d', wc_list(i)));
end
yline(15,'r:','HandleVisibility','off'); yline(-15,'r:','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('제어입력 [V]'); legend('Location','northeast');
title('빨라진 만큼 전압을 더 쓴다 (빨간선 = 15 V 한계)');

fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    교차주파수를 두 배로 하면 정착시간은 대략 절반이 됩니다.\n');
fprintf('    그런데 제어입력은 **네 배쯤** 커집니다. 표에서 확인하십시오.\n');
fprintf('    빠르게 만드는 값은 선형이 아니라 제곱으로 비쌉니다.\n');
fprintf('    구동기가 15 V 라면 이 플랜트에서는 wc = 2 정도밖에 못 씁니다.\n');
fprintf('    **자동 튜닝도 구동기 한계는 모릅니다.** 우리가 확인해야 합니다.\n\n');

%% 5. 자동 튜닝을 믿어도 되는가
%
%  pidtune 은 **모델을 그대로 믿습니다.** 모델이 틀리면 결과도 틀립니다.
%  모델 오차를 넣어 확인해 봅시다.
%
%  DC 모터의 관성 J 가 설계값의 1.5 배였다고 해 봅시다.

[G_true, ~] = plant_dcmotor('speed');
J = p.J*1.5;  b = p.b;  Km = p.K;  R = p.R;  L = p.L;
G_real = Km/((J*s + b)*(L*s + R) + Km^2);       % 실제 (관성이 더 크다)

[C5, ~] = pidtune(G, 'PIDF', 10);               % 설계는 잘못된 모델로

fprintf('=== 모델이 틀렸을 때 ===\n');
fprintf('  설계에 쓴 모델의 관성 J = %.4f\n', p.J);
fprintf('  실제 관성          J = %.4f  (1.5 배)\n\n', J);
fprintf('                 위상여유[도]   오버슈트[%%]   정착시간[s]\n');
fprintf('   -----------  ------------  ------------  -----------\n');
for i = 1:2
    if i == 1, Gi = G; nm = '설계 모델'; else, Gi = G_real; nm = '실제 플랜트'; end
    [~, pmi] = margin(C5*Gi);
    ji = stepinfo(feedback(C5*Gi, 1));
    fprintf('   %-11s  %12.2f  %12.2f  %11.3f\n', nm, pmi, ji.Overshoot, ji.SettlingTime);
end
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    모델이 틀려도 **여유가 있으면 버팁니다.** 그것이 10주차에서 배운 여유입니다.\n');
fprintf('    pidtune 이 기본으로 위상여유 60도를 목표로 하는 이유가 이것입니다.\n');
fprintf('    여유를 줄여 빠르게 만들수록 모델 오차에 약해집니다.\n\n');

t5 = (0:0.005:3)';
figure('Name','모델 오차', 'Position',[80 80 880 400]);
plot(t5, step(feedback(C5*G,1), t5), 'LineWidth', 2.4); hold on; grid on;
plot(t5, step(feedback(C5*G_real,1), t5), '--', 'LineWidth', 2.4);
yline(1,'k--');
xlabel('시간 [s]'); ylabel('각속도 [rad s^{-1}]');
legend('설계에 쓴 모델', '실제 플랜트 (관성 1.5 배)', 'Location','southeast');
title('여유가 있으면 모델이 틀려도 버틴다');

%% 6. PID 와 Lead-Lag 는 같은 것이다
%
%  이름과 표기만 다릅니다. 하는 일은 같습니다.
%
%     PID 의 항        주파수영역에서 하는 일        대응하는 보상기
%     --------------  ---------------------------  ----------------
%     I               저주파 이득을 올린다           Lag (또는 PI)
%     D (필터 포함)   위상을 올린다                  Lead (또는 PD)
%     P               전체 크기를 옮긴다             비례이득
%
%  실제로 PID 를 정리하면 Lead-Lag 와 같은 모양이 나옵니다.

C_pidf = pidtune(G, 'PIDF', 10);
C_tf = tf(C_pidf);

fprintf('=== PID 를 전달함수로 정리하면 ===\n');
C_tf
fprintf('  영점 : %s\n', mat2str(round(zero(C_tf).', 3)));
fprintf('  극점 : %s\n', mat2str(round(pole(C_tf).', 3)));
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    원점에 극점이 하나 있습니다  -> 적분기 = Lag 역할\n');
fprintf('    영점이 둘 있습니다           -> 미분 = Lead 역할\n');
fprintf('    나머지 극점 하나는 미분 필터입니다\n');
fprintf('    즉 PID(필터 포함) = **Lag 한 단 + Lead 한 단** 입니다.\n\n');

%% 7. 이번 실습의 정리
%
%   (1) I 는 Lag 계열(저주파 이득), D 는 Lead 계열(위상). 이름만 다르다
%   (2) 미분항에는 반드시 필터를 붙인다. N = 10~100
%   (3) 지글러-니콜스의 Ku, Tu 는 사실 이득여유와 wcg 다
%   (4) pidtune 은 주파수영역 설계를 자동으로 한다. 기본 목표는 위상여유 60도
%   (5) 자동 튜닝도 **구동기 한계와 모델 오차는 모른다.** 반드시 검증한다
%   (6) PID = Lead + Lag. 같은 것을 다르게 부르는 것이다
%
%  다음 실습
%    W11_04_run_simulink.m — 실제로 쓸 때 생기는 문제 : 적분 와인드업
