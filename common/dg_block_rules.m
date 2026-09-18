function dg_block_rules(ttl)
%DG_BLOCK_RULES  블록선도 축약 세 규칙 (직렬·병렬·되먹임) 을 한 장에
%
%   dg_block_rules()
%   dg_block_rules('제목')
%
%   3주차 1~2절에서 씁니다. 복잡한 블록선도도 이 셋의 조합이므로,
%   안쪽부터 하나씩 접어 나가면 반드시 하나로 줄어듭니다.
%
%   [배치 주의] 세 줄이 각각 독립된 작은 블록선도입니다.
%   입력·출력 화살표는 **도화지 좌우 끝까지** 그어야 합니다.
%   중간에서 끊으면 dg_check 가 "끊긴 끝점" 으로 잡습니다 (외부 단자로 못 봄).
%
%   See also DG_LOOP
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(ttl), ttl = '블록선도에서 외울 것은 이 세 줄뿐'; end

W = 13; H = 10.6;
dg_new(W, H, ttl);
set(gcf, 'Position', [80 80 900 740]);

xIn  = 0.5;          % 도화지 왼쪽 끝 (외부 입력 단자)
xOut = 12.5;         % 도화지 오른쪽 끝 (외부 출력 단자)

%% ① 직렬
text(0.3, 10.05, '① 직렬 — 곱한다', 'FontSize', 13, 'FontWeight','bold');
y1 = 8.9;
a1 = dg_block(5.0, y1, 1.7, 0.9, 'G_1', [0.88 0.93 1.00]);
a2 = dg_block(7.6, y1, 1.7, 0.9, 'G_2', [0.88 0.93 1.00]);
dg_arrow([xIn y1], a1.L, 'u');
dg_arrow(a1.R, a2.L, '');
dg_arrow(a2.R, [xOut y1], 'y');
text(6.5, 7.85, 'y = G_2 G_1 u', 'FontSize', 13, 'HorizontalAlignment','center', ...
     'FontWeight','bold');

%% ② 병렬
text(0.3, 7.25, '② 병렬 — 더한다', 'FontSize', 13, 'FontWeight','bold');
y2 = 6.1;
b1 = dg_block(5.4, y2+0.75, 1.7, 0.8, 'G_1', [1.00 0.95 0.85]);
b2 = dg_block(5.4, y2-0.75, 1.7, 0.8, 'G_2', [1.00 0.95 0.85]);
bs = dg_sum(8.4, y2, '++');
dg_arrow([xIn y2], [3.0 y2], 'u');
dg_arrow([3.0 y2-0.75], [3.0 y2+0.75], '');
dg_arrow([3.0 y2+0.75], b1.L, '');
dg_arrow([3.0 y2-0.75], b2.L, '');
dg_arrow(b1.R, [8.4 y2+0.75], '');
dg_arrow([8.4 y2+0.75], bs.T, '');
dg_arrow(b2.R, [8.4 y2-0.75], '');
dg_arrow([8.4 y2-0.75], bs.B, '');
dg_arrow(bs.R, [xOut y2], 'y');
text(6.5, 4.55, 'y = (G_1 + G_2) u', 'FontSize', 13, 'HorizontalAlignment','center', ...
     'FontWeight','bold');

%% ③ 되먹임
text(0.3, 3.95, '③ 되먹임 — G 를 (1 + GH) 로 나눈다', 'FontSize', 13, 'FontWeight','bold');
y3 = 2.9;
cs = dg_sum(3.2, y3, '+-');
cg = dg_block(6.4, y3, 1.7, 0.9, 'G', [0.90 1.00 0.90]);
ch = dg_block(6.4, y3-1.5, 1.7, 0.8, 'H', [0.93 0.93 0.93]);
dg_arrow([xIn y3], cs.L, 'u');
dg_arrow(cs.R, cg.L, 'e');
dg_arrow(cg.R, [xOut y3], 'y');
dg_arrow([9.8 y3], [9.8 y3-1.5], '');
dg_arrow([9.8 y3-1.5], ch.R, '');
dg_arrow(ch.L, [3.2 y3-1.5], '');
dg_arrow([3.2 y3-1.5], cs.B, '');
text(6.5, 0.75, 'y = G u / (1 + G H)', 'FontSize', 13, ...
     'HorizontalAlignment','center', 'FontWeight','bold');

text(6.5, 0.2, '나머지는 이 셋의 조합이다. 복잡한 그림도 안쪽부터 하나씩 접으면 된다', ...
     'HorizontalAlignment','center', 'FontSize', 10.5, 'Color',[0.35 0.35 0.35]);
end
