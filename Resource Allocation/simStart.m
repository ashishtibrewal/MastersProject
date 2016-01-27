%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Script that starts the simulation %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set up clean environment
clear;      % Clear all variables in the workspace
close all;  % Close all open figures
clc;        % Clear console/command prompt

% Datacenter IT & Network constants
% Insert call to a separate script/function to setup/declare all datacenter
% constants
nRequests = 100000;   % Number of requests to generate
nRacks = 20;          % Number of racks (in the datacenter)
nBlades = 20;         % Number of blades (in each rack)
nSlots = 50;          % Number of slots (in each blade)
nUnits = 25;          % Number of units (in each slot) - This could be split into three different values, one for each CPU, Memory and Storage

unitSizeCPU = 1;      % >1 signifies multi-core (A simplistic approach)
unitSizeMEM = 4;      % Each DIMM is 4 GB in size/capacity
unitSizeSTO = 500;    % Each HDD is 500 GB in size /capacity

% Network creation
[networkMap, occupiedMap, distanceMap, latencyMap, bandwidthMap] = networkCreation(nRacks, nBlades, nSlots, nUnits);

% Input generation
requestDB = inputGeneration(nRequests);    % Pre-generating randomised requests - Note that the resourec allocation is only allowed to loo

% IT resource allocation
for i = 1:nRequests
  [occupiedMap, requestDB] = resourceAllocation(i, requestDB, networkMap, occupiedMap, distanceMap, latencyMap, bandwidthMap);
end

% Network resource allocation 
% Need to get a better understanding of network resource allocation code


% Generate and plot results (Analysis)
% Need to write a separate function that generates/prints all the results
% and plots for the entire simulation
