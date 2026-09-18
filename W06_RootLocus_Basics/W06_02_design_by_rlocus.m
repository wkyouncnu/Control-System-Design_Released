%% W06_02_design_by_rlocus.m
%  6주차 실습 (2) : 근궤적으로 이득 고르기 - 드디어 설계
%
%  여기서 두 주 동안 준비한 것이 하나로 합쳐집니다.
%
%      4주차 : 사양 -> s 평면의 영역
%      6주차 : K 를 바꾸면 극점이 궤적을 따라 움직인다
%      -> 궤적이 영역을 지나는 지점의 K 를 읽으면 그것이 설계다
%
%  이 스크립트에서 답할 질문
%    Q1. 사양 영역을 근궤적 위에 어떻게 그리는가?  -> 2절
%    Q2. 원하는 지점의 K 를 어떻게 읽는가?         -> 3절
%    Q3. 고른 K 가 정말 사양을 만족하는가?         -> 4절
%    Q4. 만족하지 못하면 어떻게 하는가?            -> 5절
%
%  대응하는 강의노트 : W06_LectureNote.mlx
%  대응하는 Simulink : W06_Rlocus_Verify.slx
%
%  제어시스템설계 6주차 | 충남대학교 자율운항시스템공학과

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

%% 1. 설계 문제
%
%  플랜트는 5주차에서 쓴 DC 모터 위치제어입니다.
%
%  요구사항
%      오버슈트 20 % 이하
%      정착시간 2 초 이하
%
%  할 일
%      비례이득 K 를 골라 이 사양을 만족시켜라.
%      만족할 수 없다면 그 이유를 밝혀라.

[G, p] = plant_dcmotor('position');

P_OS = 20;      % 허용 오버슈트 [%]
ts   = 2;       % 허용 정착시간 [s]

[zeta_min, wn_min, s_target] = spec2pole(P_OS, ts);

fprintf('=== 설계 문제 ===\n');
fprintf('  플랜트 극점 : ');  fprintf('%+.3f ', pole(G)); fprintf('\n');
fprintf('  요구 : 오버슈트 %.0f %% 이하, 정착시간 %.1f s 이하\n', P_OS, ts);
fprintf('  필요 : zeta >= %.4f, wn >= %.3f rad/s\n', zeta_min, wn_min);
fprintf('  목표 극점 : %.3f +- %.3fj\n\n', real(s_target), imag(s_target));

%% 2. sgrid : 사양 영역을 근궤적 위에 그리기
%
%  새로 나오는 명령입니다.
%
%      sgrid(zeta, wn)
%
%      하는 일 : s 평면에 등감쇠비 직선과 등고유진동수 원을 그린다
%      입력    : zeta 는 감쇠비(들), wn 은 고유진동수(들). 벡터로 여러 개 가능
%      출력    : 없음. 현재 그림 위에 격자를 덧그린다
%
%  쓰는 법 세 가지
%
%      sgrid              : 기본 격자를 촘촘히 그린다
%      sgrid(zeta, wn)    : 지정한 값에만 선을 그린다  <- 설계할 때 이렇게 씁니다
%      sgrid([], wn)      : 원만 그린다 (감쇠비 선은 생략)
%      sgrid(zeta, [])    : 직선만 그린다
%
%  주의
%      sgrid 는 반드시 rlocus 를 그린 **다음에** 불러야 합니다.
%      먼저 부르면 rlocus 가 축을 다시 잡으면서 격자가 지워질 수 있습니다.
%
%  4주차와의 대응
%      등감쇠비 직선 = 오버슈트 조건 (부채꼴 경계)
%      등고유진동수 원 = 정착시간 조건 (4주차에서는 수직선이었지만
%                       sgrid 는 원으로 그립니다. 원이 더 보수적입니다)

figure('Name','근궤적 + 사양 영역');
rlocus(G); hold on;
sgrid(zeta_min, wn_min);
axis([-14 2 -8 8]);
title(sprintf('근궤적과 사양 영역 (\\zeta \\geq %.3f, \\omega_n \\geq %.2f)', ...
      zeta_min, wn_min));

fprintf('=== sgrid 로 그린 사양 경계 ===\n');
fprintf('  등감쇠비 직선 : 실축과 %.1f 도. 이 안쪽이어야 오버슈트 조건 만족\n', ...
        rad2deg(acos(zeta_min)));
fprintf('  등고유진동수 원 : 반지름 %.3f. 이 바깥이어야 정착시간 조건 만족\n\n', wn_min);

%% 3. rlocfind : 원하는 지점의 이득 읽기
%
%  새로 나오는 명령입니다.
%
%      [k, poles] = rlocfind(L)         마우스로 클릭해 고른다 (수업 중에 사용)
%      [k, poles] = rlocfind(L, p)      점 p 를 지정한다 (스크립트에서 사용)
%
%      하는 일 : 궤적 위에서 지정한 점에 가장 가까운 곳의 이득을 찾는다
%      입력    : L 은 개루프 전달함수, p 는 s 평면의 점 (복소수)
%      출력    : k 는 그 지점의 이득, poles 는 그때의 폐루프 극점 전부
%
%  주의 두 가지
%
%      (1) 지정한 점이 궤적 위에 없으면 가장 가까운 점을 찾아 줍니다.
%          그래서 나온 극점이 원하던 위치와 다를 수 있습니다. 반드시 확인하십시오.
%
%      (2) 반환된 poles 는 **폐루프 극점 전부**입니다.
%          우리가 관심 있는 것은 보통 지배극점(원점에 가장 가까운 쌍)입니다.
%
%  수업 중에는 인자 없이 불러 마우스로 클릭해 보십시오.
%  스크립트에서는 점을 지정합니다.

% 목표 극점 근처에서 이득을 찾습니다
[K_design, cl_poles] = rlocfind(G, s_target);

fprintf('=== rlocfind 로 이득 읽기 ===\n');
fprintf('  지정한 점   : %.3f + %.3fj\n', real(s_target), imag(s_target));
fprintf('  찾은 이득 K : %.3f\n', K_design);
fprintf('  그때의 폐루프 극점 :\n');
for i = 1:numel(cl_poles)
    fprintf('      %+.4f %+.4fj\n', real(cl_poles(i)), imag(cl_poles(i)));
end
fprintf('\n');

%% 4. 고른 이득이 사양을 만족하는가
%
%  근궤적으로 고른 K 를 실제 응답으로 검증합니다.
%  이 단계를 절대 건너뛰지 마십시오.
%
%  이유는 4주차에서 배웠습니다.
%      사양 공식은 "극점 두 개, 영점 없음" 가정에서 나온 2차 근사입니다.
%      이 플랜트는 극점이 셋이므로 어긋날 수 있습니다.

T = feedback(K_design*G, 1);
info = stepinfo(T);

fprintf('=== 검증 ===\n');
fprintf('  오버슈트 : %.2f %%   (요구 %.0f %% 이하)\n', info.Overshoot, P_OS);
fprintf('  정착시간 : %.3f s    (요구 %.1f s 이하)\n', info.SettlingTime, ts);
if info.Overshoot <= P_OS && info.SettlingTime <= ts
    fprintf('  --> 사양 만족\n\n');
else
    fprintf('  --> 사양 불만족. 5절에서 원인을 봅니다.\n\n');
end

t = 0:0.005:4;
figure('Name','설계 결과 검증');
plot(t, step(T, t), 'LineWidth', 2); hold on;
yline(1, 'k--', 'LineWidth', 1.5);
yline(1+P_OS/100, 'r:', 'LineWidth', 1.5);
xline(ts, 'r:', 'LineWidth', 1.5);
grid on; xlabel('시간 [s]'); ylabel('각도 [rad]');
title(sprintf('K = %.2f 일 때의 응답', K_design));

%% 5. 왜 어긋나는가 : 궤적이 사양 영역을 지나지 않는다
%
%  가장 먼저 확인할 것은 rlocfind 가 **정말 우리가 원한 지점을 찾았는가** 입니다.
%
%  rlocfind 는 지정한 점이 궤적 위에 없으면 **가장 가까운 궤적 위의 점**을
%  찾아 줍니다. 그래서 목표와 전혀 다른 곳이 나올 수 있습니다.
%  이때 나온 이득을 그대로 쓰면 당연히 사양을 만족하지 못합니다.

[~, idx] = sort(abs(real(cl_poles)));
dom = cl_poles(idx(1:2));
oth = cl_poles(idx(3:end));

fprintf('=== 진단 1 : rlocfind 가 목표점을 찾았는가 ===\n');
fprintf('  원한 지점   : %+.3f %+.3fj\n', real(s_target), imag(s_target));
fprintf('  실제 찾은 점 : %+.3f %+.3fj\n', real(dom(1)), imag(dom(1)));
gap = abs(dom(1) - s_target);
fprintf('  두 점 사이 거리 : %.3f\n', gap);
if gap > 0.5
    fprintf('  --> 크게 어긋났습니다. **궤적이 목표점 근처를 지나지 않는다**는 뜻입니다.\n');
    fprintf('      이것이 사양을 만족하지 못한 진짜 이유입니다.\n\n');
else
    fprintf('  --> 목표점을 제대로 찾았습니다.\n\n');
end

%% 5-1. 진단 2 : 세 번째 극점은 문제인가
%
%  극점이 셋이므로 2차 근사가 어긋날 수도 있습니다. 따로 확인합니다.
%
%  4주차의 경험칙
%      다른 극점이 지배극점보다 5배 이상 왼쪽에 있으면 무시해도 된다

fprintf('=== 진단 2 : 세 번째 극점 ===\n');
fprintf('  지배극점 : %+.4f %+.4fj\n', real(dom(1)), imag(dom(1)));
fprintf('  나머지   : %+.4f\n', real(oth(1)));
fprintf('  배율     : %.1f 배\n', abs(real(oth(1)))/abs(real(dom(1))));
if abs(real(oth(1)))/abs(real(dom(1))) >= 5
    fprintf('  --> 5배 이상이므로 세 번째 극점은 문제가 아닙니다.\n');
    fprintf('      즉 이번 실패의 원인은 진단 1 쪽입니다.\n\n');
else
    fprintf('  --> 5배가 안 되므로 2차 근사도 어긋납니다.\n\n');
end

%% 5-2. 궤적이 어디까지 갈 수 있는가
%
%  근궤적은 K 로 정해지는 **정해진 길**입니다.
%  그 길 위에만 극점을 놓을 수 있습니다.
%
%  이 시스템의 궤적을 보면
%
%      원점 극점과 s = -2 극점이 서로 다가와 만난 뒤
%      복소수가 되어 **위로 곧장 올라갑니다**
%
%  올라가는 동안 실수부가 거의 변하지 않습니다.
%  즉 아무리 K 를 키워도 **극점을 왼쪽으로 보낼 수가 없습니다.**
%  정착시간은 실수부가 정하므로, 정착시간 사양을 만족할 방법이 없는 것입니다.
%
%  아래에서 궤적 위 극점들의 실수부 범위를 확인합니다.

[rr, kk] = rlocus(G);
fin = isfinite(kk);
reDom = max(real(rr(:,fin)), [], 1);        % 각 이득에서 가장 오른쪽 극점
fprintf('=== 궤적이 도달할 수 있는 실수부 ===\n');
fprintf('  안정 구간에서 지배극점 실수부의 최댓값 : %+.3f\n', max(reDom(reDom<0)));
fprintf('  정착시간 %.0f s 를 만족하려면 실수부가 %+.3f 보다 왼쪽이어야 합니다.\n', ...
        ts, -4/ts);
fprintf('  --> 궤적이 거기까지 가지 못합니다. 비례제어로는 불가능합니다.\n\n');

%% 6. 이득을 직접 훑어 최적점 찾기
%
%  근궤적으로 대략을 잡고, 이득을 촘촘히 훑어 실제로 사양을 만족하는
%  범위를 찾는 것이 실무 방식입니다.
%
%  아래에서 K 를 훑으며 오버슈트와 정착시간을 계산해
%  사양을 만족하는 구간을 찾습니다.

K_scan = linspace(1, 120, 300);
os = zeros(size(K_scan));  tset = zeros(size(K_scan));
for i = 1:numel(K_scan)
    ii = stepinfo(feedback(K_scan(i)*G, 1));
    os(i)   = ii.Overshoot;
    tset(i) = ii.SettlingTime;
end

ok = (os <= P_OS) & (tset <= ts);

figure('Name','이득 스윕');
tiledlayout(2,1,'TileSpacing','compact');
nexttile
plot(K_scan, os, 'LineWidth', 2); hold on;
yline(P_OS, 'r--', 'LineWidth', 1.5); grid on;
ylabel('오버슈트 [%]'); title('이득에 따른 성능');
ylim([0 100]);
nexttile
plot(K_scan, tset, 'LineWidth', 2); hold on;
yline(ts, 'r--', 'LineWidth', 1.5); grid on;
xlabel('비례이득 K'); ylabel('정착시간 [s]');
ylim([0 10]);

fprintf('=== 이득 스윕 결과 ===\n');
if any(ok)
    fprintf('  사양을 만족하는 K 범위 : %.1f ~ %.1f\n', ...
            K_scan(find(ok,1)), K_scan(find(ok,1,'last')));
    Kbest = K_scan(find(ok,1,'last'));
    ib = stepinfo(feedback(Kbest*G,1));
    fprintf('  그중 가장 큰 K = %.1f 을 고르면\n', Kbest);
    fprintf('    오버슈트 %.2f %%, 정착시간 %.3f s\n', ib.Overshoot, ib.SettlingTime);
    fprintf('  왜 큰 쪽을 고르는가: 이득이 클수록 외란 억제가 좋기 때문입니다 (1주차)\n\n');
else
    fprintf('  이 범위에서 사양을 만족하는 K 가 없습니다.\n');
    fprintf('  비례제어만으로는 이 사양을 만족할 수 없다는 뜻입니다.\n');
    fprintf('  -> 7주차에서 PD 나 Lead 보상기로 해결합니다.\n\n');
    Kbest = K_design;
end

%% 7. 제어입력도 확인할 것
%
%  응답만 보고 만족하면 안 됩니다. 제어입력이 실현 가능한지 봐야 합니다.
%
%  목표값에서 제어입력까지의 전달함수는 이렇습니다.
%
%      U(s)/R(s) = K / (1 + K*G(s))
%
%  MATLAB 에서는 feedback(K, G) 로 만듭니다.
%  왜 이 식인지 3주차 블록선도 규칙으로 확인해 보십시오.

Tu = feedback(Kbest, G);
u_max = max(abs(step(Tu, t)));

fprintf('=== 제어입력 확인 ===\n');
fprintf('  K = %.1f 일 때 최대 제어입력 = %.1f V\n', Kbest, u_max);
fprintf('  실제 모터 구동기는 보통 12~48 V 입니다.\n');
if u_max > 48
    fprintf('  --> 이 설계는 구동기 한계를 넘습니다. 이득을 줄여야 합니다.\n\n');
else
    fprintf('  --> 실현 가능한 범위입니다.\n\n');
end

figure('Name','제어입력');
plot(t, step(Tu, t), 'LineWidth', 2); hold on;
yline(48, 'r--', 'LineWidth', 1.5);
yline(-48, 'r--', 'LineWidth', 1.5);
grid on; xlabel('시간 [s]'); ylabel('제어입력 u [V]');
title(sprintf('K = %.1f 일 때의 제어입력 (빨간선 = 48 V 한계)', Kbest));

%% 8. 이번 실습의 정리
%
%  설계 절차 (앞으로 계속 씁니다)
%
%      1) 사양을 zeta, wn 으로 바꾼다              (spec2pole)
%      2) 근궤적을 그린다                          (rlocus)
%      3) 사양 영역을 겹쳐 그린다                  (sgrid)
%      4) 궤적이 영역을 지나는 지점의 이득을 읽는다 (rlocfind)
%      5) stepinfo 로 실제 성능을 확인한다          <- 절대 생략 금지
%      6) 제어입력이 실현 가능한지 확인한다         <- 자주 잊는 단계
%
%  주의할 점
%
%      rlocus 의 이득 눈금은 성기다. 정확한 값은 따로 계산할 것
%      rlocus 그림 위에 legend 를 부르면 오류가 난다. title 이나 text 를 쓸 것
%      sgrid 는 rlocus 다음에 부를 것
%      사양 공식은 2차 근사다. 세 번째 극점이 가까우면 어긋난다
%
%  비례제어의 한계
%
%      근궤적은 K 로 정해지는 길이다. 그 길 위에만 극점을 놓을 수 있다.
%      길이 사양 영역을 지나지 않으면 비례제어로는 방법이 없다.
%      그때는 길 자체를 바꿔야 하고, 그것이 극이나 영을 추가하는 일이다.
%      -> 7주차 PD, PI, Lead, Lag 보상기
%
%  다음 실습 : W06_03_run_simulink.m
%              고른 이득을 Simulink 에서 확인하고, 포화가 있으면
%              어떻게 달라지는지 봅니다.
