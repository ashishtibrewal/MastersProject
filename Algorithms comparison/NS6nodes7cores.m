function NumSlots=NS6nodes7cores()

%Generate number of slots for a 6 node topology with 7 cores links between
%each node

NumSlots(:,:,1,2)=zeros(14,200);
NumSlots(:,:,1,6)=zeros(14,200);
NumSlots(:,:,2,3)=zeros(14,200);
NumSlots(:,:,2,6)=zeros(14,200);
NumSlots(:,:,3,4)=zeros(14,200);
NumSlots(:,:,3,5)=zeros(14,200);
NumSlots(:,:,3,6)=zeros(14,200);
NumSlots(:,:,4,5)=zeros(14,200);
NumSlots(:,:,5,6)=zeros(14,200);
