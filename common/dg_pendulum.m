function dg_pendulum(mode)
%DG_PENDULUM  진자를 그림으로 그린다 (장치 그림 · 자유물체도 · 두 동작점 비교)
%
%   dg_pendulum()          매달린 진자와 자유물체도를 나란히
%   dg_pendulum('down')    매달린 진자만
%   dg_pendulum('up')      거꾸로 선 진자만
%   dg_pendulum('fbd')     자유물체도만
%   dg_pendulum('compare') 두 동작점을 나란히 (3주차 하이라이트)
%
%   이 그림이 말하는 것
%     같은 진자인데 **어느 자세 근처에서 보느냐**에 따라 중력이 하는 일이 정반대입니다.
%
%     - 매달린 자세 : 밀면 중력이 **되돌린다**   $\rightarrow$ 안정
%     - 거꾸로 선 자세 : 밀면 중력이 **더 넘어뜨린다** $\rightarrow$ 불안정
%
%     식으로는 부호 하나 차이지만 결과는 완전히 다릅니다.
%
%   예제
%     dg_pendulum('compare');
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(mode), mode = 'both'; end

switch lower(mode)
    case 'down'
        figure('Color','w'); local_pend(gca, +1, '매달린 진자 (안정)');
    case 'up'
        figure('Color','w'); local_pend(gca, -1, '거꾸로 선 진자 (불안정)');
    case 'fbd'
        figure('Color','w'); local_fbd(gca);
    case 'compare'
        figure('Color','w','Position',[80 80 1000 420]);
        tiledlayout(1,2,'TileSpacing','compact');
        nexttile; local_pend(gca, +1, '매달린 진자 : 중력이 되돌린다');
        nexttile; local_pend(gca, -1, '거꾸로 선 진자 : 중력이 넘어뜨린다');
    otherwise
        figure('Color','w','Position',[80 80 1000 420]);
        tiledlayout(1,2,'TileSpacing','compact');
        nexttile; local_pend(gca, +1, '매달린 진자');
        nexttile; local_fbd(gca);
end
end

% ---------------------------------------------------------------
function local_pend(ax, dir, ttl)
% dir = +1 이면 아래로 매달림, -1 이면 위로 섬
axes(ax); cla; hold on; axis equal off;
xlim([0 8]); ylim([0 8]);

if dir > 0, py = 5.8; else, py = 2.2; end
px = 4;                               % 회전축
L  = 3.0;
th = deg2rad(24);                     % 기울어진 각도

% 천장 또는 바닥
if dir > 0
    plot([2.2 5.8], [py+0.9 py+0.9], 'k-', 'LineWidth', 2.5);
    for x = 2.3:0.35:5.7
        plot([x x-0.25], [py+0.9 py+1.15], 'k-', 'LineWidth', 1);
    end
else
    plot([2.2 5.8], [py-0.9 py-0.9], 'k-', 'LineWidth', 2.5);
    for x = 2.3:0.35:5.7
        plot([x x-0.25], [py-0.9 py-1.15], 'k-', 'LineWidth', 1);
    end
    plot([px px], [py-0.9 py], 'k-', 'LineWidth', 2);
end

% 기준선 (연직)
plot([px px], [py, py - dir*(L+0.7)], 'k:', 'LineWidth', 1.2);

% 막대와 추
bx = px + L*sin(th);
by = py - dir*L*cos(th);
plot([px bx], [py by], 'k-', 'LineWidth', 3);
plot(px, py, 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'k');
plot(bx, by, 'o', 'MarkerSize', 26, 'MarkerFaceColor', [0.88 0.92 1.0], ...
     'MarkerEdgeColor', 'k', 'LineWidth', 1.8);
text(bx, by, 'm', 'FontSize', 13, 'FontWeight','bold', ...
     'HorizontalAlignment','center');

% 각도 표시
aa = linspace(0, th, 30);
r  = 1.15;
plot(px + r*sin(aa), py - dir*r*cos(aa), '-', 'Color', [0.2 0.4 0.8], 'LineWidth', 1.8);
text(px + 0.30, py - dir*1.55, '\theta', 'FontSize', 16, ...
     'Color', [0.2 0.4 0.8], 'FontWeight','bold');

% 중력 (추에서 아래로)
local_arrow([bx by], [bx by-1.3], [0.85 0.2 0.15], 2.0);
text(bx + 0.62, by - 0.9, 'm g', 'FontSize', 12, ...
     'Color', [0.85 0.2 0.15], 'FontWeight','bold');

% 막대 길이 표시 (막대에 수직으로 조금 떨어뜨려 놓는다)
mx = px + L*sin(th)/2;  my = py - dir*L*cos(th)/2;
nx = -dir*cos(th);      ny = -sin(th);          % 막대에 수직인 방향
text(mx + 0.55*nx, my + 0.55*ny, 'l', 'FontSize', 15, 'FontWeight','bold', ...
     'HorizontalAlignment','center');

% 결론 한 줄 (두 자세 모두 같은 높이에 둔다. 좌우로 어긋나면 비교가 안 된다)
if dir > 0
    msg = '밀면 중력이 되돌린다';        col = [0.15 0.45 0.2];
else
    msg = '밀면 중력이 더 넘어뜨린다';   col = [0.80 0.20 0.15];
end
text(4, 0.4, msg, 'FontSize', 12, 'Color', col, ...
     'FontWeight','bold', 'HorizontalAlignment','center');

title(ttl, 'FontSize', 12);
end

% ---------------------------------------------------------------
function local_fbd(ax)
axes(ax); cla; hold on; axis equal off;
xlim([0 8]); ylim([0 8]);

px = 4; py = 6.2; L = 3.0; th = deg2rad(30);
bx = px + L*sin(th);
by = py - L*cos(th);

plot([px px], [py, py-L-0.5], 'k:', 'LineWidth', 1.2);
plot([px bx], [py by], 'k-', 'LineWidth', 3);
plot(px, py, 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'k');
plot(bx, by, 'o', 'MarkerSize', 26, 'MarkerFaceColor', [0.88 0.92 1.0], ...
     'MarkerEdgeColor', 'k', 'LineWidth', 1.8);

% 중력 전체
local_arrow([bx by], [bx by-1.6], [0.85 0.2 0.15], 2.2);
text(bx+0.5, by-1.2, 'm g', 'FontSize', 12, 'Color', [0.85 0.2 0.15], ...
     'FontWeight','bold');

% 접선 성분 (막대에 수직)
tx = cos(th); ty = sin(th);                 % 접선 방향 (되돌리는 쪽)
local_arrow([bx by], [bx-1.5*tx by-1.5*ty], [0.15 0.35 0.75], 2.2);
text(bx-1.9*tx-0.1, by-1.9*ty-0.25, 'm g sin\theta', 'FontSize', 12, ...
     'Color', [0.15 0.35 0.75], 'FontWeight','bold', 'HorizontalAlignment','center');

% 반지름 성분 (막대 방향, 장력이 상쇄)
rx = sin(th); ry = -cos(th);
plot([bx bx+1.2*rx], [by by+1.2*ry], ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5);

text(4, 1.5, 'm l^2 (d^2\theta/dt^2) = - m g l sin\theta + \tau', ...
     'FontSize', 13, 'FontWeight','bold', 'HorizontalAlignment','center');
text(4, 0.9, '회전 방향으로 실제로 일하는 것은 접선 성분뿐입니다', ...
     'FontSize', 10, 'Color', [0.45 0.45 0.45], 'HorizontalAlignment','center');
text(4, 0.35, 'sin 이 들어 있어서 이 식은 비선형입니다', ...
     'FontSize', 10, 'Color', [0.8 0.2 0.15], 'HorizontalAlignment','center');

title('자유물체도 : 중력을 두 방향으로 쪼갠다', 'FontSize', 12);
end

% ---------------------------------------------------------------
function local_arrow(a, b, col, lw)
plot([a(1) b(1)], [a(2) b(2)], '-', 'Color', col, 'LineWidth', lw);
d = b - a; L = hypot(d(1), d(2)); d = d/L;
n = [-d(2), d(1)];
hl = 0.30; hw = 0.14;
base = b - hl*d;
fill([b(1) base(1)+hw*n(1) base(1)-hw*n(1)], ...
     [b(2) base(2)+hw*n(2) base(2)-hw*n(2)], col, 'EdgeColor', col);
end
