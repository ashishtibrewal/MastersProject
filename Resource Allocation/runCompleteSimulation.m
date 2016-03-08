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
numRequests = 10;     % Total number of requests to generate

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input generation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TODO move input generation code here to keep the requests generated
% consistent across all simulations

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Type 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str = sprintf('Running simulation for Type 1 ....\n');
disp(str);

% Import configuration file (YAML config files)
yaml_configFile = 'config/configType1.yaml';    % File to import (File path)
dataCenterConfig = ReadYaml(yaml_configFile);   % Read file and store it into a struct called dataCenterConfig
[requestDB_1, dataCenterMap_T1] = simStart(dataCenterConfig, numRequests);

str = sprintf('\nx-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x\n');
disp(str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Type 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str = sprintf('Running simulation for Type 2 ....\n');
disp(str);

% Import configuration file (YAML config files)
yaml_configFile = 'config/configType2.yaml';    % File to import (File path)
dataCenterConfig = ReadYaml(yaml_configFile);   % Read file and store it into a struct called dataCenterConfig
[requestDB_2, dataCenterMap_T2] = simStart(dataCenterConfig, numRequests);

str = sprintf('\nx-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x\n');
disp(str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Type 3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str = sprintf('Running simulation for Type 3 ....\n');
disp(str);

% Import configuration file (YAML config files)
yaml_configFile = 'config/configType3.yaml';    % File to import (File path)
dataCenterConfig = ReadYaml(yaml_configFile);   % Read file and store it into a struct called dataCenterConfig
[requestDB_3, dataCenterMap_T3] = simStart(dataCenterConfig, numRequests);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot results/graphs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NEED TO THINK OF GRAPHS THAT CAN BE PLOTTED TO DEPICT SIMULATION RESULTS
nRequests = numRequests; % Number of requests generated
tTime = nRequests;       % Total time simulated
time = 1:tTime;

% BLOCKING PROBABILITY (Request vs BP)
nBlocked_T1 = zeros(1,size(time,2));
nBlocked_T2 = zeros(1,size(time,2));
nBlocked_T3 = zeros(1,size(time,2));
% Main time loop
for t = 1:tTime
  blocked_T1 = find(cell2mat(requestDB_1(1:t,11)) == 0);    % Find requests that have been blocked upto time t
  blocked_T2 = find(cell2mat(requestDB_2(1:t,11)) == 0);    % Find requests that have been blocked upto time t
  blocked_T3 = find(cell2mat(requestDB_3(1:t,11)) == 0);    % Find requests that have been blocked upto time t
  nBlocked_T1(t) = size(blocked_T1,1);                      % Count the number of requests found
  nBlocked_T2(t) = size(blocked_T2,1);                      % Count the number of requests found
  nBlocked_T3(t) = size(blocked_T3,1);                      % Count the number of requests found
end

%yFactor = eps;
yFactor = 1/(2 * nRequests);
figure ('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
semilogy(time,max(yFactor,(nBlocked_T1/nRequests)),'x-');
hold on;
semilogy(time,max(yFactor,(nBlocked_T2/nRequests)),'x-');
semilogy(time,max(yFactor,(nBlocked_T3/nRequests)),'x-');
xlabel('Request no.');
ylabel('Blocking probability');
legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
title('Blocking probability');

% BLOCKING PROBABILITY (CPU,MEM,STO Utilisation vs BP)
nBlocked_T1 = zeros(1,size(time,2));
nBlocked_T2 = zeros(1,size(time,2));
nBlocked_T3 = zeros(1,size(time,2));
nUnits = 8;
totalCPUunits_T1 = size(dataCenterMap_T1.locationMap.CPUs,2) * nUnits;
totalMEMunits_T1 = size(dataCenterMap_T1.locationMap.MEMs,2) * nUnits;
totalSTOunits_T1 = size(dataCenterMap_T1.locationMap.STOs,2) * nUnits;
totalCPUunits_T2 = size(dataCenterMap_T2.locationMap.CPUs,2) * nUnits;
totalMEMunits_T2 = size(dataCenterMap_T2.locationMap.MEMs,2) * nUnits;
totalSTOunits_T2 = size(dataCenterMap_T2.locationMap.STOs,2) * nUnits;
totalCPUunits_T3 = size(dataCenterMap_T3.locationMap.CPUs,2) * nUnits;
totalMEMunits_T3 = size(dataCenterMap_T3.locationMap.MEMs,2) * nUnits;
totalSTOunits_T3 = size(dataCenterMap_T3.locationMap.STOs,2) * nUnits;
totalCPUunitsUtilized_T1 = zeros(1,size(time,2));
totalMEMunitsUtilized_T1 = zeros(1,size(time,2));
totalSTOunitsUtilized_T1 = zeros(1,size(time,2));
totalCPUunitsUtilized_T2 = zeros(1,size(time,2));
totalMEMunitsUtilized_T2 = zeros(1,size(time,2));
totalSTOunitsUtilized_T2 = zeros(1,size(time,2));
totalCPUunitsUtilized_T3 = zeros(1,size(time,2));
totalMEMunitsUtilized_T3 = zeros(1,size(time,2));
totalSTOunitsUtilized_T3 = zeros(1,size(time,2));
CPUutilization_T1 = zeros(1,size(time,2));
MEMutilization_T1 = zeros(1,size(time,2));
STOutilization_T1 = zeros(1,size(time,2));
CPUutilization_T2 = zeros(1,size(time,2));
MEMutilization_T2 = zeros(1,size(time,2));
STOutilization_T2 = zeros(1,size(time,2));
CPUutilization_T3 = zeros(1,size(time,2));
MEMutilization_T3 = zeros(1,size(time,2));
STOutilization_T3 = zeros(1,size(time,2));
% Main time loop
for t = 1:tTime
  % Type 1
  CPUunitsUtilized_T1 = [];
  MEMunitsUtilized_T1 = [];
  STOunitsUtilized_T1 = [];
  allocatedResources_T1 = requestDB_1{t,12};
  for i = 1:size(allocatedResources_T1,1)
    for j = 1:size(allocatedResources_T1,2)
      % Extract current cell from the heldITresources cell array
      currentCell = allocatedResources_T1{i,j};
      if (~isempty(currentCell))
        switch (i)
          % CPU nodes
          case 1
            CPUunitsUtilized_T1 = [CPUunitsUtilized_T1, currentCell{2}];
          % MEM nodes
          case 2
            MEMunitsUtilized_T1 = [MEMunitsUtilized_T1, currentCell{2}];
          % STO nodes
          case 3
            STOunitsUtilized_T1 = [STOunitsUtilized_T1, currentCell{2}];
        end
      end
    end
  end

  
  totalCPUunitsUtilized_T1(t) = sum(CPUunitsUtilized_T1,2);
  totalMEMunitsUtilized_T1(t) = sum(MEMunitsUtilized_T1,2);
  totalSTOunitsUtilized_T1(t) = sum(STOunitsUtilized_T1,2);
  
  if (t > 1)
    CPUutilization_T1(t) = ((totalCPUunitsUtilized_T1(t)/totalCPUunits_T1) * 100) + CPUutilization_T1((t - 1));
    MEMutilization_T1(t) = ((totalMEMunitsUtilized_T1(t)/totalMEMunits_T1) * 100) + MEMutilization_T1((t - 1));
    STOutilization_T1(t) = ((totalSTOunitsUtilized_T1(t)/totalSTOunits_T1) * 100) + STOutilization_T1((t - 1));
  else
    CPUutilization_T1(t) = totalCPUunitsUtilized_T1(t)/totalCPUunits_T1;
    MEMutilization_T1(t) = totalMEMunitsUtilized_T1(t)/totalMEMunits_T1;
    STOutilization_T1(t) = totalSTOunitsUtilized_T1(t)/totalSTOunits_T1;
  end
  
  % Type 2
  CPUunitsUtilized_T2 = [];
  MEMunitsUtilized_T2 = [];
  STOunitsUtilized_T2 = [];
  allocatedResources_DB2 = requestDB_2{t,12};
  for i = 1:size(allocatedResources_DB2,1)
    for j = 1:size(allocatedResources_DB2,2)
      % Extract current cell from the heldITresources cell array
      currentCell = allocatedResources_DB2{i,j};
      if (~isempty(currentCell))
        switch (i)
          % CPU nodes
          case 1
            CPUunitsUtilized_T2 = [CPUunitsUtilized_T2, currentCell{2}];
          % MEM nodes
          case 2
            MEMunitsUtilized_T2 = [MEMunitsUtilized_T2, currentCell{2}];
          % STO nodes
          case 3
            STOunitsUtilized_T2 = [STOunitsUtilized_T2, currentCell{2}];
        end
      end
    end
  end
  
  totalCPUunitsUtilized_T2(t) = sum(CPUunitsUtilized_T2,2);
  totalMEMunitsUtilized_T2(t) = sum(MEMunitsUtilized_T2,2);
  totalSTOunitsUtilized_T2(t) = sum(STOunitsUtilized_T2,2);
  
  if (t > 1)
    CPUutilization_T2(t) = ((totalCPUunitsUtilized_T2(t)/totalCPUunits_T2) * 100) + CPUutilization_T2((t - 1));
    MEMutilization_T2(t) = ((totalMEMunitsUtilized_T2(t)/totalMEMunits_T2) * 100) + MEMutilization_T2((t - 1));
    STOutilization_T2(t) = ((totalSTOunitsUtilized_T2(t)/totalSTOunits_T2) * 100) + STOutilization_T2((t - 1));
  else
    CPUutilization_T2(t) = totalCPUunitsUtilized_T2(t)/totalCPUunits_T2;
    MEMutilization_T2(t) = totalMEMunitsUtilized_T2(t)/totalMEMunits_T2;
    STOutilization_T2(t) = totalSTOunitsUtilized_T2(t)/totalSTOunits_T2;
  end
  
  % Type 3
  CPUunitsUtilized_T3 = [];
  MEMunitsUtilized_T3 = [];
  STOunitsUtilized_T3 = [];
  allocatedResources_DB3 = requestDB_3{t,12};
  for i = 1:size(allocatedResources_DB3,1)
    for j = 1:size(allocatedResources_DB3,2)
      % Extract current cell from the heldITresources cell array
      currentCell = allocatedResources_DB3{i,j};
      if (~isempty(currentCell))
        switch (i)
          % CPU nodes
          case 1
            CPUunitsUtilized_T3 = [CPUunitsUtilized_T3, currentCell{2}];
          % MEM nodes
          case 2
            MEMunitsUtilized_T3 = [MEMunitsUtilized_T3, currentCell{2}];
          % STO nodes
          case 3
            STOunitsUtilized_T3 = [STOunitsUtilized_T3, currentCell{2}];
        end
      end
    end
  end
  
  totalCPUunitsUtilized_T3(t) = sum(CPUunitsUtilized_T3,2);
  totalMEMunitsUtilized_T3(t) = sum(MEMunitsUtilized_T3,2);
  totalSTOunitsUtilized_T3(t) = sum(STOunitsUtilized_T3,2);
  
  if (t > 1)
    CPUutilization_T3(t) = ((totalCPUunitsUtilized_T3(t)/totalCPUunits_T3) * 100) + CPUutilization_T3((t - 1));
    MEMutilization_T3(t) = ((totalMEMunitsUtilized_T3(t)/totalMEMunits_T3) * 100) + MEMutilization_T3((t - 1));
    STOutilization_T3(t) = ((totalSTOunitsUtilized_T3(t)/totalSTOunits_T3) * 100) + STOutilization_T3((t - 1));
  else
    CPUutilization_T3(t) = totalCPUunitsUtilized_T3(t)/totalCPUunits_T3;
    MEMutilization_T3(t) = totalMEMunitsUtilized_T3(t)/totalMEMunits_T3;
    STOutilization_T3(t) = totalSTOunitsUtilized_T3(t)/totalSTOunits_T3;
  end
  
  blocked_T1 = find(cell2mat(requestDB_1(1:t,11)) == 0);    % Find requests that have been blocked upto time t
  blocked_T2 = find(cell2mat(requestDB_2(1:t,11)) == 0);    % Find requests that have been blocked upto time t
  blocked_T3 = find(cell2mat(requestDB_3(1:t,11)) == 0);    % Find requests that have been blocked upto time t
  nBlocked_T1(t) = size(blocked_T1,1);                      % Count the number of requests found
  nBlocked_T2(t) = size(blocked_T2,1);                      % Count the number of requests found
  nBlocked_T3(t) = size(blocked_T3,1);                      % Count the number of requests found
end

figure ('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
semilogy(CPUutilization_T1,(nBlocked_T1/nRequests),'x-');
hold on;
semilogy(CPUutilization_T2,(nBlocked_T2/nRequests),'x-');
semilogy(CPUutilization_T3,(nBlocked_T3/nRequests),'x-');
xlabel('CPU utilization');
ylabel('Blocking probability');
legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
title('Blocking probability');

figure ('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
semilogy(MEMutilization_T1,(nBlocked_T1/nRequests),'x-');
hold on;
semilogy(MEMutilization_T2,(nBlocked_T2/nRequests),'x-');
semilogy(MEMutilization_T3,(nBlocked_T3/nRequests),'x-');
xlabel('CPU utilization');
ylabel('Blocking probability');
legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
title('Blocking probability');

figure ('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
semilogy(STOutilization_T1,(nBlocked_T1/nRequests),'x-');
hold on;
semilogy(STOutilization_T2,(nBlocked_T2/nRequests),'x-');
semilogy(STOutilization_T3,(nBlocked_T3/nRequests),'x-');
xlabel('CPU utilization');
ylabel('Blocking probability');
legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
title('Blocking probability');

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