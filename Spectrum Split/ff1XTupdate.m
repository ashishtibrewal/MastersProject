
%CHONG NEW!!!!!!!!!

function [resource,upXT1,LXPR,NumSlots]=ff1XTupdate(resource,pathmemory,link,x,LXPR,NumSlots)

h=3e-6;
BW=0;
pathmemory=pathmemory(pathmemory~=0);
n=length(pathmemory);
a=zeros(1,n-1);
b=zeros(1,n-1);
core=zeros(1,n-1);
Firstslot=zeros(1,n-1);
XTperLink=zeros(1,n-1);

%requestNum is the number of request coming.

% XT=10*log10(3-3*exp(-4*h*distance*1000))-10*log10(1+3*exp(-4*h*distance*1000));
% XT1=10*log10(6-6*exp(-7*h*distance*1000))-10*log10(1+6*exp(-7*h*distance*1000));
for i=1:(n-1)
    a(i)=pathmemory(i);
    b(i)=pathmemory(i+1);
    if a(i)>b(i)
        k=a(i);
        a(i)=b(i);
        b(i)=k;
    end
end

for i=1:(n-1)
    [c,d]=find(NumSlots(:,:,a(i),b(i))==x);
    core(i)=c(1);    %c is the core number of affected request
    Firstslot(i)=d(1);  %d is the first column number of affected request
    BW=length(d); %the bw in each link is the same of affected request
end

XT=0;
for i=1:(n-1)

    

      %  num=count7(resource,core(i),Firstslot(i),BW,a(i),b(i));
      %  XTperLink(i)=(num-num*exp(-(num+1)*h*link(a(i),b(i))*1000))/(1+num*exp(-(num+1)*h*link(a(i),b(i))*1000));
        
        
       [n1,n2]=count7_2(resource,core(i),Firstslot(i),BW,a(i),b(i));  
        total_n = n1+n2;        
         n1(n1>3)=3;     
                
         XTperLink(i)=(n1+0.5*n2-n1*exp(-(total_n+1)*h*link(a(i),b(i))*1000)- n2*exp(-(total_n+1)*h*link(a(i),b(i))*1000)*0.5)/(1+n1*exp(-(total_n+1)*h*link(a(i),b(i))*1000)+n2*exp(-(total_n+1)*h*link(a(i),b(i))*1000));
        XT=XT+XTperLink(i);

    
end


%when XT still less than -24, just need to update the LXPR value because
%blocking and resource value is not changed.
    for i=1:n-1
        for j=1:BW
            LXPR(core(i),Firstslot(i)+j-1,a(i),b(i))=XTperLink(i);
        end
    end
    upXT1=XT;
    
   
    



% if core~=1
%     for m=1:n-1
%         num=count7(resource,core,col,BW,a(m),b(m));
%         XTperLink(m)=(num-num*exp(-(num+1)*h*link(a(m),b(m))*1000))/(1+num*exp(-(num+1)*h*link(a(m),b(m))*1000));
%         XT=XT+XTperLink(m);
%
%     end
%     XT=10*log10(XT);
%     if XT<=-24
%         for k=i:i+BW-1
%             column=mod(k,100);
%             if column==0
%                 column=100;
%             end
%             row=ceil(k/100);
%             for j=1:n-1
%                 resource(row,column,a(j),b(j))=0;
%                 LXPR(row,column,x,a(j),b(j))=XTperLink(j);
%                 NumSlots(row,column,a(j),b(j))=x;
%
%                 if XTperLink(j)~=0
%
%                     ReqNum=find7(row,column,a(j),b(j),NumSlots);
%                 end
%                 % ReqNum is the request number affected by this XT
%                 % ReqNums is the array to store all affected requests
%                 for l=1:6
%                     if isempty(find(ReqNums==ReqNum(l), 1))==1
%                         ReqNums=[ReqNmus ReqNum(l)];
%                     end
%                 end
%             end
%         end
%         upXT1=XT;
%         break;
%     end
% end
% if i==slot+1-BW
%     upblocking=1;
%     upXT1=-inf;
% end
% end






