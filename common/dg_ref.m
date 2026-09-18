function dg_ref(name, caption)
%DG_REF  참고 그림(common/figures 의 PNG)을 한글 설명과 함께 띄운다
%
%   dg_ref('rlc_circuit')
%   dg_ref('rlc_circuit', 'RLC 회로 : 커패시터와 인덕터가 둘 다 있으면 2차가 된다')
%
%   왜 필요한가
%     블록선도나 장치 그림은 대부분 `dg_loop`, `dg_msd` 처럼 **코드로 직접 그립니다.**
%     한글 설명을 넣을 수 있고 나중에 고치기도 쉽기 때문입니다.
%
%     다만 이미 잘 만들어진 그림이 있으면 굳이 다시 그릴 필요가 없습니다.
%     그럴 때 이 함수로 불러 쓰고, **설명만 한글로 붙입니다.**
%
%   쓸 수 있는 그림 (common/figures)
%     msd_system       질량-스프링-댐퍼 장치 그림
%     msd_fbd          질량-스프링-댐퍼 자유물체도
%     rlc_circuit      RLC 회로
%     loop_K           비례이득만 있는 폐루프
%     loop_controller_disturbance   제어기와 외란이 있는 폐루프
%     rootlocus_example  근궤적 예시
%     freq_1 ~ freq_9  주파수응답 관련 (9~10주차에서 씁니다)
%
%   이름만 주고 부르면 목록을 보여 줍니다.
%
%     dg_ref
%
%   출처
%     MathWorks / University of Michigan 의 Control Tutorials for MATLAB and
%     Simulink 라이브 스크립트에서 가져왔습니다.
%     원본은 `2026_실습/Interactive Live Script Control Tutorials...` 폴더에 있습니다.
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

here = fileparts(mfilename('fullpath'));
figdir = fullfile(here, 'figures');

if nargin < 1 || isempty(name)
    d = dir(fullfile(figdir, '*.png'));
    fprintf('쓸 수 있는 참고 그림 (%d 개)\n', numel(d));
    for i = 1:numel(d)
        [~, b] = fileparts(d(i).name);
        fprintf('  %s\n', b);
    end
    return
end

[~, ~, ext] = fileparts(name);
if isempty(ext), name = [name '.png']; end
p = fullfile(figdir, name);

if ~isfile(p)
    error('dg_ref:없음 - %s 를 찾을 수 없습니다. 목록을 보려면 dg_ref 를 인자 없이 부르십시오.', name);
end

img = imread(p);
figure('Color','w');
imshow(img, 'Border', 'tight');
if nargin >= 2 && ~isempty(caption)
    title(caption, 'FontSize', 12, 'FontWeight', 'normal');
end
end
