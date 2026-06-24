% establish variables
heart_rate_baseline = 60;
heart_rate_caffeine = 70;

cardiac_cyc_baseline = 60 / heart_rate_baseline;
cardiac_cyc_caffeine = 60 / heart_rate_caffeine;

syst_baseline = 1/3 * cardiac_cyc_baseline;
syst_caffeine = 1/3 * cardiac_cyc_caffeine;

stroke_v = 70;
dt = 0.001;
t = 0:dt:20;

% Windkessel parameters
R_baseline = 1.0;
C_baseline = 2.0;

R_caffeine = 1.2;   % increased resistance
C_caffeine = 1.6;   % decreased compliance

% flow timing
t_change_baseline = mod(t, cardiac_cyc_baseline);
t_change_caffeine = mod(t, cardiac_cyc_caffeine);

in_syst_baseline = t_change_baseline <= syst_baseline;
in_syst_caffeine = t_change_caffeine <= syst_caffeine;

% forward systolic amplitude
A_forward_baseline = stroke_v * pi / (2 * syst_baseline);
A_forward_caffeine = stroke_v * pi / (2 * syst_caffeine);

%% -------- Create Flow I(t) for both cases --------
I_baseline = zeros(size(t));
I_caffeine = zeros(size(t));

I_baseline(in_syst_baseline) = A_forward_baseline * sin(pi * t_change_baseline(in_syst_baseline) / syst_baseline);
I_caffeine(in_syst_caffeine) = A_forward_caffeine * sin(pi * t_change_caffeine(in_syst_caffeine) / syst_caffeine);

%% -------- Plot Flow I(t) --------
figure;
hold on;

plot(t, I_baseline, 'LineWidth', 2, 'DisplayName', 'Baseline');
plot(t, I_caffeine, 'LineWidth', 2, 'LineStyle', '--', 'DisplayName', 'Caffeine');

xlabel('Time (s)');
ylabel('Flow I(t) (mL/s)');
title('Flow with Baseline vs Caffeine');
legend('show');
grid on;
hold off;

%% -------- Compute Pressure P(t) --------
P_baseline = zeros(size(t));
P_caffeine = zeros(size(t));

P_baseline(1) = 80;
P_caffeine(1) = 80;

for n = 1:length(t)-1
    dPdt_baseline = (1/C_baseline) * (I_baseline(n) - P_baseline(n)/R_baseline);
    P_baseline(n+1) = P_baseline(n) + dt * dPdt_baseline;

    dPdt_caffeine = (1/C_caffeine) * (I_caffeine(n) - P_caffeine(n)/R_caffeine);
    P_caffeine(n+1) = P_caffeine(n) + dt * dPdt_caffeine;
end

%% -------- Plot Pressure P(t) --------
figure;
hold on;

plot(t, P_baseline, 'LineWidth', 2, 'DisplayName', 'Baseline');
plot(t, P_caffeine, 'LineWidth', 2, 'LineStyle', '--', 'DisplayName', 'Caffeine');

xlabel('Time (s)');
ylabel('Pressure P(t)');
title('Pressure with Baseline vs Caffeine');
legend('show');
grid on;
hold off;

%% -------- Compute steady-state systolic, diastolic, pulse pressure --------
steady_idx = t >= 15;   % use last 5 seconds

% baseline
P_sys_baseline = max(P_baseline(steady_idx));
P_dia_baseline = min(P_baseline(steady_idx));
PP_baseline = P_sys_baseline - P_dia_baseline;

% caffeine
P_sys_caffeine = max(P_caffeine(steady_idx));
P_dia_caffeine = min(P_caffeine(steady_idx));
PP_caffeine = P_sys_caffeine - P_dia_caffeine;

fprintf('Baseline: HR = %.0f bpm, Systolic = %.2f, Diastolic = %.2f, Pulse Pressure = %.2f\n', ...
    heart_rate_baseline, P_sys_baseline, P_dia_baseline, PP_baseline);

fprintf('Caffeine: HR = %.0f bpm, Systolic = %.2f, Diastolic = %.2f, Pulse Pressure = %.2f\n', ...
    heart_rate_caffeine, P_sys_caffeine, P_dia_caffeine, PP_caffeine);