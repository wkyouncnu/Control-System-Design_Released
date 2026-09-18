%% W10_03_run_simulink.m
%  10주차 실습 (3) : Simulink 모델을 선형화해서 안정 여유를 뽑아낸다
%
%  이번 실습의 핵심 메시지
%
%      실제 현장에서 모델은 전달함수로 오지 않는다. **블록선도로 온다.**
%      그래서 블록선도를 선형화해 개루프를 뽑아내는 절차를 알아야 한다.
%
%  그리고 하나 더
%
%      시간지연은 크기를 전혀 건드리지 않고 **위상만 깎는다.**
%      근궤적으로는 다루기 어렵지만 주파수영역에서는 아주 쉽다.
%      이것이 주파수영역 방법이 실무에서 사랑받는 또 하나의 이유다.
%
%  [Simulink 만으로도 볼 수 있습니다]
%      >> open_system('W10_Margin_Check')
%  tau_d 를 0, 0.3, 0.6 으로 바꿔 가며 Ctrl+T 로 돌려 보십시오.
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

model = 'W10_Margin_Check';

% Transport Delay 의 지연이 0 이면 Simulink 가 경고를 냅니다.
% "직접 피드스루로 자동 설정했다" 는 안내일 뿐 결과에는 문제가 없으므로 꺼 둡니다.
ws = warning('off', 'Simulink:blocks:TDelayDirectThroughAutoSet');
warning('off', 'Control:analysis:MarginUnstable');   % 표를 훑는 것이 목적이므로
cleanupObj = onCleanup(@() warning(ws));  %#ok<NASGU>

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
%  강의자료 6장의 표준 예제를 그대로 씁니다.
%
%      G(s) = 1 / ( s*(s+1)^2 )

G = 1/(s*(s+1)^2);
[numG, denG] = tfdata(G, 'v');   %#ok<ASGLU>  <- 모델이 읽습니다

K     = 0.5;
r_amp = 1;
tau_d = 0;                       % 아직 지연 없음
t_end = 60;

if ~bdIsLoaded(model), load_system(model); end

%% 2. 모델을 선형화해서 개루프를 뽑는다
%
%  절차는 두 줄입니다.
%
%    (1) linio 로 **어디를 자를 것인가** 를 지정한다
%    (2) linearize 로 그 두 점 사이의 전달함수를 구한다
%
%  여기서는
%    입력점 : 오차 신호 e (합산점의 출력)     -> 'openinput'
%    출력점 : 플랜트 출력 y                    -> 'openoutput'
%  로 두었으므로, 얻어지는 것은 e 에서 y 까지의 **개루프** 전달함수입니다.
%
%  왜 'open' 인가 — 루프를 끊어야 개루프가 됩니다.
%  끊지 않으면 폐루프 전달함수가 나옵니다. margin 은 개루프를 받아야 합니다.

io(1) = linio([model '/오차'],        1, 'openinput');
io(2) = linio([model '/플랜트 G(s)'], 1, 'openoutput');

% 시간지연을 근사하지 말고 **그대로** 담아 달라는 옵션입니다.
% 이것을 빠뜨리면 Transport Delay 가 이득 1 로 선형화되어
% "지연을 넣었는데 위상여유가 안 변한다" 는 이상한 결과가 나옵니다.
opt = linearizeOptions('UseExactDelayModel', 'on');

L_sim = tf(linearize(model, io, opt));
L_th  = K*G;

fprintf('=== Simulink 선형화 결과 ===\n');
L_sim
fprintf('  손으로 쓴 개루프 K*G :\n');
L_th
[gm1, pm1, wg1, wp1] = margin(L_sim);
[gm2, pm2, wg2, wp2] = margin(L_th);
fprintf('  선형화 : GM %.3f 배 (%.2f dB), PM %.2f 도, wcg %.3f, wcp %.3f\n', ...
        gm1, 20*log10(gm1), pm1, wg1, wp1);
fprintf('  이론값 : GM %.3f 배 (%.2f dB), PM %.2f 도, wcg %.3f, wcp %.3f\n', ...
        gm2, 20*log10(gm2), pm2, wg2, wp2);
fprintf('  --> 일치합니다. 블록선도에서 뽑은 개루프가 곧 K*G 입니다.\n\n');

%% 2-1. 왜 이 절차가 중요한가
%
%  실무의 모델은 대개 이렇습니다.
%
%    - 비선형 블록이 섞여 있다 (포화, 마찰, 룩업 테이블)
%    - 서브시스템이 여러 겹으로 쌓여 있다
%    - 손으로 전달함수를 쓰는 것이 사실상 불가능하다
%
%  이때 linearize 는 **동작점 근처에서** 선형 모델을 자동으로 만들어 줍니다.
%  3주차에서 손으로 한 야코비안 선형화를 도구가 대신 해 주는 것입니다.

%% 3. 시간지연을 넣으면
%
%  시간지연 tau 의 주파수응답은 이렇습니다.
%
%      exp(-j*w*tau)
%
%  크기는 항상 1 입니다. **크기 곡선이 전혀 변하지 않습니다.**
%  위상만 -w*tau [rad] 만큼 깎입니다. 그리고 이 값은 주파수에 비례하므로
%  **고주파일수록 심하게 깎입니다.**
%
%  결과적으로 이득여유는 줄고 위상여유도 줄어듭니다.

fprintf('=== 시간지연이 위상여유를 깎는다 ===\n');
fprintf('     tau_d[s]   깎는 위상[도]   PM[도]   GM[dB]   진폭 성장비   폐루프\n');
fprintf('   ----------  -------------  -------  -------  -----------  --------\n');

tau_list = [0 0.2 0.5 1.0 1.5 2.0];
PM_sim = zeros(size(tau_list));

for i = 1:numel(tau_list)
    tau_d = tau_list(i);                        %#ok<NASGU>

    L_d = linearize(model, io, opt);            % 지연이 포함된 개루프
    [gmd, pmd] = margin(L_d);
    PM_sim(i) = pmd;

    % 폐루프 안정성은 시뮬레이션으로 확인합니다.
    % 지연이 있으면 극점이 무한히 많아 pole() 만으로는 판단하기 어렵습니다.
    out = sim(model);
    yy  = squeeze(out.y_sim.Data);
    tt  = out.y_sim.Time;
    mid  = max(abs(yy(tt > 0.4*tt(end) & tt < 0.6*tt(end)) - r_amp));
    late = max(abs(yy(tt > 0.8*tt(end)) - r_amp));
    grow = late / max(mid, eps);                % 1 보다 크면 진폭이 커지는 중
    if late < 0.05*r_amp,  st = '안정';
    elseif grow > 1.05,    st = '발산';
    else,                  st = '진동';
    end

    fprintf('   %10.2f  %13.1f  %7.2f  %7.2f  %11.3f  %8s\n', ...
            tau_list(i), rad2deg(tau_list(i)*wp2), pmd, 20*log10(gmd), grow, st);
end
fprintf('\n');
fprintf('  읽는 법\n');
fprintf('    지연이 깎는 위상은 tau * wcp [rad] 입니다.\n');
fprintf('    wcp = %.3f rad/s 이므로 tau = %.3f s 면 위상여유가 정확히 0 이 됩니다.\n', ...
        wp2, deg2rad(pm2)/wp2);
fprintf('    즉 이 설계는 **%.2f 초까지의 지연은 견딥니다.**\n\n', deg2rad(pm2)/wp2);

%% 3-1. 크기는 정말 안 변하는가
%
%  선형화 결과에서 직접 확인합니다.
%  linearize 는 지연을 근사(Pade)해서 유리함수로 만들어 주므로
%  아주 높은 주파수에서는 조금 어긋날 수 있지만, 관심 대역에서는 일치합니다.

tau_d = 1.0;                                    %#ok<NASGU>
L_d1  = linearize(model, io, opt);

w = logspace(-2, 1, 400);
figure('Name','시간지연은 위상만 깎는다', 'Position',[80 80 880 500]);
tiledlayout(2,1,'TileSpacing','compact');

nexttile
semilogx(w, 20*log10(squeeze(abs(freqresp(L_th, w)))), 'LineWidth', 2.4); hold on; grid on;
semilogx(w, 20*log10(squeeze(abs(freqresp(L_d1, w)))), '--', 'LineWidth', 2);
yline(0,'k--');
ylabel('크기 [dB]');
legend('지연 없음', '지연 1 초', '0 dB', 'Location','southwest');
title('크기 곡선은 그대로다');

nexttile
semilogx(w, unwrap(squeeze(angle(freqresp(L_th, w))))*180/pi, 'LineWidth', 2.4); hold on; grid on;
semilogx(w, unwrap(squeeze(angle(freqresp(L_d1, w))))*180/pi, '--', 'LineWidth', 2);
yline(-180,'k--'); xline(wp2, ':', 'LineWidth', 1.8);
xlabel('주파수 [rad s^{-1}]'); ylabel('위상 [도]'); ylim([-360 -80]);
legend('지연 없음', '지연 1 초', '-180도', '교차주파수', 'Location','southwest');
title('위상만 깎인다. 고주파일수록 심하다');

%% 4. 시간영역에서 확인
%
%  마지막으로 실제 응답을 봅니다. 위상여유가 줄면 진동이 심해집니다.

figure('Name','지연이 응답에 미치는 영향', 'Position',[80 80 880 420]);
hold on; grid on;
for i = 1:numel(tau_list)
    tau_d = tau_list(i);                        %#ok<NASGU>
    out = sim(model);
    plot(out.y_sim.Time, squeeze(out.y_sim.Data), 'LineWidth', 1.8, ...
         'DisplayName', sprintf('\\tau = %.1f s  (PM %.0f도)', tau_list(i), PM_sim(i)));
end
yline(r_amp, 'k--', 'HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력'); ylim([-1 3]);
legend('Location','northeast');
title('위상여유가 줄면 진동이 심해지고 결국 발산한다');

%% 5. 직접 해 볼 것
%
%   (1) K 를 1.0 으로 키우고 지연을 다시 훑어 보면?
%       -> 위상여유가 처음부터 작으므로 훨씬 작은 지연에서 발산한다.
%          "이득을 키우면 지연에 약해진다" 는 실무 감각을 얻을 수 있다
%
%   (2) 견딜 수 있는 지연을 두 배로 늘리려면?
%       -> tau_max = PM/wcp 이므로 위상여유를 키우거나 교차주파수를 낮춰야 한다.
%          11주차의 Lead 와 Lag 가 각각 이 두 가지를 한다
%
%   (3) 모델에 포화 블록을 넣으면 linearize 는 어떻게 되는가?
%       -> 동작점에서 포화가 안 걸려 있으면 이득 1 인 통과로 선형화된다.
%          즉 선형화는 포화를 "보지 못한다". 6주차의 교훈과 같다
%
%   (4) 플랜트를 DC 모터 위치 모델로 바꾸면?
%       -> numG, denG 만 바꾸면 된다. 코드는 그대로다
%
%  모델 열기:
%      >> open_system('W10_Margin_Check')
