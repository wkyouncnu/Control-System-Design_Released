%% Kp = 10
% Method 1 : calculate the closed loop transfer function by hand
n = 10;
d = [1 2 12];
sys = tf(n, d);
 
t = 0:0.001:5;
% Method 2 
Kp =tf(n,1);
G_s = tf(1, [1 2 2]);
GT=feedback(Kp*G_s,1);
R=ones(size(t));
 
% sys & GT are the same
%% Using lsim
figure()
y = lsim(GT,R,t);
plot(t, y, 'LineWidth', 2);
title('Step response of mass-spring-damper')
xlabel('time (s)')
legend('Kp = 10')
ylabel('x(t)')
grid on;
 
%% Using step
figure()
y = step(sys,t); hold on;
% S = stepinfo(sys)
plot(t, y, 'LineWidth', 2);
title('Step response of mass-spring-damper')
xlabel('time (s)')
legend('Kp = 10')
ylabel('x(t)')
grid on;


%%
t = 0:0.001:5;
Step = ones(size(t));  % step input
Ramp = t.*ones(size(t));  % ramp input
Parabolic = 1/2*t.^2.*ones(size(t));  % parabolic input

figure()
plot(t, Step, 'LineWidth', 2); hold on;
plot(t, Ramp, 'LineWidth', 2); 
plot(t, Parabolic, 'LineWidth', 2);
xlabel('time (s)');
grid on;
legend('Step','Ramp','Parabolic');

% sys & GT are the same
%% Using lsim for RAMP
figure()
y = lsim(GT,Ramp,t);
plot(t, Ramp, 'LineWidth', 2);  hold on;
plot(t, y, 'LineWidth', 2);
title('RAMP response of mass-spring-damper')
xlabel('time (s)')
legend('Ramp input', 'Response');
ylabel('x(t)')
grid on;
 
%% Using lsim for Parabolic
figure()
y = lsim(GT,Parabolic,t);
plot(t, Parabolic, 'LineWidth', 2);  hold on;
plot(t, y, 'LineWidth', 2);
title('Parabolic response of mass-spring-damper')
xlabel('time (s)')
legend('Parabolic input', 'Response');
ylabel('x(t)')
grid on;
 