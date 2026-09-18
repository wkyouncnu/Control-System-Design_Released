function dg_second_order(ttl)
%DG_SECOND_ORDER  표준 2차 시스템을 적분기 두 개로 그린 블록선도
%
%   dg_second_order()
%   dg_second_order('제목')
%
%   4주차 7절 (W04_SecondOrder_Sweep.slx 와 같은 구조) 에서 씁니다.
%   전달함수 블록 하나로 그리면 zeta 가 어디 들어가는지 안 보입니다.
%   적분기 두 개로 펼치면 **감쇠 경로의 게인 2*zeta*wn** 이 눈에 보입니다.
%   이것이 7주차 미분제어 D 와 같은 자리라는 것을 여기서 미리 보여 줍니다.
%
%   [배치 주의] 입력·출력 화살표는 도화지 좌우 끝까지 그어야 합니다.
%
%   See also DG_LOOP
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(ttl)
    ttl = '표준 2차 시스템을 적분기 두 개로 펼치면';
end

W = 15; H = 7.2;
dg_new(W, H, ttl);
set(gcf, 'Position', [60 60 1120 560]);

y = 5.2;
sm = dg_sum(2.3, y, '+-');
kg = dg_block( 4.3, y, 1.9, 1.0, '\omega_n^2',  [1.00 0.93 0.85]);
sd = dg_sum(6.6, y, '+-');
i1 = dg_block( 8.6, y, 1.5, 1.0, '1/s',         [0.90 0.95 1.00]);
i2 = dg_block(11.2, y, 1.5, 1.0, '1/s',         [0.90 0.95 1.00]);
dm = dg_block( 8.6, y-2.6, 2.4, 1.0, '2\zeta\omega_n', [0.88 1.00 0.88]);

dg_arrow([0.6 y], sm.L, 'r');
dg_arrow(sm.R, kg.L, 'e');
dg_arrow(kg.R, sd.L, '');
dg_arrow(sd.R, i1.L, 'd^2y/dt^2');
dg_arrow(i1.R, i2.L, 'dy/dt');
dg_arrow(i2.R, [14.4 y], 'y');

% 감쇠 경로 : 속도를 되먹인다
dg_arrow([10.4 y], [10.4 y-2.6], '');
dg_arrow([10.4 y-2.6], dm.R, '');
dg_arrow(dm.L, [6.6 y-2.6], '');
dg_arrow([6.6 y-2.6], sd.B, '');

% 위치 되먹임
dg_arrow([13.2 y], [13.2 y-4.3], '');
dg_arrow([13.2 y-4.3], [2.3 y-4.3], '');
dg_arrow([2.3 y-4.3], sm.B, '');

text(8.6, 1.55, '속도를 되먹이는 이 길이 감쇠다', ...
     'HorizontalAlignment','center', 'FontSize', 11.5, ...
     'Color', [0.15 0.50 0.20], 'FontWeight','bold');
text(7.7, 0.42, ['이 게인을 0 으로 두면 \zeta = 0 이 되어 영원히 진동한다. ' ...
                 '7주차 미분제어 D 가 바로 이 자리다'], ...
     'HorizontalAlignment','center', 'FontSize', 10.5, 'Color', [0.35 0.35 0.35]);
end
