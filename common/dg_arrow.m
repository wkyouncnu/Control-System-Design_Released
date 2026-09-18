function dg_arrow(p1, p2, label, style)
%DG_ARROW  블록선도에 신호선(화살표)을 그린다
%
%   dg_arrow(p1, p2)
%   dg_arrow(p1, p2, label)
%   dg_arrow(p1, p2, label, style)
%
%   입력
%     p1    - 출발점 [x y]
%     p2    - 도착점 [x y]
%     label - 신호 이름 (예 : 'r', 'e', 'u', 'y'). 생략 가능
%     style - 선 모양
%             'line' (기본) 곧은 선
%             'down'  먼저 오른쪽으로, 그다음 아래로 꺾는다
%             'up'    먼저 오른쪽으로, 그다음 위로 꺾는다
%             'back'  피드백 경로. 아래로 내려갔다가 왼쪽으로 간 뒤 위로 올라간다
%             'dash'  점선 (외란이나 잡음처럼 원치 않는 신호에 쓴다)
%
%   신호 이름 약속 (과목 전체에서 통일)
%     r 목표값,  e 오차,  u 제어입력,  y 출력,  d 외란,  n 측정잡음
%
%   예제
%     dg_new(8, 3);
%     g = dg_block(4, 1.5, 2, 1, 'G(s)');
%     dg_arrow([1 1.5], g.L, 'u');
%     dg_arrow(g.R, [7 1.5], 'y');
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 3, label = ''; end
if nargin < 4 || isempty(style), style = 'line'; end

col   = [0.15 0.15 0.15];
ls    = '-';
isExt = false;                 % 외부 신호(외란, 잡음) 인가
if strcmp(style, 'dash')
    ls    = '--';
    col   = [0.80 0.25 0.15];
    style = 'line';
    isExt = true;
end

switch style
    case 'line'
        pts = [p1; p2];
    case 'down'
        pts = [p1; p2(1) p1(2); p2];
    case 'up'
        pts = [p1; p2(1) p1(2); p2];
    case 'back'
        yb  = min(p1(2), p2(2)) - 1.0;
        pts = [p1; p1(1) yb; p2(1) yb; p2];
    otherwise
        pts = [p1; p2];
end

% 마지막 구간만 빼고 선으로 그린다
if size(pts,1) > 2
    plot(pts(1:end-1,1), pts(1:end-1,2), ls, 'Color', col, 'LineWidth', 1.4);
end

% 마지막 구간은 화살표
a = pts(end-1,:);  b = pts(end,:);
plot([a(1) b(1)], [a(2) b(2)], ls, 'Color', col, 'LineWidth', 1.4);

d = b - a;
L = hypot(d(1), d(2));
if L > 1e-9
    d  = d / L;
    hl = 0.22;                 % 화살촉 길이
    hw = 0.10;                 % 화살촉 폭
    n  = [-d(2), d(1)];        % 수직 방향
    tip  = b;
    base = b - hl*d;
    fill([tip(1) base(1)+hw*n(1) base(1)-hw*n(1)], ...
         [tip(2) base(2)+hw*n(2) base(2)-hw*n(2)], ...
         col, 'EdgeColor', col);
end

% 신호 이름은 첫 구간의 가운데에 붙인다.
% 세로 선이면 위가 아니라 옆에 붙여야 선과 겹치지 않는다.
if ~isempty(label)
    m  = (pts(1,:) + pts(2,:)) / 2;
    seg = pts(2,:) - pts(1,:);
    if abs(seg(2)) > abs(seg(1))          % 세로에 가까운 구간
        text(m(1) + 0.30, m(2), label, ...
             'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', ...
             'FontSize', 11, 'Color', col, 'Interpreter', 'tex');
    else
        text(m(1), m(2) + 0.26, label, ...
             'HorizontalAlignment', 'center', 'FontSize', 11, ...
             'Color', col, 'Interpreter', 'tex');
    end
end

dg_register('arrow', struct('pts', pts, 'label', label, 'ext', isExt));
end
