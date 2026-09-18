function dg_rc(kind)
%DG_RC  RC 회로 또는 RLC 회로를 그림으로 그린다
%
%   dg_rc()          RC  회로 (1차)
%   dg_rc('rc')      같음
%   dg_rc('rlc')     RLC 회로 (2차)
%
%   질량-스프링-댐퍼와 RC 회로는 **생김새가 전혀 다른데 식이 같습니다.**
%   그래서 하나를 풀 줄 알면 다른 것도 풉니다.
%   이것을 전기-기계 상사(analogy)라고 합니다.
%
%     기계 : $m\ddot{x} + b\dot{x} + kx = F$
%     전기 : $L\ddot{q} + R\dot{q} + q/C = v$
%
%   RC 회로는 그중 1차짜리입니다 ($L = 0$).
%   인덕터를 넣으면 2차가 되어 MSD 와 **항까지 하나씩 대응**합니다.
%
%     L <-> m (관성)     R <-> b (감쇠)     1/C <-> k (복원)
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(kind), kind = 'rc'; end
isRLC = strcmpi(kind, 'rlc');

figure('Color','w','Position',[80 80 720 420]);
ax = axes; hold on; axis equal off;
xlim([0 10]); ylim([0 7]);

% 좌표
xl = 1.6; xr = 8.0; yb = 1.4; yt = 5.4;

% 저항 구간. RLC 는 인덕터 자리를 만들어야 하므로 저항을 왼쪽으로 당긴다.
if isRLC, xR1 = 2.9; xR2 = 4.3;  xL1 = 5.0; xL2 = 6.6;
else,     xR1 = 3.4; xR2 = 5.2;
end

% 전선
plot([xl xl], [yb+0.9 yt-0.9], 'k-', 'LineWidth', 1.8);        % 왼쪽
plot([xl xR1], [yt yt], 'k-', 'LineWidth', 1.8);               % 위 왼쪽
if isRLC
    plot([xR2 xL1], [yt yt], 'k-', 'LineWidth', 1.8);          % R 과 L 사이
    plot([xL2 xr],  [yt yt], 'k-', 'LineWidth', 1.8);          % 위 오른쪽
else
    plot([xR2 xr], [yt yt], 'k-', 'LineWidth', 1.8);           % 위 오른쪽
end
plot([xl xr], [yb yb], 'k-', 'LineWidth', 1.8);                % 아래
plot([xr xr], [yb yt], 'k-', 'LineWidth', 1.8);                % 오른쪽 (윗부분)

% 전압원 (원 + 기호)
th = linspace(0,2*pi,100);
r  = 0.55;
yc = (yb+yt)/2;
fill(xl + r*cos(th), yc + r*sin(th), 'w', 'EdgeColor','k', 'LineWidth', 1.8);
text(xl, yc+0.18, '+', 'FontSize', 13, 'HorizontalAlignment','center');
text(xl, yc-0.22, '-', 'FontSize', 15, 'HorizontalAlignment','center');
text(xl-0.95, yc, 'v_{in}(t)', 'FontSize', 13, 'FontWeight','bold', ...
     'HorizontalAlignment','center', 'Color', [0.85 0.2 0.15]);

% 저항 (지그재그)
local_res([xR1 yt], [xR2 yt], 0.32);
text((xR1+xR2)/2, yt+0.75, 'R', 'FontSize', 15, 'FontWeight','bold', ...
     'HorizontalAlignment','center');

% 인덕터 (코일) — RLC 일 때만
if isRLC
    local_coil([xL1 yt], [xL2 yt], 0.34);
    text((xL1+xL2)/2, yt+0.80, 'L', 'FontSize', 15, 'FontWeight','bold', ...
         'HorizontalAlignment','center');
end

% 커패시터 (평행판) — 오른쪽 세로선 중간에
plot([xr-0.7 xr+0.7], [yc+0.22 yc+0.22], 'k-', 'LineWidth', 3);
plot([xr-0.7 xr+0.7], [yc-0.22 yc-0.22], 'k-', 'LineWidth', 3);
plot([xr xr], [yc+0.22 yt], 'k-', 'LineWidth', 1.8);
plot([xr xr], [yb yc-0.22], 'k-', 'LineWidth', 1.8);
text(xr+1.15, yc, 'C', 'FontSize', 15, 'FontWeight','bold', ...
     'HorizontalAlignment','center');

% 출력 전압 표시
plot([xr+0.55 xr+0.55], [yc+0.22 yc-0.22], 'w-');   % 자리 확보용
text(xr+1.15, yc+0.95, '+', 'FontSize', 13, 'HorizontalAlignment','center', ...
     'Color', [0.15 0.35 0.75]);
text(xr+1.15, yc-1.0, '-', 'FontSize', 15, 'HorizontalAlignment','center', ...
     'Color', [0.15 0.35 0.75]);
text(xr+1.9, yc+0.5, 'v_C(t)', 'FontSize', 13, 'FontWeight','bold', ...
     'Color', [0.15 0.35 0.75], 'HorizontalAlignment','center');

% 전류 (저항 앞쪽 전선 위에)
local_arrow([xR1-1.25 yt+0.40], [xR1-0.35 yt+0.40], [0.15 0.55 0.25], 1.8);
text(xR1-0.80, yt+0.80, 'i(t)', 'FontSize', 12, 'Color', [0.15 0.55 0.25], ...
     'FontWeight','bold', 'HorizontalAlignment','center');

if isRLC
    text(5.0, 0.75, ['v_{in} = L di/dt + R i + v_C  이고  i = C dv_C/dt' ...
                     '   \rightarrow   LC v_C'''' + RC v_C'' + v_C = v_{in}'], ...
         'FontSize', 12, 'FontWeight','bold', 'HorizontalAlignment','center');
    text(5.0, 0.15, 'L \leftrightarrow m ,   R \leftrightarrow b ,   1/C \leftrightarrow k', ...
         'FontSize', 12, 'HorizontalAlignment','center', 'Color', [0.15 0.35 0.75]);
    title('RLC 회로 : MSD 와 항이 하나씩 대응하는 2차 시스템', 'FontSize', 12);
else
    text(5.0, 0.55, ...
         'v_{in} = R i + v_C  이고  i = C dv_C/dt   \rightarrow   RC dv_C/dt + v_C = v_{in}', ...
         'FontSize', 12, 'FontWeight','bold', 'HorizontalAlignment','center');
    title('RC 회로 : 입력은 v_{in}, 출력은 v_C', 'FontSize', 12);
end
end

% ---------------------------------------------------------------
function local_coil(p1, p2, amp)
% 인덕터 : 반원 네 개를 이어 붙인다
L = p2(1)-p1(1);  lead = 0.22;  n = 4;
seg = (L - 2*lead)/n;
plot([p1(1) p1(1)+lead], [p1(2) p1(2)], 'k-', 'LineWidth', 1.8);
th = linspace(pi, 0, 40);
for i = 1:n
    cx = p1(1) + lead + seg*(i-0.5);
    plot(cx + (seg/2)*cos(th), p1(2) + amp*sin(th), 'k-', 'LineWidth', 1.8);
end
plot([p2(1)-lead p2(1)], [p2(2) p2(2)], 'k-', 'LineWidth', 1.8);
end

% ---------------------------------------------------------------
function local_res(p1, p2, amp)
L = p2(1)-p1(1);  lead = 0.28;  n = 6;
xs = [p1(1) p1(1)+lead];  ys = [p1(2) p1(2)];
seg = (L-2*lead)/n;
for i = 1:n
    xs(end+1) = p1(1)+lead+seg*(i-0.5); %#ok<AGROW>
    if mod(i,2)==1, ys(end+1) = p1(2)+amp; else, ys(end+1) = p1(2)-amp; end %#ok<AGROW>
end
xs(end+1) = p2(1)-lead; ys(end+1) = p2(2);
xs(end+1) = p2(1);      ys(end+1) = p2(2);
plot(xs, ys, 'k-', 'LineWidth', 1.8);
end

% ---------------------------------------------------------------
function local_arrow(a, b, col, lw)
plot([a(1) b(1)], [a(2) b(2)], '-', 'Color', col, 'LineWidth', lw);
d = b-a; L = hypot(d(1),d(2)); d = d/L; n = [-d(2) d(1)];
hl = 0.24; hw = 0.11; base = b - hl*d;
fill([b(1) base(1)+hw*n(1) base(1)-hw*n(1)], ...
     [b(2) base(2)+hw*n(2) base(2)-hw*n(2)], col, 'EdgeColor', col);
end
