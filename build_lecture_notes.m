function build_lecture_notes(weekFilter, embedOutputs, forceOverwrite)
%BUILD_LECTURE_NOTES  강의노트(.mlx)를 원본 스크립트로부터 생성합니다. (교수자용)
%
%   각 주차 폴더의  _src/Wxx_LectureNote_src.m  을 읽어
%   상위 폴더에  Wxx_LectureNote.mlx  로 변환합니다.
%
%   BUILD_LECTURE_NOTES()                    모든 주차를 변환
%   BUILD_LECTURE_NOTES('W01')               W01 만 변환
%   BUILD_LECTURE_NOTES('W01', true)         그림까지 문서 안에 미리 삽입 시도
%   BUILD_LECTURE_NOTES('W01', false, true)  직접 고친 .mlx 도 덮어쓴다
%
%   [안전장치] .mlx 가 _src 보다 나중에 저장되어 있으면 **건너뜁니다.**
%   Live Editor 에서 직접 고친 것을 덮어써 버리는 사고를 막기 위해서입니다.
%   실제로 이 사고가 날 뻔했습니다 — 교수자가 W01 강의노트에 영어 용어와
%   예제 두 개를 직접 추가해 두었는데, 그대로 다시 만들었으면 사라졌을 것입니다.
%
%   그림 삽입에 대하여
%     기본값은 false 입니다. 만들어진 .mlx 를 열면 코드와 설명만 있고 그림은
%     아직 없습니다. Live Editor 에서 [모두 실행]을 한 번 누르면 그림이 채워지고,
%     그 상태로 저장하면 다음부터는 열자마자 그림이 보입니다.
%     수업 전에 한 번 눌러 두시면 됩니다.
%
%     두 번째 인자를 true 로 주면 자동 삽입을 시도하지만, MATLAB 이
%     원격/자동화 모드로 실행 중일 때는 실패할 수 있습니다. 실패해도 문서
%     자체는 멀쩡하므로 위의 [모두 실행] 방법을 쓰면 됩니다.
%
%   변환 규칙 (MATLAB 이 알아서 해 줍니다)
%     %%  로 시작하는 줄        -> 제목/절 머리글
%     그 바로 아래의 % 주석들   -> 본문 설명 텍스트
%     나머지                    -> 코드 블록
%
%   따라서 원본 스크립트는 "%% 절 제목 / % 설명 여러 줄 / 코드" 순서로
%   쓰면 그대로 강의자료처럼 변환됩니다.
%
%   [중요] 이 함수는 .mlx 를 덮어씁니다.
%   .mlx 를 Live Editor 에서 직접 편집했다면 그 편집 내용이 사라집니다.
%   평소 수정은 .mlx 를 직접 하시고, 이 함수는 처음 만들 때나
%   원본을 크게 뜯어고칠 때만 사용하십시오.
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1 || isempty(weekFilter),     weekFilter     = 'W*';  end
if nargin < 2 || isempty(embedOutputs),   embedOutputs   = false; end
if nargin < 3 || isempty(forceOverwrite), forceOverwrite = false; end

% 'W01' 처럼 짧게 줘도 'W01*' 로 알아서 확장합니다.
if ~contains(weekFilter, '*'), weekFilter = [weekFilter '*']; end

root = fileparts(mfilename('fullpath'));

% 주차 폴더 아래의 모든 _src 폴더를 찾습니다.
% (강의노트는 Wxx/_src, 숙제는 Wxx/hw/_src 에 있습니다)
weekDirs = dir(fullfile(root, weekFilter));
weekDirs = weekDirs([weekDirs.isdir]);
if isempty(weekDirs)
    error('build_lecture_notes:noWeek', '해당하는 주차 폴더가 없습니다: %s', weekFilter);
end

srcList = [];
for i = 1:numel(weekDirs)
    found = dir(fullfile(root, weekDirs(i).name, '**', '_src', '*_src.m'));
    srcList = [srcList; found]; %#ok<AGROW>
end
if isempty(srcList)
    error('build_lecture_notes:noSrc', '_src 폴더에서 원본을 찾지 못했습니다.');
end

%% [안전장치] .mlx 를 Live Editor 에서 직접 고친 것이 있는지 먼저 본다
%  교수자가 .mlx 를 직접 편집한 뒤 이 함수를 돌리면 그 편집이 사라집니다.
%  .mlx 가 _src 보다 **나중에 저장되었으면** 직접 고친 것으로 보고 건너뜁니다.
%  덮어쓰려면 세 번째 인자를 true 로 주십시오.
%
%  [주의] 시간만 보고 판단하므로, 편집 없이 [모두 실행] 후 저장만 해도 걸립니다.
%         그때는 force 로 넘기면 됩니다. 반대로 놓치는 것보다 낫습니다.
skipIdx = false(numel(srcList),1);
if ~forceOverwrite
    for j = 1:numel(srcList)
        sp = fullfile(srcList(j).folder, srcList(j).name);
        op = fullfile(fileparts(srcList(j).folder), ...
                      [erase(erase(srcList(j).name,'_src'), '.m') '.mlx']);
        if isfile(op)
            ds = dir(sp);  do_ = dir(op);
            if do_.datenum > ds.datenum + 1/86400      % 1 초 이상 최신이면
                skipIdx(j) = true;
            end
        end
    end
end
if any(skipIdx)
    fprintf('\n----------------------------------------------------------\n');
    fprintf('  [주의] 아래 .mlx 는 원본보다 나중에 저장되었습니다.\n');
    fprintf('         Live Editor 에서 직접 고치셨을 수 있어 **건너뜁니다.**\n');
    for j = find(skipIdx).'
        fprintf('    - %s\n', erase(erase(srcList(j).name,'_src'), '.m'));
    end
    fprintf('\n  어떻게 할지\n');
    fprintf('    (1) 고친 내용을 살리려면 -> 그 내용을 _src 에 옮겨 적은 뒤 다시 실행\n');
    fprintf('    (2) 고친 것이 없거나 버려도 되면 -> build_lecture_notes(주차, false, true)\n');
    fprintf('----------------------------------------------------------\n');
end

nOK = 0;
for j = 1:numel(srcList)
    srcPath = fullfile(srcList(j).folder, srcList(j).name);
    outDir  = fileparts(srcList(j).folder);              % _src 의 부모 폴더
    outName = erase(srcList(j).name, '_src');            % ..._src.m -> ....m
    outPath = fullfile(outDir, [erase(outName, '.m') '.mlx']);

    fprintf('\n[%s]\n', srcList(j).name);
    if skipIdx(j)
        fprintf('  건너뜀 (.mlx 가 원본보다 최신입니다)\n');
        continue
    end
    if true

        % --- 1단계: 원본이 오류 없이 도는지 먼저 확인 ---
        %     이걸 건너뛰고 출력 삽입을 하면, 오류가 난 절 이후의 출력이
        %     통째로 사라져 버립니다.
        fprintf('  1) 원본 실행 검증 ... ');
        try
            evalin('base', sprintf('run(''%s'');', srcPath));
            fprintf('통과\n');
        catch ME
            fprintf('실패\n');
            fprintf('     오류: %s\n', ME.message);
            fprintf('     이 파일은 건너뜁니다. 원본을 고친 뒤 다시 실행하십시오.\n');
            continue;
        end
        close all;

        % --- 2단계: .m -> .mlx 변환 ---
        %     MATLAB 기본 변환기는 한글 문서에서 내용을 조용히 빠뜨리므로
        %     (한글로 시작하는 절 제목, 여러 줄 문단 등)
        %     내용을 직접 만들어 넣는 mlx_from_script 를 씁니다.
        fprintf('  2) .mlx 변환 ... ');
        rep = mlx_from_script(srcPath, outPath);
        fprintf('완료 (소제목 %d, 본문 %d, 코드 %d)\n', ...
                rep.nHeading, rep.nText, rep.nCode);

        if isempty(rep.missing)
            fprintf('     내용 검사 : 누락 없음\n');
        else
            fprintf(2, '     내용 검사 : %d 개 누락!\n', numel(rep.missing));
            for q = 1:numel(rep.missing)
                fprintf(2, '        - %s\n', rep.missing{q});
            end
        end

        if isempty(rep.latexBad)
            fprintf('     수식 검사 : 지원되지 않는 명령 없음\n');
        else
            fprintf(2, '     수식 검사 : Live Editor 가 모르는 명령 %d 개!\n', ...
                    numel(rep.latexBad));
            for q = 1:numel(rep.latexBad)
                fprintf(2, '        - \\%s   (글자 그대로 남게 됩니다)\n', rep.latexBad{q});
            end
        end

        % --- 3단계: 그림과 출력값을 문서 안에 삽입 ---
        if embedOutputs
            fprintf('  3) 출력 삽입 ... ');
            try
                matlab.internal.liveeditor.executeAndSave(outPath);
                fprintf('완료\n');
            catch ME
                fprintf('건너뜀 (%s)\n', ME.message);
                fprintf('     문서 자체는 정상입니다. 열어서 [모두 실행]을 누르면 됩니다.\n');
            end
            close all;
        end

        fprintf('  -> %s\n', outPath);
        nOK = nOK + 1;
    end
end

fprintf('\n총 %d 개의 강의노트를 생성했습니다.\n', nOK);

end
