function dg_msd(mode)
%DG_MSD  질량-스프링-댐퍼를 그림으로 그린다 (장치 그림 · 자유물체도)
%
%   dg_msd()          장치 그림과 자유물체도를 나란히
%   dg_msd('system')  장치 그림만
%   dg_msd('fbd')     자유물체도만
%
%   자유물체도(free body diagram)란
%     물체 하나만 떼어 내서 **그 물체에 걸리는 힘만** 화살표로 그린 그림입니다.
%     모델링의 첫걸음이고, 여기서 부호를 틀리면 뒤가 전부 틀립니다.
%
%   이 그림이 말하는 것
%     - 스프링은 늘어난 만큼 되돌리려 한다      $\rightarrow$  $-k x$
%     - 댐퍼는 빠르게 움직일수록 방해한다        $\rightarrow$  $-b\dot{x}$
%     - 둘 다 **움직임을 방해하는 쪽**이라 부호가 음수다
%
%   예제
%     dg_msd();          % 수업에서 가장 많이 쓰는 형태
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(mode), mode = 'both'; end

switch lower(mode)
    case 'system'
        figure('Color','w'); local_system(gca);
    case 'fbd'
        figure('Color','w'); local_fbd(gca);
    otherwise
        figure('Color','w','Position',[80 80 1000 380]);
        tiledlayout(1,2,'TileSpacing','compact');
        nexttile; local_system(gca);
        nexttile; local_fbd(gca);
end
end

% ---------------------------------------------------------------
function local_system(ax)
axes(ax); cla; hold on; axis equal off;
xlim([0 10]); ylim([0 5]);

% 벽 (빗금)
plot([1 1], [0.6 4.2], 'k-', 'LineWidth', 2.5);
for y = 0.7:0.35:4.1
    plot([0.65 1], [y+0.25 y], 'k-', 'LineWidth', 1);
end

% 스프링 (위)
local_spring([1 3.3], [4.6 3.3], 0.30, 8);
text(2.8, 3.85, 'k', 'FontSize', 13, 'FontWeight','bold', ...
     'HorizontalAlignment','center');

% 댐퍼 (아래)
local_damper([1 1.7], [4.6 1.7], 0.32);
text(2.8, 1.05, 'b', 'FontSize', 13, 'FontWeight','bold', ...
     'HorizontalAlignment','center');

% 질량
rectangle('Position', [4.6 1.2, 1.9 2.6], 'FaceColor', [0.88 0.92 1.0], ...
          'EdgeColor', 'k', 'LineWidth', 1.8);
text(5.55, 2.5, 'm', 'FontSize', 16, 'FontWeight','bold', ...
     'HorizontalAlignment','center');

% 바닥
plot([0.65 9.4], [1.2 1.2], 'k-', 'LineWidth', 1.2);

% 외력 F
local_arrow([6.5 2.5], [8.6 2.5], [0.85 0.2 0.15], 2.2);
text(7.55, 2.9, 'F(t)', 'FontSize', 13, 'Color', [0.85 0.2 0.15], ...
     'FontWeight','bold', 'HorizontalAlignment','center');

% 변위 x
plot([5.55 5.55], [3.8 4.55], 'k:', 'LineWidth', 1);
local_arrow([5.55 4.35], [7.3 4.35], [0.1 0.1 0.1], 1.6);
text(6.4, 4.72, 'x(t)  (오른쪽이 +)', 'FontSize', 11, ...
     'HorizontalAlignment','center');

title('장치 그림 : 벽 - 스프링 - 댐퍼 - 질량', 'FontSize', 12);
end

% ---------------------------------------------------------------
function local_fbd(ax)
axes(ax); cla; hold on; axis equal off;
xlim([0 10]); ylim([0 5]);

% 떼어 낸 질량
rectangle('Position', [4.0 1.8, 2.0 1.6], 'FaceColor', [0.88 0.92 1.0], ...
          'EdgeColor', 'k', 'LineWidth', 1.8);
text(5.0, 2.6, 'm', 'FontSize', 16, 'FontWeight','bold', ...
     'HorizontalAlignment','center');

% 오른쪽 : 외력 F
local_arrow([6.0 2.6], [8.3 2.6], [0.85 0.2 0.15], 2.2);
text(7.15, 3.0, 'F(t)', 'FontSize', 13, 'Color', [0.85 0.2 0.15], ...
     'FontWeight','bold', 'HorizontalAlignment','center');

% 왼쪽 : 스프링 힘과 댐퍼 힘 (둘 다 왼쪽으로)
local_arrow([4.0 3.05], [1.9 3.05], [0.15 0.35 0.75], 2.0);
text(2.95, 3.45, 'k x', 'FontSize', 13, 'Color', [0.15 0.35 0.75], ...
     'FontWeight','bold', 'HorizontalAlignment','center');

local_arrow([4.0 2.15], [1.9 2.15], [0.15 0.55 0.25], 2.0);
text(2.95, 1.6, 'b dx/dt', 'FontSize', 13, 'Color', [0.15 0.55 0.25], ...
     'FontWeight','bold', 'HorizontalAlignment','center');

% 양의 방향
local_arrow([7.2 0.9], [8.8 0.9], [0.35 0.35 0.35], 1.4);
text(8.0, 0.45, '+ 방향', 'FontSize', 11, 'Color', [0.35 0.35 0.35], ...
     'HorizontalAlignment','center');

% 뉴턴 제2법칙
text(5.0, 4.55, 'm a = F - k x - b dx/dt', ...
     'FontSize', 13, 'FontWeight','bold', 'HorizontalAlignment','center');
text(5.0, 4.05, '(오른쪽을 + 로 잡았다)', ...
     'FontSize', 10, 'Color', [0.45 0.45 0.45], 'HorizontalAlignment','center');

title('자유물체도 : 질량 하나에 걸리는 힘', 'FontSize', 12);
end

% ---------------------------------------------------------------
function local_spring(p1, p2, amp, n)
% 지그재그 스프링
L  = p2(1) - p1(1);
lead = 0.5;
xs = [p1(1), p1(1)+lead];
ys = [p1(2), p1(2)];
seg = (L - 2*lead)/n;
for i = 1:n
    xs(end+1) = p1(1) + lead + seg*(i-0.5); %#ok<AGROW>
    if mod(i,2)==1, ys(end+1) = p1(2)+amp; else, ys(end+1) = p1(2)-amp; end %#ok<AGROW>
end
xs(end+1) = p2(1)-lead;  ys(end+1) = p2(2);
xs(end+1) = p2(1);       ys(end+1) = p2(2);
plot(xs, ys, 'k-', 'LineWidth', 1.8);
end

% ---------------------------------------------------------------
function local_damper(p1, p2, h)
% 실린더 + 피스톤
xm = (p1(1)+p2(1))/2;
w  = 1.0;                                   % 실린더 길이
plot([p1(1) xm-w/2], [p1(2) p1(2)], 'k-', 'LineWidth', 1.8);
% 실린더 (ㄷ 자, 오른쪽이 열림)
plot([xm-w/2 xm+w/2], [p1(2)+h p1(2)+h], 'k-', 'LineWidth', 1.8);
plot([xm-w/2 xm+w/2], [p1(2)-h p1(2)-h], 'k-', 'LineWidth', 1.8);
plot([xm-w/2 xm-w/2], [p1(2)-h p1(2)+h], 'k-', 'LineWidth', 1.8);
% 피스톤 (실린더 안의 판)
plot([xm+w/4 xm+w/4], [p1(2)-h*0.85 p1(2)+h*0.85], 'k-', 'LineWidth', 3.5);
plot([xm+w/4 p2(1)], [p2(2) p2(2)], 'k-', 'LineWidth', 1.8);
end

% ---------------------------------------------------------------
function local_arrow(a, b, col, lw)
plot([a(1) b(1)], [a(2) b(2)], '-', 'Color', col, 'LineWidth', lw);
d = b - a; L = hypot(d(1), d(2)); d = d/L;
n = [-d(2), d(1)];
hl = 0.28; hw = 0.13;
base = b - hl*d;
fill([b(1) base(1)+hw*n(1) base(1)-hw*n(1)], ...
     [b(2) base(2)+hw*n(2) base(2)-hw*n(2)], col, 'EdgeColor', col);
end
