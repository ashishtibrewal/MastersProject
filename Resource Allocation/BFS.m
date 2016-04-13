function [ITresourceNodes, ITsuccessful, ITfailureCause] = BFS(dataCenterMap, startNode, reqResourceUnits, updatedUnitAvailableMap, removeLinks, request)
  % Function to implement the "customised" Breadth-First Search (BFS) algorithm
  % resourceNodes - 1st row = CPUs, 2nd row = MEMs, 3rd row = STOs
  % successful - Only set if all resources have been found
  
  % Import global macros
  global SUCCESS;
  global FAILURE;

  % Import required packages
  import java.util.LinkedList     % Import java LinkedList package to be able to use queues

  % Extract required maps from the data center map struct
  completeResourceMap = dataCenterMap.completeResourceMap;
  %completeUnitAvailableMap = dataCenterMap.completeUnitAvailableMap;
  completeConnectivityMap = dataCenterMap.connectivityMap.completeConnectivity;
  completeDistanceMap = dataCenterMap.distanceMap.completeDistance;
  completeBandwidthMap = dataCenterMap.bandwidthMap.completeBandwidth;
  
  % Required resource units
  CPUunitsRequired = reqResourceUnits.reqCPUunits;
  MEMunitsRequired = reqResourceUnits.reqMEMunits;
  STOunitsRequired = reqResourceUnits.reqSTOunits;
  
  % Pre-allocate (and initialize) output variable
  ITresourceNodes = cell(3,max([CPUunitsRequired,MEMunitsRequired,STOunitsRequired]));    % This caters for worst-case allocation (i.e. one unit on each slot)
  
  % Initialize utility variables
  CPUindex = 1;
  MEMindex = 1;
  STOindex = 1;
  CPUunitsFound = 0;
  MEMunitsFound = 0;
  STOunitsFound = 0;
  CPUsBreakWhile = false;
  MEMsBreakWhile = false;
  STOsBreakWhile = false;

  % Extract request's bandwidth requirements
  %requiredBAN_CM = request{4};    % MINIMUM ACCEPTABLE BANDWIDTH (CPU-MEM)
  requiredBAN_MS = request{5};    % MINIMUM ACCEPTABLE BANDWIDTH (MEM-STO)
  
  % Remove failure nodes
  if (removeLinks == 1)
    linksToRemove = find(completeBandwidthMap < requiredBAN_MS);      % Based on MEM-STO bandwith requirement. TODO could try with CPU-MEM and see how the performance changes
    completeDistanceMap(linksToRemove) = Inf;                         % Disconnect/remove links that do not have enough bandwidth available to prevent the k-shortest paths algorithm from using them
    completeDistanceMap(logical(eye(size(completeDistanceMap)))) = 0; % Zero leading diagonal since it's set to infinity when removing 'useless' links
    completeBandwidthMap(linksToRemove) = 0;                          % Zero the bandwidth on links that do not satisfy the minimum constraints/requirements
  end
  
  % Create graph and initialize distances with infinity (Each column is a node)
  % 1st 'row' holds the node's distance from the source
  % 2nd 'row' holds the node's parent/predecessor
  % 3rd 'row' holds the node's number (i.e. it's linear label/name)
  graphNodes = cell(3,size(completeConnectivityMap,2));
  graphNodes(1,:) = {inf};    % Initialize all distances to infinity
  graphNodes(2,:) = {0};      % Initialize all parent/predecessor to 0
  graphNodes(3,:) = num2cell(1:size(completeConnectivityMap,2));  % Initialize node labels/names
  
  % Create empty queue that needs to be used to store nodes in FIFO format
  q = LinkedList();
  
  % Initialize and enqueue start node
  graphNodes{1,startNode} = 0;        % Initialize start node's distance to zero
  q.add(graphNodes(:,startNode));     % Add start node to the queue
  
  % Check source node (i.e. start node) for available resource units
  % Check source node (i.e. start node) for available CPU units
  if (CPUunitsFound < CPUunitsRequired)
    if (strcmp('CPU',completeResourceMap(startNode)) && updatedUnitAvailableMap(startNode) > 0)
      unitsFound = updatedUnitAvailableMap(startNode);
      if ((CPUunitsRequired - CPUunitsFound) >= unitsFound)
        CPUunitsFound = CPUunitsFound + unitsFound;
        ITresourceNodes{1,CPUindex} = {startNode,unitsFound};
      else
        unitsRequired = CPUunitsRequired - CPUunitsFound;
        CPUunitsFound = CPUunitsFound + unitsRequired;
        ITresourceNodes{1,CPUindex} = {startNode,unitsRequired};
      end
      CPUindex = CPUindex + 1;    % Increment index
      % If the required number of CPU units have been found
      if (CPUunitsFound == CPUunitsRequired)
        CPUsBreakWhile = true;
      end
    end
  end
  
  % Check source node (i.e. start node) for available MEM units
  if (MEMunitsFound < MEMunitsRequired)
    if (strcmp('MEM',completeResourceMap(startNode)) && updatedUnitAvailableMap(startNode) > 0)
      unitsFound = updatedUnitAvailableMap(startNode);
      if ((MEMunitsRequired - MEMunitsFound) >= unitsFound)
        MEMunitsFound = MEMunitsFound + unitsFound;
        ITresourceNodes{2,MEMindex} = {startNode,unitsFound};
      else
        unitsRequired = MEMunitsRequired - MEMunitsFound;
        MEMunitsFound = MEMunitsFound + unitsRequired;
        ITresourceNodes{2,MEMindex} = {startNode,unitsRequired};
      end
      MEMindex = MEMindex + 1;    % Increment index
      % If the required number of CPU units have been found
      if (MEMunitsFound == MEMunitsRequired)
        MEMsBreakWhile = true;
      end
    end
  end
  
  % Check source node (i.e. start node) for available STO units
  if (STOunitsFound < STOunitsRequired)
    if (strcmp('STO',completeResourceMap(startNode)) && updatedUnitAvailableMap(startNode) > 0)
      unitsFound = updatedUnitAvailableMap(startNode);
      if ((STOunitsRequired - STOunitsFound) >= unitsFound)
        STOunitsFound = STOunitsFound + unitsFound;
        ITresourceNodes{3,STOindex} = {startNode,unitsFound};
      else
        unitsRequired = STOunitsRequired - STOunitsFound;
        STOunitsFound = STOunitsFound + unitsRequired;
        ITresourceNodes{3,STOindex} = {startNode,unitsRequired};
      end
      STOindex = STOindex + 1;    % Increment index
      % If the required number of CPU units have been found
      if (STOunitsFound == STOunitsRequired)
        STOsBreakWhile = true;
      end
    end
  end
  
  % Run until the queue is empty (i.e. the whole graph is traversed)
  while (q.size() > 0)
    currentNode = q.remove();                           % Remove head of queue
    adjaceny = completeConnectivityMap(currentNode(3),:);   % Extract it's information from the connectivity/adjacency matrix
    neighbours = find(adjaceny == 1);                   % Find current nodes neighbours
    neighbourBandwidth = [];                            % Initialize empty matrix to store link bandwidth between neighbours
    neighboursIndex = [];                               % Initialize empty index array
    
    % Extract the bandwidth available on links to neighbouring nodes
    for i = 1:size(neighbours,2)
      neighbourBandwidth(i) = completeBandwidthMap(currentNode(3),neighbours(i));
    end
    
    % Extract the links in descending order and update the index matrix
    for i = 1:size(neighbourBandwidth,2)
      [~,index] = max(neighbourBandwidth);
      neighboursIndex = [neighboursIndex,index];
      neighbourBandwidth(index) = 0;
    end
    
    % Find a random permutation to be used as vector indices
    %neighboursIndex = randperm(numel(neighbours));
    
    % Iterate through all it's neighbours
    for node = 1:size(neighbours,2)
      nNode = neighboursIndex(node);                    % Extract a node inxed from the neighboursIndex vector
      if (graphNodes{1,neighbours(nNode)} == inf)
        graphNodes{1,neighbours(nNode)} = graphNodes{1,currentNode(3)} + completeDistanceMap(currentNode(3),neighbours(nNode));
        graphNodes{2,neighbours(nNode)} = graphNodes{3,currentNode(3)};
        q.add(graphNodes(:,neighbours(nNode)));
        
        % Find CPU units
        if (CPUunitsFound < CPUunitsRequired)
          % If a required type of resource node is found that's got at least a single unit free, store it's location
          if (strcmp('CPU',completeResourceMap(neighbours(nNode))) && updatedUnitAvailableMap(neighbours(nNode)) > 0)
            unitsFound = updatedUnitAvailableMap(neighbours(nNode));
            if ((CPUunitsRequired - CPUunitsFound) >= unitsFound)
              CPUunitsFound = CPUunitsFound + unitsFound;
              ITresourceNodes{1,CPUindex} = {neighbours(nNode),unitsFound};
            else
              unitsRequired = CPUunitsRequired - CPUunitsFound;
              CPUunitsFound = CPUunitsFound + unitsRequired;
              ITresourceNodes{1,CPUindex} = {neighbours(nNode),unitsRequired};
            end
            CPUindex = CPUindex + 1;    % Increment index
          end
          % If the required number of CPU units have been found
          if (CPUunitsFound == CPUunitsRequired)
            CPUsBreakWhile = true;
          end
        else
          CPUsBreakWhile = true;
        end
        
        % Find MEM units
        if (MEMunitsFound < MEMunitsRequired)
          % If a required type of resource node is found that's got at least a single unit free, store it's location
          if (strcmp('MEM',completeResourceMap(neighbours(nNode))) && updatedUnitAvailableMap(neighbours(nNode)) > 0)
            unitsFound = updatedUnitAvailableMap(neighbours(nNode));
            if ((MEMunitsRequired - MEMunitsFound) >= unitsFound)
              MEMunitsFound = MEMunitsFound + unitsFound;
              ITresourceNodes{2,MEMindex} = {neighbours(nNode),unitsFound};
            else
              unitsRequired = MEMunitsRequired - MEMunitsFound;
              MEMunitsFound = MEMunitsFound + unitsRequired;
              ITresourceNodes{2,MEMindex} = {neighbours(nNode),unitsRequired};
            end
            MEMindex = MEMindex + 1;    % Increment index
          end
          % If the required number of MEM units have been found
          if (MEMunitsFound == MEMunitsRequired)
            MEMsBreakWhile = true;
          end
        else
          MEMsBreakWhile = true;
        end
        
        % Find STO units
        if (STOunitsFound < STOunitsRequired)
          % If a required type of resource node is found that's got at least a single unit free, store it's location
          if (strcmp('STO',completeResourceMap(neighbours(nNode))) && updatedUnitAvailableMap(neighbours(nNode)) > 0)
            unitsFound = updatedUnitAvailableMap(neighbours(nNode));
            if ((STOunitsRequired - STOunitsFound) >= unitsFound)
              STOunitsFound = STOunitsFound + unitsFound;
              ITresourceNodes{3,STOindex} = {neighbours(nNode),unitsFound};
            else
              unitsRequired = STOunitsRequired - STOunitsFound;
              STOunitsFound = STOunitsFound + unitsRequired;
              ITresourceNodes{3,STOindex} = {neighbours(nNode),unitsRequired};
            end
            STOindex = STOindex + 1;    % Increment index
          end
          % If the required number of STO units have been found
          if (STOunitsFound == STOunitsRequired)
            STOsBreakWhile = true;
          end
        else
          STOsBreakWhile = true;
        end
      end
    end
    
    % If all required resources have been found break out of the while loop else keep searching
    if (CPUsBreakWhile == true && MEMsBreakWhile == true && STOsBreakWhile == true)
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
  
end