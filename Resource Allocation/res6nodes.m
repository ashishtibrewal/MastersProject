function resource=res6nodes()
% res6nodes - Function to generate a 4D (boolean) matrix that represents 
% node/resource on a network topology with 6 nodes. A value of 1 represents
% that it is available and a value of 0 represents that it is unavailable.

  resource(:,:,1,2)=ones(14,200);
  resource(:,:,1,6)=ones(14,200);
  
  resource(:,:,2,3)=ones(14,200);
  resource(:,:,2,6)=ones(14,200);
  
  resource(:,:,3,4)=ones(14,200);
  resource(:,:,3,5)=ones(14,200);
  resource(:,:,3,6)=ones(14,200);
  
  resource(:,:,4,5)=ones(14,200);
  
  resource(:,:,5,6)=ones(14,200);
  
end
