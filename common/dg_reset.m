function dg_reset()
%DG_RESET  다이어그램 검사 보관함을 비운다
%
%   dg_reset()
%
%   자동 검증을 돌리기 **전에** 한 번 부릅니다.
%   앞서 다른 파일이 그린 그림이 섞이지 않도록 하기 위해서입니다.
%
%   보통은 verify_all 이 알아서 부르므로 직접 쓸 일은 없습니다.
%
%   제어시스템설계 | 충남대학교 자율운항시스템공학과

if isappdata(0, 'DG_LOG'), rmappdata(0, 'DG_LOG'); end
if isappdata(0, 'DG_REG'), rmappdata(0, 'DG_REG'); end
end
