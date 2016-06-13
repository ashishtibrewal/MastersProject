function [dataCenterMap, ITallocationResult, NETallocationResult, ITresourceNodesAllocated, ...
          NETresourcesAllocaed, ITfailureCause, NETfailureCause, pathLatenciesAllocated, timeTaken, pathsUnitMax, ...
          pathsBandwidth] = resourceAllocation(request, dataCenterConfig, dataCenterMap, dataCenterItems)
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
  holdTimeMapIT = dataCenterMap.holdTimeMapIT;
  holdTimeMapNET = dataCenterMap.holdTimeMapNET;

  % Extract data center configuration parameters
  nRacks = dataCenterConfig.nRacks;
  nBlades = dataCenterConfig.nBlades;
  nSlots = dataCenterConfig.nSlots;
  nUnits = dataCenterConfig.nUnits;
  nTORs = dataCenterConfig.nTOR;
  nTOBs = dataCenterConfig.nTOB;

  unitSizeCPU = dataCenterConfig.unitSize.CPU;
  unitSizeMEM = dataCenterConfig.unitSize.MEM;
  unitSizeSTO = dataCenterConfig.unitSize.STO;
  
  % Extract total number of units of each type of resource
  nCPU_units = dataCenterItems.nCPU_units;
  nMEM_units = dataCenterItems.nMEM_units;
  nSTO_units = dataCenterItems.nSTO_units;

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
  requiredCPU = request{1};
  requiredMEM = request{2};
  requiredSTO = request{3};
  requiredHDT = request{8};   % (Same) Hold time applies to both the IT and network resources
  
  % Extract required maps from the data center map struct
  completeResourceMap = dataCenterMap.completeResourceMap;
  completeUnitAvailableMap = dataCenterMap.completeUnitAvailableMap;
  updatedUnitAvailableMap = completeUnitAvailableMap;   % Copy of the original unit available map on which changes are made
  
  % IMPORTANT NOTE: A unit can only be allocated to a single request.
  % Updates/changes are made to the copies of the original maps and the
  % original maps are only updated once the ALL required resources for a
  % request have been allocated.
  
  % Evaluate number of bins (i.e. units inside a slot) required for each
  % resource (Using the ceil function to round up to the closest integer)
  reqCPUunits = ceil(requiredCPU/unitSizeCPU);    % Number of CPU units required
  reqMEMunits = ceil(requiredMEM/unitSizeMEM);    % Number of MEM units required
  reqSTOunits = ceil(requiredSTO/unitSizeSTO);    % Number of STO units required
  
  % Copying values to different variables (to keep variable names consistent across all algorithms)
  CPUunitsRequired = reqCPUunits;
  MEMunitsRequired = reqMEMunits;
  STOunitsRequired = reqSTOunits;
  
  % Evaluate minimum number of slots required
  minReqCPUslots = floor(reqCPUunits/nUnits);    % Number of CPU slots required
  minReqMEMslots = floor(reqMEMunits/nUnits);    % Number of MEM slots required
  minReqSTOslots = floor(reqSTOunits/nUnits);    % Number of STO slots required
  
  % Check to avoid minimum required slots being zero
  if (minReqCPUslots == 0)
    minReqCPUslots = 1;
  end
  if (minReqMEMslots == 0)
    minReqMEMslots = 1;
  end
  if (minReqSTOslots == 0)
    minReqSTOslots = 1;
  end
  
  % Pack required resource units into a struct
  reqResourceUnits.reqCPUunits = reqCPUunits;
  reqResourceUnits.reqMEMunits = reqMEMunits;
  reqResourceUnits.reqSTOunits = reqSTOunits;
  
  % Initialize number of bins (i.e. units inside a slot) allocated for each
  % resource
  nCPUunitsAllocated = 0;   % Number to CPU units successfully allocated
  nMEMunitsAllocated = 0;   % Number to MEM units successfully allocated
  nSTOunitsAllocated = 0;   % Number to STO units successfully allocated
  
  % Extract locations for each type of resource
  CPUlocations = dataCenterMap.locationMap.CPUs;
  MEMlocations = dataCenterMap.locationMap.MEMs;
  STOlocations = dataCenterMap.locationMap.STOs;

  % Extract locations of resources
  ITlocations = dataCenterMap.completeResourceMap;
  
  % Find number of units in slots of specific resource types
  CPUunitsInSlots = [CPUlocations; completeUnitAvailableMap(CPUlocations)];
  MEMunitsInSlots = [MEMlocations; completeUnitAvailableMap(MEMlocations)];
  STOunitsInSlots = [STOlocations; completeUnitAvailableMap(STOlocations)];
  
  % Find slots of specific resource that have at least a single unit free/available
  availableCPUslots = find(CPUunitsInSlots(2,:) > 0);
  availableMEMslots = find(MEMunitsInSlots(2,:) > 0);
  availableSTOslots = find(STOunitsInSlots(2,:) > 0);
  
  % Find the total number of slots available for each resource type
  nCPUslotAvailable = size(availableCPUslots,2);
  nMEMslotAvailable = size(availableMEMslots,2);
  nSTOslotAvailable = size(availableSTOslots,2);
  
  % Find total units available in the available slots
  availableCPUunits =  sum(CPUunitsInSlots(2,availableCPUslots),2);
  availableMEMunits =  sum(MEMunitsInSlots(2,availableMEMslots),2);
  availableSTOunits =  sum(STOunitsInSlots(2,availableSTOslots),2);
  
  str = sprintf('Slot availability (units) -> CPU: %d (%d)  MEM: %d (%d)  STO: %d (%d)', nCPUslotAvailable, availableCPUunits, nMEMslotAvailable, availableMEMunits, nSTOslotAvailable, availableSTOunits);
  disp(str);
  
  %%%%%% MAIN IT RESOURCE ALLOCATION ALGORITHM %%%%%%
  
  % Start/reset timer for each request (i.e. each function invokation) - Starting here since the main allocation algorithm starts here
  tic;
  
  % Primary scanning loop iterator (Jump to atleast the next rack)
  loopIncrement = nSlots * nBlades;

  ITresourceUnavailable = 0;    % Initialize/reset IT resource unavailable for every iteration of the loop
  NETresourceUnavailable = 0;   % Initialize/reset NET resource unavailable for every iteration of the loop
  ITsuccessful = FAILURE;       % Initialize/reset IT successful for every iteration of the loop
  NETsuccessful = FAILURE;      % Initialize/reset NET successful for every iteration of the loop
  heldITresources = {};         % Initialize/reset held IT resources for every iteration of the loop
  heldNETresources = {};        % Initialize/reset held NET resources for every iteration of the loop
  ITfailureCause = 'NONE';      % Initialize/reset IT resource allocation failure cause for every iteration of the loop
  NETfailureCause = 'NONE';     % Initialize/reset NET resource allocation failure cause for every iteration of the loop
  pathLatenciesAllocated = {};  % Initialize/reset path latencies for every iteration of the loop

  nCPU_SlotsToScan = size(CPUlocations,2);  % Number of slots to scan
  nMEM_SlotsToScan = size(MEMlocations,2);  % Number of slots to scan
  nSTO_SlotsToScan = size(STOlocations,2);  % Number of slots to scan
  totalSlotsToScan = size(ITlocations, 2);    % Total number of slots to scan
  scanStartNode = (nTORs * nRacks) + (nTOBs * nBlades * nRacks) + 1;    % First non-switch node
  
  % Find the number of slots that are free
  nAvailableCPUslots = size(availableCPUslots,2);
  nAvailableMEMslots = size(availableMEMslots,2);
  nAvailableSTOslots = size(availableSTOslots,2);

  if ((nCPU_SlotsToScan == 0) || (nAvailableCPUslots < minReqCPUslots))        % Don't need to search any further since no (or not enough) CPU slots are available
    ITresourceUnavailable = 1;
    heldITresources = {};
    ITfailureCause = 'CPU';   % Allocation failed due to unavailibility of CPUs
  elseif ((nMEM_SlotsToScan == 0) || (nAvailableMEMslots < minReqMEMslots))    % Don't need to search any further since no (or not enough) MEM slots are available
    ITresourceUnavailable = 1;
    heldITresources = {};
    ITfailureCause = 'MEM';   % Allocation failed due to unavailibility of MEMs
  elseif ((nSTO_SlotsToScan == 0) || (nAvailableSTOslots < minReqSTOslots))    % Don't need to search any further since no (or not enough) STO slots are available
    ITresourceUnavailable = 1;
    heldITresources = {};
    ITfailureCause = 'STO';   % Allocation failed due to unavailibility of STOs
  else
    % Loop to iterate/try multiple combinations when a particular chosen combination
    % of resources fails and with these nodes removed before the next iteration/try
    for slotNo = scanStartNode:loopIncrement:totalSlotsToScan
      %str = sprintf('Starting node: %d \n', ITlocations(slotNo));
      %disp(str);
      startSlot = scanStartNode;     % Start slot/node
      
      % Initialise variables that keep track to the number of units found
      CPUunitsFound = 0;
      MEMunitsFound = 0;
      STOunitsFound = 0;
      CPUindex = 1;
      MEMindex = 1;
      STOindex = 1;
      
      % Pre-allocate (and initialize) cell to hold resource nodes
      ITresourceNodes = cell(3,max([CPUunitsRequired,MEMunitsRequired,STOunitsRequired]));    % This caters for worst-case allocation (i.e. one unit on each slot)
      
      % Find CPUs, MEMs and STOs by interating over all IT slots
      for slot = startSlot:totalSlotsToScan
        % Extract slot type
        slotType = ITlocations(slot);
        
        % Store the slot type as an integer (Need to do this since the switch-case statement doesn't accept strings).
        if (strcmp(slotType,'CPU'))
          slotTypeInt = 1;
        elseif (strcmp(slotType,'MEM'))
          slotTypeInt = 2;
        elseif (strcmp(slotType,'STO'))
          slotTypeInt = 3;
        end

        % Switch on slot type
        switch (slotTypeInt)
          % CPU slots
          case 1 
            if (CPUunitsFound < CPUunitsRequired)
              if (updatedUnitAvailableMap(slot) > 0)
                unitsFound = updatedUnitAvailableMap(slot);
                if ((CPUunitsRequired - CPUunitsFound) >= unitsFound)
                  CPUunitsFound = CPUunitsFound + unitsFound;
                  ITresourceNodes{1,CPUindex} = {slot,unitsFound};
                else
                  unitsRequired = CPUunitsRequired - CPUunitsFound;
                  CPUunitsFound = CPUunitsFound + unitsRequired;
                  ITresourceNodes{1,CPUindex} = {slot,unitsRequired};
                end
                CPUindex = CPUindex + 1;    % Increment index
              end            
            end
            
          % MEM slots
          case 2
            if (MEMunitsFound < MEMunitsRequired)
              if (updatedUnitAvailableMap(slot) > 0)
                unitsFound = updatedUnitAvailableMap(slot);
                if ((MEMunitsRequired - MEMunitsFound) >= unitsFound)
                  MEMunitsFound = MEMunitsFound + unitsFound;
                  ITresourceNodes{2,MEMindex} = {slot,unitsFound};
                else
                  unitsRequired = MEMunitsRequired - MEMunitsFound;
                  MEMunitsFound = MEMunitsFound + unitsRequired;
                  ITresourceNodes{2,MEMindex} = {slot,unitsRequired};
                end
                MEMindex = MEMindex + 1;    % Increment index
              end            
            end
            
          % STO slots
          case 3
            if (STOunitsFound < STOunitsRequired)
              if (updatedUnitAvailableMap(slot) > 0)
                unitsFound = updatedUnitAvailableMap(slot);
                if ((STOunitsRequired - STOunitsFound) >= unitsFound)
                  STOunitsFound = STOunitsFound + unitsFound;
                  ITresourceNodes{3,STOindex} = {slot,unitsFound};
                else
                  unitsRequired = STOunitsRequired - STOunitsFound;
                  STOunitsFound = STOunitsFound + unitsRequired;
                  ITresourceNodes{3,STOindex} = {slot,unitsRequired};
                end
                STOindex = STOindex + 1;    % Increment index
              end            
            end
        end
        
        % Check if all required resource units have been found
        if ((CPUunitsFound == CPUunitsRequired) && ...
            (MEMunitsFound == MEMunitsRequired) && ...
            (STOunitsFound == STOunitsRequired))
          ITsuccessful = SUCCESS;
          ITfailureCause = 'NONE';
          break;
        else
          ITsuccessful = FAILURE;
          % Failure cause possible values
          % NONE = 0
          % CPU = 1
          % MEM = 2
          % STO = 3
          % CPU & MEM = 4
          % CPU & STO = 5
          % MEM & STO = 6
          CPUfailed = (CPUunitsRequired - CPUunitsFound);
          MEMfailed = (MEMunitsRequired - MEMunitsFound);
          STOfailed = (STOunitsRequired - STOunitsFound);
          if (CPUfailed > 0)
            ITfailureCause = 'CPU';
          elseif (MEMfailed > 0)
            ITfailureCause = 'MEM';
          elseif (STOfailed > 0)
            ITfailureCause = 'STO';
          elseif ((CPUfailed > 0) && (MEMfailed > 0))
            ITfailureCause = 'CPU-MEM';
          elseif ((CPUfailed > 0) && (STOfailed > 0))
            ITfailureCause = 'CPU-STO';
          elseif ((MEMfailed > 0) && (STOfailed > 0))
            ITfailureCause = 'MEM-STO';
          end
        end
      end
      
      % Used to compare nodes allocated using the above search scheme with BFS
      %CPUnodesAll = ITresourceNodes{1,:};
      %MEMnodesAll = ITresourceNodes{2,:};
      %STOnodesAll = ITresourceNodes{3,:};
      
      %[ITresourceNodes, ITsuccessful, ITfailureCause] = BFS(dataCenterMap, startSlot, reqResourceUnits, updatedUnitAvailableMap);
  
      %CPUnodesAll = ITresourceNodes{1,:};
      %MEMnodesAll = ITresourceNodes{2,:};
      %STOnodesAll = ITresourceNodes{3,:};
      
      % Check if all resources have been successfully found
      if (ITsuccessful == SUCCESS)
        % Locations of resources that are "held" for the current request
        heldITresources = ITresourceNodes;
        % TODO Add network allocation code - if network is successful, break out else start search for new 
        % IT slots from next available resource node
        [NETresourceLinks, NETsuccessful, NETfailureCause, updatedBandwidthMap, failureNodes, pathLatenciesAllocated, pathsUnitMax, pathsBandwidth] = networkAllocation(request, heldITresources, dataCenterMap, dataCenterConfig);
        if (NETsuccessful == SUCCESS)
          heldNETresources = NETresourceLinks;
          break;    % Can only break out of the for loop if **both** IT and network resources are satisfied else start scanning from next available slot
        else
          heldNETresources = {};
          NETresourceUnavailable = 1;
          %disp(NETfailureCause);
          heldITresources = {};   % Free/empty held held resources cell network allocation failed for this set of IT resources
          % Update copy of unit available map to avoid BFS finding the same nodes that were "held" in the previous iteration
          updatedUnitAvailableMap(failureNodes) = 0;    % Set units available in failure nodes to be zero

          % Find number of units in slots of specific resource types
          CPUunitsInSlots_updated = [CPUlocations; updatedUnitAvailableMap(CPUlocations)];
          MEMunitsInSlots_updated = [MEMlocations; updatedUnitAvailableMap(MEMlocations)];
          STOunitsInSlots_updated = [STOlocations; updatedUnitAvailableMap(STOlocations)];

          % Find slots of specific resource that have at least a single unit free/available
          availableCPUslots_updated = find(CPUunitsInSlots_updated(2,:) > 0);
          availableMEMslots_updated = find(MEMunitsInSlots_updated(2,:) > 0);
          availableSTOslots_updated = find(STOunitsInSlots_updated(2,:) > 0);

          % Find total units available in the available slots
          availableCPUunits_updated =  sum(CPUunitsInSlots_updated(2,availableCPUslots_updated),2);
          availableMEMunits_updated =  sum(MEMunitsInSlots_updated(2,availableMEMslots_updated),2);
          availableSTOunits_updated =  sum(STOunitsInSlots_updated(2,availableSTOslots_updated),2);

          % Need to do this check since the actual failure cause is not unavailibility of IT resources but the 
          % unavailibility of NET resources
          if (availableCPUunits_updated < reqCPUunits || availableMEMunits_updated < reqMEMunits || availableSTOunits_updated < reqSTOunits)
            break;
          end
        end
      else
        ITresourceUnavailable = 1;
        heldITresources = {};
        pathLatenciesAllocated = {};
        break;      % Break out of the inner loop since required number of IT resources couldn't be found
      end
    end
  end

  % Stop/record timer for each request (Stop here since everything after
  % this is mainly post processing)
  timeTaken = toc;

  % Break out of loop if both IT and netowrk resources have been successfully allocated
  if (ITsuccessful == SUCCESS && NETsuccessful == SUCCESS)
    ITresult = SUCCESS;
    NETresult = SUCCESS;
    str = sprintf('Resources allocated for current request. Time taken: %.2fs \n', timeTaken);
    disp(str);
    % Update complete unit/resource available map
    for i = 1:size(heldITresources,1)
      for j = 1:size(heldITresources,2)
        if (~isempty(heldITresources{i,j}))
          resourceNode = heldITresources{i,j}{1,1};
          unitsOccupied = heldITresources{i,j}{1,2};
          dataCenterMap.completeUnitAvailableMap(resourceNode) = dataCenterMap.completeUnitAvailableMap(resourceNode) - unitsOccupied;
        end
      end
    end
    % Update bandwidth map (i.e. subtract amount of bandwidth used on a link)
    dataCenterMap.bandwidthMap.completeBandwidth = updatedBandwidthMap;
  else
    ITresult = FAILURE;
    NETresult = FAILURE;
    if (ITresourceUnavailable == 1)
      str = sprintf('Resources (IT) unavailable for current request (Cause: %s)! Time taken: %.2fs \n', ITfailureCause, timeTaken);
      disp(str);
    elseif (NETresourceUnavailable == 1)
      str = sprintf('Resources (NET) unavailable for current request (Cause: %s)! Time taken: %.2fs \n', NETfailureCause, timeTaken);
      disp(str);
    end
  end   
  
  %%%%%% UPDATE GLOBAL MAPS & OUTPUT RESULTS %%%%%% 
  ITallocationResult = ITresult;
  NETallocationResult = NETresult;
  ITresourceNodesAllocated = heldITresources;
  NETresourcesAllocaed = heldNETresources;
  
  % Update holdtime map (Need one for resources and one for bandwidth)
  
end
