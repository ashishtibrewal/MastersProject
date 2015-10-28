function count=isIn(array,num)
k=length(array);
count=0;
for j=1:k
    if array(j)==num
        count=1;
    end
end