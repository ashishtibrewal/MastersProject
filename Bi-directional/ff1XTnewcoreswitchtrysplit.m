function [resource,blocking,XTtotal,LXPR,NumSlots,ReqNums,XTblock,EXTblock,linkblock,XTeach]=ff1XTnewcoreswitchtrysplit(BW,path,link,resource,x,LXPR,NumSlots,linkblock,pathmemory,XTtotal,XTeach)
XTblock=0;
EXTblock=0;
blocking=0;
n=length(path);
a=zeros(1,n-1);
b=zeros(1,n-1);
h=5e-5;



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
    
rowcs=zeros(1,n-1);
columncs=zeros(1,n-1);

%Find the minimum xt connection not matter it satisfies xt threshold

for ln=1:n-1 %linknumber
    corecost=zeros(1,14);
    corecost(7)=inf;
   corecost(8)=7;corecost(9)=7;corecost(10)=7;corecost(11)=7;corecost(12)=7;corecost(13)=7;corecost(14)=7;
    XTtemp=inf;
    
    a(ln)=path(ln);
    b(ln)=path(ln+1);
    if a(ln)>b(ln)
       k=a(ln);
        a(ln)=b(ln);
        b(ln)=k;
        corecost=zeros(1,14);
        corecost(14)=inf;
        corecost(1)=7;corecost(2)=7;corecost(3)=7;corecost(4)=7;corecost(5)=7;corecost(6)=7;corecost(7)=7;
        %corecost(2)=0.5;
        %4-6-2-13-9-11-8
       % corecost(7)=10;corecost(3)=10;corecost(5)=10;corecost(1)=10;corecost(14)=10;corecost(10)=10;corecost(12)=10;corecost(8)=6;corecost(9)=3;corecost(11)=4;corecost(2)=1;corecost(13)=1;
    end
    for time=1:randi([4,6])
        
        if time==1
            [~,corenum]=max(corecost);
        else
            [~,corenum]=min(corecost);
        end
        
        corecost=cost7_2(corecost,corenum);
        
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
                
                sum=sum+resource(row,column,a(ln),b(ln));
                
            end
            
            if sum==2
                
                col=mod(i,200);
                num=count7_2(resource,row,col,2,a(ln),b(ln));
                XTperLink(ln)=(num-num*exp(-(num+1)*h*link(a(ln),b(ln))*1000))/(1+num*exp(-(num+1)*h*link(a(ln),b(ln))*1000));
                

                if XTperLink(ln)==0
                    XTtemp=0;
                    rowcs(ln)=row;
                    columncs(ln)=col;
                    out=1;
                    break
                else
                    if XTperLink(ln)<XTtemp   %Ð¡ÓÚÎÞÇî
                        XTtemp=XTperLink(ln);
                        rowcs(ln)=row;
                        columncs(ln)=col;

                    end
                end

            end

        end

        if out==1
            break
        end

    end
    
    XTperLink(ln)=XTtemp;
    XT=XT+XTperLink(ln);

end

%Find the minimum XT slots
XT2=10*log10(XT);

if (any(XTperLink==inf)==1)||(any(rowcs==0)==1)||(any(columncs==0)==1)
    blocking=1;%Blocking by resource congestion.
    
     [resource,LXPR,NumSlots,linkblock]=ff1XTconvertDBswitchsplit(path,resource,x,LXPR,NumSlots,linkblock,t-1);

else
    if XT2>-24
        XTblock=1;
        blocking=1;%Blocking by resource congestion.
        [resource,LXPR,NumSlots,linkblock]=ff1XTconvertDBswitchsplit(path,resource,x,LXPR,NumSlots,linkblock,t-1);

    end
    
    if XT2<=-24
        
        for ln=1:n-1
            
        for j=1:2
            
            
                 resource(rowcs(ln),columncs(ln)+j-1,a(ln),b(ln))=0;
                LXPR(rowcs(ln),columncs(ln)+j-1,a(ln),b(ln))=XTperLink(ln);
                NumSlots(rowcs(ln),columncs(ln)+j-1,a(ln),b(ln))=x+0.01*t;
                
                if XTperLink(ln)~=0
                    
                    ReqNum=find7(rowcs(ln),columncs(ln)+j-1,a(ln),b(ln),NumSlots);
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
                [resource,upblocking,NumSlots]=ff1XTcheck(resource,pathmemory(floor(ReqNums(k)),:),link,ReqNums(k),NumSlots);
                % up_blocking=up_blocking+upblocking;
                if upblocking~=0
                    break
                end
            end
            
            if upblocking~=0
                EXTblock=1;
                XTblock=0;
                %Then we need to convert resource of new request back to 1
                %and add one block number
                [resource,LXPR,NumSlots,linkblock]=ff1XTconvertDBswitchsplit(path,resource,x,LXPR,NumSlots,linkblock,t);
                XTtotal(x)=0;
                blocking=1;
                for h=1:BW(x)/2
                    XTeach(x,h)=0;
                end
            else
                
                for k=2:length(ReqNums) %ReqNums(1)=0;
                    
                     ReqNumsMeM=[ReqNumsMeM ReqNums(k)];
                    
%                     [resource,upXT1,LXPR,NumSlots]=ff1XTupdate(resource,pathmemory(ReqNums(k),:),link,ReqNums(k),LXPR,NumSlots);
%                     XTtotal(ReqNums(k))=upXT1;
                end
                
                XTeach(x,t)=XT;
            end
        else
            XTeach(x,t)=XT;
        end
    end
end

if blocking~=1||t==BW(x)/2
        
        XTblock=0;
        EXTblock=0;
        for k=2:length(ReqNumsMeM) %ReqNums(1)=0;
                          
           [resource,upXT1,LXPR,NumSlots]=ff1XTupdate(resource,pathmemory(floor(ReqNumsMeM(k)),:),link,ReqNumsMeM(k),LXPR,NumSlots);
            XTeach(round(floor(ReqNumsMeM(k))),round(100*((ReqNumsMeM(k)-floor(ReqNumsMeM(k))))))=upXT1;
        end
end      
if blocking==1
    
     for h=1:BW(x)/2
         XTeach(x,h)=0;
     end
    XTtotal(x)=0;
    
    for m=1:(n-1)
        linkblock(2,a(m),b(m))=linkblock(2,a(m),b(m))+1;
    end
    
    break
end



end





