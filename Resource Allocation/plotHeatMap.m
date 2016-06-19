function plotHeatMap(dataCenterConfig, dataCenterMap, updateType, displayFigures)
% Function to plot the heatmap that represents the resource utilisation on
% each node (a node is a slot in this context)

  % Extract data center configuration parameters
  nRacks = dataCenterConfig.nRacks;
  nBlades = dataCenterConfig.nBlades;
  nSlots = dataCenterConfig.nSlots;
  nUnits = dataCenterConfig.nUnits;
  nTOR = dataCenterConfig.nTOR;
  nTOB = dataCenterConfig.nTOB;
  
  nTORs = nTOR * nRacks;
  nTOBs = nTOB * nBlades * nRacks;
  nNodes = nSlots * nBlades * nRacks;
  nNodesPerRack = nSlots * nBlades;
  
  startNode = (nTORs + nTOBs);
  endNode = startNode + nNodes;
  

  % Find number of subfigures required
  nFigsFactors = [];
  for i = 1:(nRacks * 2)
    if (mod((nRacks * 2),i) == 0)
      nFigsFactors = [nFigsFactors,i];
    end
  end

  nFigsFactorsSize = size(nFigsFactors,2);
  if (mod(nFigsFactorsSize,2) == 0)
    nSubFigs = [nFigsFactors(nFigsFactorsSize/2), nFigsFactors((nFigsFactorsSize/2) + 1)];
  else
    nSubFigs = [nFigsFactors(ceil(nFigsFactorsSize/2)), nFigsFactors(ceil(nFigsFactorsSize/2))];
  end

  % Find factors (multiples) of nNodes to be able to create a scalable heatmap
  nNodesFactors = [];
  for i = 1:nNodesPerRack
    if (mod(nNodesPerRack,i) == 0)
      nNodesFactors = [nNodesFactors,i];
    end
  end
  
  nNodesFactorsSize = size(nNodesFactors,2);
  if (mod(nNodesFactorsSize,2) == 0)
    hmSize = [nNodesFactors(nNodesFactorsSize/2), nNodesFactors((nNodesFactorsSize/2) + 1)];
  else
    hmSize = [nNodesFactors(ceil(nNodesFactorsSize/2)), nNodesFactors(ceil(nNodesFactorsSize/2))];
  end

  hmSize = [nBlades, nSlots];
  
  % Sub tight plot parameters
  gap = [0.05,0.01];
  margin_tb = [0.02,0.04];
  margin_rl = [0.02,0.02];

  scaleFactor = 8;

  rmap = zeros([hmSize,3]);
  rmapScaled = zeros([(hmSize * scaleFactor),3]);
  
  hmap = zeros([hmSize,3]);
  hmapScaled = zeros([(hmSize * scaleFactor),3]);

%   x = linspace(0,nSlots,(nSlots + 1));
%   y = linspace(0,nBlades,(nBlades + 1));
% 
%   % Horizontal grid 
%   for k = 1:length(y)
%     line([x(1) x(end)], [y(k) y(k)]);
%   end
% 
%   % Vertical grid
%   for k = 1:length(x)
%     line([x(k) x(k)], [y(1) y(end)]);
%   end
% 
%   axis square
  
  switch (updateType)
    case 'locationMap'
      if (displayFigures == 1)
        % Open new figure (Done once before starting the main time loop)
        figure('Name', 'Data Center Heatmap', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
      else
        % Open new figure but turn its visibility off
        figure('Name', 'Data Center Heatmap', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
      end
      figNo = 1;
      for i = 1:nRacks
        startNode = (nTORs + nTOBs) + ((i - 1) * (nSlots * nBlades));
        for r = 1:hmSize(1)
          for c = 1:hmSize(2)
            nodeType = dataCenterMap.completeResourceMap(startNode + ((r - 1) * hmSize(2)) + c);
            if (strcmp(nodeType, 'CPU') == 1)
                rmap(r,c,:) = [0,0,0];
            elseif (strcmp(nodeType, 'MEM') == 1)
                rmap(r,c,:) = [1,1,1];
            elseif (strcmp(nodeType, 'STO') == 1)
                rmap(r,c,:) = [0.5,0.5,0.5];
            end
          end
        end

        for r = 1:hmSize(1)
          for c = 1:hmSize(2)
            rmapScaled((((r - 1) * scaleFactor) + 1):(r * scaleFactor),(((c - 1) * scaleFactor) + 1):(c * scaleFactor),1) = rmap(r,c,1);
            rmapScaled((((r - 1) * scaleFactor) + 1):(r * scaleFactor),(((c - 1) * scaleFactor) + 1):(c * scaleFactor),2) = rmap(r,c,2);
            rmapScaled((((r - 1) * scaleFactor) + 1):(r * scaleFactor),(((c - 1) * scaleFactor) + 1):(c * scaleFactor),3) = rmap(r,c,3);
          end
        end

        subtightplot(nSubFigs(1),nSubFigs(2),figNo,gap,margin_tb,margin_rl);

        for r = 1:hmSize(1)
          for c = 1:hmSize(2)
            nodeType = dataCenterMap.completeResourceMap(startNode + ((r - 1) * hmSize(2)) + c);
            if (strcmp(nodeType, 'CPU') == 1)
                colorRGB = [0,0,0];
                rectangle('Position', [((c - 1) * 2), ((hmSize(1) * 2) - (r * 2)), 2, 2], 'FaceColor', colorRGB, 'EdgeColor', [1,1,1]);
            elseif (strcmp(nodeType, 'MEM') == 1)
                colorRGB = [1,1,1];
                rectangle('Position', [((c - 1) * 2), ((hmSize(1) * 2) - (r * 2)), 2, 2], 'FaceColor', colorRGB);
            elseif (strcmp(nodeType, 'STO') == 1)
                colorRGB = [0.5,0.5,0.5];
                rectangle('Position', [((c - 1) * 2), ((hmSize(1) * 2) - (r * 2)), 2, 2], 'FaceColor', colorRGB);
            end
          end
        end
        %axis([0,(nSlots * 2),0,(nBlades * 2)]);
        axis tight;   % Extend plot to the edges
        axis off;
        str = sprintf('Rack %d Setup', i);
        title(str);

%         x = linspace(0,nSlots,(nSlots + 1));
%         y = linspace(0,nBlades,(nBlades + 1));
% 
%         % Horizontal grid 
%         for k = 1:length(y)
%           line([x(1) x(end)], [y(k) y(k)]);
%         end
% 
%         % Vertical grid
%         for k = 1:length(x)
%           line([x(k) x(k)], [y(1) y(end)]);
%         end
%         
%         axis off;
        
%         subtightplot(nSubFigs(1),nSubFigs(2),figNo,[0.01,0],0,0);
%         imshow(rmapScaled);
%         str = sprintf('Rack %d S', i);
%         title(str);
%         if (mod(i,nSubFigs(2)) == 0)
%           figNo = figNo + (nSubFigs(2) + 1);
%         else
%           figNo = figNo + 1;
%         end

        if (mod(i,nSubFigs(2)) == 0)
          figNo = figNo + (nSubFigs(2) + 1);
        else
          figNo = figNo + 1;
        end
      end

      %title('Resource type - CPUs = Black, MEMs = While, STOs = Grey');
      
    case 'heatMap'
      figNo = nSubFigs(2) + 1;
      for i = 1:nRacks
        startNode = (nTORs + nTOBs) + ((i - 1) * (nSlots * nBlades));
        for r = 1:hmSize(1)
          for c = 1:hmSize(2)
            nodeVal = dataCenterMap.completeUnitAvailableMap(startNode + ((r - 1) * hmSize(2)) + c);
            avalibilityRatio = nodeVal/nUnits;
            hmap(r,c,:) = [(1 - avalibilityRatio), avalibilityRatio, 0];
          end
        end

        for r = 1:hmSize(1)
          for c = 1:hmSize(2)
            hmapScaled((((r - 1) * scaleFactor) + 1):(r * scaleFactor),(((c - 1) * scaleFactor) + 1):(c * scaleFactor),1) = hmap(r,c,1);
            hmapScaled((((r - 1) * scaleFactor) + 1):(r * scaleFactor),(((c - 1) * scaleFactor) + 1):(c * scaleFactor),2) = hmap(r,c,2);
            hmapScaled((((r - 1) * scaleFactor) + 1):(r * scaleFactor),(((c - 1) * scaleFactor) + 1):(c * scaleFactor),3) = hmap(r,c,3);
          end
        end

        subtightplot(nSubFigs(1),nSubFigs(2),figNo,gap,margin_tb,margin_rl);

        for r = 1:hmSize(1)
          for c = 1:hmSize(2)
            nodeVal = dataCenterMap.completeUnitAvailableMap(startNode + ((r - 1) * hmSize(2)) + c);
            avalibilityRatio = nodeVal/nUnits;
            colorRGB = [(1 - avalibilityRatio), avalibilityRatio, 0];
            rectangle('Position', [((c - 1) * 2), ((hmSize(1) * 2) - (r * 2)), 2, 2], 'FaceColor', colorRGB);
          end
        end
        %axis([0,(nSlots * 2),0,(nBlades * 2)]);
        axis tight;   % Extend plot to the edges
        axis off;
        str = sprintf('Rack %d Utilisation', i);
        title(str);

%         x = linspace(0,nSlots,(nSlots + 1));
%         y = linspace(0,nBlades,(nBlades + 1));
% 
%         % Horizontal grid 
%         for k = 1:length(y)
%           line([x(1) x(end)], [y(k) y(k)]);
%         end
% 
%         % Vertical grid
%         for k = 1:length(x)
%           line([x(k) x(k)], [y(1) y(end)]);
%         end
%       
%         axis off;

%         subtightplot(nSubFigs(1),nSubFigs(2),figNo,[0.01,0],0,0);
%         imshow(rmapScaled);
%         str = sprintf('Rack %d U', i);
%         title(str);
%         if (mod(i,nSubFigs(2)) == 0)
%           figNo = figNo + (nSubFigs(2) + 1);
%         else
%           figNo = figNo + 1;
%         end

        if (mod(i,nSubFigs(2)) == 0)
          figNo = figNo + (nSubFigs(2) + 1);
        else
          figNo = figNo + 1;
        end
      end
      
      %title('Resource Utilization - Green = Max free, Yellow = Min free, Red = None free');
      
    case 'allMapsSetup' 
      if (displayFigures == 1)
        % Open new figure (Done once before starting the main time loop)
        figure('Name', 'Data Center Heatmap', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
      else
        % Open new figure but turn its visibility off
        figure('Name', 'Data Center Heatmap', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700], 'Visible', 'off');
      end
      figNo_s = 1;
      figNo_h = nSubFigs(2) + 1;
      for i = 1:nRacks
        % Plot rack setup
        startNode_s = (nTORs + nTOBs) + ((i - 1) * (nSlots * nBlades));
        subtightplot(nSubFigs(1),nSubFigs(2),figNo_s,gap,margin_tb,margin_rl);
        for r = 1:hmSize(1)
          for c = 1:hmSize(2)
            nodeType = dataCenterMap.completeResourceMap(startNode_s + ((r - 1) * hmSize(2)) + c);
            if (strcmp(nodeType, 'CPU') == 1)
                colorRGB = [0,0,0];
                rectangle('Position', [((c - 1) * 2), ((hmSize(1) * 2) - (r * 2)), 2, 2], 'FaceColor', colorRGB, 'EdgeColor', [1,1,1]);
            elseif (strcmp(nodeType, 'MEM') == 1)
                colorRGB = [1,1,1];
                rectangle('Position', [((c - 1) * 2), ((hmSize(1) * 2) - (r * 2)), 2, 2], 'FaceColor', colorRGB);
            elseif (strcmp(nodeType, 'STO') == 1)
                colorRGB = [0.5,0.5,0.5];
                rectangle('Position', [((c - 1) * 2), ((hmSize(1) * 2) - (r * 2)), 2, 2], 'FaceColor', colorRGB);
            end
          end
        end
        %axis([0,(nSlots * 2),0,(nBlades * 2)]);
        axis tight;   % Extend plot to the edges
        axis off;
        str = sprintf('Rack %d Setup', i);
        title(str);
        if (mod(i,nSubFigs(2)) == 0)
          figNo_s = figNo_s + (nSubFigs(2) + 1);
        else
          figNo_s = figNo_s + 1;
        end
        
        % Plot rack utilization
        startNode_h = (nTORs + nTOBs) + ((i - 1) * (nSlots * nBlades));
        subtightplot(nSubFigs(1),nSubFigs(2),figNo_h,gap,margin_tb,margin_rl);
        for r = 1:hmSize(1)
          for c = 1:hmSize(2)
            nodeVal = dataCenterMap.completeUnitAvailableMap(startNode_h + ((r - 1) * hmSize(2)) + c);
            avalibilityRatio = nodeVal/nUnits;
            colorRGB = [(1 - avalibilityRatio), avalibilityRatio, 0];
            rectangle('Position', [((c - 1) * 2), ((hmSize(1) * 2) - (r * 2)), 2, 2], 'FaceColor', colorRGB);
          end
        end
        %axis([0,(nSlots * 2),0,(nBlades * 2)]);
        axis tight;   % Extend plot to the edges
        axis off;
        str = sprintf('Rack %d Utilisation', i);
        title(str);
        if (mod(i,nSubFigs(2)) == 0)
          figNo_h = figNo_h + (nSubFigs(2) + 1);
        else
          figNo_h = figNo_h + 1;
        end
      end
      
    case 'allMaps' 
      figNo_s = 1;
      figNo_h = nSubFigs(2) + 1;
      % Clear figure before plotting
      clf;
      for i = 1:nRacks
        % Plot rack setup
        startNode_s = (nTORs + nTOBs) + ((i - 1) * (nSlots * nBlades));
        subtightplot(nSubFigs(1),nSubFigs(2),figNo_s,gap,margin_tb,margin_rl);
        for r = 1:hmSize(1)
          for c = 1:hmSize(2)
            nodeType = dataCenterMap.completeResourceMap(startNode_s + ((r - 1) * hmSize(2)) + c);
            if (strcmp(nodeType, 'CPU') == 1)
                colorRGB = [0,0,0];
                rectangle('Position', [((c - 1) * 2), ((hmSize(1) * 2) - (r * 2)), 2, 2], 'FaceColor', colorRGB, 'EdgeColor', [1,1,1]);
            elseif (strcmp(nodeType, 'MEM') == 1)
                colorRGB = [1,1,1];
                rectangle('Position', [((c - 1) * 2), ((hmSize(1) * 2) - (r * 2)), 2, 2], 'FaceColor', colorRGB);
            elseif (strcmp(nodeType, 'STO') == 1)
                colorRGB = [0.5,0.5,0.5];
                rectangle('Position', [((c - 1) * 2), ((hmSize(1) * 2) - (r * 2)), 2, 2], 'FaceColor', colorRGB);
            end
          end
        end
        %axis([0,(nSlots * 2),0,(nBlades * 2)]);
        axis tight;   % Extend plot to the edges
        axis off;
        str = sprintf('Rack %d Setup', i);
        title(str);
        if (mod(i,nSubFigs(2)) == 0)
          figNo_s = figNo_s + (nSubFigs(2) + 1);
        else
          figNo_s = figNo_s + 1;
        end
        
        % Plot rack utilization
        startNode_h = (nTORs + nTOBs) + ((i - 1) * (nSlots * nBlades));
        subtightplot(nSubFigs(1),nSubFigs(2),figNo_h,gap,margin_tb,margin_rl);
        for r = 1:hmSize(1)
          for c = 1:hmSize(2)
            nodeVal = dataCenterMap.completeUnitAvailableMap(startNode_h + ((r - 1) * hmSize(2)) + c);
            avalibilityRatio = nodeVal/nUnits;
            colorRGB = [(1 - avalibilityRatio), avalibilityRatio, 0];
            rectangle('Position', [((c - 1) * 2), ((hmSize(1) * 2) - (r * 2)), 2, 2], 'FaceColor', colorRGB);
          end
        end
        %axis([0,(nSlots * 2),0,(nBlades * 2)]);
        axis tight;   % Extend plot to the edges
        axis off;
        str = sprintf('Rack %d Utilisation', i);
        title(str);
        if (mod(i,nSubFigs(2)) == 0)
          figNo_h = figNo_h + (nSubFigs(2) + 1);
        else
          figNo_h = figNo_h + 1;
        end
      end
  end
      
  %blocked = find(cell2mat(requestDB(1:t,9)) == 0);
  %nBlocked = [nBlocked,size(blocked,1)];
  %subplot(1,3,3);
  %plot(nBlocked,t);
  %title('Blocking probability');

  pause(0.001);      % Pause to update the plot/figure (Pausing for 100 ms)

end
