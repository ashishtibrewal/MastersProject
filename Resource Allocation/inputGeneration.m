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

  CPUs = 1024;        % Total CPUs in the datacenter
  MEMs = 4096;        % Todal amount of memory in the datacenter
  STOs = 8192;        % Total amount of storage in the datacenter

  cpuMin = 1;
  cpuMax = 16;

  memoryMin = 1;
  memoryMax = 32;

  storageMin = 1;
  storageMax = 32;

  bandwidhtMin = 10;        % In Gb/s
  bandwidhtMax = 400;       % In Gb/s

%   figure;
%   hold on;
  
  for i = 1:100000
    CPU = log2(cpuMax) * rand (1,1);
    MEM = log2(memoryMax) * rand (1,1);
    STO = log2(storageMax) * rand (1,1);
    BWH = log2(bandwidhtMax) * rand(1,1);

    if CPU == 0
      CPU = cpuMin;
    end
    
    if MEM == 0
      MEM = memoryMin;
    end
    
    if STO == 0
      STO = storageMin;
    end
    
    if BWH == 0
      BWH = bandwidthMin;
    end
    
    nCPU = round(2^CPU);   % Required number of compute units for this request
    nMEM = round(2^MEM);   % Required number of memory units for this request
    nSTO = round(2^STO);   % Required number of storage units for this request
    nBAN = round(2^BWH);   % Required bandwidth for this request
    % nCPU = customDistribution(CPU);
    
    % Collect/store data generated over i iterations
    CPUi(i) = nCPU;
    MEMi(i) = nMEM;
    STOi(i) = nSTO;
    BWHi(i) = nBAN;
%     scatter(i,nCPU,'filled');
%     scatter(i,nMEM,'filled');
%     scatter(i,nSTO,'filled');
%     scatter(i,nBAN,'filled');
  end
  
  nbins = 100;
  figure(1);
  histogram(CPUi,nbins);
  title('CPU distribution');
  figure(2);
  histogram(MEMi,nbins);
  title('Memory distribution');
  figure(3);
  histogram(STOi,nbins);
  title('Storage distribution');
  figure(4);
  histogram(BWHi,nbins);
  title('Bandwidth distribution');
end

% function value = customDistribution(randNum)
% 
% 
% end

