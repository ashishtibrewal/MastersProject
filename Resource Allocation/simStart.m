%%+++++++++++++++++++++++++++++++++++++%%
%%% Script that starts the simulation %%%
%%+++++++++++++++++++++++++++++++++++++%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up clean environment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;      % Clear all variables in the workspace
close all;  % Close all open figures
clc;        % Clear console/command prompt

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Datacenter IT & Network constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Insert call to a separate script/function to setup/declare all datacenter
% constants

%CPU_racks = 20;
%MEM_racks = 60;
%STO_racks = 40;

% NEED TO CHANGE THESE TO HAVE A BETTER SPREAD OF RESOURCES
racksCPU = 1:10;      % Racks  1-10 are for CPUs
racksMEM = 11:20;     % Racks 11-20 are for MEMs
racksSTO = 21:30;     % Racks 21-30 are for STOs

nRequests = 1000;   % Number of requests to generate
nRacks = 30;          % Number of racks (in the datacenter)
nBlades = 20;         % Number of blades (in each rack)
nSlots = 50;          % Number of slots (in each blade)
nUnits = 25;          % Number of units (in each slot) - This could be split into three different values, one for each CPU, Memory and Storage

unitSizeCPU = 1;      % >1 signifies multi-core (A simplistic approach)
unitSizeMEM = 4;      % Each DIMM is 4 GB in size/capacity
unitSizeSTO = 500;    % Each HDD is 500 GB in size /capacity

CPUs = size(racksCPU,2) * nBlades * nSlots * nUnits * unitSizeCPU;     % Total CPUs in the datacenter
MEMs = size(racksMEM,2) * nBlades * nSlots * nUnits * unitSizeMEM;     % Todal amount of memory in the datacenter
STOs = size(racksSTO,2) * nBlades * nSlots * nUnits * unitSizeSTO;     % Total amount of storage in the datacenter

% Pack all required data center configuration parameters into a struct
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
[networkMap, occupiedMap, distanceMap, latencyMap, bandwidthMap] = networkCreation(dataCenterConfig);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input generation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
requestDB = inputGeneration(nRequests);    % Pre-generating randomised requests - Note that the resource allocation is only allowed to look at the request for the current iteration

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IT resource allocation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Iterate over all generated requests
for i = 1:nRequests
  [occupiedMap, requestDB] = resourceAllocation(i, requestDB, networkMap, occupiedMap, distanceMap, latencyMap, bandwidthMap, dataCenterConfig);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Network resource allocation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Need to get a better understanding of network resource allocation code


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate and plot results (Analysis)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Need to write a separate function that generates/prints all the results
% and plots for the entire simulation
