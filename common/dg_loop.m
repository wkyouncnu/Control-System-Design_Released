function dg_loop(kind, ttl)
%DG_LOOP  자주 쓰는 표준 블록선도를 한 줄로 그린다
%
%   dg_loop(kind)
%   dg_loop(kind, '제목')
%
%   그릴 수 있는 것
%     'open'         개루프 — 되먹임이 없다
%     'closed'       단위 피드백 폐루프 — 가장 기본
%     'controller'   제어기 C(s) 가 있는 폐루프
%     'disturbance'  외란 d 가 플랜트 입력으로 들어오는 폐루프
%     'sensor'       센서 H(s) 가 있는 비단위 피드백
%     'saturation'   구동기 포화가 있는 폐루프
%     'noise'        측정 잡음 n 이 있는 폐루프
%     'statespace'   상태공간 (적분기와 A, B, C)
%     'pid'          PID 세 갈래가 더해지는 폐루프
%     'statefeedback' 상태궤환 u = -Kx + Kr*r
%     'observer'     관측기 기반 제어기 (플랜트와 관측기가 나란히)
%
%   신호 이름 약속
%     r 목표값,  e 오차,  u 제어입력,  y 출력,  d 외란,  n 측정잡음
%
%   예제
%     dg_loop('closed', '오늘 다룰 구조');
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 2, ttl = ''; end

switch lower(kind)

case 'open'
    dg_new(10, 3, ttl);
    c = dg_block(3.2, 1.6, 1.8, 1.0, 'C(s)', [0.88 0.93 1.00]);
    g = dg_block(6.6, 1.6, 1.8, 1.0, 'G(s)', [0.93 0.93 0.93]);
    dg_arrow([0.8 1.6], c.L, 'r');
    dg_arrow(c.R, g.L, 'u');
    dg_arrow(g.R, [9.4 1.6], 'y');
    text(5.0, 0.35, '출력을 보지 않는다 = 눈 감고 물 붓기', ...
         'HorizontalAlignment','center','FontSize',10,'Color',[0.45 0.45 0.45]);

case {'closed', 'controller'}
    dg_new(10, 3.4, ttl);
    e = dg_sum(2.2, 2.0, '+-');
    c = dg_block(4.2, 2.0, 1.6, 1.0, 'C(s)', [0.88 0.93 1.00]);
    g = dg_block(7.0, 2.0, 1.6, 1.0, 'G(s)', [0.93 0.93 0.93]);
    dg_arrow([0.6 2.0], e.L, 'r');
    dg_arrow(e.R, c.L, 'e');
    dg_arrow(c.R, g.L, 'u');
    dg_arrow(g.R, [9.4 2.0], 'y');
    dg_arrow([8.4 2.0], e.B, '', 'back');
    text(5.0, 0.30, '출력을 다시 빼서 오차를 만든다 = 샤워기 온도 맞추기', ...
         'HorizontalAlignment','center','FontSize',10,'Color',[0.45 0.45 0.45]);

case 'disturbance'
    dg_new(10, 3.8, ttl);
    e = dg_sum(2.0, 2.0, '+-');
    c = dg_block(3.8, 2.0, 1.5, 1.0, 'C(s)', [0.88 0.93 1.00]);
    sd = dg_sum(5.5, 2.0, '++');
    g = dg_block(7.2, 2.0, 1.5, 1.0, 'G(s)', [0.93 0.93 0.93]);
    dg_arrow([0.5 2.0], e.L, 'r');
    dg_arrow(e.R, c.L, 'e');
    dg_arrow(c.R, sd.L, 'u');
    dg_arrow([5.5 3.3], sd.T, 'd', 'dash');
    dg_arrow(sd.R, g.L, '');
    dg_arrow(g.R, [9.4 2.0], 'y');
    dg_arrow([8.6 2.0], e.B, '', 'back');
    text(5.0, 0.30, '외란 d 는 바람이나 마찰처럼 밖에서 밀고 들어오는 힘', ...
         'HorizontalAlignment','center','FontSize',10,'Color',[0.45 0.45 0.45]);

case 'dist_open'
    % 1주차 6절 : 외란이 들어오는 개루프.
    % 'dist_closed' 와 **짝으로** 쓴다. 두 그림에서 d 가 꽂히는 자리가 같다.
    %
    % [주의] 한 도화지에 두 구조를 나란히 그리면, 두 구조 사이의 화살표
    %        끝점이 도화지 한가운데에 떠서 dg_check 가 "끊긴 끝점" 으로 잡는다.
    %        그래서 그림을 둘로 나눈다.
    dg_new(9.6, 3.9, ttl);
    kf = dg_block(2.3, 2.0, 1.5, 1.0, 'K_{ff}', [0.88 0.93 1.00]);
    s1 = dg_sum(4.6, 2.0, '++');
    g1 = dg_block(6.6, 2.0, 1.5, 1.0, 'G(s)', [0.93 0.93 0.93]);
    dg_arrow([0.5 2.0], kf.L, 'r');
    dg_arrow(kf.R, s1.L, 'u');
    dg_arrow([4.6 3.3], s1.T, 'd', 'dash');
    dg_arrow(s1.R, g1.L, 'u+d');
    dg_arrow(g1.R, [9.1 2.0], 'y');
    text(4.8, 0.30, ...
        '되먹임 선이 없다 — 외란이 들어온 줄도 모른다', ...
        'HorizontalAlignment','center','FontSize',10,'Color',[0.45 0.45 0.45]);

case 'dist_closed'
    % 1주차 6절 : 같은 외란이 들어오는 폐루프. 'dist_open' 과 짝.
    dg_new(11.4, 3.9, ttl);
    kr = dg_block(1.9, 2.0, 1.2, 1.0, 'K_r', [0.88 0.93 1.00]);
    se = dg_sum(3.7, 2.0, '+-');
    kk = dg_block(5.0, 2.0, 1.0, 1.0, 'K',   [0.88 0.93 1.00]);
    s2 = dg_sum(6.5, 2.0, '++');
    g2 = dg_block(8.2, 2.0, 1.5, 1.0, 'G(s)', [0.93 0.93 0.93]);
    dg_arrow([0.5 2.0], kr.L, 'r');
    dg_arrow(kr.R, se.L, '');
    dg_arrow(se.R, kk.L, 'e');
    dg_arrow(kk.R, s2.L, 'u');
    dg_arrow([6.5 3.3], s2.T, 'd', 'dash');
    dg_arrow(s2.R, g2.L, 'u+d');
    dg_arrow(g2.R, [10.9 2.0], 'y');
    dg_arrow([10.1 2.0], se.B, '', 'back');
    text(5.7, 0.30, ...
        '되먹임 선이 있다 — d 가 만든 변화가 e 로 돌아와 u 를 바꾼다', ...
        'HorizontalAlignment','center','FontSize',10,'Color',[0.45 0.45 0.45]);

case 'sensor'
    dg_new(10, 3.6, ttl);
    e = dg_sum(2.2, 2.2, '+-');
    c = dg_block(4.2, 2.2, 1.6, 1.0, 'C(s)', [0.88 0.93 1.00]);
    g = dg_block(7.0, 2.2, 1.6, 1.0, 'G(s)', [0.93 0.93 0.93]);
    h = dg_block(5.6, 0.7, 1.6, 0.8, 'H(s)', [1.00 0.95 0.85]);
    dg_arrow([0.6 2.2], e.L, 'r');
    dg_arrow(e.R, c.L, 'e');
    dg_arrow(c.R, g.L, 'u');
    dg_arrow(g.R, [9.4 2.2], 'y');
    dg_arrow([8.4 2.2], [8.4 0.7], '');
    dg_arrow([8.4 0.7], h.R, '');
    dg_arrow(h.L, [2.2 0.7], '');
    dg_arrow([2.2 0.7], e.B, '');
    text(5.0, 3.35, '센서도 나름의 동특성이 있다. 그래서 H(s) 가 1 이 아니다', ...
         'HorizontalAlignment','center','FontSize',10,'Color',[0.45 0.45 0.45]);

case 'saturation'
    dg_new(11, 3.4, ttl);
    e = dg_sum(2.0, 2.0, '+-');
    c = dg_block(3.7, 2.0, 1.4, 1.0, 'C(s)', [0.88 0.93 1.00]);
    sa = dg_block(5.8, 2.0, 1.6, 1.0, '포화', [1.00 0.88 0.85]);
    g = dg_block(8.1, 2.0, 1.4, 1.0, 'G(s)', [0.93 0.93 0.93]);
    dg_arrow([0.5 2.0], e.L, 'r');
    dg_arrow(e.R, c.L, 'e');
    dg_arrow(c.R, sa.L, 'u');
    dg_arrow(sa.R, g.L, '');
    dg_arrow(g.R, [10.4 2.0], 'y');
    dg_arrow([9.5 2.0], e.B, '', 'back');
    text(5.5, 0.30, '구동기는 정해진 값까지만 낸다. 그 이상을 요구하면 잘려 나간다', ...
         'HorizontalAlignment','center','FontSize',10,'Color',[0.45 0.45 0.45]);

case 'noise'
    dg_new(10, 3.8, ttl);
    e = dg_sum(2.0, 2.2, '+-');
    c = dg_block(3.8, 2.2, 1.5, 1.0, 'C(s)', [0.88 0.93 1.00]);
    g = dg_block(6.4, 2.2, 1.5, 1.0, 'G(s)', [0.93 0.93 0.93]);
    sn = dg_sum(8.4, 2.2, '++');
    dg_arrow([0.5 2.2], e.L, 'r');
    dg_arrow(e.R, c.L, 'e');
    dg_arrow(c.R, g.L, 'u');
    dg_arrow(g.R, sn.L, 'y');
    dg_arrow([8.4 3.5], sn.T, 'n', 'dash');
    dg_arrow(sn.R, [9.6 2.2], '');
    dg_arrow([9.0 2.2], e.B, '', 'back');
    text(5.0, 0.35, '센서가 재는 값에는 항상 잡음이 섞여 있다', ...
         'HorizontalAlignment','center','FontSize',10,'Color',[0.45 0.45 0.45]);

case 'statespace'
    dg_new(11.5, 3.6, ttl);
    b  = dg_block(2.2, 2.2, 1.2, 0.9, 'B', [0.88 0.93 1.00]);
    sm = dg_sum(4.0, 2.2, '++');
    it = dg_block(6.4, 2.2, 1.6, 0.9, '적분', [0.90 1.00 0.90]);
    cc = dg_block(9.0, 2.2, 1.2, 0.9, 'C', [0.88 0.93 1.00]);
    aa = dg_block(6.0, 0.7, 1.2, 0.8, 'A', [1.00 0.95 0.85]);
    dg_arrow([0.7 2.2], b.L, 'u');
    dg_arrow(b.R, sm.L, '');
    dg_arrow(sm.R, it.L, 'dx/dt');
    dg_arrow(it.R, cc.L, 'x');
    dg_arrow(cc.R, [11.0 2.2], 'y');
    dg_arrow([7.8 2.2], [7.8 0.7], '');
    dg_arrow([7.8 0.7], aa.R, '');
    dg_arrow(aa.L, [4.0 0.7], '');
    dg_arrow([4.0 0.7], sm.B, '');
    text(5.7, 3.35, '상태 x 는 게임 세이브 파일. 지금까지의 이야기가 다 들어 있다', ...
         'HorizontalAlignment','center','FontSize',10,'Color',[0.45 0.45 0.45]);

case 'pid'
    dg_new(11, 4.6, ttl);
    e  = dg_sum(1.8, 2.4, '+-');
    kp = dg_block(4.0, 3.6, 1.5, 0.8, 'Kp',    [0.88 0.93 1.00]);
    ki = dg_block(4.0, 2.4, 1.5, 0.8, 'Ki / s', [0.90 1.00 0.90]);
    kd = dg_block(4.0, 1.2, 1.5, 0.8, 'Kd s',  [1.00 0.95 0.85]);
    sm = dg_sum(6.6, 2.4, '++');
    g  = dg_block(8.4, 2.4, 1.5, 1.0, 'G(s)', [0.93 0.93 0.93]);
    text(6.6 - 0.55, 2.4 + 0.62, '+', 'HorizontalAlignment','center', ...
         'FontSize', 12, 'FontWeight','bold');
    dg_arrow([0.5 2.4], e.L, 'r');
    dg_arrow(e.R, [3.0 2.4], 'e');
    dg_arrow([3.0 1.2], [3.0 3.6], '');
    dg_arrow([3.0 3.6], kp.L, '');
    dg_arrow([3.0 2.4], ki.L, '');
    dg_arrow([3.0 1.2], kd.L, '');
    dg_arrow(kp.R, [6.6 3.6], '');
    dg_arrow([6.6 3.6], sm.T, '');
    dg_arrow(ki.R, sm.L, '');
    dg_arrow(kd.R, [6.6 1.2], '');
    dg_arrow([6.6 1.2], sm.B, '');
    dg_arrow(sm.R, g.L, 'u');
    dg_arrow(g.R, [10.6 2.4], 'y');
    dg_arrow([10.0 2.4], [10.0 0.5], '');
    dg_arrow([10.0 0.5], [1.8 0.5], '');
    dg_arrow([1.8 0.5], e.B, '');
    text(5.5, 4.35, 'P 는 지금, I 는 쌓인 과거, D 는 다가올 미래를 본다', ...
         'HorizontalAlignment','center','FontSize',10,'Color',[0.45 0.45 0.45]);

case 'statefeedback'
    dg_new(11.5, 4.2, ttl);
    kr = dg_block(1.7, 2.6, 1.3, 0.9, 'Kr',   [1.00 0.95 0.85]);
    sm = dg_sum(3.9, 2.6, '+-');
    g  = dg_block(6.4, 2.6, 2.2, 1.1, '플랜트', [0.93 0.93 0.93]);
    kk = dg_block(6.4, 0.9, 1.3, 0.8, 'K',    [0.88 0.93 1.00]);
    dg_arrow([0.4 2.6], kr.L, 'r');
    dg_arrow(kr.R, sm.L, '');
    dg_arrow(sm.R, g.L, 'u');
    dg_arrow(g.R, [10.9 2.6], 'x');
    dg_arrow([9.4 2.6], [9.4 0.9], '');
    dg_arrow([9.4 0.9], kk.R, '');
    dg_arrow(kk.L, [3.9 0.9], '');
    dg_arrow([3.9 0.9], sm.B, '');
    text(5.8, 3.95, '상태를 전부 재서 되돌린다.  u = -K x + Kr r', ...
         'HorizontalAlignment','center','FontSize',10,'Color',[0.45 0.45 0.45]);

case 'observer'
    dg_new(12, 5.0, ttl);
    sm = dg_sum(2.2, 3.4, '+-');
    g  = dg_block(4.4, 3.4, 2.0, 1.0, '실제 플랜트', [0.93 0.93 0.93]);
    ob = dg_block(4.4, 1.3, 2.0, 1.0, '관측기',     [0.90 1.00 0.90]);
    kk = dg_block(8.6, 1.3, 1.3, 0.8, 'K',         [0.88 0.93 1.00]);
    dg_arrow([0.6 3.4], sm.L, 'r');
    dg_arrow(sm.R, g.L, 'u');
    dg_arrow(g.R, [11.2 3.4], 'y');
    dg_arrow([3.2 3.4], [3.2 1.3], '');
    dg_arrow([3.2 1.3], ob.L, 'u');
    dg_arrow([10.2 3.4], [10.2 2.4], '');
    dg_arrow([10.2 2.4], [4.4 2.4], 'y 를 관측기에도 준다');
    dg_arrow([4.4 2.4], ob.T, '');
    dg_arrow(ob.R, kk.L, 'x 추정');
    dg_arrow(kk.R, [10.6 1.3], '');
    dg_arrow([10.6 1.3], [10.6 0.4], '');
    dg_arrow([10.6 0.4], [2.2 0.4], '');
    dg_arrow([2.2 0.4], sm.B, '');
    text(6.0, 4.65, '상태를 못 재면 만들어 낸다 — 같은 모델을 함께 돌린다', ...
         'HorizontalAlignment','center','FontSize',10,'Color',[0.45 0.45 0.45]);

otherwise
    error('dg_loop:종류 - 모르는 종류입니다: %s (help dg_loop 참고)', kind);
end
end
