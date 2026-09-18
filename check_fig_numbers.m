function rep = check_fig_numbers(only, verbose)
%CHECK_FIG_NUMBERS  강의노트 "그림 해석" 표의 숫자가 그림과 맞는지 대조한다
%
%   rep = check_fig_numbers()          전 주차
%   rep = check_fig_numbers('W04')     한 주차만
%   rep = check_fig_numbers('', false) 조용히
%
%   왜 필요한가
%     강의노트의 그림마다 "어디를 보면 무엇이 보이는가" 표가 붙어 있습니다.
%     그 표에는 "0.8 에서 멈춘다", "1.3 에 안착", "7.3 배" 같은 **숫자**가 들어갑니다.
%     그림을 고치거나 파라미터를 바꾸면 그림은 바뀌는데 표는 그대로 남습니다.
%     사람 눈으로는 1637 줄을 다 대조할 수 없으므로 이 함수가 대신 봅니다.
%
%   어떻게 확인하는가
%     1) make_figures 에서 그림 목록을 받아 **그림을 실제로 다시 그린다**
%     2) 그려진 figure 에서 숫자 증거를 전부 긁는다
%          - 모든 곡선의 XData / YData (최소·최대·처음·끝, 그리고 지나간 값 전체)
%          - 제목 · 축이름 · 범례 · 도화지 위 글자에 적힌 숫자
%     3) 해석 표의 숫자 하나하나가 그 증거로 설명되는지 본다
%
%   판정
%     [지지됨]   표의 숫자가 그림 데이터나 글자에서 발견된다
%     [확인필요] 발견되지 않는다. **틀렸다는 뜻은 아니고 사람이 봐야 한다는 뜻**
%
%   왜 "틀렸다" 가 아닌가
%     표에는 그림에서 직접 읽을 수 없는 숫자도 정당하게 들어갑니다.
%     예를 들어 "2주차에서 배운 것", "10 배로 줄어든다" 같은 것들입니다.
%     그래서 이 함수는 **후보를 좁혀 줄 뿐**이고 판단은 사람이 합니다.
%
%   출력  rep - 구조체
%     rep.nFig    검사한 그림 수
%     rep.nNum    대조한 숫자 개수
%     rep.nFlag   확인이 필요한 숫자 개수
%     rep.flag    표 (그림 이름, 주차, 숫자, 그 줄)
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(only),    only = '';    end
if nargin < 2 || isempty(verbose), verbose = true; end

here = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end

jobs = make_figures('--jobs');
jobName = string(cellfun(@(x) string(x), jobs(:,1)));

srcs = dir(fullfile(here, 'W*', '_src', '*LectureNote_src.m'));
nFig = 0; nNum = 0;
flagFig = string.empty; flagWk = string.empty;
flagVal = []; flagRow = string.empty;

for i = 1:numel(srcs)
    wk = string(srcs(i).name(1:3));
    if ~isempty(only) && ~contains(wk, only), continue; end
    blocks = local_blocks(fullfile(srcs(i).folder, srcs(i).name));

    for b = 1:numel(blocks)
        png = blocks(b).png;
        k = find(jobName == png, 1);
        if isempty(k)
            if verbose
                fprintf('  [!] %s : %s 는 make_figures 목록에 없습니다\n', wk, png);
            end
            continue
        end

        % ---- 그림을 실제로 다시 그려 숫자 증거를 긁는다
        close all force
        try
            dg_reset();
            jobs{k,2}();
            drawnow;
            ev = local_evidence(gcf);
        catch ME
            if verbose
                fprintf('  [!] %s : %s 를 그리다 실패 — %s\n', wk, png, ME.message);
            end
            continue
        end
        nFig = nFig + 1;

        for r = 1:numel(blocks(b).rows)
            row  = blocks(b).rows(r);
            vals = local_numbers(row);
            for v = vals(:).'
                nNum = nNum + 1;
                if ~local_supported(v, ev)
                    flagFig(end+1,1) = png;   flagWk(end+1,1) = wk;   %#ok<AGROW>
                    flagVal(end+1,1) = v;     flagRow(end+1,1) = row; %#ok<AGROW>
                end
            end
        end
    end
end
close all force

rep = struct('nFig', nFig, 'nNum', nNum, 'nFlag', numel(flagVal), ...
             'flag', table(flagWk, flagFig, flagVal, flagRow, ...
                    'VariableNames', {'주차','그림','숫자','표의_줄'}));

if verbose
    fprintf('\n=== 그림 해석 표의 숫자 대조 ===\n');
    fprintf('  그림 %d 개 · 숫자 %d 개 대조\n', nFig, nNum);
    fprintf('  그림에서 확인된 것    : %d\n', nNum - rep.nFlag);
    fprintf('  사람이 봐야 하는 것   : %d\n\n', rep.nFlag);
    if rep.nFlag > 0
        u = unique(flagFig, 'stable');
        for q = 1:numel(u)
            m = flagFig == u(q);
            fprintf('  [%s] %s — 숫자 %d 개\n', flagWk(find(m,1)), u(q), sum(m));
        end
    end
end
end

% ======================================================================
function B = local_blocks(path)
% 강의노트 원본에서 (그림 이름, 해석 표의 줄들) 을 뽑아낸다
L = strsplit(fileread(path), newline, 'CollapseDelimiters', false);
B = struct('png', {}, 'rows', {});
hit = find(~cellfun(@isempty, regexp(L, '!\[[^\]]*\]\([^)]+\.png\)', 'once')));
for k = hit(:).'
    tok = regexp(L{k}, '\(([^)]+\.png)\)', 'tokens', 'once');
    rows = string.empty;
    j = k + 1;
    while j <= numel(L)
        % 다음 절이나 다음 그림을 만나면 이 블록은 끝
        if ~isempty(regexp(L{j}, '^%%', 'once')), break; end
        if ~isempty(regexp(L{j}, '!\[[^\]]*\]\([^)]+\.png\)', 'once')), break; end
        if ~isempty(regexp(L{j}, '^%\s*\|', 'once'))
            r = string(L{j});
            % 표의 구분선(|---|---|) 과 머리글은 건너뛴다
            if isempty(regexp(r, '^%\s*\|[\s\-\|]+$', 'once')) && ...
               ~contains(r, '관찰 위치')
                rows(end+1,1) = r; %#ok<AGROW>
            end
        end
        j = j + 1;
    end
    B(end+1) = struct('png', string(tok{1}), 'rows', rows); %#ok<AGROW>
end
end

% ======================================================================
function ev = local_evidence(f)
% 그려진 figure 에서 숫자 증거를 전부 긁는다
ev = struct('pts', [], 'txt', []);
pts = []; txt = [];

ax = findobj(f, 'Type', 'axes');
for a = ax(:).'
    % --- 곡선·점·막대의 데이터
    for h = findobj(a, '-property', 'YData').'
        y = get(h, 'YData'); y = y(isfinite(y));
        x = [];
        if isprop(h, 'XData'), x = get(h, 'XData'); x = x(isfinite(x)); end
        if ~isempty(y)
            % 지나간 값 전체 + 특별히 중요한 자리(처음·끝·최대·최소)
            pts = [pts, y(:).', y(1), y(end), min(y), max(y)]; %#ok<AGROW>
        end
        if ~isempty(x)
            pts = [pts, x(1), x(end), min(x), max(x)]; %#ok<AGROW>
        end
    end
    % --- 축 눈금
    pts = [pts, get(a,'XTick'), get(a,'YTick')]; %#ok<AGROW>
    % --- 제목·축이름
    txt = [txt, local_str(get(a,'Title')), local_str(get(a,'XLabel')), ...
                local_str(get(a,'YLabel'))]; %#ok<AGROW>
end
% --- 도화지 위 글자 · 범례
%  [주의] String 은 문자열 하나일 수도 있고 여러 줄짜리 cell 일 수도 있다.
%         그대로 이어 붙이면 행/열이 어긋나 오류가 나므로 항상 행벡터로 편다.
for h = findobj(f, 'Type', 'text').'
    txt = [txt, local_flat(get(h,'String'))]; %#ok<AGROW>
end
for h = findobj(f, 'Type', 'legend').'
    txt = [txt, local_flat(get(h,'String'))]; %#ok<AGROW>
end
for h = findobj(f, '-property', 'DisplayName').'
    txt = [txt, local_flat(get(h, 'DisplayName'))]; %#ok<AGROW>
end

ev.pts = unique(pts(isfinite(pts)));
tn = [];
for s = txt(:).'
    tn = [tn, local_numbers(s).']; %#ok<AGROW>
end
ev.txt = unique(tn);
end

function s = local_str(h)
s = string.empty(1,0);
if ~isempty(h) && isprop(h,'String')
    s = local_flat(get(h,'String'));
end
end

function s = local_flat(v)
% String 속성이 무엇으로 오든 문자열 **행벡터**로 편다
s = string.empty(1,0);
if isempty(v), return; end
if iscell(v)
    v = v(~cellfun(@isempty, v));
    if isempty(v), return; end
    s = string(v(:)).';
elseif ischar(v)
    s = string(cellstr(v)).';        % 여러 줄짜리 char 행렬도 있다
else
    s = string(v(:)).';
end
end

% ======================================================================
function v = local_numbers(str)
% 문자열에서 숫자를 뽑는다. 첨자·차수처럼 숫자가 아닌 것은 최대한 걸러낸다
s = string(str);
s = regexprep(s, '`[^`]*`', ' ');            % `코드` 안은 명령 이름이다
s = regexprep(s, '[A-Za-z]_\{?\d+\}?', ' '); % x_1, p_{12} 같은 첨자
s = regexprep(s, '\^\{?-?\d+\}?', ' ');      % s^2, 10^{-3} 의 지수
s = regexprep(s, '\\\w+', ' ');              % \frac, \omega 같은 명령
s = regexprep(s, '\d+\s*주차', ' ');          % "4주차"
s = regexprep(s, '\d+\s*절', ' ');            % "3-1절"
m = regexp(s, '-?\d+\.?\d*', 'match');
v = str2double(m).';
v = v(isfinite(v));
end

% ======================================================================
function tf = local_supported(v, ev)
% 표의 숫자 v 가 그림의 증거로 설명되는가
tf = true;

% 0, 1, 2 같은 아주 작은 정수는 거의 언제나 나타난다. 판정에서 뺀다.
if abs(v) <= 2 && abs(v - round(v)) < 1e-9, return; end

tol = max(0.02 * abs(v), 1e-6);          % 상대 2 %

% 1) 그림 글자에 그대로 적혀 있는가
if any(abs(ev.txt - v) <= tol), return; end

% 2) 곡선이 그 값을 지나갔는가 (또는 축 눈금에 있는가)
if ~isempty(ev.pts) && any(abs(ev.pts - v) <= tol), return; end

% 3) 백분율로 적힌 것이 비율로 그려진 경우 (예 : 표 40 % <-> 그림 0.4)
if any(abs(ev.pts - v/100) <= max(0.02*abs(v/100), 1e-6)), return; end
if any(abs(ev.pts*100 - v) <= tol), return; end

tf = false;
end
