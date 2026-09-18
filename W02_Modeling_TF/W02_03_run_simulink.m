%% W02_03_run_simulink.m
%  2주차 실습 (3) : 같은 시스템을 Simulink 에서 세 가지 방법으로 만들기
%
%  W02_02 에서 우리는 이런 흐름을 배웠습니다.
%
%      미분방정식  ->  전달함수  ->  (상태공간)
%
%  이 셋이 "같은 것의 다른 표현"이라는 말을 자주 듣지만, 정말 그런지
%  직접 확인해 본 적은 없을 것입니다. 이번 실습에서 확인합니다.
%
%  모델 W02_MSD_ThreeWays.slx 에는 세 개의 경로가 나란히 들어 있습니다.
%      경로 A : 적분기 두 개로 미분방정식을 그대로 구현
%      경로 B : Transfer Fcn 블록
%      경로 C : State-Space 블록
%
%  이 스크립트에서 답할 질문
%    Q1. 세 경로의 응답이 정말 같은가?                        -> 3절
%    Q2. 초기조건을 주면 어떻게 되는가?                       -> 4절 (중요)
%
%  제어시스템설계 2주차 | 충남대학교 자율운항시스템공학과

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

model = 'W02_MSD_ThreeWays';

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
%  세 경로가 모두 같은 물리 파라미터를 쓰도록 워크스페이스에 변수를 만듭니다.
%  경로 A 는 m, b, k 를 각각 쓰고
%  경로 B 는 분모 계수 [m b k] 를 쓰고
%  경로 C 는 상태공간 행렬 A_msd, B_msd, C_msd, D_msd 를 씁니다.
%
%  세 경로가 같은 숫자를 보고 있다는 점이 중요합니다.
%  그래야 "표현이 다를 뿐 같은 시스템"이라는 비교가 성립합니다.

[G, p] = plant_msd();

m = p.m;   b = p.b;   k = p.k;

A_msd = p.A;   B_msd = p.B;   C_msd = p.C;   D_msd = p.D;

F_amp = 1;          % 입력 힘의 크기 [N]
t_end = 40;         % 시뮬레이션 시간 [s]

fprintf('=== 파라미터 ===\n');
fprintf('  m = %.2f,  b = %.2f,  k = %.2f\n', m, b, k);
fprintf('  상태공간 A = [%g %g ; %g %g]\n', A_msd(1,1), A_msd(1,2), A_msd(2,1), A_msd(2,2));
fprintf('  상태공간 B = [%g ; %g]\n\n', B_msd(1), B_msd(2));

%% 2. 실험 1 : 초기조건 0, 계단 입력
%
%  가장 기본적인 경우입니다. 물체가 가만히 있는 상태에서 힘 1 N 을 가합니다.
%  세 경로의 응답이 완전히 겹쳐야 합니다.

x0_pos = 0;         % 초기 위치 [m]
x0_vel = 0;         % 초기 속도 [m/s]

fprintf('=== 실험 1 : 초기조건 0 ===\n');
out1 = sim(model);

t  = (0:0.01:t_end)';
yA = interp1(out1.y_A.Time, squeeze(out1.y_A.Data), t);
yB = interp1(out1.y_B.Time, squeeze(out1.y_B.Data), t);
yC = interp1(out1.y_C.Time, squeeze(out1.y_C.Data), t);

% MATLAB 쪽 계산 (비교 기준)
yM = step(F_amp*G, t);

fprintf('  경로 A(적분기) vs 경로 B(전달함수) 최대 차이 : %.3e m\n', max(abs(yA-yB)));
fprintf('  경로 A(적분기) vs 경로 C(상태공간) 최대 차이 : %.3e m\n', max(abs(yA-yC)));
fprintf('  경로 B vs MATLAB step 명령        최대 차이 : %.3e m\n', max(abs(yB-yM)));
fprintf('  --> 세 표현이 같은 시스템임이 확인됩니다.\n\n');

figure('Name','실험 1 : 초기조건 0');
h1 = plot(t, yA, 'LineWidth', 3); hold on;
h2 = plot(t, yB, '--', 'LineWidth', 2.5);
h3 = plot(t, yC, ':', 'LineWidth', 2.5);
h4 = plot(t, yM, 'k-.', 'LineWidth', 1.5);
grid on;
xlabel('Time [s]'); ylabel('x [m]');
title('초기조건 0 : 네 가지 방법의 응답이 완전히 겹친다');
legend([h1 h2 h3 h4], {'경로 A (적분기)', '경로 B (Transfer Fcn)', ...
       '경로 C (State-Space)', 'MATLAB step'}, 'Location','southeast');

%% 3. 왜 겹치는가
%
%  겹치는 것이 당연해 보이지만, 사실 세 경로는 계산 방식이 전혀 다릅니다.
%
%    경로 A : 매 시간스텝마다 가속도를 계산해 두 번 적분합니다.
%             솔버가 미분방정식을 수치적으로 푸는 것입니다.
%    경로 B : 전달함수를 내부적으로 상태공간으로 바꾼 뒤 적분합니다.
%    경로 C : 주어진 A, B, C, D 행렬로 바로 적분합니다.
%
%  계산 경로가 달라도 답이 같은 이유는, 셋 다 같은 미분방정식을 나타내기
%  때문입니다. 표현은 사람이 편하려고 고른 옷일 뿐이고, 알맹이는 하나입니다.
%
%  실무적으로는 이렇게 골라 씁니다.
%      적분기 구성  : 시스템 내부를 보여 주고 싶을 때, 비선형 요소를 넣을 때
%      Transfer Fcn : 빠르게 선형 시스템 하나를 붙이고 싶을 때
%      State-Space  : 상태가 여러 개이고 상태를 직접 다뤄야 할 때 (12~14주차)

%% 4. 실험 2 : 초기조건을 주면 무슨 일이 일어나는가
%
%  이번이 이 실습의 핵심입니다.
%
%  힘은 전혀 주지 않고(F = 0), 대신 물체를 0.5 m 당겨 놓고 놓습니다.
%  실제 물리 시스템이라면 당연히 진동하며 돌아올 것입니다.
%
%  그런데 Transfer Fcn 블록에는 초기조건을 넣는 칸이 아예 없습니다.
%  블록을 더블클릭해서 확인해 보십시오.
%
%  왜 없을까요? 전달함수의 정의 자체가 "초기조건 0" 이라는 가정 위에
%  세워져 있기 때문입니다. W02_02 의 7절에서 이야기한 그 한계입니다.

F_amp  = 0;         % 힘을 주지 않는다
x0_pos = 0.5;       % 0.5 m 당겨 놓고
x0_vel = 0;         % 가만히 놓는다

fprintf('=== 실험 2 : F = 0, 초기 위치 %.1f m ===\n', x0_pos);
out2 = sim(model);

yA2 = interp1(out2.y_A.Time, squeeze(out2.y_A.Data), t);
yB2 = interp1(out2.y_B.Time, squeeze(out2.y_B.Data), t);
yC2 = interp1(out2.y_C.Time, squeeze(out2.y_C.Data), t);

fprintf('  경로 A (적분기)     초기값 %.3f m -> 진동하며 수렴\n', yA2(1));
fprintf('  경로 B (전달함수)   초기값 %.3f m -> 처음부터 끝까지 0\n', yB2(1));
fprintf('  경로 C (상태공간)   초기값 %.3f m -> 진동하며 수렴\n', yC2(1));
fprintf('  A 와 C 의 최대 차이 : %.3e m  (둘은 여전히 일치합니다)\n', max(abs(yA2-yC2)));
fprintf('  --> 전달함수만 이 상황을 표현하지 못합니다.\n\n');

figure('Name','실험 2 : 초기조건이 있을 때');
h1 = plot(t, yA2, 'LineWidth', 3); hold on;
h2 = plot(t, yB2, '--', 'LineWidth', 2.5);
h3 = plot(t, yC2, ':', 'LineWidth', 2.5);
yline(0, 'k:'); grid on;
xlabel('Time [s]'); ylabel('x [m]');
title('힘 없이 0.5 m 당겨 놓고 놓았을 때');
legend([h1 h2 h3], {'경로 A (적분기)', '경로 B (Transfer Fcn) - 반응 없음', ...
       '경로 C (State-Space)'}, 'Location','northeast');

%% 5. 정리
%
%  1) 미분방정식, 전달함수, 상태공간은 같은 시스템의 세 가지 표현입니다.
%     초기조건이 0 이면 세 방법의 답이 완전히 일치합니다.
%
%  2) 하지만 완전히 대등하지는 않습니다. 전달함수는 초기조건을 담지 못합니다.
%     입력과 출력의 관계만 담는 표현이기 때문입니다.
%
%  3) 상태공간은 시스템 내부의 상태를 직접 다루므로 초기조건을 자연스럽게
%     표현합니다. 그리고 입력이나 출력이 여러 개여도 똑같은 형태로 씁니다.
%     이 장점 때문에 12~14주차의 현대제어는 전부 상태공간 위에서 진행됩니다.
%
%  4) 그렇다고 전달함수가 열등한 것은 아닙니다. 극점, 영점, 주파수응답,
%     안정여유 같은 직관적인 개념은 전달함수에서만 자연스럽게 나옵니다.
%     6~11주차의 고전제어는 전달함수 위에서 진행됩니다.
%     두 언어를 모두 할 줄 알아야 하는 이유입니다.
%
%% 6. 직접 해 볼 것
%
%   (1) x0_vel = 2 로 바꿔 보십시오. (당기지 않고 속도만 준 경우)
%       -> 위치는 0 에서 시작하지만 곧바로 밀려 나갑니다.
%
%   (2) F_amp = 1 과 x0_pos = 0.5 를 동시에 주면?
%       -> 계단응답과 초기조건 응답이 더해집니다. 선형 시스템의 중첩원리입니다.
%
%   (3) 모델을 열어 Transfer Fcn 블록을 더블클릭해 보십시오.
%       >> open_system('W02_MSD_ThreeWays')
%       초기조건을 넣을 칸이 정말 없는지 눈으로 확인하십시오.
%
%   (4) 경로 A 에서 '댐퍼 b' 게인을 0 으로 만들면?
%       -> 감쇠가 사라져 영원히 진동합니다. W02_02 의 5절에서 본
%          "b=0 이면 극점이 허수축 위" 상황입니다.
