function dg_sine_io(G, w)
%DG_SINE_IO  "사인을 넣으면 사인이 나온다" 를 한 장으로 보여 준다
%
%   dg_sine_io()            기본 예제 G = 1/(s+1), w = 1 rad/s
%   dg_sine_io(G, w)        원하는 시스템과 주파수로
%
%   왜 이 그림이 필요한가
%     주파수응답을 처음 배울 때 학생이 가장 안 믿는 것이 이 사실입니다.
%
%       선형 시불변 시스템에 사인을 넣으면
%       **같은 주파수의 사인**이 나온다. 달라지는 것은 크기와 위상뿐이다.
%
%     보드 선도는 이 "크기비" 와 "위상차" 를 주파수마다 모아 놓은 것에 지나지
%     않습니다. 그러니 이 그림 하나가 9주차 전체의 출발점입니다.
%
%   그림에 나오는 것
%     위   - 입력 사인과 출력 사인을 같은 축에 겹쳐 그린다
%     아래 - 크기비 |G(jw)| 와 위상차 angle(G(jw)) 를 화살표로 표시
%
%   See also DG_MARGIN, BODE
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(G), G = tf(1, [1 1]); end
if nargin < 2 || isempty(w), w = 1;            end

%% 크기비와 위상차 (이것이 곧 주파수응답)
Gjw   = freqresp(G, w);
mag   = abs(Gjw);
phdeg = rad2deg(angle(Gjw));
tlag  = -deg2rad(phdeg)/w;          % 위상지연을 시간지연으로 환산 [s]

%% 정상상태 구간만 본다
Tper = 2*pi/w;
t    = linspace(0, 3*Tper, 900)';
u    = sin(w*t);
y    = mag*sin(w*t + deg2rad(phdeg));

ax = axes(figure('Color','w','Position',[100 100 760 420]));
hold(ax, 'on'); grid(ax, 'on');

plot(t, u, 'LineWidth', 2.2, 'Color', [0.15 0.35 0.75]);
plot(t, y, 'LineWidth', 2.2, 'Color', [0.85 0.25 0.15]);
yline(0, 'k-');

%% 서로 대응하는 꼭짓점 한 쌍을 고른다
tu = Tper/4;                 % 입력이 처음 꼭짓점에 닿는 시각
tp = tu + tlag;              % 출력의 대응하는 꼭짓점 (위상지연만큼 늦다)

%% 크기비를 세로 막대로
plot([tp tp], [0 mag], '-', 'Color', [0.85 0.25 0.15], 'LineWidth', 2.4);
plot(tp, mag, 'o', 'MarkerSize', 8, 'LineWidth', 2, ...
     'MarkerEdgeColor', [0.85 0.25 0.15]);
plot([tu tu], [0 1], '-', 'Color', [0.15 0.35 0.75], 'LineWidth', 2.4);
text(tp + 0.30*Tper, 0.98, sprintf('크기비 |G| = %.3f', mag), ...
     'FontSize', 11, 'FontWeight','bold', 'Color', [0.85 0.25 0.15], ...
     'HorizontalAlignment','left');

%% 위상차를 시간지연으로
yb = 1.28;
plot([tu tp], [yb yb], 'k-', 'LineWidth', 1.4);
plot([tu tu], [yb-0.08 yb+0.08], 'k-', 'LineWidth', 1.4);
plot([tp tp], [yb-0.08 yb+0.08], 'k-', 'LineWidth', 1.4);
text(tp + 0.06*Tper, yb, sprintf('%.1f도 늦는다  (= %.3f 초)', phdeg, tlag), ...
     'HorizontalAlignment','left', 'FontSize', 11, 'FontWeight','bold');

xlabel('시간 [s]'); ylabel('신호');
ylim([-1.35 1.75]);
legend({'입력  sin(\omega t)', '출력'}, 'Location','southeast');
title(sprintf('사인을 넣으면 사인이 나온다  (\\omega = %.3g rad/s)', w), ...
      'FontSize', 12, 'FontWeight', 'bold');
subtitle('달라지는 것은 크기와 위상뿐. 이 둘을 주파수마다 모으면 보드 선도가 된다', ...
         'FontSize', 10, 'Color', [0.45 0.45 0.45]);
end
