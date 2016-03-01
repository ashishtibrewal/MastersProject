%%+++++++++++++++++++++++++++++++++++++%%
%%% Script that starts the simulation %%%
%%+++++++++++++++++++++++++++++++++++++%%

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
SUCCESS = 1;
FAILURE = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Import configuration file (YAML config files)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
yaml_configFile = 'config/import_config.yaml';  % File to import (File path)
dataCenterConfig = ReadYaml(yaml_configFile);   % Read file and store it into a struct called dataCenterConfig

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Evaluate IT & Network constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nRequests = 100;      % Number of requests to generate
tTime = nRequests;    % Total time to simulate for (1 second for each request)

% Initialize counter variables
nCPUs = 0;
nMEMs = 0;
nSTOs = 0;
nCPU_MEM = 0;

% Total number of racks specified in the configuration file
rackNo = fieldnames(dataCenterConfig.racksConfig);

% Iterate over all specified racks
for i = 1:numel(rackNo)
  % Find homogeneous blades of CPUs
  nCPUs = nCPUs + size(find([dataCenterConfig.racksConfig.(rackNo{i}){:}] == dataCenterConfig.setupTypes.homogenCPU), 2);
  % Find homogeneous blades of MEMs
  nMEMs = nMEMs + size(find([dataCenterConfig.racksConfig.(rackNo{i}){:}] == dataCenterConfig.setupTypes.homogenMEM), 2);
  % Find homogeneous blades of STOs
  nSTOs = nSTOs + size(find([dataCenterConfig.racksConfig.(rackNo{i}){:}] == dataCenterConfig.setupTypes.homogenSTO), 2);
  % Find heterogeneous blades of CPUs & MEMs
  nCPU_MEM = nCPU_MEM + size(find([dataCenterConfig.racksConfig.(rackNo{i}){:}] == dataCenterConfig.setupTypes.heterogenCPU_MEM), 2);
end

% TODO Need to make this more flexible (Currently breaks for odd number of slots in a blade)
% Add heterogenous values to nCPUs and nMEMs and evaluate total amount/units of resources available
CPUs = (nCPUs * dataCenterConfig.nSlots * dataCenterConfig.nUnits * dataCenterConfig.unitSize.CPU) + (((nCPU_MEM * dataCenterConfig.nSlots) * (dataCenterConfig.heterogenSplit.heterogenCPU_MEM/100)) * dataCenterConfig.nUnits * dataCenterConfig.unitSize.CPU);
MEMs = (nMEMs * dataCenterConfig.nSlots * dataCenterConfig.nUnits * dataCenterConfig.unitSize.MEM) + (((nCPU_MEM * dataCenterConfig.nSlots) * ((100 - dataCenterConfig.heterogenSplit.heterogenCPU_MEM)/100)) * dataCenterConfig.nUnits * dataCenterConfig.unitSize.MEM);
STOs = (nSTOs * dataCenterConfig.nSlots * dataCenterConfig.nUnits * dataCenterConfig.unitSize.STO);

% Find total number of units of each type of resource
nCPU_units = CPUs/dataCenterConfig.unitSize.CPU;
nMEM_units = MEMs/dataCenterConfig.unitSize.MEM;
nSTO_units = STOs/dataCenterConfig.unitSize.STO;

% Pack number of different types of resource items into a struct (Using a
% different struct to keep the original YAML struct unmodified)
dataCenterItems.nCPUs = CPUs;
dataCenterItems.nMEMs = MEMs;
dataCenterItems.nSTOs = STOs;
dataCenterItems.nCPU_units = nCPU_units;
dataCenterItems.nMEM_units = nMEM_units;
dataCenterItems.nSTO_units = nSTO_units;

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

ITresourceAllocStatusColumn = 9;
networkResourceAllocStatusColumn = 10;
requestStatusColumn = 11;

% Open figure - Updated when each request's resource allocation is complete
%figure ('Name', 'Data Center Rack Usage (1st rack of each type)', 'NumberTitle', 'off', 'Position', [40, 100, 1200, 700]);

% USED ONLY FOR DEBUGGING
%tTime = 1;
testRequest = {5,10,10,1000,1000,50,50,4000,0,0,0,0};    % Test request used for debugging

% Main time loop
for t = 1:tTime
  % Each timestep, look at it's corresponding request in the request database
  % INTER-ARRIVAL RATE = 1 request/second
  requestDBindex = t;
  % Extract request from the database for current timestep
  request = requestDB(requestDBindex,:);
  %request = testRequest;
  
  % Display required resources for request on the prompt
  requestString = sprintf(' %d', request{1:3});
  str = sprintf('Requried resouces (Request no. %d): %s', requestDBindex, requestString);
  disp(str);
  
  %%%%%%%%%% IT & NET resource allocation %%%%%%%%%%
  [dataCenterMap, ITallocationResult, NETallocationResult, ITresourceNodesAllocated] = resourceAllocation(request, dataCenterConfig, dataCenterMap, dataCenterItems);
  
  % Update request database
  requestDB(requestDBindex,12) = {ITresourceNodesAllocated};
  
  % Plot usage
  %plotUsage(dataCenterMap, dataCenterConfig);

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
  requestDB{requestDBindex, ITresourceAllocStatusColumn} =  ITallocationResult;
  
  % Update network resource allocation column
  %requestDB(requestDBindex, networkResourceAllocStatusColumn) =  networkAllocationResult;
  
  % Update request status column
  if (ITallocationResult == 1 && networkAllocationResult == 1)
    requestDB{requestDBindex, requestStatusColumn} = 1;
  end
end

str = sprintf('Resource allocation complete.\n');
disp(str);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate and plot results (Analysis)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str = sprintf('Displaying results ...');
disp(str);

displayResults(dataCenterMap, requestDB, nRequests, dataCenterConfig);

% NEED TO THINK OF GRAPHS THAT CAN BE PLOTTED TO DEPICT SIMULATION RESULTS

str = sprintf('\n+------- SIMULATION COMPLETE --------+\n');
disp(str);
diary off;                       % Turn diary (i.e. logging functionality) off
% str = sprintf('Opening simulation log ...');
% disp(str);
% open('log/log.txt');
