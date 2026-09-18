function dg_pi_loop(ttl)
%DG_PI_LOOP  PI 제어기를 붙인 속도제어 루프 (W05_SteadyStateError.slx 와 같은 구조)
%
%   dg_pi_loop()
%   dg_pi_loop('제목')
%
%   5주차 10절에서 씁니다. 적분 경로를 **따로 그려야** Ki 를 0 으로 두면
%   무엇이 사라지는지 보입니다. PID 블록 하나로 그리면 그게 안 보입니다.
%
%   [배치 주의] 입력·출력 화살표는 도화지 좌우 끝까지 그어야 합니다.
%
%   See also DG_LOOP, DG_SECOND_ORDER
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(ttl)
    ttl = 'PI 제어기 — 적분 경로가 오차를 0 으로 만든다';
end

W = 15; H = 7.9;
dg_new(W, H, ttl);
set(gcf, 'Position', [60 60 1120 540]);

y = 5.0;
sm = dg_sum(2.2, y, '+-');
kp = dg_block( 5.0, y+1.05, 1.8, 0.9, 'K_p',      [1.00 0.93 0.85]);
ki = dg_block( 5.0, y-1.05, 1.8, 0.9, 'K_i / s',  [0.88 1.00 0.88]);
sa = dg_sum(7.8, y, '++');
pl = dg_block(10.8, y, 2.6, 1.1, '모터 G(s)',     [0.90 0.95 1.00]);

dg_arrow([0.6 y], sm.L, 'r');
dg_arrow(sm.R, [3.6 y], 'e');
dg_arrow([3.6 y-1.05], [3.6 y+1.05], '');
dg_arrow([3.6 y+1.05], kp.L, '');
dg_arrow([3.6 y-1.05], ki.L, '');
dg_arrow(kp.R, [7.8 y+1.05], '');
dg_arrow([7.8 y+1.05], sa.T, '');
dg_arrow(ki.R, [7.8 y-1.05], '');
dg_arrow([7.8 y-1.05], sa.B, '');
dg_arrow(sa.R, pl.L, 'u');
dg_arrow(pl.R, [14.4 y], 'y');

dg_arrow([13.0 y], [13.0 1.5], '');
dg_arrow([13.0 1.5], [2.2 1.5], '');
dg_arrow([2.2 1.5], sm.B, '');

text(5.0, y+1.95, '오차에 비례해서 지금 민다', 'HorizontalAlignment','center', ...
     'FontSize', 10.5, 'Color', [0.75 0.45 0.10], 'FontWeight','bold');
text(6.4, y-2.15, '오차를 쌓아 둔다 — 오차가 0 이어도 힘이 남는다', ...
     'HorizontalAlignment','center', 'FontSize', 10.5, ...
     'Color', [0.15 0.50 0.20], 'FontWeight','bold');
text(7.5, 0.45, ['K_i = 0 으로 두면 아래 경로가 사라져 그냥 비례제어가 된다. ' ...
                 '그때 정상상태 오차가 남는다'], ...
     'HorizontalAlignment','center', 'FontSize', 10.5, 'Color', [0.35 0.35 0.35]);
end
