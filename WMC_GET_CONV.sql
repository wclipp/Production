create or replace 
function WMC_GET_CONV(myuom in varchar2,
    inPartID in number, outConv out number)
    return NUMBER
is
    Conv	number;
begin
    select conversion_rate
    into Conv
    from mtl_uom_conversions
    where inventory_item_id = inPartID
    and uom_code = myuom;
    outConv := Conv;
    return 0;
exception
  when NO_DATA_FOUND then
     if myuom = '4CS' then
        outConv := 0;
        return 0;
     else
       return SQLCODE;
     end if;
  when others then
     return SQLCODE;
END;
 