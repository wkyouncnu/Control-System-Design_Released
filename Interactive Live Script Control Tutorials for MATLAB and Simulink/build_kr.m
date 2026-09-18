function build_kr(only)
%BUILD_KR  CTMS 튜토리얼의 한글판(_KR.mlx)을 만든다 (교수자용)
%
%   build_kr()              전부
%   build_kr('Modeling')    이름에 'Modeling' 이 들어간 것만
%
%   원본 영어 파일은 **건드리지 않습니다.**
%   `_KR_src/` 의 한글 원고를 읽어 각 튜토리얼 폴더 옆에
%   `<이름>_KR.mlx` 를 만들어 둡니다.
%
%   예 :
%     Introduction_SystemModeling/
%       Introduction_SystemModeling.mlx      (원본, 영어)
%       Introduction_SystemModeling_KR.mlx   (한글판, 이 함수가 만듦)
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 1, only = ''; end

here = fileparts(mfilename('fullpath'));
srcs = dir(fullfile(here, '_KR_src', '*_KR_src.m'));

fprintf('=== 한글판 만들기 ===\n');
nOK = 0;
for i = 1:numel(srcs)
    [~, base] = fileparts(srcs(i).name);
    stem = erase(base, '_KR_src');                 % 예: Introduction_SystemModeling
    if ~isempty(only) && ~contains(stem, only), continue; end

    % 원본이 있는 폴더를 찾는다
    tgtDir = '';
    d = dir(fullfile(here, '*'));
    d = d([d.isdir] & ~startsWith({d.name}, '.') & ~startsWith({d.name}, '_'));
    for k = 1:numel(d)
        if isfile(fullfile(here, d(k).name, [stem '.mlx'])) || ...
           contains(d(k).name, stem) || contains(stem, d(k).name)
            tgtDir = fullfile(here, d(k).name); break
        end
    end
    if isempty(tgtDir), tgtDir = here; end

    outPath = fullfile(tgtDir, [stem '_KR.mlx']);
    srcPath = fullfile(srcs(i).folder, srcs(i).name);

    % 원고가 오류 없이 도는지 먼저 확인
    ok = true;
    try
        evalc(sprintf('evalin(''base'', ''run(''''%s'''')'')', srcPath));
    catch ME
        fprintf('  [!] %-34s 실행 실패 : %s\n', stem, ME.message);
        ok = false;
    end
    close all force;
    if ~ok, continue; end

    rep = mlx_from_script(srcPath, outPath);
    fprintf('  [OK] %-34s 절 %2d, 그림 %d, 수식 %d, 누락 %d, 미지원수식 %d\n', ...
            stem, rep.nHeading, rep.nImage, rep.nEq, ...
            numel(rep.missing), numel(rep.latexBad));
    nOK = nOK + 1;
end
fprintf('  한글판 %d 개를 만들었습니다.\n\n', nOK);
end
