%%+++++++++++++++++++++++++++++++++++++%%
%%% Script that starts the simulation %%%
%%+++++++++++++++++++++++++++++++++++++%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up clean environment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;      % Clear all variables in the workspace
close all;  % Close all open figures
clc;        % Clear console/command prompt
str = sprintf('\n+-------- SIMULATION STARTED --------+\n');
disp(str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Miscellaneous simulation "variables" (including macros)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Macro definitions
SUCCESS = 1;
FAILURE = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Import configuration file (YAML config files)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
yaml_configFile = 'config/import_config.yaml';  % File to import (File path)
yaml_configStruct = ReadYaml(yaml_configFile);  % Read file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Evaluate IT & Network constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nRequests = 10;      % Number of requests to generate
tTime = nRequests;    % Total time to simulate for (1 second for each request)

% Initialize counter variables
nCPUs = 0;
nMEMs = 0;
nSTOs = 0;
nCPU_MEM = 0;

% Total number of racks specified in the configuration file
rackNo = fieldnames(yaml_configStruct.racksConfig);

% Iterate over all specified racks
for i = 1:numel(rackNo)
  % Find homogeneous blades of CPUs
  nCPUs = nCPUs + size(find([yaml_configStruct.racksConfig.(rackNo{i}){:}] == yaml_configStruct.setupTypes.homogenCPU), 2);
  % Find homogeneous blades of MEMs
  nMEMs = nMEMs + size(find([yaml_configStruct.racksConfig.(rackNo{i}){:}] == yaml_configStruct.setupTypes.homogenMEM), 2);
  % Find homogeneous blades of STOs
  nSTOs = nSTOs + size(find([yaml_configStruct.racksConfig.(rackNo{i}){:}] == yaml_configStruct.setupTypes.homogenSTO), 2);
  % Find heterogeneous blades of CPUs & MEMs
  nCPU_MEM = nCPU_MEM + size(find([yaml_configStruct.racksConfig.(rackNo{i}){:}] == yaml_configStruct.setupTypes.heterogenCPU_MEM), 2);
end

% Add heterogenous values to nCPUs and nMEMs and evaluate total amount/units of resources available
CPUs = (nCPUs * yaml_configStruct.nSlots * yaml_configStruct.nUnits * yaml_configStruct.unitSize.CPU) + (((nCPU_MEM * yaml_configStruct.nSlots) * (yaml_configStruct.heterogenSplit.heterogenCPU_MEM/100)) * yaml_configStruct.nUnits * yaml_configStruct.unitSize.CPU);
MEMs = (nMEMs * yaml_configStruct.nSlots * yaml_configStruct.nUnits * yaml_configStruct.unitSize.MEM) + (((nCPU_MEM * yaml_configStruct.nSlots) * ((100 - yaml_configStruct.heterogenSplit.heterogenCPU_MEM)/100)) * yaml_configStruct.nUnits * yaml_configStruct.unitSize.MEM);
STOs = (nSTOs * yaml_configStruct.nSlots * yaml_configStruct.nUnits * yaml_configStruct.unitSize.STO);

% Pack all required data center configuration parameters into a struct
dataCenterConfig.nRacks = yaml_configStruct.nRacks;
dataCenterConfig.nBlades = yaml_configStruct.nBlades;
dataCenterConfig.nSlots = yaml_configStruct.nSlots;
dataCenterConfig.nUnits = yaml_configStruct.nUnits;

dataCenterConfig.unitSizeCPU = yaml_configStruct.unitSize.CPU;
dataCenterConfig.unitSizeMEM = yaml_configStruct.unitSize.MEM;
dataCenterConfig.unitSizeSTO = yaml_configStruct.unitSize.STO;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Network creation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str = sprintf('Network creation started ...');
disp(str);

dataCenterMap = networkCreation(dataCenterConfig);

str = sprintf('Network creation complete.\n');
disp(str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input generation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str = sprintf('Input generation started ...');
disp(str);

requestDB = inputGeneration(nRequests);    % Pre-generating randomised requests - Note that the resource allocation is only allowed to look at the request for the current iteration

str = sprintf('Input generation complete.\n');
disp(str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot data center structure as a graph
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% str = sprintf('Data center topology/layout plot started ...');
% disp(str);
% plotDataCenterLayout(dataCenterMap, dataCenterConfig);   % Function to plot data center layout
% 
% str = sprintf('Data center topology/layout plot complete.\n');
% disp(str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Resource allocation main time loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str = sprintf('Resource allocation started ...');
disp(str);

ITresourceAllocStatusColumn = 7;
networkResourceAllocStatusColumn = 8;
requestStatusColumn = 9;

% Open figure - Updated when each request's resource allocation is complete
figure ('Name', 'Data Center Rack Usage (1st rack of each type)', 'NumberTitle', 'off', 'Position', [40, 100, 1200, 700]);

% Main time loop
for t = 1:tTime
  % Each timestep, look at it's corresponding request in the request database
  requestDBindex = t;
  % Extract request from the database
  request = requestDB(requestDBindex,:);
  
  %%%%%%%%%% IT resource allocation %%%%%%%%%%
  [dataCenterMap, ITallocationResult] = resourceAllocation(request, dataCenterConfig, dataCenterMap);
  plotUsage(dataCenterMap, dataCenterConfig);

  %%%%%%%%%% Network resource allocation %%%%%%%%%%
  % Need to get a better understanding of network resource allocation code
  networkAllocationResult = 0;

  %%%%%%%%%% Update requests database %%%%%%%%%%
  % Doing this to "simulate parallelism" with IT and network resource
  % allocation. Updating the request database after the IT resource
  % allocation makes the updated database available to the network resource
  % allocation unit which is not what we want. We want them to work
  % independently although we would still require information on which IT
  % resources have been allocated to this request (if any, i.e. Rack
  % number, blade number, slot number and unit numbers for each slot). This
  % can be stored in the request database (i.e. requestDB).
  
  % Update IT resource allocation column
  requestDB(requestDBindex, ITresourceAllocStatusColumn) =  ITallocationResult;
  
  % Update network resource allocation column
  %requestDB(requestDBindex, networkResourceAllocStatusColumn) =  networkAllocationResult;
  
  % Update request status column
  if (ITallocationResult == SUCCESS && networkAllocationResult == SUCCESS)
    requestDB(requestDBindex, requestStatusColumn) = SUCCESS;
  end
end

str = sprintf('Resource allocation complete.\n');
disp(str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate and plot results (Analysis)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str = sprintf('Displaying results ...\n');
disp(str);

displayResults(dataCenterMap, requestDB, nRequests, dataCenterConfig);

% NEED TO THINK OF GRAPHS THAT CAN BE PLOTTED TO DEPICT SIMULATION RESULTS

str = sprintf('\n+------- SIMULATION COMPLETE --------+\n');
disp(str);
