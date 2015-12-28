function corecost=cost7(corecost,corenum)
% Function of evaluate the corecost. Core cost for a specific core is equal
% to the sum of the corecosts of all it's neighbouring cores.
corecost(corenum)=inf;

if corenum==1
    for i=2:1:7
        corecost(i)=corecost(i)+1;
    end
end

if corenum==2
    corecost(1)=corecost(1)+1;
    corecost(3)=corecost(3)+1;
    corecost(7)=corecost(7)+1;
end

if corenum==3
    corecost(1)=corecost(1)+1;
    corecost(2)=corecost(2)+1;
    corecost(4)=corecost(4)+1;
end

if corenum==4
    corecost(1)=corecost(1)+1;
    corecost(3)=corecost(3)+1;
    corecost(5)=corecost(5)+1;
end

if corenum==5
    corecost(1)=corecost(1)+1;
    corecost(4)=corecost(4)+1;
    corecost(6)=corecost(6)+1;
end

if corenum==6
    corecost(1)=corecost(1)+1;
    corecost(5)=corecost(5)+1;
    corecost(7)=corecost(7)+1;
end

if corenum==7
    corecost(1)=corecost(1)+1;
    corecost(2)=corecost(2)+1;
    corecost(6)=corecost(6)+1;
end
