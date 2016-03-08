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
  requiredBAN_CM = request{4};    % MAXIMUM ACCEPTABLE BANDWIDTH (CPU-MEM)
  requiredBAN_MS = request{5};    % MAXIMUM ACCEPTABLE BANDWIDTH (MEM-STO)
  requiredLAT_CM = request{6};    % MAXIMUM ACCEPTABLE LATENCY (CPU-MEM)
  requiredLAT_MS = request{7};    % MAXIMUM ACCEPTABLE LATENCY (MEM-STO)
  
  % Initialize result variables
  LATsuccess = SUCCESS;
  BANsuccess = SUCCESS;
  pathTaken = 0;
  updatedBandwidtMap = completeBandwidthMap;    % Initialize updated bandwidth map with complete bandwitdh map
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
  kPaths = 1;     % Specify number of shortest paths to find
  
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
  
  % Check the latency from each (required) node to every other (required) node
  % TODO change later to add different latency checks for CPU-MEM & MEM-STO
  for k = 1:kPaths
    % Reset success variable for every/k-th path
    LATsuccess = SUCCESS;
    for i = 1:nNodes
      for j = (i + 1):nNodes
        % Check latency between the nodes and if any of them go over, break
        if (ksPath_Latency(i,j,k) > requiredLAT_CM)
          LATsuccess = FAILURE;
          failureNodesInternal = [failureNodesInternal, ALLnodes(j)];
          break;
        end
        pathLatenciesAllocated = [pathLatenciesAllocated, ksPath_Latency(i,j,k)];
      end
%       if (LATsuccess == FAILURE)
%         break;
%       end
    end
    if (LATsuccess == SUCCESS)
      pathTaken = k;
      break;
    end
  end
  
  % Check the bandwidth (on each link) from each (required) node to every other (required) node
  % TODO change later to add different bandwidth checks for CPU-MEM & MEM-STO
  if (LATsuccess == SUCCESS && pathTaken ~= 0)   % Only check for bandwidth if the latency constraint has been satisfied
    for i = 1:nNodes
      for j = (i + 1):nNodes
        % Extract the kth path for the current pair of nodes
        path = ksPath_Paths{i,j}{pathTaken};
        %disp(path);
        % Check for the required bandwidth
        for node = 1:(size(path,2) - 1)
          %str = sprintf('%d  %d  %d', path(node), path(node + 1), updatedBandwidtMap(path(node),path(node + 1)));
          %disp(str);
          if (updatedBandwidtMap(path(node),path(node + 1)) < requiredBAN_CM)
            BANsuccess = FAILURE;
            failureNodesInternal = [failureNodesInternal, ALLnodes(j)];
          else
          % Update (copied version of) bandwidth map in both upper & bottom triangles since it needs to be symmetric
          updatedBandwidtMap(path(node),path(node + 1)) = updatedBandwidtMap(path(node),path(node + 1)) - requiredBAN_CM;
          updatedBandwidtMap(path(node + 1),path(node)) = updatedBandwidtMap(path(node + 1),path(node)) - requiredBAN_CM;
          end
        end
%         if (BANsuccess == FAILURE)
%           break;
%         end
      end
%       if (BANsuccess == FAILURE)
%         break;
%       end
    end
  end

  % Update outputs
  if (LATsuccess == SUCCESS && BANsuccess == SUCCESS)
    NETsuccessful = SUCCESS;
    NETfailureCause = 'NONE';
    NETresourceLinks = ksPath_Paths(:,:);
    failureNodes = [];
  else
    NETsuccessful = FAILURE;
    if (LATsuccess == FAILURE)
      NETfailureCause = 'LAT';
    elseif (BANsuccess == FAILURE)
      NETfailureCause = 'BAN';
    end
    NETresourceLinks = [];
    failureNodes = unique(failureNodesInternal,'first');
  end
end