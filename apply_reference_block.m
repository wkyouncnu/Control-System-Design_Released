function apply_reference_block(weekFilter)
%APPLY_REFERENCE_BLOCK  모든 강의노트 첫 장에 참고자료 블록을 넣습니다. (교수자용)
%
%   APPLY_REFERENCE_BLOCK()        전 주차
%   APPLY_REFERENCE_BLOCK('W09')   한 주차만
%
%   무엇을 하는가
%     `_templates/reference_block.txt` 의 내용을 각 주차 강의노트 원본
%     (`_src/Wxx_LectureNote_src.m`) 의 **첫 장**에 넣습니다.
%     들어가는 자리는 문서 제목 바로 아래, "제어시스템설계 · 충남대학교" 줄 다음입니다.
%
%   왜 도구로 만드는가
%     교수자 요청 — "항상 첫장에 동일한 포맷으로 넣어줘".
%     손으로 복사하면 주차마다 조금씩 달라집니다. 원본은 한 곳(템플릿)에만 두고
%     이 함수가 모든 주차에 같은 것을 넣습니다. 링크가 바뀌면 템플릿만 고치고
%     이 함수를 다시 돌리면 전 주차가 한 번에 갱신됩니다.
%
%   몇 번을 돌려도 안전합니다
%     이미 들어가 있으면 지우고 새로 넣습니다(덮어쓰기). 중복되지 않습니다.
%
%   넣은 뒤에는
%     build_lecture_notes()   로 .mlx 를 다시 만들고
%     verify_all()            로 검증합니다
%
%   같은 형식을 쓰는 다른 과목
%     센서신호처리및융합/00_GradCourse_2026/_templates/week.md 의
%     "Reference material — read this first" 콜아웃이 원본입니다.
%     그쪽은 영어 강의라 영어, 이 과목은 한글입니다. 링크는 같습니다.
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(weekFilter), weekFilter = 'W*'; end
if ~contains(weekFilter, '*'), weekFilter = [weekFilter '*']; end

root  = fileparts(mfilename('fullpath'));
tplF  = fullfile(root, '_templates', 'reference_block.txt');
if ~isfile(tplF)
    error('apply_reference_block:템플릿없음', ...
          '템플릿을 찾을 수 없습니다: %s', tplF);
end

blk = strsplit(fileread(tplF), {sprintf('\r\n'), sprintf('\n')});
blk = blk(~cellfun(@(x) isempty(strtrim(x)), blk));   % 끝의 빈 줄 제거

FIRST = '% **참고자료 — 먼저 볼 것**';       % 블록의 시작을 알아보는 표시
LAST  = '% | Simulink |';                    % 블록의 마지막 줄이 시작하는 모양
ANCHOR = '충남대학교 자율운항시스템공학과';   % 이 줄 **다음**에 넣는다

srcs = dir(fullfile(root, weekFilter, '_src', '*_LectureNote_src.m'));
if isempty(srcs)
    error('apply_reference_block:원본없음', '강의노트 원본을 찾지 못했습니다.');
end

fprintf('=== 참고자료 블록 넣기 ===\n');
nNew = 0; nUpd = 0; nSkip = 0;

for k = 1:numel(srcs)
    f = fullfile(srcs(k).folder, srcs(k).name);
    L = strsplit(fileread(f), {sprintf('\r\n'), sprintf('\n')});

    % --- 이미 들어 있으면 걷어낸다 (덮어쓰기) ---
    i0 = find(strcmp(strtrim(L), strtrim(FIRST)), 1);
    hadBefore = ~isempty(i0);
    if hadBefore
        i1 = find(startsWith(strtrim(L(i0:end)), LAST), 1);
        if isempty(i1)
            fprintf('  [!] %-28s 시작 표시는 있는데 끝을 못 찾았습니다. 건너뜁니다.\n', ...
                    srcs(k).name);
            nSkip = nSkip + 1;
            continue
        end
        i1 = i0 + i1 - 1;
        % 블록 바로 뒤의 빈 주석줄(%) 하나도 함께 걷어낸다
        if i1 < numel(L) && strcmp(strtrim(L{i1+1}), '%'), i1 = i1 + 1; end
        L(i0:i1) = [];
    end

    % --- 넣을 자리 찾기 ---
    a = find(contains(L, ANCHOR), 1);
    if isempty(a)
        fprintf('  [!] %-28s "%s" 줄이 없어 자리를 못 찾았습니다.\n', ...
                srcs(k).name, ANCHOR);
        nSkip = nSkip + 1;
        continue
    end

    % 앵커 다음이 빈 주석줄이면 그 뒤에 넣어 문단이 붙지 않게 한다
    ins = a;
    if ins < numel(L) && strcmp(strtrim(L{ins+1}), '%'), ins = ins + 1; end

    L = [L(1:ins), {'%'}, blk, {'%'}, L(ins+1:end)];

    fid = fopen(f, 'w', 'n', 'UTF-8');
    fwrite(fid, strjoin(L, newline));
    fclose(fid);

    if hadBefore
        fprintf('  [갱신] %-28s\n', srcs(k).name);  nUpd = nUpd + 1;
    else
        fprintf('  [추가] %-28s\n', srcs(k).name);  nNew = nNew + 1;
    end
end

fprintf('\n  추가 %d · 갱신 %d · 건너뜀 %d\n', nNew, nUpd, nSkip);
fprintf('  이어서 build_lecture_notes() 와 verify_all() 을 돌리십시오.\n\n');
end
