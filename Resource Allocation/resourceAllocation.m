function [dataCenterMap, ITallocationResult, NETallocationResult, ITresourceNodesAllocated, NETresourcesAllocaed, ITfailureCause, NETfailureCause] = resourceAllocation(request, dataCenterConfig, dataCenterMap, dataCenterItems)
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

  % Cell array to store all contention ratios (i.e. for each i-th iteration)
  CRs = cell(1,size(contentionRatios,2));

  for iCR = 1:size(contentionRatios,2)
    ITresourceUnavailable = 0;    % Initialize/reset IT resource unavailable for every iteration of the loop
    NETresourceUnavailable = 0;   % Initialize/reset NET resource unavailable for every iteration of the loop
    ITsuccessful = FAILURE;       % Initialize/reset IT successful for every iteration of the loop
    NETsuccessful = FAILURE;      % Initialize/reset NET successful for every iteration of the loop
    heldITresources = [];         % Initialize/reset held IT resources for every iteration of the loop
    heldNETresources = [];        % Initialize/reset held NET resources for every iteration of the loop
    ITfailureCause = 'NONE';      % Initialize/reset IT resource allocation failure cause for every iteration of the loop
    NETfailureCause = 'NONE';     % Initialize/reset NET resource allocation failure cause for every iteration of the loop

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
        disp(str);
      
      case 3
        if ((strcmp(CRs{iCR - 2},'CPU') == 1 && strcmp(CRs{iCR - 1},'MEM') == 1) || (strcmp(CRs{iCR - 1},'CPU') == 1 && strcmp(CRs{iCR - 2},'MEM') == 1))
          CRs{iCR} = 'STO';
        elseif ((strcmp(CRs{iCR - 2},'CPU') == 1 && strcmp(CRs{iCR - 1},'STO') == 1) || (strcmp(CRs{iCR - 1},'CPU') == 1 && strcmp(CRs{iCR - 2},'STO') == 1))
          CRs{iCR} = 'MEM';
        elseif ((strcmp(CRs{iCR - 2},'MEM') == 1 && strcmp(CRs{iCR - 1},'STO') == 1) || (strcmp(CRs{iCR - 1},'MEM') == 1 && strcmp(CRs{iCR - 2},'STO') == 1))
          CRs{iCR} = 'CPU';
        end
        str = sprintf('Switching CR: %s', CRs{iCR});
        disp(str);
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
          heldITresources = [];
          ITfailureCause = 'CPU';   % Allocation failed due to unavailibility of CPUs
        else
          for slotNo = 1:nSlots:nCPU_SlotsToScan
            %str = sprintf('Starting CPU node: %d, %d, %d \n', CPUlocations(availableCPUslots(slotNo)), CPUlocations(availableCPUslots(1,slotNo)),CPUunitsInSlots(1,availableCPUslots(slotNo)));
            %disp(str);
            startCPUslot = CPUunitsInSlots(1,availableCPUslots(slotNo)); % CPU start slot/node
            [ITresourceNodes, ITsuccessful, ITfailureCause] = BFS(dataCenterMap, startCPUslot, reqResourceUnits, updatedUnitAvailableMap);
            % Check if all resources have been successfully found
            if (ITsuccessful == SUCCESS)
              % Locations of resources that are "held" for the current request
              heldITresources = ITresourceNodes;
              % TODO Add network allocation code - if network is successful, break out else start search for new 
              % IT slots from next available resource node
              [NETresourceLinks, NETsuccessful, NETfailureCause, updatedBandwidthMap, failureNodes] = networkAllocation(request, heldITresources, dataCenterMap, dataCenterConfig);
              if (NETsuccessful == SUCCESS)
                heldNETresources = NETresourceLinks;
                break;    % Can only break out of the for loop if **both** IT and network resources are satisfied else start scanning from next available slot
              else
                heldNETresources = [];
                NETresourceUnavailable = 1;
                disp(NETfailureCause);
                % Update copy of unit available map to avoid BFS finding the same nodes that were "held" in the previous iteration
                % Initialize empty matrices to hold slot/node numbers
                CPUnodes = [];
                MEMnodes = [];
                STOnodes = [];
                % Extract slot/node numbers/locations to be able to update updatedUnitAvailableMap
                for i = 1:size(heldITresources,1)
                  for j = 1:size(heldITresources,2)
                    % Extract current cell from the heldITresources cell array
                    currentCell = heldITresources{i,j};
                    if (~isempty(currentCell))
                      switch (i)
                        % CPU nodes
                        case 1
                          CPUnodes = [CPUnodes, currentCell{1}];
                        % MEM nodes
                        case 2
                          MEMnodes = [MEMnodes, currentCell{1}];
                        % STO nodes
                        case 3
                          STOnodes = [STOnodes, currentCell{1}];
                      end
                    end
                  end
                end
                % Concatenate all nodes into a single matrix (Horizontal concatenation)
                ALLnodes = horzcat(CPUnodes,MEMnodes,STOnodes); 
                %updatedUnitAvailableMap(ALLnodes) = 0;
                %updatedUnitAvailableMap(CPUnodes) = 0;
                updatedUnitAvailableMap(failureNodes) = 0;

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
              heldITresources = [];
            end
          end
          if (ITsuccessful == SUCCESS && NETsuccessful == SUCCESS)
            break;    % Break out of outer loop
          end
        end

        case 'MEM'
        nMEM_SlotsToScan = size(availableMEMslots,2);  % Number of slots to scan
        if ((nMEM_SlotsToScan == 0) || (nMEM_SlotsToScan < minReqMEMslots))    % Break out of while loop since no (or not enough) MEM slots are available
          ITresourceUnavailable = 1;
          heldITresources = [];
          ITfailureCause = 'MEM';   % Allocation failed due to unavailibility of MEMs
        else
          for slotNo = 1:nSlots:nMEM_SlotsToScan
            startMEMslot = MEMunitsInSlots(1,availableMEMslots(slotNo)); % MEM start slot/node
            [ITresourceNodes, ITsuccessful, ITfailureCause] = BFS(dataCenterMap, startMEMslot, reqResourceUnits, updatedUnitAvailableMap);
            % Check if all resources have been successfully found
            if (ITsuccessful == SUCCESS)
              % Locations of resources that are "held" for the current request
              heldITresources = ITresourceNodes;
              % TODO Add network allocation code - if network is successful, break out else start search for new 
              % IT slots from next available resource node
              [NETresourceLinks, NETsuccessful, NETfailureCause, updatedBandwidthMap, failureNodes] = networkAllocation(request, heldITresources, dataCenterMap, dataCenterConfig);
              if (NETsuccessful == SUCCESS)
                heldNETresources = NETresourceLinks;
                break;    % Can only break out of the for loop if **both** IT and network resources are satisfied else start scanning from next available slot
              else
                heldNETresources = [];
                NETresourceUnavailable = 1;
                disp(NETfailureCause);
                % Update copy of unit available map to avoid BFS finding the same nodes that were "held" in the previous iteration
                % Initialize empty matrices to hold slot/node numbers
                CPUnodes = [];
                MEMnodes = [];
                STOnodes = [];
                % Extract slot/node numbers/locations to be able to update updatedUnitAvailableMap
                for i = 1:size(heldITresources,1)
                  for j = 1:size(heldITresources,2)
                    % Extract current cell from the heldITresources cell array
                    currentCell = heldITresources{i,j};
                    if (~isempty(currentCell))
                      switch (i)
                        % CPU nodes
                        case 1
                          CPUnodes = [CPUnodes, currentCell{1}];
                        % MEM nodes
                        case 2
                          MEMnodes = [MEMnodes, currentCell{1}];
                        % STO nodes
                        case 3
                          STOnodes = [STOnodes, currentCell{1}];
                      end
                    end
                  end
                end
                % Concatenate all nodes into a single matrix (Horizontal concatenation)
                ALLnodes = horzcat(CPUnodes,MEMnodes,STOnodes); 
                %updatedUnitAvailableMap(ALLnodes) = 0;
                %updatedUnitAvailableMap(MEMnodes) = 0;
                updatedUnitAvailableMap(failureNodes) = 0;

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
              heldITresources = [];
            end
          end
          if (ITsuccessful == SUCCESS && NETsuccessful == SUCCESS)
            break;    % Break out of outer loop
          end
        end

        case 'STO'
        nSTO_SlotsToScan = size(availableSTOslots,2);  % Number of slots to scan
        if ((nSTO_SlotsToScan == 0) || (nSTO_SlotsToScan < minReqSTOslots))    % Break out of while loop since no (or not enough) STO slots are available
          ITresourceUnavailable = 1;
          heldITresources = [];
          ITfailureCause = 'STO';   % Allocation failed due to unavailibility of STOs
        else
          for slotNo = 1:nSlots:nSTO_SlotsToScan
            startSTOslot = STOunitsInSlots(1,availableSTOslots(slotNo)); % STO start slot/node
            [ITresourceNodes, ITsuccessful, ITfailureCause] = BFS(dataCenterMap, startSTOslot, reqResourceUnits, updatedUnitAvailableMap);
            % Check if all resources have been successfully found
            if (ITsuccessful == SUCCESS)
              % Locations of resources that are "held" for the current request
              heldITresources = ITresourceNodes;
              % TODO Add network allocation code - if network is successful, break out else start search for new 
              % IT slots from next available resource node
              [NETresourceLinks, NETsuccessful, NETfailureCause, updatedBandwidthMap, failureNodes] = networkAllocation(request, heldITresources, dataCenterMap, dataCenterConfig);
              if (NETsuccessful == SUCCESS)
                heldNETresources = NETresourceLinks;
                break;    % Can only break out of the for loop if **both** IT and network resources are satisfied else start scanning from next available slot
              else
                heldNETresources = [];
                NETresourceUnavailable = 1;
                disp(NETfailureCause);
                % Update copy of unit available map to avoid BFS finding the same nodes that were "held" in the previous iteration
                % Initialize empty matrices to hold slot/node numbers
                CPUnodes = [];
                MEMnodes = [];
                STOnodes = [];
                % Extract slot/node numbers/locations to be able to find bandwidth available and latency between them
                for i = 1:size(heldITresources,1)
                  for j = 1:size(heldITresources,2)
                    % Extract slot/node numbers/locations to be able to update updatedUnitAvailableMap
                    currentCell = heldITresources{i,j};
                    if (~isempty(currentCell))
                      switch (i)
                        % CPU nodes
                        case 1
                          CPUnodes = [CPUnodes, currentCell{1}];
                        % MEM nodes
                        case 2
                          MEMnodes = [MEMnodes, currentCell{1}];
                        % STO nodes
                        case 3
                          STOnodes = [STOnodes, currentCell{1}];
                      end
                    end
                  end
                end
                % Concatenate all nodes into a single matrix (Horizontal concatenation)
                ALLnodes = horzcat(CPUnodes,MEMnodes,STOnodes); 
                %updatedUnitAvailableMap(ALLnodes) = 0;
                %updatedUnitAvailableMap(STOnodes) = 0;
                updatedUnitAvailableMap(failureNodes) = 0;

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
              heldITresources = [];
            end
          end
          if (ITsuccessful == SUCCESS && NETsuccessful == SUCCESS)
            break;    % Break out of outer loop
          end
        end
    end
  end

  % Break out of loop if both IT and netowrk resources have been successfully allocated
  if (ITsuccessful == SUCCESS && NETsuccessful == SUCCESS)
    ITresult = SUCCESS;
    NETresult = SUCCESS;
    str = sprintf('Resources allocated for current request.\n');
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
      str = sprintf('Resources (IT) unavailable for current request!\n');
      disp(str);
    elseif (NETresourceUnavailable == 1)
      str = sprintf('Resources (NET) unavailable for current request!\n');
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