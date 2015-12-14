function corecost = cost7_2(corecost,corenum)
% cost7_2 - Function to generate core cost for a 7 core fibre
%   Function parameters:
%     corecost - Matrix containing the core cost values
%     corenum - Value containing the current core number
%   Function return values:
%     corecost - Updated core cost value for a particular core

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
  if corenum==8
      for i=9:1:14
          corecost(i)=corecost(i)+1;
      end
  end

  if corenum==9
      corecost(10)=corecost(10)+1;
      corecost(8)=corecost(8)+1;
      corecost(14)=corecost(14)+1;
  end

  if corenum==10
      corecost(8)=corecost(8)+1;
      corecost(9)=corecost(9)+1;
      corecost(11)=corecost(11)+1;
  end

  if corenum==11
      corecost(8)=corecost(8)+1;
      corecost(10)=corecost(10)+1;
      corecost(12)=corecost(12)+1;
  end

  if corenum==12
      corecost(8)=corecost(8)+1;
      corecost(11)=corecost(11)+1;
      corecost(13)=corecost(13)+1;
  end

  if corenum==13
      corecost(14)=corecost(14)+1;
      corecost(12)=corecost(12)+1;
      corecost(8)=corecost(8)+1;
  end

  if corenum==14
      corecost(8)=corecost(8)+1;
      corecost(9)=corecost(9)+1;
      corecost(13)=corecost(13)+1;
  end
  
end
