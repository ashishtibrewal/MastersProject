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
  
  latencyCM_MSfactor = 2;                 % "Scalibility" factor between CM and MS latency
  latencyRangeCM = 50;                   % Range of acceptable latency values (Must be a multiple of 500)
  latencyMinCM = 250;                    % In ns (i.e. nanoseconds)
  latencyMaxCM = 600;                   % In ns (i.e. nanoseconds)
  
  latencyMinMS = latencyMinCM * latencyCM_MSfactor;       % In ns (i.e. nanoseconds) -> 10x HIGHER acceptable (min) latency between MEM & STO
  latencyMaxMS = latencyMaxCM * latencyCM_MSfactor;       % In ns (i.e. nanoseconds) -> 10x HIGHER acceptable (max) latency between MEM & STO
  latencyRangeMS = latencyRangeCM * latencyCM_MSfactor;   % Range of acceptable latency values (Must be a multiple of 1000)
  
  holdTimeMin = 1;                        % In s (i.e. seconds)
  holdTimeMax = 1000;                     % In s (i.e. seconds)
  
  arrivalRateMin = 0;                     % Minimum number of requests generated per second
  arrivalRateMax = 5;                     % Maximum number of requests generated per second
  arrivalRateAverage = 3;                 % Average number of requests generated per second (i.e. lambda in a Poisson pdf)
  lambda = arrivalRateAverage;            % Lamba (Mean/average) used in the Poisson distribution to generate arrival-time
  
  totalRequestsGenerated = 0;             % Initialize total requests generated
  DBindex = 1;                            % Initialize database index
  time = 0;                               % Stores value of time (in seconds)
  
  requestDB = cell(nRequests, 17);        % Matrix to store all generated requests (Each row contains a different request)
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
  % Column 17 -> Arrival time
  
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
  
  % Start infinite loop to simulate time (in seconds) - Break out once the 
  % required number of requests have been generated
  while(1) 
    % Number of requests generated for current time
    %currentRequests = poissrnd(lambda,[1,1]);   % Generate a random number of requests from a Poisson distribution
    currentRequests = 1;                         % Maximum of 1 request per second
    
    % Generate time (in seconds) at which the request is generated
    arrivalTime = poissrnd(10,[1,1]);             % Generate a random arrival time from a Poisson distribution
    
    % Increment time (i.e. increment upto arrival time of current request)
    time = time + arrivalTime;
    
    % Check to prevent total requests going over the limit
    if ((totalRequestsGenerated + currentRequests) > nRequests)
      currentRequests = nRequests - totalRequestsGenerated;
    end
    
    % Increment total requests generated
    totalRequestsGenerated = totalRequestsGenerated + currentRequests;
    
    % Iterate to generate the required number of requests for current time
    for i = 1:currentRequests
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
      %nBAN_MS = randi((bandwidthMaxMS/bandwidthMinMS)) * bandwidthMinMS;
      nBAN_MS = nBAN_CM * bandwidthCM_MSfactor;     % To prevent MEM-STO being higher than CPU-MEM
      
      % CPU - Memory latency
      nLAT_CM = randi([(latencyMinCM/latencyRangeCM),(latencyMaxCM/latencyRangeCM)]) * latencyRangeCM;
      
      % Memory - Storage latency
      %nLAT_MS = randi([(latencyMinMS/latencyRangeMS),(latencyMaxMS/latencyRangeMS)]) * latencyRangeMS;
      nLAT_MS = nLAT_CM * latencyCM_MSfactor;       % To prevent MEM-STO being higher than CPU-MEM
      
      % Request holdtime (TODO Could use a Poisson distribution)
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
      
      % Arrival-time
      AT = time;
      
      % Collect/store data generated over i iterations
      requestDB(DBindex,:) = {nCPU, nMEM, nSTO, nBAN_CM, nBAN_MS, nLAT_CM, nLAT_MS, nHDT, 0, 0, 0, {}, {}, 'NONE', 'NONE', {}, AT};
      %testRequest = {64,128,256,100,50,10000,20000,4000,0,0,0,{},{},'NONE','NONE',{}, AT};    % Test request used for debugging
      %requestDB(i,:) = testRequest;
  
      if (scatterPlot == 1)
        % Store all iteration numbers/values
        is(:,DBindex) = i;
        % Store all nCPU values
        nCPUs(:,DBindex) = nCPU;
        nMEMs(:,DBindex) = nMEM;
        nSTOs(:,DBindex) = nSTO;
        nBAN_CMs(:,DBindex) = nBAN_CM;
        nLAT_CMs(:,DBindex) = nLAT_CM;
      end
      
      % Increment database index
      DBindex = DBindex + 1;
    end
    
    % If all required requests have been generated, break out of the outer
    % (time) loop
    if (totalRequestsGenerated == nRequests)
      break;
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