function [cpu, memory, storage, latency, bandwidth] = inputGeneration()
% inputGeneration - Function to generate the input that feeds into the
% resource allocation algorithm
%   Funtion return values:
%     cpu - number of cpu units required
%     memory - number of memory units requried
%     storage - number of storage units requried
%     latency - network latency constraint
%     bandwidth - network bandwidth constraint
%   Notes:
%     Design could explicilty output number of cores and this could be 
%     factored in in the main resource allocation algorithm.
%     Could also test how the performance scales when the input minimum and
%     maximum values for memory, cpu, storage, latency and bandwidth are
%     changed.

% Input generation code goes here
cpuMin = 1;
cpuMax = 64;

memoryMin = 1;
memoryMax = 8;

storageMin = 1;
storageMax = 10;


end

