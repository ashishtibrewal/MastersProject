function [dataCenterMap, ITallocationResult] = resourceAllocation(request, dataCenterConfig, dataCenterMap);
  % Function to allocate the IT resources
  % NEED TO PLAN AND TRY DIFFERENT APPROACHES.
  
  % Extract data center network maps
  networkMap = dataCenterMap.networkMap;
  occupiedMap = dataCenterMap.occupiedMap;
  distanceMap = dataCenterMap.distanceMap;
  latencyMap = dataCenterMap.latencyMap;
  bandwidthMap = dataCenterMap.bandwidthMap;
  holdTimeMap = dataCenterMap.holdTimeMap;

  % Extract data center configuration parameters
  nRacks = dataCenterConfig.nRacks;
  nBlades = dataCenterConfig.nBlades;
  nSlots = dataCenterConfig.nSlots;
  nUnits = dataCenterConfig.nUnits;

  unitSizeCPU = dataCenterConfig.unitSizeCPU;
  unitSizeMEM = dataCenterConfig.unitSizeMEM;
  unitSizeSTO = dataCenterConfig.unitSizeSTO;

  racksCPU = dataCenterConfig.racksCPU;
  racksMEM = dataCenterConfig.racksMEM;
  racksSTO = dataCenterConfig.racksSTO;

  % Obtain the required resource values from the request
  requiredCPU = request(1);
  requiredMEM = request(2);
  requiredSTO = request(3);
  requiredBAN = request(4);
  requiredLAT = request(5);
  requiredHDT = request(6);   % (Same) Hold time applies to both the IT and network resources

  % Flags that are set when a required resource has been alloated
  allocatedCPU = 0;
  allocatedMEM = 0;
  allocatedSTO = 0;

  % NEED TO MAKE SURE THAT ALL RESOURCES THAT ARE BEING ALLOCATED FOR A
  % REQUEST ARE CONNECTED (Currently this is indirectly true since all
  % racks are connected to each, all blades in a rack are connected to each
  % other and all slots in a blade are connected to each other.
  % 1. NEED TO CHECK FOR CONNECTIVITY
  % 2. NEED TO CHECK FOR HOLD TIME
  % ALLOCATE ONLY IF BOTH CONDITIONS ARE PASSED

  % Scan through all racks
  for rackNo = 1:nRacks
    % Scan through all blades
    for bladeNo = 1:nBlades
      % Scan through all slots
      for slotNo = 1:nSlots

        % If the current rack is a CPU rack
        if (racksCPU(racksCPU == rackNo))
          % If the required CPU units haven't been allocated
          if (allocatedCPU == 0)
            % If a CPU unit is free on a slot/blade/rack
            if (requiredCPU <= occupiedMap(slotNo,bladeNo,rackNo))
              % Update occupiedMap to reflect reduced available/free CPU units
              occupiedMap(slotNo,bladeNo,rackNo) = occupiedMap(slotNo,bladeNo,rackNo) - requiredCPU;
              allocatedCPU = 1;
              str = sprintf('CPU allocated for this request !!!');
              %disp(str);
            end
          end
        end

        % If the current rack is a MEM rack
        if (racksMEM(racksMEM == rackNo))
          % If the required memory units haven't been allocated
          if (allocatedMEM == 0)
            % If a MEM unit is free on a slot/blade/rack
            if (requiredMEM <= occupiedMap(slotNo,bladeNo,rackNo))
              % Update occupiedMap to reflect reduced available/free MEM units
              occupiedMap(slotNo,bladeNo,rackNo) = occupiedMap(slotNo,bladeNo,rackNo) - requiredMEM;
              allocatedMEM = 1;
              str = sprintf('MEM allocated for this request !!!');
              %disp(str);
            end
          end
        end

        % If the current rack is a STO rack
        if (racksSTO(racksSTO == rackNo))
          % If the required storage units haven't been allocated
          if (allocatedSTO == 0)
            % If a STO unit is free on a slot/blade/rack
            if (requiredSTO <= occupiedMap(slotNo,bladeNo,rackNo))
              % Update occupiedMap to reflect reduced available/free STO units
              occupiedMap(slotNo,bladeNo,rackNo) = occupiedMap(slotNo,bladeNo,rackNo) - requiredSTO;
              allocatedSTO = 1;
              str = sprintf('STO allocated for this request !!!');
              %disp(str);
            end
          end
        end
        
        % Check to break out of the inner most loop
        if (allocatedCPU == 1 && allocatedMEM == 1 && allocatedSTO == 1)
          ITallocationResult = 1;
          str = sprintf('Complete resource allocation for this request successful !!!');
          %disp(str);
          break;        % Break out of the loop since the request has been 
        else
          ITallocationResult = 0;
        end
      end
      
      % Check to break out of the middle loop
      if (allocatedCPU == 1 && allocatedMEM == 1 && allocatedSTO == 1)
        ITallocationResult = 1;
        %str = sprintf('Complete resource allocation for request %i !!!', i);
        %disp(str);
        break;        % Break out of the loop since the request has been 
      else
        ITallocationResult = 0;
      end
    end
    
    % Check to break out of the outer most loop
    if (allocatedCPU == 1 && allocatedMEM == 1 && allocatedSTO == 1)
      ITallocationResult = 1;
      %str = sprintf('Complete resource allocation for request %i !!!', i);
      %disp(str);
      break;        % Break out of the loop since the request has been 
    else
      ITallocationResult = 0;
    end
  end
  
  % Update the occupied map in the data center map struct to reflect the
  % current status of the occupied resource after having allocated the
  % current resource
  dataCenterMap.occupiedMap = occupiedMap;
  
end