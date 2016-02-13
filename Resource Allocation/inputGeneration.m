function requestDB = inputGeneration(nRequests)
% Function to generate the input that feeds into the resource allocation 
% algorithm
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

% TODO Need to generate different requried bandwidths for CPU-MEM and
% MEM-STO
% TODO Need to generate these bandwidths based on the number of CPUs
% requested (i.e. there is a correation)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Declare input request constants
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  cpuMin = 1;               % In cores
  cpuMax = 32;              % In cores

  memoryMin = 1;            % In GBs
  memoryMax = 32;           % In GBs

  storageMin = 1;           % In GBs
  storageMax = 256;         % In GBs

  bandwidthMin = 50;        % In Gb/s
  bandwidthMax = 400;       % In Gb/s
  
  latencyMin = 5;           % In ns (i.e. nanoseconds)
  latencyMax = 100;         % In ns (i.e. nanoseconds)
  
  holdTimeMin = 1;          % In s (i.e. seconds)
  holdTimeMax = 100000;     % In s (i.e. seconds)
  
  % Add columns for cpu-mem bandwidth and mem-sto bandwidth
  requestDB = (zeros(nRequests, 9));  % Matrix to store all generated requests (Each row contains a different request)
  % Column 1 -> CPU
  % Column 2 -> Memory
  % Column 3 -> Storage
  % Column 4 -> Bandwidth
  % Column 5 -> Latency
  % Column 6 -> Hold time
  % Column 7 -> IT resource allocation stats (0 = not allocated, 1 = allocated)
  % Column 8 -> Network resource allocation stats (0 = not allocated, 1 = allocated)
  % Column 9 -> Request status (0 = not served, 1 = served, 2 = rejected)
  
  distributionPlot = 0;   % Flag variable to check if anything needs to be plotted
  scatterPlot = 1;
  
  if (scatterPlot == 1)
    figure ('Name', 'Input Request Scatter Plot', 'NumberTitle', 'off');
    hold on;
    is = zeros(1,nRequests);
    nCPUs = zeros(1,nRequests);
    nMEMs = zeros(1,nRequests);
    nSTOs = zeros(1,nRequests);
    nBANs = zeros(1,nRequests);
    nLATs = zeros(1,nRequests);
  end
  
  % CPU-MEM logarithm (base) factor
  logBaseCPU_MEM = 1.4;
  
  % Iterate to generate the required number of requests
  for i = 1:nRequests
    nCPU = round(cpuMax * rand(1));
    nMEM = round(logb(nCPU,logBaseCPU_MEM));   %nMEM = round(logb(nCPU,2));
    nSTO = round(storageMax * rand(1));
    nBAN = round(bandwidthMax * rand(1));
    nLAT = round(latencyMax * rand(1));
    nHDT = round(holdTimeMax * rand(1));
    
    % Boundary checks
    if (nCPU < cpuMin)
      nCPU = cpuMin;
    elseif (nCPU > cpuMax)
      nCPU = cpuMax;
    end
    
    if (nMEM < memoryMin)
      nMEM = memoryMin;
    elseif (nMEM > memoryMax)
      nMEM = memoryMax;
    end
    
    if (nSTO < storageMin)
      nSTO = storageMin;
    elseif (nSTO > storageMax)
      nSTO = storageMax;
    end
    
    if (nBAN < bandwidthMin)
      nBAN = bandwidthMin;
    elseif (nBAN > bandwidthMax)
      nBAN = bandwidthMax;
    end
    
    if (nLAT < latencyMin)
      nLAT = latencyMin;
    elseif (nLAT > latencyMax)
      nLAT = latencyMax;
    end
    
    if (nHDT < holdTimeMin)
      nHDT = holdTimeMin;
    elseif (nHDT > holdTimeMax)
      nHDT = holdTimeMax;
    end
    
    % Collect/store data generated over i iterations
    requestDB(i,:) = [nCPU, nMEM, nSTO, nBAN, nLAT, nHDT, 0, 0, 0];

    if (scatterPlot == 1)
      % Store all iteration numbers/values
      is(:,i) = i;
      % Store all nCPU values
      nCPUs(:,i) = nCPU;
      nMEMs(:,i) = nMEM;
      nSTOs(:,i) = nSTO;
      nBANs(:,i) = nBAN;
      nLATs(:,i) = nLAT;
    end
  end

  if (scatterPlot == 1)
    % Scatter plot each field individually to obtain different colours
    scatter(is,nCPUs,'^');
    scatter(is,nMEMs,'x');
    scatter(is,nSTOs,'s');
    scatter(is,nBANs,'filled','d');
    scatter(is,nLATs,'filled','h');
    
    % Plot legend and axis labels
    legend({'CPU (Cores)','MEM (GB)','STO (GB)','BAN (GB/s)','LAT (ns)'},'Location','NE');
    xlabel('Request no.');
    ylabel('Quantity');
  end
  
  if (distributionPlot == 1)
    nbins = 100;
    figure ('Name', 'Input (Discrete) Probability Distributions', 'NumberTitle', 'off');

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