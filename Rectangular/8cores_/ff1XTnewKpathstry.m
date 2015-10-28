function [resource,blocking,XTtotal,LXPR,NumSlots,ReqNums,k_index,XTblock,EXTblock,linkblock,Bcauses]=ff1XTnewKpathstry(BW,kshortestpaths,link,resource,x,LXPR,NumSlots,linkblock,pathmemory,XTtotal)

k_index=0;
XTblock=0;
EXTblock=0;
Bcauses=zeros(1,3);
%Bcauses 0 for no blocking, 1 for blocked by XT 2 for blocked by resource
%for each path.
for y=1:length(kshortestpaths)
    
    
k_index=k_index+1;

seq=7;
blocking=0;
n=length(kshortestpaths{y});
a=zeros(1,n-1);
b=zeros(1,n-1);
h=5e-5;

%%%change
%requestNum is the number of request coming.


% XT=10*log10(3-3*exp(-4*h*distance*1000))-10*log10(1+3*exp(-4*h*distance*1000));
% XT1=10*log10(6-6*exp(-7*h*distance*1000))-10*log10(1+6*exp(-7*h*distance*1000));
for i=1:(n-1)
 a(i)=kshortestpaths{y}(i);
    b(i)=kshortestpaths{y}(i+1);
    if a(i)>b(i)
        k=a(i);
        a(i)=b(i);
        b(i)=k;
    end
end

for i=1:(n-1)
  
    linkblock(1,a(i),b(i))=linkblock(1,a(i),b(i))+1;
end



for time=1:7
    
    for i=1+(seq-1)*200:seq*200+1-BW
        
    out=0;
    sum=0;
    XT=0;
    upblocking=0;
    
        ReqNum=zeros(1,6);
        ReqNums=0;
        XTperLink=zeros(1,n-1);
    
    for k=i:i+BW-1
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
            num=count7(resource,row,col,BW,a(m),b(m));
            XTperLink(m)=(num-num*exp(-(num+1)*h*link(a(m),b(m))*1000))/(1+num*exp(-(num+1)*h*link(a(m),b(m))*1000));
            XT=XT+XTperLink(m);
            
        end
        XT2=10*log10(XT);
        
        if sum==(n-1)*BW&&XT2>-24
            XTblock=XTblock+1;
            Bcauses(k_index)=1;
        end

        if sum==(n-1)*BW&&XT2<=-24
            for k=i:i+BW-1
                column=mod(k,200);
                if column==0
                    column=200;
                end
                row=ceil(k/200);
                for j=1:n-1
                    %LXPR is the XT value in each link per request
                    %NumSlots shows the used slots with its request number
                    resource(row,column,a(j),b(j))=0;
                    LXPR(row,column,a(j),b(j))=XTperLink(j);
                    NumSlots(row,column,a(j),b(j))=x;
                    
                    if XTperLink(j)~=0
                        
                        ReqNum=find7(row,column,a(j),b(j),NumSlots);
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
            
              if length(ReqNums)~=1
                
                for k=2:length(ReqNums)%ReqNums(1)=0;
                    [resource,upblocking,NumSlots]=ff1XTcheck(resource,pathmemory(ReqNums(k),:),link,ReqNums(k),NumSlots);
                    % up_blocking=up_blocking+upblocking;
                    if upblocking~=0
                        break
                    end
                end
                
                if upblocking~=0
                    EXTblock=EXTblock+1;
                    Bcauses(k_index)=1;
                    %Then we need to convert resource of new request back to 1
                    %and add one block number
                    [resource,LXPR,NumSlots,linkblock]=ff1XTconvert(BW,kshortestpaths{y},resource,x,LXPR,NumSlots,linkblock);
                    
                else
                    
                    out=1;
                    for k=2:length(ReqNums) %ReqNums(1)=0;
                        
                        [resource,upXT1,LXPR,NumSlots]=ff1XTupdate(resource,pathmemory(ReqNums(k),:),link,ReqNums(k),LXPR,NumSlots);
                        XTtotal(ReqNums(k))=upXT1;
                    end
                end
                
            else 
                out =1;
              end
            
            if out==1
            XTblock=0;
            EXTblock=0;
            Bcauses(k_index)=0;
            XTtotal(x)=XT;
            break;
            end
        end

    
            if i==seq*200+1-BW
            seq=seq-1;
            end
    end
    
        
    if out==1
        break;
    end
    
    
    if time==7
        
        if Bcauses(k_index)==0
            Bcauses(k_index)=2;
        end

        
        blocking=1;
        
         XTtotal(x)=0;
         
       for m=1:(n-1)
  
    linkblock(2,a(m),b(m))=linkblock(2,a(m),b(m))+1;
       end    
        
    end
end

if blocking==0
    break;
end

end



