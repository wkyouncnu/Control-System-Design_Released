function dg_motor()
%DG_MOTOR  DC 모터를 그림으로 그린다 (전기 쪽과 기계 쪽)
%
%   dg_motor()
%
%   DC 모터가 어려운 이유는 **전기와 기계가 맞물려 있기** 때문입니다.
%   그림을 보면 어디서 맞물리는지가 보입니다.
%
%     전기 -> 기계 :  전류가 흐르면 토크가 난다      $\tau = K i$
%     기계 -> 전기 :  빨리 돌면 역기전력이 생긴다    $e = K \omega$
%
%   그래서 식이 두 줄이고, 그 둘이 서로를 참조합니다.
%
%     $$L\frac{di}{dt} + R i = V - K\omega, \qquad
%       J\frac{d\omega}{dt} + b\,\omega = K i$$
%
%   이 두 줄을 정리하면 5주차에서 쓰는 전달함수가 나옵니다.
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

figure('Color','w','Position',[60 60 1000 460]);
ax = axes; hold on; axis equal off;
xlim([0 14]); ylim([0 7]);

xl = 1.4; yb = 1.6; yt = 5.4;

% ---- 전기 쪽 -----------------------------------------------------
plot([xl xl], [yb+0.9 yt-0.9], 'k-', 'LineWidth', 1.8);
plot([xl 3.0], [yt yt], 'k-', 'LineWidth', 1.8);
plot([xl 6.6], [yb yb], 'k-', 'LineWidth', 1.8);

% 전압원
th = linspace(0,2*pi,100); r = 0.55; yc = (yb+yt)/2;
fill(xl + r*cos(th), yc + r*sin(th), 'w', 'EdgeColor','k', 'LineWidth', 1.8);
text(xl, yc+0.18, '+', 'FontSize', 13, 'HorizontalAlignment','center');
text(xl, yc-0.22, '-', 'FontSize', 15, 'HorizontalAlignment','center');
text(xl-0.9, yc, 'V(t)', 'FontSize', 13, 'FontWeight','bold', ...
     'Color', [0.85 0.2 0.15], 'HorizontalAlignment','center');

% 저항 R
local_res([3.0 yt], [4.4 yt], 0.30);
text(3.7, yt+0.72, 'R', 'FontSize', 14, 'FontWeight','bold', ...
     'HorizontalAlignment','center');

% 인덕터 L (반원 네 개)
local_ind([4.7 yt], [6.1 yt], 0.26);
text(5.4, yt+0.72, 'L', 'FontSize', 14, 'FontWeight','bold', ...
     'HorizontalAlignment','center');

% 역기전력 (전압원 기호)
plot([6.1 6.6], [yt yt], 'k-', 'LineWidth', 1.8);
plot([6.6 6.6], [yt yc+0.55], 'k-', 'LineWidth', 1.8);
fill(6.6 + r*cos(th), yc + r*sin(th), 'w', 'EdgeColor','k', 'LineWidth', 1.8);
text(6.6, yc+0.18, '+', 'FontSize', 13, 'HorizontalAlignment','center');
text(6.6, yc-0.22, '-', 'FontSize', 15, 'HorizontalAlignment','center');
plot([6.6 6.6], [yc-0.55 yb], 'k-', 'LineWidth', 1.8);
text(5.35, yc, 'e = K \omega', 'FontSize', 12, 'FontWeight','bold', ...
     'Color', [0.15 0.35 0.75], 'HorizontalAlignment','center');
text(5.35, yc-0.55, '(역기전력)', 'FontSize', 10, ...
     'Color', [0.45 0.45 0.45], 'HorizontalAlignment','center');

% 전류
local_arrow([2.1 yt+0.40], [2.9 yt+0.40], [0.15 0.55 0.25], 1.8);
text(2.5, yt+0.80, 'i(t)', 'FontSize', 12, 'Color', [0.15 0.55 0.25], ...
     'FontWeight','bold', 'HorizontalAlignment','center');

text(4.0, 0.55, '전기 쪽 :  L di/dt + R i = V - K\omega', ...
     'FontSize', 12, 'FontWeight','bold', 'HorizontalAlignment','center');

% ---- 맞물리는 곳 --------------------------------------------------
local_arrow([7.4 yc+0.5], [9.0 yc+0.5], [0.85 0.2 0.15], 2.0);
text(8.2, yc+1.0, '\tau = K i', 'FontSize', 12, 'FontWeight','bold', ...
     'Color', [0.85 0.2 0.15], 'HorizontalAlignment','center');
local_arrow([9.0 yc-0.5], [7.4 yc-0.5], [0.15 0.35 0.75], 2.0);
text(8.2, yc-1.05, 'e = K \omega', 'FontSize', 12, 'FontWeight','bold', ...
     'Color', [0.15 0.35 0.75], 'HorizontalAlignment','center');

% ---- 기계 쪽 -----------------------------------------------------
rc = 1.45; cx = 11.0; cyy = yc;
fill(cx + rc*cos(th), cyy + rc*sin(th), [0.90 0.94 1.0], ...
     'EdgeColor','k', 'LineWidth', 2);
plot(cx, cyy, 'ko', 'MarkerSize', 7, 'MarkerFaceColor','k');
text(cx, cyy+0.35, 'J', 'FontSize', 16, 'FontWeight','bold', ...
     'HorizontalAlignment','center');
text(cx, cyy-0.45, '(관성)', 'FontSize', 10, 'Color', [0.45 0.45 0.45], ...
     'HorizontalAlignment','center');

% 회전 방향
aa = linspace(-0.6, 1.5, 40);
plot(cx + (rc+0.45)*cos(aa), cyy + (rc+0.45)*sin(aa), '-', ...
     'Color', [0.15 0.45 0.2], 'LineWidth', 2);
local_arrow([cx+(rc+0.45)*cos(aa(end-3)) cyy+(rc+0.45)*sin(aa(end-3))], ...
            [cx+(rc+0.45)*cos(aa(end))   cyy+(rc+0.45)*sin(aa(end))], ...
            [0.15 0.45 0.2], 2.0);
text(cx+0.2, cyy+rc+1.05, '\omega (각속도)', 'FontSize', 12, ...
     'Color', [0.15 0.45 0.2], 'FontWeight','bold', 'HorizontalAlignment','center');

% 마찰
text(cx+rc+0.9, cyy-0.9, 'b\omega', 'FontSize', 12, 'FontWeight','bold', ...
     'HorizontalAlignment','center');
text(cx+rc+0.9, cyy-1.45, '(마찰)', 'FontSize', 10, 'Color', [0.45 0.45 0.45], ...
     'HorizontalAlignment','center');

text(11.0, 0.55, '기계 쪽 :  J d\omega/dt + b\omega = K i', ...
     'FontSize', 12, 'FontWeight','bold', 'HorizontalAlignment','center');

title('DC 모터 : 전기와 기계가 K 로 맞물려 있다', 'FontSize', 13);
end

% ---------------------------------------------------------------
function local_res(p1, p2, amp)
L = p2(1)-p1(1); lead = 0.22; n = 6;
xs = [p1(1) p1(1)+lead]; ys = [p1(2) p1(2)];
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
function local_ind(p1, p2, amp)
n = 4; L = p2(1)-p1(1); seg = L/n;
plot([p1(1) p2(1)], [p1(2) p2(2)], 'w-');
for i = 1:n
    xc = p1(1) + seg*(i-0.5);
    aa = linspace(0, pi, 30);
    plot(xc + (seg/2)*cos(aa), p1(2) + amp*sin(aa), 'k-', 'LineWidth', 1.8);
end
end

% ---------------------------------------------------------------
function local_arrow(a, b, col, lw)
plot([a(1) b(1)], [a(2) b(2)], '-', 'Color', col, 'LineWidth', lw);
d = b-a; L = hypot(d(1),d(2)); d = d/L; n = [-d(2) d(1)];
hl = 0.26; hw = 0.12; base = b - hl*d;
fill([b(1) base(1)+hw*n(1) base(1)-hw*n(1)], ...
     [b(2) base(2)+hw*n(2) base(2)-hw*n(2)], col, 'EdgeColor', col);
end
