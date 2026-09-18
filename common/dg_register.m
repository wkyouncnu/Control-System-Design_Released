function dg_register(what, item)
%DG_REGISTER  다이어그램 요소를 기록장에 적어 둔다 (내부용)
%
%   dg_block, dg_sum, dg_arrow 가 자동으로 호출합니다.
%   사용자가 직접 부를 일은 없습니다.
%
%   기록해 두는 이유는 dg_check 가 나중에 읽어서
%   끊긴 선, 겹친 블록, 블록을 뚫고 지나가는 선을 찾아내기 위해서입니다.
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

reg = getappdata(0, 'DG_REG');
if isempty(reg)
    reg = struct('W', NaN, 'H', NaN, 'boxes', {{}}, 'arrows', {{}});
end

switch what
    case 'box'
        reg.boxes{end+1} = item;
    case 'arrow'
        reg.arrows{end+1} = item;
end

setappdata(0, 'DG_REG', reg);
end
