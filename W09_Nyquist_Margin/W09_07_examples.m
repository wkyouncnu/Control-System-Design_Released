%% W09_07_examples.m
%  9주차 실습 (7) : 단독 Simulink 예제 네 개를 차례로 돌려 손계산과 맞춰 본다
%
%  이번 실습의 핵심 메시지
%
%      안정 여유는 식이 아니라 **눈으로 볼 수 있는 것**이다.
%      루프를 한 바퀴 돌려 보면 그 자리에서 보인다.
%
%  네 모델은 서로 아무 관계가 없습니다. 하나씩 따로 열어 돌려도 됩니다.
%  이 스크립트는 네 개를 한꺼번에 돌려 **손계산과 숫자를 대조**할 뿐입니다.
%
%      W09_E1_LoopOnce      루프를 끊고 한 바퀴 -> 돌아온 진폭이 |L|
%      W09_E2_GainMargin    루프를 닫고 K 세 개 -> 수렴 · 지속진동 · 발산
%      W09_E3_DelayMargin   지연만 키우기      -> tau_max = PM / wcp
%      W09_E4_Bandwidth     폐루프에 사인      -> 공진봉우리와 대역폭
%
%  [Simulink 만으로도 볼 수 있습니다]
%      >> open_system('W09_E1_LoopOnce')
%  모델을 열면 파라미터가 자동으로 들어가므로 바로 Ctrl+T 를 누르면 됩니다.
%
%  제어시스템설계 9주차 | 충남대학교 자율운항시스템공학과

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

% Transport Delay 의 지연이 0 이면 Simulink 가 안내 경고를 냅니다.
% 결과에는 문제가 없으므로 꺼 둡니다.
warning('off', 'Simulink:blocks:TDelayDirectThroughAutoSet');

%% 0. 네 모델이 공통으로 쓰는 플랜트
%
%  강의자료 6장의 표준 예제입니다. 네 모델 모두 이것 하나만 씁니다.
%
%      G(s) = 1 / ( s*(s+1)^2 )
%
%  왜 이 플랜트인가 — 손으로 계산이 되기 때문입니다.
%  w = 1 을 넣어 보면
%
%      (j + 1)^2 = j^2 + 2j + 1 = 2j
%      j * 2j    = 2*j^2        = -2
%      G(j1)     = 1 / (-2)     = -0.5
%
%  즉 크기는 0.5, 위상은 정확히 -180 도입니다.
%  **이 플랜트는 w = 1 에서 신호를 반으로 줄이고 위아래를 뒤집습니다.**
%  이 한 줄이 오늘 네 실험 전체의 출발점입니다.

G = 1/(s*(s+1)^2);
[numG, denG] = tfdata(G, 'v');     %#ok<ASGLU>  <- 네 모델이 이 두 변수를 읽습니다

% 위상은 -180 도와 +180 도가 같은 방향입니다.
% MATLAB 은 +180 을 내놓을 수 있는데, 우리는 "깎인 양" 으로 읽으므로
% 음수 쪽으로 적어 둡니다.
ph1 = angle(freqresp(G,1))*180/pi;
if ph1 > 179.9, ph1 = ph1 - 360; end

fprintf('=== 손으로 먼저 ===\n');
fprintf('  G(j1) = %.4f%+.4fj\n', real(freqresp(G,1)), imag(freqresp(G,1)));
fprintf('  |G(j1)| = %.4f,  위상 = %.1f 도\n\n', abs(freqresp(G,1)), ph1);

%% 1. E1 — 루프를 끊고 한 바퀴만 돌려 본다
%
%  되먹임선이 없는 모델입니다. 신호가 한 번만 지나갑니다.
%
%      사인 -> K -> G -> 출력
%
%  w = 1 사인을 넣으면 나오는 진폭은 K * |G(j1)| = 0.5*K 입니다.
%  이것이 바로 **루프이득의 크기** |L(j1)| 입니다.
%
%  진폭 재는 법 — 이 플랜트는 적분기(1/s)를 가지고 있어서
%  출력에 **일정한 치우침(DC)** 이 생깁니다. 그래서 최댓값만 보면 안 되고
%  (최댓값 - 최솟값)/2 로 재야 합니다. 치우침이 저절로 빠집니다.

model = 'W09_E1_LoopOnce';
if ~bdIsLoaded(model), load_system(model); end

w_in  = 1;
t_end = 40;
K_list = [0.5 2 3];

fprintf('=== E1 : 루프를 끊고 한 바퀴 (w = 1) ===\n');
fprintf('        K     돌아온 진폭   손계산 0.5*K   뒤집혔나\n');
fprintf('   -------  ------------  ------------  ----------\n');

amp_E1 = zeros(size(K_list));
for i = 1:numel(K_list)
    K = K_list(i);                               %#ok<NASGU>
    out = sim(model);

    tt = out.y_sim.Time;
    yy = squeeze(out.y_sim.Data);
    uu = squeeze(out.u_sim.Data);

    late = tt > 0.7*t_end;                       % 과도구간을 버린다
    amp_E1(i) = (max(yy(late)) - min(yy(late))) / 2;

    % 뒤집혔는지 — 입력이 가장 클 때 출력이 평균보다 아래인가
    yl = yy(late);  ul = uu(late);  tl = tt(late);
    [~, kmax] = max(ul);
    flipped = yl(kmax) < mean(yl);

    if flipped, tag = '뒤집힘'; else, tag = '그대로'; end
    fprintf('   %7.2f  %12.4f  %12.4f  %10s\n', ...
            K_list(i), amp_E1(i), 0.5*K_list(i), tag);
end
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    K = 2 에서 돌아온 진폭이 정확히 1 입니다.\n');
fprintf('    넣은 것과 **같은 크기로, 뒤집혀서** 돌아왔습니다.\n');
fprintf('    여기에 되먹임의 빼기가 한 번 더 뒤집으면 원래 신호와 같아집니다.\n');
fprintf('    즉 신호가 스스로를 유지합니다. **이것이 안정 한계입니다.**\n\n');

%% 1-1. 그림으로 — 넣은 사인과 돌아온 사인
%
%  K 세 개를 한 장에 겹쳐 그립니다. 점선이 넣은 사인입니다.

figure('Name','E1 : 한 바퀴 돌아온 신호', 'Position',[80 80 880 420]);
hold on; grid on;
for i = 1:numel(K_list)
    K = K_list(i);                               %#ok<NASGU>
    out = sim(model);
    tt = out.y_sim.Time;  yy = squeeze(out.y_sim.Data);
    plot(tt, yy - mean(yy(tt>0.7*t_end)), 'LineWidth', 1.8, ...
         'DisplayName', sprintf('K = %.1f  (진폭 %.2f)', K_list(i), amp_E1(i)));
end
plot(out.u_sim.Time, squeeze(out.u_sim.Data), 'k--', ...
     'LineWidth', 1.4, 'DisplayName', '넣은 사인');
xlim([0.7*t_end t_end]); xlabel('시간 [s]'); ylabel('치우침을 뺀 출력');
legend('Location','eastoutside');
title('돌아온 진폭이 1 을 넘으면 루프가 스스로 커진다');

%% 2. E2 — 똑같은 플랜트에 되먹임선 하나만 더 긋는다
%
%  E1 과 블록이 같습니다. 더해진 것은 되먹임선 하나뿐입니다.
%  그런데 결과는 완전히 달라집니다.
%
%  E1 에서 잰 진폭으로 **미리 예측할 수 있습니다.**
%
%      진폭 < 1  ->  돌 때마다 작아진다  ->  수렴
%      진폭 = 1  ->  크기가 유지된다    ->  지속진동
%      진폭 > 1  ->  돌 때마다 커진다    ->  발산

model = 'W09_E2_GainMargin';
if ~bdIsLoaded(model), load_system(model); end

t_end = 60;

fprintf('=== E2 : 루프를 닫으면 ===\n');
fprintf('        K    E1 진폭   예측      실제      마지막 진폭\n');
fprintf('   -------  ---------  --------  --------  -----------\n');

for i = 1:numel(K_list)
    K = K_list(i);                               %#ok<NASGU>
    out = sim(model);

    tt = out.y_sim.Time;  yy = squeeze(out.y_sim.Data);

    mid  = (max(yy(tt>0.4*t_end & tt<0.6*t_end)) - min(yy(tt>0.4*t_end & tt<0.6*t_end)))/2;
    late = (max(yy(tt>0.8*t_end)) - min(yy(tt>0.8*t_end)))/2;

    if late < 0.02,              act = '수렴';
    elseif late > 1.05*mid,      act = '발산';
    else,                        act = '지속진동';
    end

    if     amp_E1(i) < 0.98, prd = '수렴';
    elseif amp_E1(i) > 1.02, prd = '발산';
    else,                    prd = '지속진동';
    end

    fprintf('   %7.2f  %9.4f  %8s  %8s  %11.4f\n', ...
            K_list(i), amp_E1(i), prd, act, late);
end
fprintf('\n');

[gm, pm, wcg, wcp] = margin(0.5*G);
fprintf('  읽는 법\n');
fprintf('    K = 0.5 에서 margin 이 알려 주는 이득여유는 %.2f 배 (%.2f dB) 입니다.\n', ...
        gm, 20*log10(gm));
fprintf('    0.5 의 %.2f 배는 %.2f — E2 에서 지속진동이 나온 그 K 입니다.\n', ...
        gm, 0.5*gm);
fprintf('    **이득여유란 "지금 이득을 몇 배까지 키워도 되는가" 입니다.**\n');
fprintf('    진동 주기는 2*pi/%.3f = %.2f 초 — E1 에서 넣었던 주파수입니다.\n\n', ...
        wcg, 2*pi/wcg);

%% 2-1. 그림으로 — 수렴 · 지속진동 · 발산
figure('Name','E2 : K 세 개로 안정 한계를 통과한다', 'Position',[80 80 880 420]);
hold on; grid on;
for i = 1:numel(K_list)
    K = K_list(i);                               %#ok<NASGU>
    out = sim(model);
    plot(out.y_sim.Time, squeeze(out.y_sim.Data), 'LineWidth', 1.9, ...
         'DisplayName', sprintf('K = %.1f  (E1 진폭 %.2f)', K_list(i), amp_E1(i)));
end
yline(1, 'k--', 'HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력'); ylim([-1 3]);
legend('Location','northwest');
title('E1 에서 잰 진폭이 1 을 넘는 순간 폐루프가 발산한다');

%% 3. E3 — 이득은 그대로, 지연만 키운다
%
%  시간지연의 주파수응답은 exp(-j*w*tau) 입니다.
%
%      크기 = 1   (항상)
%      위상 = -w*tau [rad]
%
%  **크기를 전혀 건드리지 않습니다.** 그래서 이득여유로는 설명이 안 됩니다.
%  깎이는 것은 위상여유뿐입니다. 그리고 위상여유가 0 이 되는 지연이
%
%      tau_max = PM[rad] / wcp
%
%  입니다. 교차주파수 wcp 에서 위상이 -180 도에 닿으면 끝입니다.

model = 'W09_E3_DelayMargin';
if ~bdIsLoaded(model), load_system(model); end

K     = 0.5;
t_end = 80;

tau_max = (pm*pi/180) / wcp;
tau_list = [0, 0.5*tau_max, tau_max, 1.5*tau_max];

fprintf('=== E3 : 지연만 키운다 (K = 0.5 고정) ===\n');
fprintf('  PM = %.2f 도, wcp = %.4f rad/s  ->  tau_max = %.3f 초\n\n', pm, wcp, tau_max);
fprintf('     tau[s]   깎는 위상[도]   남은 PM[도]   마지막 진폭   판정\n');
fprintf('   ---------  -------------  ------------  -----------  --------\n');

for i = 1:numel(tau_list)
    tau_d = tau_list(i);                         %#ok<NASGU>
    out = sim(model);

    tt = out.y_sim.Time;  yy = squeeze(out.y_sim.Data);
    mid  = (max(yy(tt>0.4*t_end & tt<0.6*t_end)) - min(yy(tt>0.4*t_end & tt<0.6*t_end)))/2;
    late = (max(yy(tt>0.8*t_end)) - min(yy(tt>0.8*t_end)))/2;

    if late < 0.02,         st = '수렴';
    elseif late > 1.05*mid, st = '발산';
    else,                   st = '지속진동';
    end

    eaten = tau_list(i)*wcp*180/pi;
    fprintf('   %9.3f  %13.1f  %12.1f  %11.4f  %8s\n', ...
            tau_list(i), eaten, pm - eaten, late, st);
end
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    이득은 0.5 로 한 번도 건드리지 않았습니다.\n');
fprintf('    그런데 지연 %.2f 초만으로 안정 한계에 닿았습니다.\n', tau_max);
fprintf('    **위상여유는 "얼마나 늦어도 되는가" 를 재는 자입니다.**\n\n');

%% 3-1. 그림으로 — 지연이 응답을 망가뜨린다
figure('Name','E3 : 지연만으로 발산한다', 'Position',[80 80 880 420]);
hold on; grid on;
for i = 1:numel(tau_list)
    tau_d = tau_list(i);                         %#ok<NASGU>
    out = sim(model);
    plot(out.y_sim.Time, squeeze(out.y_sim.Data), 'LineWidth', 1.8, ...
         'DisplayName', sprintf('\\tau = %.2f s  (남은 PM %.0f도)', ...
                                tau_list(i), pm - tau_list(i)*wcp*180/pi));
end
yline(1, 'k--', 'HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력'); ylim([-1 3]);
legend('Location','northwest');
title('이득은 그대로인데 지연만으로 안정 한계를 넘는다');

%% 4. E4 — 폐루프에 사인을 넣어 대역폭을 직접 잰다
%
%  지금까지 셋은 모두 **개루프** 이야기였습니다. 이번에는 루프를 닫고 잽니다.
%  8주차에서 플랜트의 보드 선도를 사인으로 쟀던 그 방법 그대로입니다.
%
%      사인 하나 넣기 -> 나온 사인의 진폭 재기 -> 진폭비 적기
%
%  그리고 두 가지 숫자를 찾습니다.
%
%      공진봉우리 Mr  : 진폭비가 1 을 넘어 가장 커지는 값
%      대역폭 w_BW    : 진폭비가 0.707 (= -3 dB) 로 떨어지는 주파수
%
%  왜 0.707 인가 — 전력이 절반이 되는 지점입니다. 20*log10(0.707) = -3 dB.

model = 'W09_E4_Bandwidth';
if ~bdIsLoaded(model), load_system(model); end

K     = 0.5;
t_end = 160;
T     = feedback(K*G, 1);                  % 손계산용 폐루프

w_list = [0.1 0.2 0.4 0.6 0.8 1.0 1.2 1.6 2.0];

fprintf('=== E4 : 폐루프의 진폭비를 사인으로 잰다 (K = 0.5) ===\n');
fprintf('     w[rad/s]   넣은 진폭   나온 진폭   진폭비   dB      손계산 진폭비\n');
fprintf('   ----------  ----------  ----------  -------  ------  -------------\n');

ratio = zeros(size(w_list));
for i = 1:numel(w_list)
    w_in = w_list(i);                            %#ok<NASGU>
    out  = sim(model);

    tt = out.y_sim.Time;
    yy = squeeze(out.y_sim.Data);
    uu = squeeze(out.u_sim.Data);

    late = tt > 0.7*t_end;                       % 정상상태만 쓴다
    au = (max(uu(late)) - min(uu(late))) / 2;
    ay = (max(yy(late)) - min(yy(late))) / 2;
    ratio(i) = ay / au;

    fprintf('   %10.2f  %10.4f  %10.4f  %7.4f  %+6.2f  %13.4f\n', ...
            w_list(i), au, ay, ratio(i), 20*log10(ratio(i)), ...
            abs(freqresp(T, w_list(i))));
end
fprintf('\n');

[Mr, iMr] = max(ratio);
fprintf('  읽는 법\n');
fprintf('    공진봉우리 : w = %.2f 에서 진폭비 %.3f (%.2f dB) 로 가장 큽니다.\n', ...
        w_list(iMr), Mr, 20*log10(Mr));
fprintf('    **1 보다 크다는 것은 지령보다 더 크게 흔들린다는 뜻입니다.**\n');
fprintf('    대역폭   : bandwidth 명령은 %.4f rad/s 라고 합니다.\n', bandwidth(T));
fprintf('    위 표에서 진폭비가 0.707 을 지나는 자리와 맞는지 보십시오.\n');
fprintf('    참고로 개루프 교차주파수는 %.4f rad/s 였습니다.\n', wcp);
fprintf('    **w_BW 가 w_c 보다 큽니다.** 이유는 강의노트 5-1-3-2 절에 있습니다.\n\n');

%% 4-1. 그림으로 — 사인으로 잰 점과 보드 선도
%
%  손계산(선)과 시뮬레이션(점)이 겹치는지 확인합니다.

w = logspace(-1.2, 0.7, 300);
figure('Name','E4 : 사인으로 잰 폐루프 크기', 'Position',[80 80 880 440]);
semilogx(w, 20*log10(squeeze(abs(freqresp(T, w)))), 'LineWidth', 2.2); hold on; grid on;
semilogx(w_list, 20*log10(ratio), 'o', 'MarkerSize', 9, 'LineWidth', 2);
yline(-3, 'k--'); yline(0, 'k:');
xline(bandwidth(T), 'r--', 'LineWidth', 1.6);
xlabel('주파수 [rad s^{-1}]'); ylabel('폐루프 크기 [dB]');
legend('손계산 (freqresp)', '사인으로 실측', '-3 dB', '0 dB', '대역폭', ...
       'Location','southwest');
title('폐루프 보드 선도를 사인 아홉 번으로 직접 그렸다');

%% 5. 직접 해 볼 것
%
%   (1) E1 에서 w_in 을 0.5 로 바꾸면 돌아온 사인이 뒤집히는가?
%       -> 안 뒤집힌다. -180 도는 w = 1 에서만 생긴다.
%          그래서 안정 한계를 논할 때는 **그 주파수**를 먼저 찾아야 한다
%
%   (2) E2 에서 K = 1.9 와 2.1 을 넣어 보면?
%       -> 1.9 는 아주 느리게 수렴하고 2.1 은 아주 느리게 발산한다.
%          경계가 칼같이 갈린다는 것을 눈으로 본다
%
%   (3) E3 에서 K 를 1.0 으로 키우고 다시 tau 를 훑으면?
%       -> 견디는 지연이 훨씬 짧아진다. 이득을 키우면 지연에 약해진다
%
%   (4) E4 에서 K 를 0.2 로 줄이면 대역폭은?
%       -> 좁아진다. 즉 느려진다. 대신 공진봉우리도 작아진다.
%          10주차의 맞바꿈이 여기서 시작된다
%
%  모델 열기:
%      >> open_system('W09_E1_LoopOnce')
%      >> open_system('W09_E2_GainMargin')
%      >> open_system('W09_E3_DelayMargin')
%      >> open_system('W09_E4_Bandwidth')
