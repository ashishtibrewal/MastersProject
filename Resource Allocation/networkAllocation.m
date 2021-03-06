function [NETresourceLinks, NETsuccessful, NETfailureCause, updatedBandwidtMap, ...
          failureNodes, pathLatenciesAllocated, pathsUnitMax, pathsBandwidth] ...
          = networkAllocation(request, heldITresources, dataCenterMap, dataCenterConfig)
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
  completeBandwidthMapOriginal = dataCenterMap.bandwidthMap.completeBandwidthOriginal;
  sparseBandwitdhMap = sparse(completeBandwidthMap);      % Sparse matrix containing links with its corresponding/respective bandwidth
  
  % Extract required items from the data center config struct
  minChannelLatency = dataCenterConfig.bounds.minChannelLatency;
  TOR_delay = dataCenterConfig.switchDelay.TOR;
  TOB_delay = dataCenterConfig.switchDelay.TOB;
  defaultDelay = dataCenterConfig.defaultDelay;
  
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
  
  % Update complete distance map and the complete bandwidth map to contain links that satisfy the request's bandwidth requirement
  completeDistanceUpdated = completeDistance;                    % Store the original distance map that contains all the links
  completeBandwidthMapUpdated = completeBandwidthMap;            % Store the original bandwidth map that contains all the available bandwidth
  linksToRemove = find(completeBandwidthMap < requiredBAN_MS);   % Based on MEM-STO bandwith requirement. TODO could try with MEM-STO and see how the performance changes
  completeDistanceUpdated(linksToRemove) = Inf;                  % Disconnect/remove links that do not have enough bandwidth available to prevent the k-shortest paths algorithm from using them
  completeDistanceUpdated(logical(eye(size(completeDistanceUpdated)))) = 0;   % Zero leading diagonal since it's set to infinity when removing 'useless' links
  completeBandwidthMapUpdated(linksToRemove) = 0;                % Zero the bandwidth on links that do not satisfy the minimum constraints/requirements
  totalDistance = 0;                                             % Initialise total distance variable
 
  % Evaluate the total distance (i.e. sum of all distances in the graph) - Sum all elements in the upper-traingle - Looping around to avoid adding infinity to the sum being calculated
  for i = 1:size(completeDistanceUpdated,2)
    for j = (i + 1):size(completeDistanceUpdated,2)
      % Check if a link exists (i.e. has a finite distance)
      if (completeDistanceUpdated(i,j) ~= Inf)
        totalDistance = totalDistance + completeDistanceUpdated(i,j);
      end
    end
  end
  
  % Evaluate the total bandwidth (i.e. sum of all bandwidths in the graph) - Sum all elements in the upper-traingle - Don't need loops since the values are all finite
  totalBandwidth = sum(sum(triu(completeBandwidthMapUpdated)));
  
  % Set weightage factor (w = 0.5 is equal weightage to both bandwidth and latency/distance)
  f = 0.5;    % A higher value of f favours bandwidth whereas a lower value favours latency
  
  % Function type (1 - 4)
  fType = 3;    % Used to switch between different weightage function implementations
  
  % Find the maximum bandwidth
  maxBandwidth = max(max(completeBandwidthMapUpdated));
  
  % Find the maximum/longest distance (Ignoring infinity)
  distanceIndices = find(completeDistanceUpdated < Inf);   % Find (linear) indices of elements that have a finite distance value
  distancesWithoutInfinity = completeDistanceUpdated(distanceIndices);  % Store all finite distance values into a column vector
  maxDistance = max(distancesWithoutInfinity);      % Find the maximum distance
  
  % Weigh all edges/links on the graph based on both it's latency (distance) and bandwidth (capacity)
  newWeightedGraph = completeDistanceUpdated;     % Initialise with updated distance matrix
  for i = 1:size(completeDistanceUpdated,2)
    for j = 1:size(completeDistanceUpdated,2)
      % Check if a link exists and that there is bandwidth available on it
      if ((completeDistanceUpdated(i,j) ~= Inf) && (completeBandwidthMapUpdated(i,j) > 0))
        switch (fType)
          case 1
            % W_new = f * W_b + (1 - f) * W_l, where W_b = (1 - W_b_ij/W_b_total) and W_l = W_l_ij/W_l_total
            newWeightedGraph(i,j) = (f * (1 - (completeBandwidthMapUpdated(i,j)/totalBandwidth))) + ((1 - f) * (completeDistanceUpdated(i,j)/totalDistance));
          case 2
            % W_new = f * W_b + (1 - f) * W_l, where W_b = (1 - W_b_ij/W_b_max) and W_l = W_l_ij/W_l_max
            newWeightedGraph(i,j) = (f * (1 - (completeBandwidthMapUpdated(i,j)/maxBandwidth))) + ((1 - f) * (completeDistanceUpdated(i,j)/maxDistance));
          case 3
            % W_new = f * W_b + (1 - f) * W_l, where W_b = (1 - W_b_ij/W_b_O_ij) and W_l = W_l_ij/W_l_max
            newWeightedGraph(i,j) = (f * (1 - (completeBandwidthMapUpdated(i,j)/completeBandwidthMapOriginal(i,j)))) + ((1 - f) * (completeDistanceUpdated(i,j)/maxDistance));
          case 4
            % W_new = W_l/W_b  -> Want to minimize f(x,y) = dist(x,y)/bandwidth(x,y)
            newWeightedGraph(i,j) = completeDistanceUpdated(i,j)/completeBandwidthMapUpdated(i,j);
        end
      end
    end
  end

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
  weightedEdgeSparseGraph = sparse(newWeightedGraph);       % Use the updated complete distance map to create a weighted sparse matrix
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
      % Use the k-shortest paths algorithm (Distances generated are irrelevant since the weights on the sparse graph are modified and do not represent real distance values)
      [~,ksPath_Paths{i,j}] = graphkshortestpaths(weightedEdgeSparseGraph, sourceNode, destNode, kPaths);
      % Check that at least k shortest paths have been found for the current set of source and destination nodes
      if (size(ksPath_Paths{i,j},2) ~= kPaths)
          copyPath = ksPath_Paths{i,j};
        % Copy pahts until the k paths exist
        while (size(ksPath_Paths{i,j},2) ~= 3)
          ksPath_Paths{i,j} = [ksPath_Paths{i,j},copyPath];
        end
      end
      % Evaluate the distance of all paths between node i and j
      kpaths_ij = ksPath_Paths{i,j};
      for k = 1:kPaths
        path_ij = kpaths_ij{k};   % Extract k-th path between i and j
        % Use the path to evaluate its total distance
        for pathNode = 1:(size(path_ij,2) - 1)
          ksPath_Dist(i,j,k) = ksPath_Dist(i,j,k) + completeDistance(path_ij(pathNode), path_ij(pathNode + 1));
        end
      end
      % Store distance found for a specific set of source and destination nodes to the latency matrix
      ksPath_Latency(i,j,:) = ksPath_Dist(i,j,:) * minChannelLatency;
      % Find if the path found contains any switches for every k-th path
      for k = 1:kPaths
        % Check if the k-th path exists (To avoid index out of bounds errors)
        if (numel(ksPath_Paths{i,j}{k}) ~= 0)
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
          % Add the default delay (i.e. Tx and Rx delays) to every k-th path
          ksPath_Latency(i,j,k) = ksPath_Latency(i,j,k) + defaultDelay;
        else
          % If a path doesn't exist, set its corresponding latency to infinity
          ksPath_Latency(i,j,k) = Inf;
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
  
  % Check the latency from each (required) node to every other (required) node for every kth path
  for i = 1:nNodes
    for j = (i + 1):nNodes
      for k = 1:kPaths
        % Check latency CPU nodes to all other nodes
        if ((i >= CPUnodesStart) && (i <= CPUnodesEnd))
          % CPU, MEM nodes
          if (((j >= CPUnodesStart) && (j <= CPUnodesEnd)) || ((j >= MEMnodesStart) && (j <= MEMnodesEnd)))
            if (ksPath_Latency(i,j,k) <= requiredLAT_CM)
              kthPathLatency(i,j,k) = 1;
              %kthPathLatency(j,i,k) = 1;   % Since the matrix is always symmetric
            end
          % STO nodes
          elseif ((j >= STOnodesStart) && (j <= STOnodesEnd))
            if (ksPath_Latency(i,j,k) <= requiredLAT_MS)
              kthPathLatency(i,j,k) = 1;
              %kthPathLatency(j,i,k) = 1;   % Since the matrix is always symmetric
            end
          end

        % Check latency between MEM nodes to all other nodes
        elseif ((i >= MEMnodesStart) && (i <= MEMnodesEnd))
          % CPU nodes
          if (((j >= CPUnodesStart) && (j <= CPUnodesEnd)))
            if (ksPath_Latency(i,j,k) <= requiredLAT_CM)
              kthPathLatency(i,j,k) = 1;
              %kthPathLatency(j,i,k) = 1;   % Since the matrix is always symmetric
            end
          % MEM, STO nodes
          elseif (((j >= MEMnodesStart) && (j <= MEMnodesEnd)) || ((j >= STOnodesStart) && (j <= STOnodesEnd)))
            if (ksPath_Latency(i,j,k) <= requiredLAT_MS)
              kthPathLatency(i,j,k) = 1;
              %kthPathLatency(j,i,k) = 1;   % Since the matrix is always symmetric
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
              %kthPathLatency(j,i,k) = 1;   % Since the matrix is always symmetric
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
        failureNodesInternal = [failureNodesInternal, ALLnodes(i), ALLnodes(j)];
      end
    end
  end
  
  % Initialize paths cell array to store paths taken from every node to every other node
  paths = cell(nNodes);
  pathsUnitMax = cell(nNodes);
  pathsBandwidth = cell(nNodes);
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

            % Update cell tracking maximum units for a path
            pathsUnitMax{i,j} = unitsMax;

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
                    pathsBandwidth{i,j} = requiredBAN_CM; 
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
                    pathsBandwidth{i,j} = requiredBAN_MS; 
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
                    pathsBandwidth{i,j} = requiredBAN_CM;
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
                    pathsBandwidth{i,j} = requiredBAN_MS;
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
                    pathsBandwidth{i,j} = requiredBAN_MS;
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
          failureNodesInternal = [failureNodesInternal, ALLnodes(i), ALLnodes(j)];
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
