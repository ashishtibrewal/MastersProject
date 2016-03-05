function [ITresourceNodes, ITsuccessful, ITfailureCause] = BFS(dataCenterMap, startNode, reqResourceUnits)
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
  completeUnitAvailableMap = dataCenterMap.completeUnitAvailableMap;
  completeConnectivityMap = dataCenterMap.connectivityMap.completeConnectivity;
  completeDistanceMap = dataCenterMap.distanceMap.completeDistance;
  
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
    if (strcmp('CPU',completeResourceMap(startNode)) && completeUnitAvailableMap(startNode) > 0)
      unitsFound = completeUnitAvailableMap(startNode);
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
    if (strcmp('MEM',completeResourceMap(startNode)) && completeUnitAvailableMap(startNode) > 0)
      unitsFound = completeUnitAvailableMap(startNode);
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
    if (strcmp('STO',completeResourceMap(startNode)) && completeUnitAvailableMap(startNode) > 0)
      unitsFound = completeUnitAvailableMap(startNode);
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
    currentNode = q.remove();     % Remove head of queue
    adjaceny = completeConnectivityMap(currentNode(3),:);   % Extract it's information from the connectivity/adjacency matrix
    neighbours = find(adjaceny == 1);   % Find current nodes neighbours
    
    % Iterate through all it's neighbours
    for nNode = 1:size(neighbours,2)
      if (graphNodes{1,neighbours(nNode)} == inf)
        graphNodes{1,neighbours(nNode)} = graphNodes{1,currentNode(3)} + completeDistanceMap(currentNode(3),neighbours(nNode));
        graphNodes{2,neighbours(nNode)} = graphNodes{3,currentNode(3)};
        q.add(graphNodes(:,neighbours(nNode)));
        
        % Find CPU units
        if (CPUunitsFound < CPUunitsRequired)
          % If a required type of resource node is found that's got at least a single unit free, store it's location
          if (strcmp('CPU',completeResourceMap(neighbours(nNode))) && completeUnitAvailableMap(neighbours(nNode)) > 0)
            unitsFound = completeUnitAvailableMap(neighbours(nNode));
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
          if (strcmp('MEM',completeResourceMap(neighbours(nNode))) && completeUnitAvailableMap(neighbours(nNode)) > 0)
            unitsFound = completeUnitAvailableMap(neighbours(nNode));
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
          if (strcmp('STO',completeResourceMap(neighbours(nNode))) && completeUnitAvailableMap(neighbours(nNode)) > 0)
            unitsFound = completeUnitAvailableMap(neighbours(nNode));
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