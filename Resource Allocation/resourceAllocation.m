function [dataCenterMap, ITallocationResult, NETallocationResult, ITresourceNodesAllocated] = resourceAllocation(request, dataCenterConfig, dataCenterMap, dataCenterItems)
  % Function to allocate the IT resources
  % NEED TO PLAN AND TRY DIFFERENT APPROACHES.
  
  % Import global macros
  global SUCCESS;
  global FAILURE;
  
  % Extract data center network maps
  connectivityMap = dataCenterMap.connectivityMap;
  availableMap = dataCenterMap.availableMap;
  distanceMap = dataCenterMap.distanceMap;
  latencyMap = dataCenterMap.latencyMap;
  bandwidthMap = dataCenterMap.bandwidthMap;
  holdTimeMap = dataCenterMap.holdTimeMap;

  % Extract data center configuration parameters
  nRacks = dataCenterConfig.nRacks;
  nBlades = dataCenterConfig.nBlades;
  nSlots = dataCenterConfig.nSlots;
  nUnits = dataCenterConfig.nUnits;

  unitSizeCPU = dataCenterConfig.unitSize.CPU;
  unitSizeMEM = dataCenterConfig.unitSize.MEM;
  unitSizeSTO = dataCenterConfig.unitSize.STO;
  
  % Extract total number of units of each type of resource
  nCPU_units = dataCenterItems.nCPU_units;
  nMEM_units = dataCenterItems.nMEM_units;
  nSTO_units = dataCenterItems.nSTO_units;

  % Obtain the required resource values from the request
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
  % Column 12 -> Resource nodes allocated
  requiredCPU = request{1};
  requiredMEM = request{2};
  requiredSTO = request{3};
  requiredBAN_CM = request{4};    % MAXIMUM ACCEPTABLE BANDWIDTH (CPU-MEM)
  requiredBAN_MS = request{5};    % MAXIMUM ACCEPTABLE BANDWIDTH (MEM-STO)
  requiredLAT_CM = request{6};    % MAXIMUM ACCEPTABLE LATENCY (CPU-MEM)
  requiredLAT_MS = request{7};    % MAXIMUM ACCEPTABLE LATENCY (MEM-STO)
  requiredHDT = request{8};   % (Same) Hold time applies to both the IT and network resources

  % Flags that are set when a required resource has been alloated
  assignedCPU = 0;
  assignedMEM = 0;
  assignedSTO = 0;
  
  % Extract required maps from the data center map struct
  completeResourceMap = dataCenterMap.completeResourceMap;
  completeunitAvailableMap = dataCenterMap.completeUnitAvailableMap;
  
  % IMPORTANT NOTE: A unit can only be allocated to a single request.
  % Updates/changes are made to the copies of the original maps and the
  % original maps are only updated once the ALL required resources for a
  % request have been allocated.
  
  % Evaluate number of bins (i.e. units inside a slot) required for each
  % resource (Using the ceil function to round up to the closest integer)
  reqCPUunits = ceil(requiredCPU/unitSizeCPU);    % Number of CPU slots required
  reqMEMunits = ceil(requiredMEM/unitSizeMEM);    % Number of MEM slots required
  reqSTOunits = ceil(requiredSTO/unitSizeSTO);    % Number of STO slots required
  
  % Pack required resource units into a struct
  reqResourceUnits.reqCPUunits = reqCPUunits;
  reqResourceUnits.reqMEMunits = reqMEMunits;
  reqResourceUnits.reqSTOunits = reqSTOunits;
  
  % Initialize number of bins (i.e. units inside a slot) allocated for each
  % resource
  nCPUunitsAllocated = 0;   % Number to CPU units successfully allocated
  nMEMunitsAllocated = 0;   % Number to MEM units successfully allocated
  nSTOunitsAllocated = 0;   % Number to STO units successfully allocated
  
  % Evaluate contention ratios (Do it in terms of units and not total
  % values since the allocation is being done in units)
  crCPU = reqCPUunits/nCPU_units;
  crMEM = reqMEMunits/nMEM_units;
  crSTO = reqSTOunits/nSTO_units;
  
  contentionRatios = [crCPU,crMEM,crSTO];
  maxCR = max(contentionRatios);
  maxCRindex = find(contentionRatios == maxCR);
  % If all types have equal contention ratios, prioritise CPUs 
  if (size(maxCRindex,2) > 1)
    maxCRindex = 1;
  end
  switch(maxCRindex)
    case 1
      maxCRswitch = 'CPU';
      str = sprintf('CPU has the highest contention ratio.');
      disp(str);
    case 2
      maxCRswitch = 'MEM';
      str = sprintf('MEM has the highest contention ratio.');
      disp(str);
    case 3
      maxCRswitch = 'STO';
      str = sprintf('STO has the highest contention ratio.');
      disp(str);
  end
  
  % Extract locations for each type of resource
  CPUlocations = dataCenterMap.locationMap.CPUs;
  MEMlocations = dataCenterMap.locationMap.MEMs;
  STOlocations = dataCenterMap.locationMap.STOs;
  
  % Run infinite loop until **both** IT and network resources have been found
  while (true)
    %%%%%% MAIN IT RESOURCE ALLOCATION ALGORITHM %%%%%%
    
    resourceUnavailable = 0;      % Initialize resource unavailable
    
    % Run BFS to find required (avaliable) resources starting at a specific
    % resoure node with the resource type having the highest contention ratio
    % TODO Start from first unit available node rather than the first node
    % of a specific unit type - This could have a huge performance
    % improvement
    switch (maxCRswitch)
      case 'CPU'
        nCPU_SlotsToScan = size(CPUlocations,2);  % Number of slots to scan
        for slotNo = 1:nCPU_SlotsToScan
          [ITresourceNodes, ITsuccessful] = BFS(dataCenterMap, CPUlocations(slotNo), reqResourceUnits);
          % Check if all resources have been successfully found
          if (ITsuccessful == SUCCESS)
            % Locations of resources that are "held" for the current request
            heldITresources = ITresourceNodes;
            break;
          elseif (slotNo == 2)
            resourceUnavailable = 1;
            break;
          end
        end

        case 'MEM'
        nMEM_SlotsToScan = size(MEMlocations,2);  % Number of slots to scan
        for slotNo = 1:nMEM_SlotsToScan
          [ITresourceNodes, ITsuccessful] = BFS(dataCenterMap, MEMlocations(slotNo), reqResourceUnits);
          % Check if all resources have been successfully found
          if (ITsuccessful == SUCCESS)
            % Locations of resources that are "held" for the current request
            heldITresources = ITresourceNodes;
            break;
          elseif (slotNo == 2)
            resourceUnavailable = 1;
            break;
          end
        end

        case 'STO'
        nSTO_SlotsToScan = size(STOlocations,2);  % Number of slots to scan
        for slotNo = 1:nSTO_SlotsToScan
          [ITresourceNodes, ITsuccessful] = BFS(dataCenterMap, STOlocations(slotNo), reqResourceUnits);
          % Check if all resources have been successfully found
          if (ITsuccessful == SUCCESS)
            % Locations of resources that are "held" for the current request
            heldITresources = ITresourceNodes;
            break;
          elseif (slotNo == 2)
            resourceUnavailable = 1;
            break;
          end
        end
    end

    %%%%%% MAIN NETWORK RESOURCE ALLOCATION ALGORITHM %%%%%%
    % Would need to run k-shortest path on held nodes
    % First check for latency between held nodes, if successful, then find
    % bandwidth on these links
    NETsucceful = SUCCESS;
    
    % Break out of loop if both IT and netowrk resources have been successfully allocated
    if (ITsuccessful == SUCCESS && NETsucceful == SUCCESS)
      ITresult = SUCCESS;
      NETresult = SUCCESS;
      break;
    elseif (resourceUnavailable == 1)       % Break out of while loop if enough resources couldn't be found
      ITresult = FAILURE;
      NETresult = SUCCESS;      % TODO Change later
      str = sprintf('Resource unavailable for current request.');
      disp(str);
      break;
    end    
  end
  
  %%%%%% UPDATE GLOBAL MAPS & OUTPUT RESULTS %%%%%% 
  ITallocationResult = ITresult;
  NETallocationResult = NETresult;
  ITresourceNodesAllocated = ITresourceNodes;
  
  % Update complete unit/resource available map
  for i = 1:size(ITresourceNodesAllocated,1)
    for j = 1:size(ITresourceNodesAllocated,2)
      if (~isempty(ITresourceNodesAllocated{i,j}) && ITresult == SUCCESS)
        resourceNode = ITresourceNodesAllocated{i,j}{1,1};
        unitsOccupied = ITresourceNodesAllocated{i,j}{1,2};
        dataCenterMap.completeUnitAvailableMap(resourceNode) = dataCenterMap.completeUnitAvailableMap(resourceNode) - unitsOccupied;
      end
    end
  end
  
  % Update bandwidth map
  
  % Update holdtime map (Need one for resources and one for bandwidth)
  
end