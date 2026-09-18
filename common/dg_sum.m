function p = dg_sum(x, y, signs, r)
%DG_SUM  블록선도에 합산점(동그라미)을 그린다
%
%   dg_sum(x, y)
%   dg_sum(x, y, signs)
%   dg_sum(x, y, signs, r)
%   p = dg_sum(...)
%
%   합산점이란
%     신호 두 개를 더하거나 빼는 자리입니다. 피드백 제어에서 가장 중요한 곳이
%     여기입니다. 목표값에서 측정값을 빼서 **오차**를 만드는 자리이기 때문입니다.
%
%   입력
%     x, y  - 동그라미 한가운데 좌표
%     signs - 부호 두 글자. 첫 글자는 **왼쪽** 입력, 둘째는 **아래쪽** 입력
%             기본값 '+-'  (목표값은 더하고 측정값은 뺀다는 뜻)
%     r     - 반지름 (기본 0.28)
%
%   출력
%     p - dg_block 과 같은 형식의 좌표 구조체 (p.L p.R p.T p.B p.C)
%
%   예제
%     dg_new(8, 3);
%     e = dg_sum(3, 1.5, '+-');
%     dg_arrow([1 1.5], e.L, 'r');
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 3 || isempty(signs), signs = '+-';  end
if nargin < 4 || isempty(r),     r     = 0.28;  end

th = linspace(0, 2*pi, 100);
fill(x + r*cos(th), y + r*sin(th), 'w', ...
     'EdgeColor', [0.2 0.2 0.2], 'LineWidth', 1.4);

% 왼쪽 입력 부호 (동그라미 바깥 왼쪽 위)
text(x - r*2.3, y + r*1.4, signs(1), ...
     'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');

% 아래쪽 입력 부호 (동그라미 바깥 아래 오른쪽)
if numel(signs) >= 2
    text(x + r*1.2, y - r*1.9, signs(2), ...
         'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
end

p.L = [x-r, y];
p.R = [x+r, y];
p.T = [x, y+r];
p.B = [x, y-r];
p.C = [x, y];

dg_register('box', struct('x',x, 'y',y, 'w',2*r, 'h',2*r, 'label',signs, 'kind','sum'));
end
