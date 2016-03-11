%%+++++++++++++++++++++++++++++++++++++%%
%%% Function that starts the simulation %%%
%%+++++++++++++++++++++++++++++++++++++%%

function [requestDB, dataCenterMap] = simStart (dataCenterConfig, numRequests, requestDB)
  % Function that sets up and starts the requried simulation
  
  % Import global macros
  global SUCCESS;
  global FAILURE;
  SUCCESS = 1;          % Assign a value to global macro (Reassigning to avoid error from parfor)
  FAILURE = 0;          % Assign a value to global macro (Reassigning to avoid error from parfor)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Evaluate IT & Network constants
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  nRequests = numRequests;    % Number of requests to generate
  tTime = nRequests;          % Total time to simulate for (1 second for each request)

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
  plotHeatMap(dataCenterConfig, dataCenterMap, 'allMapsSetup');

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Resource allocation main time loop
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  str = sprintf('Resource allocation started ...\n');
  disp(str);

  ITresourceAllocStatusColumn = 9;
  networkResourceAllocStatusColumn = 10;
  requestStatusColumn = 11;

  % Open figure - Updated when each request's resource allocation is complete
  %figure ('Name', 'Data Center Rack Usage (1st rack of each type)', 'NumberTitle', 'off', 'Position', [40, 100, 1200, 700]);

  %time = 1:tTime;

  %nBlocked = zeros(1,size(time,2));

  % Main time loop
  for t = 1:tTime
    % Each timestep, look at it's corresponding request in the request database
    % INTER-ARRIVAL RATE = 1 request/second
    requestDBindex = t;
    % Extract request from the database for current timestep
    request = requestDB(requestDBindex,:);

    % Display required resources for request on the prompt
    requestString = sprintf(' %d', request{1:7});
    str = sprintf('Requried resouces (Request no. %d): %s', requestDBindex, requestString);
    disp(str);

    %profile on;         % Turn on profiler

    %%%%%%%%%% IT & NET resource allocation %%%%%%%%%%
    [dataCenterMap, ITallocationResult, NETallocationResult, ITresourceNodesAllocated, NETresourcesAllocaed, ITfailureCause, NETfailureCause, pathLatenciesAllocated] = resourceAllocation(request, dataCenterConfig, dataCenterMap, dataCenterItems);

    %profile off;         % Turn off profiler
    %profile viewer;     % View profiler results

    % Update request database
    requestDB(requestDBindex,12:16) = {ITresourceNodesAllocated,NETresourcesAllocaed,ITfailureCause,NETfailureCause,pathLatenciesAllocated};

    % Plot usage
    %plotUsage(dataCenterMap, dataCenterConfig);

    % Plot heat map (Updated everytime a new request is being allocated/handled)
    if (mod(t,10) == 0)   % Plot (after) every 10 requests to avoid slowing down the simulation
      plotHeatMap(dataCenterConfig, dataCenterMap, 'allMaps');
    end

    %blocked = find(cell2mat(requestDB(1:t,9)) == 0);    % Find requests that have been blocked upto time t
    %nBlocked(t) = size(blocked,1);                      % Count the number of requests found

    %%%%%%%%%% Network resource allocation %%%%%%%%%%
    % Need to get a better understanding of network resource allocation code
    %NETallocationResult = FAILURE;

    %%%%%%%%%% Update requests database %%%%%%%%%%
    % Doing this to "simulate parallelism" with IT and network resource
    % allocation. Updating the request database after the IT resource
    % allocation makes the updated database available to the network resource
    % allocation unit which is not what we want. We want them to work
    % independently although we would still require information on which IT
    % resources have been allocated to this request (if any, i.e. Rack
    % number, blade number, slot number and unit numbers for each slot). This
    % can be stored in the request database (i.e. requestDB).

    % Update IT resource allocation column
    requestDB{requestDBindex, ITresourceAllocStatusColumn} =  ITallocationResult;

    % Update network resource allocation column
    requestDB{requestDBindex, networkResourceAllocStatusColumn} =  NETallocationResult;

    % Update request status column
    if (ITallocationResult == SUCCESS && NETallocationResult == SUCCESS)
      requestDB{requestDBindex, requestStatusColumn} = SUCCESS;
    end
  end

  % Plot blocking probability
  % figure ('Name', 'Blocking Probability', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  % semilogy(time,(nBlocked/tTime));
  % title('Blocking probability');

  str = sprintf('Resource allocation complete.\n');
  disp(str);

end