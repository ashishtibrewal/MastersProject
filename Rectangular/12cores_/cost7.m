function corecost=cost7(corecost,corenum)

corecost(corenum)=inf;

if corenum==1
    
    corecost(2)=corecost(2)+1;
    corecost(8)=corecost(8)+1;
    corecost(7)=corecost(7)+0.5;
end

if corenum==2
    corecost(1)=corecost(1)+1;
    corecost(3)=corecost(3)+1;
    corecost(8)=corecost(8)+0.5;
    corecost(6)=corecost(6)+0.5;
    corecost(7)=corecost(7)+1;
end

if corenum==3
    corecost(6)=corecost(6)+1;
    corecost(2)=corecost(2)+1;
    corecost(4)=corecost(4)+1;
    corecost(5)=corecost(5)+0.5;
    corecost(7)=corecost(7)+0.5;
end

if corenum==4
    corecost(6)=corecost(6)+0.4;
    corecost(3)=corecost(3)+1;
    corecost(5)=corecost(5)+1;
    corecost(1)=corecost(1)+1;
end

if corenum==5
    corecost(3)=corecost(3)+0.5;
    corecost(4)=corecost(4)+1;
    corecost(6)=corecost(6)+1;
end

if corenum==6
    corecost(4)=corecost(4)+0.5;
    corecost(2)=corecost(2)+0.5;
    corecost(3)=corecost(3)+1;
    corecost(5)=corecost(5)+1;
    corecost(7)=corecost(7)+1;
end

if corenum==7
    corecost(3)=corecost(3)+0.5;
    corecost(2)=corecost(2)+1;
    corecost(6)=corecost(6)+1;
    corecost(1)=corecost(1)+0.5;
    corecost(8)=corecost(8)+1;
end
if corenum==8
    corecost(1)=corecost(1)+1;
    corecost(2)=corecost(2)+0.5;
    corecost(7)=corecost(7)+1;
end
