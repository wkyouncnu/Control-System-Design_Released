function dg_region(P_OS, ts, box)
%DG_REGION  사양을 s 평면 위의 "쓸 수 있는 영역" 으로 색칠해 보여 준다
%
%   dg_region(P_OS, ts)
%   dg_region(P_OS, ts, [xmin xmax ymin ymax])
%
%   왜 이 그림이 중요한가
%     "오버슈트 10 % 이하, 정착시간 2 초 이하" 라는 **말**을
%     $s$ 평면 위의 **영역**으로 바꿔 놓으면 설계가 눈에 보이는 일이 됩니다.
%     그다음부터 설계란 "극점을 이 영역 안에 넣는 일" 이 됩니다.
%
%   두 조건이 각각 무엇을 정하는가
%     - 오버슈트 $\rightarrow$ $\zeta \ge \zeta_{min}$ $\rightarrow$ **부채꼴** (각도 조건)
%     - 정착시간 $\rightarrow$ $\zeta\omega_n \ge 4/t_s$ $\rightarrow$ **세로선 왼쪽** (실수부 조건)
%
%   두 조건을 모두 만족하는 곳이 색칠된 영역입니다.
%
%   예제
%     dg_region(10, 2);
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 3 || isempty(box), box = []; end

[zmin, wmin, starget] = spec2pole(P_OS, ts);
sig = zmin*wmin;                       % 필요한 실수부 크기 = 4/ts

if isempty(box)
    % 부채꼴 경계가 눈에 보이도록 잡는다.
    % 너무 넓게 잡으면 왼쪽이 통째로 칠해져 부채꼴 모양이 안 보인다.
    box = [-3.0*sig, 0.8*sig, -2.6*sig, 2.6*sig];
end

figure('Color','w','Position',[80 80 780 620]);
hold on; grid on; axis equal;
xlim(box(1:2)); ylim(box(3:4));

% ---- 만족 영역을 다각형으로 색칠 --------------------------------
th = acos(zmin);                       % 실축에서 잰 각도
xL = box(1);
yTop =  abs(xL)*tan(th);
yBot = -yTop;

% 부채꼴(각도 조건) ∩ 세로선 왼쪽(실수부 조건)
px = [-sig, xL, xL, -sig];
py = [ sig*tan(th), yTop, yBot, -sig*tan(th)];
fill(px, py, [0.80 0.92 0.80], 'EdgeColor','none', 'FaceAlpha', 0.75, ...
     'DisplayName', '두 조건을 다 만족하는 영역');

% ---- 경계선 -----------------------------------------------------
% zeta 선은 **원점에서 뻗어 나옵니다.** 원점 근처 구간은 옅게 그려
% "각도 조건은 만족하지만 너무 느린 곳" 이라는 것을 보여 줍니다.
plot([0 -sig], [0  sig*tan(th)], ':', 'Color', [0.15 0.45 0.2], ...
     'LineWidth', 1.6, 'HandleVisibility','off');
plot([0 -sig], [0 -sig*tan(th)], ':', 'Color', [0.15 0.45 0.2], ...
     'LineWidth', 1.6, 'HandleVisibility','off');
plot([xL -sig], [yTop  sig*tan(th)], '-', 'Color', [0.15 0.45 0.2], ...
     'LineWidth', 2, 'DisplayName', sprintf('\\zeta = %.3f 선 (오버슈트 %.0f %%)', zmin, P_OS));
plot([xL -sig], [yBot -sig*tan(th)], '-', 'Color', [0.15 0.45 0.2], ...
     'LineWidth', 2, 'HandleVisibility','off');
plot([-sig -sig], [box(3) box(4)], '--', 'Color', [0.35 0.2 0.6], ...
     'LineWidth', 2, 'DisplayName', sprintf('실수부 = -%.2f (정착시간 %.0f s)', sig, ts));

% ---- 목표 극점 ---------------------------------------------------
plot(real(starget), imag(starget), 'p', 'MarkerSize', 17, ...
     'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'k', ...
     'DisplayName', '두 조건이 딱 맞는 점');
plot(real(starget), -imag(starget), 'p', 'MarkerSize', 17, ...
     'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'k', 'HandleVisibility','off');

xline(0, 'k-', 'LineWidth', 1.4, 'HandleVisibility','off');
yline(0, 'k-', 'LineWidth', 1.0, 'HandleVisibility','off');

% ---- 안내 글 -----------------------------------------------------
text(box(1)*0.95, box(4)*0.45, '왼쪽으로 갈수록 빠르다', ...
     'FontSize', 11, 'Color', [0.35 0.2 0.6], 'HorizontalAlignment','left');
text(box(2)*0.9, box(4)*0.62, ...
     sprintf('원점에서 잰 각도가\n%.0f^{\\circ} 안쪽이라야\n오버슈트가 작다', rad2deg(th)), ...
     'FontSize', 11, 'Color', [0.15 0.45 0.2], 'HorizontalAlignment','right');
% 각도를 눈으로 보이게 표시
ra = 0.75*sig;
aa = linspace(pi, pi-th, 40);
plot(ra*cos(aa), ra*sin(aa), '-', 'Color', [0.15 0.45 0.2], ...
     'LineWidth', 1.6, 'HandleVisibility','off');
text(-ra*1.18, ra*0.30, sprintf('%.0f^{\\circ}', rad2deg(th)), ...
     'FontSize', 12, 'Color', [0.15 0.45 0.2], 'FontWeight','bold');

xlabel('실수부  \sigma'); ylabel('허수부  j\omega');
title(sprintf('사양 = s 평면의 영역   (오버슈트 %.0f %% 이하, 정착시간 %.0f s 이하)', ...
      P_OS, ts), 'FontSize', 12);
legend('Location','southwest');
end
