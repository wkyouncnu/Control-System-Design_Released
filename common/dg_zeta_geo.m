function dg_zeta_geo(zeta, wn, ttl)
%DG_ZETA_GEO  2차 극점의 $s$ 평면 기하 — $\zeta$ 와 $\omega_n$ 이 어디인가
%
%   dg_zeta_geo()
%   dg_zeta_geo(zeta, wn)
%   dg_zeta_geo(zeta, wn, '제목')
%
%   왜 이 그림인가
%     2차 표준형의 두 숫자가 **극점 위치의 어디에 해당하는지**를 모르면
%     4주차의 사양 변환도, 6주차의 sgrid 도 외우기만 하게 됩니다.
%     그림 한 장이면 다시 외울 필요가 없습니다.
%
%   읽는 법 (이 그림에 전부 표시됩니다)
%
%     극점        s = -zeta*wn +- j*wn*sqrt(1-zeta^2)
%     wn          원점에서 극점까지의 **거리**
%     zeta        그 선이 음의 실축과 이루는 각 theta 의 **코사인**  (zeta = cos theta)
%     sigma       실수부의 크기 = zeta*wn      -> 얼마나 빨리 사그라드는가
%     wd          허수부         = wn*sqrt(1-zeta^2)  -> 얼마나 빨리 흔들리는가
%
%   그래서 이렇게 이어집니다.
%
%     정착시간  ts ~ 4/sigma        실수부만 정한다  (왼쪽으로 갈수록 빠르다)
%     오버슈트  %OS = f(zeta)       각도만 정한다    (원점에서 본 각이 좁을수록 얌전하다)
%
%   See also DG_POLEMAP, DG_REGION, SPEC2POLE
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(zeta), zeta = 0.5; end
if nargin < 2 || isempty(wn),   wn   = 1;   end
if nargin < 3 || isempty(ttl)
    ttl = sprintf('2차 극점의 기하 : \\zeta = %.2f, \\omega_n = %.2f', zeta, wn);
end

sg = zeta*wn;                     % 실수부의 크기
wd = wn*sqrt(1 - zeta^2);         % 허수부
th = acos(zeta);                  % 음의 실축과 이루는 각

ax = axes(figure('Color','w','Position',[80 80 760 620]));
hold(ax,'on'); axis(ax,'equal'); grid(ax,'on');

% 아래쪽에 **설명 전용 띠**를 두어 글자가 극점과 겹치지 않게 합니다.
R  = wn*1.45;
yb = -R*1.35;                     % 이 아래는 글자만 쓰는 자리
xlim([-R*1.18 R*0.50]); ylim([yb - R*0.55, R*1.15]);

% 축
plot([-R*1.18 R*0.50], [0 0], 'k-', 'LineWidth', 1);
plot([0 0], [-R*1.12 R*1.12], 'k-', 'LineWidth', 1);
text(R*0.44, -R*0.07, '실수부 \sigma', 'FontSize', 11);
text(R*0.03, R*1.08, '허수부 j\omega', 'FontSize', 11);

% 등 wn 원
tt = linspace(pi/2, 3*pi/2, 200);
plot(wn*cos(tt), wn*sin(tt), ':', 'Color', [0.55 0.55 0.55], 'LineWidth', 1.4);

% 원점에서 극점까지 (= wn)
plot([0 -sg], [0 wd], '-', 'Color', [0.15 0.35 0.75], 'LineWidth', 2.6);
% 실수부
plot([0 -sg], [0 0], '-', 'Color', [0.85 0.25 0.15], 'LineWidth', 2.6);
plot([-sg -sg], [0 wd], '-', 'Color', [0.10 0.55 0.25], 'LineWidth', 2.6);

% 극점
plot(-sg,  wd, 'x', 'MarkerSize', 16, 'LineWidth', 3.5, 'Color', [0.15 0.35 0.75]);
plot(-sg, -wd, 'x', 'MarkerSize', 16, 'LineWidth', 3.5, 'Color', [0.15 0.35 0.75]);

% 각도 호
ar = wn*0.34;
ta = linspace(pi - th, pi, 60);
plot(ar*cos(ta), ar*sin(ta), '-', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.6);
text(-ar*1.12, ar*0.30, '\theta', 'FontSize', 13, 'Color', [0.35 0.35 0.35]);

% 이름표 — 선 위에 겹치지 않게 바깥쪽으로 밀어 둡니다
text(-sg*0.42, wd*0.78, sprintf('\\omega_n = %.2f', wn), ...
     'Color', [0.15 0.35 0.75], 'FontSize', 12, 'FontWeight','bold', ...
     'HorizontalAlignment','left');
text(-sg*0.5, -R*0.12, sprintf('\\sigma = \\zeta\\omega_n = %.2f', sg), ...
     'Color', [0.85 0.25 0.15], 'FontSize', 12, 'FontWeight','bold', ...
     'HorizontalAlignment','center');
text(-sg - R*0.03, wd*0.5, sprintf('\\omega_d = %.2f', wd), ...
     'Color', [0.10 0.55 0.25], 'FontSize', 12, 'FontWeight','bold', ...
     'HorizontalAlignment','right');

% 아래쪽 설명 (극점보다 훨씬 아래, 전용 띠에)
xl = -R*1.12;
text(xl, yb,             sprintf('\\zeta = cos\\theta = %.2f   (\\theta = %.0f도)', ...
     zeta, rad2deg(th)), 'FontSize', 12, 'FontWeight','bold');
text(xl, yb - R*0.16, '각도가 좁을수록 얌전하다  \rightarrow  오버슈트는 \zeta 만 정한다', ...
     'FontSize', 10.5, 'Color', [0.35 0.35 0.35]);
text(xl, yb - R*0.30, '왼쪽으로 갈수록 빠르다  \rightarrow  정착시간은 \sigma 만 정한다', ...
     'FontSize', 10.5, 'Color', [0.35 0.35 0.35]);
text(xl, yb - R*0.45, sprintf('%%OS = %.1f %%,   t_s \\approx 4/\\sigma = %.2f s', ...
     100*exp(-zeta*pi/sqrt(1-zeta^2)), 4/sg), ...
     'FontSize', 11, 'Color', [0.20 0.20 0.20], 'FontWeight','bold');

xlabel('실수부'); ylabel('허수부');
title(ttl, 'FontSize', 12, 'FontWeight','bold');
end
