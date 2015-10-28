

%CHONG NEW!!!!!!!!!


function [resource,upblocking,NumSlots]=ff1XTcheck(resource,pathmemory,link,x,NumSlots)
%h=5e-5;
BW=0;
pathmemory=pathmemory(pathmemory~=0);
n=length(pathmemory);
a=zeros(1,n-1);
b=zeros(1,n-1);
core=zeros(1,n-1);
Firstslot=zeros(1,n-1);
XTperLink=zeros(1,n-1);

up=0;
down=0;
%h=5e-5;

%-------------------------------NEW h-----------------------------------
k=6e-2;
R=50e-3;
p=4e6;
cp=30e-6;

h= (2*k^2 *R)/(p * cp);


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


for i=1:(n-1)
       XT=0;
       % num=count7(resource,core(i),Firstslot(i),BW,a(i),b(i));
       % XTperLink(i)=(num-num*exp(-(num+1)*h*link(a(i),b(i))*1000))/(1+num*exp(-(num+1)*h*link(a(i),b(i))*1000));
        
        
        [n1,n2]=count7(resource,core(i),Firstslot(i),BW,a(i),b(i));  
         total_n = n1+n2;       
              
          [n3,n4]=count7_(resource,core(i),Firstslot(i),BW,a(i),b(i)); %same direc n3--cp  n4--cp1
                 
                 up=up+ n3*(1-exp(-(total_n+1)*h*link(a(i),b(i))*1000));
                 down=down+ n3*exp(-(total_n+1)*h*link(a(i),b(i))*1000);
                 
                 if n4~=0
                     cp= sqrt(2)*cp;
                     k=4e-4;
                     h= (2*k^2 *R)/(p * cp);
                     up=up+ n4*(1-exp(-(total_n+1)*h*link(a(i),b(i))*1000));
                     down=down+ n4*exp(-(total_n+1)*h*link(a(i),b(i))*1000);
                     
                     cp=30e-6;

                     h= (2*k^2 *R)/(p * cp);
                 end
                 
                 [n5,n6]=count7__(resource,core(i),Firstslot(i),BW,a(i),b(i)); %opp direc
                    up=up+ n5*(1-exp(-(total_n+1)*h*link(a(i),b(i))*1000))*0.5;
                    down=down+ n5*exp(-(total_n+1)*h*link(a(i),b(i))*1000);
                 if n6~=0
                     cp= sqrt(2)*cp;
                     k=4e-4;
                     h= (2*k^2 *R)/(p * cp);
                     up=up+ n6*(1-exp(-(total_n+1)*h*link(a(i),b(i))*1000))*0.5;
                     down=down+ n6*exp(-(total_n+1)*h*link(a(i),b(i))*1000);
                     
                     cp=30e-6;

                     h= (2*k^2 *R)/(p * cp);
                 end
                 
                 %cp= sqrt(2)*cp;
                 %h1= (2*k^2 *R)/(p * cp);
                
                 
                 XTperLink(i)=up/(1+down);      
        % XTperLink(i)=(n1+0.5*n2-n1*exp(-(total_n+1)*h*link(a(i),b(i))*1000)- n2*exp(-(total_n+1)*h*link(a(i),b(i))*1000)*0.5)/(1+n1*exp(-(total_n+1)*h*link(a(i),b(i))*1000)+n2*exp(-(total_n+1)*h*link(a(i),b(i))*1000));
        
         
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







