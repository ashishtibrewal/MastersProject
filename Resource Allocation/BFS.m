function resourceNode = BFS(dataCenterMap, startNode)
  % Function to implement the Breadth-First Search (BFS) algorithm

  % Import required packages
  import java.util.LinkedList     % Import java LinkedList package to be able to use queues

  % Extract required maps from the data center map struct
  completeResourceMap = dataCenterMap.completeResourceMap;
  unitAvailableMap = dataCenterMap.completeUnitAvailableMap;
  completeConnectivityMap = dataCenterMap.connectivityMap.completeConnectivity;
  
  % Create graph and initialize distances with infinity
  % 1st 'row' holds the node's distance from the source
  % 2nd 'row' holds the node's parent/predecessor
  % 3rd 'row' holds the node's number (i.e. it's label/name)
  graphNodes = cell(3,size(completeConnectivityMap,2));
  graphNodes(1,:) = {inf};    % Initialize all distances to infinity
  graphNodes(2,:) = {0};      % Initialize all parent/predecessor to 0
  graphNodes(3,:) = num2cell(1:size(completeConnectivityMap,2));  % Initialize node labels/names
  
  % Create empty queue that needs to be used to store nodes in FIFO format
  q = LinkedList();
  
  % Initialize and enqueue start node
  graphNodes{1,startNode} = 0;
  q.add(graphNodes(:,startNode));
  
  % Run until the queue is empty (i.e. the whole graph is traversed)
  while (q.size() > 0)
    currentNode = q.remove();     % Remove head of queue
    adjaceny = completeConnectivityMap(currentNode(3,:),:);   % Extract it's information from the connectivity/adjacency matrix
    neighbours = find(adjaceny == 1);   % Find current nodes neighbours
    
    % Iterate through all it's neighbours
    for nNode = 1:size(neighbours,2)
      if (graphNodes{1,neighbours(nNode)} == inf)
        graphNodes{1,neighbours(nNode)} = graphNodes{1,currentNode(3,:)} + 1;   %TODO Could potentially add real distance values
        graphNodes{2,neighbours(nNode)} = graphNodes{3,currentNode(3,:)};
        q.add(graphNodes(:,neighbours(nNode)));
      end
    end
  end
  resourceNode = 0;
end