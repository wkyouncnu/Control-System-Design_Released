%% W12_01_state_response.m
%  12주차 실습 (1) : 상태방정식의 해와 모드
%
%  이 스크립트에서 답할 질문
%    Q1. 상태방정식의 해는 어떻게 생겼는가?        -> 1절
%    Q2. 행렬 지수함수 expm 은 무엇인가?           -> 2절
%    Q3. 고유값과 고유벡터가 왜 나오는가?          -> 3절
%    Q4. 모드란 무엇인가?                          -> 4절
%    Q5. 상태공간과 전달함수는 어떻게 오가는가?    -> 5절
%
%  대응하는 강의노트 : W12_LectureNote.mlx
%  대응하는 Simulink : W12_StateSpace_Modes.slx
%
%  제어시스템설계 12주차 | 충남대학교 자율운항시스템공학과

clc; clear all; close all;

%% 경로 자동 등록 — setup_path 를 아직 안 했어도 알아서 잡습니다
%  (이 블록은 실습 내용과 상관없습니다. 지우지 마십시오.)
if isempty(which('plant_msd'))
    p_ = pwd;
    if ~isempty(mfilename('fullpath')), p_ = fileparts(mfilename('fullpath')); end
    for k_ = 1:4
        if isfile(fullfile(p_,'setup_path.m')), run(fullfile(p_,'setup_path.m')); break; end
        p_ = fileparts(p_);
    end
    clear p_ k_
end
s = tf('s');

%% 1. 상태방정식의 해
%
%  3주차에서 상태공간을 만들었습니다. 오늘은 그것을 **푸는** 이야기입니다.
%
%      x' = A*x + B*u
%      y  = C*x + D*u
%
%  입력이 없는 경우(u = 0)부터 봅니다.
%
%      x' = A*x,     x(0) = x0
%
%  스칼라였다면 답은 뻔합니다.
%
%      x' = a*x  ->  x(t) = exp(a*t)*x(0)
%
%  행렬이어도 **모양이 똑같습니다.**
%
%      x(t) = expm(A*t)*x(0)
%
%  이 expm(A*t) 를 **상태천이행렬**이라고 부릅니다.
%  "초기 상태를 시각 t 의 상태로 옮겨 주는 행렬" 이라는 뜻입니다.

A = [0 1; -2 -3];       % 고유값 -1, -2
B = [0; 1];
C = [1 0];
D = 0;
sys = ss(A, B, C, D);

fprintf('=== 오늘의 시스템 ===\n');
fprintf('  A = %s\n', mat2str(A));
fprintf('  고유값 : %s\n', mat2str(round(eig(A).', 4)));
fprintf('  전달함수 :\n');
tf(sys)

%% 1-1. 확인 — expm 으로 구한 답과 lsim 이 같은가
x0 = [1; 0];
t  = (0:0.01:6)';

X_expm = zeros(numel(t), 2);
for i = 1:numel(t)
    X_expm(i,:) = (expm(A*t(i))*x0).';
end

X_lsim = initial(ss(A, B, eye(2), [0;0]), x0, t);

fprintf('=== expm 으로 푼 것 vs initial 로 푼 것 ===\n');
fprintf('  최대 차이 : %.3e\n', max(max(abs(X_expm - X_lsim))));
fprintf('  --> 같습니다. initial 이 내부에서 하는 일이 바로 이것입니다.\n\n');

figure('Name','상태천이행렬', 'Position',[80 80 900 400]);
plot(t, X_expm(:,1), 'LineWidth', 2.5); hold on; grid on;
plot(t, X_expm(:,2), 'LineWidth', 2.5);
plot(t, X_lsim(:,1), '--', 'LineWidth', 1.5);
plot(t, X_lsim(:,2), '--', 'LineWidth', 1.5);
xlabel('시간 [s]'); ylabel('상태');
legend('x_1 (expm)','x_2 (expm)','x_1 (initial)','x_2 (initial)','Location','northeast');
title('x(t) = expm(A t) x(0)');

%% 2. 행렬 지수함수는 무엇인가
%
%  정의는 스칼라 지수함수의 급수를 그대로 옮긴 것입니다.
%
%      expm(A*t) = I + A*t + (A*t)^2/2! + (A*t)^3/3! + ...
%
%  이 급수를 실제로 몇 항까지 더해 보면 expm 과 같아집니다.

t1 = 0.5;
E_exact = expm(A*t1);
fprintf('=== 급수로 직접 계산해 보기 (t = %.1f) ===\n', t1);
fprintf('    항 개수   급수 결과와 expm 의 차이\n');
fprintf('   --------  --------------------------\n');
E_sum = zeros(2);
for n = 0:10
    E_sum = E_sum + (A*t1)^n / factorial(n);
    if ismember(n, [1 2 3 5 8 10])
        fprintf('   %8d  %26.3e\n', n+1, max(max(abs(E_sum - E_exact))));
    end
end
fprintf('   --> 항을 늘릴수록 빠르게 수렴합니다.\n');
fprintf('       실제로는 MATLAB 이 더 똑똑한 방법(Pade 근사)을 씁니다.\n\n');

%% 2-1. 상태천이행렬의 성질
%
%  스칼라 지수함수와 같은 성질을 그대로 가집니다.
%
%      expm(A*0)       = I
%      expm(A*(t1+t2)) = expm(A*t1)*expm(A*t2)
%      expm(A*t)^-1    = expm(-A*t)
%
%  **주의** — 한 가지는 다릅니다.
%
%      expm(A + B) 는 expm(A)*expm(B) 와 **같지 않습니다.**
%      A*B = B*A 일 때만 같습니다. 행렬 곱은 교환법칙이 성립하지 않기 때문입니다.

fprintf('=== 상태천이행렬의 성질 확인 ===\n');
fprintf('  expm(A*0) = I 인가        : 차이 %.3e\n', max(max(abs(expm(A*0) - eye(2)))));
fprintf('  expm(A*3) = expm(A*1)*expm(A*2) 인가 : 차이 %.3e\n', ...
        max(max(abs(expm(A*3) - expm(A*1)*expm(A*2)))));
Bm = [1 0; 0 2];
fprintf('  expm(A+Bm) = expm(A)*expm(Bm) 인가   : 차이 %.3e  (A*Bm ~= Bm*A 이므로 다르다)\n\n', ...
        max(max(abs(expm(A+Bm) - expm(A)*expm(Bm)))));

%% 3. 고유값과 고유벡터가 왜 나오는가
%
%  급수로는 계산할 수 있지만 **의미가 안 보입니다.**
%  그래서 A 를 대각화합니다.
%
%      A*v = lambda*v     (고유값 방정식)
%
%  고유벡터를 모아 T = [v1 v2 ...] 로 두면
%
%      T^-1 * A * T = diag(lambda1, lambda2, ...)  =  Lambda
%
%  그러면 상태천이행렬이 아주 간단해집니다.
%
%      expm(A*t) = T * expm(Lambda*t) * T^-1
%                = T * diag(exp(l1*t), exp(l2*t), ...) * T^-1
%
%  **대각행렬의 지수함수는 대각원소를 각각 지수함수로 바꾼 것뿐입니다.**
%  그래서 행렬 지수함수가 결국 **스칼라 지수함수 몇 개의 조합**이 됩니다.

[V, Lam] = eig(A);
lam = diag(Lam);

fprintf('=== 고유값 분해 ===\n');
fprintf('  고유값 : %s\n', mat2str(round(lam.', 4)));
fprintf('  고유벡터 (열마다 하나) :\n');
disp(round(V, 4));
fprintf('  대각화 확인 : inv(V)*A*V =\n');
disp(round(V\A*V, 6));
fprintf('\n');

E1 = expm(A*t1);
E2 = V * diag(exp(lam*t1)) / V;
fprintf('  expm(A*t) 를 두 가지로 계산 (t = %.1f)\n', t1);
fprintf('    직접 expm      : %s\n', mat2str(round(E1, 4)));
fprintf('    고유값 분해로  : %s\n', mat2str(round(real(E2), 4)));
fprintf('    차이 %.3e --> 같습니다.\n\n', max(max(abs(E1 - real(E2)))));

%% 3-1. 유사변환 — 좌표를 바꿔도 시스템은 같다
%
%  T 를 아무 가역행렬로 잡고 z = T^-1 * x 로 좌표를 바꾸면
%
%      z' = (T^-1*A*T)*z + (T^-1*B)*u
%      y  = (C*T)*z + D*u
%
%  이것을 **유사변환**이라고 합니다. 중요한 성질 두 가지가 있습니다.
%
%      (1) 고유값이 변하지 않는다  ->  **극점이 변하지 않는다**
%      (2) 전달함수가 변하지 않는다
%
%  즉 **상태공간 표현은 하나가 아닙니다.** 무수히 많습니다.
%  그런데 전달함수는 하나입니다. 3주차에서 본 이야기와 같습니다.

T_rand = [1 2; 3 5];
A_new = T_rand\A*T_rand;
B_new = T_rand\B;
C_new = C*T_rand;

fprintf('=== 유사변환 확인 ===\n');
fprintf('  원래 A     의 고유값 : %s\n', mat2str(round(eig(A).', 4)));
fprintf('  바꾼 A_new 의 고유값 : %s\n', mat2str(round(eig(A_new).', 4)));
fprintf('  두 전달함수의 차이 : %s\n', ...
        mat2str(round(norm(tf(ss(A,B,C,D)) - tf(ss(A_new,B_new,C_new,D)), inf), 10)));
fprintf('  --> 좌표를 바꿔도 극점과 전달함수는 그대로입니다.\n\n');

%  T 를 아무렇게나 잡을 것이 아니라 **고유벡터**로 잡으면 특별한 일이 생깁니다.
%  T = V 이면 V^-1*A*V = Lambda (대각행렬) 이 되어 상태방정식이
%
%      z_i' = lambda_i * z_i        (i = 1, 2)
%
%  처럼 서로 얽히지 않은 1차 방정식으로 **갈라집니다.**
%  그래서 각 z_i 는 z_i(0)*exp(lambda_i*t) 하나로 움직입니다.
%  강의노트 6절의 w12_similarity.png 가 이 사실을 그림으로 보인 것입니다.

[V_m, D_m] = eig(A);
lam_m = diag(D_m);
A_diag = V_m\A*V_m;

fprintf('=== 고유벡터를 좌표로 쓰면 ===\n');
fprintf('  V^-1*A*V = %s\n', mat2str(round(A_diag, 6)));
fprintf('  비대각 성분의 크기 : %.2e  (0 이면 완전히 분리된 것)\n', ...
        max(abs(A_diag(~eye(2)))));

%  실제로 z 가 순수 지수함수인지 수치로 확인합니다.
x0_m  = [1; 0.2];
t_m   = linspace(0, 4, 401);
z_num = zeros(2, numel(t_m));
for j = 1:numel(t_m)
    z_num(:,j) = V_m\(expm(A*t_m(j))*x0_m);   % 계산한 상태를 모드 좌표로
end
z0_m  = V_m\x0_m;
z_ana = [z0_m(1)*exp(lam_m(1)*t_m); z0_m(2)*exp(lam_m(2)*t_m)];  % 해석해

fprintf('  z 계산값과 해석해의 최대 차이 : %.2e\n', ...
        max(abs(z_num(:) - z_ana(:))));
fprintf('  --> 모드 좌표에서는 지수함수 하나씩으로 갈라집니다.\n\n');

%% 4. 모드 — 고유벡터 방향에서 출발하면
%
%  초기조건을 **고유벡터 방향**으로 주면 어떻게 될까요.
%
%      x(0) = v1  (첫 번째 고유벡터)
%
%  그러면
%
%      x(t) = expm(A*t)*v1 = exp(lambda1*t)*v1
%
%  즉 **방향은 그대로이고 크기만 지수함수로 변합니다.**
%  이런 움직임 하나하나를 **모드** 라고 부릅니다.
%
%  일반적인 초기조건은 고유벡터들의 합으로 쓸 수 있으므로
%
%      x(t) = c1*exp(l1*t)*v1 + c2*exp(l2*t)*v2 + ...
%
%  **모든 응답은 결국 모드들의 합입니다.**

fprintf('=== 고유벡터 방향에서 출발하면 ===\n');
for k = 1:2
    v = V(:,k)/norm(V(:,k));
    Xk = zeros(numel(t), 2);
    for i = 1:numel(t), Xk(i,:) = (expm(A*t(i))*v).'; end
    ratio = Xk(:,1)./Xk(:,2);
    fprintf('  고유벡터 %d (lambda = %+.1f) 에서 출발\n', k, real(lam(k)));
    fprintf('    x1/x2 비율이 처음 %.4f, 끝 %.4f  -> 방향이 변하지 않는다\n', ...
            ratio(1), ratio(end));
    fprintf('    크기가 exp(%.1f*t) 로 줄어드는가 : t=1 에서 %.4f (이론 %.4f)\n', ...
            real(lam(k)), norm(Xk(round(1/0.01)+1,:)), exp(real(lam(k))*1));
end
fprintf('\n');

figure('Name','모드', 'Position',[80 80 950 400]);
tiledlayout(1,2,'TileSpacing','compact');

nexttile; hold on; grid on; axis equal;
for a = [-1.2 -0.6 0.6 1.2]
    for b = [-1.2 -0.6 0.6 1.2]
        Xt = zeros(numel(t),2);
        for i = 1:numel(t), Xt(i,:) = (expm(A*t(i))*[a;b]).'; end
        plot(Xt(:,1), Xt(:,2), 'Color', [0.75 0.78 0.85], 'HandleVisibility','off');
    end
end
for k = 1:2
    v = V(:,k)/norm(V(:,k));
    plot([-1.6*v(1) 1.6*v(1)], [-1.6*v(2) 1.6*v(2)], 'LineWidth', 2.5, ...
         'DisplayName', sprintf('고유벡터 (\\lambda = %.0f)', real(lam(k))));
end
xlim([-1.6 1.6]); ylim([-1.8 1.8]);
xlabel('x_1'); ylabel('x_2'); legend('Location','northwest');
title('모든 궤적은 느린 고유벡터 방향으로 붙는다');

nexttile; hold on; grid on;
for k = 1:2
    v = V(:,k)/norm(V(:,k));
    Xk = zeros(numel(t),2);
    for i = 1:numel(t), Xk(i,:) = (expm(A*t(i))*v).'; end
    plot(t, Xk(:,1), 'LineWidth', 2.4, ...
         'DisplayName', sprintf('고유벡터 출발 (\\lambda = %.0f)', real(lam(k))));
end
Xm = zeros(numel(t),2);
for i = 1:numel(t), Xm(i,:) = (expm(A*t(i))*[1;0]).'; end
plot(t, Xm(:,1), '--', 'LineWidth', 2, 'DisplayName','아무 방향 (섞여 있다)');
xlabel('시간 [s]'); ylabel('x_1'); legend('Location','northeast');
title('고유벡터에서 출발하면 지수함수 하나뿐');

%% 4-1. 안정성 — 고유값 하나라도 우반면이면 불안정
%
%  모드가 exp(lambda*t) 로 움직이므로 결론이 바로 나옵니다.
%
%      모든 고유값의 실수부 < 0   ->  모든 모드가 사라진다  ->  안정
%      하나라도 실수부 > 0        ->  그 모드가 커진다      ->  불안정
%
%  **하나만 나빠도 전체가 불안정합니다.** 나머지가 아무리 좋아도 소용없습니다.
%
%  그리고 5주차에서 배운 "극점 = 고유값" 이 여기서 증명됩니다.
%
%      전달함수의 분모 = det(s*I - A) = A 의 특성다항식

fprintf('=== 극점과 고유값이 같은가 ===\n');
fprintf('  A 의 고유값        : %s\n', mat2str(round(eig(A).', 4)));
fprintf('  전달함수의 극점    : %s\n', mat2str(round(pole(tf(sys)).', 4)));
fprintf('  det(sI - A) 의 근  : %s\n', mat2str(round(roots(poly(A)).', 4)));
fprintf('  --> 셋이 같습니다.\n\n');

Au = [0 1; 2 -1];       % 강의자료 예제 8-3 : 우반면 극점이 하나
fprintf('=== 불안정한 예 (강의자료 예제 8-3) ===\n');
fprintf('  A = %s\n', mat2str(Au));
fprintf('  고유값 : %s\n', mat2str(round(eig(Au).', 4)));
fprintf('  --> +1 이 있으므로 불안정합니다.\n');
[Vu, Lu] = eig(Au);
fprintf('  불안정한 모드의 방향 (고유벡터) : %s\n', ...
        mat2str(round(Vu(:, real(diag(Lu)) > 0).', 4)));
fprintf('  이 방향으로 조금이라도 벗어나면 되돌아오지 않고 커집니다.\n\n');

tu = (0:0.02:4)';
figure('Name','불안정한 모드', 'Position',[80 80 900 400]);
Xs = zeros(numel(tu),2); Xu = zeros(numel(tu),2);
v_s = Vu(:, real(diag(Lu)) < 0);  v_s = v_s/norm(v_s);
v_u = Vu(:, real(diag(Lu)) > 0);  v_u = v_u/norm(v_u);
for i = 1:numel(tu)
    Xs(i,:) = (expm(Au*tu(i))*v_s).';
    Xu(i,:) = (expm(Au*tu(i))*v_u).';
end
semilogy(tu, abs(Xs(:,1)), 'LineWidth', 2.4); hold on; grid on;
semilogy(tu, abs(Xu(:,1)), 'LineWidth', 2.4);
xlabel('시간 [s]'); ylabel('|x_1| (로그축)');
legend(sprintf('안정한 모드 (\\lambda = %.0f)', min(real(diag(Lu)))), ...
       sprintf('불안정한 모드 (\\lambda = %.0f)', max(real(diag(Lu)))), ...
       'Location','east');
title('불안정한 모드는 지수적으로 커진다');

%% 5. 상태공간과 전달함수 오가기
%
%  3주차에서 유도한 식입니다.
%
%      G(s) = C*(s*I - A)^-1*B + D
%
%  MATLAB 에서는 tf 와 ss 로 오갑니다.
%
%  **주의** — ss 로 되돌아온 결과는 원래 A, B, C 와 **다를 수 있습니다.**
%  유사변환만큼의 자유도가 있기 때문입니다. 극점과 전달함수는 같습니다.

sys_tf  = tf(sys);
sys_ss2 = ss(sys_tf);

fprintf('=== 왕복 변환 ===\n');
fprintf('  원래 A      : %s\n', mat2str(round(A, 4)));
fprintf('  왕복 후 A   : %s\n', mat2str(round(sys_ss2.A, 4)));
fprintf('  고유값 (원래)  : %s\n', mat2str(round(eig(A).', 4)));
fprintf('  고유값 (왕복)  : %s\n', mat2str(round(eig(sys_ss2.A).', 4)));
fprintf('  --> 행렬은 달라졌지만 고유값은 같습니다. 유사변환 관계입니다.\n\n');

%% 5-1. C*(sI-A)^-1*B 를 직접 계산해 보기
fprintf('=== 공식을 직접 써 보기 ===\n');
for sv = [0, 1i, 2]
    Gv_formula = C*((sv*eye(2) - A)\B) + D;
    Gv_matlab  = freqresp(sys, sv/1i);
    if sv == 0
        Gv_matlab = dcgain(sys);
    end
    fprintf('  s = %-6s : 공식 %.6f%+.6fi\n', mat2str(sv), ...
            real(Gv_formula), imag(Gv_formula));
end
fprintf('  (s = 0 을 넣으면 직류이득 %.4f 가 나옵니다)\n\n', dcgain(sys));

%% 6. 이번 실습의 정리
%
%   (1) 상태방정식의 해는 x(t) = expm(A*t)*x(0). 스칼라와 모양이 같다
%   (2) 대각화하면 expm 이 스칼라 지수함수 몇 개로 분해된다
%   (3) 그 하나하나가 **모드**다. 고유벡터 방향으로 출발하면 모드 하나만 나온다
%   (4) 고유값 하나라도 우반면이면 불안정하다
%   (5) 극점 = 고유값 = det(sI-A) 의 근. 셋은 같은 것이다
%   (6) 유사변환으로 상태공간 표현은 무수히 많지만 전달함수는 하나다
%
%  다음 실습
%    W12_02_ctrb_obsv.m — 제어할 수 있는가, 볼 수 있는가
