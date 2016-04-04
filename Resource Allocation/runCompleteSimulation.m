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
numTypes = 3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Import configuration files (YAML config files)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Import Type 1 configuration file
yaml_configFile_T1 = 'config/configType1.yaml';    % File to import (File path)
dataCenterConfig_T1 = ReadYaml(yaml_configFile_T1);   % Read file and store it into a struct called dataCenterConfig

% Import Type 2 configuration file
yaml_configFile_T2 = 'config/configType2.yaml';    % File to import (File path)
dataCenterConfig_T2 = ReadYaml(yaml_configFile_T2);   % Read file and store it into a struct called dataCenterConfig

% Import Type 3 configuration file
yaml_configFile_T3 = 'config/configType3.yaml';    % File to import (File path)
dataCenterConfig_T3 = ReadYaml(yaml_configFile_T3);   % Read file and store it into a struct called dataCenterConfig

% Type independent configuration file
dataCenterConfig = dataCenterConfig_T1;         % Store it as a separate variable to be able to extract common elements for all configuration types

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input generation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Inputs generated here to keep it consistent across all simulations
str = sprintf('Input generation started ...');
disp(str);

requestDB = inputGeneration(numRequests);    % Pre-generating randomised requests - Note that the resource allocation is only allowed to look at the request for the current iteration

str = sprintf('Input generation complete.\n');
disp(str);

% Start timer
tic;

% Initialize variables to be able to use in the main paralllel loop (parfor)
requestDB_T1 = [];
dataCenterMap_T1 = [];
requestDB_T2 = [];
dataCenterMap_T2 = [];
requestDB_T3 = [];
dataCenterMap_T3 = [];

% Start parallel for loop to run multiple threads
parfor i = 1:numTypes
  type = i;     % Type of configuration/setup
  switch (i)
    case 1
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Type 1
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      str = sprintf('Running simulation for Type 1 ....\n');
      disp(str);

      [requestDB_T1_L, dataCenterMap_T1_L] = simStart(dataCenterConfig_T1, numRequests, requestDB, type);
      requestDB_T1 = [requestDB_T1, requestDB_T1_L];
      dataCenterMap_T1 = [dataCenterMap_T1, dataCenterMap_T1_L];

    case 2
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Type 2
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      str = sprintf('Running simulation for Type 2 ....\n');
      disp(str);

      [requestDB_T2_L, dataCenterMap_T2_L] = simStart(dataCenterConfig_T2, numRequests, requestDB, type);
      requestDB_T2 = [requestDB_T2, requestDB_T2_L];
      dataCenterMap_T2 = [dataCenterMap_T2, dataCenterMap_T2_L];

    case 3
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Type 3
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      str = sprintf('Running simulation for Type 3 ....\n');
      disp(str);

      [requestDB_T3_L, dataCenterMap_T3_L] = simStart(dataCenterConfig_T3, numRequests, requestDB, type);
      requestDB_T3 = [requestDB_T3, requestDB_T3_L];
      dataCenterMap_T3 = [dataCenterMap_T3, dataCenterMap_T3_L];
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate and plot results (Analysis)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str = sprintf('Displaying results (Type 1) ...');
disp(str);

displayResults(dataCenterMap_T1, requestDB_T1, numRequests, dataCenterConfig_T1);

str = sprintf('\nDisplaying results (Type 2) ...');
disp(str);

displayResults(dataCenterMap_T2, requestDB_T2, numRequests, dataCenterConfig_T2);

str = sprintf('\nDisplaying results (Type 3) ...');
disp(str);

displayResults(dataCenterMap_T3, requestDB_T3, numRequests, dataCenterConfig_T3);

% Stop timer and print its value
toc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot results/graphs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NEED TO THINK OF GRAPHS THAT CAN BE PLOTTED TO DEPICT SIMULATION RESULTS

% Plot heat maps
plotHeatMap(dataCenterConfig_T1, dataCenterMap_T1, 'allMapsSetup');
plotHeatMap(dataCenterConfig_T2, dataCenterMap_T2, 'allMapsSetup');
plotHeatMap(dataCenterConfig_T3, dataCenterMap_T3, 'allMapsSetup');

nRequests = numRequests; % Number of requests generated
tTime = nRequests;       % Total time simulated
time = 1:tTime;

% BLOCKING PROBABILITY (Request vs BP)
nBlocked_T1 = zeros(1,size(time,2));
nBlocked_T2 = zeros(1,size(time,2));
nBlocked_T3 = zeros(1,size(time,2));
% Main time loop
for t = 1:tTime
  blocked_T1 = find(cell2mat(requestDB_T1(1:t,11)) == 0);    % Find requests that have been blocked upto time t
  blocked_T2 = find(cell2mat(requestDB_T2(1:t,11)) == 0);    % Find requests that have been blocked upto time t
  blocked_T3 = find(cell2mat(requestDB_T3(1:t,11)) == 0);    % Find requests that have been blocked upto time t
  nBlocked_T1(t) = size(blocked_T1,1);                      % Count the number of requests found
  nBlocked_T2(t) = size(blocked_T2,1);                      % Count the number of requests found
  nBlocked_T3(t) = size(blocked_T3,1);                      % Count the number of requests found
end

%yFactor = eps;               % Set to epsilon to avoid going to -inf
%yFactor = 1/(2 * nRequests);  % Set to half the maximum blocking probability to avoid going to -inf
yFactor = 0;
figure ('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
semilogy(time,max(yFactor,(nBlocked_T1/nRequests)),'x-');
hold on;
semilogy(time,max(yFactor,(nBlocked_T2/nRequests)),'x-');
semilogy(time,max(yFactor,(nBlocked_T3/nRequests)),'x-');
xlabel('Request no.');
ylabel('Blocking probability');
legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
title('Request no. vs Blocking probability');

% BLOCKING PROBABILITY (CPU,MEM,STO utilization vs BP)
nBlocked_T1 = zeros(1,size(time,2));
nBlocked_T2 = zeros(1,size(time,2));
nBlocked_T3 = zeros(1,size(time,2));
nUnits = dataCenterConfig.nUnits;
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
totalNETutilized_T1 = zeros(1,size(time,2));
totalNETutilized_T2 = zeros(1,size(time,2));
totalNETutilized_T3 = zeros(1,size(time,2));
NETutilization_T1 = zeros(1,size(time,2));
NETutilization_T2 = zeros(1,size(time,2));
NETutilization_T3 = zeros(1,size(time,2));
completeResourceMap_T1 = dataCenterMap_T1.completeResourceMap;
completeResourceMap_T2 = dataCenterMap_T2.completeResourceMap;
completeResourceMap_T3 = dataCenterMap_T3.completeResourceMap;
maxLatency_T1 = zeros(1,size(time,2));
minLatency_T1 = zeros(1,size(time,2));
averageLatency_T1 = zeros(1,size(time,2));
reqLatencyCM_T1 = zeros(1,size(time,2));
reqLatencyMS_T1 = zeros(1,size(time,2));
maxLatency_T2 = zeros(1,size(time,2));
minLatency_T2 = zeros(1,size(time,2));
averageLatency_T2 = zeros(1,size(time,2));
reqLatencyCM_T2 = zeros(1,size(time,2));
reqLatencyMS_T2 = zeros(1,size(time,2));
maxLatency_T3 = zeros(1,size(time,2));
minLatency_T3 = zeros(1,size(time,2));
averageLatency_T3 = zeros(1,size(time,2));
reqLatencyCM_T3 = zeros(1,size(time,2));
reqLatencyMS_T3 = zeros(1,size(time,2));

% Evaluate total bandwidth - Type 1
bandwidthMap_T1 = dataCenterMap_T1.bandwidthMap.completeBandwidthOriginal;
totalNET_T1 = 0;
for i = 1:size(bandwidthMap_T1,1)
  for j = (i + 1):size(bandwidthMap_T1,2)
    totalNET_T1 = totalNET_T1 + bandwidthMap_T1(i,j);
  end
end

% Evaluate total bandwidth - Type 2
bandwidthMap_T2 = dataCenterMap_T2.bandwidthMap.completeBandwidthOriginal;
totalNET_T2 = 0;
for i = 1:size(bandwidthMap_T2,1)
  for j = (i + 1):size(bandwidthMap_T2,2)
    totalNET_T2 = totalNET_T2 + bandwidthMap_T2(i,j);
  end
end

% Evaluate total bandwidth - Type 3
bandwidthMap_T3 = dataCenterMap_T3.bandwidthMap.completeBandwidthOriginal;
totalNET_T3 = 0;
for i = 1:size(bandwidthMap_T3,1)
  for j = (i + 1):size(bandwidthMap_T3,2)
    totalNET_T3 = totalNET_T3 + bandwidthMap_T3(i,j);
  end
end

% Main time loop
for t = 1:tTime
  % Type 1 IT resource utilization
  CPUunitsUtilized_T1 = 0;
  MEMunitsUtilized_T1 = 0;
  STOunitsUtilized_T1 = 0;
  allocatedResources_T1 = requestDB_T1{t,12};
  for i = 1:size(allocatedResources_T1,1)
    for j = 1:size(allocatedResources_T1,2)
      % Extract current cell from the heldITresources cell array
      NETcell = allocatedResources_T1{i,j};
      if (~isempty(NETcell))
        switch (i)
          % CPU nodes
          case 1
            CPUunitsUtilized_T1 = [CPUunitsUtilized_T1, NETcell{2}];
          % MEM nodes
          case 2
            MEMunitsUtilized_T1 = [MEMunitsUtilized_T1, NETcell{2}];
          % STO nodes
          case 3
            STOunitsUtilized_T1 = [STOunitsUtilized_T1, NETcell{2}];
        end
      end
    end
  end

  if (t == 1)
    totalCPUunitsUtilized_T1(t) = sum(CPUunitsUtilized_T1,2);
    totalMEMunitsUtilized_T1(t) = sum(MEMunitsUtilized_T1,2);
    totalSTOunitsUtilized_T1(t) = sum(STOunitsUtilized_T1,2);
  else
    totalCPUunitsUtilized_T1(t) = sum(CPUunitsUtilized_T1,2) + totalCPUunitsUtilized_T1((t - 1));
    totalMEMunitsUtilized_T1(t) = sum(MEMunitsUtilized_T1,2) + totalMEMunitsUtilized_T1((t - 1));
    totalSTOunitsUtilized_T1(t) = sum(STOunitsUtilized_T1,2) + totalSTOunitsUtilized_T1((t - 1));
  end
  
  CPUutilization_T1(t) = (totalCPUunitsUtilized_T1(t)/totalCPUunits_T1) * 100;
  MEMutilization_T1(t) = (totalMEMunitsUtilized_T1(t)/totalMEMunits_T1) * 100;
  STOutilization_T1(t) = (totalSTOunitsUtilized_T1(t)/totalSTOunits_T1) * 100;
  
  % Type 2 IT resource utilization
  CPUunitsUtilized_T2 = 0;
  MEMunitsUtilized_T2 = 0;
  STOunitsUtilized_T2 = 0;
  allocatedResources_DB2 = requestDB_T2{t,12};
  for i = 1:size(allocatedResources_DB2,1)
    for j = 1:size(allocatedResources_DB2,2)
      % Extract current cell from the heldITresources cell array
      NETcell = allocatedResources_DB2{i,j};
      if (~isempty(NETcell))
        switch (i)
          % CPU nodes
          case 1
            CPUunitsUtilized_T2 = [CPUunitsUtilized_T2, NETcell{2}];
          % MEM nodes
          case 2
            MEMunitsUtilized_T2 = [MEMunitsUtilized_T2, NETcell{2}];
          % STO nodes
          case 3
            STOunitsUtilized_T2 = [STOunitsUtilized_T2, NETcell{2}];
        end
      end
    end
  end
  
  if (t == 1)
    totalCPUunitsUtilized_T2(t) = sum(CPUunitsUtilized_T2,2);
    totalMEMunitsUtilized_T2(t) = sum(MEMunitsUtilized_T2,2);
    totalSTOunitsUtilized_T2(t) = sum(STOunitsUtilized_T2,2);
  else
    totalCPUunitsUtilized_T2(t) = sum(CPUunitsUtilized_T2,2) + totalCPUunitsUtilized_T2((t - 1));
    totalMEMunitsUtilized_T2(t) = sum(MEMunitsUtilized_T2,2) + totalMEMunitsUtilized_T2((t - 1));
    totalSTOunitsUtilized_T2(t) = sum(STOunitsUtilized_T2,2) + totalSTOunitsUtilized_T2((t - 1));
  end
  
  CPUutilization_T2(t) = (totalCPUunitsUtilized_T2(t)/totalCPUunits_T2) * 100;
  MEMutilization_T2(t) = (totalMEMunitsUtilized_T2(t)/totalMEMunits_T2) * 100;
  STOutilization_T2(t) = (totalSTOunitsUtilized_T2(t)/totalSTOunits_T2) * 100;
  
  % Type 3 IT resource utilization
  CPUunitsUtilized_T3 = 0;
  MEMunitsUtilized_T3 = 0;
  STOunitsUtilized_T3 = 0;
  allocatedResources_DB3 = requestDB_T3{t,12};
  for i = 1:size(allocatedResources_DB3,1)
    for j = 1:size(allocatedResources_DB3,2)
      % Extract current cell from the heldITresources cell array
      NETcell = allocatedResources_DB3{i,j};
      if (~isempty(NETcell))
        switch (i)
          % CPU nodes
          case 1
            CPUunitsUtilized_T3 = [CPUunitsUtilized_T3, NETcell{2}];
          % MEM nodes
          case 2
            MEMunitsUtilized_T3 = [MEMunitsUtilized_T3, NETcell{2}];
          % STO nodes
          case 3
            STOunitsUtilized_T3 = [STOunitsUtilized_T3, NETcell{2}];
        end
      end
    end
  end
  
  if (t == 1)
    totalCPUunitsUtilized_T3(t) = sum(CPUunitsUtilized_T3,2);
    totalMEMunitsUtilized_T3(t) = sum(MEMunitsUtilized_T3,2);
    totalSTOunitsUtilized_T3(t) = sum(STOunitsUtilized_T3,2);
  else
    totalCPUunitsUtilized_T3(t) = sum(CPUunitsUtilized_T3,2) + totalCPUunitsUtilized_T3((t - 1));
    totalMEMunitsUtilized_T3(t) = sum(MEMunitsUtilized_T3,2) + totalMEMunitsUtilized_T3((t - 1));
    totalSTOunitsUtilized_T3(t) = sum(STOunitsUtilized_T3,2) + totalSTOunitsUtilized_T3((t - 1));
  end
  
  CPUutilization_T3(t) = (totalCPUunitsUtilized_T3(t)/totalCPUunits_T3) * 100;
  MEMutilization_T3(t) = (totalMEMunitsUtilized_T3(t)/totalMEMunits_T3) * 100;
  STOutilization_T3(t) = (totalSTOunitsUtilized_T3(t)/totalSTOunits_T3) * 100;
  
  % Type 1 network utilization
  NETutilized_T1 = 0;
  requestBAN_CM = requestDB_T1{t,4};
  requestBAN_MS = requestDB_T1{t,5};
  allocatedNETresources_DB1 = requestDB_T1{t,13};
  allocatedITresources_DB1 = requestDB_T1{t,12};
  for i = 1:size(allocatedNETresources_DB1,1)
    for j = 1:size(allocatedNETresources_DB1,2)
      % Extract current cell from the heldITresources cell array
      NETcell = allocatedNETresources_DB1{i,j};
      if (~isempty(NETcell))
        NETmatrix = cell2mat(NETcell);
        NETmatrixSize = size(NETmatrix,2);
        startNode = char(completeResourceMap_T1(NETmatrix(1)));
        endNode = char(completeResourceMap_T1(NETmatrix(NETmatrixSize)));
        
        % Find number of units used in source and destination nodes
        unitsSource = 0;
        unitsDest = 0;
        for p = 1:size(allocatedITresources_DB1,1)
          for q = 1:size(allocatedITresources_DB1,2)
            ITcell = allocatedITresources_DB1{p,q};
            if (~isempty(ITcell))
              ITmatrix = cell2mat(ITcell);
              % Source units
              if (ITmatrix(1) == NETmatrix(1))
                unitsSource = ITmatrix(2);
              % Destination units
              elseif (ITmatrix(1) == NETmatrix(NETmatrixSize))
                unitsDest = ITmatrix(2);
              end
            end
          end
        end
        
        % Find the maximum units allocated out of source and destination nodes
        unitsMax = max(unitsSource,unitsDest);
        
        % Switch on the start node in the path
        switch (startNode)
          % CPU start node
          case 'CPU'
            if (strcmp(endNode,'CPU') || strcmp(endNode,'MEM'))
              NETutilized_T1 = NETutilized_T1 + ((NETmatrixSize - 1) * requestBAN_CM) * unitsMax;
            elseif (strcmp(endNode,'STO'))
              NETutilized_T1 = NETutilized_T1 + ((NETmatrixSize - 1) * requestBAN_MS) * unitsMax;
            end
            
          % MEM start node
          case 'MEM'
            if (strcmp(endNode,'CPU'))
              NETutilized_T1 = NETutilized_T1 + ((NETmatrixSize - 1) * requestBAN_CM) * unitsMax;
            elseif (strcmp(endNode,'MEM') || strcmp(endNode,'STO'))
              NETutilized_T1 = NETutilized_T1 + ((NETmatrixSize - 1) * requestBAN_MS) * unitsMax;
            end
            
          % STO start node
          case 'STO'
            if (strcmp(endNode,'CPU') || strcmp(endNode,'MEM') || strcmp(endNode,'STO'))
              NETutilized_T1 = NETutilized_T1 + ((NETmatrixSize - 1) * requestBAN_MS) * unitsMax;
            end
        end
      end
    end
  end
  
  if (t == 1)
    totalNETutilized_T1(t) = NETutilized_T1;
  else
    totalNETutilized_T1(t) = NETutilized_T1 + totalNETutilized_T1((t - 1));
  end
  
  NETutilization_T1(t) = (totalNETutilized_T1(t)/totalNET_T1) * 100;
  
  % Type 2 network utilization
  NETutilized_T2 = 0;
  requestBAN_CM = requestDB_T2{t,4};
  requestBAN_MS = requestDB_T2{t,5};
  allocatedNETresources_DB2 = requestDB_T2{t,13};
  allocatedITresources_DB2 = requestDB_T2{t,12};
  for i = 1:size(allocatedNETresources_DB2,1)
    for j = 1:size(allocatedNETresources_DB2,2)
      % Extract current cell from the heldITresources cell array
      NETcell = allocatedNETresources_DB2{i,j};
      if (~isempty(NETcell))
        NETmatrix = cell2mat(NETcell);
        NETmatrixSize = size(NETmatrix,2);
        startNode = char(completeResourceMap_T2(NETmatrix(1)));
        endNode = char(completeResourceMap_T2(NETmatrix(NETmatrixSize)));
        
        % Find number of units used in source and destination nodes
        unitsSource = 0;
        unitsDest = 0;
        for p = 1:size(allocatedITresources_DB2,1)
          for q = 1:size(allocatedITresources_DB2,2)
            ITcell = allocatedITresources_DB2{p,q};
            if (~isempty(ITcell))
              ITmatrix = cell2mat(ITcell);
              % Source units
              if (ITmatrix(1) == NETmatrix(1))
                unitsSource = ITmatrix(2);
              % Destination units
              elseif (ITmatrix(1) == NETmatrix(NETmatrixSize))
                unitsDest = ITmatrix(2);
              end
            end
          end
        end
        
        % Find the maximum units allocated out of source and destination nodes
        unitsMax = max(unitsSource,unitsDest);
        
        % Switch on the start node in the path
        switch (startNode)
          % CPU start node
          case 'CPU'
            if (strcmp(endNode,'CPU') || strcmp(endNode,'MEM'))
              NETutilized_T2 = NETutilized_T2 + ((NETmatrixSize - 1) * requestBAN_CM) * unitsMax;
            elseif (strcmp(endNode,'STO'))
              NETutilized_T2 = NETutilized_T2 + ((NETmatrixSize - 1) * requestBAN_MS) * unitsMax;
            end
            
          % MEM start node
          case 'MEM'
            if (strcmp(endNode,'CPU'))
              NETutilized_T2 = NETutilized_T2 + ((NETmatrixSize - 1) * requestBAN_CM) * unitsMax;
            elseif (strcmp(endNode,'MEM') || strcmp(endNode,'STO'))
              NETutilized_T2 = NETutilized_T2 + ((NETmatrixSize - 1) * requestBAN_MS) * unitsMax;
            end
            
          % STO start node
          case 'STO'
            if (strcmp(endNode,'CPU') || strcmp(endNode,'MEM') || strcmp(endNode,'STO'))
              NETutilized_T2 = NETutilized_T2 + ((NETmatrixSize - 1) * requestBAN_MS) * unitsMax;
            end
        end
      end
    end
  end
  
  if (t == 1)
    totalNETutilized_T2(t) = NETutilized_T2;
  else
    totalNETutilized_T2(t) = NETutilized_T2 + totalNETutilized_T2((t - 1));
  end
  
  NETutilization_T2(t) = (totalNETutilized_T2(t)/totalNET_T2) * 100;
  
  % Type 3 network utilization
  NETutilized_T3 = 0;
  requestBAN_CM = requestDB_T3{t,4};
  requestBAN_MS = requestDB_T3{t,5};
  allocatedNETresources_DB3 = requestDB_T3{t,13};
  allocatedITresources_DB3 = requestDB_T3{t,12};
  for i = 1:size(allocatedNETresources_DB3,1)
    for j = 1:size(allocatedNETresources_DB3,2)
      % Extract current cell from the heldITresources cell array
      NETcell = allocatedNETresources_DB3{i,j};
      if (~isempty(NETcell))
        NETmatrix = cell2mat(NETcell);
        NETmatrixSize = size(NETmatrix,2);
        startNode = char(completeResourceMap_T3(NETmatrix(1)));
        endNode = char(completeResourceMap_T3(NETmatrix(NETmatrixSize)));
        
        % Find number of units used in source and destination nodes
        unitsSource = 0;
        unitsDest = 0;
        for p = 1:size(allocatedITresources_DB3,1)
          for q = 1:size(allocatedITresources_DB3,2)
            ITcell = allocatedITresources_DB3{p,q};
            if (~isempty(ITcell))
              ITmatrix = cell2mat(ITcell);
              % Source units
              if (ITmatrix(1) == NETmatrix(1))
                unitsSource = ITmatrix(2);
              % Destination units
              elseif (ITmatrix(1) == NETmatrix(NETmatrixSize))
                unitsDest = ITmatrix(2);
              end
            end
          end
        end
        
        % Find the maximum units allocated out of source and destination nodes
        unitsMax = max(unitsSource,unitsDest);
        
        % Switch on the start node in the path
        switch (startNode)
          % CPU start node
          case 'CPU'
            if (strcmp(endNode,'CPU') || strcmp(endNode,'MEM'))
              NETutilized_T3 = NETutilized_T3 + ((NETmatrixSize - 1) * requestBAN_CM) * unitsMax;
            elseif (strcmp(endNode,'STO'))
              NETutilized_T3 = NETutilized_T3 + ((NETmatrixSize - 1) * requestBAN_MS) * unitsMax;
            end
            
          % MEM start node
          case 'MEM'
            if (strcmp(endNode,'CPU'))
              NETutilized_T3 = NETutilized_T3 + ((NETmatrixSize - 1) * requestBAN_CM) * unitsMax;
            elseif (strcmp(endNode,'MEM') || strcmp(endNode,'STO'))
              NETutilized_T3 = NETutilized_T3 + ((NETmatrixSize - 1) * requestBAN_MS) * unitsMax;
            end
            
          % STO start node
          case 'STO'
            if (strcmp(endNode,'CPU') || strcmp(endNode,'MEM') || strcmp(endNode,'STO'))
              NETutilized_T3 = NETutilized_T3 + ((NETmatrixSize - 1) * requestBAN_MS) * unitsMax;
            end
        end
      end
    end
  end
  
  if (t == 1)
    totalNETutilized_T3(t) = NETutilized_T3;
  else
    totalNETutilized_T3(t) = NETutilized_T3 + totalNETutilized_T3((t - 1));
  end
  
  NETutilization_T3(t) = (totalNETutilized_T3(t)/totalNET_T3) * 100;
  
  blocked_T1 = find(cell2mat(requestDB_T1(1:t,11)) == 0);    % Find requests that have been blocked upto time t
  blocked_T2 = find(cell2mat(requestDB_T2(1:t,11)) == 0);    % Find requests that have been blocked upto time t
  blocked_T3 = find(cell2mat(requestDB_T3(1:t,11)) == 0);    % Find requests that have been blocked upto time t
  nBlocked_T1(t) = size(blocked_T1,1);                      % Count the number of requests found
  nBlocked_T2(t) = size(blocked_T2,1);                      % Count the number of requests found
  nBlocked_T3(t) = size(blocked_T3,1);                      % Count the number of requests found

  % Type 1 latency allocated
  if (requestDB_T1{t,11} == 1)    % Check if the request was successfully allocated
    latencyAllocated_T1 = requestDB_T1{t,16};
    maxLatency_T1(t) = max([latencyAllocated_T1{:}]);
    minLatency_T1(t) = min([latencyAllocated_T1{:}]);
    averageLatency_T1(t) = sum([latencyAllocated_T1{:}],2)/size([latencyAllocated_T1{:}],2);
  end
  reqLatencyCM_T1(t) = requestDB_T1{t,6};
  reqLatencyMS_T1(t) = requestDB_T1{t,7};

  % Type 2 latency allocated
  if (requestDB_T2{t,11} == 1)    % Check if the request was successfully allocated
    latencyAllocated_T2 = requestDB_T2{t,16};
    maxLatency_T2(t) = max([latencyAllocated_T2{:}]);
    minLatency_T2(t) = min([latencyAllocated_T2{:}]);
    averageLatency_T2(t) = sum([latencyAllocated_T2{:}],2)/size([latencyAllocated_T2{:}],2);
  end
  reqLatencyCM_T2(t) = requestDB_T2{t,6};
  reqLatencyMS_T2(t) = requestDB_T2{t,7};

  % Type 3 latency allocated
  if (requestDB_T3{t,11} == 1)    % Check if the request was successfully allocated
    latencyAllocated_T3 = requestDB_T3{t,16};
    maxLatency_T3(t) = max([latencyAllocated_T3{:}]);
    minLatency_T3(t) = min([latencyAllocated_T3{:}]);
    averageLatency_T3(t) = sum([latencyAllocated_T3{:}],2)/size([latencyAllocated_T3{:}],2);
  end
  reqLatencyCM_T3(t) = requestDB_T3{t,6};
  reqLatencyMS_T3(t) = requestDB_T3{t,7};
end

figure ('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
semilogy(CPUutilization_T1,(nBlocked_T1/nRequests),'x-');
hold on;
semilogy(CPUutilization_T2,(nBlocked_T2/nRequests),'x-');
semilogy(CPUutilization_T3,(nBlocked_T3/nRequests),'x-');
xlabel('CPU utilization (%)');
ylabel('Blocking probability');
legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
title('CPU utilization vs Blocking probability');

figure ('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
semilogy(MEMutilization_T1,(nBlocked_T1/nRequests),'x-');
hold on;
semilogy(MEMutilization_T2,(nBlocked_T2/nRequests),'x-');
semilogy(MEMutilization_T3,(nBlocked_T3/nRequests),'x-');
xlabel('Memory utilization (%)');
ylabel('Blocking probability');
legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
title('Memory utilization vs Blocking probability');

figure ('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
semilogy(STOutilization_T1,(nBlocked_T1/nRequests),'x-');
hold on;
semilogy(STOutilization_T2,(nBlocked_T2/nRequests),'x-');
semilogy(STOutilization_T3,(nBlocked_T3/nRequests),'x-');
xlabel('Storage utilization (%)');
ylabel('Blocking probability');
legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
title('Storage utilization vs Blocking probability');

figure ('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
semilogy(CPUutilization_T1,(nBlocked_T1/nRequests),'x-');
hold on;
semilogy(MEMutilization_T1,(nBlocked_T1/nRequests),'x-');
semilogy(STOutilization_T1,(nBlocked_T1/nRequests),'x-');
xlabel('IT resource utilization (%)');
ylabel('Blocking probability');
legend('CPU utilization','Memory utilization','Storage utilization','location','northwest');
title('IT Resource utilization vs Blocking probability - Homogenous racks (Homogeneous blades)');

figure ('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
semilogy(CPUutilization_T2,(nBlocked_T2/nRequests),'x-');
hold on;
semilogy(MEMutilization_T2,(nBlocked_T2/nRequests),'x-');
semilogy(STOutilization_T2,(nBlocked_T2/nRequests),'x-');
xlabel('IT resource utilization (%)');
ylabel('Blocking probability');
legend('CPU utilization','Memory utilization','Storage utilization','location','northwest');
title('IT Resource utilization vs Blocking probability - Heterogeneous racks (Homogeneous blades)');

figure ('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
semilogy(CPUutilization_T3,(nBlocked_T3/nRequests),'x-');
hold on;
semilogy(MEMutilization_T3,(nBlocked_T3/nRequests),'x-');
semilogy(STOutilization_T3,(nBlocked_T3/nRequests),'x-');
xlabel('IT resource utilization (%)');
ylabel('Blocking probability');
legend('CPU utilization','Memory utilization','Storage utilization','location','northwest');
title('IT Resource utilization vs Blocking probability - Heterogeneous racks (Heterogeneous blades)');

figure ('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
semilogy(NETutilization_T1,(nBlocked_T1/nRequests),'x-');
hold on;
semilogy(NETutilization_T2,(nBlocked_T2/nRequests),'x-');
semilogy(NETutilization_T3,(nBlocked_T3/nRequests),'x-');
xlabel('Network utilization (%)');
ylabel('Blocking probability');
legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
title('Network utilization vs Blocking probability');

% UTILIZATION (REQUEST group vs NET,CPU,MEM,STO utilization) - Log (Semi-log) scale
figure ('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
semilogy(time,CPUutilization_T1,'-');
hold on;
semilogy(time,MEMutilization_T1,'-');
semilogy(time,STOutilization_T1,'-');
xlabel('Request no.');
ylabel('IT resource utilization');
legend('CPU','Memory','Storage','location','northwest');
title('Request no. vs IT Resource utilization - Homogenous racks (Homogeneous blades)');

figure ('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
semilogy(time,CPUutilization_T2,'-');
hold on;
semilogy(time,MEMutilization_T2,'-');
semilogy(time,STOutilization_T2,'-');
xlabel('Request no.');
ylabel('IT resource utilization');
legend('CPU','Memory','Storage','location','northwest');
title('Request no. vs IT Resource utilization - Heterogeneous racks (Homogeneous blades)');

figure ('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
semilogy(time,CPUutilization_T3,'-');
hold on;
semilogy(time,MEMutilization_T3,'-');
semilogy(time,STOutilization_T3,'-');
xlabel('Request no.');
ylabel('IT resource utilization');
legend('CPU','Memory','Storage','location','northwest');
title('Request no. vs IT Resource utilization - Heterogeneous racks (Heterogeneous blades)');

figure ('Name', 'Network Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
semilogy(time,NETutilization_T1,'-');
hold on;
semilogy(time,NETutilization_T2,'-');
semilogy(time,NETutilization_T3,'-');
xlabel('Request no.');
ylabel('Network utilization');
legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
title('Request no. vs Network utilization');

% UTILIZATION (REQUEST group vs NET,CPU,MEM,STO utilization) - Linear scale
figure ('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
plot(time,CPUutilization_T1,'-');
hold on;
plot(time,MEMutilization_T1,'-');
plot(time,STOutilization_T1,'-');
xlabel('Request no.');
ylabel('IT resource utilization');
legend('CPU','Memory','Storage','location','northwest');
title('Request no. vs IT Resource utilization - Homogenous racks (Homogeneous blades)');

figure ('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
plot(time,CPUutilization_T2,'-');
hold on;
plot(time,MEMutilization_T2,'-');
plot(time,STOutilization_T2,'-');
xlabel('Request no.');
ylabel('IT resource utilization');
legend('CPU','Memory','Storage','location','northwest');
title('Request no. vs IT Resource utilization - Heterogeneous racks (Homogeneous blades)');

figure ('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
plot(time,CPUutilization_T3,'-');
hold on;
plot(time,MEMutilization_T3,'-');
plot(time,STOutilization_T3,'-');
xlabel('Request no.');
ylabel('IT resource utilization');
legend('CPU','Memory','Storage','location','northwest');
title('Request no. vs IT Resource utilization - Heterogeneous racks (Heterogeneous blades)');

figure ('Name', 'Network Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
plot(time,NETutilization_T1,'-');
hold on;
plot(time,NETutilization_T2,'-');
plot(time,NETutilization_T3,'-');
xlabel('Request no.');
ylabel('Network utilization');
legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
title('Request no. vs Network utilization');

% LATENCY ALLOCATION (REQUEST group vs LATENCY ALLOCATED - min, average, max graph)
figure ('Name', 'Latency Allocated', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
plot(time,averageLatency_T1,'s');
hold on;
plot(time,minLatency_T1,'o');
plot(time,maxLatency_T1,'x');
plot(time,reqLatencyCM_T1,'+');
plot(time,reqLatencyMS_T1,'*');
xlabel('Request no.');
ylabel('Latency (ns)');
legend('Average latency', 'Minimum latency', 'Maximum latency', 'Requested CPU-MEM latency', 'Requested MEM-STO latency','location','northwest');
title('Request no. vs Latency - Homogenous racks (Homogeneous blades)');

figure ('Name', 'Latency Allocated', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
plot(time,averageLatency_T2,'s');
hold on;
plot(time,minLatency_T2,'o');
plot(time,maxLatency_T2,'x');
plot(time,reqLatencyCM_T2,'+');
plot(time,reqLatencyMS_T2,'*');
xlabel('Request no.');
ylabel('Latency (ns)');
legend('Average latency', 'Minimum latency', 'Maximum latency', 'Requested CPU-MEM latency', 'Requested MEM-STO latency','location','northwest');
title('Request no. vs Latency - Heterogeneous racks (Homogeneous blades)');

figure ('Name', 'Latency Allocated', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
plot(time,averageLatency_T3,'s');
hold on;
plot(time,minLatency_T3,'o');
plot(time,maxLatency_T3,'x');
plot(time,reqLatencyCM_T3,'+');
plot(time,reqLatencyMS_T3,'*');
xlabel('Request no.');
ylabel('Latency (ns)');
legend('Average latency', 'Minimum latency', 'Maximum latency', 'Requested CPU-MEM latency', 'Requested MEM-STO latency','location','northwest');
title('Request no. vs Latency - Heterogeneous racks (Heterogeneous blades)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clean up & display log
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str = sprintf('\n+------- SIMULATION COMPLETE --------+\n');
disp(str);
diary off;                       % Turn diary (i.e. logging functionality) off
%clear;
%str = sprintf('Opening simulation log ...');
%disp(str);
%open('log/log.txt');