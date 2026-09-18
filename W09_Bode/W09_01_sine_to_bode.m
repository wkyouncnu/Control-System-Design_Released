%% W09_01_sine_to_bode.m
%  9주차 실습 (1) : 사인을 넣어 보드 선도를 직접 만들어 본다
%
%  이 스크립트에서 답할 질문
%    Q1. 사인을 넣으면 정말 사인이 나오는가?            -> 2절
%    Q2. 크기비와 위상차는 어떻게 재는가?               -> 3절
%    Q3. 직접 잰 값이 bode 곡선 위에 놓이는가?          -> 4절
%    Q4. 크기를 왜 dB 로, 주파수를 왜 로그로 그리는가?  -> 5절
%
%  대응하는 강의노트 : W09_LectureNote.mlx
%  대응하는 Simulink : W09_SineSweep.slx
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

%% 1. 오늘의 플랜트
%
%  1~5주차에서 쓰던 질량-스프링-댐퍼를 다시 씁니다.
%  이미 극점도 알고 계단응답도 아는 시스템이라
%  "주파수로 보면 어떻게 보이는가" 에만 집중할 수 있습니다.

[G, p] = plant_msd();

fprintf('=== 오늘의 플랜트 ===\n');
G
fprintf('  m = %.1f, b = %.1f, k = %.1f\n', p.m, p.b, p.k);
fprintf('  극점 : %s\n', mat2str(round(pole(G).', 4)));
fprintf('  고유진동수 wn = %.3f rad/s,  감쇠비 zeta = %.3f\n\n', ...
        sqrt(p.k/p.m), p.b/(2*sqrt(p.k*p.m)));

%% 2. 사인을 하나 넣어 본다
%
%  주파수응답의 출발점은 이 한 문장입니다.
%
%      선형 시불변 시스템에 사인을 넣으면
%      **같은 주파수의 사인**이 나온다. 크기와 위상만 달라진다.
%
%  정말 그런지 직접 확인합니다.
%  주의할 것은 **처음 몇 초는 과도응답이 섞여 있다**는 점입니다.
%  충분히 기다린 뒤의 구간만 보아야 합니다.

w_test = 0.5;                       % 넣어 볼 주파수 [rad/s]
Tp = 2*pi/w_test;                   % 한 주기 [s]
t  = (0:Tp/400:30*Tp)';
u  = sin(w_test*t);
y  = lsim(G, u, t);

figure('Name','사인 입력에 대한 응답');
plot(t, u, 'LineWidth', 2); hold on;
plot(t, y, 'LineWidth', 2); grid on;
xline(10*Tp, 'k--', 'LineWidth', 1.5);
xlabel('시간 [s]'); ylabel('신호');
legend('입력 사인', '출력', '이 뒤부터 정상상태', 'Location','southeast');
title(sprintf('\\omega = %.2f rad/s 를 넣었을 때', w_test));

fprintf('=== 사인을 넣어 보면 ===\n');
fprintf('  주파수 %.2f rad/s, 한 주기 %.2f s\n', w_test, Tp);
fprintf('  처음 %.0f 초 정도는 과도응답이 섞여 있습니다.\n', 10*Tp);
fprintf('  그 뒤에는 입력과 똑같은 모양의 사인이 됩니다.\n\n');

%% 3. 크기비와 위상차를 어떻게 재는가
%
%  두 가지 방법이 있습니다.
%
%  (1) 눈으로 재기 — 진폭을 자로 재고, 꼭짓점이 얼마나 늦는지 본다
%      직관적이지만 잡음이 있으면 부정확합니다.
%
%  (2) 계산으로 재기 — 신호에 exp(-j*w*t) 를 곱해 합한다
%      이것이 푸리에 계수를 구하는 것과 같습니다.
%      잡음에 강하고 자동화할 수 있어 실무에서 이 방법을 씁니다.
%
%  여기서는 두 방법을 다 해 보고 값이 같은지 확인합니다.

keep = t > t(end) - 6*Tp;           % 마지막 여섯 주기만 사용
tt = t(keep);  uu = u(keep);  yy = y(keep);

% (1) 눈으로 재기 (진폭은 최댓값-최솟값의 절반)
mag_eye = (max(yy) - min(yy)) / (max(uu) - min(uu));

% (2) 계산으로 재기
Fu = sum(uu .* exp(-1j*w_test*tt));
Fy = sum(yy .* exp(-1j*w_test*tt));
mag_cal = abs(Fy) / abs(Fu);
ph_cal  = rad2deg(angle(Fy/Fu));

% (3) 이론값 : G(jw) 에 그냥 넣으면 된다
Gjw = freqresp(G, w_test);

fprintf('=== 크기비와 위상차 ===\n');
fprintf('  진폭으로 잰 크기비      : %.4f\n', mag_eye);
fprintf('  계산으로 잰 크기비      : %.4f\n', mag_cal);
fprintf('  이론값 |G(jw)|          : %.4f\n', abs(Gjw));
fprintf('  계산으로 잰 위상차      : %.2f 도\n', ph_cal);
fprintf('  이론값 angle(G(jw))     : %.2f 도\n', rad2deg(angle(Gjw)));
fprintf('  --> 셋이 같습니다. 주파수응답이란 그냥 G(s) 에 s = jw 를 넣은 것입니다.\n\n');

%% 3-1. 왜 s 에 jw 를 넣으면 되는가
%
%  입력이 sin(wt) 일 때 라플라스 변환은 w/(s^2+w^2) 이고,
%  이 분모의 근이 s = ±jw 입니다.
%  부분분수로 풀면 **s = ±jw 항의 계수가 정상상태 응답**이 되고,
%  나머지 항(플랜트 극점에서 오는 것)은 시간이 지나면 사라집니다.
%
%  그 계수를 계산하면 정확히 G(jw) 가 나옵니다.
%  그래서 "정상상태 사인응답 = G(jw)" 입니다.
%
%  4주차에서 배운 것과 이어집니다.
%    계단응답의 정상상태 = G(0)    (s = 0 을 넣은 것)
%    사인응답의 정상상태 = G(jw)   (s = jw 를 넣은 것)

%% 4. 여러 주파수에서 재서 모아 본다
%
%  이제 주파수를 바꿔 가며 위 작업을 반복합니다.
%  그 결과를 모아 놓은 것이 **보드 선도**입니다.

ws = [0.2 0.4 0.6 0.8 1.0 1.5 2.5 5];
mag_meas = zeros(size(ws));
ph_meas  = zeros(size(ws));

fprintf('=== 주파수를 바꿔 가며 재기 ===\n');
fprintf('    w[rad/s]   크기비    크기[dB]   위상[도]\n');
fprintf('   ---------  --------  ---------  ---------\n');
for i = 1:numel(ws)
    w  = ws(i);
    Tp = 2*pi/w;
    tv = (0:Tp/400:30*Tp)';
    uv = sin(w*tv);
    yv = lsim(G, uv, tv);
    kp = tv > tv(end) - 6*Tp;
    Fu = sum(uv(kp).*exp(-1j*w*tv(kp)));
    Fy = sum(yv(kp).*exp(-1j*w*tv(kp)));
    mag_meas(i) = abs(Fy/Fu);
    ph_meas(i)  = rad2deg(angle(Fy/Fu));
    fprintf('   %9.2f  %8.4f  %9.2f  %9.2f\n', ...
            w, mag_meas(i), 20*log10(mag_meas(i)), ph_meas(i));
end
fprintf('\n');

wg = logspace(-1.2, 1.2, 500);
[mg, pg] = bode(G, wg);
mg = squeeze(mg);  pg = squeeze(pg);

figure('Name','직접 잰 값과 bode 곡선', 'Position',[80 80 850 480]);
tiledlayout(2,1,'TileSpacing','compact');

nexttile
semilogx(wg, 20*log10(mg), 'LineWidth', 2); hold on; grid on;
semilogx(ws, 20*log10(mag_meas), 'o', 'MarkerSize', 10, 'LineWidth', 2);
ylabel('크기 [dB]');
legend('bode 가 그린 곡선', '사인을 넣어 직접 잰 값', 'Location','southwest');
title('보드 선도는 사인을 넣고 재 본 결과를 모은 것이다');

nexttile
semilogx(wg, pg, 'LineWidth', 2); hold on; grid on;
semilogx(ws, ph_meas, 'o', 'MarkerSize', 10, 'LineWidth', 2);
xlabel('주파수 [rad/s]'); ylabel('위상 [도]');
title('위상도 마찬가지');

%% 5. 왜 dB 와 로그축인가
%
%  두 가지 이유가 있습니다.
%
%  (1) **곱셈이 덧셈이 된다**
%      전달함수는 대개 인수들의 곱입니다. 로그를 취하면 합이 되므로
%      인수마다 따로 그린 뒤 더하면 됩니다. 이것이 손작도의 핵심입니다.
%
%          20*log10(|G1*G2|) = 20*log10(|G1|) + 20*log10(|G2|)
%
%  (2) **넓은 범위를 한 그림에 담을 수 있다**
%      크기가 1000배 차이 나도 dB 로는 60 차이일 뿐입니다.

fprintf('=== dB 로 바꾸면 곱셈이 덧셈이 된다 ===\n');
G1 = 1/(s+1);  G2 = 1/(s+10);
w0 = 3;
m1 = abs(freqresp(G1, w0));  m2 = abs(freqresp(G2, w0));
m12 = abs(freqresp(G1*G2, w0));
fprintf('  w = %.1f 에서\n', w0);
fprintf('    |G1| = %.4f  -> %8.3f dB\n', m1, 20*log10(m1));
fprintf('    |G2| = %.4f  -> %8.3f dB\n', m2, 20*log10(m2));
fprintf('    |G1*G2| = %.5f -> %8.3f dB   (두 dB 값의 합 = %.3f)\n\n', ...
        m12, 20*log10(m12), 20*log10(m1)+20*log10(m2));

fprintf('  자주 쓰는 값 (외워 두면 편합니다)\n');
for r = [0.01 0.1 0.5 1/sqrt(2) 1 2 10 100]
    fprintf('    크기 %7.4f 배  =  %7.2f dB\n', r, 20*log10(r));
end
fprintf('\n');

%% 6. 이번 실습의 정리
%
%   (1) 사인을 넣으면 같은 주파수의 사인이 나온다. 크기와 위상만 달라진다
%   (2) 그 크기비와 위상차가 곧 G(jw) 다
%   (3) 주파수마다 그것을 모아 그린 것이 보드 선도다
%   (4) 크기는 dB, 주파수는 로그로 그린다. 곱셈이 덧셈이 되기 때문이다
%
%  다음 실습
%    W09_02_bode_asymptotes.m — 손으로 보드 선도를 그리는 법
