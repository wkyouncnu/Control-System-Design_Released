function report = mlx_from_script(srcPath, outPath)
%MLX_FROM_SCRIPT  .m 원본을 Live Script(.mlx) 로 정확하게 변환합니다.
%
%   report = MLX_FROM_SCRIPT(srcPath, outPath)
%
%   왜 이 함수를 쓰는가
%     MATLAB 기본 변환기(matlab.internal.liveeditor.openAndSave)는 한글 문서에서
%     내용을 조용히 빠뜨립니다. 확인된 증상은 두 가지입니다.
%       (1) %% 절 제목의 첫 글자가 한글이면 제목이 통째로 사라짐
%       (2) 여러 줄로 된 본문 문단이 통째로 사라지는 경우가 있음
%     오류 메시지 없이 없어지므로 알아채기 어렵습니다.
%     그래서 이 함수가 문서 본문을 직접 만들어 넣고, 끝에 누락 검사까지 합니다.
%
%   ── 원본 .m 작성 규칙 ────────────────────────────────────────────────
%
%   구조
%     %% 제목            첫 번째는 문서 제목, 이후는 절 제목
%     % 본문 텍스트       빈 % 줄이 문단을 나눔
%     코드                 코드가 시작되면 다음 %% 까지 전부 코드
%
%   글자 꾸미기 (본문 안에서)
%     $...$              인라인 수식 (LaTeX)      예:  $\zeta = 0.1$
%     $$...$$            독립 수식 (그 줄 전체)   예:  $$G(s) = \frac{1}{ms^2}$$
%     **굵게**            굵은 글씨
%     `코드`              고정폭 글씨 (명령 이름 등)
%
%   목록 (개조식으로 쓸 때)
%     % - 항목            글머리 기호 항목
%     % - 항목이 길면
%     %   이렇게 이어서 씀 (다음 줄을 들여쓰면 앞 항목에 이어붙음)
%
%   주의
%     - 본문에 곱셈 기호 * 를 그냥 쓰지 마십시오. 수식은 반드시 $...$ 안에.
%     - 꾸밈은 겹쳐 쓸 수 없습니다. 예를 들어 **굵게 안의 `코드`** 처럼 쓰면
%       안쪽 표시가 글자 그대로 남습니다. 하나만 쓰십시오.
%     - 누락 검사가 이런 경우를 잡아 주므로, 검사 결과를 꼭 확인하십시오.
%
%   출력
%     report.nTitle/.nHeading/.nText/.nBullet/.nEq/.nCode  요소 개수
%     report.missing                                        누락된 문장
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

%% 1단계 : 형식이 올바른 .mlx 껍데기 만들기
%  압축 구조와 메타데이터를 직접 만들지 않아도 되도록 기본 변환기를 한 번 씁니다.
matlab.internal.liveeditor.openAndSave(srcPath, outPath);

%% 2단계 : 원본을 직접 해석해 본문 XML 만들기
blocks = local_parse(srcPath);

%% 3단계 : 본문을 갈아 끼우고 다시 압축
tmp = tempname;  mkdir(tmp);
cleanup = onCleanup(@() rmdir(tmp, 's')); %#ok<NASGU>
unzip(outPath, tmp);

% 그림 블록이 있으면 media 폴더에 넣고 관계 파일에 등록합니다.
% 이렇게 해야 **파일을 열자마자 그림이 보입니다.** 실행할 필요가 없습니다.
imgRel  = local_embedImages(blocks, srcPath, tmp);
xmlStr  = local_buildXml(blocks, imgRel);

fid = fopen(fullfile(tmp,'matlab','document.xml'), 'w', 'n', 'UTF-8');
fwrite(fid, xmlStr, 'char');  fclose(fid);

outXml = fullfile(tmp,'matlab','output.xml');
if isfile(outXml)
    fid = fopen(outXml, 'w', 'n', 'UTF-8');
    fwrite(fid, ['<?xml version="1.0" encoding="UTF-8"?>' newline ...
        '<w:document xmlns:w="http://schemas.openxmlformats.org/' ...
        'wordprocessingml/2006/main"><w:body/></w:document>'], 'char');
    fclose(fid);
end

L = dir(fullfile(tmp,'**','*'));  L = L(~[L.isdir]);
rel = arrayfun(@(f) erase(fullfile(f.folder,f.name), [tmp filesep]), ...
               L, 'UniformOutput', false);
zipPath = [tempname '.zip'];
zip(zipPath, rel, tmp);
if isfile(outPath), delete(outPath); end
movefile(zipPath, outPath);

%% 4단계 : 누락 검사
report = local_verify(blocks, outPath);

end

% ======================================================================
function blocks = local_parse(srcPath)
%LOCAL_PARSE  .m 원본을 블록 목록으로 바꿉니다.

txt   = fileread(srcPath);
lines = regexp(txt, '\r\n|\r|\n', 'split');

blocks   = struct('style', {}, 'text', {});
para     = '';
bullet   = '';
codeBuf  = {};
tblBuf   = {};
codeMode = false;
isFirst  = true;

    function flushPara()
        if ~isempty(strtrim(para))
            blocks(end+1) = struct('style','text','text',strtrim(para)); %#ok<AGROW>
        end
        para = '';
    end
    function flushBullet()
        if ~isempty(strtrim(bullet))
            blocks(end+1) = struct('style','bullet','text',strtrim(bullet)); %#ok<AGROW>
        end
        bullet = '';
    end
    function flushTable()
        if ~isempty(tblBuf)
            blocks(end+1) = struct('style','table', ...
                'text', strjoin(tblBuf, char(10))); %#ok<AGROW>
        end
        tblBuf = {};
    end
    function flushCode()
        while ~isempty(codeBuf) && isempty(strtrim(codeBuf{end})), codeBuf(end) = []; end
        while ~isempty(codeBuf) && isempty(strtrim(codeBuf{1})),   codeBuf(1)   = []; end
        if ~isempty(codeBuf)
            blocks(end+1) = struct('style','code', ...
                'text', strjoin(codeBuf, newline)); %#ok<AGROW>
        end
        codeBuf = {};
    end

for i = 1:numel(lines)
    ln = lines{i};

    % ---- 절 제목 ----
    tokSec = regexp(ln, '^\s*%%(.*)$', 'tokens', 'once');
    if ~isempty(tokSec)
        flushBullet(); flushPara(); flushTable(); flushCode();
        titleTxt = strtrim(tokSec{1});
        if isFirst, sty = 'title'; isFirst = false; else, sty = 'heading'; end
        if ~isempty(titleTxt)
            blocks(end+1) = struct('style',sty,'text',titleTxt); %#ok<AGROW>
        end
        codeMode = false;
        continue
    end

    % ---- 그림 삽입 지시문 ----
    %   % ![캡션](파일이름.png)
    %   common/figures 폴더의 PNG 를 문서 안에 **직접 박아 넣습니다.**
    %   그래서 파일을 열자마자 그림이 보입니다 (실행할 필요 없음).
    tokImg = regexp(ln, '^\s*%\s*!\[([^\]]*)\]\(([^)]+)\)\s*$', 'tokens', 'once');
    if ~isempty(tokImg)
        flushBullet(); flushPara(); flushTable(); flushCode();
        blocks(end+1) = struct('style','image', ...
            'text', sprintf('%s|%s', strtrim(tokImg{2}), strtrim(tokImg{1}))); %#ok<AGROW>
        codeMode = false;
        continue
    end

    if ~codeMode
        tokCom = regexp(ln, '^\s*%(.*)$', 'tokens', 'once');
        if ~isempty(tokCom)
            raw  = tokCom{1};              % 들여쓰기 판단용 (자르지 않음)
            body = strtrim(raw);

            if isempty(body)
                flushBullet(); flushPara(); flushTable();
                continue
            end

            % ---- 표 ----
            %   | 머리1 | 머리2 |
            %   |---|---|
            %   | 값1  | 값2  |
            %   구분선(|---|)은 버리고 나머지 줄을 행으로 모읍니다.
            %   이 줄들을 문단에 섞으면 한 줄로 뭉개져 버리므로 따로 받습니다.
            %   [주의] 수식의 절댓값 기호와 헷갈리면 안 됩니다.
            %   "|G| = \frac{...}" 같은 줄도 | 로 시작하므로, 표로 보려면
            %   **| 로 시작하고 | 로 끝나며 | 가 셋 이상**이어야 합니다 (= 두 칸 이상).
            %   실제로 이 조건이 없어서 W09 숙제의 $$ 수식이 표로 잘못 잡혔습니다.
            if startsWith(body, '|') && endsWith(body, '|') && count(body, '|') >= 3
                flushBullet(); flushPara();
                if isempty(regexp(body, '^\|[\s:\-|]+\|\s*$', 'once'))
                    tblBuf{end+1} = body; %#ok<AGROW>
                end
                continue
            end
            flushTable();

            % 글머리 기호로 시작하는가
            tokBul = regexp(body, '^[-*]\s+(.*)$', 'tokens', 'once');
            if ~isempty(tokBul)
                flushBullet(); flushPara();
                bullet = strtrim(tokBul{1});
                continue
            end

            % 항목을 만들고 있는 중이고, 이 줄이 더 들여쓰기 되어 있으면 이어붙임
            if ~isempty(bullet) && ~isempty(regexp(raw, '^\s\s+\S', 'once'))
                bullet = [bullet ' ' body]; %#ok<AGROW>
                continue
            end

            flushBullet();
            if isempty(para), para = body; else, para = [para ' ' body]; end %#ok<AGROW>
            continue
        end

        if isempty(strtrim(ln))
            flushBullet(); flushPara(); flushTable();
            continue
        end
        flushBullet(); flushPara(); flushTable();
        codeMode = true;
    end

    codeBuf{end+1} = ln; %#ok<AGROW>
end

flushBullet(); flushPara(); flushTable(); flushCode();

end

% ======================================================================
function imgRel = local_embedImages(blocks, srcPath, tmp)
%LOCAL_EMBEDIMAGES  그림 블록의 PNG 를 .mlx 안에 넣고 관계를 등록합니다.
%
%   .mlx 는 zip 이고, 그림은 이렇게 들어갑니다.
%     1) media/imageN.png 로 파일을 복사
%     2) matlab/_rels/document.xml.rels 에 관계 한 줄 추가
%     3) document.xml 에 <w:customXml w:element="image"> 문단 삽입 (3단계는 호출자가)
%
%   이 방식이라야 **파일을 열자마자 그림이 보입니다.**
%   코드로 그리게만 해 두면 학생이 [모두 실행] 을 눌러야 보입니다.

imgRel = containers.Map('KeyType','char','ValueType','any');

idx = find(strcmp({blocks.style}, 'image'));
if isempty(idx), return; end

% 그림을 찾을 곳 : 원본 파일 옆, 그리고 common/figures
here    = fileparts(mfilename('fullpath'));
srcDir  = fileparts(srcPath);
figDirs = { fullfile(here, 'common', 'figures'), srcDir, ...
            fullfile(srcDir, '..', 'figures') };

mediaDir = fullfile(tmp, 'media');
if ~exist(mediaDir, 'dir'), mkdir(mediaDir); end

% 관계 파일이 없을 수도 있습니다 (수식도 그림도 없는 문서였다면).
% 그럴 때는 빈 관계 파일을 새로 만듭니다.
relDir  = fullfile(tmp, 'matlab', '_rels');
if ~exist(relDir, 'dir'), mkdir(relDir); end
relFile = fullfile(relDir, 'document.xml.rels');
if ~isfile(relFile)
    fid = fopen(relFile, 'w', 'n', 'UTF-8');
    fwrite(fid, ['<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>' newline ...
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' ...
        newline '</Relationships>'], 'char');
    fclose(fid);
end
fid = fopen(relFile, 'r', 'n', 'UTF-8');
relXml = fread(fid, '*char')';  fclose(fid);

% [Content_Types].xml 에 png 확장자가 등록돼 있어야 그림이 열립니다.
ctFile = fullfile(tmp, '[Content_Types].xml');
if isfile(ctFile)
    fid = fopen(ctFile, 'r', 'n', 'UTF-8');
    ct = fread(fid, '*char')';  fclose(fid);
    if ~contains(ct, 'Extension="png"')
        ct = strrep(ct, '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">', ...
            ['<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' newline ...
             '  <Default ContentType="image/png" Extension="png"/>']);
        fid = fopen(ctFile, 'w', 'n', 'UTF-8');
        fwrite(fid, ct, 'char');  fclose(fid);
    end
end

% 이미 쓰인 rId 중 가장 큰 번호를 찾습니다
used = regexp(relXml, 'Id="rId(\d+)"', 'tokens');
nextId = 1;
for i = 1:numel(used), nextId = max(nextId, str2double(used{i}{1}) + 1); end

% 이미 있는 image 번호
ex = dir(fullfile(mediaDir, 'image*.png'));
nextImg = numel(ex) + 1;

addRel = '';
for k = 1:numel(idx)
    parts = strsplit(blocks(idx(k)).text, '|');
    fname = parts{1};
    if isKey(imgRel, fname), continue; end

    srcImg = '';
    for d = 1:numel(figDirs)
        cand = fullfile(figDirs{d}, fname);
        if isfile(cand), srcImg = cand; break; end
    end
    if isempty(srcImg)
        warning('mlx_from_script:그림없음', '그림 파일을 찾을 수 없습니다: %s', fname);
        continue
    end

    tgtName = sprintf('image%d.png', nextImg);
    copyfile(srcImg, fullfile(mediaDir, tgtName));

    info = imfinfo(srcImg);
    W = info(1).Width;  H = info(1).Height;
    maxW = 640;                                  % 문서 폭에 맞춘 최대 가로 크기
    if W > maxW, H = round(H * maxW / W); W = maxW; end

    rid = sprintf('rId%d', nextId);
    addRel = [addRel sprintf(['  <Relationship Id="%s" Target="../media/%s" ' ...
        'Type="http://schemas.mathworks.com/matlab/code/2013/relationships/image"/>' newline], ...
        rid, tgtName)]; %#ok<AGROW>

    imgRel(fname) = struct('rid', rid, 'w', W, 'h', H);
    nextId  = nextId + 1;
    nextImg = nextImg + 1;
end

if ~isempty(addRel)
    relXml = strrep(relXml, '</Relationships>', [addRel '</Relationships>']);
    fid = fopen(relFile, 'w', 'n', 'UTF-8');
    fwrite(fid, relXml, 'char');  fclose(fid);
end
end

% ======================================================================
function xmlStr = local_buildXml(blocks, imgRel)
%LOCAL_BUILDXML  블록 목록을 Live Script 본문 XML 로 만듭니다.

if nargin < 2, imgRel = containers.Map('KeyType','char','ValueType','any'); end

% 섹션 구분자
%   Live Editor 에서 절 단위 실행(Ctrl+Enter)이 되려면 절 사이에
%   빈 문단 하나를 섹션 구분자로 넣어야 합니다.
%   이것이 없으면 문서 전체가 한 덩어리가 되어 절 실행이 안 됩니다.
SECT = '<w:p><w:pPr><w:sectPr/></w:pPr></w:p>';

parts = cell(1, numel(blocks));
for i = 1:numel(blocks)
    b = blocks(i);

    % 소제목마다 그 앞에 섹션 구분자를 넣습니다 (문서 제목 앞에는 넣지 않음)
    pre = '';
    if strcmp(b.style, 'heading')
        pre = SECT;
    end

    switch b.style
        case 'image'
            sp2   = strsplit(b.text, '|');
            fname = sp2{1};
            cap   = '';
            if numel(sp2) >= 2, cap = sp2{2}; end
            if isKey(imgRel, fname)
                r = imgRel(fname);
                imgXml = sprintf(['<w:p><w:pPr><w:pStyle w:val="text"/>' ...
                    '<w:jc w:val="center"/></w:pPr>' ...
                    '<w:customXml w:element="image"><w:customXmlPr>' ...
                    '<w:attr w:name="height" w:val="%d"/>' ...
                    '<w:attr w:name="width" w:val="%d"/>' ...
                    '<w:attr w:name="verticalAlign" w:val="baseline"/>' ...
                    '<w:attr w:name="altText" w:val="%s"/>' ...
                    '<w:attr w:name="relationshipId" w:val="%s"/>' ...
                    '</w:customXmlPr></w:customXml></w:p>'], ...
                    r.h, r.w, local_esc(cap), r.rid);
            else
                imgXml = sprintf(['<w:p><w:pPr><w:pStyle w:val="text"/></w:pPr>' ...
                    '<w:r><w:t>[그림을 찾을 수 없음: %s]</w:t></w:r></w:p>'], local_esc(fname));
            end
            capXml = '';
            if ~isempty(cap)
                capXml = sprintf(['<w:p><w:pPr><w:pStyle w:val="text"/>' ...
                    '<w:jc w:val="center"/></w:pPr>%s</w:p>'], local_runs(cap));
            end
            parts{i} = [pre imgXml capXml];

        case 'code'
            parts{i} = [pre sprintf(['<w:p><w:pPr><w:pStyle w:val="code"/></w:pPr>' ...
                '<w:r><w:t><![CDATA[%s]]></w:t></w:r></w:p>'], b.text)];

        case 'bullet'
            parts{i} = [pre sprintf(['<w:p><w:pPr><w:pStyle w:val="ListParagraph"/>' ...
                '<w:numPr><w:numId w:val="1"/></w:numPr></w:pPr>%s</w:p>'], ...
                local_runs(b.text))];

        case 'table'
            % 마크다운 표를 진짜 표(w:tbl)로 만듭니다.
            % 이렇게 하지 않으면 "| 항목 | Lead | Lag | |---|---|" 처럼
            % 한 줄로 뭉개져 버립니다 (실제로 그렇게 나오고 있었습니다).
            rows = strsplit(b.text, char(10));
            trXml = '';
            for r0 = 1:numel(rows)
                cells = local_cells(rows{r0});
                tcXml = '';
                for c0 = 1:numel(cells)
                    cellTxt = strtrim(cells{c0});
                    % 첫 줄은 머리글이므로 굵게
                    if r0 == 1 && ~isempty(cellTxt) && ~contains(cellTxt, '**')
                        cellTxt = ['**' cellTxt '**'];
                    end
                    tcXml = [tcXml sprintf(['<w:tc><w:tcPr><w:tcW w:w="0" w:type="auto"/>' ...
                        '</w:tcPr><w:p><w:pPr><w:pStyle w:val="text"/></w:pPr>%s</w:p>' ...
                        '</w:tc>'], local_runs(cellTxt))]; %#ok<AGROW>
                end
                trXml = [trXml '<w:tr>' tcXml '</w:tr>']; %#ok<AGROW>
            end
            parts{i} = [pre '<w:tbl><w:tblPr><w:tblW w:w="0" w:type="auto"/>' ...
                '<w:tblBorders>' ...
                '<w:top w:val="single" w:sz="4" w:color="BFBFBF"/>' ...
                '<w:left w:val="single" w:sz="4" w:color="BFBFBF"/>' ...
                '<w:bottom w:val="single" w:sz="4" w:color="BFBFBF"/>' ...
                '<w:right w:val="single" w:sz="4" w:color="BFBFBF"/>' ...
                '<w:insideH w:val="single" w:sz="4" w:color="BFBFBF"/>' ...
                '<w:insideV w:val="single" w:sz="4" w:color="BFBFBF"/>' ...
                '</w:tblBorders></w:tblPr>' trXml '</w:tbl>'];

        otherwise   % title / heading / text
            eqOnly = regexp(strtrim(b.text), '^\$\$(.+)\$\$$', 'tokens', 'once');
            if ~isempty(eqOnly) && strcmp(b.style,'text')
                % 독립 수식 문단
                parts{i} = [pre sprintf(['<w:p><w:pPr><w:pStyle w:val="text"/></w:pPr>' ...
                    '<w:customXml w:element="equation"><w:customXmlPr>' ...
                    '<w:attr w:name="displayStyle" w:val="true"/></w:customXmlPr>' ...
                    '<w:r><w:t><![CDATA[%s]]></w:t></w:r></w:customXml></w:p>'], ...
                    strtrim(eqOnly{1}))];
            else
                parts{i} = [pre sprintf('<w:p><w:pPr><w:pStyle w:val="%s"/></w:pPr>%s</w:p>', ...
                    b.style, local_runs(b.text))];
            end
    end
end

xmlStr = ['<?xml version="1.0" encoding="UTF-8"?>' newline ...
          '<w:document xmlns:w="http://schemas.openxmlformats.org/' ...
          'wordprocessingml/2006/main"><w:body>' strjoin(parts,'') ...
          '</w:body></w:document>'];
end

% ======================================================================
function xml = local_runs(txt)
%LOCAL_RUNS  한 문단 안의 꾸밈 표시를 XML 런으로 바꿉니다.
%   $...$ 수식, **...** 굵게, `...` 고정폭
%
%   수식을 가장 먼저 떼어냅니다.
%   그래야 **굵게 안의 $수식$** 처럼 겹쳐 써도 수식이 제대로 나옵니다.
%   (수식을 나중에 처리하면 굵게가 먼저 통째로 잡아먹어 $ 기호가 글자로 남습니다)

% 1단계 : 수식을 자리표시자로 바꿔 둔다
eqs = {};
[eqTok, eqSpl] = regexp(txt, '\$[^$]+\$', 'match', 'split');
buf = eqSpl{1};
for i = 1:numel(eqTok)
    eqs{end+1} = eqTok{i}(2:end-1); %#ok<AGROW>
    buf = [buf sprintf('\x01%d\x02', numel(eqs)) eqSpl{i+1}]; %#ok<AGROW>
end

% 2단계 : 남은 부분에서 링크·굵게·고정폭을 처리한다
%   링크 [보이는 글자](주소) 는 Live Editor 에서
%   <w:hyperlink w:docLocation="주소"> 로 저장됩니다 (CTMS 원본에서 확인한 형식).
%   관계 파일에 등록할 필요가 없어 주소를 그대로 넣으면 됩니다.
[mk, sp] = regexp(buf, '(\[[^\]]+\]\([^)\s]+\))|(\*\*[^*]+\*\*)|(`[^`]+`)', ...
                  'match', 'split');

xml = '';
for i = 1:numel(sp)
    if ~isempty(sp{i})
        xml = [xml local_plain(sp{i}, eqs, '')]; %#ok<AGROW>
    end
    if i <= numel(mk)
        m = mk{i};
        if startsWith(m, '[')
            lk = regexp(m, '^\[([^\]]+)\]\(([^)\s]+)\)$', 'tokens', 'once');
            xml = [xml sprintf('<w:hyperlink w:docLocation="%s">%s</w:hyperlink>', ...
                   local_esc(lk{2}), local_plain(lk{1}, eqs, ''))]; %#ok<AGROW>
        elseif startsWith(m, '**')
            xml = [xml local_plain(m(3:end-2), eqs, '<w:b/>')]; %#ok<AGROW>
        else
            xml = [xml local_plain(m(2:end-1), eqs, ...
                   '<w:rFonts w:cs="monospace"/>')]; %#ok<AGROW>
        end
    end
end
if isempty(xml)
    xml = '<w:r><w:t></w:t></w:r>';
end
end

% ======================================================================
function xml = local_plain(seg, eqs, rpr)
%LOCAL_PLAIN  자리표시자를 수식으로 되돌리며 런을 만듭니다.
%   rpr 이 비어 있지 않으면 글자 부분에 그 서식(굵게 등)을 입힙니다.
%   수식 자체에는 서식을 입히지 않습니다. 수식은 스스로 조판되기 때문입니다.

xml = '';
[tok, spl] = regexp(seg, '\x01(\d+)\x02', 'tokens', 'split');
for i = 1:numel(spl)
    if ~isempty(spl{i})
        if isempty(rpr)
            xml = [xml sprintf('<w:r><w:t>%s</w:t></w:r>', local_esc(spl{i}))]; %#ok<AGROW>
        else
            xml = [xml sprintf('<w:r><w:rPr>%s</w:rPr><w:t>%s</w:t></w:r>', ...
                   rpr, local_esc(spl{i}))]; %#ok<AGROW>
        end
    end
    if i <= numel(tok)
        k = str2double(tok{i}{1});
        xml = [xml sprintf(['<w:customXml w:element="equation"><w:customXmlPr>' ...
            '<w:attr w:name="displayStyle" w:val="false"/></w:customXmlPr>' ...
            '<w:r><w:t><![CDATA[%s]]></w:t></w:r></w:customXml>'], eqs{k})]; %#ok<AGROW>
    end
end
end

% ======================================================================
function cells = local_cells(row)
%LOCAL_CELLS  표의 한 줄을 칸으로 나눕니다.
%
%   **수식 안($...$)의 파이프로는 나누지 않습니다.**
%   노름이나 절댓값을 표에 쓰면 (예: $|G|$) 그냥 나누다가 칸이 어긋납니다.

row   = strtrim(row);
row   = regexprep(row, '^\||\|$', '');     % 양 끝의 파이프 제거
cells = {};
cur   = '';
inEq  = false;
for i = 1:numel(row)
    ch = row(i);
    if ch == '$'
        inEq = ~inEq;  cur(end+1) = ch; %#ok<AGROW>
    elseif ch == '|' && ~inEq
        cells{end+1} = cur; %#ok<AGROW>
        cur = '';
    else
        cur(end+1) = ch; %#ok<AGROW>
    end
end
cells{end+1} = cur;
end

% ======================================================================
function s = local_esc(s)
s = strrep(s, '&', '&amp;');
s = strrep(s, '<', '&lt;');
s = strrep(s, '>', '&gt;');
end

% ======================================================================
function report = local_verify(blocks, outPath)
%LOCAL_VERIFY  원본의 모든 문장이 결과물에 들어갔는지 확인합니다.

tmp = tempname; mkdir(tmp);
cleanup = onCleanup(@() rmdir(tmp,'s')); %#ok<NASGU>
unzip(outPath, tmp);
fid = fopen(fullfile(tmp,'matlab','document.xml'), 'r', 'n', 'UTF-8');
doc = fread(fid,'*char')'; fclose(fid);

% 검사용으로 태그를 걷어내 순수 글자만 남깁니다.
% 꾸밈이 들어간 문장은 XML 에서 여러 런으로 쪼개지므로, 태그를 지우지 않으면
% 멀쩡한 문장도 누락으로 잘못 잡힙니다.
plain = strrep(doc, '<![CDATA[', '');
plain = strrep(plain, ']]>', '');
plain = regexprep(plain, '<[^>]*>', '');
plain = strrep(plain, '&amp;', '&');
plain = strrep(plain, '&lt;',  '<');
plain = strrep(plain, '&gt;',  '>');
plain = regexprep(plain, '\s+', ' ');

% ---- LaTeX 명령 점검 ----
%   MATLAB Live Editor 는 LaTeX 의 일부만 지원합니다.
%   예를 들어 \dfrac 은 지원하지 않아서 글자 그대로 남아 버립니다.
%   오류 없이 이상하게 렌더링되므로 미리 걸러 냅니다.
okCmd = { ...
  'frac','sqrt','sum','prod','int','lim','left','right','begin','end','array', ...
  'cdot','times','div','pm','mp','approx','neq','ne','leq','geq','le','ge', ...
  'equiv','propto','sim','simeq','cong','ll','gg','ldots', ...
  'ldots','cdots','vdots','ddots','quad','qquad',',',';','!',' ', ...
  'mathbf','mathrm','mathcal','mathbb','textrm','text','rm','bf','it', ...
  'alpha','beta','gamma','delta','epsilon','varepsilon','zeta','eta','theta', ...
  'vartheta','iota','kappa','lambda','mu','nu','xi','pi','rho','sigma','tau', ...
  'upsilon','phi','varphi','chi','psi','omega', ...
  'Gamma','Delta','Theta','Lambda','Xi','Pi','Sigma','Upsilon','Phi','Psi','Omega', ...
  'dot','ddot','hat','bar','tilde','vec','overline','underline', ...
  'infty','partial','nabla','forall','exists','in','notin','subset','cup','cap', ...
  'to','rightarrow','leftarrow','Rightarrow','Leftarrow','Longrightarrow', ...
  'Longleftarrow','leftrightarrow','mapsto', ...
  'sin','cos','tan','sec','csc','cot','arcsin','arccos','arctan', ...
  'sinh','cosh','tanh','log','ln','exp','max','min','deg','circ', ...
  'angle','perp','parallel','prime','ast','star','bullet','%','&','#','_','{','}','$' };

allEq = {};
for i = 1:numel(blocks)
    if any(strcmp(blocks(i).style, {'code','image'})), continue; end
    e = regexp(blocks(i).text, '\$\$?([^$]+)\$\$?', 'tokens');
    for q = 1:numel(e), allEq{end+1} = e{q}{1}; end %#ok<AGROW>
end
cmds = regexp(strjoin(allEq, ' '), '\\([a-zA-Z]+)', 'tokens');
cmds = unique(cellfun(@(c) c{1}, cmds, 'UniformOutput', false));
report.latexCmds = cmds;
report.latexBad  = cmds(~ismember(cmds, okCmd));

st = {blocks.style};
report.nTitle   = sum(strcmp(st,'title'));
report.nHeading = sum(strcmp(st,'heading'));
report.nText    = sum(strcmp(st,'text'));
report.nBullet  = sum(strcmp(st,'bullet'));
report.nCode    = sum(strcmp(st,"code"));
report.nImage   = sum(strcmp(st,"image"));
report.nEq      = numel(strfind(doc, 'w:element="equation"'));
report.missing  = {};

for i = 1:numel(blocks)
    if any(strcmp(blocks(i).style, {'code','image'})), continue; end

    % 표는 셀마다 문단이 나뉘므로 행 전체가 이어져 있지 않습니다.
    % 그래서 셀 하나하나가 들어갔는지로 확인합니다.
    if strcmp(blocks(i).style, 'table')
        rows = strsplit(blocks(i).text, char(10));
        for r0 = 1:numel(rows)
            cs = local_cells(rows{r0});
            for c0 = 1:numel(cs)
                cp = strtrim(cs{c0});
                cp = regexprep(cp, '\[([^\]]+)\]\([^)]+\)', '$1');  % 링크는 보이는 글자만
                % 수식 자리는 잘림표시로 바꾼다. 수식은 XML 에서 별도 런이 되므로
                % 앞뒤 글자가 이어져 있지 않다 (본문 문단 검사와 같은 방식).
                cp = regexprep(cp, '\$[^$]+\$', char(10));
                cp = strrep(strrep(cp, '**', ''), '`', '');
                sg = strtrim(regexp(cp, char(10), 'split'));
                sg = sg(~cellfun(@isempty, sg));
                if isempty(sg), continue; end
                sg = cellfun(@(x) strtrim(regexprep(x, '\s+', ' ')), sg, ...
                             'UniformOutput', false);
                [~, kk] = max(cellfun(@numel, sg));
                cp = sg{kk};
                if isempty(cp), continue; end
                if numel(cp) > 20, cp = cp(1:20); end
                if ~contains(plain, cp)
                    report.missing{end+1} = ['(표) ' rows{r0}]; %#ok<AGROW>
                    break
                end
            end
        end
        continue
    end

    % 꾸밈 표시를 걷어낸 순수 글자로 확인합니다.
    probe = blocks(i).text;
    probe = regexprep(probe, '\[([^\]]+)\]\([^)]+\)', '$1');   % 링크는 보이는 글자만 남는다
    % 수식 자리는 잘림표시(줄바꿈)로 바꿔 두고, 순수 글자 토막만 남깁니다.
    probe = regexprep(probe, '\$\$[^$]+\$\$', char(10));
    probe = regexprep(probe, '\$[^$]+\$',     char(10));
    probe = strrep(probe, '**', '');
    probe = strrep(probe, '`',  '');
    if isempty(strtrim(probe)), continue; end

    % 꾸밈 때문에 문장이 쪼개져도 잡히도록, 가장 긴 토막 하나로 확인합니다.
    seg = strtrim(regexp(probe, char(10), 'split'));
    seg = seg(~cellfun(@isempty, seg));
    if isempty(seg), continue; end
    seg = cellfun(@(x) strtrim(regexprep(x, '\s+', ' ')), seg, 'UniformOutput', false);
    [~, k] = max(cellfun(@numel, seg));
    probe = seg{k};
    if numel(probe) > 25, probe = probe(1:25); end

    if ~contains(plain, probe)
        report.missing{end+1} = blocks(i).text; %#ok<AGROW>
    end
end
end
