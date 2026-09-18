function dg_spec_map(ttl)
%DG_SPEC_MAP  사양에서 극점까지 — 4주차 전체를 한 줄로 이은 지도
%
%   dg_spec_map()
%   dg_spec_map('제목')
%
%   4주차 4-3절에서 씁니다. "말 -> 숫자 -> 위치" 로 가는 길을 보여 줍니다.
%   설계는 이 화살표를 **왼쪽에서 오른쪽으로** 따라가는 일이고,
%   검증은 **오른쪽 끝에서 다시 왼쪽으로** 돌아와 맞는지 보는 일입니다.
%
%   [배치 주의] 입력·출력 화살표는 도화지 좌우 끝까지 그어야 합니다.
%   dg_check 는 도화지 가장자리(여백 1.05 안쪽)만 외부 단자로 봅니다.
%
%   See also SPEC2POLE, DG_BLOCK_RULES
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(ttl)
    ttl = '4주차 전체 지도 : 말 → 숫자 → 위치';
end

W = 15; H = 6.4;
dg_new(W, H, ttl);
set(gcf, 'Position', [60 60 1120 500]);

y = 4.3;
b1 = dg_block( 2.6, y, 3.4, 1.5, '',  [1.00 0.92 0.88]);
b2 = dg_block( 6.6, y, 2.6, 1.5, '',  [0.90 0.95 1.00]);
b3 = dg_block(10.2, y, 2.6, 1.5, '',  [0.90 1.00 0.90]);
b4 = dg_block(13.4, y, 1.8, 1.5, '',  [0.95 0.95 0.95]);

local_two(b1, '요구 사양',  '%OS \leq 10, t_s \leq 2 s');
local_two(b2, '설계 상수',  '\zeta \geq 0.591,  \omega_n \geq 3.39');
local_two(b3, '목표 극점',  's = -2.00 \pm 2.73j');
local_two(b4, '응답',       '확인');

dg_arrow([0.6 y], b1.L, '');
dg_arrow(b1.R, b2.L, '');
dg_arrow(b2.R, b3.L, '');
dg_arrow(b3.R, b4.L, '');
dg_arrow(b4.R, [14.6 y], '');

% 화살표 위에 "무엇으로 넘어가는가"
local_lab(4.60, y+1.05, 'spec2pole');
local_lab(8.40, y+1.05, '-\zeta\omega_n \pm j\omega_n\surd(1-\zeta^2)');
local_lab(11.90, y+1.05, 'step / stepinfo');

% 되돌아오는 검증 경로
dg_arrow([13.4 y-0.75], [13.4 2.2], '');
dg_arrow([13.4 2.2], [2.6 2.2], '');
dg_arrow([2.6 2.2], b1.B, '');
text(8.0, 1.85, '검증 — 정말 사양을 만족하는지 다시 확인한다', ...
     'HorizontalAlignment','center', 'FontSize', 11.5, ...
     'Color', [0.75 0.25 0.15], 'FontWeight','bold');

text(7.5, 0.75, ['설계는 왼쪽 → 오른쪽, 검증은 오른쪽 → 왼쪽. ' ...
                 '이 왕복을 한 번은 반드시 돈다'], ...
     'HorizontalAlignment','center', 'FontSize', 10.5, 'Color', [0.35 0.35 0.35]);
end

% ---------------------------------------------------------------
function local_two(b, top, bot)
% 블록 안에 두 줄을 쓴다 (윗줄은 이름, 아랫줄은 실제 값)
text(b.C(1), b.C(2)+0.32, top, 'HorizontalAlignment','center', ...
     'FontSize', 12, 'FontWeight','bold');
text(b.C(1), b.C(2)-0.34, bot, 'HorizontalAlignment','center', ...
     'FontSize', 10.5, 'Color', [0.20 0.20 0.20]);
end

function local_lab(x, y, str)
text(x, y, str, 'HorizontalAlignment','center', 'FontSize', 10.5, ...
     'Color', [0.15 0.35 0.65], 'FontWeight','bold');
end
