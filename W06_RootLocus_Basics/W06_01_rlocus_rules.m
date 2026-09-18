%% W06_01_rlocus_rules.m
%  6주차 실습 (1) : 근궤적 - 이득을 바꾸면 극점이 어디로 가는가
%
%  5주차에서 K 를 바꿔 가며 roots 로 극점을 추적했습니다.
%  그 그림에 이름이 있습니다. **근궤적(root locus)** 입니다.
%
%  이 스크립트에서 답할 질문
%    Q1. rlocus 명령은 무엇을 그리는가?               -> 2절
%    Q2. 궤적은 어디서 출발해 어디로 가는가?          -> 3절
%    Q3. 몇 개의 가지가 생기는가?                     -> 4절
%    Q4. 극이나 영을 추가하면 궤적이 어떻게 변하는가? -> 5절
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

%% 1. 근궤적이란 무엇인가
%
%  폐루프 특성방정식은 이것입니다.
%
%      1 + K*L(s) = 0        L(s) = 개루프 전달함수 (K 를 뺀 나머지)
%
%  K 를 0 에서 무한대까지 바꾸면 이 방정식의 근이 움직입니다.
%  그 근들이 s 평면에 그리는 자취가 근궤적입니다.
%
%  왜 중요한가
%
%      2주차 : 극점 위치가 응답을 결정한다
%      4주차 : 사양은 s 평면의 영역이 된다
%      6주차 : K 를 바꾸면 극점이 이 길을 따라 움직인다
%
%      -> 궤적이 사양 영역을 지나는 지점을 찾아 그때의 K 를 읽으면
%         그것이 곧 제어기 설계다
%
%  이 세 줄이 앞으로 두 주의 전부입니다.

%% 1-1. 궤적의 뿌리 — 각도 조건과 크기 조건
%
%  이 절이 6주차의 뿌리입니다. 뒤에 나오는 규칙 1~6 이 전부 여기서 나옵니다.
%
%      1 + K*L(s) = 0     ->     L(s) = -1/K
%
%  K 는 양의 실수이므로 -1/K 는 **음의 실수**입니다.
%  어떤 복소수가 음의 실수가 되려면 두 가지가 동시에 성립해야 합니다.
%
%      각도 조건 : ∠L(s) = ±180 도 × (2q+1)   -> 그 점이 궤적 위인가
%      크기 조건 : |L(s)| = 1/K                -> 그때의 K 는 얼마인가
%
%  순서가 중요합니다. 먼저 각도로 걸러 내고, 통과한 점에만 크기를 씁니다.
%
%  세는 법은 자를 대고 재는 것과 같습니다.
%
%      ∠L(s) = (영점에서 온 각의 합) - (극점에서 온 각의 합)
%      K     = (극점까지 거리의 곱) / (영점까지 거리의 곱)
%
%  아래에서 두 시험점을 직접 재 봅니다.

Gsmall = 1/((s+1)*(s+3));
tests  = [-2+2i, -0.5+2i];

fprintf('=== 각도 조건으로 걸러 보기 ===\n');
fprintf('  %-16s %-10s %-10s %-10s %s\n', '시험점', '극점 -1', '극점 -3', '합[도]', '판정');
for st = tests
    a1 = rad2deg(angle(st + 1));
    a2 = rad2deg(angle(st + 3));
    onLocus = abs(a1 + a2 - 180) < 1e-6;
    fprintf('  %-16s %-10.2f %-10.2f %-10.2f %s\n', ...
            sprintf('%.1f%+.1fj', real(st), imag(st)), a1, a2, a1+a2, ...
            string(onLocus));
end

%  각도 조건을 통과한 점에 대해서만 K 를 구합니다.
sd = tests(1);
K_mag = abs(sd + 1) * abs(sd + 3);
fprintf('\n  크기 조건이 준 K = %.4f\n', K_mag);
fprintf('  그 K 의 폐루프 극점 = %s\n', mat2str(round(roots([1 4 3+K_mag]).', 4)));
fprintf('  시험점과 같으면 성공입니다.\n\n');
%% 2. rlocus : 근궤적을 그리는 명령
%
%  새로 나오는 명령입니다.
%
%      rlocus(L)
%
%      하는 일 : 1 + K*L(s) = 0 의 근을 K = 0 부터 무한대까지 추적해 그린다
%      입력    : 개루프 전달함수 L (K 는 빼고 넣습니다)
%      출력    : 출력을 받지 않으면 그림을 그린다
%                [r, k] = rlocus(L) 로 받으면 근과 이득을 숫자로 준다
%
%  주의할 점 두 가지
%
%      (1) L 에 K 를 곱해서 넣으면 안 됩니다.
%          rlocus 가 K 를 알아서 훑기 때문입니다.
%          rlocus(5*G) 라고 쓰면 궤적 모양은 같지만 이득 눈금이 5배 어긋납니다.
%
%      (2) L 은 개루프 전달함수입니다. 폐루프가 아닙니다.
%          feedback 을 쓰지 말고 그냥 G 를 넣으십시오.
%
%  5주차에서 쓴 DC 모터 위치 모델로 그려 봅니다.

[Gp, pp] = plant_dcmotor('position');

figure('Name','근궤적 기본');
rlocus(Gp);
grid on;
title('DC 모터 위치제어의 근궤적');

fprintf('=== 근궤적 기본 ===\n');
fprintf('  개루프 극점 : ');  fprintf('%+.3f ', pole(Gp)); fprintf('\n');
fprintf('  개루프 영점 : ');
if isempty(zero(Gp)), fprintf('없음'); else, fprintf('%+.3f ', zero(Gp)); end
fprintf('\n\n');

%% 2-1. 숫자로 받아 보기
%
%  [r, k] = rlocus(L) 로 받으면 그리지 않고 데이터를 줍니다.
%
%      r : 각 이득에서의 근. 크기는 (극점 개수) x (이득 개수)
%      k : 훑은 이득 값들
%
%  5주차에서 roots 로 직접 만들었던 것과 같은 데이터입니다.
%  rlocus 가 그 작업을 대신 해 주는 것입니다.

[r, k] = rlocus(Gp);
fprintf('=== rlocus 가 준 데이터 ===\n');
fprintf('  근 배열 크기 : %d x %d  (극점 %d 개, 이득 %d 개)\n', ...
        size(r,1), size(r,2), size(r,1), size(r,2));
fprintf('  이득 범위    : %.3f ~ %s\n', min(k), string(max(k)));
fprintf('  마지막 이득이 Inf 인 점에 주의하십시오.\n');
fprintf('  rlocus 는 K 가 무한대로 가는 끝점까지 포함시킵니다.\n\n');

%% 2-2. 주의 : rlocus 의 이득 눈금은 성깁니다
%
%  rlocus 는 그림을 예쁘게 그리는 것이 목적이라 이득을 촘촘히 훑지 않습니다.
%  위에서 보듯 %d 개 남짓만 계산합니다.
%
%  그래서 "궤적이 허수축을 넘는 정확한 이득" 을 rlocus 데이터에서 바로 읽으면
%  실제 값과 어긋납니다. 정확한 값이 필요하면 직접 촘촘히 훑어야 합니다.

kf = k(isfinite(k));
maxRe = max(real(r(:, isfinite(k))), [], 1);
idx = find(maxRe > 0, 1);
fprintf('=== 임계이득 : 성긴 눈금 vs 촘촘한 눈금 ===\n');
if isempty(idx)
    fprintf('  rlocus 눈금에서는 허수축을 넘는 점을 찾지 못했습니다.\n');
else
    fprintf('  rlocus 눈금으로 읽은 값 : K = %.1f  (부정확)\n', kf(idx));
end

% 촘촘히 다시 훑기 (5주차에서 쓴 방법)
[numP, denP] = tfdata(Gp, 'v');
Kfine = linspace(1, 200, 8000);
mre = zeros(size(Kfine));
for i = 1:numel(Kfine)
    mre(i) = max(real(roots(denP + Kfine(i)*[zeros(1,numel(denP)-numel(numP)) numP])));
end
K_crit = Kfine(find(mre > 0, 1));
fprintf('  촘촘히 훑어 구한 값     : K = %.2f  (정확)\n', K_crit);
fprintf('  5주차에서 손으로 구한 값 : K = 120.12\n');
fprintf('  --> 촘촘한 값이 손 계산과 일치합니다.\n');
fprintf('      그림은 rlocus 로 보고, 숫자는 따로 계산하는 습관을 들이십시오.\n\n');

%% 3. 궤적은 어디서 출발해 어디로 가는가
%
%  규칙 1 : 궤적은 개루프 극점에서 출발한다 (K = 0)
%  규칙 2 : 궤적은 개루프 영점에서 끝난다 (K = 무한대)
%
%  왜 그런가 (아주 짧은 유도)
%
%      1 + K*L(s) = 0  ->  L(s) = -1/K
%
%      K -> 0    이면 L(s) -> 무한대  -> L 의 극점
%      K -> 무한 이면 L(s) -> 0       -> L 의 영점
%
%  이게 전부입니다. 외울 것도 없이 식에서 바로 나옵니다.
%
%  그런데 영점이 극점보다 적으면 어떻게 될까요?
%  남는 가지는 무한대로 뻗어 나갑니다. 그 방향을 점근선이라 합니다.

%  주의 : rlocus 로 그린 그림 위에 legend 를 부르면 R2024b 에서 오류가 납니다.
%         Control System Toolbox 의 차트 객체가 범례를 자체 관리하기 때문입니다.
%         설명은 title 이나 text 로 넣으십시오.

figure('Name','출발점과 도착점');
rlocus(Gp); hold on;
plot(real(pole(Gp)), imag(pole(Gp)), 'rx', 'MarkerSize', 14, 'LineWidth', 3);
grid on;
title('궤적은 개루프 극점(빨간 x)에서 출발한다');

fprintf('=== 출발점과 도착점 ===\n');
fprintf('  개루프 극점 %d 개 -> 가지 %d 개가 여기서 출발\n', ...
        numel(pole(Gp)), numel(pole(Gp)));
fprintf('  개루프 영점 %d 개 -> %d 개 가지가 여기로 도착\n', ...
        numel(zero(Gp)), numel(zero(Gp)));
fprintf('  남은 %d 개 가지는 무한대로 뻗어 나갑니다.\n\n', ...
        numel(pole(Gp)) - numel(zero(Gp)));

%% 3-1. 실축 위의 궤적 — 손작도에서 가장 먼저 하는 일
%
%  규칙 : 실축 위의 어떤 점에서, 그 점의 오른쪽에 있는 극점과 영점의
%         개수를 센다. 홀수이면 궤적 위, 짝수(0 포함)이면 아니다.
%
%  왜 그런가 (1-1 절의 각도 조건에서 바로 나옵니다)
%
%      시험점 오른쪽의 실수 극·영 -> 벡터가 왼쪽을 향하므로 각이 180 도
%      시험점 왼쪽의 실수 극·영   -> 벡터가 오른쪽을 향하므로 각이 0 도
%      복소 극·영은 켤레쌍이라 위아래가 상쇄되어 합이 0 도
%
%      -> 각의 합 = (오른쪽 개수) × 180 도
%      -> 180 도의 홀수배가 되려면 오른쪽 개수가 홀수여야 한다

pz_demo = [-1 -3 -5 -2];          % 극점 -1,-3,-5 와 영점 -2
ed = sort(pz_demo);
fprintf('=== 실축 규칙 손으로 세기 ===\n');
fprintf('  %-14s %-12s %s\n', '구간', '오른쪽 개수', '궤적인가');
bounds = [-6.5 ed 0];
for i = 1:numel(bounds)-1
    mid = (bounds(i) + bounds(i+1))/2;
    cnt = sum(pz_demo > mid);
    fprintf('  %-14s %-12d %s\n', ...
            sprintf('%.1f ~ %.1f', bounds(i), bounds(i+1)), cnt, ...
            string(mod(cnt,2)==1));
end

figure('Name','실축 규칙');
rlocus((s+2)/((s+1)*(s+3)*(s+5))); grid on;
xlim([-6.5 1]); ylim([-3 3]);
title('위 표에서 참으로 나온 구간이 실축 위 궤적이다');
fprintf('\n  그림의 실축 부분과 위 표를 대조하십시오.\n\n');

%% 3-2. 이탈점 — 궤적이 실축을 떠나는 자리
%
%      1 + K*L(s) = 0   ->   K = -1/L(s)
%
%  이 K 를 실축 위에서만 그리면 보통의 함수 K(sigma) 가 됩니다.
%  실축 위의 두 가지가 마주 보고 다가와 만나는 자리는 그 함수의 봉우리입니다.
%  그보다 K 가 크면 실축에 해가 없으므로 근이 복소수가 됩니다.
%
%      조건 : dK/dsigma = 0
%
%  예 : L = 1/((s+1)(s+3)) 이면 K(sigma) = -(sigma+1)(sigma+3) 이고
%       dK/dsigma = -(2*sigma+4) = 0 에서 sigma = -2, 그때 K = 1

sg   = linspace(-2.999, -1.001, 4001);
Ksg  = -(sg+1).*(sg+3);
[Kb, ib] = max(Ksg);
r_b  = roots([1 4 3+Kb]);

figure('Name','이탈점');
plot(sg, Ksg, 'LineWidth', 2.5); hold on; grid on;
plot(sg(ib), Kb, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
xlabel('실축 위의 위치 \sigma'); ylabel('그 점을 지나려면 필요한 K');
title(sprintf('봉우리 : sigma = %.2f, K = %.2f', sg(ib), Kb));

fprintf('=== 이탈점 ===\n');
fprintf('  수치로 찾은 값 : sigma = %.4f, K = %.4f\n', sg(ib), Kb);
fprintf('  손계산         : sigma = -2,     K = 1\n');
fprintf('  그 K 의 폐루프 극점 : %s  (중근)\n', mat2str(round(r_b.', 4)));
fprintf('  감쇠비 = %.4f  ->  임계감쇠입니다.\n\n', -real(r_b(1))/abs(r_b(1)));

%% 3-3. 허수축 교차 — 임계 이득을 손으로 구한다
%
%  궤적이 허수축을 지나는 순간의 근은 s = j*w 입니다.
%  그러므로 특성방정식에 s = j*w 를 그대로 대입합니다.
%  복소수 방정식 하나 = 실수 방정식 두 개이므로 K 와 w 를 함께 구할 수 있습니다.
%
%  예 : L = 1/(s(s+1)(s+3))  ->  s^3 + 4s^2 + 3s + K = 0
%
%       s = j*w 를 넣으면   -j*w^3 - 4*w^2 + 3*j*w + K = 0
%
%       허수부 : -w^3 + 3w = 0   ->  w = sqrt(3) = 1.7321
%       실수부 : K - 4*w^2 = 0   ->  K = 12
%
%  5주차에서 라우스 표로 구한 답과 같습니다.

Lj  = 1/(s*(s+1)*(s+3));
w_h = sqrt(3);  K_h = 4*w_h^2;

fprintf('=== 허수축 교차 ===\n');
fprintf('  손계산 : K = %.4f, w = %.4f, 진동 주기 = %.4f s\n', ...
        K_h, w_h, 2*pi/w_h);
fprintf('  K = %.1f  극점 : %s\n', K_h,   mat2str(round(pole(feedback(K_h*Lj,1)).', 4)));
fprintf('  K = 11.5  극점 : %s  (안정)\n',  mat2str(round(pole(feedback(11.5*Lj,1)).', 4)));
fprintf('  K = 12.5  극점 : %s  (불안정)\n', mat2str(round(pole(feedback(12.5*Lj,1)).', 4)));

figure('Name','임계 이득에서의 응답');
tt = 0:0.02:15;
plot(tt, step(feedback(4*Lj,1), tt), 'LineWidth', 2); hold on; grid on;
plot(tt, step(feedback(K_h*Lj,1), tt), 'LineWidth', 2);
plot(tt, step(feedback(16*Lj,1), tt), 'LineWidth', 2);
ylim([-2 4]); xlabel('시간 [s]'); ylabel('출력 y');
legend('K = 4 (안정)', 'K = 12 (임계)', 'K = 16 (불안정)', 'Location','northwest');
title(sprintf('K = 12 에서 진폭이 일정한 진동. 주기 %.2f s', 2*pi/w_h));
fprintf('\n  임계 이득에서 진폭이 일정한 진동이 나옵니다.\n');
fprintf('  그 주기를 재면 w 를 확인할 수 있습니다.\n\n');
%% 4. 가지 개수와 점근선
%
%  규칙 3 : 가지의 개수 = 개루프 극점의 개수
%  규칙 4 : 무한대로 가는 가지의 개수 = (극점 수) - (영점 수) = n - m
%  규칙 5 : 점근선의 각도
%
%      theta = (2*q + 1)*180 / (n - m),   q = 0, 1, 2, ...
%
%  규칙 6 : 점근선이 실축과 만나는 점
%
%      sigma = (극점의 합 - 영점의 합) / (n - m)
%
%  이 공식들을 외울 필요는 없습니다. MATLAB 이 그려 주니까요.
%  다만 **n - m 이 클수록 궤적이 오른쪽으로 휘어진다**는 사실은 알아 두십시오.
%  이것이 5절의 핵심입니다.

n = numel(pole(Gp));
m = numel(zero(Gp));
sigma = (sum(pole(Gp)) - sum(zero(Gp))) / (n - m);
theta = (2*(0:(n-m-1)) + 1) * 180 / (n - m);

fprintf('=== 점근선 ===\n');
fprintf('  극점 수 n = %d, 영점 수 m = %d,  n - m = %d\n', n, m, n-m);
fprintf('  점근선 중심 sigma = %.3f\n', real(sigma));
fprintf('  점근선 각도 : ');  fprintf('%.1f도  ', theta);  fprintf('\n\n');

%% 5. 극이나 영을 추가하면 어떻게 변하는가
%
%  이번 절이 6주차에서 가장 중요합니다.
%  제어기를 설계한다는 것은 결국 **극이나 영을 추가하는 일**이기 때문입니다.
%
%      비례제어(P)  : 아무것도 추가하지 않음. K 만 조절
%      미분제어(D)  : 영점을 추가          -> 궤적을 왼쪽으로 당김
%      적분제어(I)  : 원점에 극점을 추가   -> 궤적을 오른쪽으로 밀어냄
%
%  왜 그런가: n - m 이 바뀌기 때문입니다.
%
%      극을 추가하면 n 이 늘어 n - m 이 커진다 -> 점근선이 오른쪽으로 눕는다
%      영을 추가하면 m 이 늘어 n - m 이 작아진다 -> 점근선이 왼쪽으로 선다
%
%  아래에서 직접 확인합니다. 기준은 간단한 2차 시스템입니다.

G_base = 1/((s+1)*(s+2));

cases = { '기준 : 1/((s+1)(s+2))',        G_base
          '극 추가 : /(s+3)',             G_base/(s+3)
          '극 두 개 추가 : /((s+3)(s+4))', G_base/((s+3)*(s+4))
          '영 추가 : *(s+3)',             G_base*(s+3) };

figure('Name','극과 영을 추가하면');
tiledlayout(2,2,'TileSpacing','compact');
for i = 1:4
    nexttile
    rlocus(cases{i,2});
    grid on; title(cases{i,1});
    xlim([-6 3]); ylim([-4 4]);
end

fprintf('=== 극과 영의 효과 ===\n');
fprintf('  구성                        n-m   점근선 각도\n');
fprintf('  --------------------------  ---  --------------\n');
for i = 1:4
    Gi = cases{i,2};
    ni = numel(pole(Gi)); mi = numel(zero(Gi));
    if ni-mi > 0
        th = (2*(0:(ni-mi-1)) + 1)*180/(ni-mi);
        fprintf('  %-26s  %3d   ', cases{i,1}, ni-mi);
        fprintf('%.0f ', th); fprintf('도\n');
    else
        fprintf('  %-26s  %3d   (무한대로 가는 가지 없음)\n', cases{i,1}, ni-mi);
    end
end
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    n-m = 2 : 점근선이 +-90 도. 궤적이 수직으로 올라간다\n');
fprintf('    n-m = 3 : 점근선이 60, 180, 300 도. 두 가지가 오른쪽으로 휜다\n');
fprintf('              -> 이득을 키우면 불안정해진다\n');
fprintf('    영을 추가하면 n-m 이 줄어 궤적이 왼쪽으로 당겨진다\n');
fprintf('              -> 더 안정해지고 더 빨라진다. 이것이 미분제어의 원리\n\n');

%% 6. 미리 보는 결론 : PD 제어가 왜 좋은가
%
%  5절의 마지막 그림을 다시 보십시오.
%  영점을 추가했더니 궤적이 통째로 왼쪽으로 옮겨갔습니다.
%
%  왼쪽이 좋은 이유는 2주차와 4주차에서 배웠습니다.
%
%      왼쪽 = 실수부가 크게 음수 = 빨리 잦아든다 = 정착시간이 짧다
%
%  그리고 궤적이 허수축에서 멀어졌으므로 불안정해질 걱정도 줄었습니다.
%
%  즉 영점 하나를 추가하는 것만으로
%
%      더 빠르고 + 더 안정한
%
%  시스템을 만들 수 있습니다. 그 영점을 만드는 것이 **미분제어**입니다.
%
%      PD 제어기 : C(s) = Kp + Kd*s = Kd*(s + Kp/Kd)
%
%  괄호 안의 (s + Kp/Kd) 가 바로 추가되는 영점입니다.
%  영점 위치는 Kp/Kd 로 우리가 정할 수 있습니다.
%  7주차에서 이 위치를 어떻게 고르는지 배웁니다.

figure('Name','P 제어 vs PD 제어');
tiledlayout(1,2,'TileSpacing','compact');
nexttile
rlocus(Gp); grid on; xlim([-15 5]); ylim([-10 10]);
title('P 제어 (영점 없음)');
nexttile
rlocus(Gp*(s+3)); grid on; xlim([-15 5]); ylim([-10 10]);
title('PD 제어 (영점 s = -3 추가)');

%  임계이득은 앞에서 배운 대로 촘촘히 훑어 구합니다.
%  (rlocus 의 성긴 눈금으로 읽으면 부정확하고, Inf 이득 때문에 오해하기 쉽습니다)

fprintf('=== P 제어 vs PD 제어 ===\n');
Kfine2 = linspace(0.1, 5000, 20000);

for c = 1:2
    if c == 1, Lc = Gp;         nmc = 'P 제어 (영점 없음)';
    else,      Lc = Gp*(s+3);   nmc = 'PD 제어 (영점 s=-3)'; end
    [nc, dc] = tfdata(Lc, 'v');
    kc = NaN;
    for i = 1:numel(Kfine2)
        if max(real(roots(dc + Kfine2(i)*[zeros(1,numel(dc)-numel(nc)) nc]))) > 0
            kc = Kfine2(i); break
        end
    end
    if isnan(kc)
        fprintf('  %-22s : 훑은 범위(최대 %.0f)에서 불안정해지지 않았습니다\n', ...
                nmc, max(Kfine2));
    else
        fprintf('  %-22s : K = %.1f 에서 불안정해집니다\n', nmc, kc);
    end
end
fprintf('  --> 영점 하나로 안정 범위가 크게 넓어졌습니다.\n\n');

%% 7. 이번 실습의 정리
%
%  1) 근궤적은 1 + K*L(s) = 0 의 근이 K 에 따라 움직이는 자취다.
%
%  2) rlocus(L) 로 그린다. L 은 개루프이고 K 는 빼고 넣는다.
%     [r,k] = rlocus(L) 로 숫자를 받을 수도 있다.
%
%  3) 궤적은 개루프 극점에서 출발해 개루프 영점에서 끝난다.
%     남는 가지는 점근선을 따라 무한대로 간다.
%
%  4) 가지 개수 = 극점 개수. 무한대로 가는 가지 = n - m.
%     n - m 이 클수록 궤적이 오른쪽으로 휘어 불안정해지기 쉽다.
%
%  5) 극을 추가하면 오른쪽으로, 영을 추가하면 왼쪽으로 궤적이 움직인다.
%     이것이 각각 적분제어와 미분제어의 효과다.
%
%  다음 실습 : W06_02_design_by_rlocus.m
%              4주차의 사양 영역을 근궤적 위에 겹쳐 이득을 고릅니다.
%              여기서 드디어 "설계" 를 하게 됩니다.
