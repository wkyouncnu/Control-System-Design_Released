function dg_design_steps(ttl)
%DG_DESIGN_STEPS  근궤적 설계 여섯 단계 — 6주차부터 7·11·13주차까지 그대로 쓴다
%
%   dg_design_steps()
%   dg_design_steps('제목')
%
%   6주차 8절에서 씁니다. 앞의 네 단계는 도구를 부르는 일이고,
%   **뒤의 두 단계가 실무에서 자주 빠집니다.** 그래서 색을 달리했습니다.
%
%   [배치 주의] 입력·출력 화살표는 도화지 좌우 끝까지 그어야 합니다.
%
%   See also SPEC2POLE, DG_SPEC_MAP
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(ttl)
    ttl = '근궤적 설계 여섯 단계 — 뒤의 둘을 빼먹지 말 것';
end

W = 15.4; H = 7.6;
dg_new(W, H, ttl);
set(gcf, 'Position', [60 60 1150 560]);

yT = 5.6;  yB = 2.4;
cA = [0.88 0.93 1.00];        % 도구를 부르는 단계
cB = [1.00 0.88 0.85];        % 자주 빠뜨리는 단계

t1 = dg_block( 2.4, yT, 3.6, 1.5, '', cA);
t2 = dg_block( 7.0, yT, 3.6, 1.5, '', cA);
t3 = dg_block(11.6, yT, 3.6, 1.5, '', cA);
b1 = dg_block(11.6, yB, 3.6, 1.5, '', cA);
b2 = dg_block( 7.0, yB, 3.6, 1.5, '', cB);
b3 = dg_block( 2.4, yB, 3.6, 1.5, '', cB);

local_step(t1, '① 사양을 극점으로', 'spec2pole(%OS, t_s)');
local_step(t2, '② 궤적을 그린다',   'rlocus(L)');
local_step(t3, '③ 영역을 겹친다',   'sgrid(zeta, wn)');
local_step(b1, '④ 이득을 읽는다',   'rlocfind(L)');
local_step(b2, '⑤ 성능을 확인',     'stepinfo(T)');
local_step(b3, '⑥ 제어입력 확인',   'max|u| < 한계?');

dg_arrow([0.4 yT], t1.L, '');
dg_arrow(t1.R, t2.L, '');
dg_arrow(t2.R, t3.L, '');
dg_arrow([13.4 yT], [13.4 yB], '');      % 오른쪽 끝에서 아랫줄로 내려간다
dg_arrow(b1.L, b2.R, '');
dg_arrow(b2.L, b3.R, '');
dg_arrow(b3.L, [0.4 yB], '완료');

text(7.7, 4.0, '⑤⑥ 을 빼먹으면 시뮬레이션은 되는데 실물이 안 된다', ...
     'FontSize', 11.5, 'Color', [0.75 0.20 0.15], 'FontWeight','bold', ...
     'HorizontalAlignment','center');
text(7.7, 0.6, ['①~④ 는 MATLAB 이 해 준다. ' ...
                '⑤⑥ 은 사람이 해야 한다'], ...
     'HorizontalAlignment','center', 'FontSize', 10.5, 'Color', [0.35 0.35 0.35]);
end

% ---------------------------------------------------------------
function local_step(b, top, bot)
text(b.C(1), b.C(2)+0.30, top, 'HorizontalAlignment','center', ...
     'FontSize', 12, 'FontWeight','bold');
text(b.C(1), b.C(2)-0.34, bot, 'HorizontalAlignment','center', ...
     'FontSize', 10.5, 'Color', [0.15 0.35 0.65]);
end
