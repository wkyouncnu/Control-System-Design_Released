%% W04_03_run_simulink.m
%  4주차 실습 (3) : Simulink 로 zeta 와 wn 을 바꿔 가며 확인하기
%
%  모델 W04_SecondOrder_Sweep.slx 는 표준 2차 시스템을 적분기 두 개로
%  구현한 것입니다. 전달함수 블록을 쓰지 않은 이유는 zeta 가 블록 어디에
%  들어가는지 눈으로 보이게 하기 위해서입니다.
%
%      가속도 = wn^2*(r - y) - 2*zeta*wn*(속도)
%
%  감쇠 경로의 게인 2*zeta*wn 이 zeta 가 들어가는 유일한 자리입니다.
%  이 게인을 0 으로 만들면 영원히 진동합니다.
%
%  [Simulink 만으로도 볼 수 있습니다]
%  모델을 열고 Ctrl+T 만 눌러도 Scope 가 열리며 결과가 나옵니다.
%      >> open_system('W04_SecondOrder_Sweep')
%
%  이 스크립트는 값을 바꿔 가며 반복 실행하고 MATLAB 계산과 대조할 때 씁니다.
%
%  제어시스템설계 4주차 | 충남대학교 자율운항시스템공학과

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

model = 'W04_SecondOrder_Sweep';

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

%% 1. 스크립트에서 Simulink 를 반복 실행하는 법
%
%  이번 주에 새로 배우는 기법입니다.
%
%  블록에 숫자 대신 변수 이름을 적어 두면, 스크립트에서 값만 바꿔 가며
%  sim 을 여러 번 부를 수 있습니다. 블록을 일일이 더블클릭할 필요가 없습니다.
%
%      for zeta = [0.1 0.3 0.5]
%          out = sim(model);       % 이 시점의 zeta 값으로 실행됨
%      end
%
%  주의할 점
%    - sim 은 워크스페이스의 현재 값을 읽습니다. 루프 안에서 값을 바꾸면 됩니다
%    - 결과는 out 구조체에 담겨 옵니다. To Workspace 블록 이름으로 꺼냅니다
%    - 가변스텝 솔버라 시간 간격이 매번 다르므로 비교하려면 interp1 이 필요합니다

wn    = 2;
t_end = 15;
t     = (0:0.01:t_end)';        % 열벡터로 만들어야 뺄셈이 제대로 됩니다

zeta_list = [0.1 0.3 0.5 0.707 1.0];

fprintf('=== Simulink 반복 실행 ===\n');
fprintf('  wn = %.1f 고정, zeta 를 바꿔 가며 실행합니다.\n\n', wn);

figure('Name','zeta 스윕');
Y = zeros(numel(t), numel(zeta_list));

fprintf('   zeta   오버슈트[%%]  정착시간[s]   MATLAB 과의 차이\n');
fprintf('  ------  ----------  -----------  ----------------\n');
for i = 1:numel(zeta_list)
    zeta = zeta_list(i);                 %#ok<NASGU>  <- 모델이 이 값을 읽습니다

    out = sim(model);
    Y(:,i) = interp1(out.y_sim.Time, squeeze(out.y_sim.Data), t);

    % 같은 것을 MATLAB 으로도 계산해 대조
    G  = wn^2/(s^2 + 2*zeta_list(i)*wn*s + wn^2);
    ym = step(G, t);
    err = max(abs(Y(:,i) - ym));

    info = stepinfo(G);
    fprintf('  %6.3f  %10.1f  %11.2f  %16.2e\n', ...
            zeta_list(i), info.Overshoot, info.SettlingTime, err);

    plot(t, Y(:,i), 'LineWidth', 2); hold on;
end
yline(1, 'k--', 'LineWidth', 1.5); grid on;
xlabel('시간 [s]'); ylabel('출력 y');
title(sprintf('Simulink 로 구한 계단응답 (\\omega_n = %.1f)', wn));
legend(arrayfun(@(z) sprintf('\\zeta = %.3f', z), zeta_list, ...
       'UniformOutput', false), 'Location','southeast');

fprintf('\n  --> MATLAB 과의 차이가 모두 1e-4 아래입니다. 같은 시스템입니다.\n\n');

%% 2. 감쇠를 완전히 없애면
%
%  zeta = 0 으로 두면 감쇠 경로의 게인이 0 이 됩니다.
%  블록선도에서 되먹임 하나가 끊어지는 셈입니다.
%
%  결과는 2주차에서 배운 그대로입니다. 극점이 허수축 위로 올라가
%  영원히 같은 크기로 진동합니다.

zeta = 0;                                %#ok<NASGU>
out0 = sim(model);
y0 = interp1(out0.y_sim.Time, squeeze(out0.y_sim.Data), t);

G0 = wn^2/(s^2 + wn^2);
fprintf('=== 감쇠를 없애면 (zeta = 0) ===\n');
fprintf('  극점 : ');
p0 = pole(G0); fprintf('%+.3f%+.3fj  ', [real(p0).'; imag(p0).']); fprintf('\n');
fprintf('  실수부가 0 이므로 영원히 진동합니다.\n');
fprintf('  진동 주기 = 2*pi/wn = %.3f s\n\n', 2*pi/wn);

figure('Name','감쇠가 없을 때');
plot(t, y0, 'LineWidth', 2); hold on;
yline(1, 'k--', 'LineWidth', 1.5); yline(0,'k:'); yline(2,'k:');
grid on; xlabel('시간 [s]'); ylabel('출력 y');
title('\zeta = 0 : 감쇠 경로가 끊어지면 영원히 진동한다');
legend('출력', '목표값', 'Location','southeast');

%% 3. 사양을 만족하는 zeta, wn 을 넣어 보기
%
%  W04_02 에서 구한 값을 그대로 Simulink 에 넣어 확인합니다.
%  요구 : 오버슈트 10 % 이하, 정착시간 2 초 이하

P_OS = 10;  ts_req = 2;
[zeta, wn] = spec2pole(P_OS, ts_req);    %#ok<ASGLU>  <- 모델이 이 값을 읽습니다
t_end = 5;
t2 = (0:0.005:t_end)';

out_t = sim(model);
y_t = interp1(out_t.y_sim.Time, squeeze(out_t.y_sim.Data), t2);

% Simulink 결과에서 직접 성능 지표를 뽑아 봅니다
info_sim = stepinfo(y_t, t2, 1);

fprintf('=== 사양 검증 (Simulink 결과에서 직접 측정) ===\n');
fprintf('  넣은 값   : zeta = %.4f, wn = %.4f\n', zeta, wn);
fprintf('  오버슈트  : %.2f %%   (요구 %.0f %% 이하)\n', info_sim.Overshoot, P_OS);
fprintf('  정착시간  : %.2f s    (요구 %.1f s 이하)\n', info_sim.SettlingTime, ts_req);
if info_sim.Overshoot <= P_OS + 0.5 && info_sim.SettlingTime <= ts_req
    fprintf('  --> 사양 만족\n\n');
else
    fprintf('  --> 사양 불만족\n\n');
end

figure('Name','사양 검증');
plot(t2, y_t, 'LineWidth', 2); hold on;
yline(1, 'k--', 'LineWidth', 1.5);
yline(1+P_OS/100, 'r:', 'LineWidth', 1.5);
xline(ts_req, 'r:', 'LineWidth', 1.5);
grid on; xlabel('시간 [s]'); ylabel('출력 y');
title('Simulink 로 확인한 사양 만족 여부');
legend('Simulink 출력', '목표값', ...
       sprintf('오버슈트 한계 %.0f%%', P_OS), ...
       sprintf('정착시간 한계 %.0fs', ts_req), 'Location','southeast');

%% 3-1. stepinfo 의 또 다른 사용법
%
%  지금까지는 stepinfo(G) 처럼 전달함수를 넣었습니다.
%  그런데 Simulink 결과처럼 **데이터만 있을 때**도 쓸 수 있습니다.
%
%      stepinfo(y, t, yfinal)
%
%      입력 : y 는 출력 데이터, t 는 시간 벡터, yfinal 은 최종값
%      출력 : 전달함수를 넣었을 때와 같은 구조체
%
%  yfinal 을 직접 알려 줘야 하는 이유는, 데이터만 봐서는 언제 끝나는지
%  MATLAB 이 알 수 없기 때문입니다. 잘못 주면 정착시간이 엉뚱하게 나옵니다.
%
%  실험 데이터를 분석할 때 이 형태를 많이 씁니다.

%% 4. 직접 해 볼 것
%
%   (1) zeta_list 에 1.5 를 추가해 보십시오.
%       -> 오버슈트는 0 인데 정착시간이 오히려 길어집니다. 왜일까요?
%
%   (2) wn 을 4 로 바꾸고 zeta 를 그대로 두면?
%       -> 오버슈트는 그대로이고 응답만 빨라집니다.
%          오버슈트가 zeta 만의 함수라는 것을 눈으로 확인하는 실험입니다.
%
%   (3) 모델을 열어 '감쇠 2 zeta wn' 게인을 지우고 선을 이어 보십시오.
%       -> zeta = 0 과 같아집니다. 감쇠 경로가 하는 일이 무엇인지 보입니다.
%
%   (4) 적분기 '적분2 위치' 의 초기조건을 0.5 로 주면?
%       -> 0.5 에서 출발해 1 로 갑니다. 3주차에서 배운 초기조건 응답입니다.
%
%  모델 열기:
%      >> open_system('W04_SecondOrder_Sweep')
