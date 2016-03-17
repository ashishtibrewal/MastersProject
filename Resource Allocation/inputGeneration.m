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
  % NOTE : CM = CPU-MEM & MS = MEM-STO

  cpuMin = 1;                             % In cores
  cpuMax = 32;                            % In cores

  memoryMin = 1;                          % In GBs
  memoryMax = 32;                         % In GBs

  storageMin = 64;                        % In GBs
  storageMax = 256;                       % In GBs

  bandwidthCM_MSfactor = 5;               % "Scalibility" factor between CM and MS bandwidth
  bandwidthMinCM = 25;                    % In Gb/s
  bandwidthMaxCM = 100;                   % In Gb/s
  
  bandwidthMinMS = bandwidthMinCM/bandwidthCM_MSfactor;      % In Gb/s -> 5x LOWER acceptable (min) bandwidth between MEM & STO
  bandwidthMaxMS = bandwidthMaxCM/bandwidthCM_MSfactor;      % In Gb/s -> 5x LOWER acceptable (max) bandwidth between MEM & STO
  
  latencyCM_MSfactor = 10;                % "Scalibility" factor between CM and MS latency
  latencyRangeCM = 1000;                  % Range of acceptable latency values (Must be a multiple of 1000)
  latencyMinCM = 4000;                    % In ns (i.e. nanoseconds)
  latencyMaxCM = 12000;                   % In ns (i.e. nanoseconds)
  
  latencyMinMS = latencyMinCM * latencyCM_MSfactor;       % In ns (i.e. nanoseconds) -> 10x HIGHER acceptable (min) latency between MEM & STO
  latencyMaxMS = latencyMaxCM * latencyCM_MSfactor;       % In ns (i.e. nanoseconds) -> 10x HIGHER acceptable (max) latency between MEM & STO
  latencyRangeMS = latencyRangeCM * latencyCM_MSfactor;   % Range of acceptable latency values (Must be a multiple of 1000)
  
  holdTimeMin = 1;                        % In s (i.e. seconds)
  holdTimeMax = 1000;                     % In s (i.e. seconds)
  
  requestDB = cell(nRequests, 16);        % Matrix to store all generated requests (Each row contains a different request)
  % Column  1 -> CPU
  % Column  2 -> Memory
  % Column  3 -> Storage
  % Column  4 -> Bandwidth (CPU-MEM)
  % Column  5 -> Bandwidth (MEM-STO)
  % Column  6 -> Latency (CPU-MEM)
  % Column  7 -> Latency (MEM-STO)
  % Column  8 -> Hold time
  % Column  9 -> IT resource allocation stats (0 = not allocated, 1 = allocated)
  % Column 10 -> Network resource allocation stats (0 = not allocated, 1 = allocated)
  % Column 11 -> Request status (0 = not served, 1 = served, 2 = rejected)
  % Column 12 -> IT resource nodes allocated
  % Column 13 -> NET resource (links) allocated
  % Column 14 -> IT failure cause
  % Column 15 -> NET failure cause
  % Column 16 -> Allocated path latencies
  
  distributionPlot = 0;   % Flag variable to check if anything needs to be plotted
  scatterPlot = 0;
  
  if (scatterPlot == 1)
    figure ('Name', 'Input Request Scatter Plot', 'NumberTitle', 'off');
    hold on;
    is = zeros(1,nRequests);
    nCPUs = zeros(1,nRequests);
    nMEMs = zeros(1,nRequests);
    nSTOs = zeros(1,nRequests);
    nBAN_CMs = zeros(1,nRequests);
    nLAT_CMs = zeros(1,nRequests);
  end
  
  % CPU-MEM logarithm (base) factor
  logBaseCPU_MEM = 1.4;
  
  % Iterate to generate the required number of requests
  for i = 1:nRequests
    % CPU
    nCPU = randi([cpuMin,cpuMax]);
    if (mod(nCPU,2) ~= 0)   % Check to prevent odd number of CPUs
      nCPU = nCPU + 1;
    end
    
    % Memory
    nMEM = round(logb(nCPU,logBaseCPU_MEM));   %nMEM = round(logb(nCPU,2));
    if (mod(nMEM,2) ~= 0)   % Check to prevent odd number of MEMs
      nMEM = nMEM + 1;
    end
    
    % Storage
    nSTO = randi([storageMin,storageMax]);
    if (mod(nSTO,2) ~= 0)   % Check to prevent odd number of STOs
      nSTO = nSTO + 1;
    end
    
    % CPU - Memory bandwidth
    nBAN_CM = randi((bandwidthMaxCM/bandwidthMinCM)) * bandwidthMinCM;
    
    % Memory - Storage bandwidth
    nBAN_MS = randi((bandwidthMaxMS/bandwidthMinMS)) * bandwidthMinMS;
    
    % CPU - Memory latency
    nLAT_CM = randi([(latencyMinCM/latencyRangeCM),(latencyMaxCM/latencyRangeCM)]) * latencyRangeCM;
    
    % Memory - Storage latency
    nLAT_MS = randi([(latencyMinMS/latencyRangeMS),(latencyMaxMS/latencyRangeMS)]) * latencyRangeMS;
    
    % Request holdtime
    nHDT = randi((holdTimeMax/holdTimeMin)) * holdTimeMin;
    
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
    
    if (nBAN_CM < bandwidthMinCM)
      nBAN_CM = bandwidthMinCM;
    elseif (nBAN_CM > bandwidthMaxCM)
      nBAN_CM = bandwidthMaxCM;
    end
    
    if (nBAN_MS < bandwidthMinMS)
      nBAN_MS = bandwidthMinMS;
    elseif (nBAN_MS > bandwidthMaxMS)
      nBAN_MS = bandwidthMaxMS;
    end
    
    if (nLAT_CM < latencyMinCM)
      nLAT_CM = latencyMinCM;
    elseif (nLAT_CM > latencyMaxCM)
      nLAT_CM = latencyMaxCM;
    end
    
    if (nLAT_MS < latencyMinMS)
      nLAT_MS = latencyMinMS;
    elseif (nLAT_MS > latencyMaxMS)
      nLAT_MS = latencyMaxMS;
    end
    
    if (nHDT < holdTimeMin)
      nHDT = holdTimeMin;
    elseif (nHDT > holdTimeMax)
      nHDT = holdTimeMax;
    end
    
    % Collect/store data generated over i iterations
    %testRequest = {64,128,256,100,50,10000,20000,4000,0,0,0,{},{},'NONE','NONE',{}};    % Test request used for debugging
    %requestDB(i,:) = testRequest;
    requestDB(i,:) = {nCPU, nMEM, nSTO, nBAN_CM, nBAN_MS, nLAT_CM, nLAT_MS, nHDT, 0, 0, 0, {}, {},'NONE','NONE',{}};

    if (scatterPlot == 1)
      % Store all iteration numbers/values
      is(:,i) = i;
      % Store all nCPU values
      nCPUs(:,i) = nCPU;
      nMEMs(:,i) = nMEM;
      nSTOs(:,i) = nSTO;
      nBAN_CMs(:,i) = nBAN_CM;
      nLAT_CMs(:,i) = nLAT_CM;
    end
  end

  if (scatterPlot == 1)
    % Scatter plot each field individually to obtain different colours
    scatter(is,nCPUs,'^');
    scatter(is,nMEMs,'x');
    scatter(is,nSTOs,'s');
    scatter(is,nBAN_CMs,'filled','d');
    scatter(is,nLAT_CMs,'filled','h');
    
    % Plot legend and axis labels
    legend({'CPU (Cores)','MEM (GB)','STO (GB)','BAN (GB/s)','LAT (ns)'},'Location','NE');
    xlabel('Request no.');
    ylabel('Quantity');
  end
  
  if (distributionPlot == 1)
    nbins = 100;
    figure ('Name', 'Input (Discrete) Probability Distributions', 'NumberTitle', 'off','Position', [40, 100, 1200, 700]);

    subplot(2,4,1);
    histogram(cell2mat(requestDB(:,1)),nbins);
    title('CPU distribution');

    subplot(2,4,2);
    histogram(cell2mat(requestDB(:,2)),nbins);
    title('Memory distribution');
    
    subplot(2,4,3);
    histogram(cell2mat(requestDB(:,4)),nbins);
    title('CPU-MEM Bandwidth distribution');
    
    subplot(2,4,4);
    histogram(cell2mat(requestDB(:,5)),nbins);
    title('MEM-STO Bandwidth distribution');
    
    subplot(2,4,5);
    histogram(cell2mat(requestDB(:,8)),nbins);
    title('Holdtime distribution');

    subplot(2,4,6);
    histogram(cell2mat(requestDB(:,3)),nbins);
    title('Storage distribution');

    subplot(2,4,7);
    histogram(cell2mat(requestDB(:,6)),nbins);
    title('CPU-MEM Latency distribution');
    
    subplot(2,4,8);
    histogram(cell2mat(requestDB(:,7)),nbins);
    title('MEM-STO Latency distribution');
  end 

end