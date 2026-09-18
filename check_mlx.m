function rep = check_mlx(mlxPath, verbose)
%CHECK_MLX  다 만든 .mlx 를 열어 깨진 수식과 서식이 없는지 검사한다
%
%   rep = check_mlx('W07_LectureNote.mlx')
%   rep = check_mlx(path, false)          % 조용히
%
%   왜 필요한가
%     mlx_from_script 는 만드는 **과정**에서 검사합니다.
%     이 함수는 다 만들어진 **결과물**을 다시 열어 봅니다.
%     Live Editor 에서 사람이 손으로 고친 뒤에도 쓸 수 있습니다.
%
%   무엇을 보는가
%     .mlx 는 사실 zip 파일입니다. 안에 matlab/document.xml 이 들어 있고
%     거기에 본문 글자와 수식이 따로 담겨 있습니다.
%     이 함수는 그 XML 을 풀어서 **본문 글자 안에 남아 있으면 안 되는 것**을 찾습니다.
%
%   검사 항목
%     1) 본문에 남은 `$`        — 수식이 글자로 남았다는 뜻
%     2) 본문에 남은 `**`, 백틱 — 굵게/코드 표시가 글자로 남았다
%     3) 본문에 남은 역슬래시 명령 (\frac 등) — 수식 밖으로 새어 나왔다
%     4) 수식 안의 미지원 LaTeX 명령 (\dfrac, \iff, \dots 등)
%     5) 제어문자 (sed 로 잘못 고쳤을 때 생긴다)
%     6) 절 구분자 개수 — 0 이면 Ctrl+Enter 절 실행이 안 된다
%
%   출력  rep - 구조체
%     rep.ok        문제가 없으면 true
%     rep.nIssue    문제 개수
%     rep.msg       문제 설명 (문자열 배열)
%     rep.nSection  절 개수
%     rep.nEq       수식 개수
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 2 || isempty(verbose), verbose = true; end

msg = string.empty;
[~, base, ext] = fileparts(mlxPath);
shortName = [base ext];

if ~isfile(mlxPath)
    rep = struct('ok', false, 'nIssue', 1, 'msg', "파일이 없습니다", ...
                 'nSection', 0, 'nEq', 0);
    if verbose, fprintf('  [!] %s : 파일이 없습니다\n', shortName); end
    return
end

% ---- .mlx (zip) 풀어서 document.xml 읽기 -------------------------
tmp = tempname;
mkdir(tmp);
cleaner = onCleanup(@() rmdir(tmp, 's'));
try
    unzip(mlxPath, tmp);
catch
    rep = struct('ok', false, 'nIssue', 1, 'msg', "zip 으로 열리지 않습니다", ...
                 'nSection', 0, 'nEq', 0);
    if verbose, fprintf('  [!] %s : zip 으로 열리지 않습니다\n', shortName); end
    return
end

docFile = fullfile(tmp, 'matlab', 'document.xml');
if ~isfile(docFile)
    rep = struct('ok', false, 'nIssue', 1, 'msg', "document.xml 이 없습니다", ...
                 'nSection', 0, 'nEq', 0);
    if verbose, fprintf('  [!] %s : document.xml 이 없습니다\n', shortName); end
    return
end

fid = fopen(docFile, 'r', 'n', 'UTF-8');
xml = fread(fid, '*char')';
fclose(fid);

% ---- 절 구분자와 수식 개수 --------------------------------------
nSection = numel(strfind(xml, '<w:sectPr/>'));

% [중요] .mlx 는 수식을 **두 가지 형식**으로 저장합니다.
%
%   (가) 갓 만들었을 때  : <w:t><![CDATA[\zeta]]></w:t>
%   (나) Live Editor 를 거친 뒤 : <w:t>\zeta</w:t>      (CDATA 가 사라진다)
%
% 예전에는 (가) 만 보고 있어서, 왕복을 거친 파일에서는 수식 280 개 중
% 13 개만 검사되고 나머지는 "본문에 LaTeX 가 새어 나옴" 으로 오탐이 났습니다.
% 그래서 **equation 블록 자체를 통째로 떼어 내는** 방식으로 바꿉니다.
eqBlk = regexp(xml, '<w:customXml w:element="equation".*?</w:customXml>', ...
               'match', 'dotall');
eqs = string.empty;
for i = 1:numel(eqBlk)
    tk = regexp(eqBlk{i}, '<w:t[^>]*>(.*?)</w:t>', 'tokens', 'dotall');
    if isempty(tk), continue, end
    s = strjoin(cellfun(@(c) c{1}, tk, 'UniformOutput', false), '');
    s = regexprep(s, '^<!\[CDATA\[', '');     % (가) 형식이면 껍데기를 벗긴다
    s = regexprep(s, '\]\]>$', '');
    eqs(end+1) = string(s); %#ok<AGROW>
end
nEq = numel(eqs);

% ---- 본문 글자만 뽑기 -------------------------------------------
% 수식 블록과 코드 블록(CDATA)을 먼저 지우고, 남은 <w:t> 내용만 모은다
xmlNoEq = regexprep(xml, '<w:customXml w:element="equation".*?</w:customXml>', '', 'dotall');
xmlNoEq = regexprep(xmlNoEq, '<!\[CDATA\[.*?\]\]>', '');
tTok    = regexp(xmlNoEq, '<w:t[^>]*>(.*?)</w:t>', 'tokens');
body    = string(cellfun(@(c) c{1}, tTok, 'UniformOutput', false));
bodyAll = strjoin(body, ' ');

% XML 이스케이프를 되돌린다
bodyAll = replace(bodyAll, "&lt;",  "<");
bodyAll = replace(bodyAll, "&gt;",  ">");
bodyAll = replace(bodyAll, "&amp;", "&");

% ---- 1) 본문에 남은 $ --------------------------------------------
if contains(bodyAll, "$")
    bad = local_context(bodyAll, "$", 40);
    for i = 1:numel(bad)
        msg(end+1) = "수식이 글자로 남음 : ..." + bad(i) + "..."; %#ok<AGROW>
    end
end

% ---- 2) 본문에 남은 ** 또는 백틱 ---------------------------------
if contains(bodyAll, "**")
    bad = local_context(bodyAll, "**", 40);
    for i = 1:numel(bad)
        msg(end+1) = "굵게 표시가 글자로 남음 : ..." + bad(i) + "..."; %#ok<AGROW>
    end
end
if contains(bodyAll, "`")
    bad = local_context(bodyAll, "`", 40);
    for i = 1:numel(bad)
        msg(end+1) = "코드 표시가 글자로 남음 : ..." + bad(i) + "..."; %#ok<AGROW>
    end
end

% ---- 3) 본문에 새어 나온 LaTeX 명령 ------------------------------
lat = regexp(bodyAll, '\\[a-zA-Z]{2,}', 'match');
if ~isempty(lat)
    u = unique(string(lat));
    msg(end+1) = "본문에 LaTeX 명령이 새어 나옴 : " + strjoin(u, ", "); %#ok<AGROW>
end

% ---- 4) 수식 안의 미지원 명령 ------------------------------------
% 목록은 mlx_from_script 와 똑같은 것을 씁니다 (common/latex_ok_commands.m).
% 두 군데에 따로 적어 두면 언젠가 어긋나기 때문입니다.
okCmd = string(latex_ok_commands());

badCmd = string.empty;
for i = 1:nEq
    cmds = regexp(eqs(i), '\\([a-zA-Z]+|.)', 'tokens');
    for c = 1:numel(cmds)
        nm = string(cmds{c}{1});
        if ~any(nm == okCmd)
            badCmd(end+1) = nm; %#ok<AGROW>
        end
    end
end
if ~isempty(badCmd)
    msg(end+1) = "수식 안의 미지원 LaTeX 명령 : " + ...
                 strjoin("\" + unique(badCmd), ", "); %#ok<AGROW>
end

% ---- 4-1) 수식 안의 잘못된 이스케이프 ------------------------------
% \\zeta 처럼 백슬래시를 두 번 쓰면 Live Editor 가 "줄바꿈 + zeta" 로 읽어
% 화면에 \zeta 가 글자로 남습니다. 원본 .m 을 만들 때 sprintf 감각으로
% 백슬래시를 이스케이프하다 생기는 실수입니다.
%
% 행렬 안의 줄바꿈 \\ 는 정상이므로, **뒤에 영문자나 % 가 오는 경우만** 잡습니다.
esc = string.empty;
for i = 1:nEq
    m = regexp(eqs(i), '\\\\[a-zA-Z%]\w*', 'match');
    if ~isempty(m), esc = [esc, string(m)]; end %#ok<AGROW>
end
if ~isempty(esc)
    msg(end+1) = "수식의 백슬래시가 두 번 들어감 (화면에 글자로 남습니다) : " + ...
                 strjoin(unique(esc), ", "); %#ok<AGROW>
end

% ---- 4-2) 수식의 짝이 안 맞는 것 -----------------------------------
% 중괄호, \left\right, \begin\end 가 안 맞으면 수식 전체가 안 그려집니다.
for i = 1:nEq
    e = eqs(i);
    nOpen  = count(e, "{") - count(e, "\{");
    nClose = count(e, "}") - count(e, "\}");
    if nOpen ~= nClose
        msg(end+1) = "수식의 중괄호 짝이 안 맞음 : " + local_short(e); %#ok<AGROW>
    end
    % [주의] \rightarrow 와 \leftrightarrow 안에도 left/right 글자가 있습니다.
    %        뒤에 영문자가 오면 다른 명령이므로 세면 안 됩니다.
    nL = numel(regexp(e, '\\left(?![a-zA-Z])', 'match'));
    nR = numel(regexp(e, '\\right(?![a-zA-Z])', 'match'));
    if nL ~= nR
        msg(end+1) = "수식의 \left 와 \right 짝이 안 맞음 : " + local_short(e); %#ok<AGROW>
    end
    if count(e, "\begin") ~= count(e, "\end")
        msg(end+1) = "수식의 \begin 과 \end 짝이 안 맞음 : " + local_short(e); %#ok<AGROW>
    end
    if strlength(strtrim(e)) == 0
        msg(end+1) = "빈 수식이 있음 ($$ 사이가 비었습니다)"; %#ok<AGROW>
    end
    if contains(e, "$")
        msg(end+1) = "수식 안에 $ 가 또 있음 (구분자가 겹쳤습니다) : " + local_short(e); %#ok<AGROW>
    end
end

% ---- 4-3) 표의 칸 수가 줄마다 다른가 -------------------------------
% 한 줄만 칸 수가 다르면 표가 통째로 어그러집니다.
% 원본에서 셀 안의 수식에 | 가 들어갔을 때 주로 생깁니다.
tb0 = strfind(xml, '<w:tbl>');
tb1 = strfind(xml, '</w:tbl>');
nTable = numel(tb0);
for i = 1:min(numel(tb0), numel(tb1))
    seg  = xml(tb0(i):tb1(i)+7);
    rows = regexp(seg, '<w:tr>.*?</w:tr>', 'match');
    nc   = cellfun(@(r) numel(strfind(r, '<w:tc>')), rows);
    if numel(unique(nc)) > 1
        msg(end+1) = sprintf("표 %d 의 칸 수가 줄마다 다름 (%s) — 셀 안의 | 를 확인하십시오", ...
                             i, strjoin(string(nc), "/")); %#ok<AGROW>
    end
end

% ---- 5) 제어문자 -------------------------------------------------
cc = double(char(bodyAll));
if any(cc < 9 | cc == 11 | cc == 12)
    msg(end+1) = "본문에 제어문자가 섞여 있음 (sed 로 고치다 생긴 것일 수 있음)"; %#ok<AGROW>
end

% ---- 6) 절 구분자 ------------------------------------------------
if nSection == 0
    msg(end+1) = "절 구분자가 없음 — Live Editor 에서 Ctrl+Enter 절 실행이 안 됩니다"; %#ok<AGROW>
end

rep = struct('ok', isempty(msg), 'nIssue', numel(msg), 'msg', msg, ...
             'nSection', nSection, 'nEq', nEq, 'nTable', nTable);

if verbose
    if rep.ok
        fprintf('  [OK] %s : 절 %d, 수식 %d, 표 %d, 문제 없음\n', ...
                shortName, nSection, nEq, nTable);
    else
        fprintf('  [!] %s : 문제 %d 개 (절 %d, 수식 %d)\n', ...
                shortName, numel(msg), nSection, nEq);
        for i = 1:numel(msg)
            fprintf('        - %s\n', msg(i));
        end
    end
end
end

% ---------------------------------------------------------------
function s = local_short(e)
%LOCAL_SHORT  긴 수식을 메시지에 넣기 좋게 자른다
e = string(e);
if strlength(e) > 60
    s = extractBefore(e, 58) + "...";
else
    s = e;
end
end

% ---------------------------------------------------------------
function out = local_context(str, pat, span)
% 문제가 된 곳의 앞뒤를 잘라 보여 준다 (최대 3 군데)
idx = strfind(str, pat);
out = string.empty;
for i = 1:min(3, numel(idx))
    a = max(1, idx(i)-span);
    b = min(strlength(str), idx(i)+span);
    out(end+1) = extractBetween(str, a, b); %#ok<AGROW>
end
end
