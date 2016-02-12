function plotDataCenterLayout(dataCenterMap, dataCenterConfig)
% Function to plot the data center layout (i.e. how all racks are laid out
% (and connected) in the data center, how all blades are laid out (and 
% connected) in each rack and how each slot is laid out (and connected) in
% each blade.

  % Extract data center network map from data center map struct
  networkMap = dataCenterMap.networkMap;

%   racksCPU = dataCenterConfig.racksCPU;   % Extract the CPU nodes
%   racksMEM = dataCenterConfig.racksMEM;   % Extract the MEM nodes
%   racksSTO = dataCenterConfig.racksSTO;   % Extract the STO nodes
  
  figure ('Name', 'Data Center Topology', 'NumberTitle', 'off', 'Position', [150, 50, 1000, 700]);
  subplot(2,2,1);
  G_racks = graph(networkMap.rackConnectivity, 'OmitSelfLoops');
  plot(G_racks, 'Layout', 'circle');
%   H_racks = plot(G_racks, 'Layout', 'circle');
%   highlight(H_racks, racksCPU, 'NodeColor', 'r'); % Red nodes are CPU nodes
%   highlight(H_racks, racksMEM, 'NodeColor', 'g'); % Red nodes are MEM nodes
%   highlight(H_racks, racksSTO, 'NodeColor', 'b'); % Red nodes are STO nodes
  title('Data Center Topology - Nodes = Racks, Edges = Connections');
  
  subplot(2,2,2);
  G_blades = graph(networkMap.bladeConnectivity(:,:,1), 'OmitSelfLoops');
  plot(G_blades, 'Layout', 'layered');
  title('Intra-rack (Blade) Topology (On Rack 1) - Nodes = Blades, Edges = Connections');
  
  subplot(2,2,3);
  G_slots = graph(networkMap.slotConnectivity(:,:,1,1), 'OmitSelfLoops');
  plot(G_slots, 'Layout', 'layered');
  title('Intra-blade (Slot) Topology (On Rack 1, Blade 1) - Nodes = Slots, Edges = Connections)');
  
  % Fourth plot to be used for intra-slot (Unit) topology  
  % subplot(2,2,4);

end

