%%+++++++++++++++++++++++++++++++++++++%%
%%% Script that runs all simualtions  %%%
%%+++++++++++++++++++++++++++++++++++++%%

% Script to automate/run the complete simulation with different
% data-center, resource pool setups.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up clean environment and logging functionality
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
diaryFileName = 'log/log.txt';  % Log file name/path
diary(diaryFileName);           % Create new diary with the specified file name
clear;                          % Clear all variables in the workspace
close all;                      % Close all open figures
clc;                            % Clear console/command prompt
diary on;                       % Turn diary (i.e. logging functionality) on
str = sprintf('\n+-------- SIMULATION STARTED --------+\n');
disp(str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Miscellaneous simulation "variables" (including macros)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Macro definitions
global SUCCESS;       % Declare macro as global
global FAILURE;       % Declare macro as global
SUCCESS = 1;          % Assign a value to global macro
FAILURE = 0;          % Assign a value to global macro


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Evaluate constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numRequests = 1000;     % Total number of requests to generate

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Type 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str = sprintf('Running simulation for Type 1 ....\n');
disp(str);

yaml_configFile = 'config/configType1.yaml';  % File to import (File path)
requestDB_1 = simStart(yaml_configFile, numRequests);

str = sprintf('\nx-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x\n');
disp(str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Type 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str = sprintf('Running simulation for Type 2 ....\n');
disp(str);

yaml_configFile = 'config/configType2.yaml';  % File to import (File path)
requestDB_2 = simStart(yaml_configFile, numRequests);

str = sprintf('\nx-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x\n');
disp(str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Type 3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str = sprintf('Running simulation for Type 3 ....\n');
disp(str);

yaml_configFile = 'config/configType3.yaml';  % File to import (File path)
requestDB_3 = simStart(yaml_configFile, numRequests);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot results/graphs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NEED TO THINK OF GRAPHS THAT CAN BE PLOTTED TO DEPICT SIMULATION RESULTS

% BLOCKING PROBABILITY (Request vs BP)
nRequests = numRequests; % Number of requests generated
tTime = nRequests;       % Total time simulated
time = 1:tTime;
nBlocked_1 = zeros(1,size(time,2));
nBlocked_2 = zeros(1,size(time,2));
nBlocked_3 = zeros(1,size(time,2));
% Main time loop
for t = 1:tTime
  blocked_1 = find(cell2mat(requestDB_1(1:t,11)) == 0);    % Find requests that have been blocked upto time t
  blocked_2 = find(cell2mat(requestDB_2(1:t,11)) == 0);    % Find requests that have been blocked upto time t
  blocked_3 = find(cell2mat(requestDB_3(1:t,11)) == 0);    % Find requests that have been blocked upto time t
  nBlocked_1(t) = size(blocked_1,1);                      % Count the number of requests found
  nBlocked_2(t) = size(blocked_2,1);                      % Count the number of requests found
  nBlocked_3(t) = size(blocked_3,1);                      % Count the number of requests found
end

%yFactor = eps;
yFactor = 1/(2 * nRequests);
figure ('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
semilogy(time,max(yFactor,(nBlocked_1/nRequests)),'x-');
hold on;
semilogy(time,max(yFactor,(nBlocked_2/nRequests)),'x-');
semilogy(time,max(yFactor,(nBlocked_3/nRequests)),'x-');
xlabel('Request no.');
ylabel('Blocking probability');
legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
title('Blocking probability');

% BLOCKING PROBABILITY (CPU,MEM,STO Utilisation vs BP)

% LATENCY ALLOCATION (REQUEST group vs LATENCY ALLOCATED - min, average, max graph)

% UTILIZATION (REQUEST group vs NET,CPU,MEM,STO utilisation)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clean up & display log
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str = sprintf('\n+------- SIMULATION COMPLETE --------+\n');
disp(str);
diary off;                       % Turn diary (i.e. logging functionality) off
%clear;
str = sprintf('Opening simulation log ...');
disp(str);
open('log/log.txt');