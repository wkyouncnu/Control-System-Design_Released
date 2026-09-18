function [zeta_min, wn_min, s_target] = spec2pole(P_OS, ts, pct)
%SPEC2POLE  시간응답 사양을 목표 극점 조건으로 바꿉니다.
%
%   [zeta_min, wn_min, s_target] = SPEC2POLE(P_OS, ts)
%   [zeta_min, wn_min, s_target] = SPEC2POLE(P_OS, ts, pct)
%
%   입력
%     P_OS : 허용 오버슈트 [%]     예: 10 이면 10 % 이하
%     ts   : 허용 정착시간 [s]
%     pct  : 정착시간 기준 [%]. 생략하면 2 (2 % 기준)
%
%   출력
%     zeta_min : 이 값 이상이어야 오버슈트 조건을 만족하는 감쇠비
%     wn_min   : 이 값 이상이어야 정착시간 조건을 만족하는 고유진동수
%     s_target : 두 조건을 딱 맞게 만족하는 극점 (복소수 한 쌍 중 위쪽)
%
%   원리
%     표준 2차 시스템의 오버슈트는 감쇠비만으로 정해집니다.
%
%         %OS = 100 * exp( -zeta*pi / sqrt(1-zeta^2) )
%
%     이 식을 zeta 에 대해 풀면
%
%         zeta = -ln(OS/100) / sqrt( pi^2 + ln(OS/100)^2 )
%
%     정착시간은 포락선 exp(-zeta*wn*t) 가 허용오차까지 줄어드는 시간입니다.
%
%         2 % 기준 : ts = 4/(zeta*wn)      ->  wn = 4/(zeta*ts)
%         5 % 기준 : ts = 3/(zeta*wn)      ->  wn = 3/(zeta*ts)
%
%   어떻게 쓰는가
%     구한 두 값은 s 평면에서 "극점이 여기 있어야 한다"는 영역을 그립니다.
%
%       zeta >= zeta_min  ->  원점에서 뻗은 부채꼴 안쪽 (덜 진동)
%       wn   >= wn_min    ->  반지름 wn_min 인 원 바깥쪽 (더 빠름)
%
%     6주차 근궤적에서 sgrid(zeta_min, wn_min) 으로 이 영역을 그려 놓고
%     궤적이 그 안을 지나는 지점의 이득을 고르게 됩니다.
%
%   주의
%     이 공식은 영점이 없는 표준 2차 시스템에서 유도된 것입니다.
%     영점이 있거나 극점이 셋 이상이면 어림값으로만 쓰고 반드시
%     stepinfo 로 실제 값을 확인해야 합니다.
%
%   예제
%     [z, w] = spec2pole(10, 2);      % 오버슈트 10 % 이하, 정착시간 2 s 이하
%
%   See also STEPINFO, SGRID

% 제어시스템설계 | 충남대학교 자율운항시스템공학과

if nargin < 3 || isempty(pct), pct = 2; end

if P_OS <= 0 || P_OS >= 100
    error('spec2pole:badOS', '오버슈트는 0 과 100 사이여야 합니다. 입력값: %g', P_OS);
end
if ts <= 0
    error('spec2pole:badTs', '정착시간은 양수여야 합니다. 입력값: %g', ts);
end

r = log(P_OS/100);
zeta_min = -r / sqrt(pi^2 + r^2);

switch pct
    case 2, c = 4;
    case 5, c = 3;
    otherwise
        % 일반식: 포락선이 pct/100 까지 줄어드는 시간
        c = -log(pct/100);
end

wn_min = c / (zeta_min * ts);

% 두 조건을 딱 맞게 만족하는 극점
s_target = -zeta_min*wn_min + 1j*wn_min*sqrt(1 - zeta_min^2);

end
