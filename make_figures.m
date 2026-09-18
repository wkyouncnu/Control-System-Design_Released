function out = make_figures(only)
%MAKE_FIGURES  강의노트에 박아 넣을 그림을 전부 PNG 로 만든다 (교수자용)
%
%   make_figures()          전부 다시 만든다
%   make_figures('msd')     이름에 'msd' 가 들어간 것만
%   j = make_figures('--jobs')   그리지 않고 목록만 돌려준다
%                                (check_fig_numbers 가 쓴다.
%                                 그림 함수가 이 파일 안에 있어서
%                                 밖에서는 핸들을 받아야만 부를 수 있다)
%
%   왜 PNG 로 미리 만드는가
%     `.mlx` 안에 코드만 넣어 두면 학생이 **[모두 실행] 을 눌러야** 그림이 보입니다.
%     파일을 열자마자 보이게 하려면 그림이 문서 안에 **박혀 있어야** 합니다.
%     그래서 여기서 PNG 를 만들고, 강의노트 원본에서는 이렇게 불러 씁니다.
%
%       % ![캡션](파일이름.png)
%
%   만들어지는 곳
%     common/figures/
%
%   그림을 고치려면
%     `common/dg_*.m` 을 고친 뒤 이 함수를 다시 돌리고,
%     `build_lecture_notes` 로 강의노트를 다시 만드십시오.
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1, only = ''; end

here   = fileparts(mfilename('fullpath'));
figdir = fullfile(here, 'common', 'figures');
if ~exist(figdir, 'dir'), mkdir(figdir); end

% 이름 , 그리는 코드 , 해상도
jobs = {
% ---- 블록선도 (전 주차 공용) -----------------------------------------
 'loop_open.png',        @() dg_loop('open',        '개루프 — 출력을 보지 않는다'),            120
 'loop_closed.png',      @() dg_loop('closed',      '폐루프 — 출력을 보고 고친다'),            120
 'loop_controller.png',  @() dg_loop('controller',  '제어기 C(s) 가 있는 폐루프'),             120
 'loop_disturbance.png', @() dg_loop('disturbance', '외란 d 가 플랜트 입력으로 들어온다'),      120
 'loop_dist_open.png',   @() dg_loop('dist_open',   '개루프에 외란이 들어오면'),                120
 'loop_dist_closed.png', @() dg_loop('dist_closed', '같은 외란이 폐루프에 들어오면'),            120
 'loop_sensor.png',      @() dg_loop('sensor',      '센서 H(s) 가 있는 비단위 피드백'),        120
 'loop_saturation.png',  @() dg_loop('saturation',  '구동기 포화가 있는 폐루프'),              120
 'loop_noise.png',       @() dg_loop('noise',       '측정 잡음 n 이 섞이는 폐루프'),           120
 'loop_statespace.png',  @() dg_loop('statespace',  '상태공간 : 적분기와 A, B, C'),            120
 'loop_pid.png',         @() dg_loop('pid',         'PID — 세 갈래가 더해진다'),               120
 'loop_statefb.png',     @() dg_loop('statefeedback','상태궤환 : u = -Kx + Kr r'),             120
 'loop_observer.png',    @() dg_loop('observer',    '관측기 기반 제어기'),                     120
% ---- 장치 그림 --------------------------------------------------------
 'msd_both.png',         @() dg_msd(),               130
 'msd_only.png',         @() dg_msd('system'),       140
 'msd_freebody.png',     @() dg_msd('fbd'),          140
 'rc_circuit.png',       @() dg_rc(),                130
 'rlc_circuit.png',      @() dg_rc('rlc'),           130
 'motor_schematic.png',  @() dg_motor(),             120
 'pendulum_both.png',    @() dg_pendulum(),          120
 'pendulum_compare.png', @() dg_pendulum('compare'), 120
 'pendulum_fbd.png',     @() dg_pendulum('fbd'),     130
% ---- 개념 그림 --------------------------------------------------------
 'polemap.png',          @() dg_polemap(),           95
 'stepspec.png',         @() dg_stepspec(0.4, 2),    110
 'stepspec_low.png',     @() dg_stepspec(0.7, 2),    110
 'region_10_2.png',      @() dg_region(10, 2),       105
 'region_20_2.png',      @() dg_region(20, 2),       105
 'region_1_52.png',      @() dg_region(1, 5.2),      105
% ---- 주차별 해석 그림 --------------------------------------------------
 'w01_gain_sweep.png',   @() fig_gain_sweep(),       105
 'w01_disturbance.png',  @() fig_disturbance(),      105
 'car_feedback.png',     @() dg_car(),               120
 'w01_ol_fail.png',      @() fig_w01_openloop_fail(), 100
 'w01_two_scenes.png',   @() fig_w01_two_scenes(),    95
 'w01_sensitivity.png',  @() fig_w01_sensitivity(),  100
 'w02_damper_sweep.png', @() fig_damper_sweep(),     105
 'w02_zero_effect.png',  @() fig_zero_effect(),      105
 'modeling_steps.png',   @() dg_modeling_steps(),    120
 'zeta_geo_05.png',      @() dg_zeta_geo(0.5, 1),    105
 'zeta_geo_02.png',      @() dg_zeta_geo(0.2, 1),    105
 'w02_damping.png',      @() fig_w02_damping(),       95
 'w02_pole_time.png',    @() fig_w02_pole_to_time(),  95
 'w02_tf_limits.png',    @() fig_w02_tf_limits(),     95
 'w02_rlc_vs_rc.png',    @() fig_rlc_vs_rc(),        105
 'w03_linearize.png',    @() fig_linearize(),        105
 'w03_pendulum_resp.png',@() fig_pend_resp(),        105
 'block_rules.png',      @() dg_block_rules(),       110
 'w03_state_meaning.png',@() fig_w03_state_meaning(), 95
 'w03_ss_vs_tf.png',     @() fig_w03_ss_vs_tf(),      95
 'w03_why_ss.png',       @() fig_w03_why_ss(),        95
 'w03_how_narrow.png',   @() fig_w03_how_narrow(),    95
 'w06_angle_cond.png',   @() fig_w06_angle_cond(),    95
 'w07_angle_def.png',    @() fig_w07_angle_def(),     95
 'w09_phase_asym.png',   @() fig_w09_phase_asym(),    95
 'w09_hand_margin.png',  @() fig_w09_hand_margin(),   95
 'w10_contour.png',      @() fig_w10_contour(),       95
 'w10_encircle.png',     @() fig_w10_encircle(),      95
 'w06_real_axis.png',    @() fig_w06_real_axis(),     95
 'w06_breakaway.png',    @() fig_w06_breakaway(),     95
 'w06_jw_cross.png',     @() fig_w06_jw_cross(),      95
 'w03_taylor.png',       @() fig_w03_taylor(),        95
 'w03_jacobian.png',     @() fig_w03_jacobian(),      95
 'w03_equilibrium.png',  @() fig_w03_equilibrium(),   95
 'w03_valid_range.png',  @() fig_w03_valid_range(),   95
 'w04_zeta_sweep.png',   @() fig_zeta_sweep(),       105
 'w04_third_pole.png',   @() fig_third_pole(),       105
 'w04_first_order.png',  @() fig_w04_first_order(),   95
 'w04_os_zeta.png',      @() fig_w04_os_zeta(),       95
 'w04_ts_envelope.png',  @() fig_w04_ts_envelope(),   95
 'w04_spec_map.png',     @() dg_spec_map(),          110
 'w04_region_build.png', @() fig_w04_region_build(),  95
 'w04_sim_blocks.png',   @() dg_second_order(),      110
 'w05_gain_poles.png',   @() fig_gain_poles(),       105
 'w05_type_table.png',   @() fig_type_table(),        95
 'w05_why_error.png',    @() fig_w05_why_error(),     95
 'w05_tradeoff.png',     @() fig_w05_tradeoff(),      95
 'w05_kr_vs_int.png',    @() fig_w05_kr_vs_int(),     95
 'w05_error_const.png',  @() fig_w05_error_const(),   95
 'w05_pi_loop.png',      @() dg_pi_loop(),           110
 'w05_type_signal.png',  @() fig_w05_type_signal(),  110
 'w06_four_loci.png',    @() fig_four_loci(),        100
 'w06_asymptote.png',    @() fig_asymptote(),        100
 'w06_sgrid.png',        @() fig_sgrid(),            105
 'w06_design_fail.png',  @() fig_design_fail(),      105
 'w06_what_is.png',      @() fig_w06_what_is(),       95
 'w06_start_end.png',    @() fig_w06_start_end(),     95
 'w06_saturation.png',   @() fig_w06_saturation(),    95
 'w06_design_steps.png', @() dg_design_steps(),      110
 'w07_pd_locus.png',     @() fig_pd_locus(),         105
 'w07_four_comp.png',    @() fig_four_comp(),        105
 'w07_pz_map.png',       @() fig_pz_map(),           105
 'w07_noise.png',        @() fig_noise(),            105
 'w07_zero_place.png',   @() fig_w07_zero_place(),    95
 'w07_zero_os.png',      @() fig_w07_zero_overshoot(), 95
 'w07_pd_improper.png',  @() fig_w07_pd_improper(),   95
 'w07_lead_tradeoff.png',@() fig_w07_lead_tradeoff(), 95
 'w07_pd_vs_pi.png',     @() fig_w07_pd_vs_pi(),      95
 'w07_pseudo_deriv.png', @() fig_w07_pseudo_deriv(),  95
% ---- 9~10주차 : 주파수응답 ---------------------------------------------
 'w09_sine_io.png',      @() dg_sine_io(),           100
 'w09_measure.png',      @() fig_sine_measure(),     100
 'w09_asymptote.png',    @() fig_bode_asymptote(),   100
 'w09_resonance.png',    @() fig_resonance(),        100
 'w09_lpf.png',          @() fig_lpf(),               95
 'w09_hpf.png',          @() fig_hpf(),               95
 'w09_cutoff.png',       @() fig_cutoff_tradeoff(),   95
 'w09_filters.png',      @() fig_filter_family(),     95
 'w09_plant_lpf.png',    @() fig_plant_is_lpf(),      95
% ---- 9주차 : 교수자 강의자료(부록 13~19쪽)의 예제를 그대로 재현 ----
 'w09_lpf_prof.png',     @() fig_lpf_prof(),          95
 'w09_tau_time.png',     @() fig_tau_time(),          95
 'w09_tau_freq.png',     @() fig_tau_freq(),          95
 'w09_bw_order.png',     @() fig_bw_order(),          95
 'w10_margin_read.png',  @() dg_margin(tf(0.5,[1 2 1 0]), ...
                              '읽는 자리 : 이득여유와 위상여유'),  95
 'w10_nyquist_K.png',    @() fig_nyquist_K(),        100
 'w10_pm_os.png',        @() fig_pm_os(),            100
 'w10_bw_speed.png',     @() fig_bw_speed(),         100
 'w10_why_minus1.png',   @() fig_w10_why_minus_one(), 95
 'w10_delay.png',        @() fig_w10_delay(),         95
 'w10_sensitivity.png',  @() fig_w10_sensitivity(),   95
% ---- 11주차 : 주파수영역 설계와 PID ------------------------------------
 'w11_lead_bode.png',    @() fig_lead_bode(),        100
 'w11_lag_bode.png',     @() fig_lag_bode(),         100
 'w11_design_steps.png', @() fig_w11_design_steps(),  95
 'w11_multistage.png',   @() fig_w11_multistage(),   100
 'w11_pid_compare.png',  @() fig_pid_compare(),      100
 'w11_pid_bands.png',    @() fig_w11_pid_bands(),    100
 'w11_windup.png',       @() fig_windup(),           100
 'w11_lead_alpha.png',   @() fig_w11_lead_alpha(),    95
 'w11_lead_cost.png',    @() fig_w11_lead_cost(),     95
 'w11_lead_vs_lag.png',  @() fig_w11_lead_vs_lag(),   95
 'w11_dfilter.png',      @() fig_w11_dfilter(),       95
% ---- 12주차 : 상태공간 해석 ---------------------------------------------
 'w12_transition.png',   @() fig_w12_transition(),   100
 'w12_diagonalize.png',  @() fig_w12_diagonalize(),  100
 'w12_modes.png',        @() fig_modes(),            100
 'w12_eig_map.png',      @() fig_w12_eig_map(),      100
 'w12_similarity.png',   @() fig_w12_similarity(),   100
 'w12_reach.png',        @() fig_w12_reach(),        100
 'w12_ctrb.png',         @() fig_ctrb(),             100
 'w12_obsv.png',         @() fig_obsv(),             100
 'w12_hidden_mode.png',  @() fig_w12_hidden_mode(),  100
 'w12_gateway.png',      @() fig_w12_gateway(),       95
% ---- 13주차 : 극배치 ----------------------------------------------------
 'w13_place_map.png',    @() fig_place_map(),        100
 'w13_effort.png',       @() fig_effort(),           100
 'w13_kr.png',           @() fig_kr(),               100
 'w13_coeff_match.png',  @() fig_w13_coeff_match(),  100
 'w13_servo.png',        @() fig_w13_servo(),        100
 'w13_pendulum.png',     @() fig_w13_pendulum(),      95
 'w13_nonlin_check.png', @() fig_w13_nonlin_check(),  95
 'w13_saturation.png',   @() fig_w13_saturation(),    95
% ---- 14주차 : 관측기 ----------------------------------------------------
 'w14_error_dyn.png',    @() fig_w14_error_dyn(),    100
 'w14_duality.png',      @() fig_w14_duality(),      100
 'w14_converge.png',     @() fig_obs_converge(),     100
 'w14_pole_speed.png',   @() fig_w14_pole_speed(),   100
 'w14_obs_noise.png',    @() fig_obs_noise(),        100
 'w14_separation.png',   @() fig_separation(),       100
 'w14_true_vs_est.png',  @() fig_w14_true_vs_est(),  100
 'w14_semester_arc.png', @() fig_w14_semester_arc(),  95
};

if strcmp(only, '--jobs')
    out = jobs;
    return
end

fprintf('=== 그림 만들기 ===\n');
made = 0;  nBad = 0;
for i = 1:size(jobs,1)
    name = jobs{i,1};
    if ~isempty(only) && ~contains(name, only), continue; end
    close all force;
    dg_reset();
    try
        jobs{i,2}();
        drawnow;
        % 블록선도라면 끊긴 선·겹침이 없는지 여기서 검사한다
        chk = dg_check_all(name, false);
        if ~chk.ok
            nBad = nBad + chk.nIssue;
            fprintf('  [!] %-24s 다이어그램 문제 %d 개\n', name, chk.nIssue);
            for q = 1:numel(chk.msg), fprintf('        - %s\n', chk.msg(q)); end
        end
        exportgraphics(gcf, fullfile(figdir, name), 'Resolution', jobs{i,3}, ...
                       'BackgroundColor', 'white');
        info = imfinfo(fullfile(figdir, name));
        fprintf('  [OK] %-24s %4d x %4d\n', name, info(1).Width, info(1).Height);
        made = made + 1;
    catch ME
        fprintf('  [!] %-24s %s\n', name, ME.message);
    end
end
close all force;
fprintf('  %d 개 만들었습니다 -> %s\n', made, figdir);
if nBad == 0
    fprintf('  다이어그램 검사 : 문제 없음\n\n');
else
    fprintf('  다이어그램 검사 : 문제 %d 개 (위 목록 확인)\n\n', nBad);
end
end

% ======================================================================
%  주차별 해석 그림
%  전부 "결론이 보이는 제목" 을 달아 둡니다.
% ======================================================================

function fig_gain_sweep()
s = tf('s'); G = plant_msd(); t = (0:0.02:25)';
figure('Position',[60 60 900 380]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile; hold on; grid on;
for K = [1 5 20]
    plot(t, step(feedback(K*G,1), t), 'LineWidth', 2, 'DisplayName', sprintf('K = %d', K));
end
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력'); legend('Location','southeast');
title('이득을 키우면 정확해지지만 흔들린다');
nexttile; hold on; grid on;
Ks = linspace(0.5, 40, 200); es = zeros(size(Ks)); os = es;
for i=1:numel(Ks)
    T = feedback(Ks(i)*G,1); es(i) = 1-dcgain(T);
    ii = stepinfo(T); os(i) = ii.Overshoot;
end
yyaxis left;  plot(Ks, 100*es, 'LineWidth', 2); ylabel('정상상태 오차 [%]');
yyaxis right; plot(Ks, os, 'LineWidth', 2);     ylabel('오버슈트 [%]');
xlabel('이득 K'); title('오차와 오버슈트는 반대로 움직인다');
end

function fig_disturbance()
s = tf('s'); G = plant_msd(); K = 9; t = (0:0.02:30)';
figure('Position',[60 60 900 380]);
d = 0.5*(t >= 10);
y_open = lsim(G, d, t);                       % 개루프 : 외란이 그대로
y_cl   = lsim(feedback(G, K), d, t);          % 폐루프 : G/(1+KG)
plot(t, y_open, 'LineWidth', 2); hold on;
plot(t, y_cl, 'LineWidth', 2);
xline(10, 'k:', 'LineWidth', 1.5); yline(0, 'k--'); grid on;
xlabel('시간 [s]'); ylabel('외란 때문에 생긴 출력 [m]');
legend('개루프 — 그대로 밀린다', '폐루프 — 밀어낸다', '외란 시작', 'Location','northwest');
title(sprintf('같은 외란인데 폐루프는 %.0f 배 작게 받는다', ...
      max(abs(y_open))/max(abs(y_cl))));
end

function fig_damper_sweep()
s = tf('s'); t = (0:0.02:20)'; bl = [0.2 1.0 2.0 3.0];
figure('Position',[60 60 900 380]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile; hold on; grid on;
for b = bl
    pl = pole(1/(s^2+b*s+1));
    plot(real(pl), imag(pl), 'x', 'MarkerSize',12,'LineWidth',2.5, ...
         'DisplayName', sprintf('b = %.1f', b));
end
th = linspace(0,2*pi,200); plot(cos(th), sin(th), 'k:', 'HandleVisibility','off');
xline(0,'k-','HandleVisibility','off'); yline(0,'k-','HandleVisibility','off');
axis equal; xlabel('실수부'); ylabel('허수부'); legend('Location','best');
title('극점은 반지름 1 인 원 위를 미끄러진다');
nexttile; hold on; grid on;
for b = bl
    plot(t, step(1/(s^2+b*s+1), t), 'LineWidth', 2, 'DisplayName', sprintf('b = %.1f', b));
end
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력'); legend('Location','southeast');
title('b = 2 에서 진동이 사라진다 (임계감쇠)');
end

function fig_zero_effect()
s = tf('s'); t = (0:0.02:15)';
figure('Position',[60 60 900 380]);
hold on; grid on;
for z = [0.5 2 10]
    Gz = (s+z)/(s^2+0.6*s+1); Gz = Gz/dcgain(Gz);
    plot(t, step(Gz, t), 'LineWidth', 2, 'DisplayName', sprintf('영점 s = -%.1f', z));
end
plot(t, step(1/(s^2+0.6*s+1), t), 'k--', 'LineWidth', 1.8, 'DisplayName','영점 없음');
yline(1,'k:','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력 (크기를 맞춘 값)'); legend('Location','northeast');
title('영점이 원점에 가까울수록 오버슈트가 커진다');
end

function fig_rlc_vs_rc()
s = tf('s'); t = (0:0.02:25)';
figure('Position',[60 60 850 360]);
plot(t, step(tf(1,[1 0.4 1]), t), 'LineWidth', 2); hold on;
plot(t, step(tf(1,[1 1]), t), '--', 'LineWidth', 2);
yline(1,'k:'); grid on;
xlabel('시간 [s]'); ylabel('출력 (크기를 맞춘 값)');
legend('RLC (2차) — 흔들린다','RC (1차) — 안 흔들린다','최종값','Location','southeast');
title('에너지를 저장하는 곳이 둘이면 진동한다');
end

function fig_linearize()
th = linspace(-pi/2, pi/2, 400);
figure('Position',[60 60 900 380]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile
plot(rad2deg(th), sin(th), 'LineWidth', 2.5); hold on;
plot(rad2deg(th), th, 'LineWidth', 2);
grid on; xlabel('각도 [deg]'); ylabel('값');
legend('sin\theta (진짜)','\theta (근사)','Location','southeast');
title('작은 각도에서는 두 선이 겹친다');
nexttile
dg = 1:60; err = abs(deg2rad(dg)-sin(deg2rad(dg)))./abs(sin(deg2rad(dg)))*100;
plot(dg, err, 'LineWidth', 2.5); hold on;
yline(5,'r--','LineWidth',1.5); grid on;
xlabel('각도 [deg]'); ylabel('상대오차 [%]'); ylim([0 20]);
legend('선형화 오차','5 % 기준','Location','northwest');
title('약 30도까지는 오차가 5 % 안쪽이다');
end

function fig_pend_resp()
s = tf('s'); g = 9.81; l = 0.3;
G_down = 1/(s^2 + g/l);  G_up = 1/(s^2 - g/l);
t = (0:0.005:2)';
figure('Position',[60 60 900 380]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile
plot(t, step(G_down, t), 'LineWidth', 2, 'Color',[0.15 0.45 0.2]); grid on;
xlabel('시간 [s]'); ylabel('각도 [rad]');
title('매달린 진자 : 흔들리기만 한다 (안정)');
nexttile
plot(t, step(G_up, t), 'LineWidth', 2, 'Color',[0.85 0.2 0.15]); grid on;
xlabel('시간 [s]'); ylabel('각도 [rad]');
title('거꾸로 선 진자 : 넘어간다 (불안정)');
end

function fig_zeta_sweep()
s = tf('s'); wn = 2; zl = [0.1 0.3 0.5 0.707 1.0 1.5]; t = (0:0.01:15)';
figure('Position',[60 60 950 400]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile; hold on; grid on;
for z = zl
    plot(t, step(wn^2/(s^2+2*z*wn*s+wn^2), t), 'LineWidth', 2, ...
         'DisplayName', sprintf('\\zeta = %.3g', z));
end
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력'); legend('Location','southeast');
title('감쇠비가 작을수록 많이 튄다');
nexttile; hold on; grid on;
for z = zl
    pl = pole(wn^2/(s^2+2*z*wn*s+wn^2));
    plot(real(pl), imag(pl), 'x', 'MarkerSize',12,'LineWidth',3);
end
xline(0,'k-','LineWidth',1.5); yline(0,'k:');
axis equal; xlim([-3.5 0.5]); ylim([-2.5 2.5]);
xlabel('실수부'); ylabel('허수부');
title('그때의 극점 (반지름 \omega_n 인 원 위)');
end

function fig_third_pole()
s = tf('s'); [~,~,st] = spec2pole(10,2);
den = poly([st conj(st)]); G2 = tf(den(end), den);
sig = abs(real(st)); t = (0:0.01:6)';
figure('Position',[60 60 900 380]);
hold on; grid on;
for r = [1 2 5 10]
    p = r*sig;
    plot(t, step(G2*(p/(s+p)), t), 'LineWidth', 2, ...
         'DisplayName', sprintf('세 번째 극점 = %g\\sigma', r));
end
plot(t, step(G2, t), 'k--', 'LineWidth', 2, 'DisplayName', '2차 (기준)');
yline(1,'k:','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력'); legend('Location','southeast');
title('세 번째 극점이 5 배 이상 멀면 2차로 봐도 된다');
end

function fig_gain_poles()
figure('Position',[60 60 900 400]);
hold on; grid on;
for K = linspace(0.5, 45, 240)
    r = roots([1 6 5 K]);
    plot(real(r), imag(r), '.', 'Color',[0.3 0.5 0.8], 'MarkerSize', 7);
end
r30 = roots([1 6 5 30]);
plot(real(r30), imag(r30), 'rx', 'MarkerSize', 15, 'LineWidth', 3);
xline(0,'k-','LineWidth',2);
xlabel('실수부'); ylabel('허수부');
title('K = 30 에서 극점이 허수축을 넘는다 (빨간 x = 임계이득)');
end

function fig_type_table()
s = tf('s');
Ls = { 'Type 0', 5/((s+1)*(s+5)); 'Type 1', 5/(s*(s+5)); 'Type 2', 5*(s+1)/(s^2*(s+5)) };
nm = {'계단','램프','포물선'};
tt = (0:0.05:12)'; ins = { ones(size(tt)), tt, 0.5*tt.^2 };
figure('Position',[60 60 1000 720]);
tiledlayout(3,3,'TileSpacing','compact','Padding','compact');
for a = 1:3
    for b = 1:3
        nexttile
        T = feedback(Ls{a,2},1); u = ins{b};
        if all(real(pole(T))<0), y = lsim(T,u,tt); else, y = nan(size(tt)); end
        plot(tt,u,'LineWidth',2,'Color',[0.15 0.35 0.75]); hold on;
        plot(tt,y,'LineWidth',2,'Color',[0.85 0.2 0.15]); grid on;
        ym = max([u; y(~isnan(y))]); ylim([-0.1*ym 1.15*ym]); xlim([0 12]);
        if a==1, title([nm{b} ' 입력'], 'FontSize',11); end
        if b==1, ylabel(Ls{a,1},'FontWeight','bold'); end
        if a==3, xlabel('시간 [s]'); end
        % 오차가 "커진다" 는 판정은 크기가 아니라 **끝에서 늘어나는가** 로 한다.
        % 크기로만 보면 타입 0 + 계단(오차 0.50 으로 일정) 이 잘못 걸린다.
        e  = u(end)-y(end);
        eh = u(round(end/2))-y(round(end/2));
        if isnan(e)
            s2 = '불안정';
        elseif abs(e) < 5e-3
            s2 = '오차 0';
        elseif abs(e) > abs(eh)*1.3 + 1e-6
            s2 = sprintf('오차 커짐 (%.1f -> %.1f)', eh, e);
        else
            s2 = sprintf('오차 %.2f 로 일정', e);
        end
        text(0.05,0.90,s2,'Units','normalized','FontSize',11,'FontWeight','bold', ...
             'Color',[0.3 0.3 0.3]);
    end
end
sgtitle('적분기 하나가 입력 한 단계를 감당한다','FontSize',13,'FontWeight','bold');
end

function fig_four_loci()
s = tf('s');
Ls = { 'L_a = 1/((s+1)(s+3))',        1/((s+1)*(s+3))
       'L_b = 1/(s(s+1)(s+3))',       1/(s*(s+1)*(s+3))
       'L_c = (s+2)/(s(s+1)(s+3))',   (s+2)/(s*(s+1)*(s+3))
       'L_d = 1/(s(s+1)(s+3)(s+5))',  1/(s*(s+1)*(s+3)*(s+5)) };
figure('Position',[60 60 950 700]);
tiledlayout(2,2,'TileSpacing','compact');
for i=1:4
    nexttile; rlocus(Ls{i,2}); grid on;
    xlim([-8 3]); ylim([-6 6]); title(Ls{i,1}, 'FontSize', 11);
end
sgtitle('영점을 더하면 궤적이 왼쪽으로 당겨진다 (L_b 와 L_c 를 비교)', ...
        'FontSize', 12, 'FontWeight','bold');
end

function fig_asymptote()
% [주의] 이름표를 손으로 적지 말 것. n-m 은 시스템에서 세어야 한다.
%        예전에 'n-m = 1' 처럼 적어 두었다가 전부 하나씩 어긋난 적이 있다.
s = tf('s');
D = { '(s+2)/((s+1)(s+3))',           (s+2)/((s+1)*(s+3))
      '1/((s+1)(s+3))',               1/((s+1)*(s+3))
      '1/(s(s+1)(s+3))',              1/(s*(s+1)*(s+3))
      '1/(s(s+1)(s+3)(s+5))',         1/(s*(s+1)*(s+3)*(s+5)) };
figure('Position',[60 60 950 700]);
tiledlayout(2,2,'TileSpacing','compact');
for i=1:4
    nexttile
    L = D{i,2}; pl = pole(L); zr = zero(L);
    n = numel(pl); m = numel(zr);
    sg = real((sum(pl)-sum(zr))/(n-m));
    th = (2*(0:(n-m-1))+1)*180/(n-m);
    rlocus(L); hold on;
    for q=1:numel(th)
        plot(sg+[0 20]*cosd(th(q)), [0 20]*sind(th(q)), 'r--', 'LineWidth', 1.5);
    end
    plot(sg,0,'rs','MarkerSize',9,'MarkerFaceColor','r');
    xlim([-14 6]); ylim([-10 10]); grid on;
    title(sprintf('n-m = %d : 점근선 %.0f^\\circ   (%s)', n-m, th(1), D{i,1}), ...
          'FontSize', 10.5);
end
sgtitle('n-m 이 클수록 점근선이 오른쪽으로 눕는다', 'FontSize',12,'FontWeight','bold');
end

function fig_sgrid()
s = tf('s'); G = 1/(s*(s+2)*(s+8));
[zm, wm, st] = spec2pole(20, 4);
figure('Position',[60 60 760 620]);
rlocus(G); hold on; sgrid(zm, wm);
plot(real(st), imag(st), 'p', 'MarkerSize',17,'MarkerFaceColor','m','MarkerEdgeColor','k');
plot(real(st),-imag(st), 'p', 'MarkerSize',17,'MarkerFaceColor','m','MarkerEdgeColor','k');
xlim([-12 3]); ylim([-8 8]); grid on;
title('궤적과 사양 영역이 만나는 곳이 설계점 (별표)');
end

function fig_design_fail()
s = tf('s'); G = 1/(s*(s+2)); [zm, wm] = spec2pole(10, 3);
T = rl_scan(1, G, linspace(0.2, 20, 400));
figure('Position',[60 60 950 400]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile
rlocus(G); hold on; sgrid(zm, wm);
xlim([-4 1]); ylim([-4 4]); grid on;
title('궤적이 세로 직선 : 실수부를 못 바꾼다');
nexttile
plot(T.K, T.ts, 'LineWidth', 2); hold on;
yline(3,'r--','LineWidth',1.5); grid on;
xlabel('이득 K'); ylabel('정착시간 [s]'); ylim([0 8]);
legend('실측 정착시간','요구 3 s','Location','northeast');
title('이득을 아무리 바꿔도 정착시간이 안 줄어든다');
end

function fig_pd_locus()
s = tf('s'); G = 1/(s*(s+2)*(s+8));
figure('Position',[60 60 950 420]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile; rlocus(G); grid on; xlim([-14 4]); ylim([-10 10]);
title('비례제어만 : 궤적이 오른쪽으로 휜다');
nexttile; rlocus(G*(s+3)); grid on; xlim([-14 4]); ylim([-10 10]);
title('PD (영점 s = -3) : 궤적이 왼쪽으로 당겨진다');
end

function fig_four_comp()
s = tf('s'); G = 1/(s*(s+2)); t = (0:0.02:12)';
C = { 'P    K = 1.6',              1.6
      'PD   2.7(s+3)',             2.7*(s+3)
      'Lead 14(s+3)/(s+12)',       14*(s+3)/(s+12)
      'PI   0.8(s+0.5)/s',         0.8*(s+0.5)/s };
figure('Position',[60 60 900 400]);
hold on; grid on;
for i=1:size(C,1)
    T = feedback(C{i,2}*G, 1);
    if all(real(pole(T))<0)
        plot(t, step(T,t), 'LineWidth', 2, 'DisplayName', C{i,1});
    end
end
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력'); ylim([0 1.6]); legend('Location','southeast');
title('같은 플랜트, 네 가지 보상기');
end

function fig_pz_map()
figure('Position',[60 60 1050 320]);
tiledlayout(1,4,'TileSpacing','compact');
C = { 'PD :  K(s+z)',        [],    -3,    '영점 하나를 왼쪽에'
      'Lead : K(s+z)/(s+p)', -12,   -3,    '영점 + 더 왼쪽에 극점'
      'PI :  K(s+a)/s',       0,    -0.5,  '원점에 극점 + 옆에 영점'
      'Lag : K(s+z)/(s+p)',  -0.05, -0.5,  '원점 근처 극점 + 그 오른쪽 영점' };
for i=1:4
    nexttile; hold on; grid on;
    plot(C{i,3}, 0, 'o', 'MarkerSize',13,'LineWidth',2.5,'Color',[0.15 0.45 0.2]);
    if ~isempty(C{i,2})
        plot(C{i,2}, 0, 'x', 'MarkerSize',15,'LineWidth',3,'Color',[0.85 0.2 0.15]);
    end
    xline(0,'k-','LineWidth',1.5); yline(0,'k-');
    if i<=2, xlim([-14 3]); else, xlim([-1.2 0.5]); end
    ylim([-1 1]); xlabel('실수부');
    title(sprintf('%s\n%s', C{i,1}, C{i,4}), 'FontSize', 10);
end
sgtitle('o = 영점(끌어당김),  x = 극점(밀어냄)','FontSize',12,'FontWeight','bold');
end

function fig_noise()
s = tf('s'); [G,~] = plant_dcmotor('position');
C_pd = 18.9*(s+3);  C_ld = 265*(s+2)/(s+15);
t = (0:0.001:4)';
rng(7); n = 1e-3*randn(size(t));
% 잡음이 제어입력으로 얼마나 증폭되는지 (근사 : 제어기 * 잡음)
u_pd = lsim(C_pd/(1+C_pd*G)*(s/(s/2000+1))/(s/2000+1), n, t);
u_ld = lsim(C_ld/(1+C_ld*G), n, t);
figure('Position',[60 60 900 420]);
tiledlayout(2,1,'TileSpacing','compact');
nexttile
plot(t, n, 'LineWidth', 1); grid on; ylabel('측정 잡음');
title('똑같은 잡음을 두 제어기에 넣는다');
nexttile
plot(t, u_pd, 'LineWidth', 1); hold on;
plot(t, u_ld, 'LineWidth', 1.6); grid on;
xlabel('시간 [s]'); ylabel('제어입력 요동 [V]');
legend(sprintf('PD  (표준편차 %.1f)', std(u_pd)), ...
       sprintf('Lead (표준편차 %.2f)', std(u_ld)), 'Location','northeast');
title('PD 만 제어입력이 요동친다');
end

% ======================================================================
%  9~10주차 : 주파수응답
% ======================================================================

function fig_sine_measure()
% 사인을 실제로 넣어 재 본 크기비·위상차가 bode 곡선 위에 그대로 놓인다
G  = plant_msd();
ws = [0.2 0.5 0.8 1 1.5 3 6];
mag_meas = zeros(size(ws));  ph_meas = zeros(size(ws));

for i = 1:numel(ws)
    w  = ws(i);
    Tp = 2*pi/w;
    t  = (0:Tp/400:30*Tp)';          % 정상상태에 충분히 들어가도록 길게
    u  = sin(w*t);
    y  = lsim(G, u, t);
    keep = t > t(end) - 6*Tp;        % 마지막 여섯 주기만 사용
    tt = t(keep);  uu = u(keep);  yy = y(keep);
    Fu = sum(uu.*exp(-1j*w*tt));
    Fy = sum(yy.*exp(-1j*w*tt));
    mag_meas(i) = abs(Fy)/abs(Fu);
    ph_meas(i)  = rad2deg(angle(Fy/Fu));
end

wg = logspace(-1.2, 1.2, 500);
[m, p] = bode(G, wg);
m = squeeze(m);  p = squeeze(p);

figure('Position',[60 60 900 470]);
tiledlayout(2,1,'TileSpacing','compact');

nexttile
semilogx(wg, 20*log10(m), 'LineWidth', 2.2); hold on; grid on;
semilogx(ws, 20*log10(mag_meas), 'o', 'MarkerSize', 10, 'LineWidth', 2.2, ...
         'MarkerEdgeColor', [0.85 0.25 0.15]);
ylabel('크기 [dB]');
legend('bode 가 그린 곡선', '사인을 넣어 직접 잰 값', 'Location','southwest');
title('보드 선도는 "사인 넣고 재 본 결과" 를 모아 놓은 것일 뿐이다');

nexttile
semilogx(wg, p, 'LineWidth', 2.2); hold on; grid on;
semilogx(ws, ph_meas, 'o', 'MarkerSize', 10, 'LineWidth', 2.2, ...
         'MarkerEdgeColor', [0.85 0.25 0.15]);
xlabel('주파수 [rad/s]'); ylabel('위상 [도]');
title('위상도 마찬가지다 (동그라미가 직접 잰 값)');
end


function fig_bode_asymptote()
% 인수마다 점근선을 따로 그리고 더하면 실제 곡선이 나온다
s = tf('s');
L = 10/(s*(s+1)*(0.1*s+1));
w = logspace(-2, 3, 800);

a_gain = 20*log10(10) * ones(size(w));          % 상수 이득
a_int  = -20*log10(w);                          % 적분기 1/s
a_p1   = -20*log10(max(w/1,  1));               % 극점 w = 1
a_p10  = -20*log10(max(w/10, 1));               % 극점 w = 10
a_sum  = a_gain + a_int + a_p1 + a_p10;

m = 20*log10(squeeze(abs(freqresp(L, w))));

figure('Position',[60 60 900 470]);
tiledlayout(2,1,'TileSpacing','compact');

nexttile
semilogx(w, a_gain, '--', 'LineWidth', 1.6); hold on; grid on;
semilogx(w, a_int,  '--', 'LineWidth', 1.6);
semilogx(w, a_p1,   '--', 'LineWidth', 1.6);
semilogx(w, a_p10,  '--', 'LineWidth', 1.6);
ylim([-120 40]); ylabel('크기 [dB]');
legend('상수 10 (일정)', '적분기 1/s (-20 dB/dec)', ...
       '극점 s+1 (1 부터 꺾임)', '극점 0.1s+1 (10 부터 꺾임)', ...
       'Location','southwest');
title('1단계 — 인수마다 점근선을 따로 그린다');

nexttile
semilogx(w, a_sum, '--', 'LineWidth', 2.4, 'Color', [0.85 0.25 0.15]); hold on; grid on;
semilogx(w, m, 'LineWidth', 2.2, 'Color', [0.15 0.35 0.75]);
xline(1,  ':', 'Color',[0.4 0.4 0.4]);
xline(10, ':', 'Color',[0.4 0.4 0.4]);
ylim([-120 40]); xlabel('주파수 [rad/s]'); ylabel('크기 [dB]');
legend('점근선을 다 더한 것', '실제 bode 곡선', 'Location','southwest');
title('2단계 — 더하면 실제 곡선과 거의 같다 (꺾이는 곳에서만 3 dB 차이)');
end


function fig_resonance()
% 감쇠비가 작을수록 공진 봉우리가 커지고, 그만큼 오버슈트도 커진다
s  = tf('s');
wn = 1;
zs = [0.1 0.2 0.4 0.707 1.0];
w  = logspace(-1, 1, 600);
t  = (0:0.05:30)';

figure('Position',[60 60 950 400]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile; hold on; grid on;
for z = zs
    T = wn^2/(s^2 + 2*z*wn*s + wn^2);
    semilogx(w, 20*log10(squeeze(abs(freqresp(T, w)))), 'LineWidth', 2, ...
             'DisplayName', sprintf('\\zeta = %.3g', z));
end
set(gca, 'XScale', 'log');
yline(0, 'k--', 'HandleVisibility','off');
xlabel('주파수 [rad/s]'); ylabel('크기 [dB]');
legend('Location','southwest');
title('감쇠비가 작을수록 봉우리가 높다');

nexttile; hold on; grid on;
for z = zs
    T = wn^2/(s^2 + 2*z*wn*s + wn^2);
    plot(t, step(T, t), 'LineWidth', 2, 'DisplayName', sprintf('\\zeta = %.3g', z));
end
yline(1, 'k--', 'HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력');
legend('Location','southeast');
title('같은 감쇠비가 시간영역에서는 오버슈트로 나타난다');
end


function fig_nyquist_K()
% -1 점에서 얼마나 떨어져 있는가 = 여유
s = tf('s');
G = 1/(s*(s+1)^2);
w = logspace(-2, 2, 4000);

figure('Position',[60 60 900 400]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile; hold on; grid on; axis equal;
for K = [0.5 2 3]
    fr = squeeze(freqresp(K*G, w));
    plot(real(fr), imag(fr), 'LineWidth', 2, 'DisplayName', sprintf('K = %.1f', K));
    plot(real(fr), -imag(fr), '--', 'LineWidth', 1, 'HandleVisibility','off');
end
plot(-1, 0, 'p', 'MarkerSize', 16, 'MarkerFaceColor', [0.85 0.25 0.15], ...
     'MarkerEdgeColor','k', 'DisplayName','-1 점');
xline(0,'k-','HandleVisibility','off'); yline(0,'k-','HandleVisibility','off');
xlim([-3 0.6]); ylim([-1.6 1.6]);
xlabel('실수부'); ylabel('허수부');
legend('Location','northwest');
title('K = 2 에서 궤적이 -1 점을 정확히 지난다');

nexttile; hold on; grid on;
t = (0:0.05:40)';
for K = [0.5 2 3]
    T = feedback(K*G, 1);
    if max(real(pole(T))) < 0.02
        plot(t, step(T, t), 'LineWidth', 2, 'DisplayName', sprintf('K = %.1f', K));
    end
end
yline(1, 'k--', 'HandleVisibility','off');
ylim([-0.5 2.5]); xlabel('시간 [s]'); ylabel('출력');
legend('Location','northeast');
title('그래서 K = 2 는 지속진동이 된다');
end


function fig_pm_os()
% 위상여유로 오버슈트를 짐작할 수 있다 (zeta = PM/100)
s  = tf('s');
G  = 1/(s*(s+1)^2);
Ks = linspace(0.05, 1.6, 60);

pm = zeros(size(Ks));  os = zeros(size(Ks));  os_est = zeros(size(Ks));
ws = warning('off','Control:analysis:MarginUnstable');
for i = 1:numel(Ks)
    [~, pm(i)] = margin(Ks(i)*G);
    T = feedback(Ks(i)*G, 1);
    ii = stepinfo(T);
    os(i) = ii.Overshoot;
    z = pm(i)/100;
    if z < 1 && z > 0
        os_est(i) = 100*exp(-z*pi/sqrt(1-z^2));
    else
        os_est(i) = 0;
    end
end
warning(ws);

figure('Position',[60 60 900 400]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile; hold on; grid on;
plot(pm, os,     'LineWidth', 2.4);
plot(pm, os_est, '--', 'LineWidth', 2.4);
xlabel('위상여유 [도]'); ylabel('오버슈트 [%]');
legend('실제 (stepinfo)', '공식 예측 (\zeta = PM/100)', 'Location','northeast');
title('위상여유가 크면 오버슈트가 작다');

nexttile; hold on; grid on;
plot(pm, pm/100, 'LineWidth', 2.4);
xlabel('위상여유 [도]'); ylabel('감쇠비 \zeta 추정값');
yline(0.707, 'k--');
text(20, 0.75, '\zeta = 0.707 (오버슈트 4.3 %)', 'FontSize', 10);
title('실무 기준 : 위상여유 30~60도를 확보한다');
end


function fig_bw_speed()
% 대역폭이 넓을수록 응답이 빠르다
s  = tf('s');
G  = 1/(s*(s+1)^2);
Ks = linspace(0.1, 1.5, 40);

bw = zeros(size(Ks)); tr = zeros(size(Ks)); ts = zeros(size(Ks));
for i = 1:numel(Ks)
    T = feedback(Ks(i)*G, 1);
    bw(i) = bandwidth(T);
    ii = stepinfo(T);
    tr(i) = ii.RiseTime;  ts(i) = ii.SettlingTime;
end

figure('Position',[60 60 900 400]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile; hold on; grid on;
plot(bw, tr, 'LineWidth', 2.4);
plot(bw, 1.8./bw, '--', 'LineWidth', 2);
xlabel('폐루프 대역폭 [rad/s]'); ylabel('상승시간 [s]');
legend('실제', '어림공식  t_r \approx 1.8 / \omega_{BW}', 'Location','northeast');
title('대역폭이 넓을수록 빨라진다');

nexttile; hold on; grid on;
t = (0:0.05:40)';
for K = [0.2 0.6 1.2]
    T = feedback(K*G, 1);
    plot(t, step(T, t), 'LineWidth', 2, ...
         'DisplayName', sprintf('K = %.1f  (BW %.2f)', K, bandwidth(T)));
end
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력'); legend('Location','southeast');
title('같은 이야기를 시간영역에서 보면');
end


% ======================================================================
%  11주차 : 주파수영역 설계와 PID
% ======================================================================

function fig_lead_bode()
% Lead 는 위상을 끌어올려 위상여유를 번다
s = tf('s');
G = 1/(s*(s+1));
K = 100;
[D, info] = lead_design(K, G, 50);
w = logspace(-1, 3, 800);

figure('Position',[60 60 950 470]);
tiledlayout(2,2,'TileSpacing','compact');

nexttile([1 1]);
semilogx(w, 20*log10(squeeze(abs(freqresp(K*G, w)))), 'LineWidth', 2); hold on; grid on;
semilogx(w, 20*log10(squeeze(abs(freqresp(D*G, w)))), 'LineWidth', 2);
yline(0,'k--'); ylabel('크기 [dB]'); ylim([-60 60]);
legend('보상 전 (K 만)', 'Lead 적용 후', 'Location','southwest');
title('크기 — 교차주파수가 오른쪽으로 간다');

nexttile([1 1]); hold on; grid on;
t = (0:0.002:1.2)';
plot(t, step(feedback(K*G,1), t), 'LineWidth', 2);
plot(t, step(feedback(D*G,1), t), 'LineWidth', 2);
yline(1,'k--'); xlabel('시간 [s]'); ylabel('출력');
legend('보상 전', 'Lead 적용 후', 'Location','southeast');
title(sprintf('오버슈트가 잡힌다 (위상여유 %.0f -> %.0f도)', ...
      info.PM_before, info.PM_after));

nexttile([1 1]);
semilogx(w, squeeze(angle(freqresp(K*G, w)))*180/pi, 'LineWidth', 2); hold on; grid on;
semilogx(w, unwrap(squeeze(angle(freqresp(D*G, w))))*180/pi, 'LineWidth', 2);
yline(-180,'k--'); xline(info.wm, ':', 'Color',[0.85 0.25 0.15], 'LineWidth', 1.6);
xlabel('주파수 [rad/s]'); ylabel('위상 [도]'); ylim([-200 -60]);
title(sprintf('위상 — \\omega_m = %.1f 에서 %.0f도를 밀어 올린다', info.wm, info.phi));

nexttile([1 1]);
semilogx(w, unwrap(squeeze(angle(freqresp(D/K, w))))*180/pi, 'LineWidth', 2.4, ...
         'Color', [0.85 0.25 0.15]); hold on; grid on;
xline(info.wm, ':', 'Color',[0.4 0.4 0.4], 'LineWidth', 1.6);
xlabel('주파수 [rad/s]'); ylabel('위상 [도]');
title(sprintf('Lead 보상기 자신의 위상 (\\alpha = %.3f)', info.alpha));
end


function fig_lag_bode()
% Lag 는 고주파를 낮춰 교차주파수를 왼쪽으로 옮긴다
s = tf('s');
G = 100/((s+1)*(0.2*s+1));
[D, info] = lag_design(1, G, 40);
w = logspace(-2, 3, 800);

figure('Position',[60 60 950 440]);
tiledlayout(2,2,'TileSpacing','compact');

nexttile;
semilogx(w, 20*log10(squeeze(abs(freqresp(G, w)))), 'LineWidth', 2); hold on; grid on;
semilogx(w, 20*log10(squeeze(abs(freqresp(D*G, w)))), 'LineWidth', 2);
yline(0,'k--'); xline(info.wc_new, ':', 'Color',[0.85 0.25 0.15], 'LineWidth',1.6);
ylabel('크기 [dB]'); ylim([-60 60]);
legend('보상 전', 'Lag 적용 후', 'Location','southwest');
title('고주파만 낮춘다 — 저주파(정상상태)는 그대로');

nexttile; hold on; grid on;
t = (0:0.005:4)';
plot(t, step(feedback(G,1), t), 'LineWidth', 2);
plot(t, step(feedback(D*G,1), t), 'LineWidth', 2);
yline(1,'k--'); xlabel('시간 [s]'); ylabel('출력');
legend('보상 전', 'Lag 적용 후', 'Location','southeast');
title(sprintf('진동이 잦아든다 (위상여유 %.0f -> %.0f도)', ...
      info.PM_before, info.PM_after));

nexttile;
semilogx(w, unwrap(squeeze(angle(freqresp(G, w))))*180/pi, 'LineWidth', 2); hold on; grid on;
semilogx(w, unwrap(squeeze(angle(freqresp(D*G, w))))*180/pi, 'LineWidth', 2);
yline(-180,'k--'); xline(info.wc_new, ':', 'Color',[0.85 0.25 0.15], 'LineWidth',1.6);
xlabel('주파수 [rad/s]'); ylabel('위상 [도]');
title('교차주파수가 왼쪽으로 가면 위상여유가 늘어난다');

nexttile;
semilogx(w, 20*log10(squeeze(abs(freqresp(D, w)))), 'LineWidth', 2.4, ...
         'Color',[0.85 0.25 0.15]); hold on; grid on;
xlabel('주파수 [rad/s]'); ylabel('크기 [dB]');
title(sprintf('Lag 보상기 자신 (\\beta = %.1f, 고주파를 %.1f dB 낮춘다)', ...
      info.beta, info.attn_dB));
end


function fig_w05_type_signal()
% 적분기가 "기억한다" — 정상상태에서 루프 각 지점의 값을 따라가 본다
%   [배치 주의] 위아래 두 개의 독립된 루프다. 바깥으로 나가는 화살표는
%              도화지 좌우 끝까지 그어야 dg_check 가 끊긴 끝점으로 안 본다.
W = 15.2; H = 9.4;
dg_new(W, H, '정상상태에서 루프를 한 바퀴 따라가 보면');
set(gcf, 'Position', [60 60 1120 700]);

yU = 7.0;  yL = 2.6;

% ===== 위 : 비례만 (타입 0)
sU = dg_sum(3.0, yU);
cU = dg_block( 6.3, yU, 2.6, 1.3, 'K_p = 4', [0.93 0.93 0.93]);
pU = dg_block(10.4, yU, 2.6, 1.3, 'G(s)',     [0.93 0.93 0.93]);
dg_arrow([0.4 yU], sU.L, 'r = 1');
dg_arrow(sU.R, cU.L, 'e = 0.2');
dg_arrow(cU.R, pU.L, 'u = 0.8');
dg_arrow(pU.R, [14.8 yU], 'y = 0.8');
dg_arrow([13.0 yU], [13.0 yU-1.5], '');
dg_arrow([13.0 yU-1.5], [3.0 yU-1.5], '');
dg_arrow([3.0 yU-1.5], sU.B, '');
text(0.5, yU+1.5, '비례만  (타입 0)', 'FontSize', 13, 'FontWeight','bold', ...
     'Color', [0.75 0.20 0.15]);
text(6.3, yU-2.45, 'u 를 만들려면 e 가 남아 있어야 한다.  u = K_p e', ...
     'FontSize', 11.5, 'Color', [0.75 0.20 0.15], 'HorizontalAlignment','center');

% ===== 아래 : 비례 + 적분 (타입 1)
sL = dg_sum(3.0, yL);
cL = dg_block( 6.3, yL, 2.6, 1.3, 'K_p + K_i/s', [0.88 0.96 0.88]);
pL = dg_block(10.4, yL, 2.6, 1.3, 'G(s)',        [0.93 0.93 0.93]);
dg_arrow([0.4 yL], sL.L, 'r = 1');
dg_arrow(sL.R, cL.L, 'e = 0');
dg_arrow(cL.R, pL.L, 'u = 1');
dg_arrow(pL.R, [14.8 yL], 'y = 1');
dg_arrow([13.0 yL], [13.0 yL-1.5], '');
dg_arrow([13.0 yL-1.5], [3.0 yL-1.5], '');
dg_arrow([3.0 yL-1.5], sL.B, '');
text(0.5, yL+1.5, '비례 + 적분  (타입 1)', 'FontSize', 13, 'FontWeight','bold', ...
     'Color', [0.15 0.50 0.20]);
text(6.3, yL-2.45, ['e = 0 인데 u = 1 이다.  적분기가 지나간 오차를 ' ...
                    '쌓아 두고 있기 때문이다'], ...
     'FontSize', 11.5, 'Color', [0.15 0.50 0.20], 'HorizontalAlignment','center');
end


function fig_w11_multistage()
% 한 단으로 모자란 사양 — 단을 늘리면 되지만 수확이 점점 줄어든다
%   W11_01_lead_design.m 의 5절과 같은 설정 (강의자료 예제 7-3)
s = tf('s');
G3 = 1/(s*(s+1)*(s/5+1));
K3 = 5;  target = 55;

t3 = (0:0.01:6)';
Dc = tf(K3);
Ds = {Dc};  pm = zeros(1,4);  al = nan(1,4);  od = zeros(1,4);
[~, pm(1)] = margin(Dc*G3);  od(1) = order(Dc);
for k = 1:3
    if k == 1, [Dc, ik] = lead_design(K3, G3, target, 5);
    else,      [Dk, ik] = lead_design(1, Dc*G3, target, 5);  Dc = Dc*Dk;
    end
    [~, pm(k+1)] = margin(Dc*G3);
    al(k+1) = ik.alpha;  od(k+1) = order(Dc);
    Ds{end+1} = Dc; %#ok<AGROW>
end

figure('Position',[60 60 1060 430]);
tiledlayout(1,2,'TileSpacing','compact');

% ---- 왼쪽 : 단을 늘려 가며 응답
nexttile; hold on; grid on
for k = 1:numel(Ds)
    if k == 1, lb = sprintf('보상 전 (PM %.0f\\circ)', pm(k));
    else,      lb = sprintf('Lead %d 단 (PM %.0f\\circ)', k-1, pm(k));
    end
    plot(t3, step(feedback(Ds{k}*G3, 1), t3), 'LineWidth', 2.2, 'DisplayName', lb);
end
yline(1, 'k--', 'HandleVisibility','off');
ylim([0 2]); xlabel('시간 [s]'); ylabel('출력');
legend('Location','southeast');
title('한 단으로 모자라면 나눠서 올린다');

% ---- 오른쪽 : 무엇을 얻고 무엇을 내주는가
nexttile; hold on; grid on
yyaxis left
plot(0:3, pm, 'o-', 'LineWidth', 2.6, 'MarkerSize', 8, 'MarkerFaceColor','w');
yline(target, '--', 'LineWidth', 1.4, 'HandleVisibility','off');
text(2.05, target+3.5, sprintf('목표 %d\\circ', target), 'FontSize', 11);
ylabel('위상여유 [\circ]'); ylim([0 70]);
yyaxis right
plot(0:3, od, 's-', 'LineWidth', 2.6, 'MarkerSize', 8, 'MarkerFaceColor','w');
ylabel('보상기 차수'); ylim([0 4]);
xlabel('Lead 단 수'); xlim([-0.2 3.2]); xticks(0:3);
title('한 단마다 올라가는 폭이 줄고 차수는 그대로 늘어난다');
end


function fig_w11_design_steps()
% 주파수영역 설계 다섯 단계 — 6주차 근궤적 여섯 단계와 짝이 된다
W = 16.4; H = 7.6;
dg_new(W, H, '주파수영역 설계 : 순서를 바꾸면 앞 단계가 무너진다');
set(gcf, 'Position', [60 60 1180 560]);

cLow = [0.88 0.93 1.00];      % 저주파가 정하는 단계
cMid = [1.00 0.94 0.86];      % 교차주파수가 정하는 단계
cChk = [1.00 0.88 0.85];      % 자주 빠뜨리는 단계

yT = 5.5;  yB = 2.3;
b1 = dg_block( 3.4, yT, 4.0, 1.6, '', cLow);
b2 = dg_block( 8.5, yT, 4.0, 1.6, '', cMid);
b3 = dg_block(13.6, yT, 4.0, 1.6, '', cMid);
% 아래 줄은 위 줄과 x 를 맞춘다. 세로 연결선을 블록 한가운데로 떨어뜨려야
% 끊긴 끝점이나 관통으로 잡히지 않는다 (dg_design_steps 와 같은 배치).
b4 = dg_block(13.6, yB, 4.0, 1.6, '', cMid);
b5 = dg_block( 8.5, yB, 4.0, 1.6, '', cChk);

local_fs(b1, '① 이득 K 를 정한다', 'Kv \geq 100  ->  K \geq 100');
local_fs(b2, '② 위상여유를 잰다', 'margin(K*G)');
local_fs(b3, '③ 모자란 양을 센다', '\phi = 목표 - 현재 + 여유');
local_fs(b4, '④ 보상기를 만든다', 'lead\_design(...)');
local_fs(b5, '⑤ 검증한다', 'margin, step, 그리고 u(t)');

dg_arrow([0.3 yT], b1.L, '사양');
dg_arrow(b1.R, b2.L, '');
dg_arrow(b2.R, b3.L, '');
dg_arrow(b3.B, b4.T, '');
dg_arrow(b4.L, b5.R, '');
dg_arrow(b5.L, [0.3 yB], '완료');

text(8.5, 4.0, ['① 은 저주파,  ②~④ 는 교차주파수 근처 — ' ...
                '대역이 달라서 뒤 단계가 앞 단계를 안 망친다'], ...
     'FontSize', 11.5, 'Color', [0.20 0.20 0.20], 'HorizontalAlignment','center');
text(8.5, 0.7, '⑤ 를 빼먹으면 종이 위에서만 맞는 설계가 된다 (6주차와 같다)', ...
     'HorizontalAlignment','center', 'FontSize', 10.5, 'Color', [0.75 0.20 0.15]);
end

function local_fs(b, top, bot)
text(b.C(1), b.C(2)+0.30, top, 'HorizontalAlignment','center', ...
     'FontSize', 12, 'FontWeight','bold');
text(b.C(1), b.C(2)-0.36, bot, 'HorizontalAlignment','center', ...
     'FontSize', 10, 'Color', [0.15 0.35 0.65]);
end


function fig_w11_pid_bands()
% PID 의 세 항이 주파수축을 나누어 맡는다 — "PID = Lead + Lag" 의 그림판
s  = tf('s');
% 세 대역이 눈에 띄게 갈리도록 꺾이는 두 주파수를 두 자리수 떨어뜨린다
%   w_I = Ki/Kp = 0.1 ,  w_D = Kp/Kd = 10
Kp = 2;  Ki = 0.2;  Kd = 0.2;
w  = logspace(-3, 4, 700);

mI = squeeze(abs(freqresp(Ki/s,   w)));
mP = squeeze(abs(freqresp(tf(Kp), w)));
mD = squeeze(abs(freqresp(Kd*s,   w)));
C  = Kp + Ki/s + Kd*s;
[mC, pC] = bode(C, w);
mC = squeeze(mC);  pC = squeeze(pC);

wI = Ki/Kp;        % 여기 아래로는 I 가 이긴다
wD = Kp/Kd;        % 여기 위로는 D 가 이긴다

figure('Position',[60 60 1000 520]);
tiledlayout(2,1,'TileSpacing','compact');

% ---- 크기
nexttile; hold on; grid on
yl = [1e-2 1e3];
patch([w(1) wI wI w(1)], [yl(1) yl(1) yl(2) yl(2)], [0.88 0.93 1.00], ...
      'EdgeColor','none', 'HandleVisibility','off');
patch([wD w(end) w(end) wD], [yl(1) yl(1) yl(2) yl(2)], [1.00 0.90 0.86], ...
      'EdgeColor','none', 'HandleVisibility','off');
plot(w, mI, '--', 'LineWidth', 1.8, 'Color',[0.15 0.35 0.75], 'DisplayName','I 항  K_i/s');
plot(w, mP, '--', 'LineWidth', 1.8, 'Color',[0.35 0.35 0.35], 'DisplayName','P 항  K_p');
plot(w, mD, '--', 'LineWidth', 1.8, 'Color',[0.85 0.20 0.15], 'DisplayName','D 항  K_d s');
plot(w, mC, '-',  'LineWidth', 3.0, 'Color',[0.10 0.10 0.10], 'DisplayName','PID 합');
set(gca,'XScale','log','YScale','log'); ylim(yl); xlim([w(1) w(end)]);
xline(wI, 'k:', 'LineWidth', 1.4, 'HandleVisibility','off');
xline(wD, 'k:', 'LineWidth', 1.4, 'HandleVisibility','off');
ylabel('크기'); legend('Location','southwest','Orientation','horizontal');
text(w(1)*2.0, 3e2, '저주파 : I 가 지배', 'FontSize', 11, ...
     'Color',[0.15 0.35 0.75], 'FontWeight','bold');
text(w(1)*4.0, 1.0e2, '(Lag 역할)', 'FontSize', 10.5, 'Color',[0.15 0.35 0.75]);
text(sqrt(wI*wD), 3e2, '중간 : P', 'FontSize', 11, 'FontWeight','bold', ...
     'Color',[0.30 0.30 0.30], 'HorizontalAlignment','center');
text(wD*3.0, 3e2, '고주파 : D 가 지배', 'FontSize', 11, ...
     'Color',[0.85 0.20 0.15], 'FontWeight','bold');
text(wD*3.0, 1.0e2, '(Lead 역할)', 'FontSize', 10.5, 'Color',[0.85 0.20 0.15]);
title('세 항이 주파수축을 나누어 맡는다');

% ---- 위상
nexttile; hold on; grid on
plot(w, pC, 'LineWidth', 2.6, 'Color',[0.10 0.10 0.10]);
set(gca,'XScale','log'); xlim([w(1) w(end)]); ylim([-95 95]);
yticks(-90:45:90);
yline(0, 'k:', 'HandleVisibility','off');
xline(wI, 'k:', 'LineWidth', 1.4); xline(wD, 'k:', 'LineWidth', 1.4);
text(wI*1.3, -72, sprintf('\\omega = K_i/K_p = %.1f', wI), 'FontSize', 10.5);
text(wD*1.3,  62, sprintf('\\omega = K_p/K_d = %.0f', wD), 'FontSize', 10.5);
xlabel('주파수 [rad/s]'); ylabel('위상 [\circ]');
title('저주파는 -90\circ (적분), 고주파는 +90\circ (미분)');
end


function fig_pid_compare()
% P, PI, PID 를 같은 플랜트에 나란히
s = tf('s');
G = plant_dcmotor('speed');
t = (0:0.005:4)';

C_p   = 100;
C_pi  = 100 + 200/s;
C_pid = 100 + 200/s + 10*s/(s/100 + 1);      % 미분항에는 필터를 붙인다

figure('Position',[60 60 950 400]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile; hold on; grid on;
plot(t, step(feedback(C_p*G,1),   t), 'LineWidth', 2, 'DisplayName','P');
plot(t, step(feedback(C_pi*G,1),  t), 'LineWidth', 2, 'DisplayName','PI');
plot(t, step(feedback(C_pid*G,1), t), 'LineWidth', 2, 'DisplayName','PID');
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('각속도 [rad/s]');
legend('Location','southeast');
title('I 가 오차를 없애고, D 가 진동을 잡는다');

nexttile; hold on; grid on;
plot(t, step(feedback(C_p,G)*1,   t), 'LineWidth', 2, 'DisplayName','P');
plot(t, step(feedback(C_pi,G)*1,  t), 'LineWidth', 2, 'DisplayName','PI');
plot(t, step(feedback(C_pid,G)*1, t), 'LineWidth', 2, 'DisplayName','PID');
xlabel('시간 [s]'); ylabel('제어입력 u [V]');
legend('Location','northeast');
title('공짜가 아니다 — 제어입력도 함께 본다');
end


function fig_windup()
% 적분 와인드업과 그 처방
[~, p] = plant_dcmotor('speed');
A = p.A;  B = p.B;  C = p.C;
Kp = 60;  Ki = 400;  umax = 15;            % 구동기가 낼 수 있는 전압 [V]
dt = 1e-4;  T = 2.5;  n = round(T/dt);
r  = 1;                                     % 목표 1 rad s^-1 (정상상태에 약 10 V 필요)

res = cell(1,2);
for mode = 1:2                              % 1 = 그냥, 2 = anti-windup
    x = zeros(2,1);  xi = 0;
    Y = zeros(n,1);  U = zeros(n,1);  XI = zeros(n,1);
    for k = 1:n
        y  = C*x;
        e  = r - y;
        uu = Kp*e + Ki*xi;
        us = min(max(uu, -umax), umax);
        % 적분기 갱신
        if mode == 1
            xi = xi + e*dt;                            % 무조건 쌓는다
        else
            if (us == uu) || (sign(e) ~= sign(uu))     % 포화 중이면 멈춘다
                xi = xi + e*dt;
            end
        end
        x = x + (A*x + B*us)*dt;
        Y(k) = y;  U(k) = us;  XI(k) = xi;
    end
    res{mode} = struct('Y',Y, 'U',U, 'XI',XI);
end
t = (0:n-1)'*dt;

figure('Position',[60 60 950 470]);
tiledlayout(2,2,'TileSpacing','compact');

nexttile; hold on; grid on;
plot(t, res{1}.Y, 'LineWidth', 2);
plot(t, res{2}.Y, 'LineWidth', 2);
yline(r,'k--'); ylabel('각속도 [rad/s]');
legend('그냥 PI', 'anti-windup', 'Location','southeast');
title('와인드업이 있으면 크게 넘어갔다 늦게 돌아온다');

nexttile; hold on; grid on;
plot(t, res{1}.XI, 'LineWidth', 2);
plot(t, res{2}.XI, 'LineWidth', 2);
ylabel('적분기에 쌓인 값');
title('원인 — 포화 중에도 적분기가 계속 쌓인다');

nexttile; hold on; grid on;
plot(t, res{1}.U, 'LineWidth', 2);
plot(t, res{2}.U, 'LineWidth', 2);
yline(umax,'k:'); yline(-umax,'k:');
xlabel('시간 [s]'); ylabel('제어입력 u [V]');
title(sprintf('구동기 한계 %.0f V 에 오래 붙어 있다', umax));

nexttile; hold on; grid on;
plot(t, r - res{1}.Y, 'LineWidth', 2);
plot(t, r - res{2}.Y, 'LineWidth', 2);
yline(0,'k--'); xlabel('시간 [s]'); ylabel('오차 e');
title('처방 — 포화 중에는 적분을 멈춘다 (clamping)');
end


% ======================================================================
%  12주차 : 상태공간 해석
% ======================================================================

function fig_w12_transition()
% 상태천이행렬이 하는 일 : 지금 상태를 넣으면 t 초 뒤 상태를 돌려준다
A = [0 1; -2 -3];
[V, D] = eig(A);  lam = diag(D);
tf_end = 3;  tv = linspace(0, tf_end, 400);

figure('Position',[60 60 1060 440]);
tiledlayout(1,2,'TileSpacing','compact');

% ---- 왼쪽 : 상태평면
nexttile
hold on; grid on
% 흐름 방향 화살표 (벡터장)
[X1, X2] = meshgrid(linspace(-1.2,1.2,13), linspace(-1.6,1.6,13));
DX = A(1,1)*X1 + A(1,2)*X2;
DY = A(2,1)*X1 + A(2,2)*X2;
nrm = hypot(DX, DY);  nrm(nrm==0) = 1;
quiver(X1, X2, DX./nrm, DY./nrm, 0.45, 'Color',[0.80 0.80 0.85], ...
       'HandleVisibility','off');
% 고유벡터 방향 직선
for i = 1:2
    v = V(:,i)/norm(V(:,i));
    plot([-1.4 1.4]*v(1), [-1.4 1.4]*v(2), '--', 'LineWidth', 2, ...
         'DisplayName', sprintf('고유벡터 (\\lambda = %.0f)', lam(i)));
end
% 여러 초기조건의 궤적
x0s = [1 0.9; -1 0.6; 0.4 1.4; -0.4 -1.4].';
for k = 1:size(x0s,2)
    xt = zeros(2, numel(tv));
    for j = 1:numel(tv), xt(:,j) = expm(A*tv(j))*x0s(:,k); end
    if k == 1
        plot(xt(1,:), xt(2,:), 'LineWidth', 2.2, 'Color',[0.00 0.45 0.74], ...
             'DisplayName', '상태 궤적');
    else
        plot(xt(1,:), xt(2,:), 'LineWidth', 2.2, 'Color',[0.00 0.45 0.74], ...
             'HandleVisibility','off');
    end
    plot(xt(1,1), xt(2,1), 'o', 'MarkerSize', 8, 'LineWidth', 2, ...
         'Color',[0.85 0.20 0.15], 'HandleVisibility','off');
end
plot(0, 0, 'kp', 'MarkerSize', 14, 'MarkerFaceColor','k', 'HandleVisibility','off');
xlim([-1.4 1.4]); ylim([-1.7 1.7]);
xlabel('x_1'); ylabel('x_2');
legend('Location','northeast');
title('상태평면 궤적 : 초기 상태에서 평형점으로 수렴');

% ---- 오른쪽 : 같은 것을 시간으로
nexttile
hold on; grid on
x0 = [1; 0.9];
xt = zeros(2, numel(tv));
for j = 1:numel(tv), xt(:,j) = expm(A*tv(j))*x0; end
plot(tv, xt(1,:), 'LineWidth', 2.6, 'Color',[0.00 0.45 0.74]);
plot(tv, xt(2,:), 'LineWidth', 2.6, 'Color',[0.85 0.33 0.10]);
for tq = [0 0.5 1.5]
    xq = expm(A*tq)*x0;
    plot([tq tq], [xq(1) xq(2)], 'k:', 'LineWidth', 1.2, 'HandleVisibility','off');
    plot(tq, xq(1), 'o', 'MarkerSize', 8, 'LineWidth', 1.8, ...
         'Color',[0.00 0.45 0.74], 'HandleVisibility','off');
    plot(tq, xq(2), 'o', 'MarkerSize', 8, 'LineWidth', 1.8, ...
         'Color',[0.85 0.33 0.10], 'HandleVisibility','off');
    text(tq+0.05, 1.15, sprintf('t=%.1f', tq), 'FontSize', 9);
end
yline(0, 'k:', 'HandleVisibility','off');
xlabel('시간 [s]'); ylabel('상태');
legend('x_1(t)', 'x_2(t)', 'Location','northeast');
title('상태천이행렬 e^{At} 가 지정하는 시각 t 에서의 상태');
end


function fig_w12_eig_map()
% 고유값이 s 평면 어디에 있으면 응답이 어떻게 생기는가 — 오늘의 지도
lam = {-2, -0.5, 0, 0.7, -0.4+3i, 3i};
nm  = {'-2 : 빠르게 사라진다', '-0.5 : 느리게 사라진다', ...
       '0 : 그대로 남는다', '+0.7 : 커진다', ...
       '-0.4 \pm 3j : 흔들리며 사라진다', '\pm 3j : 계속 흔들린다'};
ok  = [1 1 0 0 1 0];      % 1 = 안정에 기여, 0 = 아님
% 커지는 모드는 6 초까지 그리면 화면을 뚫고 나간다. 칸마다 시간과 범위를 달리 잡는다.
tEnd = [6 6 6 3 6 6];
yLim = {[-1.6 1.6], [-1.6 1.6], [-1.6 1.6], [-1 9], [-1.6 1.6], [-1.6 1.6]};

figure('Position',[60 60 1180 520]);
tiledlayout(3, 4, 'TileSpacing','compact');

% ---- 왼쪽 : s 평면
nexttile([3 2]); hold on; grid on
fill([-4 0 0 -4], [-5 -5 5 5], [0.90 0.96 0.90], 'EdgeColor','none');
fill([0 2.2 2.2 0], [-5 -5 5 5], [1.00 0.92 0.90], 'EdgeColor','none');
xline(0, 'k-', 'LineWidth', 1.6); yline(0, 'k-', 'LineWidth', 1.0);
for i = 1:numel(lam)
    L = lam{i};
    if ok(i), cc = [0.10 0.45 0.20]; else, cc = [0.80 0.15 0.12]; end
    plot(real(L), imag(L), 'x', 'MarkerSize', 15, 'LineWidth', 3, 'Color', cc);
    if imag(L) ~= 0
        plot(real(L), -imag(L), 'x', 'MarkerSize', 15, 'LineWidth', 3, 'Color', cc);
    end
    % 원점 부근은 표가 겹치므로 번호를 아래쪽으로 내린다
    if abs(real(L)) < 1e-9 && imag(L) == 0, dy = -0.62; else, dy = 0.42; end
    text(real(L)+0.18, imag(L)+dy, sprintf('%d', i), 'FontSize', 13, ...
         'FontWeight','bold', 'Color', cc);
end
xlim([-4 2.2]); ylim([-4.6 4.6]);
xlabel('실수부 \sigma'); ylabel('허수부 j\omega');
text(-2.0, 4.1, '좌반면 : 사라진다', 'FontSize', 12, 'FontWeight','bold', ...
     'Color', [0.10 0.45 0.20], 'HorizontalAlignment','center');
text( 1.1, 4.1, '우반면 : 커진다', 'FontSize', 12, 'FontWeight','bold', ...
     'Color', [0.80 0.15 0.12], 'HorizontalAlignment','center');
title('고유값의 자리가 모드의 성격을 정한다');

% ---- 오른쪽 : 각 고유값이 만드는 모드
for i = 1:numel(lam)
    nexttile; hold on; grid on
    t = linspace(0, tEnd(i), 600);
    y = real(exp(lam{i}*t));
    if ok(i), cc = [0.10 0.45 0.20]; else, cc = [0.80 0.15 0.12]; end
    plot(t, y, 'LineWidth', 2.2, 'Color', cc);
    yline(0, 'k:');
    ylim(yLim{i}); xlim([0 tEnd(i)]);
    if i == 4, set(gca, 'YTick', [0 4 8]); else, set(gca, 'YTick', [-1 0 1]); end
    if i >= 5, xlabel('시간 [s]'); end
    title(sprintf('%d.  %s', i, nm{i}), 'FontSize', 10.5, 'FontWeight','normal');
end
end


function fig_w12_diagonalize()
% 대각화가 e^{At} 계산을 왜 쉽게 만드는가
W = 16.0; H = 8.6;
dg_new(W, H, '대각화 : 어려운 행렬 지수함수를 스칼라 지수함수 두 개로');
set(gcf, 'Position', [60 60 1180 640]);

cHard = [1.00 0.90 0.86];
cEasy = [0.88 0.96 0.88];
cMid  = [0.93 0.93 0.93];

yT = 6.4;  yB = 2.4;
h1 = dg_block( 3.0, yT, 4.6, 1.8, '', cHard);
h2 = dg_block(13.0, yT, 4.6, 1.8, '', cHard);
e1 = dg_block( 3.0, yB, 4.6, 1.8, '', cMid);
e2 = dg_block(13.0, yB, 4.6, 1.8, '', cEasy);

local_dg2(h1, 'A', '섞여 있는 행렬');
local_dg2(h2, 'e^{At}', '급수를 무한히 더해야 한다');
local_dg2(e1, '\Lambda = V^{-1} A V', '대각행렬');
local_dg2(e2, 'e^{\Lambda t} = diag(e^{\lambda_1 t}, e^{\lambda_2 t})', '지수함수를 그냥 쓰면 된다');

dg_arrow(h1.R, h2.L, '어렵다');
dg_arrow(h1.B, e1.T, '');
dg_arrow(e1.R, e2.L, '쉽다');
dg_arrow(e2.T, h2.B, '');

text(1.0, (yT+yB)/2, 'V^{-1}( )V', 'FontSize', 12.5, 'Color', [0.15 0.35 0.75], ...
     'HorizontalAlignment','center', 'FontWeight','bold');
text(15.1, (yT+yB)/2, 'V( )V^{-1}', 'FontSize', 12.5, 'Color', [0.15 0.35 0.75], ...
     'HorizontalAlignment','center', 'FontWeight','bold');

text(W/2, 0.9, ['왼쪽 아래로 돌아가면 계산이 스칼라 두 개로 줄어든다.   ' ...
                'e^{At} = V e^{\Lambda t} V^{-1}'], ...
     'HorizontalAlignment','center', 'FontSize', 12.5, 'FontWeight','bold', ...
     'Color', [0.20 0.20 0.20]);
end

function local_dg2(b, top, bot)
text(b.C(1), b.C(2)+0.34, top, 'HorizontalAlignment','center', ...
     'FontSize', 14, 'FontWeight','bold');
text(b.C(1), b.C(2)-0.42, bot, 'HorizontalAlignment','center', ...
     'FontSize', 10.5, 'Color', [0.35 0.35 0.35]);
end


function fig_w12_reach()
% 가제어성의 기하학적 뜻 : B 와 AB 가 평면을 덮는가
A  = [0 1; -2 -3];
Bc = [0; 1];        % 가제어
Bu = [1; -1];       % A 의 고유벡터 방향 -> 못 벗어난다

figure('Position',[60 60 1060 440]);
tiledlayout(1,2,'TileSpacing','compact');

local_reach(A, Bc, '가제어 : rank = 2');
local_reach(A, Bu, '가제어 아님 : rank = 1');
end

function local_reach(A, B, ttl)
nexttile; hold on; grid on; axis equal
AB = A*B;
r  = rank(ctrb(A,B));

% 입력을 여러 가지로 넣었을 때 실제로 도달한 상태들
t = linspace(0, 3, 300);
rng(7);
for k = 1:24
    u = interp1(linspace(0,3,7), 4*randn(1,7), t, 'pchip');
    x = lsim(ss(A, B, eye(2), [0;0]), u, t, [0;0]);
    plot(x(:,1), x(:,2), '-', 'Color', [0.55 0.70 0.88 0.55], ...
         'LineWidth', 1.0, 'HandleVisibility','off');
end

sc = 1.6;
quiver(0, 0, sc*B(1),  sc*B(2),  0, 'LineWidth', 3, 'MaxHeadSize', 0.6, ...
       'Color', [0.85 0.20 0.15], 'DisplayName', 'B  (지금 미는 방향)');
quiver(0, 0, sc*AB(1)/norm(AB)*norm(B), sc*AB(2)/norm(AB)*norm(B), 0, ...
       'LineWidth', 3, 'MaxHeadSize', 0.6, ...
       'Color', [0.15 0.35 0.75], 'DisplayName', 'AB (다음 순간 흐르는 방향)');
plot(0, 0, 'kp', 'MarkerSize', 13, 'MarkerFaceColor','k', 'HandleVisibility','off');

xlim([-4 4]); ylim([-4 4]);
xlabel('x_1'); ylabel('x_2');
legend('Location','southoutside', 'Orientation','horizontal');
title(sprintf('%s   (rank(ctrb) = %d)', ttl, r));
end


function fig_w12_hidden_mode()
% 상쇄된 불안정 모드는 출력에 안 보이는 채로 상태에서 발산한다
%   7주차 3-1 절의 그 예제를 이번에는 고유값으로 설명한다
s = tf('s');
G = 1/(s-1);                       % 불안정 플랜트
C = 7*(s-1)/(s+4);                 % 제어기 영점으로 상쇄를 시도
CL = ss(feedback(C*G, 1));         % 폐루프 (상태공간으로)

t = linspace(0, 8, 800)';
r = ones(size(t));
n = size(CL.A, 1);
[y, ~, X] = lsim(CL, r, t, 0.01*ones(n,1));    % 상태를 0.01 만 건드려 둔다

figure('Position',[60 60 1060 430]);
tiledlayout(1,2,'TileSpacing','compact');

% ---- 왼쪽 : 출력만 보면 아무 문제가 없다
nexttile; hold on; grid on
plot(t, y, 'LineWidth', 2.8, 'Color',[0.00 0.45 0.74]);
xlabel('시간 [s]'); ylabel('출력 y');
ylim([0 1.0]);
text(1.0, 0.30, sprintf('정상상태 %.3f 에서 꼼짝도 안 한다', y(end)), ...
     'FontSize', 11.5, 'Color',[0.15 0.35 0.65]);
title('출력만 보면 — 완벽하게 안정해 보인다');

% ---- 오른쪽 : 같은 시뮬레이션의 내부 상태
nexttile; hold on; grid on
plot(t, X(:,1), 'LineWidth', 2.4, 'Color',[0.85 0.20 0.15]);
plot(t, X(:,2), 'LineWidth', 2.4, 'Color',[0.90 0.55 0.10]);
set(gca, 'YScale', 'log');
ylim([1e-2 1e5]);
xlabel('시간 [s]'); ylabel('내부 상태 (로그 눈금)');
legend('x_1', 'x_2', 'Location','southeast');
ev = sort(eig(CL.A), 'descend', 'ComparisonMethod','real');
text(0.4, 2.5e4, sprintf('폐루프 고유값 : %s', mat2str(round(ev.', 3))), ...
     'FontSize', 11.5, 'FontWeight','bold', 'Color',[0.85 0.20 0.15]);
text(0.4, 8e3, sprintf('rank(obsv) = %d / %d  ->  +1 이 출력에 안 보인다', ...
     rank(obsv(CL.A, CL.C)), n), 'FontSize', 11, 'Color',[0.35 0.35 0.35]);
title('같은 순간 내부에서는 — e^{+t} 로 발산하고 있다');
end


function fig_w12_gateway()
% 오늘의 두 판정이 다음 두 주의 입장권이다
W = 15.8; H = 9.2;
dg_new(W, H, '오늘 판정한 두 가지가 13·14주차의 입장권이다');
set(gcf, 'Position', [60 60 1160 680]);

cQ  = [0.93 0.93 0.93];
cOK = [0.88 0.96 0.88];
cNG = [1.00 0.90 0.86];

q1 = dg_block( 3.2, 6.9, 4.4, 1.5, '', cQ);
q2 = dg_block( 3.2, 2.6, 4.4, 1.5, '', cQ);
a1 = dg_block(11.6, 7.8, 5.6, 1.4, '', cOK);
n1 = dg_block(11.6, 5.9, 5.6, 1.4, '', cNG);
a2 = dg_block(11.6, 3.5, 5.6, 1.4, '', cOK);
n2 = dg_block(11.6, 1.6, 5.6, 1.4, '', cNG);

local_gw(q1, 'rank(ctrb(A,B)) = n ?', '가제어성');
local_gw(q2, 'rank(obsv(A,C)) = n ?', '가관측성');
text(a1.C(1), a1.C(2), '13주차 극배치 — 극점을 원하는 자리로', ...
     'HorizontalAlignment','center', 'FontSize', 12);
text(n1.C(1), n1.C(2), '못 옮기는 극점이 있다. 그 극점은 그대로', ...
     'HorizontalAlignment','center', 'FontSize', 12);
text(a2.C(1), a2.C(2), '14주차 관측기 — 못 재는 상태를 만든다', ...
     'HorizontalAlignment','center', 'FontSize', 12);
text(n2.C(1), n2.C(2), '못 알아내는 상태가 있다. 센서를 늘린다', ...
     'HorizontalAlignment','center', 'FontSize', 12);

dg_arrow(q1.R, a1.L, '예');
dg_arrow(q1.R, n1.L, '아니오');
dg_arrow(q2.R, a2.L, '예');
dg_arrow(q2.R, n2.L, '아니오');

text(W/2, 0.5, ['두 판정은 설계를 시작하기 전에 해야 한다. ' ...
                'place 가 오류를 낸 뒤에 알면 늦다'], ...
     'HorizontalAlignment','center', 'FontSize', 11.5, 'Color', [0.35 0.35 0.35]);
end

function local_gw(b, top, bot)
text(b.C(1), b.C(2)+0.30, top, 'HorizontalAlignment','center', ...
     'FontSize', 12.5, 'FontWeight','bold');
text(b.C(1), b.C(2)-0.38, bot, 'HorizontalAlignment','center', ...
     'FontSize', 10.5, 'Color', [0.35 0.35 0.35]);
end


function fig_w12_similarity()
% 유사변환 : 좌표를 바꾸면 모양은 달라져도 고유값은 그대로
A = [0 1; -2 -3];
[V, D] = eig(A);  lam = diag(D);
tv = linspace(0, 4, 600);
x0 = [1; 0.2];
z0 = V\x0;

xt = zeros(2, numel(tv));  zt = zeros(2, numel(tv));
for j = 1:numel(tv)
    xt(:,j) = expm(A*tv(j))*x0;
    zt(:,j) = V\xt(:,j);
end

figure('Position',[60 60 1060 430]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
hold on; grid on
plot(tv, xt(1,:), 'LineWidth', 2.6, 'Color',[0.00 0.45 0.74]);
plot(tv, xt(2,:), 'LineWidth', 2.6, 'Color',[0.85 0.33 0.10]);
yline(0,'k:','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('원좌표계 상태 x');
legend('x_1', 'x_2', 'Location','northeast');
title('원좌표계 : 두 모드가 중첩된 응답');

nexttile
hold on; grid on
plot(tv, zt(1,:), 'LineWidth', 2.6, 'Color',[0.47 0.67 0.19]);
plot(tv, zt(2,:), 'LineWidth', 2.6, 'Color',[0.49 0.18 0.56]);
plot(tv, zt(1,1)*exp(lam(1)*tv), 'k--', 'LineWidth', 1.4);
plot(tv, zt(2,1)*exp(lam(2)*tv), 'k--', 'LineWidth', 1.4, 'HandleVisibility','off');
yline(0,'k:','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('모드 좌표 z = V^{-1}x');
legend(sprintf('z_1  (\\lambda = %.0f)', lam(1)), ...
       sprintf('z_2  (\\lambda = %.0f)', lam(2)), ...
       '해석해 z_i(0)e^{\lambda_i t}', 'Location','northeast');
title('모드 좌표계 : 두 개의 독립 지수 모드로 분리');
end


function fig_modes()
% 고유벡터 방향으로 출발하면 순수한 지수함수 하나로 움직인다
A = [0 1; -2 -3];                 % 고유값 -1, -2
[V, D] = eig(A);
lam = diag(D);
t = (0:0.01:5)';

figure('Position',[60 60 950 400]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile; hold on; grid on; axis equal;
for a = [-1.2 -0.6 0.6 1.2]
    for b = [-1.2 -0.6 0.6 1.2]
        x0 = [a; b];
        X = (expm_traj(A, x0, t));
        plot(X(:,1), X(:,2), '-', 'Color', [0.75 0.78 0.85], 'HandleVisibility','off');
    end
end
for k = 1:2
    v = V(:,k)/norm(V(:,k));
    plot([-1.6*v(1) 1.6*v(1)], [-1.6*v(2) 1.6*v(2)], 'LineWidth', 2.5, ...
         'DisplayName', sprintf('고유벡터 (\\lambda = %.0f)', real(lam(k))));
end
xlim([-1.6 1.6]); ylim([-1.8 1.8]);
xlabel('x_1'); ylabel('x_2'); legend('Location','northwest');
title('모든 궤적은 결국 느린 고유벡터 방향으로 붙는다');

nexttile; hold on; grid on;
for k = 1:2
    x0 = V(:,k)/norm(V(:,k));
    X = expm_traj(A, x0, t);
    plot(t, X(:,1), 'LineWidth', 2.4, ...
         'DisplayName', sprintf('고유벡터 출발 (\\lambda = %.0f)', real(lam(k))));
end
X = expm_traj(A, [1;0], t);
plot(t, X(:,1), '--', 'LineWidth', 2, 'DisplayName','아무 방향 출발 (섞여 있다)');
xlabel('시간 [s]'); ylabel('x_1'); legend('Location','northeast');
title('고유벡터에서 출발하면 지수함수 하나뿐이다');
end


function X = expm_traj(A, x0, t)
% 상태천이행렬로 궤적을 직접 계산한다 (expm 을 눈으로 보여 주려는 것)
X = zeros(numel(t), numel(x0));
for i = 1:numel(t)
    X(i,:) = (expm(A*t(i))*x0).';
end
end


function fig_ctrb()
% 가제어가 아니면 입력이 못 건드리는 상태가 있다
A  = [-1 0; 0 -2];
Bc = [1; 1];       % 가제어
Bu = [1; 0];       % x2 를 못 건드린다
C  = [1 1];  D = 0;
t  = (0:0.02:5)';

figure('Position',[60 60 950 400]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile; hold on; grid on;
[~, ~, Xc] = step(ss(A, Bc, eye(2), [0;0]), t);
plot(t, Xc(:,1), 'LineWidth', 2.4, 'DisplayName','x_1');
plot(t, Xc(:,2), 'LineWidth', 2.4, 'DisplayName','x_2');
xlabel('시간 [s]'); ylabel('상태'); legend('Location','southeast');
title(sprintf('B = [1;1] : rank(ctrb) = %d  -> 가제어', rank(ctrb(A,Bc))));

nexttile; hold on; grid on;
[~, ~, Xu] = step(ss(A, Bu, eye(2), [0;0]), t);
plot(t, Xu(:,1), 'LineWidth', 2.4, 'DisplayName','x_1');
plot(t, Xu(:,2), 'LineWidth', 2.4, 'DisplayName','x_2  (꿈쩍도 않는다)');
ylim([-0.1 1.1]);
xlabel('시간 [s]'); ylabel('상태'); legend('Location','east');
title(sprintf('B = [1;0] : rank(ctrb) = %d  -> 가제어 아님', rank(ctrb(A,Bu))));
end


function fig_obsv()
% 가관측이 아니면 출력만 봐서는 구별할 수 없는 상태가 있다
A  = [-1 0; 0 -2];
B  = [0; 0];
Co = [1 1];        % 가관측
Cu = [1 0];        % x2 가 안 보인다
t  = (0:0.02:5)';

x0a = [1; 0];
x0b = [1; 1];

figure('Position',[60 60 950 400]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile; hold on; grid on;
plot(t, initial(ss(A,B,Co,0), x0a, t), 'LineWidth', 2.4, 'DisplayName','x(0) = [1;0]');
plot(t, initial(ss(A,B,Co,0), x0b, t), 'LineWidth', 2.4, 'DisplayName','x(0) = [1;1]');
xlabel('시간 [s]'); ylabel('출력 y'); legend('Location','northeast');
title(sprintf('C = [1 1] : rank(obsv) = %d  -> 두 상태가 구별된다', rank(obsv(A,Co))));

nexttile; hold on; grid on;
plot(t, initial(ss(A,B,Cu,0), x0a, t), 'LineWidth', 3.2, 'DisplayName','x(0) = [1;0]');
plot(t, initial(ss(A,B,Cu,0), x0b, t), '--', 'LineWidth', 2.2, 'DisplayName','x(0) = [1;1]');
xlabel('시간 [s]'); ylabel('출력 y'); legend('Location','northeast');
title(sprintf('C = [1 0] : rank(obsv) = %d  -> 겹친다. 구별 불가', rank(obsv(A,Cu))));
end


% ======================================================================
%  13주차 : 극배치
% ======================================================================

function fig_place_map()
% 개루프 극점을 원하는 자리로 옮긴다
[~, p] = plant_dcmotor('position');
sys = ss(p.A, p.B, p.C, p.D);
p_des = [-8 -10 -12];
[K, Kr, info] = fsfb_design(sys, p_des);

figure('Position',[60 60 950 400]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile; hold on; grid on;
plot(real(info.poles_open),   imag(info.poles_open),   'x', ...
     'MarkerSize', 14, 'LineWidth', 3, 'DisplayName','개루프 극점');
plot(real(info.poles_closed), imag(info.poles_closed), 'o', ...
     'MarkerSize', 12, 'LineWidth', 3, 'DisplayName','극배치 후');
xline(0,'k-','HandleVisibility','off'); yline(0,'k-','HandleVisibility','off');
xlim([-14 2]); ylim([-3 3]);
xlabel('실수부'); ylabel('허수부'); legend('Location','northwest');
title('원점의 적분기까지 원하는 자리로 끌어온다');

nexttile; hold on; grid on;
t = info.t;
plot(t, info.y, 'LineWidth', 2.4, 'DisplayName','극배치 + Kr');
yline(1,'k--','HandleVisibility','off');
ylim([0 1.25]);
xlabel('시간 [s]'); ylabel('각도 [rad]'); legend('Location','southeast');
title(sprintf('오버슈트 %.1f %%, 정착시간 %.2f s', info.OS, info.ts));
end


function fig_effort()
% 극을 왼쪽으로 보낼수록 빨라지지만 제어입력이 폭증한다
[~, p] = plant_dcmotor('position');
sys = ss(p.A, p.B, p.C, p.D);
a   = 4:2:24;

umax = zeros(size(a));  ts = zeros(size(a));  Kn = zeros(size(a));
for i = 1:numel(a)
    [K, ~, info] = fsfb_design(sys, [-a(i) -a(i)-2 -a(i)-4]);
    umax(i) = info.umax;  ts(i) = info.ts;  Kn(i) = norm(K);
end

figure('Position',[60 60 950 400]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
yyaxis left;  plot(a, ts,   'LineWidth', 2.4); ylabel('정착시간 [s]');
yyaxis right; semilogy(a, umax, 'LineWidth', 2.4); ylabel('최대 제어입력 [V]');
grid on; xlabel('가장 느린 극점의 위치 |Re| ');
title('빠르게 만들수록 전압이 기하급수로 커진다');

nexttile; hold on; grid on;
t = (0:0.002:1.6)';
for aa = [6 12 20]
    [~, ~, info] = fsfb_design(sys, [-aa -aa-2 -aa-4], t);
    plot(t, info.y, 'LineWidth', 2.2, ...
         'DisplayName', sprintf('극점 -%d 부근 : 정착 %.2f s, 최대 %.0f V', ...
                                aa, info.ts, info.umax));
end
yline(1, 'k--', 'HandleVisibility','off');
xlabel('시간 [s]'); ylabel('각도 [rad]'); ylim([0 1.2]);
legend('Location','southeast');
title('빨라진 만큼 전압을 더 쓴다 (흔한 구동기 한계는 24 V)');
end


function fig_kr()
% 상태궤환만으로는 정상상태 오차가 남는다
[~, p] = plant_dcmotor('position');
sys = ss(p.A, p.B, p.C, p.D);
[K, Kr] = fsfb_design(sys, [-8 -10 -12]);
Acl = p.A - p.B*K;
t = (0:0.005:1.5)';

y1 = step(ss(Acl, p.B*1,  p.C, p.D), t);      % Kr = 1
y2 = step(ss(Acl, p.B*Kr, p.C, p.D), t);      % Kr = 1/dcgain

figure('Position',[60 60 900 380]);
hold on; grid on;
plot(t, y1, 'LineWidth', 2.4, 'DisplayName', 'Kr = 1 (그냥 지령을 넣으면)');
plot(t, y2, 'LineWidth', 2.4, 'DisplayName', sprintf('Kr = %.1f (보정하면)', Kr));
yline(1, 'k--', 'HandleVisibility','off');
xlabel('시간 [s]'); ylabel('각도 [rad]');
legend('Location','east');
title('극배치는 극점만 옮긴다. 직류이득은 따로 맞춰 줘야 한다');
end


% ======================================================================
%  14주차 : 관측기
% ======================================================================

function fig_w14_error_dyn()
% 추정오차는 (A-LC)e 만 따른다 — 입력이 무엇이든 상관없다
[~, p] = plant_dcmotor('position');
A = p.A;  B = p.B;  C = p.C;
n = size(A,1);
L = obsv_design(ss(A,B,C,p.D), [-30 -34 -38]);
Ae = A - L*C;
t  = (0:0.001:0.4)';

figure('Position',[60 60 1060 430]);
tiledlayout(1,2,'TileSpacing','compact');

% ---- 왼쪽 : 초기 추정오차가 달라도 전부 0 으로
nexttile; hold on; grid on
e0s = [0.3 0 0; -0.2 1 0; 0.1 -1.5 4].';
col = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19];
for k = 1:size(e0s,2)
    et = zeros(n, numel(t));
    for j = 1:numel(t), et(:,j) = expm(Ae*t(j))*e0s(:,k); end
    plot(t, et(1,:), 'LineWidth', 2.4, 'Color', col(k,:), ...
         'DisplayName', sprintf('e_1(0) = %.1f', e0s(1,k)));
end
yline(0, 'k:', 'HandleVisibility','off');
xlabel('시간 [s]'); ylabel('각도 추정오차 e_1');
legend('Location','northeast');
title('오차는 (A-LC)e 만 따르므로 어떤 초기오차도 0 으로 간다');

% ---- 오른쪽 : 입력을 바꿔도 오차는 똑같다
nexttile; hold on; grid on
e0 = [0.3; 0; 0];
us = {zeros(size(t)), ones(size(t)), sin(40*t), 5*sin(120*t)};
lbl = {'u = 0', 'u = 계단', 'u = sin 40t', 'u = 5 sin 120t'};
sty = {'-','-','-','--'};
for k = 1:numel(us)
    % 플랜트와 관측기를 함께 적분해 실제 오차를 뽑는다 (해석해에 기대지 않는다)
    Abig = [A zeros(n); L*C  A-L*C];
    Bbig = [B; B];
    xb = lsim(ss(Abig, Bbig, [eye(n) -eye(n)], zeros(n,1)), us{k}, t, [e0; zeros(n,1)]);
    plot(t, xb(:,1), sty{k}, 'LineWidth', 2.2, 'DisplayName', lbl{k});
end
yline(0, 'k:', 'HandleVisibility','off');
xlabel('시간 [s]'); ylabel('각도 추정오차 e_1');
legend('Location','northeast');
title('네 곡선이 완전히 겹친다 — 오차 방정식에 u 가 없다');
end


function fig_w14_duality()
% 쌍대성 : 13주차 제어 문제와 14주차 추정 문제는 전치 관계
W = 15.0; H = 10.4;
dg_new(W, H, '쌍대성 : 전치를 두 번 하면 지난주 문제가 그대로 된다');
set(gcf, 'Position', [60 60 1100 760]);

cL = [0.88 0.93 1.00];        % 13주차 (제어)
cR = [0.93 0.97 0.90];        % 14주차 (추정)
xL = 3.3;  xR = 11.7;  wB = 5.4;  hB = 1.3;

rows = { '푸는 문제',   '극점을 옮긴다',          '상태를 알아낸다'
         '닫는 행렬',   'A - BK',                 'A - LC'
         '되는 조건',   '가제어  rank(ctrb(A,B))','가관측  rank(obsv(A,C))'
         '구하는 명령', 'place(A, B, p)',         'place(A'', C'', p)'''
         '치르는 대가', '제어입력이 커진다',      '잡음이 증폭된다' };

yv = 8.6:-1.75:1.6;
for i = 1:5
    bl = dg_block(xL, yv(i), wB, hB, '', cL);
    br = dg_block(xR, yv(i), wB, hB, '', cR);
    % [주의] 한글이 섞인 칸에 Consolas 를 쓰면 글자가 네모로 나온다.
    %        코드·행렬만 들어간 칸에만 고정폭 글꼴을 준다.
    fn2 = local_dualfont(rows{i,2});
    fn3 = local_dualfont(rows{i,3});
    text(bl.C(1), bl.C(2), rows{i,2}, 'HorizontalAlignment','center', ...
         'FontSize', 12.5, 'FontName', fn2);
    text(br.C(1), br.C(2), rows{i,3}, 'HorizontalAlignment','center', ...
         'FontSize', 12.5, 'FontName', fn3);
    text(W/2, yv(i)+0.52, rows{i,1}, 'HorizontalAlignment','center', ...
         'FontSize', 10, 'Color', [0.45 0.45 0.45]);
    dg_arrow(bl.R, br.L, '');
end

text(xL, 9.9, '13주차 — 제어', 'HorizontalAlignment','center', ...
     'FontSize', 14, 'FontWeight','bold', 'Color', [0.10 0.35 0.65]);
text(xR, 9.9, '14주차 — 추정', 'HorizontalAlignment','center', ...
     'FontSize', 14, 'FontWeight','bold', 'Color', [0.25 0.50 0.15]);
text(W/2, 9.9, '전치', 'HorizontalAlignment','center', ...
     'FontSize', 12, 'FontWeight','bold', 'Color', [0.75 0.20 0.15]);

text(W/2, 0.6, ['A \rightarrow A^T ,   B \rightarrow C^T ,   K \rightarrow L^T ' ...
                '   —  대응만 바꾸면 새로 배울 것이 없다'], ...
     'HorizontalAlignment','center', 'FontSize', 11.5, 'Color', [0.35 0.35 0.35]);
end

function fn = local_dualfont(str)
% 한글이 하나라도 있으면 기본 글꼴, 순수 코드면 고정폭
if any(double(str) > 127), fn = get(0, 'defaultTextFontName');
else,                      fn = 'Consolas';
end
end


function fig_w14_pole_speed()
% 관측기 극을 제어기 극의 몇 배로 둘 것인가 — 2~5 배 관례의 근거
[~, p] = plant_dcmotor('position');
A = p.A;  B = p.B;  C = p.C;
n = size(A,1);
p_ctrl = [-8 -10 -12];
t  = (0:0.0005:0.8)';
e0 = [0.3; 0; 0];

figure('Position',[60 60 1060 430]);
tiledlayout(1,2,'TileSpacing','compact');

% ---- 왼쪽 : 배속별 추정오차
nexttile; hold on; grid on
for a = [1 3 10]
    L  = obsv_design(ss(A,B,C,p.D), a*p_ctrl);
    et = zeros(n, numel(t));
    for j = 1:numel(t), et(:,j) = expm((A - L*C)*t(j))*e0; end
    plot(t, et(1,:), 'LineWidth', 2.4, 'DisplayName', sprintf('%d 배', a));
end
yline(0, 'k:', 'HandleVisibility','off');
xlabel('시간 [s]'); ylabel('각도 추정오차 e_1');
legend('Location','northeast');
title('관측기 극을 제어기 극의 몇 배로 두었나');

% ---- 오른쪽 : 배속을 훑는다
nexttile; hold on; grid on
av = 1:0.25:12;
tset = zeros(size(av));  Lnorm = zeros(size(av));
for i = 1:numel(av)
    L = obsv_design(ss(A,B,C,p.D), av(i)*p_ctrl);
    et = zeros(1, numel(t));
    for j = 1:numel(t), ej = expm((A - L*C)*t(j))*e0;  et(j) = ej(1); end
    idx = find(abs(et) > 0.02*abs(e0(1)), 1, 'last');
    if isempty(idx), tset(i) = 0; else, tset(i) = t(idx); end
    Lnorm(i) = norm(L);
end
patch([2 5 5 2], [0 0 1e6 1e6], [0.95 0.95 0.80], 'EdgeColor','none', ...
      'HandleVisibility','off');
yyaxis left
plot(av, 1000*tset, 'LineWidth', 2.6);
ylabel('추정오차 정착시간 [ms]'); ylim([0 1000*max(tset)*1.1]);
yyaxis right
plot(av, Lnorm, 'LineWidth', 2.6);
ylabel('관측기 이득 크기 ||L||');
xlabel('관측기 극 / 제어기 극  (배)');
xlim([1 12]);
title('2\sim5 배 구간 밖에서는 얻는 것보다 잃는 것이 크다');
end


function fig_w14_true_vs_est()
% 진짜 상태를 쓴 것과 추정 상태를 쓴 것이 얼마나 다른가
[~, p] = plant_dcmotor('position');
A = p.A;  B = p.B;  C = p.C;
n = size(A,1);
K  = place(A, B, [-8 -10 -12]);
L  = obsv_design(ss(A,B,C,p.D), [-30 -34 -38]);
Kr = 1 / dcgain(ss(A - B*K, B, C, 0));

t = (0:0.001:1.5)';
r = ones(size(t));

% (a) 진짜 x 를 되먹인다
ya = lsim(ss(A - B*K, B*Kr, C, 0), r, t, zeros(n,1));

% (b),(c) 관측기 기반 : 상태 [x ; xhat]
Abig = [A -B*K; L*C  A - B*K - L*C];
Bbig = [B*Kr; B*Kr];
Cbig = [C zeros(1,n)];
yb = lsim(ss(Abig, Bbig, Cbig, 0), r, t, zeros(2*n,1));
x0c = [0.3; 0; 0];
yc = lsim(ss(Abig, Bbig, Cbig, 0), r, t, [x0c; zeros(n,1)]);

figure('Position',[60 60 1060 430]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile; hold on; grid on
plot(t, ya, 'LineWidth', 3.2, 'Color',[0.00 0.45 0.74]);
plot(t, yb, '--', 'LineWidth', 2.0, 'Color',[1.00 0.80 0.00]);
plot(t, yc, 'LineWidth', 2.2, 'Color',[0.85 0.33 0.10]);
yline(1, 'k:', 'HandleVisibility','off');
xlabel('시간 [s]'); ylabel('각도 [rad]');
legend('(a) 진짜 상태 x ,  x(0)=0', '(b) 추정 상태 ,  x(0)=0', ...
       '(c) 추정 상태 ,  x(0)=0.3', 'Location','southeast');
title('(a) 와 (b) 는 완전히 겹친다');

nexttile; hold on; grid on
plot(t, yb - ya, '--', 'LineWidth', 2.4, 'Color',[0.30 0.30 0.30]);
plot(t, yc - ya, 'LineWidth', 2.4, 'Color',[0.85 0.33 0.10]);
yline(0, 'k:', 'HandleVisibility','off');
xlabel('시간 [s]'); ylabel('(a) 와의 차이 [rad]');
legend(sprintf('(b) - (a)   최대 %.1e', max(abs(yb-ya))), ...
       sprintf('(c) - (a)   최대 %.3f', max(abs(yc-ya))), ...
       'Location','northeast');
title('차이는 초기 추정오차가 살아 있는 동안만 생긴다');
end


function fig_w14_semester_arc()
% 한 학기 되짚기 : 역진자 하나가 네 주차를 관통한다
W = 17.6; H = 7.8;
dg_new(W, H, '거꾸로 선 진자 하나가 네 주차를 관통한다');
set(gcf, 'Position', [60 60 1240 560]);

c = [0.88 0.93 1.00; 0.93 0.93 0.93; 0.88 0.96 0.88; 1.00 0.90 0.86];
xv = 2.3:4.35:15.4;
yb = 4.6;

for i = 1:4
    b(i) = dg_block(xv(i), yb, 3.3, 2.2, '', c(i,:)); %#ok<AGROW>
end

top = {'3주차', '12주차', '13주차', '14주차'};
mid = {'선형화', '가제어 · 가관측', '극배치', '관측기'};
bot = {'sin\theta \approx \theta', 'rank(ctrb), rank(obsv)', ...
       'K = place(A,B,p)', 'L = place(A'',C'',p)'''};
for i = 1:4
    text(b(i).C(1), b(i).C(2)+0.72, top{i}, 'HorizontalAlignment','center', ...
         'FontSize', 10.5, 'Color', [0.45 0.45 0.45]);
    text(b(i).C(1), b(i).C(2)+0.18, mid{i}, 'HorizontalAlignment','center', ...
         'FontSize', 13, 'FontWeight','bold');
    text(b(i).C(1), b(i).C(2)-0.55, bot{i}, 'HorizontalAlignment','center', ...
         'FontSize', 10, 'Color', [0.15 0.35 0.65], 'FontName','Consolas');
end

% 화살표에는 글자를 붙이지 않고, 넘겨주는 것을 블록 위쪽에 따로 적는다.
% (블록 사이가 좁아 라벨을 가운데 두면 블록 글자와 겹친다)
dg_arrow(b(1).R, b(2).L, '');
dg_arrow(b(2).R, b(3).L, '');
dg_arrow(b(3).R, b(4).L, '');

hand = {'선형 모델', '옮길 수 있다', '못 재는 상태'};
for i = 1:3
    text((b(i).C(1)+b(i+1).C(1))/2, yb + 1.55, hand{i}, ...
         'HorizontalAlignment','center', 'FontSize', 10.5, ...
         'Color', [0.30 0.30 0.30]);
end

text(W/2, 2.85, '치르는 대가', 'HorizontalAlignment','center', ...
     'FontSize', 11.5, 'FontWeight','bold', 'Color', [0.75 0.20 0.15]);
lab = {'동작점 근처만 맞다', '못 옮기는 극점이 있다', '토크가 급증한다', '잡음이 증폭된다'};
for i = 1:4
    text(b(i).C(1), 2.1, lab{i}, 'HorizontalAlignment','center', ...
         'FontSize', 10.5, 'Color', [0.75 0.20 0.15]);
end

text(W/2, 0.9, ['네 칸을 세로로 읽으면 한 문장이 남는다 — ' ...
                '얻는 것마다 값이 있고, 그 값을 정하는 것이 설계다'], ...
     'HorizontalAlignment','center', 'FontSize', 11.5, 'Color', [0.35 0.35 0.35]);
end


function fig_obs_converge()
% 초기 추정이 틀려도 추정오차는 스스로 0 으로 간다
[~, p] = plant_dcmotor('position');
sys = ss(p.A, p.B, p.C, p.D);
L = obsv_design(sys, [-14 -16 -18]);
n = size(p.A,1);

t  = (0:0.002:1.2)';
u  = ones(size(t));
x0 = [0.5; 0; 0];                      % 실제 초기 상태
[~, ~, X] = lsim(ss(p.A, p.B, eye(n), zeros(n,1)), u, t, x0);
ymeas = X*p.C.';                        % 실제로 잴 수 있는 것은 이것 하나뿐

% 관측기 : xhat' = (A-LC) xhat + [B L][u ; y]
obs = ss(p.A - L*p.C, [p.B L], eye(n), zeros(n,2));
Xh  = lsim(obs, [u, ymeas], t, zeros(n,1));

figure('Position',[60 60 950 460]);
tiledlayout(2,2,'TileSpacing','compact');

nexttile; hold on; grid on;
plot(t, X(:,1),  'LineWidth', 2.6, 'DisplayName','실제 (잴 수 있다)');
plot(t, Xh(:,1), '--', 'LineWidth', 2.2, 'DisplayName','관측기의 추정');
ylabel('x_1 : 각도 [rad]'); legend('Location','southeast');
title('실제 초기값 0.5, 관측기는 0 에서 출발한다');

nexttile; hold on; grid on;
plot(t, X(:,2),  'LineWidth', 2.6, 'DisplayName','실제 (못 잰다)');
plot(t, Xh(:,2), '--', 'LineWidth', 2.2, 'DisplayName','관측기의 추정');
ylabel('x_2 : 각속도 [rad s^{-1}]'); legend('Location','southeast');
title('각속도는 센서가 없는데도 맞춰 낸다');

nexttile; hold on; grid on;
plot(t, X(:,1)-Xh(:,1), 'LineWidth', 2.4);
yline(0,'k--');
xlabel('시간 [s]'); ylabel('e_1 = x_1 - xhat_1');
title('추정오차는 (A - LC) 의 고유값으로 스스로 줄어든다');

nexttile; hold on; grid on;
plot(t, X(:,2)-Xh(:,2), 'LineWidth', 2.4, 'Color', [0.85 0.25 0.15]);
yline(0,'k--');
xlabel('시간 [s]'); ylabel('e_2 = x_2 - xhat_2');
title('입력 u 는 오차 방정식에서 사라진다 — 무슨 입력이든 수렴한다');
end


function fig_separation()
% 분리원리 : 전체 극점 = 제어기 극점 + 관측기 극점
[~, p] = plant_dcmotor('position');
sys = ss(p.A, p.B, p.C, p.D);
K = fsfb_design(sys, [-8 -10 -12]);
L = obsv_design(sys, [-30 -34 -38]);

A = p.A;  B = p.B;  C = p.C;
Aaug = [A, -B*K; L*C, A - B*K - L*C];
e_aug = eig(Aaug);
e_K   = eig(A - B*K);
e_L   = eig(A - L*C);

figure('Position',[60 60 900 380]);
hold on; grid on;
plot(real(e_aug), imag(e_aug), 'o', 'MarkerSize', 16, 'LineWidth', 2.5, ...
     'DisplayName','확대 시스템 전체의 고유값');
plot(real(e_K), imag(e_K), 'x', 'MarkerSize', 13, 'LineWidth', 3, ...
     'DisplayName','eig(A - BK)  제어기가 정한 것');
plot(real(e_L), imag(e_L), '+', 'MarkerSize', 15, 'LineWidth', 3, ...
     'DisplayName','eig(A - LC)  관측기가 정한 것');
xline(0,'k-','HandleVisibility','off'); yline(0,'k-','HandleVisibility','off');
xlim([-45 3]); ylim([-2 2]);
xlabel('실수부'); ylabel('허수부'); legend('Location','northwest');
title('분리원리 — 정확히 겹친다. 따로 설계해도 된다');
end


function fig_obs_noise()
% 관측기를 빠르게 할수록 잡음을 증폭한다
[~, p] = plant_dcmotor('position');
sys = ss(p.A, p.B, p.C, p.D);
n = size(p.A,1);
t = (0:0.001:0.5)';
u = ones(size(t));
[y, ~, ~] = lsim(ss(p.A, p.B, p.C, p.D), u, t, zeros(n,1));
rng(3);
yn = y + 2e-4*randn(size(y));

sets = {[-10 -12 -14], [-30 -34 -38], [-90 -95 -100]};
lbl  = {'느린 관측기 (-10 부근)', '보통 (-30 부근)', '빠른 관측기 (-90 부근)'};

figure('Position',[60 60 950 420]);
tiledlayout(2,1,'TileSpacing','compact');

nexttile; hold on; grid on;
plot(t, yn, 'LineWidth', 0.8, 'Color', [0.6 0.6 0.6]);
plot(t, y,  'LineWidth', 2);
ylabel('측정 각도 [rad]'); legend('잡음이 섞인 측정값','참값','Location','northwest');
title('센서에는 늘 잡음이 있다');

nexttile; hold on; grid on;
for i = 1:3
    L  = obsv_design(sys, sets{i});
    Xh = lsim(ss(p.A - L*p.C, [p.B L], eye(n), zeros(n,2)), [u, yn], t, zeros(n,1));
    plot(t, Xh(:,2), 'LineWidth', 1.6, 'DisplayName', lbl{i});
end
xlabel('시간 [s]'); ylabel('추정한 각속도 [rad/s]');
legend('Location','northwest');
title('빠르게 만들수록 추정값이 잡음으로 떨린다 — 공짜가 아니다');
end

% ======================================================================
%  필터 — 주파수영역과 시간영역을 **나란히** 본다
%  교수자 요청 : "저역통과 필터라고 하면 bode plot 도 들어가고,
%                 노이즈한 신호가 시간에 따라 보이고, 저역통과 필터를 통과하면
%                 어떻게 변화하는지 신호도 보여주고, 반대로 고역통과 필터의 예도"
% ======================================================================

function [t, clean, noisy] = local_noisy_signal()
% 두 성분이 섞인 신호를 만든다 — 느린 참 신호 + 빠른 잡음
%   참 신호 : 0.5 Hz  (우리가 알고 싶은 것)
%   잡음    : 20 Hz 톤 + 백색잡음  (센서가 얹은 것)
t     = (0:0.001:4)';
clean = sin(2*pi*0.5*t);
rng(11);
noisy = clean + 0.35*sin(2*pi*20*t) + 0.12*randn(size(t));
end


function fig_lpf()
% 저역통과 필터 : 느린 것은 통과, 빠른 것은 막는다
s = tf('s');
fc = 2;                        % 차단주파수 [Hz]
wc = 2*pi*fc;
G  = wc/(s + wc);              % 1차 저역통과

[t, clean, noisy] = local_noisy_signal();
y = lsim(G, noisy, t);

w  = logspace(-1, 3, 600);
m  = 20*log10(squeeze(abs(freqresp(G, w))));
ph = squeeze(angle(freqresp(G, w)))*180/pi;

figure('Position',[60 60 1000 560]);
tiledlayout(2,2,'TileSpacing','compact');

% (1,1) 크기 응답
nexttile
semilogx(w/(2*pi), m, 'LineWidth', 2.4); hold on; grid on;
yline(-3, 'r--', 'LineWidth', 1.5);
xline(fc, 'r:', 'LineWidth', 1.8);
plot(0.5, 20*log10(abs(freqresp(G, 2*pi*0.5))), 'o', ...
     'MarkerSize', 10, 'LineWidth', 2.4, 'MarkerEdgeColor', [0.10 0.55 0.25]);
plot(20,  20*log10(abs(freqresp(G, 2*pi*20))),  'o', ...
     'MarkerSize', 10, 'LineWidth', 2.4, 'MarkerEdgeColor', [0.85 0.25 0.15]);
text(0.55, -6, '참 신호 0.5 Hz', 'Color',[0.10 0.55 0.25], 'FontSize', 10);
text(6, -26, '잡음 20 Hz', 'Color',[0.85 0.25 0.15], 'FontSize', 10);
xlabel('주파수 [Hz]'); ylabel('크기 [dB]'); ylim([-45 8]);
title(sprintf('저역통과 : 차단 %g Hz 위를 깎는다', fc));

% (1,2) 입력 신호
nexttile
plot(t, noisy, 'LineWidth', 0.8, 'Color', [0.65 0.68 0.75]); hold on; grid on;
plot(t, clean, 'LineWidth', 2.4, 'Color', [0.10 0.55 0.25]);
xlabel('시간 [s]'); ylabel('신호'); ylim([-2 2]);
legend('센서가 준 값 (잡음 포함)', '알고 싶은 참 신호', 'Location','northeast');
title('필터를 통과하기 전');

% (2,1) 위상 응답
nexttile
semilogx(w/(2*pi), ph, 'LineWidth', 2.4); hold on; grid on;
xline(fc, 'r:', 'LineWidth', 1.8);
yline(-45, 'k--');
xlabel('주파수 [Hz]'); ylabel('위상 [도]'); ylim([-95 5]);
text(fc*1.3, -50, '차단주파수에서 -45도', 'FontSize', 10);
title('공짜가 아니다 — 위상이 늦는다');

% (2,2) 출력 신호
nexttile
plot(t, y, 'LineWidth', 2.2, 'Color', [0.15 0.35 0.75]); hold on; grid on;
plot(t, clean, '--', 'LineWidth', 1.8, 'Color', [0.10 0.55 0.25]);
xlabel('시간 [s]'); ylabel('신호'); ylim([-2 2]);
% 지연은 **참 신호 주파수(0.5 Hz)** 에서의 위상으로 계산한다.
% 차단주파수의 -45도를 그대로 쓰면 안 된다 (그것은 2 Hz 에서의 값이다).
ph05  = -angle(freqresp(G, 2*pi*0.5));          % [rad], 양수 = 늦음
lagms = 1000*ph05/(2*pi*0.5);
legend('필터를 통과한 값', '참 신호', 'Location','northeast');
title(sprintf('잡음은 사라졌다. 대신 %.0f도(= %.0f ms) 늦다', ...
              rad2deg(ph05), lagms));
end


function fig_hpf()
% 고역통과 필터 : 느린 것(치우침)은 막고, 빠른 변화만 통과
s  = tf('s');
fc = 0.5;
wc = 2*pi*fc;
H  = s/(s + wc);               % 1차 고역통과

t = (0:0.001:4)';
drift  = 1.2 + 0.8*t/4;                   % 센서 영점이 서서히 흐른다
event  = 0.6*sin(2*pi*5*t) .* (t > 1.5 & t < 2.5);   % 알고 싶은 빠른 사건
sig    = drift + event;
y      = lsim(H, sig, t);

w  = logspace(-2, 2, 600);
m  = 20*log10(squeeze(abs(freqresp(H, w))));
ph = squeeze(angle(freqresp(H, w)))*180/pi;

figure('Position',[60 60 1000 560]);
tiledlayout(2,2,'TileSpacing','compact');

nexttile
semilogx(w/(2*pi), m, 'LineWidth', 2.4); hold on; grid on;
yline(-3,'r--','LineWidth',1.5); xline(fc,'r:','LineWidth',1.8);
plot(5, 20*log10(abs(freqresp(H, 2*pi*5))), 'o', 'MarkerSize', 10, ...
     'LineWidth', 2.4, 'MarkerEdgeColor', [0.10 0.55 0.25]);
text(1.4, -12, '알고 싶은 5 Hz 사건', 'Color',[0.10 0.55 0.25], 'FontSize', 10);
text(0.012, -33, '느린 치우침은 막힌다', 'Color',[0.85 0.25 0.15], 'FontSize', 10);
xlabel('주파수 [Hz]'); ylabel('크기 [dB]'); ylim([-45 8]);
title(sprintf('고역통과 : 차단 %g Hz 아래를 깎는다', fc));

nexttile
plot(t, sig, 'LineWidth', 1.6, 'Color', [0.15 0.35 0.75]); hold on; grid on;
plot(t, drift, '--', 'LineWidth', 1.8, 'Color', [0.85 0.25 0.15]);
xlabel('시간 [s]'); ylabel('신호'); ylim([-0.5 3]);
legend('센서가 준 값', '영점 흐름 (없애고 싶은 것)', 'Location','northwest');
title('필터를 통과하기 전 — 사건이 치우침에 묻혀 있다');

nexttile
semilogx(w/(2*pi), ph, 'LineWidth', 2.4); hold on; grid on;
xline(fc,'r:','LineWidth',1.8); yline(45,'k--');
xlabel('주파수 [Hz]'); ylabel('위상 [도]'); ylim([-5 95]);
text(fc*1.3, 52, '차단주파수에서 +45도', 'FontSize', 10);
title('고역통과는 위상을 앞세운다 (저역통과와 반대)');

nexttile
plot(t, y, 'LineWidth', 2.2, 'Color', [0.15 0.35 0.75]); hold on; grid on;
plot(t, event, '--', 'LineWidth', 1.8, 'Color', [0.10 0.55 0.25]);
yline(0,'k-');
xlabel('시간 [s]'); ylabel('신호'); ylim([-1.2 1.2]);
legend('필터를 통과한 값', '알고 싶던 사건', 'Location','northwest');
text(0.08, 0.95, '\leftarrow 시작 순간의 봉우리는', 'FontSize', 9, 'Color',[0.45 0.45 0.45]);
text(0.08, 0.78, '   필터 자신의 과도응답이다', 'FontSize', 9, 'Color',[0.45 0.45 0.45]);
title('치우침이 사라지고 사건만 남았다');
end


function fig_cutoff_tradeoff()
% 차단주파수를 어디에 둘 것인가 — 낮으면 느리고, 높으면 시끄럽다
s = tf('s');
[t, clean, noisy] = local_noisy_signal();
fcs = [0.6 2 8 40];

figure('Position',[60 60 1000 520]);
tiledlayout(2,2,'TileSpacing','compact');
for i = 1:4
    nexttile
    G = (2*pi*fcs(i))/(s + 2*pi*fcs(i));
    y = lsim(G, noisy, t);
    plot(t, noisy, 'LineWidth', 0.6, 'Color', [0.80 0.83 0.88]); hold on; grid on;
    plot(t, clean, '--', 'LineWidth', 1.6, 'Color', [0.10 0.55 0.25]);
    plot(t, y, 'LineWidth', 2.2, 'Color', [0.15 0.35 0.75]);
    ylim([-2 2]);
    if i > 2, xlabel('시간 [s]'); end
    if mod(i,2) == 1, ylabel('신호'); end
    rms_err = sqrt(mean((y - clean).^2));
    lag_deg = -rad2deg(angle(freqresp(G, 2*pi*0.5)));
    title(sprintf('차단 %.1f Hz : 참값과의 RMS %.3f, 위상지연 %.0f도', ...
                  fcs(i), rms_err, lag_deg));
end
sgtitle('낮게 잡으면 매끄럽지만 늦고, 높게 잡으면 빠르지만 시끄럽다', ...
        'FontSize', 12, 'FontWeight', 'bold');
end


function fig_filter_family()
% 네 가지 필터를 같은 신호에 나란히
s = tf('s');
w0 = 2*pi*5;   Q = 4;
filters = { '저역통과 (2 Hz)',  (2*pi*2)/(s + 2*pi*2)
            '고역통과 (2 Hz)',  s/(s + 2*pi*2)
            '대역통과 (5 Hz)',  (w0/Q)*s/(s^2 + (w0/Q)*s + w0^2)
            '대역저지 (5 Hz)',  (s^2 + w0^2)/(s^2 + (w0/Q)*s + w0^2) };

t = (0:0.0005:2)';
x = sin(2*pi*0.5*t) + 0.7*sin(2*pi*5*t) + 0.4*sin(2*pi*30*t);
w = logspace(-1, 3, 500);

figure('Position',[60 60 1000 560]);
tiledlayout(2,2,'TileSpacing','compact');

nexttile
hold on; grid on;
for i = 1:4
    semilogx(w/(2*pi), 20*log10(squeeze(abs(freqresp(filters{i,2}, w)))), ...
             'LineWidth', 2, 'DisplayName', filters{i,1});
end
set(gca,'XScale','log'); yline(-3,'k--','HandleVisibility','off');
xlabel('주파수 [Hz]'); ylabel('크기 [dB]'); ylim([-40 6]);
legend('Location','southwest'); title('네 가지 필터의 크기 응답');

nexttile
plot(t, x, 'LineWidth', 1.2); grid on;
xlabel('시간 [s]'); ylabel('신호');
title('입력 : 0.5 Hz + 5 Hz + 30 Hz 가 섞인 신호');

nexttile
hold on; grid on;
plot(t, lsim(filters{1,2}, x, t), 'LineWidth', 2, 'DisplayName','저역통과');
plot(t, lsim(filters{2,2}, x, t), 'LineWidth', 2, 'DisplayName','고역통과');
xlabel('시간 [s]'); ylabel('신호'); legend('Location','northeast');
title('저역통과는 0.5 Hz 만, 고역통과는 나머지만 남긴다');

nexttile
hold on; grid on;
plot(t, lsim(filters{3,2}, x, t), 'LineWidth', 2, 'DisplayName','대역통과');
plot(t, lsim(filters{4,2}, x, t), 'LineWidth', 2, 'DisplayName','대역저지');
xlabel('시간 [s]'); ylabel('신호'); legend('Location','northeast');
title('대역통과는 5 Hz 만, 대역저지는 5 Hz 만 뺀다');
end


function fig_plant_is_lpf()
% 이 과목의 플랜트도 사실 저역통과 필터다
s = tf('s');
Gm = plant_msd();
Gd = plant_dcmotor('speed');
w  = logspace(-2, 2, 600);

t = (0:0.002:20)';
rng(5);
u_slow = sin(2*pi*0.05*t);
u_fast = 0.5*sin(2*pi*2*t);
u = u_slow + u_fast;

figure('Position',[60 60 1000 520]);
tiledlayout(2,2,'TileSpacing','compact');

nexttile
semilogx(w, 20*log10(squeeze(abs(freqresp(Gm/dcgain(Gm), w)))), 'LineWidth', 2.2);
hold on; grid on;
semilogx(w, 20*log10(squeeze(abs(freqresp(Gd/dcgain(Gd), w)))), 'LineWidth', 2.2);
yline(-3,'k--');
xlabel('주파수 [rad s^{-1}]'); ylabel('크기 [dB] (직류이득 1 로 맞춤)');
legend('질량-스프링-댐퍼','DC 모터 (속도)','-3 dB','Location','southwest');
ylim([-60 20]);
title('학기 내내 쓴 플랜트도 저역통과다');

nexttile
plot(t, u, 'LineWidth', 1.0, 'Color',[0.65 0.68 0.75]); hold on; grid on;
plot(t, u_slow, 'LineWidth', 2, 'Color',[0.10 0.55 0.25]);
xlabel('시간 [s]'); ylabel('입력');
legend('느린 성분 + 빠른 성분', '느린 성분만', 'Location','northeast');
title('느린 것과 빠른 것을 함께 넣으면');

nexttile
y = lsim(Gd/dcgain(Gd), u, t);
plot(t, y, 'LineWidth', 2.2, 'Color',[0.15 0.35 0.75]); hold on; grid on;
plot(t, u_slow, '--', 'LineWidth', 1.6, 'Color',[0.10 0.55 0.25]);
xlabel('시간 [s]'); ylabel('출력');
legend('DC 모터 출력','느린 성분','Location','northeast');
title('빠른 성분은 모터가 못 따라간다 = 저절로 걸러진다');

nexttile
% [주의] categorical 은 범주를 **알파벳순으로 재정렬**하므로 값과 이름이 어긋난다.
% 숫자 x 축에 직접 그리고 눈금 이름을 붙인다.
bw   = [bandwidth(Gm) bandwidth(Gd)];
name = {'질량-스프링-댐퍼', 'DC 모터 (속도)'};
bar(1:2, bw, 0.5); grid on;
set(gca, 'XTick', 1:2, 'XTickLabel', name);
ylabel('대역폭 [rad s^{-1}]');
for i = 1:2
    text(i, bw(i)+0.06, sprintf('%.2f', bw(i)), ...
         'HorizontalAlignment','center', 'FontWeight','bold');
end
ylim([0 max(bw)*1.28]);
title('대역폭 = 이 시스템이 따라갈 수 있는 한계');
end

% ======================================================================
%  교수자 강의자료의 저역통과 필터 예제를 그대로 재현한 그림들
%  출처 : 강의자료/2024년/92_부록_USV_제어기설계.pptx  13~19 쪽
%         (Low pass filter — Bode plot / Example / Time constant)
% ======================================================================

function fig_lpf_prof()
% 강의자료 14쪽의 예제를 그대로. 이산 1차 필터 y(k) = a*y(k-1) + (1-a)*u(k)
%   n = 0.05*randn,  r = sin(0.5*pi*t),  a = 0.99,  dt = 0.001
dt = 0.001;
t  = (0:dt:10)';
rng(0);
n  = 0.05*randn(size(t));      % 고주파 잡음
r  = sin(0.5*pi*t);            % 참값 (0.25 Hz)
u  = r + n;                    % 센서가 주는 raw signal

a  = 0.99;                     % 필터 계수
y  = zeros(size(t));
for k = 2:numel(t)
    y(k) = a*y(k-1) + (1-a)*u(k);
end

% 이 이산 필터와 같은 일을 하는 연속 필터
tau = -dt/log(a);              % 시정수
s   = tf('s');
Gc  = 1/(tau*s + 1);
yc  = lsim(Gc, u, t);

figure('Position',[60 60 1000 540]);
tiledlayout(2,2,'TileSpacing','compact');

nexttile([1 2])
plot(t, u, 'LineWidth', 0.6, 'Color', [0.70 0.73 0.80]); hold on; grid on;
plot(t, r, ':', 'LineWidth', 3, 'Color', [0.75 0.20 0.75]);
plot(t, y, 'LineWidth', 2, 'Color', [0.85 0.15 0.15]);
xlabel('시간 [s]'); ylabel('신호'); ylim([-1.5 1.5]);
legend('Raw signal (참값 + 잡음)', 'True value (참값)', 'Filtered signal', ...
       'Location','northeast');
title(sprintf('강의자료 예제 그대로 : a = %.2f 인 이산 저역통과 필터', a));

nexttile
plot(t, y, 'LineWidth', 2, 'Color', [0.85 0.15 0.15]); hold on; grid on;
plot(t, yc, '--', 'LineWidth', 1.8, 'Color', [0.15 0.35 0.75]);
xlabel('시간 [s]'); ylabel('신호'); xlim([0 3]); ylim([-1.2 1.2]);
legend('이산 필터  y(k) = a y(k-1) + (1-a) u(k)', ...
       sprintf('연속 필터  1/(%.4f s + 1)', tau), 'Location','southeast');
title('같은 것이다 — 계수 a 는 시정수를 정하는 것일 뿐');

nexttile
w = logspace(-1, 3, 500);
semilogx(w, 20*log10(squeeze(abs(freqresp(Gc, w)))), 'LineWidth', 2.4);
hold on; grid on;
yline(-3.01, '--k', 'LineWidth', 1.5);
xline(1/tau, 'r:', 'LineWidth', 1.8);
xlabel('주파수 [rad s^{-1}]'); ylabel('크기 [dB]'); ylim([-45 6]);
text(1/tau*1.25, -8, sprintf('\\omega_0 = 1/\\tau = %.1f rad s^{-1}', 1/tau), ...
     'FontSize', 10);
text(0.13, -6.5, 'mag = -3.01 dB', 'FontSize', 10);
title(sprintf('a = %.2f 는 곧 차단주파수 %.1f rad s^{-1} (%.2f Hz)', ...
              a, 1/tau, 1/(2*pi*tau)));
end


function fig_tau_time()
% 강의자료 17쪽 : 시정수를 바꿔 가며 계단응답. 63.21 % 선.
t_f = 3;  dt = 0.01;
t   = (0:dt:t_f)';
N   = floor(t_f/dt);
tau = 0.1*(1:2:15);
y_c = 10;

figure('Position',[60 60 1000 420]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
hold on; grid on;
for k = 1:numel(tau)
    y = zeros(N+1,1);
    for i = 1:N
        y(i+1) = y(i) - (1/tau(k))*dt*(y(i) - y_c);
    end
    plot(t, y, 'LineWidth', 1.8, 'DisplayName', sprintf('\\tau = %.1f', tau(k)));
end
plot(t, 6.321*ones(size(t)), '--k', 'LineWidth', 1.6, 'DisplayName', '63.21 %');
xlabel('시간 [s]'); ylabel('y(t)');
legend('Location','southeast', 'NumColumns', 2);
title('시정수 \tau 가 클수록 느리다 (강의자료 17쪽)');

nexttile
hold on; grid on;
for k = 1:numel(tau)
    plot(tau(k), tau(k), 'o', 'MarkerSize', 9, 'LineWidth', 2, ...
         'HandleVisibility','off');
end
tt = linspace(0, 1.6, 100);
plot(tt, tt, 'LineWidth', 2, 'Color', [0.15 0.35 0.75]);
xlabel('시정수 \tau [s]'); ylabel('63.21 % 에 닿는 시각 [s]');
xlim([0 1.6]); ylim([0 1.6]);
text(0.15, 1.3, '\tau 의 정의 그 자체 :', 'FontSize', 11);
text(0.15, 1.15, '최종값의 63.21 % 에 닿는 시각', 'FontSize', 11);
text(0.15, 0.95, '정착시간은 대략 4\tau', 'FontSize', 11, 'Color',[0.45 0.45 0.45]);
title('\tau 를 눈으로 읽는 법');
end


function fig_tau_freq()
% 강의자료 19쪽 : 시정수별 주파수응답. 0.707 선과 -3.01 dB 선.
s   = tf('s');
tau = 0.1*[1 2 5 10];

figure('Position',[60 60 1000 420]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
hold on; grid on;
for k = 1:numel(tau)
    G = 1/(tau(k)*s + 1);
    [mag, ~, wout] = bode(G, {0.1, 20});
    plot(wout, squeeze(mag), 'LineWidth', 2, ...
         'DisplayName', sprintf('\\tau = %.1f, \\omega_0 = %.0f', tau(k), 1/tau(k)));
end
plot([0.1 20], 0.707*[1 1], '--k', 'LineWidth', 1.6, 'DisplayName', 'mag = 0.707');
xlabel('주파수 [rad s^{-1}]'); ylabel('Gain');
legend('Location','northeast'); title('선형 눈금 (강의자료 19쪽)');

nexttile
hold on; grid on;
for k = 1:numel(tau)
    G = 1/(tau(k)*s + 1);
    [mag, ~, wout] = bode(G, {0.1, 20});
    semilogx(wout, 20*log10(squeeze(mag)), 'LineWidth', 2, ...
             'DisplayName', sprintf('\\tau = %.1f', tau(k)));
end
set(gca, 'XScale', 'log');
semilogx([0.1 20], -3.01*[1 1], '--k', 'LineWidth', 1.6, 'DisplayName','-3.01 dB');
xlabel('주파수 [rad s^{-1}] (로그)'); ylabel('Gain [dB]');
legend('Location','southwest');
title('로그 눈금 — 꺾이는 곳이 \omega_0 = 1/\tau');
end


function fig_bw_order()
% 강의자료 11~12쪽 : 1차·2차 시스템의 대역폭과 계단응답
s = tf('s');
t = (0:0.001:20)';

sets = { '1차', {tf(1,[1 1]), tf(10,[1 10])}, {'1/(s+1)','10/(s+10)'}
         '2차', {tf(1,[1 2 1]), tf(5,[1 2 5])}, {'1/(s^2+2s+1)','5/(s^2+2s+5)'} };

figure('Position',[60 60 1000 520]);
tiledlayout(2,2,'TileSpacing','compact');

for r0 = 1:2
    G = sets{r0,2};  lb = sets{r0,3};

    nexttile
    hold on; grid on;
    w = logspace(-2, 3, 600);
    for i = 1:2
        semilogx(w, 20*log10(squeeze(abs(freqresp(G{i}, w)))), 'LineWidth', 2.2, ...
                 'DisplayName', sprintf('%s  (BW %.3f)', lb{i}, bandwidth(G{i})));
    end
    set(gca,'XScale','log'); yline(-3,'k--','HandleVisibility','off');
    xlabel('주파수 [rad s^{-1}]'); ylabel('크기 [dB]'); ylim([-60 12]);
    legend('Location','southwest');
    title(sprintf('%s 시스템 — 대역폭', sets{r0,1}));

    nexttile
    hold on; grid on;
    plot(t, step(G{1}, t), 'LineWidth', 2.2, 'DisplayName', lb{1});
    plot(t, step(G{2}, t), ':', 'LineWidth', 2.4, 'DisplayName', lb{2});
    xlabel('시간 [s]'); ylabel('y(t)'); xlim([0 8]);
    legend('Location','southeast');
    title('대역폭이 넓은 쪽이 빠르다');
end
end

% ======================================================================
%  1주차 추가 그림
% ======================================================================

function fig_w01_openloop_fail()
% 개루프는 "미리 계산해서 넣는 것" — 계산이 맞으면 완벽하다. 그런데.
G = plant_msd();
t = (0:0.02:30)';
Kr = 1/dcgain(G);              % 개루프 보정 상수

figure('Position',[60 60 1000 420]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
plot(t, step(Kr*G, t), 'LineWidth', 2.4); hold on; grid on;
yline(1, 'k--', 'LineWidth', 1.5);
xlabel('시간 [s]'); ylabel('위치 x');
legend('개루프 (보정 상수 K_r 을 곱함)', '목표값 1', 'Location','southeast');
title(sprintf('모델이 정확하면 개루프도 정확하다 (K_r = %.2f)', Kr));

nexttile
hold on; grid on;
plot(t, step(Kr*G, t), 'LineWidth', 2.4, 'DisplayName','모델이 맞을 때');
for f = [1.3 1.6]
    Gw = plant_msd([], [], f);          % 스프링 k 가 예상보다 뻣뻣하다
    plot(t, step(Kr*Gw, t), 'LineWidth', 2, ...
         'DisplayName', sprintf('실제 k 가 %.1f 배', f));
end
yline(1, 'k--', 'HandleVisibility','off');
xlabel('시간 [s]'); ylabel('위치 x');
legend('Location','southeast');
title('그런데 모델이 틀리면 그만큼 그대로 틀린다');
end


function fig_w01_two_scenes()
% 외란과 모델오차 — 개루프와 폐루프가 갈리는 두 장면을 한 장에
G  = plant_msd();
t  = (0:0.02:40)';
Kr = 1/dcgain(G);
K  = 20;
Kc = (1 + K*dcgain(G))/(K*dcgain(G));   % 폐루프에도 공정하게 보정 상수

figure('Position',[60 60 1000 540]);
tiledlayout(2,2,'TileSpacing','compact');

% --- 장면 1 : 외란 ---
d  = 0.3;                                % t = 20 s 부터 들어오는 외란
step20 = double(t >= 20);

y_ol = step(Kr*G, t)      + d*lsim(G, step20, t);
y_cl = step(Kc*K*G/(1+K*G), t) + d*lsim(G/(1+K*G), step20, t);

nexttile
plot(t, y_ol, 'LineWidth', 2.2); hold on; grid on;
plot(t, y_cl, 'LineWidth', 2.2);
yline(1,'k--'); xline(20, ':', 'LineWidth', 1.5);
xlabel('시간 [s]'); ylabel('위치 x');
legend('개루프','폐루프 (K = 20)','목표값','외란 시작','Location','southeast');
title('장면 1 — t = 20 s 에 외란이 들어오면');

nexttile
Ks = logspace(-1, 2.3, 60);
e_dist = zeros(size(Ks));
for i = 1:numel(Ks)
    e_dist(i) = abs(d*dcgain(G/(1+Ks(i)*G)));
end
loglog(Ks, e_dist, 'LineWidth', 2.4); hold on; grid on;
loglog(Ks, d*dcgain(G)./(1+Ks*dcgain(G)), '--', 'LineWidth', 1.8);
xlabel('이득 K'); ylabel('외란이 남긴 정상상태 오차');
legend('실제', '이론  d\cdotG(0)/(1+KG(0))', 'Location','southwest');
title('K 를 키울수록 외란이 눌린다');

% --- 장면 2 : 모델 오차 ---
nexttile
hold on; grid on;
plot(t, step(Kr*G, t), 'LineWidth', 2.2, 'DisplayName','개루프 (모델 맞음)');
Gw = plant_msd([], [], 1.5);
plot(t, step(Kr*Gw, t), 'LineWidth', 2.2, 'DisplayName','개루프 (k 가 1.5 배)');
plot(t, step(Kc*K*Gw/(1+K*Gw), t), 'LineWidth', 2.2, ...
     'DisplayName','폐루프 (k 가 1.5 배)');
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('위치 x'); xlim([0 25]);
legend('Location','southeast');
title('장면 2 — 스프링이 예상보다 1.5 배 뻣뻣하면');

nexttile
e_mod = zeros(size(Ks));
for i = 1:numel(Ks)
    Kci = (1 + Ks(i)*dcgain(G))/(Ks(i)*dcgain(G));
    e_mod(i) = abs(1 - dcgain(Kci*Ks(i)*Gw/(1+Ks(i)*Gw)));
end
loglog(Ks, e_mod, 'LineWidth', 2.4); hold on; grid on;
yline(abs(1 - dcgain(Kr*Gw)), '--', 'LineWidth', 1.8, 'Color', [0.85 0.25 0.15]);
xlabel('이득 K'); ylabel('모델 오차가 남긴 정상상태 오차');
legend('폐루프', '개루프 (K 와 무관하게 일정)', 'Location','southwest');
title('K 를 키울수록 모델 오차도 눌린다');
end


function fig_w01_sensitivity()
% 두 장면이 사실 같은 식이다 — 1/(1+KG)
G  = plant_msd();
g0 = dcgain(G);
Ks = logspace(-1, 2.5, 200);

figure('Position',[60 60 1000 420]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
loglog(Ks, 1./(1 + Ks*g0), 'LineWidth', 2.8); hold on; grid on;
for Kp = [1 5 20 100]
    loglog(Kp, 1/(1+Kp*g0), 'o', 'MarkerSize', 10, 'LineWidth', 2.2, ...
           'HandleVisibility','off');
    text(Kp*1.15, 1/(1+Kp*g0), sprintf('K=%d : %.3f', Kp, 1/(1+Kp*g0)), ...
         'FontSize', 10);
end
xlabel('이득 K'); ylabel('1/(1+K G(0))');
title('외란도 모델오차도 이 값만큼 줄어든다');

nexttile
w = logspace(-2, 2, 500);
hold on; grid on;
for Kp = [1 5 20 100]
    S = 1/(1 + Kp*G);
    semilogx(w, 20*log10(squeeze(abs(freqresp(S, w)))), 'LineWidth', 2, ...
             'DisplayName', sprintf('K = %d', Kp));
end
set(gca,'XScale','log'); yline(0,'k--','HandleVisibility','off');
xlabel('주파수 [rad s^{-1}]'); ylabel('|S| = |1/(1+KG)|  [dB]');
legend('Location','southeast'); ylim([-45 15]);
title('주파수로 보면 — 9~10주차에서 다시 만난다');
end

% ======================================================================
%  2주차 추가 그림
% ======================================================================

function dg_modeling_steps()
% 모델링 네 단계를 한 줄 흐름으로
dg_new(16, 4.2, '물리에서 전달함수까지 — 네 단계');
set(gcf, 'Position', [80 80 1180 340]);

b1 = dg_block(2.2, 2.5, 2.6, 1.2, '장치 그림',   [0.93 0.93 0.93]);
b2 = dg_block(6.0, 2.5, 2.6, 1.2, '자유물체도', [1.00 0.95 0.85]);
b3 = dg_block(9.8, 2.5, 2.6, 1.2, '미분방정식', [0.88 0.93 1.00]);
b4 = dg_block(13.6, 2.5, 2.6, 1.2, '전달함수',  [0.90 1.00 0.90]);

dg_arrow(b1.R, b2.L, '힘을 센다');
dg_arrow(b2.R, b3.L, 'F = ma');
dg_arrow(b3.R, b4.L, '라플라스');

text(2.2, 1.35, '무엇이 어디에 붙어 있나', 'HorizontalAlignment','center', ...
     'FontSize', 10, 'Color',[0.45 0.45 0.45]);
text(6.0, 1.35, '질량 하나에 걸리는 힘', 'HorizontalAlignment','center', ...
     'FontSize', 10, 'Color',[0.45 0.45 0.45]);
text(9.8, 1.35, '시간의 함수', 'HorizontalAlignment','center', ...
     'FontSize', 10, 'Color',[0.45 0.45 0.45]);
text(13.6, 1.35, 's 의 함수', 'HorizontalAlignment','center', ...
     'FontSize', 10, 'Color',[0.45 0.45 0.45]);
text(8.0, 0.5, '이 순서를 건너뛰지 않는 것이 요령이다. 그림 없이 식부터 쓰면 반드시 부호를 틀린다', ...
     'HorizontalAlignment','center', 'FontSize', 10, 'Color',[0.30 0.30 0.30]);
end


function fig_w02_damping()
% 감쇠 상태 다섯 가지 — 극점 위치와 시간응답을 나란히
s  = tf('s');
wn = 1;
cases = { '과감쇠  \zeta = 2.0',    2.0
          '임계감쇠 \zeta = 1.0',   1.0
          '부족감쇠 \zeta = 0.7',   0.707
          '부족감쇠 \zeta = 0.3',   0.3
          '무감쇠  \zeta = 0.0',    0.0 };
t = (0:0.02:20)';

figure('Position',[60 60 1000 460]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
hold on; grid on; axis equal;
for i = 1:size(cases,1)
    z = cases{i,2};
    G = wn^2/(s^2 + 2*z*wn*s + wn^2);
    p = pole(G);
    plot(real(p), imag(p), 'x', 'MarkerSize', 14, 'LineWidth', 3, ...
         'DisplayName', cases{i,1});
end
tt = linspace(pi/2, 3*pi/2, 200);
plot(wn*cos(tt), wn*sin(tt), ':', 'Color',[0.6 0.6 0.6], ...
     'HandleVisibility','off', 'LineWidth', 1.3);
xline(0,'k-','HandleVisibility','off'); yline(0,'k-','HandleVisibility','off');
xlim([-2.6 0.4]); ylim([-1.3 1.3]);
xlabel('실수부'); ylabel('허수부'); legend('Location','southwest');
title('극점이 어디에 있는가 (점선 = 반지름 \omega_n)');

nexttile
hold on; grid on;
for i = 1:size(cases,1)
    z = cases{i,2};
    G = wn^2/(s^2 + 2*z*wn*s + wn^2);
    plot(t, step(G, t), 'LineWidth', 2, 'DisplayName', cases{i,1});
end
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력'); ylim([0 2.1]);
legend('Location','southeast');
title('그때 응답이 어떻게 생기는가');
end


function fig_w02_pole_to_time()
% 극점 하나를 옮겨 가며 응답이 어떻게 변하는지 — 실수부와 허수부를 따로
s = tf('s');
t = (0:0.02:14)';

figure('Position',[60 60 1000 520]);
tiledlayout(2,2,'TileSpacing','compact');

% --- 실수부만 바꾼다 (같은 진동수, 다른 감쇠) ---
wd = 1.5;
sgs = [0.2 0.5 1.0];

nexttile
hold on; grid on;
for sg = sgs
    plot([-sg -sg], [-wd wd], ':', 'Color',[0.7 0.7 0.7], 'HandleVisibility','off');
    plot(-sg,  wd, 'x', 'MarkerSize', 14, 'LineWidth', 3, ...
         'DisplayName', sprintf('\\sigma = %.1f', sg));
    plot(-sg, -wd, 'x', 'MarkerSize', 14, 'LineWidth', 3, 'HandleVisibility','off');
end
xline(0,'k-','HandleVisibility','off'); yline(0,'k-','HandleVisibility','off');
xlim([-1.4 0.3]); ylim([-2 2]);
xlabel('실수부'); ylabel('허수부'); legend('Location','northwest');
title('실수부만 바꾼다 (허수부 고정)');

nexttile
hold on; grid on;
for sg = sgs
    G = (sg^2+wd^2)/(s^2 + 2*sg*s + sg^2 + wd^2);
    plot(t, step(G, t), 'LineWidth', 2, 'DisplayName', sprintf('\\sigma = %.1f', sg));
end
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력');
legend('Location','northeast');
title('왼쪽으로 갈수록 **빨리 사그라든다** (진동수는 그대로)');

% --- 허수부만 바꾼다 ---
sg = 0.4;
wds = [0.8 1.6 3.2];

nexttile
hold on; grid on;
for wq = wds
    plot(-sg,  wq, 'x', 'MarkerSize', 14, 'LineWidth', 3, ...
         'DisplayName', sprintf('\\omega_d = %.1f', wq));
    plot(-sg, -wq, 'x', 'MarkerSize', 14, 'LineWidth', 3, 'HandleVisibility','off');
end
plot([-sg -sg], [-4 4], ':', 'Color',[0.7 0.7 0.7], 'HandleVisibility','off');
xline(0,'k-','HandleVisibility','off'); yline(0,'k-','HandleVisibility','off');
xlim([-1.0 0.3]); ylim([-4 4]);
xlabel('실수부'); ylabel('허수부'); legend('Location','northwest');
title('허수부만 바꾼다 (실수부 고정)');

nexttile
hold on; grid on;
for wq = wds
    G = (sg^2+wq^2)/(s^2 + 2*sg*s + sg^2 + wq^2);
    plot(t, step(G, t), 'LineWidth', 2, 'DisplayName', sprintf('\\omega_d = %.1f', wq));
end
yline(1,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('출력');
legend('Location','northeast');
title('위로 갈수록 **빨리 흔들린다** (사그라드는 속도는 그대로)');
end


function fig_w02_tf_limits()
% 전달함수가 못 다루는 것 세 가지
s = tf('s');
G = plant_msd();
t = (0:0.01:25)';

figure('Position',[60 60 1000 520]);
tiledlayout(2,2,'TileSpacing','compact');

% (1) 초기조건
nexttile
[A,B,C,D] = ssdata(ss(G));
y0 = initial(ss(A,B,C,D), [0.8; 0], t);
plot(t, step(G,t), 'LineWidth', 2.2); hold on; grid on;
plot(t, step(G,t) + y0, 'LineWidth', 2.2);
xlabel('시간 [s]'); ylabel('변위 x');
legend('전달함수로 구한 것 (x(0)=0 가정)', '실제 (x(0)=0.8)', 'Location','southeast');
title('한계 1 — 전달함수는 초기조건이 0 이라고 본다');

% (2) 포화
nexttile
u  = 3*ones(size(t));
ul = min(u, 1.2);
plot(t, lsim(G, u, t), 'LineWidth', 2.2); hold on; grid on;
plot(t, lsim(G, ul, t), 'LineWidth', 2.2);
xlabel('시간 [s]'); ylabel('변위 x');
legend('전달함수 (입력 3)', '실제 (구동기가 1.2 까지만)', 'Location','southeast');
title('한계 2 — 포화 같은 비선형을 모른다');

% (3) 동작점
nexttile
th = linspace(-pi, pi, 400);
plot(th, sin(th), 'LineWidth', 2.4); hold on; grid on;
plot(th, th, '--', 'LineWidth', 2);
xline(0, 'k-'); yline(0, 'k-');
xlim([-pi pi]); ylim([-1.6 1.6]);
xlabel('\theta [rad]'); ylabel('sin\theta');
legend('실제 sin\theta', '선형 근사 \theta', 'Location','southeast');
title('한계 3 — 한 동작점 근처에서만 맞다 (3주차)');

% (4) 그래도 왜 쓰는가
nexttile
w = logspace(-2, 2, 500);
semilogx(w, 20*log10(squeeze(abs(freqresp(G, w)))), 'LineWidth', 2.4);
grid on; xlabel('주파수 [rad s^{-1}]'); ylabel('크기 [dB]');
title('그래도 쓰는 이유 — 곱하고 나누기만 하면 되니까');
text(0.02, -35, {'미분방정식을 풀지 않고','블록을 곱셈으로 잇는다', ...
                 '설계는 여기서 한다'}, 'FontSize', 11);
end

% ======================================================================
%  3주차 추가 그림
% ======================================================================



function fig_w03_state_meaning()
% "상태" 가 무엇인지 — 같은 위치인데 앞일이 다르다
G = plant_msd();
[A,B,C,~] = ssdata(ss(G));
t = (0:0.02:25)';

x0s = { '위치 1, 속도 0  (가만히 놓았다)',  [1; 0]
        '위치 1, 속도 -1 (안쪽으로 던졌다)', [1; -1]
        '위치 1, 속도 +1 (바깥으로 던졌다)', [1;  1] };
% 색을 고정한다. 마커를 따로 그리면 색 순서가 밀려 범례 색이 어긋난다
col = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.93 0.69 0.13];

figure('Position',[60 60 1060 440]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
hold on; grid on;
for i = 1:3
    y = initial(ss(A,B,C,0), x0s{i,2}, t);
    plot(t, y, 'LineWidth', 2.2, 'Color', col(i,:), 'DisplayName', x0s{i,1});
end
plot(0, 1, 'ko', 'MarkerSize', 11, 'LineWidth', 2, 'HandleVisibility','off');
yline(0,'k--','HandleVisibility','off');
xlabel('시간 [s]'); ylabel('위치 x [m]');
legend('Location','northeast');
title('출발 위치가 같아도 앞일이 다르다');

nexttile
hold on; grid on;
for i = 1:3
    [~,~,X] = lsim(ss(A,B,eye(2),[0;0]), zeros(size(t)), t, x0s{i,2});
    plot(X(:,1), X(:,2), 'LineWidth', 2.2, 'Color', col(i,:), ...
         'DisplayName', x0s{i,1});
    plot(x0s{i,2}(1), x0s{i,2}(2), 'o', 'MarkerSize', 10, 'LineWidth', 2.2, ...
         'Color', col(i,:), 'HandleVisibility','off');
end
xline(0,'k-','HandleVisibility','off'); yline(0,'k-','HandleVisibility','off');
axis equal; xlim([-1.6 1.6]); ylim([-1.6 1.6]);
xlabel('위치 x [m]'); ylabel('속도 dx/dt [m/s]');
legend('Location','northeast');
title({'위치 하나로는 부족하다', '속도까지 있어야 앞일이 정해진다'});
end


function fig_w03_ss_vs_tf()
% 상태공간과 전달함수가 정말 같은가
[G, p] = plant_msd();
sys = ss(p.A, p.B, p.C, p.D);
t = (0:0.02:30)';
u = [zeros(sum(t<2),1); ones(sum(t>=2),1)];

figure('Position',[60 60 1000 430]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
y1 = lsim(G,   u, t);
y2 = lsim(sys, u, t);
plot(t, y1, 'LineWidth', 3); hold on; grid on;
plot(t, y2, '--', 'LineWidth', 2);
xlabel('시간 [s]'); ylabel('위치 x [m]');
legend('전달함수 G(s)', '상태공간 (A,B,C,D)', 'Location','southeast');
title(sprintf('완전히 겹친다 (최대 차이 %.2e)', max(abs(y1-y2))));

nexttile
pz = pole(G);  ev = eig(p.A);
plot(real(pz), imag(pz), 'x', 'MarkerSize', 18, 'LineWidth', 3.5); hold on; grid on;
plot(real(ev), imag(ev), 'o', 'MarkerSize', 13, 'LineWidth', 2.5);
xline(0,'k-'); yline(0,'k-');
xlim([-0.5 0.2]); ylim([-1.4 1.4]);
xlabel('실수부'); ylabel('허수부');
legend('전달함수의 극점 pole(G)', 'A 의 고유값 eig(A)', 'Location','northwest');
title('극점 = 고유값. 같은 숫자다');
end


function fig_w03_why_ss()
% 상태공간이 좋은 이유 세 가지
[G, p] = plant_msd();
t = (0:0.02:25)';

figure('Position',[60 60 1000 520]);
tiledlayout(2,2,'TileSpacing','compact');

% (1) 내부 상태가 보인다
nexttile
[~,~,X] = lsim(ss(p.A,p.B,eye(2),[0;0]), ones(size(t)), t, [0;0]);
plot(t, X(:,1), 'LineWidth', 2.2); hold on; grid on;
plot(t, X(:,2), 'LineWidth', 2.2);
xlabel('시간 [s]'); ylabel('상태');
legend('x_1 = 위치', 'x_2 = 속도', 'Location','northeast');
title('이유 1 — 안이 보인다 (속도까지 함께 나온다)');

% (2) 초기조건을 다룬다
nexttile
hold on; grid on;
for x0 = {[0;0], [0.6;0], [0;1.2]}
    y = step(ss(p.A,p.B,p.C,p.D), t) + initial(ss(p.A,p.B,p.C,0), x0{1}, t);
    plot(t, y, 'LineWidth', 2, 'DisplayName', sprintf('x(0) = [%.1f %.1f]', x0{1}));
end
xlabel('시간 [s]'); ylabel('위치 x');
legend('Location','northeast');
title('이유 2 — 초기조건을 그대로 넣는다');

% (3) 입출력이 여러 개여도 된다
nexttile
% 두 대의 수레가 스프링으로 묶인 시스템. 좌우 성질을 일부러 다르게 두어
% 네 경로가 서로 구분되게 만든다 (대칭이면 두 곡선이 완전히 포개진다)
A2 = [0 1 0 0; -2.0 -0.30 1.0 0; 0 0 0 1; 1.0 0 -0.8 -0.15];
B2 = [0 0; 1 0; 0 0; 0 1.6];
C2 = [1 0 0 0; 0 0 1 0];
sys2 = ss(A2, B2, C2, zeros(2,2));
y2 = step(sys2, t);
plot(t, y2(:,1,1), 'LineWidth', 2); hold on; grid on;
plot(t, y2(:,2,1), 'LineWidth', 2);
plot(t, y2(:,1,2), '--', 'LineWidth', 2);
plot(t, y2(:,2,2), '--', 'LineWidth', 2);
xlabel('시간 [s]'); ylabel('출력');
legend('u_1 \rightarrow y_1','u_1 \rightarrow y_2','u_2 \rightarrow y_1','u_2 \rightarrow y_2', ...
       'Location','northwest', 'NumColumns', 2);
title('이유 3 — 입력 2개 출력 2개도 행렬 하나로');

% (4) 그래서 12~14주차
% [주의] 한글이 섞이므로 FontName 을 Consolas 같은 영문 전용으로 두면 안 된다.
%        네모(두부) 로 깨진다. 기본 글꼴을 쓰고 자리는 x 좌표로 맞춘다.
nexttile
axis off; xlim([0 1]); ylim([0 1]);
text(0.00, 0.96, '이유 4 — 12~14주차의 도구가 전부 여기서 나온다', ...
     'FontSize', 12, 'FontWeight','bold');
rows = { '12주차', 'eig(A)',            '모드와 안정성'
         '',       'ctrb(A,B)',         '제어할 수 있는가'
         '',       'obsv(A,C)',         '볼 수 있는가'
         '13주차', 'place(A,B,p)',      '극점을 원하는 자리에 정확히'
         '',       '',                  '근궤적처럼 정해진 길을 안 따라간다'
         '14주차', 'place(A'',C'',p)''', '못 재는 상태를 만들어 낸다' };
yv = [0.80 0.71 0.62 0.47 0.38 0.23];
for i = 1:size(rows,1)
    text(0.00, yv(i), rows{i,1}, 'FontSize', 11, 'FontWeight','bold');
    text(0.17, yv(i), rows{i,2}, 'FontSize', 11, 'Color', [0.10 0.35 0.65]);
    text(0.50, yv(i), rows{i,3}, 'FontSize', 11);
end
text(0.00, 0.07, '전달함수로는 이 가운데 어느 것도 할 수 없습니다.', ...
     'FontSize', 11, 'FontWeight','bold', 'Color', [0.65 0.15 0.15]);
end


function fig_w03_how_narrow()
% 얼마나 좁아야 "좁은" 건가 — 숫자로
th = linspace(0, deg2rad(60), 300);

figure('Position',[60 60 1000 430]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
plot(rad2deg(th), 100*abs(sin(th)-th)./max(abs(sin(th)),eps), 'LineWidth', 2.6);
hold on; grid on;
yline(1, 'r--', 'LineWidth', 1.6);
yline(5, ':', 'LineWidth', 1.6, 'Color',[0.85 0.55 0.15]);
xline(rad2deg(fzero(@(x) abs(sin(x)-x)/abs(sin(x))-0.01, 0.3)), 'r:', 'LineWidth', 1.6);
xlabel('각도 [도]'); ylabel('sin\theta 를 \theta 로 바꿀 때의 오차 [%]');
legend('실제 오차', '1 % 선', '5 % 선', 'Location','northwest');
title('몇 도까지 "작은 각" 인가');

nexttile
thd = [5 10 14 20 30 45];
err = zeros(size(thd));
for i = 1:numel(thd)
    x = deg2rad(thd(i));
    err(i) = 100*abs(sin(x)-x)/abs(sin(x));
end
bar(1:numel(thd), err, 0.55); grid on;
set(gca,'XTick',1:numel(thd),'XTickLabel', compose('%d도', thd));
ylabel('오차 [%]');
for i = 1:numel(thd)
    text(i, err(i)+0.4, sprintf('%.1f', err(i)), ...
         'HorizontalAlignment','center', 'FontWeight','bold');
end
ylim([0 max(err)*1.25]);
title('실무 기준 : 14도 안쪽이면 1 % 미만');
end


function local_arrowhead(x, y, dir, L)
%LOCAL_ARROWHEAD  (x,y) 에 dir 방향의 삼각형 화살촉을 그린다
%  quiver 의 MaxHeadSize 는 축 비율에 따라 화살촉이 안 보이는 일이 잦아
%  patch 로 직접 그린다.
dir = dir/abs(dir);
tip  = (x + 1i*y) + dir*L*0.5;
back = (x + 1i*y) - dir*L*0.5;
sideL = back + 1i*dir*L*0.30;
sideR = back - 1i*dir*L*0.30;
patch(real([tip sideL sideR]), imag([tip sideL sideR]), [0.00 0.30 0.55], ...
      'EdgeColor','none', 'HandleVisibility','off');
end


function fig_w09_phase_asym()
% 위상 점근선 : 꺾임주파수의 1/10 에서 시작해 10 배에서 끝나는 직선
s = tf('s');
L = 10/(s*(s+1)*(0.1*s+1));
w = logspace(-2, 3, 800);

ramp = @(wc) -45*min(max(log10(w/(wc/10)), 0), 2);   % 1 차 극점의 위상 점근선
p_int = -90*ones(size(w));
p_p1  = ramp(1);
p_p2  = ramp(10);
p_sum = p_int + p_p1 + p_p2;
[~, ph] = bode(L, w);  ph = squeeze(ph).';

figure('Position',[60 60 1000 620]);
tiledlayout(2,1,'TileSpacing','compact');

nexttile
semilogx(w, zeros(size(w)), 'LineWidth', 2.2, 'Color',[0.30 0.75 0.93]); hold on; grid on
semilogx(w, p_int, 'LineWidth', 2.2, 'Color',[0.85 0.33 0.10]);
semilogx(w, p_p1,  'LineWidth', 2.2, 'Color',[0.93 0.69 0.13]);
semilogx(w, p_p2,  'LineWidth', 2.2, 'Color',[0.49 0.18 0.56]);
xline(0.1,':','LineWidth',1.2); xline(1,':','LineWidth',1.2);
xline(10,':','LineWidth',1.2);  xline(100,':','LineWidth',1.2);
ylim([-100 20]); ylabel('위상 [도]');
legend('상수 10 : 0°', '적분기 1/s : -90° 고정', ...
       '극점 s+1 : 0.1~10 에서 내려감', '극점 0.1s+1 : 1~100 에서 내려감', ...
       'Location','southwest');
title('조각마다의 위상 점근선 — 꺾임주파수의 1/10 에서 10 배까지 -45°/dec');

nexttile
semilogx(w, p_sum, '--', 'LineWidth', 2.8, 'Color',[0.85 0.20 0.15]); hold on; grid on
semilogx(w, ph, 'LineWidth', 2.2, 'Color',[0.00 0.45 0.74]);
yline(-180, 'k:', 'LineWidth', 1.5);
xline(0.1,':'); xline(1,':'); xline(10,':'); xline(100,':');
ylim([-290 -70]); xlabel('주파수 [rad s^{-1}]'); ylabel('위상 [도]');
legend('세 조각을 더한 점근선', '실제 위상 (bode)', 'Location','southwest');
title('더하면 실제 위상과 거의 같다 (최대 어긋남 6.3°)');
end


function fig_w09_hand_margin()
% 점근선만으로 교차주파수와 위상여유를 읽는다
s = tf('s');
L = 10/(s*(s+1)*(0.1*s+1));
w = logspace(-2, 3, 800);

mag_as = 20*log10(10) - 20*log10(w) ...
         - 20*log10(max(w/1,1)) - 20*log10(max(w/10,1));
mag_tr = 20*log10(squeeze(abs(freqresp(L, w)))).';
ramp = @(wc) -45*min(max(log10(w/(wc/10)), 0), 2);
ph_as = -90 + ramp(1) + ramp(10);
[~, ph_tr] = bode(L, w);  ph_tr = squeeze(ph_tr).';

wa = 10^0.5;                       % 점근선이 0 dB 를 지나는 곳
[~, pmT, ~, wcT] = margin(L);

figure('Position',[60 60 1000 620]);
tiledlayout(2,1,'TileSpacing','compact');

nexttile
semilogx(w, mag_as, '--', 'LineWidth', 2.6, 'Color',[0.85 0.20 0.15]); hold on; grid on
semilogx(w, mag_tr, 'LineWidth', 2.2, 'Color',[0.00 0.45 0.74]);
yline(0, 'k-', 'LineWidth', 1.2);
plot(wa,  0, 'o', 'MarkerSize', 11, 'LineWidth', 2.4, 'Color',[0.85 0.20 0.15]);
plot(wcT, 0, 'o', 'MarkerSize', 11, 'LineWidth', 2.4, 'Color',[0.00 0.45 0.74]);
text(wa*1.6, 20, sprintf('점근선 \\omega_c = %.2f\n실제 \\omega_c = %.3f\n(차이 %.1f %%)', ...
     wa, wcT, 100*(wa-wcT)/wcT), 'FontWeight','bold', 'FontSize', 10);
ylim([-100 45]); ylabel('크기 [dB]');
legend('점근선의 합', '실제 (bode)', 'Location','southwest');
title('1 단계 : 점근선이 0 dB 를 지나는 곳이 교차주파수');

nexttile
semilogx(w, ph_as, '--', 'LineWidth', 2.6, 'Color',[0.85 0.20 0.15]); hold on; grid on
semilogx(w, ph_tr, 'LineWidth', 2.2, 'Color',[0.00 0.45 0.74]);
yline(-180, 'k:', 'LineWidth', 1.5);
xline(wa, ':', 'LineWidth', 1.8, 'Color',[0.85 0.20 0.15]);
pa = interp1(log(w), ph_as, log(wa));
plot(wa, pa, 'o', 'MarkerSize', 11, 'LineWidth', 2.4, 'Color',[0.85 0.20 0.15]);
text(wa*1.6, -110, sprintf('점근선 위상 %.0f°  \\rightarrow  PM = %.0f°\n실제 PM = %.2f°  (거의 불안정)', ...
     pa, 180+pa, pmT), 'FontWeight','bold', 'FontSize', 10);
ylim([-290 -70]); xlabel('주파수 [rad s^{-1}]'); ylabel('위상 [도]');
legend('점근선의 합', '실제 (bode)', 'Location','southwest');
title('2 단계 : 그 자리에서 위상을 읽고 180° 를 더하면 위상여유');
end


function fig_w10_contour()
% 나이퀴스트 경로 : s 평면에서 우반면을 통째로 감싸는 길
figure('Position',[60 60 1060 460]);
tiledlayout(1,2,'TileSpacing','compact');

% ---- 왼쪽 : s 평면의 경로
nexttile
R  = 3.0;
th = linspace(-pi/2, pi/2, 300);
hold on; grid on
% 무한대 반원
plot(R*cos(th), R*sin(th), 'LineWidth', 2.6, 'Color',[0.00 0.45 0.74]);
% 허수축
plot([0 0], [-R R], 'LineWidth', 2.6, 'Color',[0.00 0.45 0.74]);
% 진행 방향 (허수축은 위로, 반원은 시계 방향으로 되돌아온다)
local_arrowhead(0, -1.5,  1i, 0.55);
local_arrowhead(0,  1.5,  1i, 0.55);
aTh = 0.55;
local_arrowhead(R*cos(aTh), R*sin(aTh), -1i*exp(1i*aTh), 0.55);
% 극점
plot(1, 0, 'x', 'MarkerSize', 15, 'LineWidth', 3, 'Color',[0.85 0.20 0.15]);
plot(-3, 0, 'x', 'MarkerSize', 15, 'LineWidth', 3, 'Color',[0.5 0.5 0.5]);
text(1.1, -0.45, 'P = 1', 'Color',[0.85 0.20 0.15], 'FontWeight','bold');
text(-3.9, -0.45, '좌반면 극점 (안 셈)', 'Color',[0.45 0.45 0.45]);
text(0.15, -3.05, '\omega : -\infty \rightarrow +\infty', 'FontWeight','bold', ...
     'Color',[0.00 0.45 0.74]);
text(-3.9, 3.05, '반지름 \rightarrow \infty 인 반원', 'Color',[0.00 0.45 0.74], ...
     'FontWeight','bold');
xline(0,'k-'); yline(0,'k-');
xlim([-4 4]); ylim([-3.4 3.4]); axis square
xlabel('실수부'); ylabel('허수부');
title('s 평면 : 우반면을 통째로 감싼다');

% ---- 오른쪽 : 그 길을 L 로 옮긴 결과
nexttile
s  = tf('s');
L  = 10/((s-1)*(s+3));
w  = logspace(-3, 3, 4000);
[re, im] = nyquist(L, w);
re = squeeze(re);  im = squeeze(im);
hold on; grid on
plot(re,  im,  'LineWidth', 2.4, 'Color',[0.00 0.45 0.74]);
plot(re, -im,  'LineWidth', 2.4, 'Color',[0.00 0.45 0.74]);
plot(-1, 0, 'p', 'MarkerSize', 17, 'LineWidth', 1.5, ...
     'MarkerFaceColor',[0.85 0.20 0.15], 'MarkerEdgeColor','k');
text(-1.0, 0.42, '-1 점', 'Color',[0.85 0.20 0.15], 'FontWeight','bold', ...
     'HorizontalAlignment','center');
xline(0,'k-'); yline(0,'k-');
xlim([-4 1]); ylim([-2.5 2.5]); axis square
xlabel('실수부'); ylabel('허수부');
title('L 평면 : 그 길이 이렇게 옮겨진다');
end


function fig_w10_encircle()
% 감은 횟수 N 을 실제로 세어 본다 (개루프가 불안정한 예)
s  = tf('s');
Gu = 1/((s-1)*(s+3));
w  = logspace(-3, 3, 6000);
Ks = [1 10];

figure('Position',[60 60 1080 470]);
tiledlayout(1,2,'TileSpacing','compact');

for c = 1:2
    K = Ks(c);
    [re, im] = nyquist(K*Gu, w);
    re = squeeze(re);  im = squeeze(im);

    nexttile
    hold on; grid on
    plot(re,  im, 'LineWidth', 2.6, 'Color',[0.00 0.45 0.74]);
    plot(re, -im, 'LineWidth', 2.6, 'Color',[0.00 0.45 0.74]);

    % 진행 방향 화살표 (위쪽 반은 w>0, 아래쪽 반은 w<0 쪽으로 되돌아온다)
    z  = re + 1i*im;
    dl = [0; cumsum(abs(diff(z)))];
    for frac = [0.25 0.6 0.9]
        j = find(dl >= frac*dl(end), 1);
        j = min(max(j, 2), numel(z)-1);
        d = z(j+1) - z(j-1);  d = d/abs(d);
        local_arrowhead(re(j),  im(j),  d,        0.075*range(xlim));
        % 켤레쪽은 w 가 -무한대에서 0 으로 오는 구간이므로 진행 방향이 뒤집힌다
        local_arrowhead(re(j), -im(j), -conj(d),  0.075*range(xlim));
    end

    % -1 점과 시험 광선
    plot(-1, 0, 'p', 'MarkerSize', 17, 'LineWidth', 1.5, ...
         'MarkerFaceColor',[0.85 0.20 0.15], 'MarkerEdgeColor','k');
    plot([-1 -1], [0 -3], ':', 'LineWidth', 2, 'Color',[0.85 0.20 0.15]);

    xline(0,'k-'); yline(0,'k-');
    lim = max(1.6, abs(K/3)*1.25);
    xlim([-lim 0.6]); ylim([-lim*0.8 lim*0.8]);

    if K == 1
        N = 0;  txt = '별이 곡선 바깥 \rightarrow 감지 않았다';
    else
        N = -1; txt = '별이 곡선 안쪽 \rightarrow 반시계로 한 바퀴';
    end
    Z = N + 1;
    if Z == 0, verdict = '안정'; cc = [0.15 0.45 0.20];
    else,      verdict = '불안정'; cc = [0.85 0.20 0.15]; end

    text(-lim*0.96, -lim*0.50, txt, 'FontWeight','bold', 'FontSize', 10);
    text(-lim*0.96, -lim*0.62, sprintf('N = %d,   P = 1', N), ...
         'FontWeight','bold', 'FontSize', 10);
    text(-lim*0.96, -lim*0.74, sprintf('Z = N + P = %d  \\rightarrow  %s', Z, verdict), ...
         'FontWeight','bold', 'FontSize', 11, 'Color', cc);

    xlabel('실수부'); ylabel('허수부');
    title(sprintf('K = %g  (\\omega=0 에서 %.2f 출발)', K, -K/3));
end
end


function fig_w07_angle_def()
% 각도 부족 : 목표 극점에서 180 도에 얼마나 모자라는지 재고 영점으로 채운다
s  = tf('s');
G  = 1/(s*(s+4));
sd = -4 + 6.8572i;
P  = [0 -4];
angG = rad2deg(angle(evalfr(G, sd)));
phi  = mod(-180 - angG, 360);
zp   = 4 + imag(sd)/tand(phi);

figure('Position',[60 60 1080 470]);
tiledlayout(1,2,'TileSpacing','compact');

% ---- 왼쪽 : 영점을 넣기 전
nexttile
hold on; grid on
plot(real(P), imag(P), 'x', 'MarkerSize', 14, 'LineWidth', 3, 'Color',[0.85 0.20 0.15]);
plot(real(sd), imag(sd), 'p', 'MarkerSize', 16, 'LineWidth', 2, ...
     'MarkerFaceColor',[0.93 0.69 0.13], 'MarkerEdgeColor','k');
cols = [0.00 0.45 0.74; 0.47 0.67 0.19];
for i = 1:2
    v = sd - P(i);
    quiver(real(P(i)), imag(P(i)), real(v), imag(v), 0, ...
           'LineWidth', 2.2, 'MaxHeadSize', 0.3, 'Color', cols(i,:));
    text(real(P(i))+real(v)*0.45-1.4, imag(P(i))+imag(v)*0.45+0.5, ...
         sprintf('%.1f°', rad2deg(angle(v))), 'Color', cols(i,:), 'FontWeight','bold');
end
text(real(sd)+0.5, imag(sd)+0.6, 's_d (목표 극점)', 'FontWeight','bold');
xline(0,'k-'); yline(0,'k-');
sumTh = sum(rad2deg(angle(sd - P)));
text(-17, -2.2, sprintf('극점 각의 합 = %.1f°   \\rightarrow   \\angle G(s_d) = -%.1f°', ...
     sumTh, sumTh), 'FontWeight','bold', 'FontSize', 11);
text(-17, -3.6, sprintf('-180° 가 되려면 %.1f° 를 보태야 한다', phi), ...
     'FontWeight','bold', 'FontSize', 11, 'Color',[0.85 0.20 0.15]);
xlim([-18 3]); ylim([-5 10]);
xlabel('실수부'); ylabel('허수부');
title('영점을 넣기 전 : 각이 모자란다');

% ---- 오른쪽 : 영점을 넣은 뒤
nexttile
hold on; grid on
plot(real(P), imag(P), 'x', 'MarkerSize', 14, 'LineWidth', 3, 'Color',[0.85 0.20 0.15]);
plot(-zp, 0, 'o', 'MarkerSize', 12, 'LineWidth', 3, 'Color',[0.15 0.45 0.20]);
plot(real(sd), imag(sd), 'p', 'MarkerSize', 16, 'LineWidth', 2, ...
     'MarkerFaceColor',[0.93 0.69 0.13], 'MarkerEdgeColor','k');
for i = 1:2
    v = sd - P(i);
    quiver(real(P(i)), imag(P(i)), real(v), imag(v), 0, ...
           'LineWidth', 1.6, 'MaxHeadSize', 0.3, 'Color', [0.65 0.65 0.65]);
end
vz = sd - (-zp);
quiver(-zp, 0, real(vz), imag(vz), 0, 'LineWidth', 2.6, 'MaxHeadSize', 0.25, ...
       'Color',[0.15 0.45 0.20]);
text(-zp+2.5, 1.4, sprintf('영점이 채우는 각 %.1f°', rad2deg(angle(vz))), ...
     'Color',[0.15 0.45 0.20], 'FontWeight','bold');
text(-zp-0.3, -1.2, sprintf('%.2f', -zp), 'Color',[0.15 0.45 0.20], ...
     'FontWeight','bold', 'HorizontalAlignment','center');
xline(0,'k-'); yline(0,'k-');
Ktot = 1/abs(evalfr((s+zp)*G, sd));
text(-17, -2.2, sprintf('\\angle C(s_d)G(s_d) = -180°'), 'FontWeight','bold', ...
     'FontSize', 11, 'Color',[0.15 0.45 0.20]);
text(-17, -3.6, sprintf('크기 조건 : K = %.2f', Ktot), 'FontWeight','bold', 'FontSize', 11);
xlim([-18 3]); ylim([-5 10]);
xlabel('실수부'); ylabel('허수부');
title('영점 하나로 부족분을 정확히 채웠다');
end


function fig_w06_angle_cond()
% 각도 조건 : 시험점에서 각 극점을 바라본 각을 더해 180 도인지 본다
P  = [-1 -3];
S  = [-2+2i, -0.5+2i];
ttl = {'시험점 s = -2 + 2j', '시험점 s = -0.5 + 2j'};

figure('Position',[60 60 1060 460]);
tiledlayout(1,2,'TileSpacing','compact');

for c = 1:2
    nexttile
    st = S(c);
    hold on; grid on
    plot(real(P), imag(P), 'x', 'MarkerSize', 14, 'LineWidth', 3, ...
         'Color', [0.85 0.20 0.15]);
    plot(real(st), imag(st), 'o', 'MarkerSize', 11, 'LineWidth', 2.4, ...
         'Color', [0.00 0.45 0.74], 'MarkerFaceColor', 'w');
    th = zeros(1,2);
    col = [0.00 0.45 0.74; 0.47 0.67 0.19];
    for i = 1:2
        v = st - P(i);
        th(i) = rad2deg(angle(v));
        quiver(real(P(i)), imag(P(i)), real(v), imag(v), 0, ...
               'LineWidth', 2.2, 'MaxHeadSize', 0.35, 'Color', col(i,:));
        off = [-0.55 0.30; 0.18 -0.45];
        text(real(P(i))+real(v)*0.5 + off(i,1), ...
             imag(P(i))+imag(v)*0.5 + off(i,2), ...
             sprintf('\\theta_%d = %.1f°', i, th(i)), ...
             'Color', col(i,:), 'FontWeight','bold');
        text(real(P(i)), -0.32, sprintf('%g', P(i)), ...
             'HorizontalAlignment','center', 'Color',[0.85 0.20 0.15], ...
             'FontWeight','bold');
    end
    xline(0,'k-'); yline(0,'k-');
    tot = sum(th);
    if abs(tot - 180) < 1e-6
        msg = sprintf('합 = %.1f° = 180°  →  궤적 위에 있다', tot);
        cc  = [0.15 0.45 0.20];
    else
        msg = sprintf('합 = %.1f° ≠ 180°  →  궤적 위에 없다', tot);
        cc  = [0.85 0.20 0.15];
    end
    text(-4.6, -1.4, msg, 'FontWeight','bold', 'Color', cc, 'FontSize', 11);
    if c == 1
        text(-4.6, -2.0, sprintf('K = |s+1||s+3| = %.2f', abs(st+1)*abs(st+3)), ...
             'FontWeight','bold', 'FontSize', 11);
    end
    xlim([-5 1]); ylim([-2.6 3.2]);
    xlabel('실수부'); ylabel('허수부'); title(ttl{c});
end
end


function fig_w06_real_axis()
% 실축 규칙 : 어떤 실축 점의 오른쪽에 있는 극·영의 개수가 홀수이면 궤적 위
P = [-1 -3 -5];  Z = -2;
brk = sort([P Z]);
seg = [-6.5 brk 0.8];

figure('Position',[60 60 1060 400]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
hold on; grid on
for i = 1:numel(seg)-1
    a = seg(i); b = seg(i+1);
    mid = (a+b)/2;
    cnt = sum([P Z] > mid);
    if mod(cnt,2) == 1
        plot([a b], [0 0], 'LineWidth', 7, 'Color', [0.00 0.45 0.74]);
    end
    text(mid, 0.42, sprintf('%d', cnt), 'HorizontalAlignment','center', ...
         'FontWeight','bold', 'FontSize', 11, ...
         'Color', [0.15 0.45 0.20]*(mod(cnt,2)==1) + [0.5 0.5 0.5]*(mod(cnt,2)==0));
end
plot(P, zeros(size(P)), 'x', 'MarkerSize', 15, 'LineWidth', 3, 'Color',[0.85 0.20 0.15]);
plot(Z, 0, 'o', 'MarkerSize', 12, 'LineWidth', 3, 'Color',[0.15 0.45 0.20]);
xline(0,'k-'); yline(0,'k-');
xlim([-6.5 0.8]); ylim([-0.8 0.9]);
set(gca,'YTick',[]);
xlabel('실수부');
title('숫자 = 그 구간에서 오른쪽에 있는 극·영의 개수');

nexttile
s = tf('s');
Lr = (s+2)/((s+1)*(s+3)*(s+5));
[rr, ~] = rlocus(Lr, logspace(-3, 4, 4000));
hold on; grid on
plot(real(rr).', imag(rr).', 'LineWidth', 2.4, 'Color', [0.00 0.45 0.74]);
plot(P, zeros(size(P)), 'x', 'MarkerSize', 14, 'LineWidth', 3, 'Color',[0.85 0.20 0.15]);
plot(Z, 0, 'o', 'MarkerSize', 11, 'LineWidth', 3, 'Color',[0.15 0.45 0.20]);
xline(0,'k-'); yline(0,'k-');
xlim([-6.5 0.8]); ylim([-3 3]);
xlabel('실수부'); ylabel('허수부');
title('실제 궤적 — 실축 부분이 왼쪽 굵은 구간과 같다');
end


function fig_w06_breakaway()
% 이탈점 : 실축 위에서 K 가 최대가 되는 곳에서 궤적이 갈라진다
sg = linspace(-2.999, -1.001, 600);
Ks = -(sg+1).*(sg+3);
[Kmax, im] = max(Ks);
sb = sg(im);

figure('Position',[60 60 1060 430]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
plot(sg, Ks, 'LineWidth', 2.8, 'Color',[0.00 0.45 0.74]); hold on; grid on
plot(sb, Kmax, 'o', 'MarkerSize', 11, 'LineWidth', 2.4, 'Color',[0.85 0.20 0.15]);
xline(sb, 'r:', 'LineWidth', 1.6);
yline(Kmax, 'r:', 'LineWidth', 1.6);
text(-2.95, Kmax*0.42, sprintf('\\sigma = %.2f 에서\nK = %.2f 로 최대', sb, Kmax), ...
     'FontWeight','bold');
ylim([0 Kmax*1.25]);
xlabel('실축 위의 위치 \sigma'); ylabel('그 점을 지나려면 필요한 K');
title('K(\sigma) = -(\sigma+1)(\sigma+3) 의 봉우리');

nexttile
s = tf('s');
[rr2, ~] = rlocus(1/((s+1)*(s+3)), logspace(-3, 4, 4000));
hold on; grid on
plot(real(rr2).', imag(rr2).', 'LineWidth', 2.4, 'Color',[0.00 0.45 0.74]);
plot([-1 -3], [0 0], 'x', 'MarkerSize', 14, 'LineWidth', 3, 'Color',[0.85 0.20 0.15]);
plot(sb, 0, 'o', 'MarkerSize', 12, 'LineWidth', 2.6, 'Color',[0.85 0.20 0.15]);
text(sb+0.18, 0.6, sprintf('이탈점 %.2f', sb), 'FontWeight','bold', ...
     'Color',[0.85 0.20 0.15]);
xline(0,'k-'); yline(0,'k-');
xlim([-5 1]); ylim([-3 3]);
xlabel('실수부'); ylabel('허수부');
title('그 봉우리 자리에서 궤적이 실축을 떠난다');
end


function fig_w06_jw_cross()
% 허수축 교차 : s = jw 를 특성방정식에 넣으면 K 와 w 가 한 번에 나온다
s = tf('s');
Lj = 1/(s*(s+1)*(s+3));
Kc = 12;  wc = sqrt(3);

figure('Position',[60 60 1060 430]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
[rj, ~] = rlocus(Lj, logspace(-3, 4, 5000));
hold on; grid on
plot(real(rj).', imag(rj).', 'LineWidth', 2.2, 'Color',[0.00 0.45 0.74]);
plot([0 -1 -3], [0 0 0], 'x', 'MarkerSize', 14, 'LineWidth', 3, 'Color',[0.85 0.20 0.15]);
plot([0 0], [wc -wc], 'o', 'MarkerSize', 12, 'LineWidth', 2.6, 'Color',[0.85 0.20 0.15]);
xline(0, 'k-', 'LineWidth', 1.2); yline(0, 'k-');
text(0.2, wc+0.35, sprintf('K = %g,  \\omega = %.3f', Kc, wc), ...
     'FontWeight','bold', 'Color',[0.85 0.20 0.15]);
xlim([-4 2]); ylim([-3.5 3.5]);
xlabel('실수부'); ylabel('허수부');
title('궤적이 허수축을 넘는 자리');

nexttile
Kv  = [4 12 16];
tt  = 0:0.02:15;
col = [0.15 0.45 0.20; 0.93 0.69 0.13; 0.85 0.20 0.15];
lab = {'K = 4  (안정)', 'K = 12 (임계)', 'K = 16 (불안정)'};
hold on; grid on
for i = 1:3
    y = step(feedback(Kv(i)*Lj, 1), tt);
    plot(tt, y, 'LineWidth', 2.4, 'Color', col(i,:), 'DisplayName', lab{i});
end
yline(1, 'k:', 'LineWidth', 1.2, 'HandleVisibility','off');
ylim([-2 4]); xlabel('시간 [s]'); ylabel('출력 y');
legend('Location','northwest');
title(sprintf('K = %g 에서 진폭이 일정한 진동 (주기 %.2f s)', Kc, 2*pi/wc));
end


function fig_w03_taylor()
% 테일러 급수 : 항을 하나씩 더하면 근사가 어디까지 따라오는가
th = linspace(-pi, pi, 600);
t1 = th;                                  % 1차까지
t3 = th - th.^3/6;                        % 3차까지
t5 = th - th.^3/6 + th.^5/120;            % 5차까지

figure('Position',[60 60 1060 430]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
plot(rad2deg(th), sin(th), 'LineWidth', 3, 'Color',[0.15 0.15 0.15]); hold on
plot(rad2deg(th), t1, '--',  'LineWidth', 2.2, 'Color',[0.00 0.45 0.74]);
plot(rad2deg(th), t3, '-.',  'LineWidth', 2.2, 'Color',[0.85 0.33 0.10]);
plot(rad2deg(th), t5, ':',   'LineWidth', 2.6, 'Color',[0.47 0.67 0.19]);
plot(0, 0, 'ko', 'MarkerFaceColor','k', 'MarkerSize', 8);
grid on; ylim([-1.6 1.6]); xlim([-180 180]);
xlabel('\theta [도]'); ylabel('값');
legend('sin\theta  (참값)', '1차까지 : \theta', ...
       '3차까지 : \theta - \theta^3/6', '5차까지', ...
       'Location','southeast');
title('전개 중심 \theta_0 = 0 에서 항을 하나씩 더한다');

nexttile
d = linspace(1, 90, 400);  x = deg2rad(d);
e1 = abs(sin(x) - x);
e3 = abs(sin(x) - (x - x.^3/6));
semilogy(d, e1, 'LineWidth', 4.0, 'Color',[0.55 0.75 0.95]); hold on
semilogy(d, x.^3/6, 'k--', 'LineWidth', 1.6);
semilogy(d, e3, 'LineWidth', 2.6, 'Color',[0.85 0.33 0.10]);
grid on; xlabel('\theta [도]'); ylabel('절대오차'); ylim([1e-8 1]);
legend('1차 근사의 오차 (굵은 하늘색)', '버린 첫 항  \theta^3/6 (검은 점선)', ...
       '3차 근사의 오차', 'Location','southeast');
title('검은 점선이 하늘색 위에 정확히 포개진다');
end


function fig_w03_jacobian()
% 자코비안의 뜻 : 곡면을 한 점에서 접평면으로 바꾸는 것
m = 0.5; l = 0.3; b = 0.4; g = 9.81; J = m*l^2;
f2 = @(th, w) (-m*g*l*sin(th) - b*w)/J;      % 각가속도

th0 = 0; w0 = 0;
a21 = -m*g*l*cos(th0)/J;  a22 = -b/J;         % 손으로 구한 자코비안 성분

[TH, W] = meshgrid(linspace(-2.6, 2.6, 70), linspace(-4, 4, 70));
Z  = f2(TH, W);
Zt = f2(th0, w0) + a21*(TH - th0) + a22*(W - w0);   % 접평면

figure('Position',[60 60 1060 430]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
[TH2, W2] = meshgrid(linspace(-2.6, 2.6, 22), linspace(-4, 4, 22));
surf(TH, W, Z, 'FaceColor',[0.72 0.78 0.86], 'EdgeColor','none', 'FaceAlpha', 0.95);
hold on
mesh(TH2, W2, f2(th0,w0) + a21*(TH2-th0) + a22*(W2-w0), ...
     'EdgeColor',[0.85 0.33 0.10], 'FaceColor','none', 'LineWidth', 1.0);
plot3(th0, w0, f2(th0,w0), 'ko', 'MarkerFaceColor','k', 'MarkerSize', 9);
xlabel('\theta [rad]'); ylabel('d\theta/dt [rad/s]'); zlabel('각가속도 [rad/s^2]');
view(-32, 26); grid on; zlim([-90 90]); camproj('perspective');
title('회색 곡면 = 참값,  주황 격자 = 접평면');

nexttile
w = linspace(-4, 4, 200);
plot(rad2deg(linspace(-2.6,2.6,200)), f2(linspace(-2.6,2.6,200), 0), ...
     'LineWidth', 2.8, 'Color',[0.15 0.15 0.15]); hold on
thc = linspace(-2.6, 2.6, 200);
plot(rad2deg(thc), f2(th0,w0) + a21*(thc - th0), '--', ...
     'LineWidth', 2.2, 'Color',[0.85 0.33 0.10]);
plot(0, 0, 'ko', 'MarkerFaceColor','k', 'MarkerSize', 8);
grid on; xlabel('\theta [도]'); ylabel('각가속도  (d\theta/dt = 0 일 때)');
legend('참값', sprintf('접선 기울기 a_{21} = %.2f', a21), 'Location','northeast');
title('한 방향으로 자른 단면 : 기울기가 곧 A 의 성분이다');
end


function fig_w03_equilibrium()
% 평형점 : f(x0,u0) = 0 을 푸는 자리
m = 0.5; l = 0.3; g = 9.81;
th = linspace(-0.2, 2*pi+0.2, 800);
tau_g = m*g*l*sin(th);                 % 중력 토크

figure('Position',[60 60 1060 430]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
plot(rad2deg(th), tau_g, 'LineWidth', 2.8, 'Color',[0.15 0.15 0.15]); hold on
yline(0, 'k:', 'LineWidth', 1.2);
plot(0,   0, 'o', 'MarkerSize', 11, 'LineWidth', 2.2, 'Color',[0.15 0.45 0.20]);
plot(180, 0, 'o', 'MarkerSize', 11, 'LineWidth', 2.2, 'Color',[0.85 0.20 0.15]);
plot(360, 0, 'o', 'MarkerSize', 11, 'LineWidth', 2.2, 'Color',[0.15 0.45 0.20]);
text(10,  0.35, '\theta_0 = 0  안정',        'Color',[0.15 0.45 0.20], 'FontWeight','bold');
text(190, 0.35, '\theta_0 = 180°  불안정',   'Color',[0.85 0.20 0.15], 'FontWeight','bold');
grid on; xlim([-10 370]); xticks(0:90:360);
xlabel('\theta [도]'); ylabel('중력 토크  mgl sin\theta  [N\cdotm]');
title('u_0 = 0 : 곡선이 0 을 지나는 곳이 평형점');

nexttile
u0 = 0.6;                                          % 일정한 토크를 계속 넣으면
plot(rad2deg(th), u0 - tau_g, 'LineWidth', 2.8, 'Color',[0.00 0.45 0.74]); hold on
plot(rad2deg(th), -tau_g, ':', 'LineWidth', 2.0, 'Color',[0.55 0.55 0.55]);
yline(0, 'k:', 'LineWidth', 1.2);
thStar = asin(u0/(m*g*l));
plot(rad2deg(thStar), 0, 'o', 'MarkerSize', 11, 'LineWidth', 2.2, ...
     'Color',[0.00 0.45 0.74]);
plot(rad2deg(pi-thStar), 0, 'o', 'MarkerSize', 11, 'LineWidth', 2.2, ...
     'Color',[0.85 0.20 0.15]);
text(rad2deg(thStar)+6, 0.35, sprintf('\\theta_0 = %.1f°', rad2deg(thStar)), ...
     'Color',[0.00 0.45 0.74], 'FontWeight','bold');
grid on; xlim([-10 370]); xticks(0:90:360);
xlabel('\theta [도]'); ylabel('알짜 토크  u_0 - mgl sin\theta  [N\cdotm]');
legend(sprintf('u_0 = %.1f N\\cdotm', u0), 'u_0 = 0', 'Location','southwest');
title('토크를 넣으면 평형점 자체가 옮겨 간다');
end


function fig_w03_valid_range()
% 선형 모델을 정량적으로 검증한다 : 초기각을 키우며 오차를 잰다
[sysLin, p] = plant_pendulum(0, 0.5, 0.3, 0.15);
degs = 2:2:80;
eRel = zeros(size(degs));
tEnd = 3;  t = linspace(0, tEnd, 1200)';

for i = 1:numel(degs)
    x0 = [deg2rad(degs(i)); 0];
    [tn, xn] = ode45(@(tt,x) p.f(x,0), [0 tEnd], x0, ...
                     odeset('RelTol',1e-8,'AbsTol',1e-10));
    yn = interp1(tn, xn(:,1), t, 'linear');
    yl = initial(sysLin, x0, t);
    eRel(i) = 100*max(abs(yn - yl))/max(abs(yn));
end

figure('Position',[60 60 1060 430]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile
plot(degs, eRel, 'LineWidth', 2.8, 'Color',[0.00 0.45 0.74]); hold on
yline(5, 'r--', 'LineWidth', 1.8);
d5 = interp1(eRel, degs, 5, 'linear');
xline(d5, 'r:', 'LineWidth', 1.8);
plot(d5, 5, 'ro', 'MarkerFaceColor','r', 'MarkerSize', 8);
text(d5+2, 8, sprintf('%.0f도까지 오차 5 %% 이내', d5), 'FontWeight','bold');
grid on; xlabel('초기 각도 [도]'); ylabel('최대 상대오차 [%]');
title('선형 모델이 믿을 만한 범위를 숫자로 정한다');

nexttile
show = [10 40 70];
col  = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19];
hold on; grid on
for i = 1:3
    x0 = [deg2rad(show(i)); 0];
    [tn, xn] = ode45(@(tt,x) p.f(x,0), [0 tEnd], x0);
    plot(tn, rad2deg(xn(:,1)), 'LineWidth', 2.6, 'Color', col(i,:), ...
         'DisplayName', sprintf('%d도 비선형', show(i)));
    plot(t, rad2deg(initial(sysLin, x0, t)), '--', 'LineWidth', 1.8, ...
         'Color', col(i,:), 'DisplayName', sprintf('%d도 선형', show(i)));
end
xlabel('시간 [s]'); ylabel('각도 [도]');
legend('Location','northeast', 'NumColumns', 2);
title('같은 그림을 시간응답으로 : 커질수록 박자가 어긋난다');
end


% ======================================================================
%  4주차 추가 그림
% ======================================================================

function fig_w04_first_order()
% 1차 시스템 : 시정수 하나가 전부다 (63 % 지점을 눈금으로 찍는다)
taus = [0.5 1 2];
col  = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.93 0.69 0.13];
t    = 0:0.005:10;

figure('Position', [60 60 1060 440]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
hold on; grid on;
for i = 1:3
    y = 1 - exp(-t/taus(i));
    plot(t, y, 'LineWidth', 2.4, 'Color', col(i,:), ...
         'DisplayName', sprintf('\\tau = %.1f s', taus(i)));
    plot(taus(i), 1-exp(-1), 'o', 'MarkerSize', 9, 'LineWidth', 2, ...
         'Color', col(i,:), 'HandleVisibility', 'off');
    plot([taus(i) taus(i)], [0 1-exp(-1)], ':', 'LineWidth', 1.2, ...
         'Color', col(i,:), 'HandleVisibility', 'off');
end
yline(1, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');
yline(1-exp(-1), 'k:', 'LineWidth', 1.4, 'HandleVisibility', 'off');
text(9.6, 1-exp(-1)+0.05, '63.2 %', 'FontSize', 10.5, 'FontWeight', 'bold', ...
     'HorizontalAlignment', 'right');
xlabel('시간 [s]'); ylabel('출력');
legend('Location', 'southeast');
title('\tau 초 뒤에 항상 63.2 % 에 닿는다');
ylim([0 1.15]);

nexttile
hold on; grid on;
for i = 1:3
    plot(-1/taus(i), 0, 'x', 'MarkerSize', 18, 'LineWidth', 3.5, ...
         'Color', col(i,:), 'DisplayName', ...
         sprintf('\\tau = %.1f  (극점 %.1f)', taus(i), -1/taus(i)));
end
xline(0, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
yline(0, 'k:', 'HandleVisibility', 'off');
xlim([-2.6 0.6]); ylim([-1 1]);
xlabel('실수부'); ylabel('허수부');
legend('Location', 'northwest');
title({'극점이 모두 실축 위에 있다', '허수부가 없으니 진동할 방법이 없다'});
end


function fig_w04_os_zeta()
% 오버슈트는 zeta 만의 함수다 — 곡선과 대표점, 그리고 wn 을 바꿔도 같음을 보임
z  = linspace(0.01, 0.99, 400);
os = 100*exp(-z*pi./sqrt(1-z.^2));

zk  = [0.1 0.3 0.5 0.707 0.9];
osk = 100*exp(-zk*pi./sqrt(1-zk.^2));

figure('Position', [60 60 1060 440]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
semilogy(z, os, 'LineWidth', 2.6); hold on; grid on;
plot(zk, osk, 'o', 'MarkerSize', 9, 'LineWidth', 2, 'Color', [0.85 0.33 0.10]);
for i = 1:numel(zk)
    text(zk(i)+0.025, osk(i)*1.6, sprintf('%.1f %%', osk(i)), ...
         'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.85 0.33 0.10]);
end
yline(10, 'k--', 'LineWidth', 1.4);
xlabel('감쇠비 \zeta'); ylabel('오버슈트 [%]  (로그 눈금)');
xlim([0 1]); ylim([0.05 200]);
legend('공식 곡선', '대표값', '오버슈트 10 % 선', 'Location', 'southwest');
title('오버슈트는 \zeta 하나로 정해진다');

nexttile
s = tf('s'); zf = 0.4; tt = 0:0.01:14;
hold on; grid on;
for wn = [1 2 4]
    G = wn^2/(s^2 + 2*zf*wn*s + wn^2);
    plot(tt, step(G, tt), 'LineWidth', 2.2, 'DisplayName', ...
         sprintf('\\omega_n = %d  (오버슈트 %.1f %%)', wn, stepinfo(G).Overshoot));
end
yline(1, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');
pk = 1 + exp(-zf*pi/sqrt(1-zf^2));
yline(pk, 'r:', 'LineWidth', 1.8, 'HandleVisibility', 'off');
text(13.6, pk + 0.045, '세 곡선의 봉우리가 모두 이 선에 닿는다', ...
     'FontSize', 10, 'Color', [0.80 0.20 0.15], 'FontWeight', 'bold', ...
     'HorizontalAlignment', 'right');
xlabel('시간 [s]'); ylabel('출력');
legend('Location', 'southeast');
title(sprintf('\\zeta = %.1f 로 고정하고 \\omega_n 만 바꾸면', zf));
end


function fig_w04_ts_envelope()
% 정착시간은 극점 실수부만의 함수다 — 포락선과 2 % 띠
s = tf('s'); zf = 0.4;
sig = [0.5 1.0 2.0];
col = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19];
t   = 0:0.005:14;

figure('Position', [60 60 1060 440]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
hold on; grid on;
fill([0 max(t) max(t) 0], [0.98 0.98 1.02 1.02], [0.35 0.35 0.35], ...
     'FaceAlpha', 0.45, 'EdgeColor', 'none', 'HandleVisibility', 'off');
text(13.6, 0.90, '\pm 2 % 띠', 'FontSize', 10.5, 'FontWeight', 'bold', ...
     'HorizontalAlignment', 'right', 'Color', [0.30 0.30 0.30]);
for i = 1:3
    wn = sig(i)/zf;
    G  = wn^2/(s^2 + 2*zf*wn*s + wn^2);
    plot(t, step(G, t), 'LineWidth', 2.2, 'Color', col(i,:), 'DisplayName', ...
         sprintf('|실수부| = %.1f  (t_s \\approx %.1f s)', sig(i), 4/sig(i)));
    plot(t, 1 + exp(-sig(i)*t)/sqrt(1-zf^2), ':', 'LineWidth', 1.5, ...
         'Color', col(i,:), 'HandleVisibility', 'off');
    plot(t, 1 - exp(-sig(i)*t)/sqrt(1-zf^2), ':', 'LineWidth', 1.5, ...
         'Color', col(i,:), 'HandleVisibility', 'off');
end
yline(1, 'k--', 'LineWidth', 1.2, 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('출력'); ylim([0 2]);
legend('Location', 'northeast');
title('점선 포락선이 회색 띠 안에 들어가는 순간이 t_s');

nexttile
hold on; grid on;
for i = 1:3
    wn = sig(i)/zf;
    wd = wn*sqrt(1-zf^2);
    plot([-sig(i) -sig(i)], [wd -wd], 'x', 'MarkerSize', 16, 'LineWidth', 3.2, ...
         'Color', col(i,:), 'LineStyle', 'none', 'DisplayName', ...
         sprintf('|실수부| = %.1f', sig(i)));
    xline(-sig(i), ':', 'LineWidth', 1.6, 'Color', col(i,:), ...
          'HandleVisibility', 'off');
end
xline(0, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
yline(0, 'k:', 'HandleVisibility', 'off');
xlim([-3.2 1.6]); ylim([-6.2 6.2]);
xlabel('실수부'); ylabel('허수부');
legend('Location', 'east');          % 극점이 없는 오른쪽 빈 곳에 둔다
title({'세로 점선이 왼쪽일수록 빨리 잦아든다', '허수부는 정착시간과 상관없다'});
end


function fig_w04_region_build()
% 사양 영역을 세 걸음으로 쌓는다 : 부채꼴 -> 수직선 -> 겹친 곳
P_OS = 10; ts = 2;
zmin = spec2pole(P_OS, ts);
th   = acos(zmin);
sig  = 4/ts;
rr   = linspace(0, 9, 200);

figure('Position', [60 60 1180 400]);
tiledlayout(1, 3, 'TileSpacing', 'compact');

nexttile
% 부채꼴을 도화지 밖까지 충분히 길게 채운다. 짧게 잡으면 왼쪽이 잘려 보인다
R = 20;
fill([0 -R*cos(th) -R*cos(th) 0], [0 R*sin(th) -R*sin(th) 0], ...
     [1.00 0.90 0.88], 'EdgeColor', 'none'); hold on; grid on;
plot(-rr*cos(th),  rr*sin(th), 'r-', 'LineWidth', 2.2);
plot(-rr*cos(th), -rr*sin(th), 'r-', 'LineWidth', 2.2);
xline(0, 'k-', 'LineWidth', 1.5); yline(0, 'k:');
axis equal; xlim([-8 1]); ylim([-6 6]);
xlabel('실수부'); ylabel('허수부');
title(sprintf('① 오버슈트 %d %% 이하\n\\zeta \\geq %.3f  →  각 \\leq %.1f 도', ...
      P_OS, zmin, rad2deg(th)));

nexttile
fill([-8 -sig -sig -8], [-6 -6 6 6], [0.88 0.92 1.00], 'EdgeColor', 'none');
hold on; grid on;
xline(-sig, 'b-', 'LineWidth', 2.2);
xline(0, 'k-', 'LineWidth', 1.5); yline(0, 'k:');
axis equal; xlim([-8 1]); ylim([-6 6]);
xlabel('실수부'); ylabel('허수부');
title(sprintf('② 정착시간 %d s 이하\n|실수부| \\geq %.1f', ts, sig));

nexttile
xv = linspace(-8, -sig, 300);  yv = -xv*tan(th);
fill([xv fliplr(xv)], [yv -fliplr(yv)], [0.85 0.95 0.85], 'EdgeColor', 'none');
hold on; grid on;
plot(-rr*cos(th),  rr*sin(th), 'r-', 'LineWidth', 2.0);
plot(-rr*cos(th), -rr*sin(th), 'r-', 'LineWidth', 2.0);
xline(-sig, 'b-', 'LineWidth', 2.0);
st = -sig + 1j*sig*tan(th);
plot(real(st),  imag(st), 'kp', 'MarkerSize', 17, 'MarkerFaceColor', 'y');
plot(real(st), -imag(st), 'kp', 'MarkerSize', 17, 'MarkerFaceColor', 'y');
xline(0, 'k-', 'LineWidth', 1.5); yline(0, 'k:');
axis equal; xlim([-8 1]); ylim([-6 6]);
xlabel('실수부'); ylabel('허수부');
title(sprintf('③ 둘 다 — 쐐기 모양\n목표 극점 %.2f \\pm %.2fj', ...
      real(st), imag(st)));
end


% ======================================================================
%  5주차 추가 그림
% ======================================================================

function fig_w05_why_error()
% 비례는 오차가 있어야 힘을 낸다 / 적분은 쌓아 둔 값으로 힘을 낸다
s  = tf('s');
G  = 1/(s+1);                        % 아주 단순한 플랜트 (타입 0)
Kp = 4;  Ki = 3;
t  = (0:0.01:12)';
r  = ones(size(t));

Tp = feedback(Kp*G, 1);              % 비례만
Ti = feedback((Kp + Ki/s)*G, 1);     % 비례 + 적분
yp = lsim(Tp, r, t);   yi = lsim(Ti, r, t);
ep = r - yp;           ei = r - yi;
up = lsim(feedback(Kp, G), r, t);            % 제어입력 u = C/(1+CG) * r
ui = lsim(feedback(Kp + Ki/s, G), r, t);

figure('Position', [60 60 1120 460]);
tiledlayout(1, 3, 'TileSpacing', 'compact');

nexttile
plot(t, r, 'k--', 'LineWidth', 1.6); hold on; grid on;
plot(t, yp, 'LineWidth', 2.4, 'Color', [0.85 0.33 0.10]);
plot(t, yi, 'LineWidth', 2.4, 'Color', [0.00 0.45 0.74]);
xlabel('시간 [s]'); ylabel('출력 y');
legend('목표 r = 1', sprintf('비례만 (K_p=%g)', Kp), ...
       sprintf('비례+적분 (K_i=%g)', Ki), 'Location', 'southeast');
title(sprintf('비례만 쓰면 %.2f 에서 멈춘다', yp(end)));
xlim([0 12]); ylim([0 1.25]);

nexttile
plot(t, ep, 'LineWidth', 2.4, 'Color', [0.85 0.33 0.10]); hold on; grid on;
plot(t, ei, 'LineWidth', 2.4, 'Color', [0.00 0.45 0.74]);
yline(0, 'k:', 'LineWidth', 1.4);
yline(ep(end), ':', 'LineWidth', 1.6, 'Color', [0.85 0.33 0.10]);
text(11.6, ep(end)+0.045, sprintf('%.2f 에서 멈춤', ep(end)), ...
     'HorizontalAlignment', 'right', 'FontSize', 10.5, ...
     'Color', [0.85 0.33 0.10], 'FontWeight', 'bold');
xlabel('시간 [s]'); ylabel('오차 e = r - y');
xlim([0 12]); ylim([-0.05 0.55]);
legend('비례만', '비례+적분', 'Location', 'northeast');
title('오차가 0 으로 가는가');

nexttile
plot(t, up, 'LineWidth', 2.4, 'Color', [0.85 0.33 0.10]); hold on; grid on;
plot(t, ui, 'LineWidth', 2.4, 'Color', [0.00 0.45 0.74]);
yline(1, 'k:', 'LineWidth', 1.4);
text(11.8, 1.34, '버티는 데 꼭 필요한 힘 u = 1', ...
     'HorizontalAlignment', 'right', 'FontSize', 10.5, 'FontWeight', 'bold');
xlabel('시간 [s]'); ylabel('제어입력 u');
xlim([0 12]); ylim([0.5 2.2]);
legend('비례만', '비례+적분', 'Location', 'northeast');
title('오차가 0 인데 힘을 낼 수 있는가');
end


function fig_w05_tradeoff()
% 적분기를 넣을수록 임계이득이 내려간다 — 정상상태 오차와 안정도의 맞바꿈
% 강의노트 7절과 같은 DC 모터를 쓴다. 다른 예제를 쓰면 숫자가 어긋난다.
s   = tf('s');
Gs  = plant_dcmotor('speed');        % 타입 0 (2차)
Gp  = plant_dcmotor('position');     % 타입 1 (3차)
sys = { '타입 0 — 속도 모델',        Gs
        '타입 1 — 위치 모델',        Gp
        '타입 2 — 위치 + 적분기',    Gp/s };
col = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19];
Kv  = logspace(-3, 3.5, 700);

figure('Position', [60 60 1160 460]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
hold on; grid on;
Kc = inf(1,3);
for i = 1:3
    mx = zeros(size(Kv));
    for j = 1:numel(Kv)
        mx(j) = max(real(pole(feedback(Kv(j)*sys{i,2}, 1))));
    end
    plot(Kv, mx, 'LineWidth', 2.4, 'Color', col(i,:), 'DisplayName', sys{i,1});
    k = find(mx > 0, 1, 'first');
    if isempty(k)
        Kc(i) = Inf;                          % 어떤 K 에서도 안정
    elseif k == 1
        Kc(i) = 0;                            % 가장 작은 K 부터 이미 불안정
        text(Kv(6), 3.2, '모든 K 에서 불안정', 'FontSize', 11, ...
             'FontWeight', 'bold', 'Color', col(i,:));
    else
        Kc(i) = Kv(k);
        plot(Kc(i), 0, 'v', 'MarkerSize', 11, 'MarkerFaceColor', col(i,:), ...
             'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
        text(Kc(i), 3.2, sprintf('K \\approx %.3g', Kc(i)), ...
             'HorizontalAlignment', 'center', 'FontSize', 11, ...
             'FontWeight', 'bold', 'Color', col(i,:));
    end
end
set(gca, 'XScale', 'log');
yline(0, 'k-', 'LineWidth', 2, 'HandleVisibility', 'off');
xlabel('이득 K  (로그 눈금)'); ylabel('폐루프 극점 실수부의 최댓값');
ylim([-12 6]);
legend('Location', 'southwest');
title('이 선이 0 을 넘는 순간이 불안정의 시작');

nexttile
ax = gca; hold(ax, 'on');
xlim([0 1]); ylim([0 1]);
plot([0 1], [0.755 0.755], 'k-', 'LineWidth', 1.2);
axis(ax, 'off');                      % plot 뒤에 꺼야 한다. 먼저 끄면 되살아난다
text(0.00, 0.95, '맞바꿈 — 한쪽을 얻으면 한쪽을 잃는다', ...
     'FontSize', 12.5, 'FontWeight', 'bold');
rows = { '타입',   '계단 오차',  '램프 오차',      '임계이득'
         '0',      '남는다',     '무한히 벌어짐',  local_kc(Kc(1))
         '1',      '0',          '남는다',         local_kc(Kc(2))
         '2',      '0',          '0',              local_kc(Kc(3)) };
yv = [0.82 0.66 0.52 0.38];
xv = [0.00 0.15 0.42 0.72];
for i = 1:4
    for j = 1:4
        if i == 1
            text(xv(j), yv(i), rows{i,j}, 'FontSize', 12, 'FontWeight', 'bold');
        else
            text(xv(j), yv(i), rows{i,j}, 'FontSize', 12);
        end
    end
end
text(0.00, 0.20, '아래로 갈수록 오차는 좋아지고 안정도는 나빠진다.', ...
     'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.70 0.15 0.15]);
text(0.00, 0.09, '적분기는 공짜가 아니다.', ...
     'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.70 0.15 0.15]);
end

function s = local_kc(v)
if isinf(v)
    s = '없음 — 항상 안정';
elseif v == 0
    s = '없음 — 항상 불안정';
else
    s = sprintf('K > %.3g 이면 불안정', v);
end
end


function fig_w05_kr_vs_int()
% 1주차의 Kr 보정과 적분기 — 모델이 틀렸을 때 갈린다
s  = tf('s');
Gn = 5/((s+1)*(s+5));            % 설계에 쓴 공칭 모델 (타입 0)
Gr = 1.3*Gn;                     % 실제는 30 % 더 세다
% K 를 크게 잡으면 되먹임 자체가 모델 오차를 눌러 버려 Kr 의 약점이 안 보인다.
% 1 주차의 논지를 보이려면 이득을 낮게 잡아야 한다.
K  = 1;  Ki = 2;
t  = (0:0.01:10)';
r  = ones(size(t));

Kr = 1/dcgain(feedback(K*Gn, 1));            % 공칭 모델로 미리 계산한 보정값
y_kr_n = lsim(Kr*feedback(K*Gn, 1), r, t);
y_kr_r = lsim(Kr*feedback(K*Gr, 1), r, t);
y_pi_n = lsim(feedback((K + Ki/s)*Gn, 1), r, t);
y_pi_r = lsim(feedback((K + Ki/s)*Gr, 1), r, t);

figure('Position', [60 60 1060 450]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
plot(t, r, 'k--', 'LineWidth', 1.6); hold on; grid on;
plot(t, y_kr_n, 'LineWidth', 2.4, 'Color', [0.00 0.45 0.74]);
plot(t, y_kr_r, 'LineWidth', 2.4, 'Color', [0.85 0.33 0.10]);
xlabel('시간 [s]'); ylabel('출력');
legend('목표 1', '모델이 맞을 때', '모델이 30 % 틀릴 때', 'Location', 'southeast');
title(sprintf('K_r 보정 : 틀리면 %.3f 로 어긋난다', y_kr_r(end)));
ylim([0 1.45]);

nexttile
plot(t, r, 'k--', 'LineWidth', 1.6); hold on; grid on;
plot(t, y_pi_n, 'LineWidth', 2.4, 'Color', [0.00 0.45 0.74]);
plot(t, y_pi_r, 'LineWidth', 2.4, 'Color', [0.85 0.33 0.10]);
xlabel('시간 [s]'); ylabel('출력');
legend('목표 1', '모델이 맞을 때', '모델이 30 % 틀릴 때', 'Location', 'southeast');
title(sprintf('적분기 : 틀려도 %.3f 로 되돌아온다', y_pi_r(end)));
ylim([0 1.45]);
end


function fig_w05_error_const()
% Kp, Kv, Ka 를 그림으로 — s 를 몇 개 곱하고 s=0 을 넣는가
s = tf('s');
L = { '타입 0',  5/((s+1)*(s+5))
      '타입 1',  5/(s*(s+5))
      '타입 2',  5*(s+1)/(s^2*(s+5)) };
w   = logspace(-2, 2, 500);
col = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19];

figure('Position', [60 60 1120 450]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
hold on; grid on;
for i = 1:3
    m = squeeze(abs(freqresp(L{i,2}, w)));
    loglog(w, m, 'LineWidth', 2.4, 'Color', col(i,:), 'DisplayName', L{i,1});
end
set(gca, 'XScale', 'log', 'YScale', 'log');
xlabel('주파수 \omega [rad/s]  (\omega \rightarrow 0 이 s \rightarrow 0)');
ylabel('|L(j\omega)|');
legend('Location', 'southwest');
title('s \rightarrow 0 에서 |L| 이 유한한가 무한한가');

nexttile
axis off; xlim([0 1]); ylim([0 1]);
text(0.00, 0.95, 'K_p, K_v, K_a 는 전부 같은 계산이다', ...
     'FontSize', 12.5, 'FontWeight', 'bold');
rows = { 'K_p = lim L(s)',      '계단 입력',  'e = 1/(1+K_p)'
         'K_v = lim s L(s)',    '램프 입력',   'e = 1/K_v'
         'K_a = lim s^2 L(s)',  '포물선 입력', 'e = 1/K_a' };
yv = [0.74 0.58 0.42];
for i = 1:3
    text(0.00, yv(i), rows{i,1}, 'FontSize', 12, 'FontWeight', 'bold', ...
         'Color', [0.10 0.35 0.65]);
    text(0.40, yv(i), rows{i,2}, 'FontSize', 12);
    text(0.66, yv(i), rows{i,3}, 'FontSize', 12);
end
text(0.00, 0.24, 'MATLAB 에서는 dcgain(L), dcgain(s*L), dcgain(s^2*L)', ...
     'FontSize', 11.5);
text(0.00, 0.12, 'Inf 가 나오면 오류가 아니라 "그 입력은 오차 0" 이라는 뜻', ...
     'FontSize', 11.5, 'FontWeight', 'bold', 'Color', [0.15 0.50 0.20]);
end


% ======================================================================
%  6주차 추가 그림
% ======================================================================

function fig_w06_what_is()
% 근궤적이란 무엇인가 — 점 몇 개를 찍고 이으면 그것이 궤적이다
Gp = plant_dcmotor('position');
Ks = [10 40 90 150];
col = lines(numel(Ks));
t   = 0:0.01:6;

figure('Position', [60 60 1140 460]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
hold on; grid on;
% 배경에 촘촘한 궤적을 회색으로 깔고, 그 위에 네 점을 찍는다
Kf = linspace(0, 200, 4000);
[num, den] = tfdata(Gp, 'v');
pad = [zeros(1, numel(den)-numel(num)) num];
R = zeros(numel(den)-1, numel(Kf));
for j = 1:numel(Kf), R(:,j) = roots(den + Kf(j)*pad); end
for r = 1:size(R,1)
    plot(real(R(r,:)), imag(R(r,:)), '-', 'LineWidth', 2.2, ...
         'Color', [0.62 0.62 0.62], 'HandleVisibility', 'off');
end
for i = 1:numel(Ks)
    p = pole(feedback(Ks(i)*Gp, 1));
    plot(real(p), imag(p), 'x', 'MarkerSize', 15, 'LineWidth', 3, ...
         'Color', col(i,:), 'DisplayName', sprintf('K = %d', Ks(i)));
end
xline(0, 'k-', 'LineWidth', 1.8, 'HandleVisibility', 'off');
yline(0, 'k:', 'HandleVisibility', 'off');
xlim([-14 4]); ylim([-6 6]);
xlabel('실수부'); ylabel('허수부');
legend('Location', 'northwest');
title({'회색 선이 근궤적, 색 x 가 특정 K 의 극점', ...
       '궤적은 이런 점을 무수히 이은 것이다'});

nexttile
hold on; grid on;
for i = 1:numel(Ks)
    T = feedback(Ks(i)*Gp, 1);
    if all(real(pole(T)) < 0), y = step(T, t); else, y = nan(size(t)); end
    plot(t, y, 'LineWidth', 2.2, 'Color', col(i,:), ...
         'DisplayName', sprintf('K = %d', Ks(i)));
end
yline(1, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('출력 [rad]');
ylim([-0.3 2.6]);
text(3.0, 2.35, 'K = 150 은 불안정해서 그릴 수 없다', 'FontSize', 11, ...
     'FontWeight', 'bold', 'Color', col(4,:));
legend('Location', 'southeast');
title('같은 K 의 계단응답 — 왼쪽 x 와 짝을 지어 보라');
end


function fig_w06_start_end()
% 출발점은 개루프 극점, 도착점은 개루프 영점 (없으면 무한대)
s = tf('s');
L = { '영점 없음 : 1/((s+1)(s+3))',        1/((s+1)*(s+3))
      '영점 하나 : (s+2)/((s+1)(s+5))',    (s+2)/((s+1)*(s+5)) };

figure('Position', [60 60 1120 450]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

for i = 1:2
    nexttile
    hold on; grid on;
    Kf = linspace(0, 400, 6000);
    [num, den] = tfdata(L{i,2}, 'v');
    pad = [zeros(1, numel(den)-numel(num)) num];
    R = zeros(numel(den)-1, numel(Kf));
    for j = 1:numel(Kf), R(:,j) = roots(den + Kf(j)*pad); end
    for r = 1:size(R,1)
        plot(real(R(r,:)), imag(R(r,:)), '-', 'LineWidth', 2, ...
             'Color', [0.30 0.55 0.85], 'HandleVisibility', 'off');
    end
    p0 = pole(L{i,2});  z0 = zero(L{i,2});
    plot(real(p0), imag(p0), 'x', 'MarkerSize', 17, 'LineWidth', 3.4, ...
         'Color', [0.85 0.20 0.15], 'DisplayName', '개루프 극점 — 출발점 (K=0)');
    if ~isempty(z0)
        plot(real(z0), imag(z0), 'o', 'MarkerSize', 13, 'LineWidth', 3, ...
             'Color', [0.15 0.55 0.20], 'DisplayName', '개루프 영점 — 도착점 (K=∞)');
    end
    xline(0, 'k-', 'LineWidth', 1.6, 'HandleVisibility', 'off');
    yline(0, 'k:', 'HandleVisibility', 'off');
    xlim([-8 2]); ylim([-5 5]);
    xlabel('실수부'); ylabel('허수부');
    legend('Location', 'northwest');
    title(L{i,1});
    if i == 1
        text(-3, -4.3, '갈 곳이 없어 위아래 무한대로 뻗는다', 'FontSize', 11, ...
             'FontWeight', 'bold', 'Color', [0.35 0.35 0.35], ...
             'HorizontalAlignment', 'center');
    else
        text(-3, -4.3, '한 가지는 영점으로 빨려 들어간다', 'FontSize', 11, ...
             'FontWeight', 'bold', 'Color', [0.15 0.55 0.20], ...
             'HorizontalAlignment', 'center');
    end
end
end


function fig_w06_saturation()
% 근궤적은 포화를 모른다 — 구동기 한계가 응답을 바꾼다
Gp  = plant_dcmotor('position');
K   = 31.3;
lim = [Inf 48 24 12];
t   = (0:0.002:12)';
col = [0.20 0.20 0.20; 0.00 0.45 0.74; 0.93 0.69 0.13; 0.85 0.20 0.15];

figure('Position', [60 60 1120 460]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

Y = zeros(numel(t), numel(lim));
U = zeros(numel(t), numel(lim));
[A,B,C,D] = ssdata(ss(Gp));
for i = 1:numel(lim)
    x = zeros(size(A,1),1);  dt = t(2)-t(1);
    for k = 1:numel(t)
        y = C*x + D*0;
        u = K*(1 - y);
        u = max(min(u, lim(i)), -lim(i));      % 구동기 포화
        Y(k,i) = y;  U(k,i) = u;
        x = x + dt*(A*x + B*u);                % 전진 오일러 (dt 가 충분히 작다)
    end
end

nexttile
hold on; grid on;
for i = 1:numel(lim)
    os = (max(Y(:,i)) - 1)*100;
    if isinf(lim(i))
        nm = sprintf('포화 없음 (선형) — 오버슈트 %.1f %%', os);
    else
        nm = sprintf('%d V 한계 — 오버슈트 %.1f %%', lim(i), os);
    end
    plot(t, Y(:,i), 'LineWidth', 2.2, 'Color', col(i,:), 'DisplayName', nm);
end
yline(1, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('각도 [rad]');
legend('Location', 'southeast');
title(sprintf('K = %.1f 로 설계했을 때 구동기 한계별 응답', K));

nexttile
hold on; grid on;
for i = 1:numel(lim)
    if isinf(lim(i)), nm = '포화 없음';
    else,             nm = sprintf('%d V 한계', lim(i)); end
    plot(t, U(:,i), 'LineWidth', 2.2, 'Color', col(i,:), 'DisplayName', nm);
end
yline(0, 'k:', 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('제어입력 u [V]');
xlim([0 3]); ylim([-40 40]);
legend('Location', 'northeast');
title(sprintf('t=0 에서 제어기가 요구하는 전압은 %.1f V', K));
end


% ======================================================================
%  7주차 추가 그림
% ======================================================================

function fig_w07_zero_place()
% PD 영점을 어디에 둘 것인가 — 세 자리를 나란히
s  = tf('s');
G  = 1/((s+1)*(s+4));
zs = [1 3 6];
col = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19];
t  = (0:0.005:6)';

figure('Position', [60 60 1160 460]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

% 왼쪽 : 궤적이 어떻게 달라지는가
nexttile
hold on; grid on;
Kf = linspace(0, 400, 4000);
for i = 1:numel(zs)
    L = (s + zs(i))*G;
    [num, den] = tfdata(L, 'v');
    pad = [zeros(1, numel(den)-numel(num)) num];
    R = zeros(numel(den)-1, numel(Kf));
    for j = 1:numel(Kf), R(:,j) = roots(den + Kf(j)*pad); end
    % [주의] 범례에 남길 것은 **첫 가지** 하나뿐이다.
    %        마지막 핸들에 이름을 붙이면 그것이 숨겨져 있어 data1 로 나온다.
    for r = 1:size(R,1)
        h = plot(real(R(r,:)), imag(R(r,:)), '-', 'LineWidth', 2, ...
                 'Color', col(i,:));
        if r == 1
            set(h, 'DisplayName', sprintf('영점 z = %d', zs(i)));
        else
            set(h, 'HandleVisibility', 'off');
        end
    end
    plot(-zs(i), 0, 'o', 'MarkerSize', 11, 'LineWidth', 2.4, ...
         'Color', col(i,:), 'HandleVisibility', 'off');
end
plot([-1 -4], [0 0], 'kx', 'MarkerSize', 15, 'LineWidth', 3, ...
     'DisplayName', '플랜트 극점 (-1, -4)');
xline(0, 'k-', 'LineWidth', 1.6, 'HandleVisibility', 'off');
yline(0, 'k:', 'HandleVisibility', 'off');
xlim([-10 2]); ylim([-8 8]);
xlabel('실수부'); ylabel('허수부');
legend('Location', 'northwest');
title('영점(동그라미)을 옮기면 길이 통째로 바뀐다');

% 오른쪽 : 같은 제어입력 예산에서 정상상태 오차가 얼마나 다른가
nexttile
hold on; grid on;
for i = 1:numel(zs)
    z = zs(i);
    % max|u| <= 10 을 지키는 가장 큰 K 를 찾는다.
    % [주의] PD 는 비적정이라 step(feedback(C,G)) 가 오류를 낸다.
    %        미분 킥 임펄스를 빼 주는 ctrl_input 을 써야 한다.
    Kok = 0;
    for K = linspace(0.2, 60, 300)
        C = K*(s + z);
        if ~all(real(pole(feedback(C*G,1))) < 0), continue, end
        [~, ~, umax] = ctrl_input(C, G, t);
        if umax <= 10, Kok = K; end
    end
    T = feedback(Kok*(s+z)*G, 1);
    y = step(T, t);
    plot(t, y, 'LineWidth', 2.3, 'Color', col(i,:), 'DisplayName', ...
         sprintf('z = %d  (K = %.1f, 최종 %.3f)', z, Kok, y(end)));
end
yline(1, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('출력');
ylim([0 1.25]);
legend('Location', 'southeast');
title('제어입력을 |u| \leq 10 으로 똑같이 묶었을 때');
end


function fig_w07_zero_overshoot()
% 감쇠비만 보면 안 된다 — 영점이 오버슈트를 만든다
s = tf('s');
G = 5/((s+1)*(s+2)*(s+5));
C = 26*(s+1.5);
T = feedback(C*G, 1);
t = (0:0.002:4)';

figure('Position', [60 60 1140 450]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
p = pole(T); z = zero(T);
plot(real(p), imag(p), 'x', 'MarkerSize', 16, 'LineWidth', 3.2, ...
     'Color', [0.85 0.20 0.15]); hold on; grid on;
plot(real(z), imag(z), 'o', 'MarkerSize', 12, 'LineWidth', 2.8, ...
     'Color', [0.15 0.55 0.20]);
xline(0, 'k-', 'LineWidth', 1.6, 'HandleVisibility', 'off');
yline(0, 'k:', 'HandleVisibility', 'off');
% "지배극점" 으로 뽑히는 것 (원점에 가장 가까운 것) 을 표시
[~, id] = min(abs(p));
plot(real(p(id)), imag(p(id)), 's', 'MarkerSize', 22, 'LineWidth', 2, ...
     'Color', [0.85 0.20 0.15]);
xlim([-8 4]); ylim([-16 19]);
xlabel('실수부'); ylabel('허수부');
legend({'폐루프 극점', '폐루프 영점 (-1.5)', ...
        sprintf('공식이 지배극점으로 보는 것 (%.2f)', real(p(id)))}, ...
       'Location', 'southeast');
text(-7.8, 18.4, ['영점 -1.50 이 극점 -1.49 를 거의 상쇄한다.' newline ...
                  '그래서 실제로 남는 것은 복소극점 쌍이다.'], ...
     'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.75 0.20 0.15], ...
     'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');
title('지배극점이 실수 -> 공식대로면 오버슈트 0 %');

nexttile
y = step(T, t);
plot(t, y, 'LineWidth', 2.6); hold on; grid on;
% [주의] 오버슈트는 **최종값 기준**이다. 목표 1 을 기준으로 재면 틀린다.
%        이 시스템은 최종값이 0.951 이라 두 값이 7 % 포인트나 다르다.
yf = dcgain(T);
yline(yf, 'k--', 'LineWidth', 1.4);
[ym, im] = max(y);
plot(t(im), ym, 'o', 'MarkerSize', 11, 'LineWidth', 2.4, ...
     'Color', [0.85 0.20 0.15]);
text(t(im)+0.12, ym, sprintf('실제 오버슈트 %.1f %%', stepinfo(T).Overshoot), ...
     'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.85 0.20 0.15]);
xlabel('시간 [s]'); ylabel('출력');
ylim([0 1.5*max(1, ym)]);
legend('실제 계단응답', sprintf('최종값 %.3f', yf), '최대점', ...
       'Location', 'southeast');
title('그런데 실제로는 이만큼 튄다');
end


function fig_w07_pd_improper()
% PD 는 만들 수 없다 — 고주파 이득이 끝없이 커진다
s = tf('s');
Kd = 26; z = 1.5;
Cpd = Kd*(s + z);
ps  = [15 60 240];
w   = logspace(-1, 5, 600);
col = [0.85 0.33 0.10; 0.93 0.69 0.13; 0.47 0.67 0.19];

figure('Position', [60 60 1140 450]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
m = squeeze(abs(freqresp(Cpd, w)));
loglog(w, m, 'LineWidth', 2.8, 'Color', [0.10 0.25 0.60], ...
       'DisplayName', 'PD : K_d(s+z)'); hold on; grid on;
for i = 1:numel(ps)
    % 저주파 이득을 PD 와 맞춘다. PD 는 w->0 에서 Kd*z, Lead 는 Kc*z/p 이므로
    % Kc = Kd*p 여야 둘이 같아진다.
    Cl = Kd*ps(i)*(s+z)/(s+ps(i));
    ml = squeeze(abs(freqresp(Cl, w)));
    loglog(w, ml, '--', 'LineWidth', 2.2, 'Color', col(i,:), ...
           'DisplayName', sprintf('Lead : p = %d', ps(i)));
end
set(gca, 'XScale', 'log', 'YScale', 'log');
xlabel('주파수 \omega [rad/s]'); ylabel('|C(j\omega)|');
legend('Location', 'northwest');
title('PD 는 끝없이 올라가고 Lead 는 평평해진다');

nexttile
axis off; xlim([0 1]); ylim([0 1]);
text(0.00, 0.95, 'PD 의 이득은 어디까지 커지는가', ...
     'FontSize', 12.5, 'FontWeight', 'bold');
wl = [1 100 1000 10000];
for i = 1:numel(wl)
    g = abs(freqresp(Cpd, wl(i)));
    text(0.02, 0.80 - 0.11*(i-1), sprintf('\\omega = %6d rad/s', wl(i)), ...
         'FontSize', 12);
    text(0.52, 0.80 - 0.11*(i-1), sprintf('이득 %8.0f', g), ...
         'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.85 0.20 0.15]);
end
text(0.00, 0.30, '측정 잡음은 대개 고주파다.', 'FontSize', 12);
text(0.00, 0.21, '그 잡음이 이 배율로 증폭되어 제어입력에 실린다.', 'FontSize', 12);
text(0.00, 0.09, 'Lead 는 고주파에서 평평해져 이 문제가 없다.', ...
     'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.15 0.50 0.20]);
end


function fig_w07_lead_tradeoff()
% Lead 의 맞바꿈 — p 를 키우면 성능은 좋아지고 제어입력은 커진다
% [주의] 이득을 고르는 기준을 W07_05_lead_and_lag.m 과 똑같이 맞춘다.
%        기준이 다르면 강의노트에 적힌 숫자와 그림의 숫자가 어긋난다.
s  = tf('s');
G  = plant_dcmotor('position');
z  = 2;                                   % W07_05 후보 탐색표의 합격 행 (z=2)
ps = [15 30 60];                          % W07_05 의 p_cand
[~, ~, s_target] = spec2pole(20, 2);      % W07_05 의 사양 P_OS=20, ts=2
t  = (0:0.002:4)';
col = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19];

figure('Position', [60 60 1140 460]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

Kc = zeros(1,3);  OS = zeros(1,3);  ts = zeros(1,3);  um = zeros(1,3);
Y  = zeros(numel(t),3);  U = zeros(numel(t),3);
for i = 1:3
    C0    = (s+z)/(s+ps(i));
    Kc(i) = rlocfind(G*C0, s_target);     % 목표 극점에 가장 가까운 이득
    T  = feedback(Kc(i)*C0*G, 1);
    Su = feedback(Kc(i)*C0, G);
    Y(:,i) = step(T, t);   U(:,i) = step(Su, t);
    si = stepinfo(T);  OS(i) = si.Overshoot;  ts(i) = si.SettlingTime;
    um(i) = max(abs(U(2:end,i)));
end

nexttile
hold on; grid on;
for i = 1:3
    plot(t, Y(:,i), 'LineWidth', 2.3, 'Color', col(i,:), 'DisplayName', ...
         sprintf('p = %d  (오버슈트 %.1f %%, t_s %.2f s)', ps(i), OS(i), ts(i)));
end
yline(1, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('각도 [rad]'); ylim([0 1.3]);
legend('Location', 'southeast');
title(sprintf('영점 z = %d 로 고정하고 극점 p 만 바꾸면 (사양 %%OS 20, t_s 2 s)', z));

nexttile
hold on; grid on;
for i = 1:3
    plot(t, U(:,i), 'LineWidth', 2.3, 'Color', col(i,:), 'DisplayName', ...
         sprintf('p = %d  (최대 %.0f V)', ps(i), um(i)));
end
yline(0, 'k:', 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('제어입력 u [V]');
xlim([0 1.2]);
legend('Location', 'northeast');
title('성능이 좋아진 만큼 전압을 더 쓴다');
end


function fig_w07_pd_vs_pi()
% PD 와 PI 는 서로를 대신할 수 없다
s = tf('s');
G = 1/((s+1)*(s+4));                    % 타입 0 : 오차가 남는다
t = (0:0.005:10)';

Cp  = 20;
Cpd = 8*(s+3);
Cpi = 12*(s+1)/s;

sysd = { '비례만 P',  Cp,  [0.35 0.35 0.35]
         'PD',        Cpd, [0.85 0.33 0.10]
         'PI',        Cpi, [0.00 0.45 0.74] };

figure('Position', [60 60 1140 450]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
hold on; grid on;
for i = 1:3
    T = feedback(sysd{i,2}*G, 1);
    y = step(T, t);
    plot(t, y, 'LineWidth', 2.4, 'Color', sysd{i,3}, 'DisplayName', ...
         sprintf('%s  (최종 %.3f)', sysd{i,1}, y(end)));
end
yline(1, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('출력'); ylim([0 1.35]);
legend('Location', 'southeast');
title('정상상태 오차 — PI 만 0 으로 간다');

nexttile
hold on; grid on;
for i = 1:3
    T = feedback(sysd{i,2}*G, 1);
    si = stepinfo(T);
    y = step(T, t(t<=4));
    plot(t(t<=4), y, 'LineWidth', 2.4, 'Color', sysd{i,3}, 'DisplayName', ...
         sprintf('%s  (t_s %.2f s, 오버슈트 %.1f %%)', sysd{i,1}, ...
         si.SettlingTime, si.Overshoot));
end
yline(1, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('출력'); ylim([0 1.35]);
legend('Location', 'southeast');
title('과도응답 — PD 가 가장 빠르고 덜 튄다');
end


function fig_w07_pseudo_deriv()
% 유사미분은 Lead 와 같은 것이다 — 잡음이 실린 신호를 미분해 보면
rng(7);
dt = 0.001;  t = (0:dt:3)';
clean = sin(2*pi*0.5*t);
noise = 0.02*randn(size(t));
y     = clean + noise;

tau = 0.05;
s   = tf('s');
d_true = 2*pi*0.5*cos(2*pi*0.5*t);          % 해석적 미분 (참값)
d_raw  = [0; diff(y)/dt];                   % 순수 미분
d_ps   = lsim(s/(tau*s+1), y, t);           % 유사미분

figure('Position', [60 60 1140 460]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
plot(t, y, 'LineWidth', 1.2, 'Color', [0.60 0.60 0.60], ...
     'DisplayName', '측정 신호 (잡음 포함)'); hold on; grid on;
plot(t, clean, 'LineWidth', 2.4, 'Color', [0.00 0.45 0.74], ...
     'DisplayName', '진짜 신호');
xlabel('시간 [s]'); ylabel('신호');
legend('Location', 'southeast');
title(sprintf('잡음 크기는 신호의 %.0f %% 밖에 안 된다', ...
      100*std(noise)/std(clean)));

nexttile
plot(t, d_raw, 'LineWidth', 0.8, 'Color', [0.85 0.20 0.15], ...
     'DisplayName', sprintf('순수 미분 s  (최대 %.0f)', max(abs(d_raw))));
hold on; grid on;
plot(t, d_ps, 'LineWidth', 2.4, 'Color', [0.00 0.45 0.74], ...
     'DisplayName', sprintf('유사미분 s/(%.2fs+1)  (최대 %.1f)', tau, max(abs(d_ps))));
plot(t, d_true, 'k--', 'LineWidth', 2, 'DisplayName', '참값');
xlabel('시간 [s]'); ylabel('미분값');
legend('Location', 'northeast');
title('같은 신호를 미분한 결과');
end


% ======================================================================
%  10주차 추가 그림
% ======================================================================

function fig_w10_why_minus_one()
% 왜 하필 -1 인가 — 되먹임 신호가 원래 자리로 돌아오는 그림
s = tf('s');
G = 1/(s*(s+1)^2);
Ks = [0.5 2 3];
nm = {'K = 0.5  (여유 있음)', 'K = 2  (딱 -1)', 'K = 3  (넘어섬)'};
col = [0.00 0.45 0.74; 0.93 0.69 0.13; 0.85 0.20 0.15];

figure('Position', [60 60 1160 460]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

% (1) -180 도 주파수에서 한 바퀴 돈 신호를 시간축으로 그린다
nexttile
hold on; grid on;
ws = warning('off', 'Control:analysis:MarginUnstable');
[~, ~, wcg] = margin(G);
warning(ws);
t = linspace(0, 4*2*pi/wcg, 800);
plot(t, sin(wcg*t), 'k-', 'LineWidth', 2.6, 'DisplayName', '원래 신호 e');
for i = 1:numel(Ks)
    g = abs(evalfr(Ks(i)*G, 1j*wcg));
    plot(t, -g*sin(wcg*t), 'LineWidth', 2.2, 'Color', col(i,:), ...
         'DisplayName', sprintf('%s  ->  크기 %.2f 로 되돌아옴', nm{i}, g));
end
yline(0, 'k:', 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('신호');
legend('Location', 'southoutside', 'NumColumns', 2);
title(sprintf(['위상이 -180도인 주파수 \\omega = %.2f rad/s 에서' newline ...
               '한 바퀴 돌아온 신호는 부호가 뒤집혀 있다'], wcg));

% (2) 그 결과 폐루프 계단응답
nexttile
hold on; grid on;
t2 = 0:0.02:40;
for i = 1:numel(Ks)
    T = feedback(Ks(i)*G, 1);
    y = lsim(T, ones(size(t2)), t2);
    plot(t2, y, 'LineWidth', 2.3, 'Color', col(i,:), 'DisplayName', nm{i});
end
yline(1, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('출력');
ylim([-1.5 3.5]);
legend('Location', 'northwest');
title('그래서 폐루프가 이렇게 된다');
end


function fig_w10_delay()
% 위상여유를 시간지연으로 바꿔 읽기
s  = tf('s');
G  = 1/(s*(s+1)^2);
K  = 0.5;  L = K*G;
[~, pm, ~, wcp] = margin(L);
tau_max = deg2rad(pm)/wcp;
taus = [0 0.5 1.0 1.5]*tau_max;
col  = [0.20 0.20 0.20; 0.00 0.45 0.74; 0.93 0.69 0.13; 0.85 0.20 0.15];
t    = 0:0.05:80;

figure('Position', [60 60 1160 460]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
w = logspace(-2, 1, 400);
[m, ph] = bode(L, w);
m = squeeze(m); ph = squeeze(ph);
hold on; grid on;
for i = 1:numel(taus)
    plot(w, ph - rad2deg(w(:)*taus(i)), 'LineWidth', 2.2, 'Color', col(i,:), ...
         'DisplayName', sprintf('\\tau = %.2f s', taus(i)));
end
set(gca, 'XScale', 'log');
yline(-180, 'r--', 'LineWidth', 1.8, 'HandleVisibility', 'off');
xline(wcp, 'k:', 'LineWidth', 1.6, 'HandleVisibility', 'off');
text(wcp*1.1, -60, sprintf('\\omega_{cp} = %.3f', wcp), 'FontSize', 10.5);
text(0.012, -172, '-180도 선', 'FontSize', 10.5, 'Color', [0.8 0.2 0.15], ...
     'FontWeight', 'bold');
xlabel('주파수 [rad/s]'); ylabel('위상 [도]');
ylim([-330 0]);
legend('Location', 'southwest');
title('지연은 크기를 안 건드리고 위상만 깎는다');

nexttile
hold on; grid on;
for i = 1:numel(taus)
    Ld = L;
    if taus(i) > 0, Ld = L*exp(-taus(i)*s); end
    T = feedback(Ld, 1);
    y = lsim(T, ones(size(t)), t);
    plot(t, y, 'LineWidth', 2.2, 'Color', col(i,:), ...
         'DisplayName', sprintf('\\tau = %.2f s', taus(i)));
end
yline(1, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('출력'); ylim([-0.6 2.6]);
legend('Location', 'northeast');
title(sprintf('견디는 한계는 \\tau = %.2f s (PM %.1f도 / \\omega_{cp} %.3f)', ...
      tau_max, pm, wcp));
end


function fig_w10_sensitivity()
% 감도함수 — 근본적인 맞바꿈
s = tf('s');
G = 1/(s*(s+1)^2);
Ks = [0.3 0.8 1.6];
col = [0.00 0.45 0.74; 0.93 0.69 0.13; 0.85 0.20 0.15];
w = logspace(-2, 1.5, 500);

figure('Position', [60 60 1160 460]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
hold on; grid on;
for i = 1:numel(Ks)
    S = feedback(1, Ks(i)*G);
    m = 20*log10(squeeze(abs(freqresp(S, w))));
    ws2 = warning('off', 'Control:analysis:MarginUnstable');
    [~, pm] = margin(Ks(i)*G);
    warning(ws2);
    plot(w, m, 'LineWidth', 2.3, 'Color', col(i,:), 'DisplayName', ...
         sprintf('K = %.1f  (PM %.0f도, 최대 %.1f dB)', Ks(i), pm, max(m)));
end
set(gca, 'XScale', 'log');
yline(0, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');
xlabel('주파수 [rad/s]'); ylabel('|S(j\omega)| [dB]');
legend('Location', 'southeast');
title('감도 S = 1/(1+L) — 외란을 얼마나 막는가');

nexttile
hold on; grid on;
t = 0:0.05:60;
d = double(t >= 10);                       % t=10 s 에 외란 계단
for i = 1:numel(Ks)
    S = feedback(1, Ks(i)*G);
    y = lsim(S, d, t);
    plot(t, y, 'LineWidth', 2.3, 'Color', col(i,:), ...
         'DisplayName', sprintf('K = %.1f', Ks(i)));
end
yline(0, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('외란이 만든 출력 오차');
legend('Location', 'northeast');
title('t = 10 s 에 크기 1 의 외란을 넣었을 때');
end


% ======================================================================
%  11주차 추가 그림
% ======================================================================

function fig_w11_lead_alpha()
% Lead 한 단이 올릴 수 있는 위상과 그 대가
al = linspace(0.02, 0.98, 400);
ph = asind((1-al)./(1+al));

figure('Position', [60 60 1140 450]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

% [주의] yyaxis 를 쓰면 뒤에 그린 것 때문에 축이 다시 잡혀 앞 곡선이 사라진다.
%        축 하나로 그리고 필요한 값은 글자로 적는다.
nexttile
plot(ph, 1./al, 'LineWidth', 2.8, 'Color', [0.85 0.20 0.15]);
hold on; grid on;
xline(60, 'k--', 'LineWidth', 1.8);
text(59, 52, '한 단은 60도까지', 'FontSize', 11.5, 'FontWeight', 'bold', ...
     'HorizontalAlignment', 'right');
% 표시할 점은 넷만. 다섯이면 왼쪽 두 개의 글자가 서로 겹친다
for p0 = [20 45 60 70]
    a0 = (1-sind(p0))/(1+sind(p0));
    plot(p0, 1/a0, 'o', 'MarkerSize', 9, 'LineWidth', 2, ...
         'Color', [0.85 0.20 0.15], 'MarkerFaceColor', 'w');
    % 왼쪽 끝 점은 글자가 도화지 밖으로 나가므로 오른쪽에 붙인다
    if p0 <= 30
        text(p0 + 1.5, 1/a0 + 2.0, sprintf('%.1f배 (\\alpha=%.3f)', 1/a0, a0), ...
             'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
    else
        text(p0 - 1.5, 1/a0 + 2.5, sprintf('%.1f배 (\\alpha=%.3f)', 1/a0, a0), ...
             'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'right');
    end
end
xlabel('올리려는 위상 \phi_{max} [도]');
ylabel('고주파 이득 배율  1/\alpha');
xlim([10 80]); ylim([0 60]);
title('위상을 더 올릴수록 고주파 이득이 급증한다');

nexttile
s = tf('s');
w = logspace(-1, 3, 500);
hold on; grid on;
col = lines(4);
k = 0;
for p0 = [20 40 60 70]
    k = k + 1;
    a0 = (1-sind(p0))/(1+sind(p0));
    T0 = 1/(10*sqrt(a0));                    % wm 을 10 rad/s 로 맞춘다
    D  = (T0*s+1)/(a0*T0*s+1);
    phs = squeeze(angle(freqresp(D, w)))*180/pi;
    plot(w, phs, 'LineWidth', 2.3, 'Color', col(k,:), ...
         'DisplayName', sprintf('\\phi_{max} = %d도  (\\alpha = %.3f)', p0, a0));
end
set(gca, 'XScale', 'log');
xline(10, 'k:', 'LineWidth', 1.8, 'HandleVisibility', 'off');
text(11, 5, '\omega_m = 10', 'FontSize', 11);
xlabel('주파수 [rad/s]'); ylabel('Lead 가 더하는 위상 [도]');
ylim([0 80]);
legend('Location', 'northwest');
title('봉우리의 꼭대기가 항상 \omega_m 에 온다');
end


function fig_w11_lead_cost()
% Lead 의 대가 — 제어입력과 잡음 민감도
% [주의] 강의노트 2절과 같은 플랜트를 써야 숫자가 맞는다.
%        DC 모터 속도 모델은 이미 위상여유가 충분해 Lead 가 안 붙는다.
s  = tf('s');
G  = 1/(s*(s+1));
K0 = 100;
[D, info] = lead_design(K0, G, 50, 5);
t  = (0:0.001:1.0)';

figure('Position', [60 60 1160 460]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
u0 = step(feedback(K0, G), t);
u1 = step(feedback(D,  G), t);
plot(t, u0, 'LineWidth', 2.4, 'Color', [0.35 0.35 0.35], ...
     'DisplayName', sprintf('보상 전 (최대 %.0f)', max(abs(u0))));
hold on; grid on;
plot(t, u1, 'LineWidth', 2.4, 'Color', [0.85 0.20 0.15], ...
     'DisplayName', sprintf('Lead 적용 (최대 %.0f)', max(abs(u1))));
xlabel('시간 [s]'); ylabel('제어입력 u');
legend('Location', 'northeast');
title(sprintf('고주파 이득이 %.1f 배가 된 대가', 1/info.alpha));

nexttile
w = logspace(-1, 4, 500);
m0 = 20*log10(squeeze(abs(freqresp(feedback(K0, G), w))));
m1 = 20*log10(squeeze(abs(freqresp(feedback(D,  G), w))));
semilogx(w, m0, 'LineWidth', 2.4, 'Color', [0.35 0.35 0.35], ...
         'DisplayName', '보상 전'); hold on; grid on;
semilogx(w, m1, 'LineWidth', 2.4, 'Color', [0.85 0.20 0.15], ...
         'DisplayName', 'Lead 적용');
set(gca, 'XScale', 'log');
xlabel('주파수 [rad/s]'); ylabel('잡음 -> 제어입력 [dB]');
legend('Location', 'northwest');
title('고주파 잡음이 제어입력으로 얼마나 새어 나오는가');
end


function fig_w11_lead_vs_lag()
% Lead 와 Lag 는 교차주파수를 반대쪽으로 옮긴다
s = tf('s');
G = 1/(s*(s+1));
K0 = 100;
[Dlead, ~] = lead_design(K0, G, 50, 5);
Dlag = lag_design(K0, G, 50, 5);
sysd = { '보상 전 (K만)', K0*G,      [0.35 0.35 0.35]
         'Lead 적용',     Dlead*G,   [0.85 0.20 0.15]
         'Lag 적용',      Dlag*G,    [0.00 0.45 0.74] };
w = logspace(-1, 4, 600);
% Lag 는 아주 느려서 1.5 초로는 정착이 안 보인다. 축을 넉넉히 잡는다
t = (0:0.005:10)';

figure('Position', [60 60 1160 460]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
hold on; grid on;
for i = 1:3
    m = 20*log10(squeeze(abs(freqresp(sysd{i,2}, w))));
    ws = warning('off', 'Control:analysis:MarginUnstable');
    [~, pm, ~, wcp] = margin(sysd{i,2});
    warning(ws);
    plot(w, m, 'LineWidth', 2.3, 'Color', sysd{i,3}, 'DisplayName', ...
         sprintf('%s  (\\omega_{cp} %.1f, PM %.0f도)', sysd{i,1}, wcp, pm));
    plot(wcp, 0, 'o', 'MarkerSize', 10, 'LineWidth', 2.2, ...
         'Color', sysd{i,3}, 'HandleVisibility', 'off');
end
set(gca, 'XScale', 'log');
yline(0, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');
xlabel('주파수 [rad/s]'); ylabel('개루프 크기 [dB]');
ylim([-60 60]);
legend('Location', 'southwest');
title('동그라미가 교차주파수 — Lead 는 오른쪽, Lag 는 왼쪽');

nexttile
hold on; grid on;
for i = 1:3
    y = step(feedback(sysd{i,2}, 1), t);
    plot(t, y, 'LineWidth', 2.3, 'Color', sysd{i,3}, 'DisplayName', sysd{i,1});
end
yline(1, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('출력');
legend('Location', 'southeast');
title('Lead 는 빨라지고 Lag 는 느려진다');
end


function fig_w11_dfilter()
% 미분 필터 N — 성능은 그대로인데 고주파만 커진다
s  = tf('s');
G  = plant_dcmotor('speed');
Ns = [5 20 100 1000];
w  = logspace(0, 5, 500);
col = lines(numel(Ns));
t  = (0:0.001:0.6)';

figure('Position', [60 60 1160 460]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
hold on; grid on;
for i = 1:numel(Ns)
    Cn = 100 + 200/s + 10*s/(s/Ns(i) + 1);
    m  = 20*log10(squeeze(abs(freqresp(Cn, w))));
    [~, pmn] = margin(Cn*G);
    plot(w, m, 'LineWidth', 2.3, 'Color', col(i,:), 'DisplayName', ...
         sprintf('N = %d  (PM %.1f도, \\omega=1000 에서 %.1f dB)', ...
         Ns(i), pmn, 20*log10(abs(freqresp(Cn, 1000)))));
end
set(gca, 'XScale', 'log');
xline(1000, 'k:', 'LineWidth', 1.6, 'HandleVisibility', 'off');
xlabel('주파수 [rad/s]'); ylabel('|C(j\omega)| [dB]');
legend('Location', 'northwest');
title('N 이 클수록 고주파에서만 커진다');

nexttile
hold on; grid on;
for i = 1:numel(Ns)
    Cn = 100 + 200/s + 10*s/(s/Ns(i) + 1);
    y  = step(feedback(Cn*G, 1), t);
    plot(t, y, 'LineWidth', 2.3, 'Color', col(i,:), ...
         'DisplayName', sprintf('N = %d', Ns(i)));
end
yline(1, 'k--', 'LineWidth', 1.4, 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('출력');
legend('Location', 'southeast');
title('그런데 응답은 거의 구별되지 않는다');
end


% ======================================================================
%  13주차 추가 그림
% ======================================================================

function fig_w13_coeff_match()
% 계수비교법 : 원하는 극점에서 K 까지 가는 길을 한 장에
%   식만 나열하면 "어느 계수를 어디에 맞추는 것인지" 가 안 보인다.
%   그래서 네 단계를 블록으로 놓고, 맞추는 계수끼리 화살표로 잇는다.
W = 15.6; H = 8.2;
dg_new(W, H, '계수비교법 : 미지수 2 개, 방정식 2 개이므로 답이 하나로 정해진다');
set(gcf, 'Position', [60 60 1150 600]);

cIn  = [0.88 0.93 1.00];      % 우리가 정하는 것
cSys = [0.93 0.93 0.93];      % 시스템이 주는 것
cOut = [0.88 0.96 0.88];      % 얻는 것

yT = 6.5;  yB = 2.3;

b1 = dg_block( 2.5, yT, 4.0, 1.7, '', cIn);
b2 = dg_block( 7.8, yT, 4.4, 1.7, '', cIn);
b3 = dg_block(13.0, yT, 4.4, 1.7, '', cSys);
b4 = dg_block( 7.8, yB, 4.4, 1.7, '', cOut);

local_cm(b1, '① 원하는 극점', '-4 ,  -5');
local_cm(b2, '② 원하는 특성다항식', 's^2 + 9s + 20');
local_cm(b3, '③ A-BK 의 특성다항식', 's^2 + (3+k_2)s + (2+k_1)');
local_cm(b4, '⑤ 얻는 상태궤환 이득', 'K = [ 18   6 ]');

dg_arrow(b1.R, b2.L, '곱한다');
dg_arrow(b2.R, b3.L, '');
dg_arrow([15.2 yT], [15.2 yB], '');
dg_arrow([15.2 yB], b4.R, '');

% ④ 계수를 맞추는 표 — 두 다항식 사이에 놓는다
xt = 2.6;  yt = 4.35;
text(xt, yt+0.55, '④ 같은 차수끼리 맞춘다', 'FontSize', 12, ...
     'FontWeight', 'bold', 'Color', [0.75 0.20 0.15]);
text(xt, yt-0.10, 's^1 :   9  =  3 + k_2      \rightarrow   k_2 = 6', ...
     'FontSize', 12, 'FontName', 'Consolas');
text(xt, yt-0.80, 's^0 :  20  =  2 + k_1      \rightarrow   k_1 = 18', ...
     'FontSize', 12, 'FontName', 'Consolas');

text(W/2, 0.75, ['가제어가 아니면 ③ 에 k_1 이나 k_2 가 아예 안 나타난다. ' ...
                 '그러면 ④ 를 풀 수 없다 — 12주차 판정이 여기서 쓰인다'], ...
     'HorizontalAlignment', 'center', 'FontSize', 11, 'Color', [0.35 0.35 0.35]);
end

function local_cm(b, top, bot)
text(b.C(1), b.C(2)+0.36, top, 'HorizontalAlignment','center', ...
     'FontSize', 12, 'FontWeight','bold');
text(b.C(1), b.C(2)-0.38, bot, 'HorizontalAlignment','center', ...
     'FontSize', 11.5, 'Color', [0.15 0.35 0.65], 'FontName','Consolas');
end


function fig_w13_servo()
% K_r 의 약점과 적분 상태 : 모델이 틀리면 무슨 일이 생기는가
%   적분기가 없는 플랜트(DC 모터 속도)에서만 이 차이가 드러난다.
[~, p] = plant_dcmotor('speed');
A = p.A;  B = p.B;  C = p.C;
n = size(A,1);

p_des = [-8 -10];
if n ~= 2, p_des = linspace(-8, -8-2*(n-1), n); end
K  = place(A, B, p_des);
Kr = 1 / dcgain(ss(A - B*K, B, C, 0));      % 설계할 때 믿은 모델로 계산

% 적분 상태를 더한 서보 : xdot_i = r - y
Aa = [A zeros(n,1); -C 0];
Ba = [B; 0];
Ka = place(Aa, Ba, [p_des -14]);
Kx = Ka(1:n);  Ki = Ka(end);

t  = (0:0.001:2.5)';
r  = ones(size(t));
mis = 0.30;                                  % 실제 플랜트가 30 % 약하다

figure('Position',[60 60 1060 430]);
tiledlayout(1,2,'TileSpacing','compact');

% ---- 왼쪽 : 시간응답 세 가지
nexttile; hold on; grid on
Bt = B*(1-mis);                              % 진짜 플랜트

y1 = lsim(ss(A - B*K,  B*Kr,  C, 0), r, t);             % 모델이 맞을 때
y2 = lsim(ss(A - Bt*K, Bt*Kr, C, 0), r, t);             % 모델이 틀릴 때
y3 = lsim(ss([A-Bt*Kx  -Bt*Ki; -C 0], [zeros(n,1); 1], [C 0], 0), r, t);

plot(t, y1, 'LineWidth', 2.4, 'Color',[0.00 0.45 0.74]);
plot(t, y2, 'LineWidth', 2.4, 'Color',[0.85 0.33 0.10]);
plot(t, y3, 'LineWidth', 2.4, 'Color',[0.47 0.67 0.19]);
yline(1, 'k--', 'HandleVisibility','off');
xlabel('시간 [s]'); ylabel('각속도 [rad/s]');
legend('K_r , 모델이 정확할 때', ...
       sprintf('K_r , 플랜트가 %d %% 약할 때', round(100*mis)), ...
       sprintf('적분 상태 추가, 같은 %d %% 오차', round(100*mis)), ...
       'Location','southeast');
title('K_r 은 모델을 믿고 미리 계산한 값이다');

% ---- 오른쪽 : 모델 오차를 훑는다
nexttile; hold on; grid on
mv = linspace(-0.4, 0.4, 41);
e1 = zeros(size(mv));  e2 = zeros(size(mv));
for i = 1:numel(mv)
    Bi = B*(1 - mv(i));
    e1(i) = 1 - dcgain(ss(A - Bi*K, Bi*Kr, C, 0));
    e2(i) = 1 - dcgain(ss([A-Bi*Kx  -Bi*Ki; -C 0], [zeros(n,1); 1], [C 0], 0));
end
plot(100*mv, 100*e1, 'LineWidth', 2.6, 'Color',[0.85 0.33 0.10]);
plot(100*mv, 100*e2, 'LineWidth', 2.6, 'Color',[0.47 0.67 0.19]);
yline(0, 'k:', 'HandleVisibility','off');
xline(0, 'k:', 'HandleVisibility','off');
xlabel('플랜트 이득 오차 [%]'); ylabel('정상상태 오차 [%]');
legend('K_r 만 사용', '적분 상태 추가', 'Location','northwest');
title('적분 상태는 모델 오차와 무관하게 오차를 0 으로 만든다');
end


function fig_w13_nonlin_check()
% 선형 설계가 진짜 비선형 진자에서도 통하는가
%   [좌표 주의] p.f 는 매달린 자세 기준 절대각을 받고,
%   선형 모델 (A,B) 는 직립 기준 편차이다. u = u0 - K*dx , u0 = m*g*l*sin(pi) = 0
[~, pUp] = plant_pendulum(pi);
A = pUp.A;  B = pUp.B;
[~, ~, s_t] = spec2pole(10, 1);
K = place(A, B, [s_t, conj(s_t)]);

ang = [10 70 130];                      % 직립에서 벗어난 초기각 [deg]
tf_end = 3;  tv = linspace(0, tf_end, 900);
col = [0.00 0.45 0.74; 0.47 0.67 0.19; 0.85 0.33 0.10];

figure('Position',[60 60 1060 430]);
tiledlayout(1,2,'TileSpacing','compact');

% ---- 왼쪽 : 선형 예측과 비선형 실제
nexttile; hold on; grid on
for i = 1:numel(ang)
    d0 = [deg2rad(ang(i)); 0];
    xl = zeros(2, numel(tv));
    for j = 1:numel(tv), xl(:,j) = expm((A - B*K)*tv(j))*d0; end
    plot(tv, rad2deg(xl(1,:)), '--', 'LineWidth', 1.6, 'Color', col(i,:), ...
         'HandleVisibility','off');
    [~, xn] = ode45(@(tt,xx) pUp.f(xx, -K*[xx(1)-pi; xx(2)]), tv, [pi+d0(1); 0]);
    plot(tv, rad2deg(xn(:,1) - pi), 'LineWidth', 2.4, 'Color', col(i,:), ...
         'DisplayName', sprintf('초기각 %d\\circ', ang(i)));
end
yline(0, 'k:', 'HandleVisibility','off');
xlabel('시간 [s]'); ylabel('직립에서 벗어난 각도 [deg]');
legend('Location','northeast');
title('실선 = 비선형 실제,  점선 = 선형 예측');

% ---- 오른쪽 : 어디까지 맞는가
nexttile; hold on; grid on
av = 5:5:170;
emax = zeros(size(av));  umax = zeros(size(av));
for i = 1:numel(av)
    d0 = [deg2rad(av(i)); 0];
    [~, xn] = ode45(@(tt,xx) pUp.f(xx, -K*[xx(1)-pi; xx(2)]), tv, [pi+d0(1); 0]);
    dn = xn(:,1) - pi;
    xl = zeros(2, numel(tv));
    for j = 1:numel(tv), xl(:,j) = expm((A - B*K)*tv(j))*d0; end
    emax(i) = rad2deg(max(abs(dn(:) - xl(1,:).')));
    umax(i) = max(abs(-K*[dn.'; xn(:,2).']));
end
yyaxis left
plot(av, emax, 'LineWidth', 2.6);
ylabel('선형 예측과의 최대 차이 [deg]');
yyaxis right
plot(av, umax, 'LineWidth', 2.6);
ylabel('최대 토크 |u| [N\cdotm]');
xlabel('직립에서 벗어난 초기각 [deg]');
title('각이 커질수록 선형 예측이 어긋나고 토크가 커진다');
end


function fig_w13_pendulum()
% 거꾸로 선 진자를 세운다 — 학기의 하이라이트
[~, pUp] = plant_pendulum(pi);
A = pUp.A;  B = pUp.B;  C = pUp.C;
[~, ~, s_t] = spec2pole(10, 1);
K   = place(A, B, [s_t, conj(s_t)]);
Acl = A - B*K;

figure('Position', [60 60 1160 460]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
plot(real(eig(A)), imag(eig(A)), 'x', 'MarkerSize', 18, 'LineWidth', 3.5, ...
     'Color', [0.85 0.20 0.15]); hold on; grid on;
plot(real(eig(Acl)), imag(eig(Acl)), 'o', 'MarkerSize', 14, 'LineWidth', 3, ...
     'Color', [0.00 0.45 0.74]);
xline(0, 'k-', 'LineWidth', 2.2);
yline(0, 'k:');
xlim([-9 9]); ylim([-7 7]);
xlabel('실수부'); ylabel('허수부');
legend('개루프 (+5.72 가 우반면)', ...
       sprintf('상태궤환 후 (%.1f \\pm %.1fj)', real(s_t), imag(s_t)), ...
       'Location', 'northwest');
text(5.72, 1.1, '넘어지게 하는 극점', 'FontSize', 11, 'FontWeight', 'bold', ...
     'Color', [0.85 0.20 0.15], 'HorizontalAlignment', 'center');
title('우반면 극점을 좌반면으로 끌어온다');

nexttile
t = (0:0.002:2)';
x0 = [deg2rad(10); 0];
y_o = initial(ss(A,   B, C, 0), x0, t);
y_c = initial(ss(Acl, B, C, 0), x0, t);
plot(t, rad2deg(y_o), 'LineWidth', 2.6, 'Color', [0.85 0.20 0.15]); hold on; grid on;
plot(t, rad2deg(y_c), 'LineWidth', 2.6, 'Color', [0.00 0.45 0.74]);
yline(0, 'k--', 'LineWidth', 1.4);
xlabel('시간 [s]'); ylabel('직립에서 기울어진 각도 [도]');
ylim([-6 45]);
legend('제어 없음 — 넘어간다', '상태궤환 — 돌아온다', 'Location', 'northwest');
title('10도 기울여 놓았을 때');
end


function fig_w13_saturation()
% 토크 한계가 유효범위를 정한다 (거꾸로 선 진자)
% [좌표 주의] p.f 는 매달린 자세 기준 절대각, A/B 는 직립 기준 편차다.
[~, pUp] = plant_pendulum(pi);
[~, ~, s_t] = spec2pole(10, 1);
K = place(pUp.A, pUp.B, [s_t, conj(s_t)]);

dev  = @(x) [x(1) - pi; x(2)];
abs0 = @(d) [pi + deg2rad(d); 0];

tau  = [Inf 1.0 0.6];
degs = 5:5:70;
OK   = false(numel(tau), numel(degs));
for j = 1:numel(tau)
    lj = tau(j);
    f  = @(t, x) pUp.f(x, max(min(pUp.u0 - K*dev(x), lj), -lj));
    for i = 1:numel(degs)
        [~, xi] = ode45(f, [0 6], abs0(degs(i)));
        OK(j,i) = abs(rad2deg(xi(end,1) - pi)) < 1;
    end
end

figure('Position', [60 60 1160 450]);
tiledlayout(1, 2, 'TileSpacing', 'compact');

nexttile
imagesc(degs, 1:numel(tau), double(OK));
colormap([0.95 0.78 0.76; 0.76 0.93 0.78]);
set(gca, 'YTick', 1:numel(tau), 'YTickLabel', {'한계 없음','1.0 Nm','0.6 Nm'});
xlabel('초기 기울기 [도]');
for j = 1:numel(tau)
    k = find(OK(j,:), 1, 'last');
    if ~isempty(k)
        % 마지막 칸이면 글자가 도화지 밖으로 나가므로 안쪽으로 붙인다
        if k == numel(degs), al = 'right'; else, al = 'left'; end
        text(degs(k), j, sprintf(' %d도까지 ', degs(k)), 'FontSize', 11, ...
             'FontWeight', 'bold', 'HorizontalAlignment', al);
    end
end
title('초록 = 세움, 분홍 = 넘어짐');

nexttile
hold on; grid on;
d0  = 35;
col = [0.20 0.20 0.20; 0.00 0.45 0.74; 0.85 0.20 0.15];
for j = 1:numel(tau)
    lj = tau(j);
    f  = @(t, x) pUp.f(x, max(min(pUp.u0 - K*dev(x), lj), -lj));
    [tj, xj] = ode45(f, [0 4], abs0(d0));
    if isinf(lj), nm = '한계 없음'; else, nm = sprintf('%.1f Nm', lj); end
    plot(tj, rad2deg(xj(:,1) - pi), 'LineWidth', 2.5, 'Color', col(j,:), ...
         'DisplayName', nm);
end
yline(0, 'k--', 'HandleVisibility', 'off');
xlabel('시간 [s]'); ylabel('직립에서 기울어진 각도 [도]');
ylim([-90 200]);
legend('Location', 'northwest');
title(sprintf('%d도에서 놓았을 때 — 토크가 모자라면 넘어간다', d0));
end
