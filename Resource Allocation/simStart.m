function [requestDB, dataCenterMap, nBlocked, CPUutilization, MEMutilization, STOutilization, NETutilization, minLatency, maxLatency, averageLatency] = simStart (dataCenterConfig, numRequests, requestDB, type)
  % Function that sets up and starts the requried simulation
  
  % Import global macros
  global SUCCESS;
  global FAILURE;
  global DROPPED;
  global HT_COMPLETE;
  SUCCESS = 1;          % Assign a value to global macro (Reassigning to avoid error from parfor)
  FAILURE = 0;          % Assign a value to global macro (Reassigning to avoid error from parfor)
  DROPPED = 2;          % Assign a value to global macro (Reassigning to avoid error from parfor)
  HT_COMPLETE = 3;      % Assign a value to global macro (Reassigning to avoid error from parfor)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Evaluate IT & Network constants
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %tTime = max([requestDB{:,17}]);    % Total time to simulate - in seconds (maximum arrival-time in the request database, could also use the last value in the database)
  tTime = max([requestDB{:,17}]) + [requestDB{numRequests,8}]; % Total time to simulate should be last arrival time + last hold time

  % Initialize counter variables
  nCPUs = 0;
  nMEMs = 0;
  nSTOs = 0;
  nCPU_MEM = 0;

  % Total number of racks specified in the configuration file
  rackNo = fieldnames(dataCenterConfig.racksConfig);

  % Iterate over all specified racks
  for i = 1:numel(rackNo)
    % Find homogeneous blades of CPUs
    nCPUs = nCPUs + size(find([dataCenterConfig.racksConfig.(rackNo{i}){:}] == dataCenterConfig.setupTypes.homogenCPU), 2);
    % Find homogeneous blades of MEMs
    nMEMs = nMEMs + size(find([dataCenterConfig.racksConfig.(rackNo{i}){:}] == dataCenterConfig.setupTypes.homogenMEM), 2);
    % Find homogeneous blades of STOs
    nSTOs = nSTOs + size(find([dataCenterConfig.racksConfig.(rackNo{i}){:}] == dataCenterConfig.setupTypes.homogenSTO), 2);
    % Find heterogeneous blades of CPUs & MEMs
    nCPU_MEM = nCPU_MEM + size(find([dataCenterConfig.racksConfig.(rackNo{i}){:}] == dataCenterConfig.setupTypes.heterogenCPU_MEM), 2);
  end

  % TODO Need to make this more flexible (Currently breaks for odd number of slots in a blade)
  % Add heterogenous values to nCPUs and nMEMs and evaluate total amount/units of resources available
  CPUs = (nCPUs * dataCenterConfig.nSlots * dataCenterConfig.nUnits * dataCenterConfig.unitSize.CPU) + (((nCPU_MEM * dataCenterConfig.nSlots) * (dataCenterConfig.heterogenSplit.heterogenCPU_MEM/100)) * dataCenterConfig.nUnits * dataCenterConfig.unitSize.CPU);
  MEMs = (nMEMs * dataCenterConfig.nSlots * dataCenterConfig.nUnits * dataCenterConfig.unitSize.MEM) + (((nCPU_MEM * dataCenterConfig.nSlots) * ((100 - dataCenterConfig.heterogenSplit.heterogenCPU_MEM)/100)) * dataCenterConfig.nUnits * dataCenterConfig.unitSize.MEM);
  STOs = (nSTOs * dataCenterConfig.nSlots * dataCenterConfig.nUnits * dataCenterConfig.unitSize.STO);

  % Find total number of units of each type of resource
  nCPU_units = CPUs/dataCenterConfig.unitSize.CPU;
  nMEM_units = MEMs/dataCenterConfig.unitSize.MEM;
  nSTO_units = STOs/dataCenterConfig.unitSize.STO;

  % Pack number of different types of resource items into a struct (Using a
  % different struct to keep the original YAML struct unmodified)
  dataCenterItems.nCPUs = CPUs;
  dataCenterItems.nMEMs = MEMs;
  dataCenterItems.nSTOs = STOs;
  dataCenterItems.nCPU_units = nCPU_units;
  dataCenterItems.nMEM_units = nMEM_units;
  dataCenterItems.nSTO_units = nSTO_units;

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Network creation
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  str = sprintf('Network creation started ...');
  disp(str);

  dataCenterMap = networkCreation(dataCenterConfig);

  str = sprintf('Network creation complete.\n');
  disp(str);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Plot data center structure as a graph
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % str = sprintf('Data center topology/layout plot started ...');
  % disp(str);
  % plotDataCenterLayout(dataCenterMap, dataCenterConfig);   % Function to plot data center layout
  % 
  % str = sprintf('Data center topology/layout plot complete.\n');
  % disp(str);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Generate plot for resource location
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %plotHeatMap(dataCenterConfig, dataCenterMap, 'allMapsSetup');

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Resource allocation main time loop
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  str = sprintf('Resource allocation started (Type %d) ...\n', type);
  disp(str);

  ITresourceAllocStatusColumn = 9;
  networkResourceAllocStatusColumn = 10;
  requestStatusColumn = 11;
  timeTakenColumn = 18;
  holdTimeColumn = 8;
  updatedHoldTimeColumn = 19;
  maxUnitsPathsColumn = 20;
  bandwidthAllocatedColumn = 21;

  % Open figure - Updated when each request's resource allocation is complete
  %figure ('Name', 'Data Center Rack Usage (1st rack of each type)', 'NumberTitle', 'off', 'Position', [40, 100, 1200, 700]);

  requests = 1:numRequests;

  % BLOCKING PROBABILITY (Request vs BP)
  nBlocked = zeros(1,size(requests,2));
  
  % Extract locations for each type of resource
  CPUlocations = dataCenterMap.locationMap.CPUs;
  MEMlocations = dataCenterMap.locationMap.MEMs;
  STOlocations = dataCenterMap.locationMap.STOs;

  % Evaluate total bandwidth
  bandwidthMapOriginal = dataCenterMap.bandwidthMap.completeBandwidthOriginal;
  totalNET = 0;
  for i = 1:size(bandwidthMapOriginal,1)
    for j = (i + 1):size(bandwidthMapOriginal,2)
      totalNET = totalNET + bandwidthMapOriginal(i,j);
    end
  end
  
  nUnits = dataCenterConfig.nUnits;
  totalCPUunits = size(dataCenterMap.locationMap.CPUs,2) * nUnits;
  totalMEMunits = size(dataCenterMap.locationMap.MEMs,2) * nUnits;
  totalSTOunits = size(dataCenterMap.locationMap.STOs,2) * nUnits;
  CPUutilization = zeros(1,size(requests,2));
  MEMutilization = zeros(1,size(requests,2));
  STOutilization = zeros(1,size(requests,2));
  NETutilization = zeros(1,size(requests,2));
  reqLatencyCM = zeros(1,size(requests,2));
  reqLatencyMS = zeros(1,size(requests,2));
  maxLatency = zeros(1,size(requests,2));
  minLatency = zeros(1,size(requests,2));
  averageLatency = zeros(1,size(requests,2));

  % Initialise previous time
  previousTime = 0;

  % Main request loop stating at top of the database
  for req = 1:numRequests
    % Extract current time
    currentTime = [requestDB{req,17}];
    
    % Evaluate time difference
    diffTime = currentTime - previousTime;
    
    % Update previous time
    previousTime = currentTime;
    
    % Display time and the number of requests generated
    %str = sprintf('Time: %ds - Requests: %d', t, currentRequests);
    %disp(str);

    % Update holding times for all requests upto req
    for htReq = 1:req
      % Extract updated hold time
      htUpdated = requestDB{htReq, updatedHoldTimeColumn};
      reqStatus = requestDB{htReq, requestStatusColumn}; 
      % Subtract time difference, i.e. amount of time that has already been simulated
      if(htUpdated > 0)
        htUpdated = htUpdated - diffTime;
        requestDB{htReq, updatedHoldTimeColumn} = htUpdated;
      end
      % Check if any of the updated hold time values go to zero or below
      if(htUpdated <= 0 && reqStatus == SUCCESS)
        % Correct negative values
        if(htUpdated < 0)
          requestDB{htReq, updatedHoldTimeColumn} = 0; 
        end
        % Update IT resource and bandwidth maps (Restore/add amount of resources allocated to htReq back to these maps)
        ITresources = requestDB{htReq,12};   % Extract allocated IT resources
        NETresources = requestDB{htReq,13};  % Extract allocated NET resources
        pathsUnitMax = requestDB{htReq,20};  % Extract maximum allocated units for every path
        pathsAllocatedBandwidth = requestDB{htReq, 21}; % Extract allocated path bandwidth
        % Update IT resource map
        for ITresType = 1:size(ITresources,1)
          for ITresSlot = 1:size(ITresources,2)
            if (~isempty(ITresources{ITresType,ITresSlot}))
              extractedRes = cell2mat(ITresources{ITresType,ITresSlot});
              dataCenterMap.completeUnitAvailableMap(extractedRes(1)) = dataCenterMap.completeUnitAvailableMap(extractedRes(1)) + extractedRes(2); 
            end
          end
        end
        % Update bandwith map
        for NETresDim1 = 1:size(NETresources,1)
          for NETresDim2 = (NETresDim1 + 1):size(NETresources,2)
            extractedRes = cell2mat(NETresources{NETresDim1,NETresDim2});
            unitsMax =  pathsUnitMax{NETresDim1,NETresDim2};
            path = extractedRes; 
            pathBandwidth = pathsAllocatedBandwidth{NETresDim1,NETresDim2};
            % Iterate over every edge on a path
            for pathNode = 1:(size(path,2) - 1)
              dataCenterMap.bandwidthMap.completeBandwidth(path(pathNode), path(pathNode + 1)) = dataCenterMap.bandwidthMap.completeBandwidth(path(pathNode), path(pathNode + 1)) + (unitsMax * pathBandwidth);   % Add allocated bandwidth back on to the total available edge bandwidth
              dataCenterMap.bandwidthMap.completeBandwidth(path(pathNode + 1), path(pathNode)) = dataCenterMap.bandwidthMap.completeBandwidth(path(pathNode), path(pathNode + 1));  % To keep bandwidth matrix symmetric
            end
          end
        end
        requestDB{htReq, requestStatusColumn} = HT_COMPLETE;  % Update request status in requestDB to prevent completed requests being checked again
      end
    end
    
    % Extract current request from the request database
    request = requestDB(req,:);

    % Display required resources for request on the prompt
    requestString = sprintf(' %d', request{1:7});
    str = sprintf('Type %d - Time: %ds - Requried resouces (Request no. %d): %s', type, currentTime, req, requestString);
    disp(str);

    %profile on;         % Turn on profiler

    % IT & NET resource allocation
    [dataCenterMap, ITallocationResult, NETallocationResult, ITresourceNodesAllocated, NETresourcesAllocated, ITfailureCause, ...
     NETfailureCause, pathLatenciesAllocated, timeTaken, pathsUnitMax, pathsBandwidth] = resourceAllocation(request, dataCenterConfig, dataCenterMap, dataCenterItems);
    
    %profile off;         % Turn off profiler
    %profile viewer;      % View profiler results

    % Update request database
    requestDB(req,12:16) = {ITresourceNodesAllocated,NETresourcesAllocated,ITfailureCause,NETfailureCause,pathLatenciesAllocated};

    % Plot usage
    %plotUsage(dataCenterMap, dataCenterConfig);

    % Plot heat map (Updated everytime a new request is being allocated/handled)
    %if (mod(req,50) == 0)   % Plot (after) every 50 requests to avoid slowing down the simulation
    %  plotHeatMap(dataCenterConfig, dataCenterMap, 'allMaps');
    %end

    % Update requests database
    % Update IT resource allocation column
    requestDB{req, ITresourceAllocStatusColumn} =  ITallocationResult;

    % Update network resource allocation column
    requestDB{req, networkResourceAllocStatusColumn} =  NETallocationResult;

    % Update max units on paths column
    requestDB{req, maxUnitsPathsColumn} = pathsUnitMax;
    
    % Update bandwidth allocated on paths column
    requestDB{req, bandwidthAllocatedColumn} = pathsBandwidth;

    % Update request status column and time taken to find and allocate resources (i.e. allocation time) and 'updated' hold time column
    if (ITallocationResult == SUCCESS && NETallocationResult == SUCCESS)
      requestDB{req, requestStatusColumn} = SUCCESS;
      requestDB{req, timeTakenColumn} = timeTaken;
      requestDB{req, updatedHoldTimeColumn} = requestDB{req, holdTimeColumn};
    else
      requestDB{req, requestStatusColumn} = DROPPED;
      requestDB{req, timeTakenColumn} = Inf;
    end
    
    % Update data structures that track both IT and NET utilisation after every request. Need to do this here since hold time can change the utilisation after every request.
    % Blocking probability
    % Check upto req (i.e. outer loop control vairable)
    blocked = find(cell2mat(requestDB(1:req,11)) == DROPPED);    % Find requests that have been blocked upto request req
    nBlocked(req) = size(blocked,1)/numRequests;                   % Count the number of requests found over the total number of requests

    completeUnitAvailableMap = dataCenterMap.completeUnitAvailableMap;
    CPUunitsAvailable = sum(completeUnitAvailableMap(CPUlocations));
    MEMunitsAvailable = sum(completeUnitAvailableMap(MEMlocations));
    STOunitsAvailable = sum(completeUnitAvailableMap(STOlocations));
    bandwidthMap= dataCenterMap.bandwidthMap.completeBandwidth;

    % IT resource utilization
    CPUunitsUtilized = totalCPUunits - CPUunitsAvailable;
    MEMunitsUtilized = totalMEMunits - MEMunitsAvailable;
    STOunitsUtilized = totalSTOunits - STOunitsAvailable;
    
    CPUutilization(req) = (CPUunitsUtilized/totalCPUunits) * 100;
    MEMutilization(req) = (MEMunitsUtilized/totalMEMunits) * 100;
    STOutilization(req) = (STOunitsUtilized/totalSTOunits) * 100;
    
    % Network utilization
    NETavailable = 0;
    for i = 1:size(bandwidthMap,1)
      for j = (i + 1):size(bandwidthMap,2)
        NETavailable = NETavailable + bandwidthMap(i,j);
      end
    end
    NETutilized = totalNET - NETavailable;
    
    NETutilization(req) = (NETutilized/totalNET) * 100;
    
    % Extract the requested latency (Can use any request database since all contain the same values)
    reqLatencyCM(req) = requestDB{req,6};
    reqLatencyMS(req) = requestDB{req,7};

    % Latency allocated
    if (requestDB{req,requestStatusColumn} == SUCCESS || requestDB{req,requestStatusColumn} == HT_COMPLETE)    % Check if the request was successfully allocated
      latencyAllocated = requestDB{req,16};
      maxLatency(req) = max([latencyAllocated{:}]);
      minLatency(req) = min([latencyAllocated{:}]);
      averageLatency(req) = sum([latencyAllocated{:}],2)/size([latencyAllocated{:}],2);
    end

    % Change all zeros in the allocated latency matrices to NaNs to avoid plotting them.
    maxLatency(maxLatency == 0) = NaN;
    minLatency(minLatency == 0) = NaN;
    averageLatency(averageLatency == 0) = NaN;

    % Update hold time maps
    % TODO Update hold time maps (Decrement by diffTime on each iteration)
    % If element is non-zero reduce by diffTime, if zero, reset/add value
    % to resource available map (both IT and NET). Also need to change
    % the resourceAllocation function to update hold time maps.
    % IMPORTANT NOTE: Subtract using the diffTime factor. Also need to make
    % sure that requests that have been genereated at the same time (i.e.
    % if there is more than a single request that needs to be served at the
    % same time) get their resources allocated before updating the holdtime
    % map - Another loop maybe required to do this that would checking the 
    % number of requests generated at a particular time and serve all 
    % before updating the holdtime map. 
  end
  
  str = sprintf('Resource allocation complete (Type %d).\n', type);
  disp(str);

end
