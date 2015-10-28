function [resource,LXPR,NumSlots,linkblock]=ff1XTconvertDBswitchsplit(path,resource,x,LXPR,NumSlots,linkblock,t)

n=length(path);
a=zeros(1,n-1);
b=zeros(1,n-1);
core=zeros(1,n-1);
Firstslot=zeros(1,n-1);

for i=1:(n-1)
    a(i)=path(i);
    b(i)=path(i+1);
    if a(i)>b(i)
        k=a(i);
        a(i)=b(i);
        b(i)=k;
    end
end
%  for m=1:(n-1)
%   
% linkblock(2,a(m),b(m))=linkblock(2,a(m),b(m))+1;
% 
%  end        
%         

for k=1:t
    
for i=1:(n-1)
    [c,d]=find(NumSlots(:,:,a(i),b(i))==x+0.01*k);
    core(i)=c(1);    %c is the core number
    Firstslot(i)=d(1);  %d is the first column number
    BW=length(d); %the bw in each link is the same
end

for i=1:(n-1)
    for j=1:BW
        
        resource(core(i),Firstslot(i)+j-1,a(i),b(i))=1;
        LXPR(core(i),Firstslot(i)+j-1,a(i),b(i))=0;
        NumSlots(core(i),Firstslot(i)+j-1,a(i),b(i))=0;
        
    end
end
end