create or replace 
function asnchkdigit(mystring in varchar2)
   return number
is
mycheckdigit number(2);
    whole_asn    varchar2(19);
    v_sum0			Number ;
    v_odd_sum		Number ;
    v_even_sum		Number ;
    i          Number;
    v_mod0			Number ;
begin
    if length(mystring) <> 7 then
        return (-1);   -- the asn number may already have a check digit
    end if;
    whole_asn := '0000047708' || lpad(mystring,9,'0');
    v_odd_sum := 0;
    v_even_sum := 0;
    i := 0;
   while i < 19 LOOP
        i := i  + 1;
        if MOD(i,2) = 0 then
            v_even_sum := v_even_sum + to_number(substr(whole_asn,i,1));
         ELSE
            v_odd_sum := v_odd_sum + to_number(substr(whole_asn,i,1));
         end if;
     END LOOP;
     v_sum0 := 3 * v_odd_sum + v_even_sum;
     v_mod0 := MOD(v_sum0,10);
    if v_mod0 = 0 then
        return (0);
    ELSE
        return (10 - v_mod0);
    END IF;
END;

 