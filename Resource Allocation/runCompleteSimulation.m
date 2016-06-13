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
numRequests = 1000;         % Total number of requests to generate
numTypes = 3;               % Total number of configuration types
generateNewRequestDB = 0;   % Flag that is used to generate a new request database
plotFigures = 0;            % Flag that is used to control figures/plots

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
if (generateNewRequestDB == 1)
  % Inputs generated here to keep it consistent across all simulations
  str = sprintf('Input generation started ...');
  disp(str);

  requestDB = inputGeneration(numRequests);    % Pre-generating randomised requests - Note that the resource allocation is only allowed to look at the request for the current iteration
  save('requestDB.mat','requestDB');

  str = sprintf('Input generation complete.\n');
  disp(str);
else
  % Inputs generated here to keep it consistent across all simulations
  str = sprintf('Loading input database ...');
  disp(str);

  load('requestDB');            % Load the same requestDB to keep it consistent across all simulations

  str = sprintf('Loading input database complete.\n');
  disp(str);
end

% Start MATLAB parallel pool (Using default cluster, i.e. 'local')
threadPool = gcp();     % Get current parallel pool, i.e. check if a parallel pool is open, if not open a new one
%threadPool = parpool();    % Open a new parpool with default cluster, i.e. 'local'

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
      str = sprintf('Running simulation for Type 1 ...\n');
      disp(str);

      [requestDB_T1_L, dataCenterMap_T1_L] = simStart(dataCenterConfig_T1, numRequests, requestDB, type);
      requestDB_T1 = [requestDB_T1, requestDB_T1_L];
      dataCenterMap_T1 = [dataCenterMap_T1, dataCenterMap_T1_L];

    case 2
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Type 2
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      str = sprintf('Running simulation for Type 2 ...\n');
      disp(str);

      [requestDB_T2_L, dataCenterMap_T2_L] = simStart(dataCenterConfig_T2, numRequests, requestDB, type);
      requestDB_T2 = [requestDB_T2, requestDB_T2_L];
      dataCenterMap_T2 = [dataCenterMap_T2, dataCenterMap_T2_L];

    case 3
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Type 3
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      str = sprintf('Running simulation for Type 3 ...\n');
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

% Close parpool
delete(threadPool);
%delete(gcp('nocreate'));   % The 'nocreate' option prevents opening a new one

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot results/graphs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NEED TO THINK OF GRAPHS THAT CAN BE PLOTTED TO DEPICT SIMULATION RESULTS

if(plotFigures == 1)
  % Plot heat maps
  plotHeatMap(dataCenterConfig_T1, dataCenterMap_T1, 'allMapsSetup');
  plotHeatMap(dataCenterConfig_T2, dataCenterMap_T2, 'allMapsSetup');
  plotHeatMap(dataCenterConfig_T3, dataCenterMap_T3, 'allMapsSetup');

  nRequests = numRequests; % Number of requests generated
  tRequests = nRequests;       % Total requests simulated
  requests = 1:tRequests;

  % BLOCKING PROBABILITY (Request vs BP)
  nBlocked_T1 = zeros(1,size(requests,2));
  nBlocked_T2 = zeros(1,size(requests,2));
  nBlocked_T3 = zeros(1,size(requests,2));
  % Main request loop
  for r = 1:tRequests
    blocked_T1 = find(cell2mat(requestDB_T1(1:r,11)) == 0);    % Find requests that have been blocked upto request r
    blocked_T2 = find(cell2mat(requestDB_T2(1:r,11)) == 0);    % Find requests that have been blocked upto request r
    blocked_T3 = find(cell2mat(requestDB_T3(1:r,11)) == 0);    % Find requests that have been blocked upto request r
    nBlocked_T1(r) = size(blocked_T1,1);                      % Count the number of requests found
    nBlocked_T2(r) = size(blocked_T2,1);                      % Count the number of requests found
    nBlocked_T3(r) = size(blocked_T3,1);                      % Count the number of requests found
  end

  %yFactor = eps;               % Set to epsilon to avoid going to -inf
  %yFactor = 1/(2 * nRequests);  % Set to half the maximum blocking probability to avoid going to -inf
  yFactor = 0;
  figure ('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  semilogy(requests,max(yFactor,(nBlocked_T1/nRequests)),'x-');
  hold on;
  semilogy(requests,max(yFactor,(nBlocked_T2/nRequests)),'x-');
  semilogy(requests,max(yFactor,(nBlocked_T3/nRequests)),'x-');
  xlabel('Request no.');
  ylabel('Blocking probability');
  legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
  title('Request no. vs Blocking probability');

  % BLOCKING PROBABILITY (CPU,MEM,STO utilization vs BP)
  nBlocked_T1 = zeros(1,size(requests,2));
  nBlocked_T2 = zeros(1,size(requests,2));
  nBlocked_T3 = zeros(1,size(requests,2));
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
  totalCPUunitsUtilized_T1 = zeros(1,size(requests,2));
  totalMEMunitsUtilized_T1 = zeros(1,size(requests,2));
  totalSTOunitsUtilized_T1 = zeros(1,size(requests,2));
  totalCPUunitsUtilized_T2 = zeros(1,size(requests,2));
  totalMEMunitsUtilized_T2 = zeros(1,size(requests,2));
  totalSTOunitsUtilized_T2 = zeros(1,size(requests,2));
  totalCPUunitsUtilized_T3 = zeros(1,size(requests,2));
  totalMEMunitsUtilized_T3 = zeros(1,size(requests,2));
  totalSTOunitsUtilized_T3 = zeros(1,size(requests,2));
  CPUutilization_T1 = zeros(1,size(requests,2));
  MEMutilization_T1 = zeros(1,size(requests,2));
  STOutilization_T1 = zeros(1,size(requests,2));
  CPUutilization_T2 = zeros(1,size(requests,2));
  MEMutilization_T2 = zeros(1,size(requests,2));
  STOutilization_T2 = zeros(1,size(requests,2));
  CPUutilization_T3 = zeros(1,size(requests,2));
  MEMutilization_T3 = zeros(1,size(requests,2));
  STOutilization_T3 = zeros(1,size(requests,2));
  totalNETutilized_T1 = zeros(1,size(requests,2));
  totalNETutilized_T2 = zeros(1,size(requests,2));
  totalNETutilized_T3 = zeros(1,size(requests,2));
  NETutilization_T1 = zeros(1,size(requests,2));
  NETutilization_T2 = zeros(1,size(requests,2));
  NETutilization_T3 = zeros(1,size(requests,2));
  completeResourceMap_T1 = dataCenterMap_T1.completeResourceMap;
  completeResourceMap_T2 = dataCenterMap_T2.completeResourceMap;
  completeResourceMap_T3 = dataCenterMap_T3.completeResourceMap;
  reqLatencyCM = zeros(1,size(requests,2));
  reqLatencyMS = zeros(1,size(requests,2));
  maxLatency_T1 = zeros(1,size(requests,2));
  minLatency_T1 = zeros(1,size(requests,2));
  averageLatency_T1 = zeros(1,size(requests,2));
  maxLatency_T2 = zeros(1,size(requests,2));
  minLatency_T2 = zeros(1,size(requests,2));
  averageLatency_T2 = zeros(1,size(requests,2));
  maxLatency_T3 = zeros(1,size(requests,2));
  minLatency_T3 = zeros(1,size(requests,2));
  averageLatency_T3 = zeros(1,size(requests,2));

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

  % Main request loop
  for r = 1:tRequests
    % Type 1 IT resource utilization
    CPUunitsUtilized_T1 = 0;
    MEMunitsUtilized_T1 = 0;
    STOunitsUtilized_T1 = 0;
    allocatedResources_T1 = requestDB_T1{r,12};
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

    if (r == 1)
      totalCPUunitsUtilized_T1(r) = sum(CPUunitsUtilized_T1,2);
      totalMEMunitsUtilized_T1(r) = sum(MEMunitsUtilized_T1,2);
      totalSTOunitsUtilized_T1(r) = sum(STOunitsUtilized_T1,2);
    else
      totalCPUunitsUtilized_T1(r) = sum(CPUunitsUtilized_T1,2) + totalCPUunitsUtilized_T1((r - 1));
      totalMEMunitsUtilized_T1(r) = sum(MEMunitsUtilized_T1,2) + totalMEMunitsUtilized_T1((r - 1));
      totalSTOunitsUtilized_T1(r) = sum(STOunitsUtilized_T1,2) + totalSTOunitsUtilized_T1((r - 1));
    end
    
    CPUutilization_T1(r) = (totalCPUunitsUtilized_T1(r)/totalCPUunits_T1) * 100;
    MEMutilization_T1(r) = (totalMEMunitsUtilized_T1(r)/totalMEMunits_T1) * 100;
    STOutilization_T1(r) = (totalSTOunitsUtilized_T1(r)/totalSTOunits_T1) * 100;
    
    % Type 2 IT resource utilization
    CPUunitsUtilized_T2 = 0;
    MEMunitsUtilized_T2 = 0;
    STOunitsUtilized_T2 = 0;
    allocatedResources_DB2 = requestDB_T2{r,12};
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
    
    if (r == 1)
      totalCPUunitsUtilized_T2(r) = sum(CPUunitsUtilized_T2,2);
      totalMEMunitsUtilized_T2(r) = sum(MEMunitsUtilized_T2,2);
      totalSTOunitsUtilized_T2(r) = sum(STOunitsUtilized_T2,2);
    else
      totalCPUunitsUtilized_T2(r) = sum(CPUunitsUtilized_T2,2) + totalCPUunitsUtilized_T2((r - 1));
      totalMEMunitsUtilized_T2(r) = sum(MEMunitsUtilized_T2,2) + totalMEMunitsUtilized_T2((r - 1));
      totalSTOunitsUtilized_T2(r) = sum(STOunitsUtilized_T2,2) + totalSTOunitsUtilized_T2((r - 1));
    end
    
    CPUutilization_T2(r) = (totalCPUunitsUtilized_T2(r)/totalCPUunits_T2) * 100;
    MEMutilization_T2(r) = (totalMEMunitsUtilized_T2(r)/totalMEMunits_T2) * 100;
    STOutilization_T2(r) = (totalSTOunitsUtilized_T2(r)/totalSTOunits_T2) * 100;
    
    % Type 3 IT resource utilization
    CPUunitsUtilized_T3 = 0;
    MEMunitsUtilized_T3 = 0;
    STOunitsUtilized_T3 = 0;
    allocatedResources_DB3 = requestDB_T3{r,12};
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
    
    if (r == 1)
      totalCPUunitsUtilized_T3(r) = sum(CPUunitsUtilized_T3,2);
      totalMEMunitsUtilized_T3(r) = sum(MEMunitsUtilized_T3,2);
      totalSTOunitsUtilized_T3(r) = sum(STOunitsUtilized_T3,2);
    else
      totalCPUunitsUtilized_T3(r) = sum(CPUunitsUtilized_T3,2) + totalCPUunitsUtilized_T3((r - 1));
      totalMEMunitsUtilized_T3(r) = sum(MEMunitsUtilized_T3,2) + totalMEMunitsUtilized_T3((r - 1));
      totalSTOunitsUtilized_T3(r) = sum(STOunitsUtilized_T3,2) + totalSTOunitsUtilized_T3((r - 1));
    end
    
    CPUutilization_T3(r) = (totalCPUunitsUtilized_T3(r)/totalCPUunits_T3) * 100;
    MEMutilization_T3(r) = (totalMEMunitsUtilized_T3(r)/totalMEMunits_T3) * 100;
    STOutilization_T3(r) = (totalSTOunitsUtilized_T3(r)/totalSTOunits_T3) * 100;
    
    % Type 1 network utilization
    NETutilized_T1 = 0;
    requestBAN_CM = requestDB_T1{r,4};
    requestBAN_MS = requestDB_T1{r,5};
    allocatedNETresources_DB1 = requestDB_T1{r,13};
    allocatedITresources_DB1 = requestDB_T1{r,12};
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
    
    if (r == 1)
      totalNETutilized_T1(r) = NETutilized_T1;
    else
      totalNETutilized_T1(r) = NETutilized_T1 + totalNETutilized_T1((r - 1));
    end
    
    NETutilization_T1(r) = (totalNETutilized_T1(r)/totalNET_T1) * 100;
    
    % Type 2 network utilization
    NETutilized_T2 = 0;
    requestBAN_CM = requestDB_T2{r,4};
    requestBAN_MS = requestDB_T2{r,5};
    allocatedNETresources_DB2 = requestDB_T2{r,13};
    allocatedITresources_DB2 = requestDB_T2{r,12};
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
    
    if (r == 1)
      totalNETutilized_T2(r) = NETutilized_T2;
    else
      totalNETutilized_T2(r) = NETutilized_T2 + totalNETutilized_T2((r - 1));
    end
    
    NETutilization_T2(r) = (totalNETutilized_T2(r)/totalNET_T2) * 100;
    
    % Type 3 network utilization
    NETutilized_T3 = 0;
    requestBAN_CM = requestDB_T3{r,4};
    requestBAN_MS = requestDB_T3{r,5};
    allocatedNETresources_DB3 = requestDB_T3{r,13};
    allocatedITresources_DB3 = requestDB_T3{r,12};
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
    
    if (r == 1)
      totalNETutilized_T3(r) = NETutilized_T3;
    else
      totalNETutilized_T3(r) = NETutilized_T3 + totalNETutilized_T3((r - 1));
    end
    
    NETutilization_T3(r) = (totalNETutilized_T3(r)/totalNET_T3) * 100;
    
    blocked_T1 = find(cell2mat(requestDB_T1(1:r,11)) == 0);    % Find requests that have been blocked upto request r
    blocked_T2 = find(cell2mat(requestDB_T2(1:r,11)) == 0);    % Find requests that have been blocked upto request r
    blocked_T3 = find(cell2mat(requestDB_T3(1:r,11)) == 0);    % Find requests that have been blocked upto request r
    nBlocked_T1(r) = size(blocked_T1,1);                      % Count the number of requests found
    nBlocked_T2(r) = size(blocked_T2,1);                      % Count the number of requests found
    nBlocked_T3(r) = size(blocked_T3,1);                      % Count the number of requests found

    % Extract the requested latency (Can use any request database since all contain the same values)
    reqLatencyCM(r) = requestDB_T1{r,6};
    reqLatencyMS(r) = requestDB_T1{r,7};

    % Type 1 latency allocated
    if (requestDB_T1{r,11} == 1)    % Check if the request was successfully allocated
      latencyAllocated_T1 = requestDB_T1{r,16};
      maxLatency_T1(r) = max([latencyAllocated_T1{:}]);
      minLatency_T1(r) = min([latencyAllocated_T1{:}]);
      averageLatency_T1(r) = sum([latencyAllocated_T1{:}],2)/size([latencyAllocated_T1{:}],2);
    end

    % Type 2 latency allocated
    if (requestDB_T2{r,11} == 1)    % Check if the request was successfully allocated
      latencyAllocated_T2 = requestDB_T2{r,16};
      maxLatency_T2(r) = max([latencyAllocated_T2{:}]);
      minLatency_T2(r) = min([latencyAllocated_T2{:}]);
      averageLatency_T2(r) = sum([latencyAllocated_T2{:}],2)/size([latencyAllocated_T2{:}],2);
    end

    % Type 3 latency allocated
    if (requestDB_T3{r,11} == 1)    % Check if the request was successfully allocated
      latencyAllocated_T3 = requestDB_T3{r,16};
      maxLatency_T3(r) = max([latencyAllocated_T3{:}]);
      minLatency_T3(r) = min([latencyAllocated_T3{:}]);
      averageLatency_T3(r) = sum([latencyAllocated_T3{:}],2)/size([latencyAllocated_T3{:}],2);
    end
  end

  % Change all zeros in the allocated latency matrices to NaNs to avoid plotting them.
  maxLatency_T1(maxLatency_T1 == 0) = NaN;
  minLatency_T1(minLatency_T1 == 0) = NaN;
  averageLatency_T1(averageLatency_T1 == 0) = NaN;
  maxLatency_T2(maxLatency_T2 == 0) = NaN;
  minLatency_T2(minLatency_T2 == 0) = NaN;
  averageLatency_T2(averageLatency_T2 == 0) = NaN;
  maxLatency_T3(maxLatency_T3 == 0) = NaN;
  minLatency_T3(minLatency_T3 == 0) = NaN;
  averageLatency_T3(averageLatency_T3 == 0) = NaN;

  % Start plotting
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
  semilogy(requests,CPUutilization_T1,'-');
  hold on;
  semilogy(requests,MEMutilization_T1,'-');
  semilogy(requests,STOutilization_T1,'-');
  xlabel('Request no.');
  ylabel('IT resource utilization');
  legend('CPU','Memory','Storage','location','northwest');
  title('Request no. vs IT Resource utilization - Homogenous racks (Homogeneous blades)');

  figure ('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  semilogy(requests,CPUutilization_T2,'-');
  hold on;
  semilogy(requests,MEMutilization_T2,'-');
  semilogy(requests,STOutilization_T2,'-');
  xlabel('Request no.');
  ylabel('IT resource utilization');
  legend('CPU','Memory','Storage','location','northwest');
  title('Request no. vs IT Resource utilization - Heterogeneous racks (Homogeneous blades)');

  figure ('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  semilogy(requests,CPUutilization_T3,'-');
  hold on;
  semilogy(requests,MEMutilization_T3,'-');
  semilogy(requests,STOutilization_T3,'-');
  xlabel('Request no.');
  ylabel('IT resource utilization');
  legend('CPU','Memory','Storage','location','northwest');
  title('Request no. vs IT Resource utilization - Heterogeneous racks (Heterogeneous blades)');

  figure ('Name', 'Network Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  semilogy(requests,NETutilization_T1,'-');
  hold on;
  semilogy(requests,NETutilization_T2,'-');
  semilogy(requests,NETutilization_T3,'-');
  xlabel('Request no.');
  ylabel('Network utilization');
  legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
  title('Request no. vs Network utilization');

  % UTILIZATION (REQUEST group vs NET,CPU,MEM,STO utilization) - Linear scale
  figure ('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  plot(requests,CPUutilization_T1,'-');
  hold on;
  plot(requests,MEMutilization_T1,'-');
  plot(requests,STOutilization_T1,'-');
  xlabel('Request no.');
  ylabel('IT resource utilization');
  legend('CPU','Memory','Storage','location','northwest');
  title('Request no. vs IT Resource utilization - Homogenous racks (Homogeneous blades)');

  figure ('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  plot(requests,CPUutilization_T2,'-');
  hold on;
  plot(requests,MEMutilization_T2,'-');
  plot(requests,STOutilization_T2,'-');
  xlabel('Request no.');
  ylabel('IT resource utilization');
  legend('CPU','Memory','Storage','location','northwest');
  title('Request no. vs IT Resource utilization - Heterogeneous racks (Homogeneous blades)');

  figure ('Name', 'IT Resource Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  plot(requests,CPUutilization_T3,'-');
  hold on;
  plot(requests,MEMutilization_T3,'-');
  plot(requests,STOutilization_T3,'-');
  xlabel('Request no.');
  ylabel('IT resource utilization');
  legend('CPU','Memory','Storage','location','northwest');
  title('Request no. vs IT Resource utilization - Heterogeneous racks (Heterogeneous blades)');

  figure ('Name', 'Network Utilization', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  plot(requests,NETutilization_T1,'-');
  hold on;
  plot(requests,NETutilization_T2,'-');
  plot(requests,NETutilization_T3,'-');
  xlabel('Request no.');
  ylabel('Network utilization');
  legend('Homogeneous racks (Homogeneous blades)','Heterogeneous racks (Homogeneous blades)','Heterogeneous racks (Heterogeneous blades)','location','northwest');
  title('Request no. vs Network utilization');

  % LATENCY ALLOCATION (REQUEST group vs LATENCY ALLOCATED - min, average, max graph)
  figure ('Name', 'Latency Allocated', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  plot(requests,reqLatencyCM,'+','color', 'c');
  hold on;
  plot(requests,reqLatencyMS,'*','color', 'm');
  plot(requests,averageLatency_T1,'s','color', 'r');
  plot(requests,minLatency_T1,'o','color', 'r');
  plot(requests,maxLatency_T1,'x','color', 'r');
  plot(requests,averageLatency_T2,'s','color', 'g');
  plot(requests,minLatency_T2,'o','color', 'g');
  plot(requests,maxLatency_T2,'x','color', 'g');
  plot(requests,averageLatency_T3,'s','color', 'b');
  plot(requests,minLatency_T3,'o','color', 'b');
  plot(requests,maxLatency_T3,'x','color', 'b');
  xlabel('Request no.');
  ylabel('Latency (ns)');
  legend('Requested CPU-MEM latency', 'Requested MEM-STO latency', ...
         'Average latency - Homogenous racks (Homogeneous blades)', 'Minimum latency - Homogenous racks (Homogeneous blades)', 'Maximum latency - Homogenous racks (Homogeneous blades)', ...
         'Average latency - Heterogeneous racks (Homogeneous blades)', 'Minimum latency - Heterogeneous racks (Homogeneous blades)', 'Maximum latency - Heterogeneous racks (Homogeneous blades)', ...
         'Average latency - Heterogeneous racks (Heterogeneous blades)', 'Minimum latency - Heterogeneous racks (Heterogeneous blades)', 'Maximum latency - Heterogeneous racks (Heterogeneous blades)', ...
         'location','northwest');
  title('Request no. vs Latency allocated');
end

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
