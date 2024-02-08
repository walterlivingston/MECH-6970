%% QUESTION 1
clear; close all; clc;

N = 1e3;
N_mc = 1e4;
a_true = 3;
H = ones(N,1);
variance = 1;
P_true = variance/((H'*H));
P_N = 1/N;
a = zeros(N_mc,1);
for i = 1:N_mc
    y = H*a_true + randn(N,1);
    da = 10;
    a(i) = LS(y, H, a(i));
end
P_mc = var(a);

fprintf('1) True Accuracy: %0.6g\n', P_true);
fprintf('1a) Accuracy as a Function of Samples: %0.6g\n', P_N);
fprintf('1b) Accuracy Determined from Monte Carlo: %0.6g\n\n', P_mc);

%% QUESTION 2
clear;

x = 0:4;
y = [0.181, 2.680, 3.467, 3.101, 3.437]';
var_y = (0.4)^2;
N = length(x);

Hab = [ones(N,1), x'];
ab = zeros(2,1);
[ab, idx1] = LS(y, Hab, ab);
Pab = var_y*inv(Hab'*Hab);

Habc = [ones(N,1), x', (x.^2)'];
abc = zeros(3,1);
[abc, idx2] = LS(y, Habc, abc);
Pabc = var_y*inv(Habc'*Habc);

Habcd = [ones(N,1), x', (x.^2)', (x.^3)'];
abcd = zeros(4,1);
[abcd, idx3] = LS(y, Habcd, abcd);
Pabcd = var_y*inv(Habcd'*Habcd);

warning('off');
figure();
title('2) Estimated Polynomial Coefficients Plotted')
hold("on");
fplot(@(x) ab(1) + ab(2)*x);
fplot(@(x) abc(1) + abc(2)*x + abc(3)*x^2, '--o');
fplot(@(x) abcd(1) + abcd(2)*x + abcd(3)*x^2 + abcd(4)*x^3, '-.*');
xlabel("X");
ylabel("Y");
xlim([0 5]);
ylim([0 5]);
legend('Linear', 'Quadratic', 'Cubic')
warning('on');

fprintf('2a) Standard Deviation on a(Linear): %0.6g\n', sqrt(Pab(1,1)));
fprintf('2b) Standard Deviation on a(Quadratic): %0.6g\n', sqrt(Pabc(1,1)));
fprintf('2c) Standard Deviation on a(Cubic): %0.6g\n\n', sqrt(Pabcd(1,1)));

%% QUESTION 3
clear;

a = [0 10 0 10]';
b = [0 0 10 10]';
sigma_r = 0.5;
r2 = [25 65 45 85]' + sigma_r*randn(4,1);
H_func = @(x, y) [2*(x-a) 2*(y-b)];

s_hat = [0 0]';
ds = 1e3;
while ds > 1e-4
    r2_hat = (s_hat(1) - a).^2 + (s_hat(2) - b).^2;
    H = H_func(s_hat(1), s_hat(2));
    ds = pinv(H)*(r2 - r2_hat);
    s_hat = s_hat + ds;
end
P = sigma_r*sigma_r*inv(H'*H);
fprintf('3c) Position Solution: [%0.2g, %0.2g]\n\n', s_hat);

%% QUESTION 4
clear;

filename = 'HW2_data.txt';
T = readlines(filename);
sv_pos = zeros(length(T)-4, 3);
rho = zeros(length(T)-4,1);
sigma_r = 0.5;  % [m]
for i = 4:length(T)
    data = strsplit(T(i));
    sv_pos(i-3,1) = str2double(data(2));
    sv_pos(i-3,2) = str2double(data(3));
    sv_pos(i-3,3) = str2double(data(4));
    rho(i-3) = str2double(data(5));
end

X0 = [0 0 0 0];

first4 = GPS_LS(rho(1:4), sv_pos(1:4,:), X0);
all9 = GPS_LS(rho(1:9), sv_pos(1:9, :), X0);

rho_corr = rho(1:9) + all9(:,4);
perfClock = GPS_LS(rho_corr(1:4), sv_pos(1:4, :), X0);

comb_rho = [rho(1:2); rho(10:11)];
comb_sv_pos = [sv_pos(1:2,:); sv_pos(10:11,:)];
X0_guess = [423000, -5362000, 3417000 all9(:,4)];
gpsSOOP = GPS_LS(comb_rho, comb_sv_pos, X0_guess);

fprintf('4a) Position Solution from 4 Satellites: [%0.6g, %0.6g, %0.6g, %0.6g]\n', first4);
fprintf('4b) Position Solution from 9 Satellites: [%0.6g, %0.6g, %0.6g, %0.6g]\n', all9);
fprintf('4c) Position Solution w/ Perfect Clock: [%0.6g, %0.6g, %0.6g, %0.6g]\n', perfClock);
fprintf('4d) This results in an infinite loop.\n');
fprintf('4e) Position Solution w/ 2 GPS SVs and 2 SOOPs: [%0.6g, %0.6g, %0.6g, %0.6g]\n\n', gpsSOOP);

%% QUESTION 5
A1 = 5e-9; % [s]
I_error = @(theta) A1.*(1 + 16.*(0.53 - (theta./180)).^3);
ang = @(z, r) asind(z./r);
diff = (sv_pos - all9(1:3));
z = diff(:,3);
angles = ang(z, rho);
errors = I_error(angles);

figure();
plot(angles, errors, 'o');
title('Angle vs. Ionospheric Errors');
xlabel("Angles (deg)");
ylabel("Error");

%% QUESTION 5 - ALTERNATIVE
Xu = all9;
idx = 1;
angle_range = 0:1:40;
HDOP = zeros(length(angle_range),2);
VDOP = zeros(length(angle_range),1);
TDOP = zeros(length(angle_range),1);
for a = angle_range
    diff = (sv_pos - Xu(1:3));
    z = diff(:,3);
    angles = ang(z, rho);
    rho_cut = rho(angles > a);
    sv_pos_cut = sv_pos(angles > a, :);
    angles_cut = angles(angles > a);
    if length(rho_cut) >= 4
        dx = 1e3*ones(4,1);
        while norm(dx) > 1e-4
            r = vecnorm((sv_pos_cut - Xu(1:3)), 2, 2);
            U = (sv_pos_cut - Xu(1:3))./r;
            H = [-U ones(length(U),1)];
            rho_hat = r + Xu(4) + I_error(angles_cut);
            dx = pinv(H)*(rho_cut - rho_hat);
            Xu = Xu + dx';
        end
        P = sigma_r*inv(H'*H);
        HDOP(idx, :) = sqrt(P(1,1)^2 + P(2,2)^2);
        VDOP(idx, :) = [P(3,3)];
        TDOP(idx, :) = [P(4,4)];
        idx = idx + 1;
    else
        break;
    end
end

figure();
hold on
plot(angle_range, HDOP, '*');
plot(angle_range, VDOP, 'o');
plot(angle_range, TDOP, 'x');
title("DOP vs. Mask Angle");
xlabel("Angle (deg)");
ylabel("DOP");
legend('HDOP', 'VDOP', 'TDOP');

%% FUNCTIONS
function [state, idx] = LS(y, H, state)
    ds = 1e3;
    idx = 0;
    while ds > 1e-4
        y_hat = H*state;
        ds = pinv(H)*(y - y_hat);
        state = state + ds;
        idx = idx + 1;
    end
end

function [Xu, H] = GPS_LS(rho, Xs, Xu)
    dx = 1e3*ones(4,1);
    while norm(dx) > 1e-4
        r = vecnorm((Xs - Xu(1:3)), 2, 2);
        U = (Xs - Xu(1:3))./r;
        H = [-U ones(length(U),1)];
        rho_hat = r + Xu(4);
        dx = pinv(H)*(rho - rho_hat);
        Xu = Xu + dx';
    end
end