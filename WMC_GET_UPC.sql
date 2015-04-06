create or replace 
function WMC_GET_UPC(myuom in varchar2,
       inPart in varchar2, outPartID out number, outUPC out varchar2,
       outDesc out varchar2, outFinish out varchar2)
    return NUMBER
is
    wholeupc    	varchar2(14);
    uom_code 		varchar2(1);
    v_sum0		Number ;
    v_odd_sum		Number ;
    v_even_sum		Number ;
    i          		Number;
    v_mod0		Number ;
    outupcno		VARCHAR(11);
    outchkdigit		VARCHAR(1);
    outcust_code	VARCHAR(1);
begin
    select
        inventory_item_id,
	substr(msi.attribute1,1,11) upcno,
        substr(msi.attribute2,1,1) chkdigit,
	NVL(substr(msi.attribute3,1,25), 'N/A') description,
	NVL(substr(msi.attribute4,1,20), 'N/A') finish,
        substr(msi.attribute15,1,1) cust_code
    into outPartID, outupcno, outchkdigit, outDesc, outFinish, outcust_code
    from
        mtl_system_items msi
    where
        msi.organization_id = 102
        and msi.segment1 = upper(inPart);
    if upper(myuom) <> 'RETAIL' and upper(myuom) <> 'CARTON'
         and upper(myuom) <> 'CASE' and upper(myuom) <> 'CASE4' then
         return (110);
    end if;
    if outupcno is null then
       return (120);
    end if;
    if upper(myuom) = 'RETAIL' then
       outUPC := outupcno || outchkdigit;
       return (0);
    end if;
    if upper(myuom) = 'CARTON' then
       uom_code := '2';
    elsif upper(myuom) = 'CASE4' then
       uom_code := '4';
    else
       uom_code := '3';
    end if;
    wholeupc := uom_code || outcust_code ||
       outupcno;
    if length(wholeupc) <> 13 then
       return(130);
    end if;
    v_odd_sum := 0;
    v_even_sum := 0;
    i := 0;
    while i < 13 LOOP
       i := i  + 1;
       if MOD(i,2) = 0 then
          v_even_sum := v_even_sum + to_number(substr(wholeupc,i,1));
       ELSE
          v_odd_sum := v_odd_sum + to_number(substr(wholeupc,i,1));
       end if;
    END LOOP;
    v_sum0 := 3 * v_odd_sum + v_even_sum;
    v_mod0 := MOD(v_sum0,10);
    if v_mod0 = 0 then
       outUPC := wholeupc || '0';
    ELSE
       outUPC := wholeupc || to_char(10 - v_mod0);
    END IF;
    return (0);
exception
  when NO_DATA_FOUND then
     return SQLCODE;
  when others then
     return SQLCODE;
END;
 