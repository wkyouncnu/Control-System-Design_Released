%% W09_03_run_simulink.m
%  9주차 실습 (3) : Simulink 로 주파수를 훑어 보드 선도를 직접 측정한다
%
%  이번 실습의 핵심 메시지
%
%      보드 선도는 계산으로만 얻는 것이 아니다.
%      실험으로 **재는** 것이다. 그리고 실무에서는 대개 그렇게 한다.
%
%  왜 중요한가
%      실제 장치의 전달함수를 우리는 모릅니다. 모델이 틀릴 수도 있습니다.
%      그런데 사인파를 넣어 재는 것은 **모델 없이도** 할 수 있습니다.
%      이것이 주파수영역 방법이 실무에서 사랑받는 가장 큰 이유입니다.
%
%  [Simulink 만으로도 볼 수 있습니다]
%      >> open_system('W09_SineSweep')
%  주파수 w_in 을 바꿔 가며 Ctrl+T 로 돌려 보십시오.
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

model = 'W09_SineSweep';

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

%% 1. 플랜트를 모델에 넘긴다
%
%  Simulink 의 Transfer Fcn 블록은 numG, denG 라는 워크스페이스 변수를 읽습니다.
%  숫자를 블록에 직접 적지 않는 이유는, 스크립트에서 바꿔 가며
%  같은 모델을 여러 번 돌리기 위해서입니다.

[G, p] = plant_msd();
[numG, denG] = tfdata(G, 'v');    %#ok<ASGLU>  <- 모델이 읽습니다

A_in  = 1;                        % 입력 사인의 진폭
fprintf('=== 측정할 플랜트 ===\n');
G
fprintf('  이 전달함수를 "모른다" 고 치고 실험으로 알아냅니다.\n\n');

%% 2. 주파수 하나를 재는 절차
%
%  절차는 이렇습니다.
%
%    (1) 주파수 w 를 정하고 사인을 넣는다
%    (2) 과도응답이 사라질 때까지 기다린다  <- 이것이 가장 중요합니다
%    (3) 마지막 몇 주기만 잘라 낸다
%    (4) 진폭비와 위상차를 계산한다
%
%  (2) 를 빠뜨리면 값이 틀립니다. 얼마나 기다려야 하는가는
%  플랜트의 가장 느린 극점이 정합니다. 대략 정착시간의 두 배면 충분합니다.

ts_plant = 4/abs(max(real(pole(G))));       % 대략적인 정착시간
fprintf('=== 얼마나 기다려야 하는가 ===\n');
fprintf('  가장 느린 극점의 실수부 : %.3f\n', max(real(pole(G))));
fprintf('  대략적인 정착시간       : %.2f s\n', ts_plant);
fprintf('  --> 최소 %.0f s 는 기다린 뒤에 재야 합니다.\n\n', 2*ts_plant);

%% 3. 주파수를 훑는다
%
%  이제 여러 주파수에서 (1)~(4) 를 반복합니다.
%  각 주파수마다 Simulink 를 한 번씩 돌립니다.

w_list = logspace(-1, 0.9, 14);             % 0.1 ~ 약 8 rad/s
mag_sim = zeros(size(w_list));
ph_sim  = zeros(size(w_list));

fprintf('=== Simulink 로 재기 ===\n');
fprintf('    w[rad/s]   크기비    크기[dB]   위상[도]   기다린 시간[s]\n');
fprintf('   ---------  --------  ---------  ---------  --------------\n');

for i = 1:numel(w_list)
    w_in = w_list(i);                       %#ok<NASGU>  <- 모델이 읽습니다
    Tp   = 2*pi/w_list(i);

    % 과도응답이 사라지도록 충분히, 그리고 최소 12 주기는 돌린다
    t_end = max(3*ts_plant, 12*Tp);         %#ok<NASGU>

    out = sim(model);

    tt = out.y_sim.Time;
    yy = squeeze(out.y_sim.Data);
    uu = squeeze(out.u_sim.Data);

    % 마지막 여섯 주기만 사용
    keep = tt > tt(end) - 6*Tp;
    tk = tt(keep);  yk = yy(keep);  uk = uu(keep);

    Fu = trapz(tk, uk .* exp(-1j*w_list(i)*tk));
    Fy = trapz(tk, yk .* exp(-1j*w_list(i)*tk));

    mag_sim(i) = abs(Fy/Fu);
    ph_sim(i)  = rad2deg(angle(Fy/Fu));

    fprintf('   %9.3f  %8.4f  %9.2f  %9.2f  %14.1f\n', ...
            w_list(i), mag_sim(i), 20*log10(mag_sim(i)), ph_sim(i), tt(end));
end
fprintf('\n');

%% 4. 잰 값과 이론값을 대조한다
%
%  이 대조가 이번 주차의 핵심입니다.
%  "블록선도를 돌려 잰 것" 과 "전달함수에 s=jw 를 넣은 것" 이 같아야 합니다.

Gjw = squeeze(freqresp(G, w_list));
mag_th = abs(Gjw);
ph_th  = rad2deg(angle(Gjw));

err_mag = max(abs(20*log10(mag_sim) - 20*log10(mag_th.')));
err_ph  = max(abs(ph_sim - ph_th.'));

fprintf('=== Simulink 측정 vs 이론값 ===\n');
fprintf('  크기 최대 오차 : %.4f dB\n', err_mag);
fprintf('  위상 최대 오차 : %.4f 도\n', err_ph);
if err_mag < 0.5 && err_ph < 3
    fprintf('  --> 일치합니다. 블록선도를 돌려 잰 것이 곧 G(jw) 입니다.\n\n');
else
    fprintf('  --> 오차가 큽니다. 더 오래 기다렸다가 재야 합니다.\n\n');
end

wg = logspace(-1.2, 1.1, 400);
[mg, pg] = bode(G, wg);
mg = squeeze(mg);  pg = squeeze(pg);

figure('Name','Simulink 로 잰 보드 선도', 'Position',[80 80 880 500]);
tiledlayout(2,1,'TileSpacing','compact');

nexttile
semilogx(wg, 20*log10(mg), 'LineWidth', 2); hold on; grid on;
semilogx(w_list, 20*log10(mag_sim), 'o', 'MarkerSize', 10, 'LineWidth', 2);
ylabel('크기 [dB]');
legend('이론 (bode)', 'Simulink 로 직접 잰 값', 'Location','southwest');
title('사인을 넣어 잰 결과가 이론 곡선 위에 놓인다');

nexttile
semilogx(wg, pg, 'LineWidth', 2); hold on; grid on;
semilogx(w_list, ph_sim, 'o', 'MarkerSize', 10, 'LineWidth', 2);
xlabel('주파수 [rad/s]'); ylabel('위상 [도]');
title('위상도 마찬가지');

%% 5. 기다리지 않으면 어떻게 되는가
%
%  과도응답이 남아 있는 상태에서 재면 값이 틀립니다.
%  얼마나 틀리는지 직접 확인합니다.

w_in = 1.0;                                  %#ok<NASGU>
Tp = 2*pi/w_in;

fprintf('=== 충분히 기다리지 않으면 ===\n');
fprintf('    돌린 시간[s]   잰 크기비   참값 %.4f   오차[%%]\n', abs(freqresp(G,1.0)));
fprintf('   -------------  ----------  -----------  --------\n');

true_mag = abs(freqresp(G, 1.0));
for tend = [8 15 30 60 120]
    t_end = tend;                            %#ok<NASGU>
    out = sim(model);
    tt = out.y_sim.Time;  yy = squeeze(out.y_sim.Data);  uu = squeeze(out.u_sim.Data);
    keep = tt > tt(end) - 3*Tp;
    Fu = trapz(tt(keep), uu(keep).*exp(-1j*1.0*tt(keep)));
    Fy = trapz(tt(keep), yy(keep).*exp(-1j*1.0*tt(keep)));
    mm = abs(Fy/Fu);
    fprintf('   %13.0f  %10.4f  %11s  %8.2f\n', ...
            tend, mm, '', 100*abs(mm-true_mag)/true_mag);
end
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    이 플랜트는 감쇠비가 %.2f 로 작아 과도응답이 오래갑니다.\n', ...
        p.b/(2*sqrt(p.k*p.m)));
fprintf('    짧게 돌리면 크게 틀립니다. 실험할 때 반드시 주의할 점입니다.\n\n');

%% 6. 직접 해 볼 것
%
%   (1) 감쇠 b 를 1.0 으로 키우면 (plant_msd(1, 1.0, 1))
%       -> 과도응답이 빨리 사라져 짧게 돌려도 정확해진다
%
%   (2) w_in 을 공진주파수 근처(약 1 rad/s)로 두고 진폭을 보면?
%       -> 입력보다 훨씬 큰 출력이 나온다. 이것이 공진이다
%
%   (3) 주파수를 10 rad/s 로 올리면?
%       -> 출력이 거의 안 나온다. 고주파는 통과하지 못한다 (저역통과)
%
%   (4) 모델에서 Transfer Fcn 대신 DC 모터를 넣어 보면?
%       -> plant_dcmotor 로 numG, denG 를 바꾸면 된다. 코드는 그대로다
%
%  모델 열기:
%      >> open_system('W09_SineSweep')
