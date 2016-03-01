function displayResults(dataCenterMap, requestDB, nRequests, dataCenterConfig)
% Function to generate all the results
% Request database info:
% Column 1 -> CPU
% Column 2 -> Memory
% Column 3 -> Storage
% Column 4 -> Bandwidth
% Column 5 -> Latency
% Column 6 -> Hold time
% Column 7 -> IT resource allocation stats (0 = not allocated, 1 = allocated)
% Column 8 -> Network resource allocation stats (0 = not allocated, 1 = allocated)
% Column 9 -> Request status (0 = not served, 1 = served, 2 = rejected)

str = sprintf('\n+------------------------------------+');
disp(str);
str = sprintf('|     DATA CENTER CONFIGURATION      |');
disp(str);
str = sprintf('+------------------------------------+\n');
disp(str);

str = sprintf('Number of racks: %i', dataCenterConfig.nRacks);
disp(str);
str = sprintf('Number of blades (in each rack): %i', dataCenterConfig.nBlades);
disp(str);
str = sprintf('Number of slots (in each blade): %i', dataCenterConfig.nSlots);
disp(str);

str = sprintf('\n+------------------------------------+');
disp(str);
str = sprintf('|               RESULTS              |');
disp(str);
str = sprintf('+------------------------------------+\n');
disp(str);

% Total number of requests generated
str = sprintf('Number of requests/jobs generated: %i', nRequests);
disp(str);

% Total number of IT resoure allocation failed
nResourceAllocationFailed_IT = size(find(cell2mat(requestDB(:,9)) == 0), 1);
str = sprintf('Number of IT resource allocation failed: %i', nResourceAllocationFailed_IT);
disp(str);

% Total number of network resource allocation failed
nResourceAllocationFailed_Network= size(find(cell2mat(requestDB(:,10)) == 0), 1);
str = sprintf('Number of network resource allocation failed: %i', nResourceAllocationFailed_Network);
disp(str);

% Total number of requests failed/dropped
nRequestDropped = size(find(cell2mat(requestDB(:,11)) == 0), 1);
str = sprintf('Number of requests dropped: %i', nRequestDropped);
disp(str);

% Print statistics for usage (Both IT and network resource usage)
