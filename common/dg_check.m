function rep = dg_check(name, verbose)
%DG_CHECK  방금 그린 블록선도가 제대로 이어져 있는지 자동으로 검사한다
%
%   rep = dg_check()
%   rep = dg_check('그림 이름')
%   rep = dg_check('그림 이름', false)      % 조용히
%
%   왜 필요한가
%     블록선도를 코드로 그리면 좌표를 하나 잘못 적어도 그림은 그냥 그려집니다.
%     선이 블록에 안 닿아 허공에 떠 있거나, 블록을 뚫고 지나가거나,
%     블록끼리 겹쳐도 오류가 나지 않습니다. 눈으로 일일이 확인하기 어려우므로
%     이 함수가 대신 확인합니다.
%
%   검사 항목 다섯 가지
%     1) 끊긴 끝점   — 화살표의 시작점이나 끝점이 아무 블록에도 닿지 않는다
%     2) 관통        — 화살표가 블록 안쪽을 뚫고 지나간다
%     3) 겹친 블록   — 블록 두 개가 서로 포개진다
%     4) 외톨이 블록 — 들어오거나 나가는 선이 하나도 없다
%     5) 도화지 밖   — 좌표가 dg_new 로 정한 범위를 벗어난다
%
%   출력  rep - 구조체
%     rep.ok       문제가 하나도 없으면 true
%     rep.nIssue   문제 개수
%     rep.msg      문제 설명 (문자열 배열)
%
%   예제
%     dg_loop('closed');
%     rep = dg_check('폐루프');
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(name),    name = '(이름 없음)'; end
if nargin < 2 || isempty(verbose), verbose = true;       end

reg = getappdata(0, 'DG_REG');
msg = string.empty;

if isempty(reg) || (isempty(reg.boxes) && isempty(reg.arrows))
    rep = struct('ok', false, 'nIssue', 1, 'msg', "그린 것이 없습니다 (dg_new 를 먼저 부르십시오)");
    if verbose, fprintf('  [!] %s : 그린 것이 없습니다\n', name); end
    return
end

B    = reg.boxes;
A    = reg.arrows;
tol  = 0.12;                 % 이 정도 떨어진 것은 붙어 있다고 본다
W    = reg.W;  H = reg.H;

% 블록마다 "닿은 선이 있는가" 를 세어 둔다
touched = false(1, numel(B));

%% 1) 끊긴 끝점
for i = 1:numel(A)
    pts = A{i}.pts;
    ends = [pts(1,:); pts(end,:)];
    for e = 1:2
        q  = ends(e,:);
        hit = false;
        for b = 1:numel(B)
            if local_onBoundary(q, B{b}, tol)
                hit = true;  touched(b) = true;
            end
        end
        % 다른 화살표의 어느 점과 만나도 (분기점) 이어진 것으로 본다
        if ~hit
            for j = 1:numel(A)
                if j == i, continue; end
                if local_nearPolyline(q, A{j}.pts, tol), hit = true; break; end
            end
        end
        % 도화지 가장자리는 외부 단자(지령 입력, 출력 측정, 외란)로 본다
        edge = 1.05;
        if ~hit && (q(1) <= edge || q(1) >= W-edge || q(2) >= H-edge || q(2) <= edge)
            hit = true;
        end
        if ~hit
            side = "시작점"; if e == 2, side = "끝점"; end
            msg(end+1) = sprintf("끊긴 %s : 화살표 %d(%s) 의 (%.2f, %.2f) 가 아무 데도 닿지 않음", ...
                                 side, i, string(A{i}.label), q(1), q(2)); %#ok<AGROW>
        end
    end
end

%% 2) 관통 — 화살표 구간이 블록 안쪽을 지나가는가
for i = 1:numel(A)
    pts = A{i}.pts;
    for k = 1:size(pts,1)-1
        p1 = pts(k,:);  p2 = pts(k+1,:);
        for b = 1:numel(B)
            if local_crossesInside(p1, p2, B{b}, tol)
                msg(end+1) = sprintf("관통 : 화살표 %d(%s) 가 블록 '%s' 안쪽을 지나감", ...
                                     i, string(A{i}.label), string(B{b}.label)); %#ok<AGROW>
            end
        end
    end
end

%% 3) 겹친 블록
for a = 1:numel(B)
    for b = a+1:numel(B)
        if local_overlap(B{a}, B{b})
            msg(end+1) = sprintf("겹침 : 블록 '%s' 와 '%s' 가 포개져 있음", ...
                                 string(B{a}.label), string(B{b}.label)); %#ok<AGROW>
        end
    end
end

%% 4) 외톨이 블록
for b = 1:numel(B)
    if ~touched(b)
        msg(end+1) = sprintf("외톨이 : 블록 '%s' 에 닿은 선이 없음", string(B{b}.label)); %#ok<AGROW>
    end
end

%% 5) 도화지 밖
for b = 1:numel(B)
    if B{b}.x - B{b}.w/2 < -0.05 || B{b}.x + B{b}.w/2 > W + 0.05 || ...
       B{b}.y - B{b}.h/2 < -0.05 || B{b}.y + B{b}.h/2 > H + 0.05
        msg(end+1) = sprintf("도화지 밖 : 블록 '%s'", string(B{b}.label)); %#ok<AGROW>
    end
end
for i = 1:numel(A)
    p = A{i}.pts;
    if any(p(:,1) < -0.05) || any(p(:,1) > W+0.05) || ...
       any(p(:,2) < -0.05) || any(p(:,2) > H+0.05)
        msg(end+1) = sprintf("도화지 밖 : 화살표 %d(%s)", i, string(A{i}.label)); %#ok<AGROW>
    end
end

rep = struct('ok', isempty(msg), 'nIssue', numel(msg), 'msg', msg);

if verbose
    if rep.ok
        fprintf('  [OK] 다이어그램 %s : 블록 %d, 화살표 %d, 문제 없음\n', ...
                name, numel(B), numel(A));
    else
        fprintf('  [!] 다이어그램 %s : 문제 %d 개\n', name, numel(msg));
        for i = 1:numel(msg)
            fprintf('        - %s\n', msg(i));
        end
    end
end
end

% ---------------------------------------------------------------
function tf = local_onBoundary(q, b, tol)
% 점 q 가 블록 b 의 테두리에 (또는 아주 가까이) 있는가
hw = b.w/2;  hh = b.h/2;
dx = abs(q(1) - b.x);  dy = abs(q(2) - b.y);
if strcmp(b.kind, 'sum')
    r  = b.w/2;
    tf = abs(hypot(q(1)-b.x, q(2)-b.y) - r) < tol*1.6;
else
    inX = dx <= hw + tol;   inY = dy <= hh + tol;
    onX = abs(dx - hw) < tol;  onY = abs(dy - hh) < tol;
    tf  = (onX && inY) || (onY && inX);
end
end

% ---------------------------------------------------------------
function tf = local_nearPolyline(q, pts, tol)
tf = false;
for k = 1:size(pts,1)-1
    if local_distSeg(q, pts(k,:), pts(k+1,:)) < tol, tf = true; return; end
end
end

% ---------------------------------------------------------------
function d = local_distSeg(q, a, b)
v = b - a;  L2 = v*v';
if L2 < 1e-12, d = norm(q-a); return; end
t = max(0, min(1, ((q-a)*v')/L2));
d = norm(q - (a + t*v));
end

% ---------------------------------------------------------------
function tf = local_crossesInside(p1, p2, b, tol)
% 선분이 블록 안쪽(테두리에서 tol 만큼 들어간 영역)을 지나가는가
hw = b.w/2 - tol;  hh = b.h/2 - tol;
if hw <= 0 || hh <= 0, tf = false; return; end
n  = 40;
t  = linspace(0, 1, n)';
P  = p1 + t.*(p2 - p1);
in = abs(P(:,1) - b.x) < hw & abs(P(:,2) - b.y) < hh;
% 양 끝점은 포트에 붙어 있을 수 있으므로 제외
in([1 end]) = false;
tf = any(in);
end

% ---------------------------------------------------------------
function tf = local_overlap(a, b)
tf = abs(a.x - b.x) < (a.w + b.w)/2 - 0.02 && ...
     abs(a.y - b.y) < (a.h + b.h)/2 - 0.02;
end
