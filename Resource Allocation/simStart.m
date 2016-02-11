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
% Datacenter IT & Network constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Insert call to a separate script/function to setup/declare all datacenter
% constants

%CPU_racks = 20;
%MEM_racks = 60;
%STO_racks = 40;

% NEED TO CHANGE THESE TO HAVE A BETTER SPREAD OF RESOURCES AND ALSO NEED
% TO INCREASE THE NUMBER OF RACKS
tRacks = 3;           % Types of racks in the data center
nRacks = 15;          % Number of racks (in the datacenter)
nBlades = 20;         % Number of blades (in each rack)
nSlots = 50;          % Number of slots (in each blade)
nUnits = 25;          % Number of units (in each slot) - This could be split into three different values, one for each CPU, Memory and Storage

nRequests = 10;      % Number of requests to generate
tTime = nRequests;    % Total time to simulate for (1 second for each request)

% TODO Need to change this to accommodate different types of resources on
% one rack
racksCPU = 1:((nRacks/tRacks) * 1);      % Racks  1-5 are for CPUs
racksMEM = (((nRacks/tRacks) * 1) + 1):((nRacks/tRacks) * 2);     % Racks 6-10 are for MEMs
racksSTO = (((nRacks/tRacks) * 2) + 1):nRacks;     % Racks 11-15 are for STOs

unitSizeCPU = 1;      % >1 signifies multi-core (A simplistic approach)
unitSizeMEM = 4;      % Each DIMM is 4 GB in size/capacity
unitSizeSTO = 500;    % Each HDD is 500 GB in size /capacity

CPUs = size(racksCPU,2) * nBlades * nSlots * nUnits * unitSizeCPU;     % Total CPUs in the datacenter
MEMs = size(racksMEM,2) * nBlades * nSlots * nUnits * unitSizeMEM;     % Todal amount of memory in the datacenter
STOs = size(racksSTO,2) * nBlades * nSlots * nUnits * unitSizeSTO;     % Total amount of storage in the datacenter

% Pack all required data center configuration parameters into a struct
dataCenterConfig.tRacks = tRacks;
dataCenterConfig.nRacks = nRacks;
dataCenterConfig.nBlades = nBlades;
dataCenterConfig.nSlots = nSlots;
dataCenterConfig.nUnits = nUnits;

dataCenterConfig.unitSizeCPU = unitSizeCPU;
dataCenterConfig.unitSizeMEM = unitSizeMEM;
dataCenterConfig.unitSizeSTO = unitSizeSTO;

dataCenterConfig.racksCPU = racksCPU;
dataCenterConfig.racksMEM = racksMEM;
dataCenterConfig.racksSTO = racksSTO;

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
