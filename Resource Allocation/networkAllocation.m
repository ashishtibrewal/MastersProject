function [NETresourceLinks, NETsuccessful, NETfailureCause, updatedBandwidtMap, failureNodes, pathLatenciesAllocated] = networkAllocation(request, heldITresources, dataCenterMap, dataCenterConfig)
  % Network allocation algorithm
  
  % Import global macros
  global SUCCESS;
  global FAILURE;
  
  %%%%%% MAIN NETWORK RESOURCE ALLOCATION ALGORITHM %%%%%%
  % Would need to run k-shortest path on held nodes
  % First check for latency between held nodes, if successful, then find
  % bandwidth on these links
  
  % Extract required maps from the data center map struct
  completeResourceMap = dataCenterMap.completeResourceMap;
  completeDistance = dataCenterMap.distanceMap.completeDistance;
  switchMap = dataCenterMap.switchMap;
  completeBandwidthMap = dataCenterMap.bandwidthMap.completeBandwidth;
  sparseBandwitdhMap = sparse(completeBandwidthMap);      % Sparse matrix containing links with its corresponding/respective bandwidth
  
  % Extract required items from the data center config struct
  minChannelLatency = dataCenterConfig.bounds.minChannelLatency;
  TOR_delay = dataCenterConfig.switchDelay.TOR;
  TOB_delay = dataCenterConfig.switchDelay.TOB;
  
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
  % Column 12 -> IT resource nodes allocated
  % Column 13 -> NET resource (links) allocated
  % Column 14 -> IT failure cause
  % Column 15 -> NET failure cause
  % Column 16 -> Allocated path latencies
  requiredBAN_CM = request{4};    % MINIMUM ACCEPTABLE BANDWIDTH (CPU-MEM)
  requiredBAN_MS = request{5};    % MINIMUM ACCEPTABLE BANDWIDTH (MEM-STO)
  requiredLAT_CM = request{6};    % MAXIMUM ACCEPTABLE LATENCY (CPU-MEM)
  requiredLAT_MS = request{7};    % MAXIMUM ACCEPTABLE LATENCY (MEM-STO)
  
  % Initialize result variables
  LATsuccess = SUCCESS;
  BANsuccess = SUCCESS;
  updatedBandwidtMapI = completeBandwidthMap;    % Initialize updated bandwidth map with complete bandwitdh map
  failureNodesInternal = [];    % Nodes that caused latency/bandwidth checks to fail (Initialize as empty matrix)
  pathLatenciesAllocated = {};
  
  % Initialize empty matrices to hold slot/node numbers
  CPUnodes = [];
  MEMnodes = [];
  STOnodes = [];
  ALLnodes = [];
  
  % Extract slot/node numbers/locations to be able to find bandwidth available and latency between them
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
  %disp(ALLnodes);
  
  %%%%%% K-shortest path %%%%%%
  weightedEdgeSparseGraph = sparse(completeDistance);       % Use the complete distance map to create a weighted sparse matrix
 	nNodes = size(ALLnodes, 2);                               % Obtain size of the nodes matrix (i.e. the total number of nodes)
  kPaths = 3;     % Specify number of shortest paths to find
  
  ksPath_Dist = zeros(nNodes,nNodes,kPaths);   % Initialize k-shortest path distance matrix with it's 3rd dimension being of size kPaths
  ksPath_Paths = cell(nNodes,nNodes);    % Initialize k-shortest path paths cell
  
  ksPath_Latency = zeros(nNodes,nNodes,kPaths);   % Initialize k-shortest path latency matrix with it's 3rd dimension being of size kPaths 
  
  % Run k-shortest path for every node to every other node in the graph
  for i = 1:nNodes
    for j = (i + 1):nNodes
      sourceNode = ALLnodes(i);
      destNode = ALLnodes(j);
      % Use the k-shortest paths algorithm
      [ksPath_Dist(i,j,:),ksPath_Paths{i,j}] = graphkshortestpaths(weightedEdgeSparseGraph, sourceNode, destNode, kPaths);
      % Store distance found for a specific set of source and destination nodes to the latency matrix
      ksPath_Latency(i,j,:) = ksPath_Dist(i,j,:) * minChannelLatency;
      % Find if the path found contains any switches for every k-th path
      for k = 1:kPaths
        % Extract k-th path for current source and destination nodes exluding the destination node (hence, the -1)
        kth_Path = ksPath_Paths{i,j}{k}(1:numel(ksPath_Paths{i,j}{k}) - 1);
        % Find TOR swithces
        TOR_Switches = ismember(switchMap.TOR_indexes, kth_Path);
        % Find TOB switches
        TOB_Swithces = ismember(switchMap.TOB_indexes, kth_Path);
        % If any switches exist in the shortest path
        if (nnz(TOR_Switches) || nnz(TOB_Swithces))
          % Find the total number of TOR swithces
          nTOR_Switches = sum(histcounts(kth_Path,switchMap.TOR_indexes));
          % Find the total number of TOB swithces
          nTOB_Switches = sum(histcounts(kth_Path,switchMap.TOB_indexes));
          % Find total switch delay on the path
          totalSwitchDelay = (nTOR_Switches * TOR_delay) + (nTOB_Switches * TOB_delay);
          % Update latency map
          ksPath_Latency(i,j,k) = ksPath_Latency(i,j,k) + totalSwitchDelay;
        end
        %disp(ksPath_Paths{i,j}{k}(1:numel(ksPath_Paths{i,j}{k})));
        %disp(ksPath_Latency(i,j,k));
      end
    end
  end
  
  % Evaluate start and end indexes for each type to resource
  CPUnodesStart = 1;
  CPUnodesEnd = size(CPUnodes,2);
  MEMnodesStart = CPUnodesEnd + 1;
  MEMnodesEnd = CPUnodesEnd + size(MEMnodes,2);
  STOnodesStart = MEMnodesEnd + 1;
  STOnodesEnd = MEMnodesEnd + size(STOnodes,2);
  
  % Initialize k-th path to 0 for every node to every other node
  kthPathTaken = zeros(nNodes,nNodes);
  
  % Initialize boolean matrix that keeps track of every path that satisfies the latency constraint
  kthPathLatency = zeros(nNodes,nNodes,kPaths);
  
  % Check the latency from each (required) node to every other (required)node for every kth path
  for i = 1:nNodes
    for j = (i + 1):nNodes
      for k = 1:kPaths
        % Check latency CPU nodes to all other nodes
        if ((i >= CPUnodesStart) && (i <= CPUnodesEnd))
          % CPU, MEM nodes
          if (((j >= CPUnodesStart) && (j <= CPUnodesEnd)) || ((j >= MEMnodesStart) && (j <= MEMnodesEnd)))
            if (ksPath_Latency(i,j,k) <= requiredLAT_CM)
              kthPathLatency(i,j,k) = 1;
              %kthPathLatency(j,i,k) = 1;
            end
          % STO nodes
          elseif ((j >= STOnodesStart) && (j <= STOnodesEnd))
            if (ksPath_Latency(i,j,k) <= requiredLAT_MS)
              kthPathLatency(i,j,k) = 1;
              %kthPathLatency(j,i,k) = 1;
            end
          end

        % Check latency between MEM nodes to all other nodes
        elseif ((i >= MEMnodesStart) && (i <= MEMnodesEnd))
          % CPU nodes
          if (((j >= CPUnodesStart) && (j <= CPUnodesEnd)))
            if (ksPath_Latency(i,j,k) <= requiredLAT_CM)
              kthPathLatency(i,j,k) = 1;
              %kthPathLatency(j,i,k) = 1;
            end
          % MEM, STO nodes
          elseif (((j >= MEMnodesStart) && (j <= MEMnodesEnd)) || ((j >= STOnodesStart) && (j <= STOnodesEnd)))
            if (ksPath_Latency(i,j,k) <= requiredLAT_MS)
              kthPathLatency(i,j,k) = 1;
              %kthPathLatency(j,i,k) = 1;
            end
          end

        % Check latency between STO nodes to all other nodes
        elseif ((i >= STOnodesStart) && (i <= STOnodesEnd))
          % CPU, MEM, STO nodes
          if (((j >= CPUnodesStart) && (j <= CPUnodesEnd)) || ...
              ((j >= MEMnodesStart) && (j <= MEMnodesEnd)) || ...
              ((j >= STOnodesStart) && (j <= STOnodesEnd)))
            if (ksPath_Latency(i,j,k) <= requiredLAT_MS)
              kthPathLatency(i,j,k) = 1;
              %kthPathLatency(j,i,k) = 1;
            end
          end
        end
      end
    end
  end
  
  % Check k-th path latency matrix for failure nodes (i.e. check if there's
  % atleast a single path from every node to every other node that
  % satisfies the latency constraint)
  for i = 1:nNodes
    for j = (i + 1):nNodes
      acceptableLatencyPath = 0;      % Reset it for every destination node
      for k = 1:kPaths
        if (kthPathLatency(i,j,k) == 1)
          acceptableLatencyPath = 1;
          break;
        end
      end
      if (acceptableLatencyPath == 0)   % If no acceptable latency path exists for a set of nodes
        LATsuccess = FAILURE;
        failureNodesInternal = [failureNodesInternal, ALLnodes(j)];
      end
    end
  end
  
  % Initialize paths cell array to store paths taken from every node to every other node
  paths = cell(nNodes);
  maxPaths = nNodes * ((nNodes - 1)/2);
  pathsSuccessful = zeros(1,maxPaths);
  pathsSuccessfulIndex = 1;

  % Check the bandwidth (on each link) from each (required) node to every other (required) node
  if (LATsuccess == SUCCESS)   % Only check for bandwidth if the latency constraint has been satisfied
    for i = 1:nNodes
      for j = (i + 1):nNodes
        updatedBandwidtMapI_RevertVersion = updatedBandwidtMapI;   % Keep a copy of the updated version to revert back if the k-th path fails
        for k = 1:kPaths
          BANsuccess = SUCCESS;      % Reset for every k-th path
          if (kthPathLatency(i,j,k) == 1)     % If the k-th path satisfies the latency constraint
            % Extract the kth path for the current pair of nodes
            path = ksPath_Paths{i,j}{k};
            pathLength = size(path,2);
            %disp(path);

            % Find number of units used in source and destination nodes
            unitsSource = 0;
            unitsDest = 0;
            for p = 1:size(heldITresources,1)
              for q = 1:size(heldITresources,2)
                ITcell = heldITresources{p,q};
                if (~isempty(ITcell))
                  ITmatrix = cell2mat(ITcell);
                  % Source units
                  if (ITmatrix(1) == path(1))
                    unitsSource = ITmatrix(2);
                  % Destination units
                  elseif (ITmatrix(1) == path(pathLength))
                    unitsDest = ITmatrix(2);
                  end
                end
              end
            end

            % Find the maximum units allocated out of source and destination nodes
            unitsMax = max(unitsSource,unitsDest);

            % Check for the required bandwidth
            for node = 1:(pathLength - 1)
              %str = sprintf('%d  %d  %d', path(node), path(node + 1), updatedBandwidtMap(path(node),path(node + 1)));
              %disp(str);          
              % Check bandwidth between CPU nodes to all other nodes
              if ((i >= CPUnodesStart) && (i <= CPUnodesEnd))
                % CPU, MEM nodes
                if (((j >= CPUnodesStart) && (j <= CPUnodesEnd)) || ((j >= MEMnodesStart) && (j <= MEMnodesEnd)))
                  % Check bandwidth between the nodes and if any of them don't satisfy the constraint, break
                  if (updatedBandwidtMapI(path(node),path(node + 1)) < (requiredBAN_CM * unitsMax))
                    BANsuccess = FAILURE;
                    break;    % Break out of the path loop for current k-th path since the current link on this path failed the bandwitdh constraint
                  else
                    % Update (copied version of) bandwidth map in both upper & bottom triangles since it needs to be symmetric
                    updatedBandwidtMapI(path(node),path(node + 1)) = updatedBandwidtMapI(path(node),path(node + 1)) - (requiredBAN_CM * unitsMax);
                    updatedBandwidtMapI(path(node + 1),path(node)) = updatedBandwidtMapI(path(node + 1),path(node)) - (requiredBAN_CM * unitsMax);
                  end
                % STO nodes
                elseif ((j >= STOnodesStart) && (j <= STOnodesEnd))
                  % Check bandwidth between the nodes and if any of them don't satisfy the constraint, break
                  if (updatedBandwidtMapI(path(node),path(node + 1)) < (requiredBAN_MS * unitsMax))
                    BANsuccess = FAILURE;
                    break;    % Break out of the path loop for current k-th path since the current link on this path failed the bandwitdh constraint
                  else
                    % Update (copied version of) bandwidth map in both upper & bottom triangles since it needs to be symmetric
                    updatedBandwidtMapI(path(node),path(node + 1)) = updatedBandwidtMapI(path(node),path(node + 1)) - (requiredBAN_MS * unitsMax);
                    updatedBandwidtMapI(path(node + 1),path(node)) = updatedBandwidtMapI(path(node + 1),path(node)) - (requiredBAN_MS * unitsMax);
                  end
                end

              % Check bandwidth between MEM nodes to all other nodes
              elseif ((i >= MEMnodesStart) && (i <= MEMnodesEnd))
                % CPU nodes
                if (((j >= CPUnodesStart) && (j <= CPUnodesEnd)))
                  % Check bandwidth between the nodes and if any of them don't satisfy the constraint, break
                  if (updatedBandwidtMapI(path(node),path(node + 1)) < (requiredBAN_CM * unitsMax))
                    BANsuccess = FAILURE;
                    break;    % Break out of the path loop for current k-th path since the current link on this path failed the bandwitdh constraint
                  else
                    % Update (copied version of) bandwidth map in both upper & bottom triangles since it needs to be symmetric
                    updatedBandwidtMapI(path(node),path(node + 1)) = updatedBandwidtMapI(path(node),path(node + 1)) - (requiredBAN_CM * unitsMax);
                    updatedBandwidtMapI(path(node + 1),path(node)) = updatedBandwidtMapI(path(node + 1),path(node)) - (requiredBAN_CM * unitsMax);
                  end
                % MEM, STO nodes
                elseif (((j >= MEMnodesStart) && (j <= MEMnodesEnd)) || ((j >= STOnodesStart) && (j <= STOnodesEnd)))
                  % Check bandwidth between the nodes and if any of them don't satisfy the constraint, break
                  if (updatedBandwidtMapI(path(node),path(node + 1)) < (requiredBAN_MS * unitsMax))
                    BANsuccess = FAILURE;
                    break;    % Break out of the path loop for current k-th path since the current link on this path failed the bandwitdh constraint
                  else
                    % Update (copied version of) bandwidth map in both upper & bottom triangles since it needs to be symmetric
                    updatedBandwidtMapI(path(node),path(node + 1)) = updatedBandwidtMapI(path(node),path(node + 1)) - (requiredBAN_MS * unitsMax);
                    updatedBandwidtMapI(path(node + 1),path(node)) = updatedBandwidtMapI(path(node + 1),path(node)) - (requiredBAN_MS * unitsMax);
                  end
                end

              % Check bandwidth between STO nodes to all other nodes
              elseif ((i >= STOnodesStart) && (i <= STOnodesEnd))
                % CPU, MEM, STO nodes
                if (((j >= CPUnodesStart) && (j <= CPUnodesEnd)) || ...
                    ((j >= MEMnodesStart) && (j <= MEMnodesEnd)) || ...
                    ((j >= STOnodesStart) && (j <= STOnodesEnd)))
                  % Check bandwidth between the nodes and if any of them don't satisfy the constraint, break
                  if (updatedBandwidtMapI(path(node),path(node + 1)) < (requiredBAN_MS * unitsMax))
                    BANsuccess = FAILURE;
                    break;    % Break out of the path loop for current k-th path since the current link on this path failed the bandwitdh constraint
                  else
                    % Update (copied version of) bandwidth map in both upper & bottom triangles since it needs to be symmetric
                    updatedBandwidtMapI(path(node),path(node + 1)) = updatedBandwidtMapI(path(node),path(node + 1)) - (requiredBAN_MS * unitsMax);
                    updatedBandwidtMapI(path(node + 1),path(node)) = updatedBandwidtMapI(path(node + 1),path(node)) - (requiredBAN_MS * unitsMax);
                  end
                end
              end
            end
            if (BANsuccess == SUCCESS)
              paths{i,j} = {path};
              pathLatenciesAllocated = [pathLatenciesAllocated, ksPath_Latency(i,j,k)];
              kthPathTaken(i,j) = k;
              pathsSuccessful(pathsSuccessfulIndex) = 1;
              break;    % Break out of the k-th loop for current i-th source node and j-th destination node since a path with acceptable bandwidth has been found
            else
              updatedBandwidtMapI = updatedBandwidtMapI_RevertVersion;     % Reset updated bandwithmap to its original form since the k-th path failed the bandwidth constraint/requirement
            end
          end
        end
        if (BANsuccess == FAILURE)
          failureNodesInternal = [failureNodesInternal, ALLnodes(j)];
        end
        if (pathsSuccessfulIndex < maxPaths)    % Check to prevent index going out of range
          pathsSuccessfulIndex = pathsSuccessfulIndex + 1;    % Increment paths successful index every iteration of the j-th loop
        end
      end
    end
  end

  % Update outputs
  if (LATsuccess == SUCCESS && BANsuccess == SUCCESS && sum(pathsSuccessful,2) == maxPaths)
    NETsuccessful = SUCCESS;
    NETfailureCause = 'NONE';
    NETresourceLinks = paths;
    updatedBandwidtMap = updatedBandwidtMapI;
    failureNodes = [];
  else
    NETsuccessful = FAILURE;
    if (LATsuccess == FAILURE)
      NETfailureCause = 'LAT';
    elseif (BANsuccess == FAILURE || sum(pathsSuccessful,2) ~= maxPaths)
      NETfailureCause = 'BAN';
    end
    NETresourceLinks = {};
    pathLatenciesAllocated = {};
    updatedBandwidtMap = completeBandwidthMap;
    failureNodes = unique(failureNodesInternal,'first');
  end
end