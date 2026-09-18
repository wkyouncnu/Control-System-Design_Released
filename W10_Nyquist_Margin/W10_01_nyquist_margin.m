%% W10_01_nyquist_margin.m
%  10주차 실습 (1) : 나이퀴스트 선도와 안정 여유
%
%  이 스크립트에서 답할 질문
%    Q1. 폐루프는 언제 불안정해지는가?            -> 1절
%    Q2. 나이퀴스트 선도는 무엇을 그린 것인가?    -> 2절
%    Q3. 이득여유와 위상여유를 어디서 읽는가?     -> 3절
%    Q4. 여유가 얼마면 충분한가?                  -> 4절
%    Q5. 개루프가 불안정하면 어떻게 되는가?       -> 5절
%
%  대응하는 강의노트 : W10_LectureNote.mlx
%  대응하는 Simulink : W10_Margin_Check.slx
%
%  제어시스템설계 10주차 | 충남대학교 자율운항시스템공학과

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

%% 1. 폐루프는 언제 불안정해지는가
%
%  단위 피드백 폐루프는 이렇습니다.
%
%      T(s) = L(s) / (1 + L(s))
%
%  분모가 0 이 되는 s 가 폐루프 극점입니다. 즉
%
%      1 + L(s) = 0    <=>    L(s) = -1
%
%  이것을 주파수축(s = jw)에서 보면 이렇게 읽힙니다.
%
%      어떤 주파수에서 개루프의 크기가 1 이고 위상이 -180도이면
%      그 주파수의 진동이 스스로 유지된다. 즉 폐루프가 불안정 경계다.
%
%  왜 그런가 — 위상이 -180도라는 것은 되먹임되는 신호가 뒤집혀 온다는 뜻입니다.
%  피드백에서 한 번 더 빼면 결국 더해지는 셈이 됩니다.
%  거기에 크기까지 1 이면 줄지도 늘지도 않고 계속 돕니다.

G = 1/(s*(s+1)^2);        % 강의자료 6장의 표준 예제

fprintf('=== 오늘의 개루프 ===\n');
G
fprintf('  극점 : %s\n', mat2str(round(pole(G).',4)));
fprintf('  타입 1 (원점에 극점 하나) 이므로 계단 오차는 0 입니다.\n\n');

Kv = [0.5 2 3];
fprintf('=== K 를 키우면 ===\n');
fprintf('     K    폐루프 극점 실수부 최댓값   안정?\n');
fprintf('   -----  ------------------------  --------\n');
for K = Kv
    T = feedback(K*G, 1);
    mx = max(real(pole(T)));
    if mx < 0, st = '안정'; elseif abs(mx) < 1e-6, st = '경계'; else, st = '불안정'; end
    fprintf('   %5.1f  %24.4f  %8s\n', K, mx, st);
end
fprintf('\n');

%% 2. 나이퀴스트 선도
%
%  보드 선도는 크기와 위상을 **따로** 그렸습니다.
%  나이퀴스트 선도는 둘을 **한 평면에** 그립니다.
%
%  주파수 w 를 훑으면서 복소수 L(jw) 를 복소평면에 찍는 것입니다.
%  그러면 "L = -1 이 되는가" 를 눈으로 볼 수 있습니다.
%
%  MATLAB 의 nyquist 를 써도 되지만, 여기서는 직접 그려 봅니다.
%  freqresp 로 복소수를 얻어 실수부와 허수부를 그리면 그것이 나이퀴스트 선도입니다.

w = logspace(-2, 2, 4000);

figure('Name','나이퀴스트 선도', 'Position',[80 80 900 420]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile; hold on; grid on; axis equal;
for K = Kv
    fr = squeeze(freqresp(K*G, w));
    plot(real(fr), imag(fr), 'LineWidth', 2, 'DisplayName', sprintf('K = %.1f', K));
    plot(real(fr), -imag(fr), '--', 'LineWidth', 1, 'HandleVisibility','off');
end
plot(-1, 0, 'p', 'MarkerSize', 16, 'MarkerFaceColor',[0.85 0.25 0.15], ...
     'MarkerEdgeColor','k', 'DisplayName','-1 점');
xline(0,'k-','HandleVisibility','off'); yline(0,'k-','HandleVisibility','off');
xlim([-3.2 0.6]); ylim([-1.8 1.8]);
xlabel('실수부'); ylabel('허수부'); legend('Location','northwest');
title('K = 2 에서 -1 점을 정확히 지난다');

nexttile; hold on; grid on;
t = (0:0.05:40)';
for K = Kv
    T = feedback(K*G, 1);
    if max(real(pole(T))) < 0.02
        plot(t, step(T, t), 'LineWidth', 2, 'DisplayName', sprintf('K = %.1f', K));
    end
end
yline(1,'k--','HandleVisibility','off');
ylim([-0.5 2.5]); xlabel('시간 [s]'); ylabel('출력');
legend('Location','northeast'); title('그래서 K = 2 는 지속진동');

fprintf('=== 나이퀴스트 선도가 -1 점에 얼마나 가까운가 ===\n');
fprintf('     K    -1 점까지의 최단거리   폐루프\n');
fprintf('   -----  --------------------  --------\n');
for K = Kv
    fr = squeeze(freqresp(K*G, w));
    d  = min(abs(fr - (-1)));
    T  = feedback(K*G, 1);
    mx = max(real(pole(T)));
    if mx < -1e-6,        st = '안정';
    elseif abs(mx) < 1e-6, st = '경계';
    else,                 st = '불안정';
    end
    fprintf('   %5.1f  %20.4f  %8s\n', K, d, st);
end
fprintf('\n');
fprintf('  이 최단거리에는 이름이 있습니다. **벡터여유** 라고 부르며,\n');
fprintf('  이득여유와 위상여유를 하나로 합친 지표입니다.\n\n');

%% 2-1. 나이퀴스트 판정
%
%  복소해석의 편각원리에서 나오는 결과입니다. 결론만 쓰면
%
%      Z = N + P
%
%      Z : 우반면에 있는 **폐루프** 극점 개수  (0 이어야 안정)
%      N : 나이퀴스트 선도가 -1 점을 **시계 방향으로** 감은 횟수
%      P : 우반면에 있는 **개루프** 극점 개수
%
%  실무에서 쓰는 규칙은 대개 한 줄로 줄어듭니다.
%
%      개루프가 안정하면 (P = 0),
%      나이퀴스트 선도가 -1 점을 감지 않아야 폐루프가 안정하다.

fprintf('=== 나이퀴스트 판정 확인 ===\n');
P_ol = sum(real(pole(G)) > 1e-9);
fprintf('  개루프 우반면 극점 P = %d\n', P_ol);
for K = Kv
    T = feedback(K*G, 1);
    Z = sum(real(pole(T)) > 1e-6);
    fprintf('  K = %.1f : 폐루프 우반면 극점 Z = %d -> N = Z - P = %d\n', K, Z, Z - P_ol);
end
fprintf('  주의 : K = 2 는 극점이 허수축 **위에** 있는 경계입니다.\n');
fprintf('         우반면이 아니므로 Z = 0 으로 세지만 안정한 것은 아닙니다.\n');
fprintf('         나이퀴스트 선도가 -1 점을 정확히 지나는 경우가 이것입니다.\n\n');

%% 3. 이득여유와 위상여유
%
%  "-1 점에서 얼마나 떨어져 있는가" 를 두 방향으로 나눠 잰 것입니다.
%
%    이득여유 (GM) — 위상이 -180도인 주파수(wcg)에서
%                    크기를 몇 배 더 키우면 1 이 되는가
%    위상여유 (PM) — 크기가 1(0 dB)인 주파수(wcp)에서
%                    위상이 -180도까지 몇 도 남았는가
%
%  읽는 순서를 반드시 기억하십시오.
%
%    (1) 아래 위상 그림에서 -180도가 되는 곳을 찾는다 -> wcg
%    (2) 그 주파수에서 위 크기 그림을 본다           -> 이득여유
%    (3) 위 크기 그림에서 0 dB 를 지나는 곳을 찾는다  -> wcp
%    (4) 그 주파수에서 아래 위상 그림을 본다          -> 위상여유

dg_margin(0.5*G, '읽는 자리 : 이득여유와 위상여유 (K = 0.5)');

fprintf('=== margin 이 주는 값 ===\n');
fprintf('     K      GM[배]   GM[dB]    PM[도]    wcg      wcp\n');
fprintf('   -----  --------  -------  --------  -------  -------\n');
ws = warning('off','Control:analysis:MarginUnstable');
for K = [0.2 0.5 1 2 3]
    [gm, pm, wcg, wcp] = margin(K*G);
    fprintf('   %5.1f  %8.3f  %7.2f  %8.2f  %7.3f  %7.3f\n', ...
            K, gm, 20*log10(gm), pm, wcg, wcp);
end
warning(ws);
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    K 를 키우면 크기 곡선이 위로 올라가므로 이득여유가 줄어듭니다.\n');
fprintf('    K = 2 에서 이득여유가 정확히 1 배(0 dB), 위상여유가 0 도입니다.\n');
fprintf('    이것이 안정 한계입니다. 5주차에서 구한 임계이득과 같은 값입니다.\n\n');

%% 3-1. 명령 정리 : `margin`
%
%   - **원리** : 개루프 주파수응답에서 0 dB 를 지나는 곳과 -180도를 지나는 곳을 찾는다
%   - **입력** : **개루프** 전달함수 L. 폐루프를 넣으면 안 된다
%   - **출력** : [Gm, Pm, Wcg, Wcp].
%                Gm 은 **배율**이다. dB 로 보려면 20*log10(Gm)
%
%   주의 세 가지
%     (1) 인자를 안 주고 margin(L) 만 부르면 그림을 그린다. 값을 받으려면 출력을 받는다
%     (2) 여유가 없으면 Gm = Inf 또는 Pm = Inf 로 나온다. 이것은 "무한히 안정"
%         이라는 뜻이 아니라 "그 조건을 만나는 주파수가 없다" 는 뜻이다
%     (3) 개루프가 불안정하면 margin 값만 보고 판단하면 안 된다 (5절 참고)

%% 4. 여유가 얼마면 충분한가
%
%  실무 기준은 이렇습니다.
%
%      이득여유  6 dB 이상 (약 2 배)
%      위상여유  30 ~ 60 도
%
%  왜 여유가 필요한가 — 모델은 반드시 틀리기 때문입니다.
%
%    - 부품이 노후하면 이득이 변한다
%    - 온도가 바뀌면 시정수가 변한다
%    - 계산 시간, 통신 지연이 위상을 깎는다
%
%  여유란 **그만큼 틀려도 버틴다** 는 보증입니다.

fprintf('=== 여유가 뜻하는 것 ===\n');
K0 = 0.5;
[gm0, pm0] = margin(K0*G);
fprintf('  K = %.1f 일 때 GM = %.2f 배, PM = %.1f 도\n', K0, gm0, pm0);
fprintf('\n  (1) 이득이 커지면 언제까지 버티는가\n');
fprintf('       배율     폐루프 극점 실수부 최댓값   안정?\n');
fprintf('     --------  ------------------------  --------\n');
for f = [1 1.5 2 gm0*0.99 gm0*1.01]
    mx = max(real(pole(feedback(f*K0*G, 1))));
    if mx < 0, st='안정'; else, st='불안정'; end
    fprintf('     %8.3f  %24.4f  %8s\n', f, mx, st);
end
fprintf('     --> 이득여유 %.2f 배까지 정확히 버팁니다.\n', gm0);

fprintf('\n  (2) 위상이 더 늦어지면 언제까지 버티는가 (시간지연으로 확인)\n');
[~, ~, ~, wcp0] = margin(K0*G);
fprintf('       지연[s]   깎이는 위상[도]   폐루프 극점 실수부 최댓값\n');
fprintf('     ---------  ---------------  ------------------------\n');
tau_crit = deg2rad(pm0)/wcp0;
for tau = [0 0.5 1 tau_crit*0.9 tau_crit*1.1]
    Ld = K0*G*exp(-tau*s);
    Td = feedback(pade(Ld, 6), 1);
    mx = max(real(pole(Td)));
    fprintf('     %9.3f  %15.1f  %24.4f\n', tau, rad2deg(tau*wcp0), mx);
end
fprintf('     --> 위상여유 %.1f 도는 시간지연 %.3f 초에 해당합니다.\n', pm0, tau_crit);
fprintf('         (지연이 깎는 위상 = tau * wcp [rad])\n\n');

%% 5. 개루프가 불안정하면
%
%  나이퀴스트 판정의 진짜 값어치는 여기서 나옵니다.
%  개루프가 이미 불안정한 시스템(P > 0)은 보드 선도만 봐서는 판단할 수 없습니다.
%
%  예를 들어 우반면 극점이 하나 있는 시스템을 봅시다.

Gu = 1/((s-1)*(s+3));

fprintf('=== 개루프가 불안정한 경우 ===\n');
fprintf('  G = 1/((s-1)(s+3)) : 개루프 극점 %s\n', mat2str(round(pole(Gu).',3)));
P_u = sum(real(pole(Gu)) > 0);
fprintf('  우반면 개루프 극점 P = %d\n\n', P_u);
fprintf('     K     폐루프 우반면 극점 Z   안정?   나이퀴스트 감김수 N = Z - P\n');
fprintf('   -----  ---------------------  ------  ---------------------------\n');
for K = [1 3 5 10]
    T = feedback(K*Gu, 1);
    Z = sum(real(pole(T)) > 1e-9);
    if Z == 0, st='안정'; else, st='불안정'; end
    fprintf('   %5.1f  %21d  %6s  %27d\n', K, Z, st, Z - P_u);
end
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    이 시스템은 **이득을 충분히 키워야** 안정해집니다.\n');
fprintf('    "이득을 키우면 불안정해진다" 는 상식이 항상 맞는 것은 아닙니다.\n');
fprintf('    나이퀴스트 판정 Z = N + P 는 이런 경우에도 그대로 통합니다.\n\n');

figure('Name','개루프가 불안정한 경우');
nyquist(3*Gu); grid on;
title('개루프에 우반면 극점이 있으면 -1 을 반시계로 감아야 안정');

%% 6. 이번 실습의 정리
%
%   (1) 불안정의 조건은 L(jw) = -1. 여유란 그 점에서 얼마나 떨어졌는가다
%   (2) 나이퀴스트 선도는 크기와 위상을 한 평면에 그린 것이다
%   (3) 이득여유는 -180도인 곳에서, 위상여유는 0 dB 인 곳에서 읽는다
%   (4) 실무 기준은 GM 6 dB 이상, PM 30~60도
%   (5) 위상여유는 **견딜 수 있는 시간지연**으로 바꿔 읽을 수 있다 (tau = PM/wcp)
%   (6) 개루프가 불안정하면 Z = N + P 를 써야 한다
%
%  다음 실습
%    W10_02_pm_to_time.m — 주파수영역 사양과 시간영역 사양의 번역
