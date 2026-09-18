%% W05_01_stability.m
%  5주차 실습 (1) : 안정도 - 이득을 얼마까지 키울 수 있는가
%
%  1주차에서 "K 를 무한히 키우면 안 된다" 고만 하고 넘어갔습니다.
%  오늘 그 정확한 답을 구합니다.
%
%  이 스크립트에서 답할 질문
%    Q1. 안정하다는 것은 정확히 무슨 뜻인가?          -> 1절
%    Q2. K 를 키우면 극점이 어디로 가는가?            -> 3절
%    Q3. 불안정해지는 K 값을 어떻게 찾는가?           -> 4절
%    Q4. 손으로도 구할 수 있는가?                     -> 5절
%
%  대응하는 강의노트 : W05_LectureNote.mlx
%  대응하는 Simulink : W05_SteadyStateError.slx
%
%  제어시스템설계 5주차 | 충남대학교 자율운항시스템공학과

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

%% 1. 안정하다는 것은 무슨 뜻인가
%
%  정의는 2주차에서 이미 배웠습니다.
%
%      극점이 전부 좌반면에 있으면 안정, 하나라도 우반면에 있으면 불안정
%
%  왜 그런지도 배웠습니다. 극점 p 는 응답에 exp(p*t) 항을 만들고,
%  p 의 실수부가 양수면 이 항이 무한히 커지기 때문입니다.
%
%  오늘 새로 다루는 것은 이것입니다.
%
%      제어이득 K 를 바꾸면 폐루프 극점이 움직인다.
%      그러다가 어느 순간 우반면으로 넘어간다. 그 K 는 얼마인가?
%
%  이 질문에 답하는 것이 오늘의 목표입니다.

%% 2. 오늘의 플랜트 : DC 모터 위치제어
%
%  5주차부터는 DC 모터를 씁니다. 속도 모델과 위치 모델 두 가지가 있는데
%  오늘은 둘 다 쓰면서 차이를 봅니다.
%
%  속도 모델 : 입력 전압 -> 출력 각속도
%  위치 모델 : 입력 전압 -> 출력 각도 (속도 모델을 s 로 한 번 더 나눈 것)
%
%  왜 위치 모델이 중요한가
%      원점에 극점(적분기)이 하나 더 생깁니다.
%      이 적분기가 정상상태 오차를 없애 주지만 (다음 실습에서 다룸)
%      동시에 시스템을 불안정하게 만들기 쉽습니다.
%
%  실제로 속도 모델은 K 를 아무리 키워도 불안정해지지 않지만,
%  위치 모델은 어느 값을 넘으면 불안정해집니다. 아래에서 확인합니다.

[Gs, ps] = plant_dcmotor('speed');
[Gp, pp] = plant_dcmotor('position');

fprintf('=== 두 모델 비교 ===\n');
fprintf('  속도 모델 G(s) : 극점 ');
fprintf('%.3f  ', pole(Gs)); fprintf('  (차수 %d)\n', order(Gs));
fprintf('  위치 모델 G(s) : 극점 ');
fprintf('%.3f  ', pole(Gp)); fprintf('  (차수 %d)\n', order(Gp));
fprintf('  --> 위치 모델에는 원점 극점(적분기)이 하나 더 있습니다.\n\n');

%% 3. K 를 키우면 극점이 어디로 가는가
%
%  폐루프 특성방정식은 이렇습니다.
%
%      1 + K*G(s) = 0
%
%  이것을 분모를 없애 정리하면 K 가 들어간 다항식이 됩니다.
%  K 를 조금씩 바꾸며 roots 로 근을 구하면 극점이 움직이는 길이 보입니다.
%
%  쓰는 명령 : roots
%
%      입력 : 다항식 계수 벡터 (높은 차수부터)
%      출력 : 근을 담은 열벡터
%
%  주의 : roots 는 전달함수가 아니라 계수 벡터를 받습니다.
%         전달함수에서 계수를 꺼내려면 tfdata(G, 'v') 를 씁니다.

% 위치 모델의 분자와 분모 계수
[numP, denP] = tfdata(Gp, 'v');

K_sweep = linspace(0, 300, 600);
nRoot = numel(denP) - 1;
R = zeros(nRoot, numel(K_sweep));

for i = 1:numel(K_sweep)
    % 특성방정식 : denP + K*numP = 0
    coef = denP + K_sweep(i)*[zeros(1, numel(denP)-numel(numP)) numP];
    R(:,i) = roots(coef);
end

figure('Name','K 에 따른 폐루프 극점의 이동');
for j = 1:nRoot
    plot(real(R(j,:)), imag(R(j,:)), '.', 'MarkerSize', 6); hold on;
end
xline(0, 'k-', 'LineWidth', 2);
yline(0, 'k:');
grid on;
xlabel('Real'); ylabel('Imag');
title('DC 모터 위치제어 : K 를 0 에서 300 까지 키울 때');
xlim([-15 5]); ylim([-8 8]);

fprintf('=== 극점의 이동 ===\n');
for Kx = [10 50 120 200]
    coef = denP + Kx*[zeros(1, numel(denP)-numel(numP)) numP];
    r = roots(coef);
    fprintf('  K = %3d : 최대 실수부 %+.4f  -> %s\n', Kx, max(real(r)), ...
            ternary(max(real(r)) < 0, '안정', '불안정'));
end
fprintf('\n');

%% 4. 불안정해지는 K 를 찾기
%
%  K 를 조금씩 키우면서 최대 실수부가 0 을 넘는 순간을 찾습니다.
%  이 K 를 임계이득(critical gain)이라고 합니다.

K_fine = linspace(1, 200, 4000);
maxRe = zeros(size(K_fine));
for i = 1:numel(K_fine)
    coef = denP + K_fine(i)*[zeros(1, numel(denP)-numel(numP)) numP];
    maxRe(i) = max(real(roots(coef)));
end

idx = find(maxRe > 0, 1);
K_crit = K_fine(idx);

figure('Name','임계이득 찾기');
plot(K_fine, maxRe, 'LineWidth', 2); hold on;
yline(0, 'r--', 'LineWidth', 2);
xline(K_crit, 'k:', 'LineWidth', 2);
grid on;
xlabel('비례이득 K'); ylabel('폐루프 극점의 최대 실수부');
title(sprintf('실수부가 0 을 넘는 지점 : K = %.1f', K_crit));
legend('최대 실수부', '안정 경계', sprintf('K_{crit} = %.1f', K_crit), ...
       'Location','northwest');

fprintf('=== 임계이득 ===\n');
fprintf('  수치로 찾은 K_crit = %.2f\n', K_crit);
fprintf('  이보다 작으면 안정, 크면 불안정합니다.\n\n');

%% 5. 손으로 구하기 : Routh 판별법의 핵심만
%
%  수치로 찾을 수도 있지만 손으로 구하면 K 가 어디에 들어가는지 보입니다.
%  3차 다항식에 대해서는 아주 간단한 조건이 있습니다.
%
%      a3*s^3 + a2*s^2 + a1*s + a0 = 0 이 안정할 조건
%
%          (1) 모든 계수가 같은 부호이고 0 이 아니다
%          (2) a2*a1 > a3*a0
%
%  (1) 은 필요조건일 뿐이고, (2) 가 3차에서의 핵심 조건입니다.
%  이 조건은 Routh 표를 만들면 자연스럽게 나옵니다.
%
%  우리 시스템에 적용해 봅시다.

fprintf('=== 손 계산 ===\n');
fprintf('  위치 모델 분모 계수 : ');
fprintf('%.6f  ', denP); fprintf('\n');
fprintf('  분자 계수           : ');
fprintf('%.6f  ', numP); fprintf('\n\n');

a3 = denP(1);  a2 = denP(2);  a1 = denP(3);
b0 = numP(end);          % 분자의 상수항

fprintf('  특성방정식 : %.6f*s^3 + %.4f*s^2 + %.4f*s + %.4f*K = 0\n', a3, a2, a1, b0);
fprintf('  조건 (2) : a2*a1 > a3*(b0*K)\n');
fprintf('             %.4f * %.4f > %.6f * %.4f * K\n', a2, a1, a3, b0);
K_hand = (a2*a1) / (a3*b0);
fprintf('             K < %.2f\n', K_hand);
fprintf('  수치로 찾은 값 %.2f 와 일치합니다.\n\n', K_crit);

%% 6. 세 가지 K 로 직접 확인
%
%  임계이득 아래, 근처, 위에서 각각 계단응답을 그려 봅니다.

K_test = [K_crit*0.5, K_crit*0.98, K_crit*1.1];
labels = {'안정 (K_{crit} 의 절반)', '경계 근처 (98 %)', '불안정 (110 %)'};
t = 0:0.005:3;

figure('Name','안정 / 경계 / 불안정');
tiledlayout(3,1,'TileSpacing','compact');
for i = 1:3
    T = feedback(K_test(i)*Gp, 1);
    nexttile
    plot(t, step(T, t), 'LineWidth', 2); grid on;
    ylabel('각도 [rad]');
    title(sprintf('%s : K = %.1f, 최대 실수부 %+.4f', ...
          labels{i}, K_test(i), max(real(pole(T)))));
    if i == 3, xlabel('시간 [s]'); end
end

fprintf('=== 세 경우의 응답 ===\n');
for i = 1:3
    T = feedback(K_test(i)*Gp, 1);
    fprintf('  K = %6.1f : 최대 실수부 %+.4f  -> %s\n', ...
            K_test(i), max(real(pole(T))), ...
            ternary(max(real(pole(T))) < 0, '수렴', '발산'));
end
fprintf('\n');

%% 7. 속도 모델은 왜 불안정해지지 않는가
%
%  같은 실험을 속도 모델로 해 보면 결과가 다릅니다.
%  K 를 아무리 키워도 극점이 좌반면을 벗어나지 않습니다.
%
%  이유는 차수입니다.
%
%      속도 모델 : 2차 -> 특성방정식이 2차 -> 계수가 모두 양수면 항상 안정
%      위치 모델 : 3차 -> 3차부터는 계수가 양수여도 불안정할 수 있음
%
%  2차 시스템이 안정할 조건은 "모든 계수가 양수" 뿐입니다.
%  K 를 키워도 상수항만 커지므로 계수 부호가 바뀌지 않습니다.
%
%  즉 적분기 하나가 추가되면서 시스템이 훨씬 까다로워진 것입니다.

[numS, denS] = tfdata(Gs, 'v');
fprintf('=== 속도 모델 (2차) ===\n');
for Kx = [10 100 1000 10000]
    coef = denS + Kx*[zeros(1, numel(denS)-numel(numS)) numS];
    r = roots(coef);
    fprintf('  K = %6d : 최대 실수부 %+.4f  -> %s\n', Kx, max(real(r)), ...
            ternary(max(real(r)) < 0, '안정', '불안정'));
end
fprintf('  --> 아무리 키워도 안정합니다. 2차 시스템이기 때문입니다.\n\n');

%% 8. 이번 실습의 정리
%
%  1) 안정하다 = 폐루프 극점이 전부 좌반면에 있다.
%
%  2) K 를 키우면 폐루프 극점이 움직인다. 그 길을 그린 것이
%     다음 주에 배울 근궤적이다.
%
%  3) 임계이득 K_crit 을 넘으면 불안정해진다.
%     수치로도(roots 반복) 손으로도(3차 조건) 구할 수 있다.
%
%  4) 3차 조건 a2*a1 > a3*a0 은 Routh 표에서 나온다.
%     4차 이상은 표를 만들어야 하지만, 실무에서는 roots 나
%     10주차에서 배울 안정여유를 쓴다.
%
%  5) 적분기가 하나 더 있으면(위치 모델) 불안정해지기 쉽다.
%     정상상태 오차는 좋아지지만 안정도는 나빠진다.
%     이 맞바꿈이 다음 실습의 주제다.
%
%  다음 실습 : W05_02_steady_state_error.m
%              오차가 왜 남는지, 적분기가 왜 오차를 없애는지 다룹니다.

%% 보조 함수
function out = ternary(cond, a, b)
%TERNARY  조건에 따라 두 값 중 하나를 고릅니다. (표 출력용 도우미)
if cond, out = a; else, out = b; end
end
