function [dataCenterMap, ITallocationResult, NETallocationResult, ITresourceNodesAllocated, ...
          NETresourcesAllocaed, ITfailureCause, NETfailureCause, pathLatenciesAllocated, timeTaken, pathsUnitMax, pathsBandwidth] = ...
          resourceAllocation(request, dataCenterConfig, dataCenterMap, dataCenterItems)
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
  completeBandwidthMap = dataCenterMap.bandwidthMap.completeBandwidth;
  
  % IMPORTANT NOTE: A unit can only be allocated to a single request.
  % Updates/changes are made to the copies of the original maps and the
  % original maps are only updated once the ALL required resources for a
  % request have been allocated.
  
  % Evaluate number of bins (i.e. units inside a slot) required for each
  % resource (Using the ceil function to round up to the closest integer)
  reqCPUunits = ceil(requiredCPU/unitSizeCPU);    % Number of CPU units required
  reqMEMunits = ceil(requiredMEM/unitSizeMEM);    % Number of MEM units required
  reqSTOunits = ceil(requiredSTO/unitSizeSTO);    % Number of STO units required
  
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
  
  % Evaluate contention ratios (Do it in terms of units and not total
  % values since the allocation is being done in units) - Required
  % resources over total available resource for each type
  crCPU = reqCPUunits/size(availableCPUslots,2);
  crMEM = reqMEMunits/size(availableMEMslots,2);
  crSTO = reqSTOunits/size(availableSTOslots,2);
  
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
      str = sprintf('Highest CR: CPU. Slot availability (units) -> CPU: %d (%d)  MEM: %d (%d)  STO: %d (%d)', nCPUslotAvailable, availableCPUunits, nMEMslotAvailable, availableMEMunits, nSTOslotAvailable, availableSTOunits);
      disp(str);
    case 2
      maxCRswitch = 'MEM';
      str = sprintf('Highest CR: MEM. Slot availability (units) -> CPU: %d (%d)  MEM: %d (%d)  STO: %d (%d)', nCPUslotAvailable, availableCPUunits, nMEMslotAvailable, availableMEMunits, nSTOslotAvailable, availableSTOunits);
      disp(str);
    case 3
      maxCRswitch = 'STO';
      str = sprintf('Highest CR: STO. Slot availability (units) -> CPU: %d (%d)  MEM: %d (%d)  STO: %d (%d)', nCPUslotAvailable, availableCPUunits, nMEMslotAvailable, availableMEMunits, nSTOslotAvailable, availableSTOunits);
      disp(str);
  end
  
  %%%%%% MAIN IT RESOURCE ALLOCATION ALGORITHM %%%%%%

  % Run BFS to find required (avaliable) resources starting at a specific
  % resoure node with the resource type having the highest contention ratio
  % Starting from first unit available node rather than from the first node
  % of a specific unit type - This can potentially have a huge performance
  % improvement because you avoid running BFS from nodes (i.e. slots that 
  % are already completely occupied) - THIS ALSO IMPROVES THE LOCALITY
  % FACTOR (SPECIALLY LOCALITY BETWEEN CPU & MEM, WHICH IS REALLY
  % IMPORTANT DUE TO LATENCY CONSTRAINTS) SINCE BFS IS RUN STARTING ON A
  % NODE THAT HAS AT LEAST A SINGLE UNIT FREE OF THE RESOURCE TYPE WITH
  % THE HIGHEST CONTENTION RATIO.
  
  % Start/reset timer for each request (i.e. each function invokation) - Starting here since the main allocation algorithm starts here
  tic;
  
  % Primary scanning loop iterator (Jump to atleast the next rack)
  loopIncrement = nSlots * nBlades;

  % Cell array to store all contention ratios (i.e. for each i-th iteration)
  CRs = cell(1,size(contentionRatios,2));

  % Main loop to iterate over all possible contention ratio switches starting from the primary contention ratio switch
  for iCR = 1:size(contentionRatios,2)
    ITresourceUnavailable = 0;      % Initialize/reset IT resource unavailable for every iteration of the loop
    NETresourceUnavailable = 0;     % Initialize/reset NET resource unavailable for every iteration of the loop
    NETresourceUnavailableBFS = 0;  % Initialize/reset NET resource unavailable when using BFS for every iteration of the loop
    ITsuccessful = FAILURE;         % Initialize/reset IT successful for every iteration of the loop
    NETsuccessful = FAILURE;        % Initialize/reset NET successful for every iteration of the loop
    heldITresources = {};           % Initialize/reset held IT resources for every iteration of the loop
    heldNETresources = {};          % Initialize/reset held NET resources for every iteration of the loop
    ITfailureCause = 'NONE';        % Initialize/reset IT resource allocation failure cause for every iteration of the loop
    NETfailureCause = 'NONE';       % Initialize/reset NET resource allocation failure cause for every iteration of the loop
    pathLatenciesAllocated = {};    % Initialize/reset path latencies for every iteration of the loop

    % Store contention ratios
    CRs{iCR} = maxCRswitch;
    % Reset updated unit available map for every iteration (i.e. when using different contention ratio switches)
    updatedUnitAvailableMap = completeUnitAvailableMap;
    % Update/change contention ratio switch on every iteration
    switch (iCR)
      case 2
        if (strcmp(CRs{iCR - 1},'CPU') == 1 || strcmp(CRs{iCR - 1},'STO') == 1)
          CRs{iCR} = 'MEM';
        else
          if (round(rand()) == 0)
            CRs{iCR} = 'STO';
          else
            CRs{iCR} = 'CPU';
          end
        end
        str = sprintf('Switching CR: %s', CRs{iCR});
        %disp(str);
      
      case 3
        if ((strcmp(CRs{iCR - 2},'CPU') == 1 && strcmp(CRs{iCR - 1},'MEM') == 1) || (strcmp(CRs{iCR - 1},'CPU') == 1 && strcmp(CRs{iCR - 2},'MEM') == 1))
          CRs{iCR} = 'STO';
        elseif ((strcmp(CRs{iCR - 2},'CPU') == 1 && strcmp(CRs{iCR - 1},'STO') == 1) || (strcmp(CRs{iCR - 1},'CPU') == 1 && strcmp(CRs{iCR - 2},'STO') == 1))
          CRs{iCR} = 'MEM';
        elseif ((strcmp(CRs{iCR - 2},'MEM') == 1 && strcmp(CRs{iCR - 1},'STO') == 1) || (strcmp(CRs{iCR - 1},'MEM') == 1 && strcmp(CRs{iCR - 2},'STO') == 1))
          CRs{iCR} = 'CPU';
        end
        str = sprintf('Switching CR: %s', CRs{iCR});
        %disp(str);
    end
        
    % Switch on the i-th contention ratio
    switch (CRs{iCR})
      case 'CPU'
        nCPU_SlotsToScan = size(availableCPUslots,2);  % Number of slots to scan
        % TODO Check all available slots to scan (including MEM and STO) - Dont need to do this since it's taken care of by the contention ratios
        % TODO Check required slots is less than slots available
        % TODO Change elseif slotNo section to else 
        if ((nCPU_SlotsToScan == 0) || (nCPU_SlotsToScan < minReqCPUslots))    % Break out of while loop since no (or not enough) CPU slots are available
          ITresourceUnavailable = 1;
          heldITresources = {};
          ITfailureCause = 'CPU';   % Allocation failed due to unavailibility of CPUs
        else
          for slotNo = 1:loopIncrement:nCPU_SlotsToScan
            %str = sprintf('Starting CPU node: %d, %d, %d \n', CPUlocations(availableCPUslots(slotNo)), CPUlocations(availableCPUslots(1,slotNo)),CPUunitsInSlots(1,availableCPUslots(slotNo)));
            %disp(str);
            startCPUslot = CPUunitsInSlots(1,availableCPUslots(slotNo)); % CPU start slot/node
            removeLinks = 1;    % Set to 1 to remove unacceptable links
            % Run BFS - Remove unacceptable links
            [ITresourceNodes, ITsuccessful, ITfailureCause] = BFS(dataCenterMap, startCPUslot, reqResourceUnits, updatedUnitAvailableMap, removeLinks, request);
            % Re-run to check if the failure cause was unavalibility of IT or removal of unacceptable links
            if (ITsuccessful == FAILURE)
              removeLinks = 0;  % Set to 0 to use original graph
              % Run BFS - Original graph
              [~, ITsuccessful, ITfailureCause] = BFS(dataCenterMap, startCPUslot, reqResourceUnits, updatedUnitAvailableMap, removeLinks, request);
              % Actual failure cause is IT resources
              if (ITsuccessful == FAILURE)
                ITresourceUnavailable = 1;
                heldITresources = {};
                pathLatenciesAllocated = {};
                break;    % Break out of inner scan loop since not enough IT resources are available
              else    % Actual failure cause is network resources
                NETresourceUnavailable = 1;
                NETfailureCause = 'BAN';
                % To handle the corner-case when the start node has IT resources but no NET resources
                adjaceny = completeBandwidthMap(startCPUslot,:);  % Find start node's neighbours
                neighbours = find(adjaceny > 0);    % Find neighbours with non-zero bandwidth links
                if (numel(neighbours) ~= 0)   % The start node has NET resources but BFS failed on some other links somewhere else in the graph/network
                  NETresourceUnavailableBFS = 1;
                  break;    % Break out of inner scan loop since not enough NET resources are available; any further tries would fail
                end
              end
            else      % If required IT resources have been successfully found with acceptable bandwidth links
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
            end
          end
          if (ITsuccessful == SUCCESS && NETsuccessful == SUCCESS)
            break;    % Break out of outer loop
          end
        end
        % Break out of the outer loop if required number of IT resources are unavailable
        if (ITresourceUnavailable == 1 || NETresourceUnavailableBFS == 1)
          break;    % Break out of outer loop
        end

        case 'MEM'
        nMEM_SlotsToScan = size(availableMEMslots,2);  % Number of slots to scan
        if ((nMEM_SlotsToScan == 0) || (nMEM_SlotsToScan < minReqMEMslots))    % Break out of while loop since no (or not enough) MEM slots are available
          ITresourceUnavailable = 1;
          heldITresources = {};
          ITfailureCause = 'MEM';   % Allocation failed due to unavailibility of MEMs
        else
          for slotNo = 1:loopIncrement:nMEM_SlotsToScan
            startMEMslot = MEMunitsInSlots(1,availableMEMslots(slotNo)); % MEM start slot/node
            removeLinks = 1;    % Set to 1 to remove unacceptable links
            % Run BFS - Remove unacceptable links
            [ITresourceNodes, ITsuccessful, ITfailureCause] = BFS(dataCenterMap, startMEMslot, reqResourceUnits, updatedUnitAvailableMap, removeLinks, request);
            % Re-run to check if the failure cause was unavalibility of IT or removal of unacceptable links
            if (ITsuccessful == FAILURE)
              removeLinks = 0;  % Set to 0 to use original graph
              % Run BFS - Original graph
              [~, ITsuccessful, ITfailureCause] = BFS(dataCenterMap, startMEMslot, reqResourceUnits, updatedUnitAvailableMap, removeLinks, request);
              % Actual failure cause is IT resources
              if (ITsuccessful == FAILURE)
                ITresourceUnavailable = 1;
                heldITresources = {};
                pathLatenciesAllocated = {};
                break;    % Break out of inner scan loop since not enough IT resources are available
              else    % Actual failure cause is network resources
                NETresourceUnavailable = 1;
                NETfailureCause = 'BAN';
                % To handle the corner-case when the start node has IT resources but no NET resources
                adjaceny = completeBandwidthMap(startMEMslot,:);  % Find start node's neighbours
                neighbours = find(adjaceny > 0);    % Find neighbours with non-zero bandwidth links
                if (numel(neighbours) ~= 0)   % The start node has NET resources but BFS failed on some other links somewhere else in the graph/network
                  NETresourceUnavailableBFS = 1;
                  break;    % Break out of inner scan loop since not enough NET resources are available; any further tries would fail
                end
              end
            else      % If required IT resources have been successfully found with acceptable bandwidth links
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
            end
          end
          if (ITsuccessful == SUCCESS && NETsuccessful == SUCCESS)
            break;    % Break out of outer loop
          end
        end
        % Break out of the outer loop if required number of IT resources are unavailable
        if (ITresourceUnavailable == 1 || NETresourceUnavailableBFS == 1)
          break;    % Break out of outer loop
        end

        case 'STO'
        nSTO_SlotsToScan = size(availableSTOslots,2);  % Number of slots to scan
        if ((nSTO_SlotsToScan == 0) || (nSTO_SlotsToScan < minReqSTOslots))    % Break out of while loop since no (or not enough) STO slots are available
          ITresourceUnavailable = 1;
          heldITresources = {};
          ITfailureCause = 'STO';   % Allocation failed due to unavailibility of STOs
        else
          for slotNo = 1:loopIncrement:nSTO_SlotsToScan
            startSTOslot = STOunitsInSlots(1,availableSTOslots(slotNo)); % STO start slot/node
            removeLinks = 1;    % Set to 1 to remove unacceptable links
            % Run BFS - Remove unacceptable links
            [ITresourceNodes, ITsuccessful, ITfailureCause] = BFS(dataCenterMap, startSTOslot, reqResourceUnits, updatedUnitAvailableMap, removeLinks, request);
            % Re-run to check if the failure cause was unavalibility of IT or removal of unacceptable links
            if (ITsuccessful == FAILURE)
              removeLinks = 0;  % Set to 0 to use original graph
              % Run BFS - Original graph
              [~, ITsuccessful, ITfailureCause] = BFS(dataCenterMap, startSTOslot, reqResourceUnits, updatedUnitAvailableMap, removeLinks, request);
              % Actual failure cause is IT resources
              if (ITsuccessful == FAILURE)
                ITresourceUnavailable = 1;
                heldITresources = {};
                pathLatenciesAllocated = {};
                break;    % Break out of inner scan loop since not enough IT resources are available
              else    % Actual failure cause is network resources
                NETresourceUnavailable = 1;
                NETfailureCause = 'BAN';
                % To handle the corner-case when the start node has IT resources but no NET resources
                adjaceny = completeBandwidthMap(startSTOslot,:);  % Find start node's neighbours
                neighbours = find(adjaceny > 0);    % Find neighbours with non-zero bandwidth links
                if (numel(neighbours) ~= 0)   % The start node has NET resources but BFS failed on some other links somewhere else in the graph/network
                  NETresourceUnavailableBFS = 1;
                  break;    % Break out of inner scan loop since not enough NET resources are available; any further tries would fail
                end
              end
            else      % If required IT resources have been successfully found with acceptable bandwidth links
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
            end
          end
          if (ITsuccessful == SUCCESS && NETsuccessful == SUCCESS)
            break;    % Break out of outer loop
          end
        end
        % Break out of the outer loop if required number of IT resources are unavailable
        if (ITresourceUnavailable == 1 || NETresourceUnavailableBFS == 1)
          break;    % Break out of outer loop
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
