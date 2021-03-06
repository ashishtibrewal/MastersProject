function [resource,blocking,XTtotal,LXPR,NumSlots,ReqNums,XTblock,EXTblock,linkblock,XTeach]=ff1XTnewsplit(BW,path,link,resource,x,LXPR,NumSlots,linkblock,pathmemory,XTtotal,XTeach)
XTblock=0;
EXTblock=0;
blocking=0;
n=length(path);
a=zeros(1,n-1);
b=zeros(1,n-1);
h=5e-5;
corecost=zeros(1,7);


% XT=10*log10(3-3*exp(-4*h*distance*1000))-10*log10(1+3*exp(-4*h*distance*1000));
% XT1=10*log10(6-6*exp(-7*h*distance*1000))-10*log10(1+6*exp(-7*h*distance*1000));

for i=1:(n-1)
    a(i)=path(i);
    b(i)=path(i+1);
    if a(i)>b(i)
        k=a(i);
        a(i)=b(i);
        b(i)=k;
    end
end


for i=1:(n-1)
    linkblock(1,a(i),b(i))=linkblock(1,a(i),b(i))+1;
end


ReqNumsMeM=0;

for t=1:BW(x)/2
    
corecost(7)=inf;

for time=1:7
    
    if time==1
    [~,corenum]=max(corecost);
    else
    [~,corenum]=min(corecost);
    end

    corecost=cost7(corecost,corenum);
    
    for i=1+(corenum-1)*200:corenum*200+1-2
        
        sum=0;
        XT=0;
        out=0;
        upblocking=0;
            %upblocking value notes down how many
            %previous requests are blocked due to
            %new request.
        ReqNum=zeros(1,6);
        ReqNums=0;
        XTperLink=zeros(1,n-1);
        
         for k=i:i+2-1 
            column=mod(k,200);
            if column==0
                column=200;
            end
            row=ceil(k/200);
            
            for j=1:n-1
                sum=sum+resource(row,column,a(j),b(j));
            end
            
         end
        
        col=mod(i,200);
        
        
        for m=1:n-1
            num=count7(resource,row,col,2,a(m),b(m));
            XTperLink(m)=(num-num*exp(-(num+1)*h*link(a(m),b(m))*1000))/(1+num*exp(-(num+1)*h*link(a(m),b(m))*1000));
            XT=XT+(num-num*exp(-(num+1)*h*link(a(m),b(m))*1000))/(1+num*exp(-(num+1)*h*link(a(m),b(m))*1000));
        end
        
        

        
        XT2=10*log10(XT);
        
        if sum==(n-1)*2&&XT2>-24
            XTblock=1;
        end
        
        if sum==(n-1)*2&&XT2<=-24
            for k=i:i+2-1
            column=mod(k,200);
                if column==0
                    column=200;
                end
                row=ceil(k/200); 
                for j=1:n-1
                    resource(row,column,a(j),b(j))=0;
                    LXPR(row,column,a(j),b(j))=XTperLink(j);
                    NumSlots(row,column,a(j),b(j))=x+0.01*t;
                    %x+0.01t give different slots a specific NumSlots
                    %number
                    
                    if XTperLink(j)~=0
                        
                        ReqNum=find7(row,column,a(j),b(j),NumSlots);
                        %ReqNum has decimial value
                    end
                    % ReqNum is the request number affected by this XT
                    % ReqNums is the array to store all affected requests
                    for l=1:6
                        if isempty(find(ReqNums==ReqNum(l), 1))==1
                            ReqNums=[ReqNums ReqNum(l)];
                        end
                    end
                end
            end
            %if ReqNums~=1 which means there are some xt in requests
            %need to be updated.
            % the all upblocking value should be 0, then the new request
            % can work, otherwise new request is blocked.

            
            if length(ReqNums)~=1
                
                for k=2:length(ReqNums)%ReqNums(1)=0;
                    [resource,upblocking,NumSlots]=ff1XTcheck(resource,pathmemory(floor(ReqNums(k)),:),link,ReqNums(k),NumSlots);
                    if upblocking~=0
                        break
                    end
                end
                
                if upblocking~=0
                    EXTblock=1;
                    XTblock=0;
                    %Then we need to convert resource of new request back to 1
                    %and add one block number
                    [resource,LXPR,NumSlots,linkblock]=ff1XTconvertDBs(path,resource,x,LXPR,NumSlots,linkblock,t);
                    XTtotal(x)=0;
                    for h=1:BW(x)/2
                        XTeach(x,h)=0;
                    end
                    
                    blocking=1;
                    out=2;
                    break
                else
                    
                    out=1;
                    for k=2:length(ReqNums) %ReqNums(1)=0;
                        
                        ReqNumsMeM=[ReqNumsMeM ReqNums(k)];
                        
%                         [resource,upXT1,LXPR,NumSlots]=ff1XTupdate(resource,pathmemory(floor(ReqNums(k)),:),link,ReqNums(k),LXPR,NumSlots);
%                         XTeach(floor(ReqNums(k)),100*((ReqNums(k)-floor(ReqNums(k)))))=upXT1;
                    end
                end
                
            else 
                out =1;
            end
            
            if out==1
            XTeach(x,t)=XT;
            XTblock=0;
            EXTblock=0;
            break;
            end
        end

    end
    
    if out~=0
        break;
    end
    
    if time==7
        
        blocking=1;
        
        %When the request is blocked, if it is caused by xt, choose min
        %from XTallxt. If it is caused by res, choose min from XTallres.
        
        XTtotal(x)=0;
         for h=1:BW(x)/2
             XTeach(x,h)=0;
         end
        
        for m=1:(n-1)
            linkblock(2,a(m),b(m))=linkblock(2,a(m),b(m))+1;
        end
        
        
    end
end

if blocking==1
    break
end

if blocking==0&&t==BW(x)/2
    for k=2:length(ReqNumsMeM) %ReqNums(1)=0;
                          
           [resource,upXT1,LXPR,NumSlots]=ff1XTupdate(resource,pathmemory(floor(ReqNumsMeM(k)),:),link,ReqNumsMeM(k),LXPR,NumSlots);
            XTeach(round(floor(ReqNumsMeM(k))),round(100*((ReqNumsMeM(k)-floor(ReqNumsMeM(k))))))=upXT1;
    end
    
end



end


