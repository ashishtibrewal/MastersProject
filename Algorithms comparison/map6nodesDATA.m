function link=map6nodesDATA()
% Defines all links that are present in a 6 node topology (i.e. Creates 
% links between nodes). Nodes that are not connected have a link value of
% infinity, whereas nodes that are connected have a non-zero link value.
% Need to figure out why a value of 0.025 has been chosen.
% Links between the same node is given a 0 value.

link=inf(6,6);

% Links between the same node
link(1,1)=0;
link(2,2)=0;
link(3,3)=0;
link(4,4)=0;
link(5,5)=0;
link(6,6)=0;

% Other links
link(1,2)=0.025;
link(2,1)=0.025;

link(1,6)=0.025;
link(6,1)=0.025;

link(2,3)=0.025;
link(3,2)=0.025;

link(2,6)=0.025;
link(6,2)=0.025;

link(3,4)=0.025;
link(4,3)=0.025;

link(3,5)=0.025;
link(5,3)=0.025;

link(3,6)=0.025;
link(6,3)=0.025;

link(4,5)=0.025;
link(5,4)=0.025;

link(5,6)=0.025;
link(6,5)=0.025;