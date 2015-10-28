

%CHONG NEW!!!!!!!!!


function [resource,upblocking,NumSlots]=ff1XTcheck(resource,pathmemory,link,x,NumSlots)
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
    core(i)=c(1);    %c is the core number
    Firstslot(i)=d(1);  %d is the first column number
    BW=length(d); %the bw in each link is the same
    
   end

XT=0;
for i=1:(n-1)

       % num=count7(resource,core(i),Firstslot(i),BW,a(i),b(i));
       % XTperLink(i)=(num-num*exp(-(num+1)*h*link(a(i),b(i))*1000))/(1+num*exp(-(num+1)*h*link(a(i),b(i))*1000));
        
        
        [n1,n2]=count7_2(resource,core(i),Firstslot(i),BW,a(i),b(i));  
         total_n = n1+n2;       
          n1(n1>3)=3;    
                
         XTperLink(i)=(n1+0.5*n2-n1*exp(-(total_n+1)*h*link(a(i),b(i))*1000)- n2*exp(-(total_n+1)*h*link(a(i),b(i))*1000)*0.5)/(1+n1*exp(-(total_n+1)*h*link(a(i),b(i))*1000)+n2*exp(-(total_n+1)*h*link(a(i),b(i))*1000));
        XT=XT+XTperLink(i);

end


XT=10*log10(XT);

%when XT still less than -24, just need to update the LXPR value because
%blocking and resource value is not changed.
if XT<=-24
  upblocking=0;
 
else
  upblocking=1;

end







