function [distance,path]=dijkstra(link,sta,dst)

n=length(link);
lengs=zeros(1,n);
paths=zeros(1,n);
know=zeros(1,n);
know(1)=sta;
k=1;
for i=1:1:n
    if i~=sta
        lengs(i)=link(sta,i);
        if lengs(i)~=inf
            paths(i)=sta;
        end
    end
end
index=2;
for i=1:1:n
    if i~=sta
        min=inf;
        for j=1:1:n
            count=isIn(know,j);
            if count==0&&lengs(j)<=min
                k=j;
                min=lengs(j);
            end
        end
        know(index)=k;
        index=index+1;
        for j=1:1:n
            count=isIn(know,j);
            if count==0&&(lengs(k)+link(k,j))<lengs(j)
                lengs(j)=lengs(k)+link(k,j);
                paths(j)=k;
            end
        end
    end
end
distance=lengs(dst);
k=dst;
path=zeros(1,n);
path(n)=dst;
i=n-1;

if paths(k)==0
    paths(k)=sta;
end
while paths(k)~=sta
    k=paths(k);
    path(i)=k;
    i=i-1;
end

path(i)=sta;
path=path(path~=0);
%b=find(path==0);
%m=length(b);
%for i=1:m
   % path(b(i))=[];
%end

