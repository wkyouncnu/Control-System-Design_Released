function dg_polemap()
%DG_POLEMAP  극점이 어디 있으면 응답이 어떤 모양인지 한 장으로 보여 준다
%
%   dg_polemap()
%
%   이 그림 한 장이 2주차와 4주차의 핵심입니다.
%   식을 외우는 것보다 이 그림을 머리에 넣어 두는 편이 훨씬 오래 갑니다.
%
%   읽는 법 두 가지
%     - **왼쪽으로 갈수록** 빨리 사라진다 (실수부가 감쇠 속도를 정한다)
%     - **위아래로 멀수록** 빨리 흔들린다 (허수부가 진동 주기를 정한다)
%
%   그리고 가장 중요한 것
%     - 극점이 **허수축 오른쪽**에 하나라도 있으면 발산한다
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

s = tf('s');

% 보여 줄 극점들 : [실수부, 허수부, 설명]
cases = { -0.4,  0.0, '느리게 사라짐',      [0.30 0.45 0.75]
          -2.0,  0.0, '빠르게 사라짐',      [0.15 0.35 0.85]
          -0.4,  2.0, '느리게 흔들리며 사라짐', [0.15 0.55 0.25]
          -2.0,  2.0, '빠르게 잦아듦',      [0.10 0.40 0.20]
           0.0,  2.0, '계속 흔들림',        [0.85 0.55 0.10]
           0.4,  2.0, '흔들리며 발산',      [0.85 0.20 0.15] };

figure('Color','w','Position',[50 50 1300 720]);
tl = tiledlayout(3, 4, 'TileSpacing','compact','Padding','compact');

% ---- 왼쪽 큰 칸 : s 평면 -----------------------------------------
axL = nexttile(tl, 1, [3 2]);
hold(axL,'on'); grid(axL,'on');
fill(axL, [0 4 4 0], [-4 -4 4 4], [1.0 0.90 0.88], 'EdgeColor','none');
text(axL, 2.0, 3.3, '이쪽에 있으면 발산', 'FontSize', 12, ...
     'Color', [0.75 0.15 0.10], 'FontWeight','bold', 'HorizontalAlignment','center');
text(axL, -2.2, 3.3, '이쪽에 있어야 안정', 'FontSize', 12, ...
     'Color', [0.15 0.45 0.20], 'FontWeight','bold', 'HorizontalAlignment','center');

for i = 1:size(cases,1)
    sr = cases{i,1}; si = cases{i,2}; col = cases{i,4};
    plot(axL, sr,  si, 'x', 'MarkerSize', 15, 'LineWidth', 3, 'Color', col);
    if si ~= 0
        plot(axL, sr, -si, 'x', 'MarkerSize', 15, 'LineWidth', 3, 'Color', col);
    end
    text(axL, sr, si+0.42, sprintf('%d', i), 'FontSize', 13, 'FontWeight','bold', ...
         'Color', col, 'HorizontalAlignment','center');
end

xline(axL, 0, 'k-', 'LineWidth', 2);
yline(axL, 0, 'k-', 'LineWidth', 1);
xlim(axL, [-4 4]); ylim(axL, [-4 4]);
xlabel(axL, '실수부  \sigma  (얼마나 빨리 사라지는가)');
ylabel(axL, '허수부  j\omega  (얼마나 빨리 흔들리는가)');
title(axL, 's 평면 — 극점의 위치', 'FontSize', 13);

% ---- 오른쪽 여섯 칸 : 각 극점의 시간응답 --------------------------
% 3 x 4 배치에서 오른쪽 두 열의 타일 번호
order = [3 4 7 8 11 12];
t = linspace(0, 12, 1500)';
for i = 1:6
    ax = nexttile(tl, order(i));
    local_draw(ax, cases{i,1}, cases{i,2}, i, cases{i,3}, cases{i,4}, t);
end
end

% ---------------------------------------------------------------
function local_draw(ax, sr, si, idx, name, col, t)
s = tf('s');
if si == 0
    G = -sr/(s - sr);                       % DC 이득 1 로 맞춘 1차
else
    wn2 = sr^2 + si^2;
    G = wn2/(s^2 - 2*sr*s + wn2);           % DC 이득 1 로 맞춘 2차
end
if sr > 0
    t = t(t <= 5);          % 발산하는 경우는 짧게 보아야 모양이 보인다
end
y = step(G, t);
plot(ax, t, y, 'LineWidth', 2.2, 'Color', col);
grid(ax,'on');
yline(ax, 0, 'k-');
xlabel(ax, '시간 [s]');
title(ax, sprintf('%d. %s', idx, name), 'FontSize', 11, 'Color', col);
xlim(ax, [0 t(end)]);
if sr > 0
    ylim(ax, [-1.2*max(abs(y)) 1.2*max(abs(y))]);
else
    ylim(ax, [-0.4 2.0]);
end
end
