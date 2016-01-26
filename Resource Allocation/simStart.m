%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Script that starts the simulation %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set up clean environment
clear;      % Clear all variables in the workspace
close all;  % Close all open figures
clc;        % Clear console/command prompt

% Datacenter IT & Network constants
% Insert call to a separate script/function to setup/declare all datacenter
% constants
nRequests = 100000;   % Number of requests to generate
nRacks = 10;          % Number of racks (in the datacenter)
nBlades = 20;         % Number of blades (in each rack)
nSlots = 20;          % Number of slots (in each blade)
nUnits = 20;          % Number of units (in each slot)

unitSizeCPU = 1;      % >1 signifies multi-core (A simplistic approach)
unitSizeMEM = 4;      % Each DIMM is 4 GB in size/capacity
unitSizeSTO = 500;    % Each HDD is 500 GB in size /capacity
unitSizeBWH = 1600;   % Maximum bandwidth available on a link connecting two nodes in the network
unitSizeLAT = 5;      % Minimum latency between two connected (adjacent) nodes is 5 ns (Assuming they are 1 meter apart)
% Note that the latency is 5 ns/m - Higher the distance, higher the latency

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
