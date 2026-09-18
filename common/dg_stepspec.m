function dg_stepspec(zeta, wn)
%DG_STEPSPEC  계단응답 위에 성능 사양 네 가지를 표시한 그림
%
%   dg_stepspec()            보기 좋은 기본값 (zeta = 0.4, wn = 2)
%   dg_stepspec(zeta, wn)    원하는 값으로
%
%   이 그림 한 장이 4주차의 절반입니다.
%   말로만 하면 "오버슈트", "정착시간" 이 헷갈리는데, 그림에 표시해 두면
%   각각이 응답의 **어느 부분**을 가리키는지 한눈에 보입니다.
%
%   표시하는 네 가지
%     - 상승시간 $t_r$   최종값의 10 %에서 90 %까지 걸리는 시간
%     - 첨두시간 $T_p$   가장 높이 올라간 시각
%     - 오버슈트 $\%OS$  최종값을 몇 % 넘어섰는가
%     - 정착시간 $t_s$   $\pm 2\%$ 띠 안에 들어와 다시 안 나가는 시각
%
%   예제
%     dg_stepspec(0.4, 2);
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(zeta), zeta = 0.4; end
if nargin < 2 || isempty(wn),   wn   = 2;   end

s = tf('s');
G = wn^2/(s^2 + 2*zeta*wn*s + wn^2);
info0 = stepinfo(G);
t = linspace(0, 1.35*info0.SettlingTime, 2000)';
y = step(G, t);
info = stepinfo(G);

figure('Color','w','Position',[80 80 900 520]);
hold on; grid on;

% 2 % 띠
fill([t(1) t(end) t(end) t(1)], [0.98 0.98 1.02 1.02], [0.92 0.92 0.92], ...
     'EdgeColor','none', 'HandleVisibility','off');

plot(t, y, 'LineWidth', 2.5, 'Color', [0.1 0.35 0.7]);
yline(1, 'k--', 'LineWidth', 1.2);

ymax = 1 + info.Overshoot/100;

% 첨두점
plot(info.PeakTime, ymax, 'o', 'MarkerSize', 9, 'MarkerFaceColor', [0.85 0.2 0.15], ...
     'MarkerEdgeColor', 'k');
plot([info.PeakTime info.PeakTime], [0 ymax], ':', 'Color', [0.85 0.2 0.15], 'LineWidth', 1.4);

% 오버슈트 표시 (세로 화살표)
xa = info.PeakTime + 0.35;
plot([xa xa], [1 ymax], '-', 'Color', [0.85 0.2 0.15], 'LineWidth', 1.8);
plot(xa, ymax, 'v', 'MarkerSize', 6, 'MarkerFaceColor', [0.85 0.2 0.15], ...
     'MarkerEdgeColor', [0.85 0.2 0.15]);
text(xa + 0.18, (1+ymax)/2, sprintf('%%OS = %.1f %%', info.Overshoot), ...
     'FontSize', 12, 'Color', [0.85 0.2 0.15], 'FontWeight','bold');

% 상승시간
t10 = interp1(y(1:round(end/3)), t(1:round(end/3)), 0.1, 'linear');
t90 = interp1(y(1:round(end/3)), t(1:round(end/3)), 0.9, 'linear');
plot([t10 t90], [0.1 0.1], '-', 'Color', [0.15 0.55 0.25], 'LineWidth', 2.2);
plot([t10 t10], [0 0.15], '-', 'Color', [0.15 0.55 0.25], 'LineWidth', 1.2);
plot([t90 t90], [0 0.15], '-', 'Color', [0.15 0.55 0.25], 'LineWidth', 1.2);
text(t90 + 0.08, 0.10, sprintf('  t_r = %.2f s  (10 %% \\rightarrow 90 %%)', t90-t10), ...
     'FontSize', 12, 'Color', [0.15 0.55 0.25], 'FontWeight','bold', ...
     'HorizontalAlignment','left', 'VerticalAlignment','middle');

% 첨두시간
plot([0 info.PeakTime], [-0.08 -0.08], '-', 'Color', [0.85 0.2 0.15], 'LineWidth', 1.8);
text(info.PeakTime + 0.08, -0.08, sprintf('  T_p = %.2f s', info.PeakTime), ...
     'FontSize', 12, 'Color', [0.85 0.2 0.15], 'FontWeight','bold', ...
     'HorizontalAlignment','left', 'VerticalAlignment','middle');

% 정착시간
plot([info.SettlingTime info.SettlingTime], [0 1.02], ':', ...
     'Color', [0.35 0.2 0.6], 'LineWidth', 1.8);
plot([0 info.SettlingTime], [-0.22 -0.22], '-', 'Color', [0.35 0.2 0.6], 'LineWidth', 1.8);
text(info.SettlingTime + 0.08, -0.22, sprintf('  t_s = %.2f s', info.SettlingTime), ...
     'FontSize', 12, 'Color', [0.35 0.2 0.6], 'FontWeight','bold', ...
     'HorizontalAlignment','left', 'VerticalAlignment','middle');
text(t(end)*0.99, 1.06, '\pm 2 % 띠', 'FontSize', 11, 'Color', [0.45 0.45 0.45], ...
     'HorizontalAlignment','right');

xlabel('시간 [s]'); ylabel('출력');
ylim([-0.38 ymax + 0.25]); xlim([0 t(end)*1.32]);
title(sprintf('성능 사양 네 가지  (\\zeta = %.2f, \\omega_n = %.1f)', zeta, wn), ...
      'FontSize', 13);
legend({'출력 y(t)', '목표값'}, 'Location', 'southeast');
end
