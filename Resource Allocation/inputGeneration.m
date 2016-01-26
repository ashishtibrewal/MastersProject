function requestDB = inputGeneration(nRequests)
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

  % Declare datacenter constants
  
  CPUs = 1024;        % Total CPUs in the datacenter
  MEMs = 4096;        % Todal amount of memory in the datacenter
  STOs = 8192;        % Total amount of storage in the datacenter

  cpuMin = 1;               % In cores
  cpuMax = 16;              % In cores

  memoryMin = 1;            % In GBs
  memoryMax = 32;           % In GBs

  storageMin = 1;           % In GBs
  storageMax = 256;         % In GBs

  bandwidhtMin = 10;        % In Gb/s
  bandwidhtMax = 400;       % In Gb/s
  
  latencyMin = 5;           % In ns (i.e. nanoseconds)
  latencyMax = 100;         % In ns (i.e. nanoseconds)
  
  holdTimeMin = 1;          % In s (i.e. seconds)
  holdTimeMax = 10000000;   % In s (i.e. seconds)
  
  requestDB = (zeros(nRequests, 7));  % Matrix to store all generated requests (Each row contains a different request)
  % Column 1 -> CPU
  % Column 2 -> Memory
  % Column 3 -> Storage
  % Column 4 -> Bandwidth
  % Column 5 -> Latency
  % Column 6 -> Hold time
  % Column 7 -> Request status (0 = not served, 1 = served, 2 = rejected)
  
%   figure;
%   hold on;

  plot = 0;   % Flag variable to check if anything needs to be plotted
  
  % Iterate to generate the required number of requests
  for i = 1:nRequests
    CPU = log2(cpuMax) * rand(1);
    MEM = log2(memoryMax) * rand(1);
    STO = log2(storageMax) * rand(1);
    BWH = log2(bandwidhtMax) * rand(1);
    LAT = log2(latencyMax) * rand(1);
    HDT = log2(holdTimeMax) * rand(1);

    if (CPU == 0)
      CPU = cpuMin;
    end
    
    if (MEM == 0)
      MEM = memoryMin;
    end
    
    if (STO == 0)
      STO = storageMin;
    end
    
    if (BWH == 0)
      BWH = bandwidthMin;
    end
    
    if (LAT == 0)
      LAT = latencyMin;
    end
    
    if (HDT == 0)
      HDT = holdTimeMin;
    end
    
    nCPU = round(2^CPU);   % Required number of compute units for this request
    nMEM = round(2^MEM);   % Required number of memory units for this request
    nSTO = round(2^STO);   % Required number of storage units for this request
    nBAN = round(2^BWH);   % Required (minimum) bandwidth for this request
    nLAT = round(2^LAT);   % Required (maximum) latency for this request
    nHDT = round(2^HDT);   % Required holdtime for this request
    
    % Collect/store data generated over i iterations
    requestDB(i,:) = [nCPU, nMEM, nSTO, nBAN, nLAT, nHDT, 0];
    
%     scatter(i,nCPU,'filled');
%     scatter(i,nMEM,'filled');
%     scatter(i,nSTO,'filled');
%     scatter(i,nBAN,'filled');
  end  
  
  if (plot == 1)
    nbins = 100;
    figure ('Name', 'Input Distributions', 'NumberTitle', 'off');

    subplot(2,3,1);
    histogram(requestDB(:,1),nbins);
    title('CPU distribution');

    subplot(2,3,2);
    histogram(requestDB(:,2),nbins);
    title('Memory distribution');

    subplot(2,3,3);
    histogram(requestDB(:,3),nbins);
    title('Storage distribution');

    subplot(2,3,4);
    histogram(requestDB(:,4),nbins);
    title('Bandwidth distribution');

    subplot(2,3,5);
    histogram(requestDB(:,5),nbins);
    title('Latency distribution');
    
    subplot(2,3,6);
    histogram(requestDB(:,6),nbins);
    title('Holdtime distribution');
  end 

end