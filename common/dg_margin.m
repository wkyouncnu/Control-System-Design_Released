function [Gm, Pm] = dg_margin(L, ttl)
%DG_MARGIN  보드 선도 위에서 이득여유와 위상여유를 "어디를 읽는지" 로 보여 준다
%
%   dg_margin(L)
%   dg_margin(L, '제목')
%   [Gm, Pm] = dg_margin(...)
%
%   왜 직접 그리는가
%     MATLAB 의 `margin(L)` 도 여유를 표시해 주지만 영어이고, 무엇보다
%     **어느 주파수에서 무엇을 읽는지**가 학생에게 잘 안 보입니다.
%     이 함수는 읽는 자리를 한글로 찍어 줍니다.
%
%   읽는 순서 (이 순서를 그림에 그대로 적어 둡니다)
%     1) 아래 위상 그림에서 위상이 -180도가 되는 주파수를 찾는다  -> wcg
%     2) 그 주파수에서 위 크기 그림을 본다. 0 dB 까지 남은 거리가 **이득여유**
%     3) 위 크기 그림에서 0 dB 를 지나는 주파수를 찾는다          -> wcp
%     4) 그 주파수에서 아래 위상 그림을 본다. -180도까지 남은 각이 **위상여유**
%
%   입력
%     L   - 개루프 전달함수 (제어기까지 포함한 것)
%     ttl - 제목 (생략 가능)
%
%   출력
%     Gm  - 이득여유 (배율. dB 가 아님)
%     Pm  - 위상여유 [도]
%
%   See also MARGIN, DG_SINE_IO
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 2, ttl = ''; end

[Gm, Pm, wcg, wcp] = margin(L);

w  = logspace(-2, 2, 800);
[m, p] = bode(L, w);
mdb = 20*log10(squeeze(m));
pdg = squeeze(p);

fig = figure('Color','w','Position',[100 100 780 520]);
tl  = tiledlayout(fig, 2, 1, 'TileSpacing','compact');

%% 위 : 크기
ax1 = nexttile(tl);
semilogx(ax1, w, mdb, 'LineWidth', 2.2, 'Color', [0.15 0.35 0.75]);
hold(ax1,'on'); grid(ax1,'on');
yline(ax1, 0, 'k--', 'LineWidth', 1.4);
ylabel(ax1, '크기 [dB]');
title(ax1, '크기 — 0 dB 를 지나는 곳과, 위상이 -180도인 곳을 본다');

if isfinite(wcg)
    xline(ax1, wcg, ':', 'Color',[0.85 0.25 0.15], 'LineWidth', 1.6);
    gdb = -20*log10(Gm);
    plot(ax1, wcg, gdb, 'o', 'MarkerSize', 9, 'LineWidth', 2, ...
         'MarkerEdgeColor',[0.85 0.25 0.15]);
    plot(ax1, [wcg wcg], [gdb 0], '-', 'Color',[0.85 0.25 0.15], 'LineWidth', 3);
    text(ax1, wcg*1.35, gdb/2, sprintf('이득여유 %.1f dB', -gdb), ...
         'Color',[0.85 0.25 0.15], 'FontSize', 11, 'FontWeight','bold', ...
         'HorizontalAlignment','left');
end
if isfinite(wcp)
    xline(ax1, wcp, ':', 'Color',[0.10 0.55 0.25], 'LineWidth', 1.6);
    plot(ax1, wcp, 0, 'o', 'MarkerSize', 9, 'LineWidth', 2, ...
         'MarkerEdgeColor',[0.10 0.55 0.25]);
    text(ax1, wcp*0.9, 26, sprintf('여기서 0 dB (\\omega_{cp} = %.2f)', wcp), ...
         'Color',[0.10 0.55 0.25], 'FontSize', 10, 'HorizontalAlignment','right');
end
ylim(ax1, [-70 45]); xlim(ax1, [w(1) w(end)]);

%% 아래 : 위상
ax2 = nexttile(tl);
semilogx(ax2, w, pdg, 'LineWidth', 2.2, 'Color', [0.15 0.35 0.75]);
hold(ax2,'on'); grid(ax2,'on');
yline(ax2, -180, 'k--', 'LineWidth', 1.4);
xlabel(ax2, '주파수 [rad/s]'); ylabel(ax2, '위상 [도]');
title(ax2, '위상 — -180도 까지 얼마나 남았는가');

if isfinite(wcp)
    xline(ax2, wcp, ':', 'Color',[0.10 0.55 0.25], 'LineWidth', 1.6);
    ph = -180 + Pm;
    plot(ax2, wcp, ph, 'o', 'MarkerSize', 9, 'LineWidth', 2, ...
         'MarkerEdgeColor',[0.10 0.55 0.25]);
    plot(ax2, [wcp wcp], [-180 ph], '-', 'Color',[0.10 0.55 0.25], 'LineWidth', 3);
    text(ax2, wcp*0.9, (ph-180)/2, sprintf('위상여유 %.1f도', Pm), ...
         'Color',[0.10 0.55 0.25], 'FontSize', 11, 'FontWeight','bold', ...
         'HorizontalAlignment','right');
end
if isfinite(wcg)
    xline(ax2, wcg, ':', 'Color',[0.85 0.25 0.15], 'LineWidth', 1.6);
    text(ax2, wcg*1.3, -120, sprintf('여기서 -180도 (\\omega_{cg} = %.2f)', wcg), ...
         'Color',[0.85 0.25 0.15], 'FontSize', 10, 'HorizontalAlignment','left');
end
ylim(ax2, [-290 -60]); xlim(ax2, [w(1) w(end)]);

if isempty(ttl)
    ttl = sprintf('안정 여유 : 이득여유 %.1f dB, 위상여유 %.1f도', ...
                  20*log10(Gm), Pm);
end
title(tl, ttl, 'FontSize', 12, 'FontWeight','bold');
end
