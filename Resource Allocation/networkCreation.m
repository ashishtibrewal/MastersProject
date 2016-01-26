function [networkMap, occupiedMap, distanceMap, latencyMap, bandwidthMap] =  networkCreation(nRacks, nBlades, nSlots, nUnits)
% Function to create the data center network

% Note that the latency map should have an almost linear relationship
% with the distance map (i.e. If the distance increase, the latency has to
% increase)

% Adjacency matrix

% Could also think of inter-datacenter topology - After I've got the basic
% simulation working

% Assumptions on inter-blade (i.e. intra-blade) need to be made - latency,
% connectivity (i.e. the topology) and the bandwidth capabilities of these
% links need to be set

networkMap = 0;
occupiedMap = 0;
distanceMap = 0;
latencyMap = 0;
bandwidthMap = 0;


% Fully-connected data-center (All racks are connected to all other racks)
rackConnectivity = ones(nRacks);

end