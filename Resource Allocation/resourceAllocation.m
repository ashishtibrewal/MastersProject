function [dataCenterMap, ITallocationResult] = resourceAllocation(request, dataCenterConfig, dataCenterMap, dataCenterItems)
  % Function to allocate the IT resources
  % NEED TO PLAN AND TRY DIFFERENT APPROACHES.
  
  % Extract data center network maps
  connectivityMap = dataCenterMap.connectivityMap;
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
  requiredCPU = request(1);
  requiredMEM = request(2);
  requiredSTO = request(3);
  requiredBAN_CM = request(4);    % MAXIMUM ACCEPTABLE BANDWIDTH (CPU-MEM)
  requiredBAN_MS = request(5);    % MAXIMUM ACCEPTABLE BANDWIDTH (MEM-STO)
  requiredLAT_CM = request(6);    % MAXIMUM ACCEPTABLE LATENCY (CPU-MEM)
  requiredLAT_MS = request(7);    % MAXIMUM ACCEPTABLE LATENCY (MEM-STO)
  requiredHDT = request(8);   % (Same) Hold time applies to both the IT and network resources

  % Flags that are set when a required resource has been alloated
  assignedCPU = 0;
  assignedMEM = 0;
  assignedSTO = 0;
  
  % Extract required maps from the data center map struct
  completeResourceMap = dataCenterMap.completeResourceMap;
  unitAvailableMap = dataCenterMap.completeUnitAvailableMap;

  %%%%%% MAIN IT RESOURCE ALLOCATION ALGORITHM %%%%%%
  
  % IMPORTANT NOTE: A unit can only be allocated to a single request.
  % Updates/changes are made to the copies of the original maps and the
  % original maps are only updated once the ALL required resources for a
  % request have been allocated.
  
  % Evaluate number of bins (i.e. units inside a slot) required for each
  % resource (Using the ceil function to round up to the closest integer)
  reqCPUunits = ceil(requiredCPU/unitSizeCPU);    % Number of CPU slots required
  reqMEMunits = ceil(requiredMEM/unitSizeMEM);    % Number of MEM slots required
  reqSTOunits = ceil(requiredSTO/unitSizeSTO);    % Number of STO slots required
  
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
  
  % Extract locations for each type of resource
  CPUlocations = dataCenterMap.locationMap.CPUs;
  MEMlocations = dataCenterMap.locationMap.MEMs;
  STOlocations = dataCenterMap.locationMap.STOs;
  
  % Locations of resources that are "held" for the current request
  heldCPUs = zeros(1,reqCPUunits);
  heldMEMs = zeros(1,reqMEMunits);
  heldSTOs = zeros(1,reqSTOunits);
  
  % Start scanning from the 1st slot (i.e 1st slot in the 1st rack)
  % FOR A SPECIFIC RESOURCE, ONLY SCAN ITS RESPECTIVE LOCATIONS/SLOTS
  
  %%%%%% Find availabe CPUs %%%%%%
  nCPU_SlotsToScan = size(CPUlocations,2);  % Number of slots to scan
  for slotNo = 1:1
    resourceNode = BFS(dataCenterMap, CPUlocations(slotNo));
  end
  
  
  
  
  %%%%%% Find availabe CPUs %%%%%%
  CPU_ScanStartLoc = CPUlocations(1);       % Extract first CPU location to start scan
  nCPU_SlotsToScan = size(CPUlocations,2);  % Number of slots to scan
  for slotNo = CPU_ScanStartLoc:nCPU_SlotsToScan    % Iterate over all slots that need to be scanned
    scanLoc = CPUlocations(slotNo);     % Current scan slot location
    if (unitOccupiedMap(scanLoc) >= 1)  % If at least a single unit exists in this slot
      availableCPUlocations(slotNo) = scanLoc;
    end
  end
  
  %%%%%% Find availabe MEMs %%%%%%
  MEM_ScanStartLoc = MEMlocations(1);       % Extract first MEM location to start scan
  nMEM_SlotsToScan = size(MEMlocations,2);  % Number of slots to scan
  for slotNo = MEM_ScanStartLoc:nMEM_SlotsToScan    % Iterate over all slots that need to be scanned
    scanLoc = MEMlocations(slotNo);     % Current scan slot location
    if (unitOccupiedMap(scanLoc) >= 1)  % If at least a single unit exists in this slot
      availableMEMlocations(slotNo) = scanLoc;
    end
  end
  
  %%%%%% Find availabe STOs %%%%%%
  STO_ScanStartLoc = STOlocations(1);       % Extract first STO location to start scan
  nSTO_SlotsToScan = size(STOlocations,2);  % Number of slots to scan
  for slotNo = STO_ScanStartLoc:nSTO_SlotsToScan    % Iterate over all slots that need to be scanned
    scanLoc = STOlocations(slotNo);     % Current scan slot location
    if (unitOccupiedMap(scanLoc) >= 1)  % If at least a single unit exists in this slot
      availableSTOlocations(slotNo) = scanLoc;
    end
  end
  
  ITallocationResult = 0;
  
  % NEED TO MAKE SURE THAT ALL RESOURCES THAT ARE BEING ALLOCATED FOR A
  % REQUEST ARE CONNECTED (Currently this is indirectly true since all
  % racks are connected to each, all blades in a rack are connected to each
  % other and all slots in a blade are connected to each other.
  % 1. NEED TO CHECK FOR CONNECTIVITY
  % 2. NEED TO CHECK FOR HOLD TIME
  % ALLOCATE ONLY IF BOTH CONDITIONS ARE PASSED
  % TODO Need to be able to split required resources over multiple
  % racks/blades/slots

  % Scan through all racks
%   for rackNo = 1:nRacks
%     % Scan through all blades
%     for bladeNo = 1:nBlades
%       % Scan through all slots
%       for slotNo = 1:nSlots
% 
%         % If the current rack is a CPU rack
%         if (racksCPU(racksCPU == rackNo))
%           % If the required CPU units haven't been allocated
%           if (assignedCPU == 0)
%             % If a CPU unit is free on a slot/blade/rack
%             if (requiredCPU <= occupiedMap(slotNo,bladeNo,rackNo))
%               % Required amount of CPU is assigned (i.e. can be allocated) 
%               assignedCPU = 1;
%               
%               % Store the CPU slot, blade and rack number that are ASSIGNED
%               % TO THIS REQUEST BUT NOT YET ALLOCATED.
%               slotNoCPU = slotNo;
%               bladeNoCPU = bladeNo;
%               rackNoCPU = rackNo;
%               
%               %str = sprintf('CPU assigned for this request !!!');
%               %disp(str);
%             end
%           end
%         end
% 
%         % If the current rack is a MEM rack
%         if (racksMEM(racksMEM == rackNo))
%           % If the required memory units haven't been allocated
%           if (assignedMEM == 0)
%             % If a MEM unit is free on a slot/blade/rack
%             if (requiredMEM <= occupiedMap(slotNo,bladeNo,rackNo))
%               % Required amount of MEM is assigned (i.e. can be allocated)
%               assignedMEM = 1;
%               
%               % Store the MEM slot, blade and rack number that are ASSIGNED
%               % TO THIS REQUEST BUT NOT YET ALLOCATED.
%               slotNoMEM = slotNo;
%               bladeNoMEM = bladeNo;
%               rackNoMEM = rackNo;
%               
%               %str = sprintf('MEM assigned for this request !!!');
%               %disp(str);
%             end
%           end
%         end
% 
%         % If the current rack is a STO rack
%         if (racksSTO(racksSTO == rackNo))
%           % If the required storage units haven't been allocated
%           if (assignedSTO == 0)
%             % If a STO unit is free on a slot/blade/rack
%             if (requiredSTO <= occupiedMap(slotNo,bladeNo,rackNo))
%               % Required amount of STO is assigned (i.e. can be allocated)
%               assignedSTO = 1;
%               
%               % Store the MEM slot, blade and rack number that are ASSIGNED
%               % TO THIS REQUEST BUT NOT YET ALLOCATED.
%               slotNoSTO = slotNo;
%               bladeNoSTO = bladeNo;
%               rackNoSTO = rackNo;
%               
%               %str = sprintf('STO assigned for this request !!!');
%               %disp(str);
%             end
%           end
%         end
%         
%         % Check to break out of the inner most loop
%         if (assignedCPU == 1 && assignedMEM == 1 && assignedSTO == 1)          
%           % Update occupiedMap to reflect reduced available/free CPU units
%           occupiedMap(slotNoCPU,bladeNoCPU,rackNoCPU) = occupiedMap(slotNoCPU,bladeNoCPU,rackNoCPU) - requiredCPU;
%           
%           % Update occupiedMap to reflect reduced available/free MEM units
%           occupiedMap(slotNoMEM,bladeNoMEM,rackNoMEM) = occupiedMap(slotNoMEM,bladeNoMEM,rackNoMEM) - requiredMEM;
%           
%           % Update occupiedMap to reflect reduced available/free STO units
%           occupiedMap(slotNoSTO,bladeNoSTO,rackNoSTO) = occupiedMap(slotNoSTO,bladeNoSTO,rackNoSTO) - requiredSTO;
%           
%           ITallocationResult = 1;
%           %str = sprintf('Complete resource allocation for this request successful !!!');
%           %disp(str);
%           break;        % Break out of the loop since the request has been 
%         else
%           ITallocationResult = 0;
%         end
%       end
%       
%       % Check to break out of the middle loop
%       if (assignedCPU == 1 && assignedMEM == 1 && assignedSTO == 1)
%         ITallocationResult = 1;
%         %str = sprintf('Complete resource allocation for request %i !!!', i);
%         %disp(str);
%         break;        % Break out of the loop since the request has been 
%       else
%         ITallocationResult = 0;
%       end
%     end
%     
%     % Check to break out of the outer most loop
%     if (assignedCPU == 1 && assignedMEM == 1 && assignedSTO == 1)
%       ITallocationResult = 1;
%       %str = sprintf('Complete resource allocation for request %i !!!', i);
%       %disp(str);
%       break;        % Break out of the loop since the request has been 
%     else
%       ITallocationResult = 0;
%     end
%   end
%   
%   % Update the occupied map in the data center map struct to reflect the
%   % current status of the occupied resource after having allocated the
%   % current resource
%   dataCenterMap.occupiedMap = occupiedMap;

%%%%%% MAIN NETWORK RESOURCE ALLOCATION ALGORITHM %%%%%%
  
end