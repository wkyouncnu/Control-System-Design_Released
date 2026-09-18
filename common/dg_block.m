function p = dg_block(x, y, w, h, label, col)
%DG_BLOCK  블록선도에 네모 블록 하나를 그린다
%
%   dg_block(x, y, w, h, label)
%   dg_block(x, y, w, h, label, col)
%   p = dg_block(...)
%
%   입력
%     x, y  - 블록 **한가운데**의 좌표
%     w, h  - 가로, 세로 크기
%     label - 블록 안에 쓸 글자 (예 : 'G(s)', '플랜트')
%     col   - 채움 색 (생략하면 연한 회색). [r g b] 또는 'y' 같은 문자
%
%   출력
%     p - 구조체. 다른 블록과 이을 때 쓸 좌표가 들어 있다
%         p.L 왼쪽 가운데,  p.R 오른쪽 가운데
%         p.T 위쪽 가운데,  p.B 아래쪽 가운데
%         p.C 한가운데
%
%   왜 좌표를 돌려주는가
%     화살표를 그을 때 블록의 모서리 좌표를 매번 손으로 계산하면 틀립니다.
%     dg_arrow(a.R, b.L) 처럼 쓰면 됩니다.
%
%   예제
%     dg_new(8, 3);
%     g = dg_block(4, 1.5, 2, 1, 'G(s)');
%     dg_arrow([1 1.5], g.L, 'u');
%     dg_arrow(g.R, [7 1.5], 'y');
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 6 || isempty(col), col = [0.93 0.93 0.93]; end

rectangle('Position', [x-w/2, y-h/2, w, h], ...
          'Curvature', 0.08, ...
          'FaceColor', col, ...
          'EdgeColor', [0.2 0.2 0.2], ...
          'LineWidth', 1.4);

text(x, y, label, ...
     'HorizontalAlignment', 'center', ...
     'VerticalAlignment',   'middle', ...
     'FontSize', 11, 'Interpreter', 'tex');

p.L = [x-w/2, y];
p.R = [x+w/2, y];
p.T = [x, y+h/2];
p.B = [x, y-h/2];
p.C = [x, y];

dg_register('box', struct('x',x, 'y',y, 'w',w, 'h',h, 'label',label, 'kind','block'));
end
