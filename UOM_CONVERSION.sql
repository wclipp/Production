create or replace 
function  UOM_CONVERSION(
			              in_from_uom_code   varchar2,
			   	      in_part            number,
			              in_to_uom_code   varchar2)
return number
is
lv_uom_class     VarChar2(30);
lv_conv_rate     number;
lv_conv_rate1    number;
lv_conv_rate2    number;
lv_uom_code      VarChar2(3);
cursor conv_curs is
select conversion_rate
from mtl_uom_conversions
where inventory_item_id = in_part
 and uom_code = lv_uom_code
 and uom_class = lv_uom_class;
begin
-- dbms_output.put_line('..Entering retail_to_carton() function');
-- dbms_output.put_line('....IN uom_code = '|| in_uom_code);
-- dbms_output.put_line('....IN part = '|| in_part);
-- lv_trace:= '..First uom class select';
If in_from_uom_code = in_to_uom_code then
  lv_conv_rate := 1;
Else
  select uom_class
  into lv_uom_class
  from mtl_units_of_measure
  where uom_code = in_from_uom_code;
  -- dbms_output.put_line('..UOM_CLASS = '||lv_uom_class);
    lv_uom_code := in_from_uom_code;
    OPEN conv_curs;
    FETCH conv_curs into lv_conv_rate1;
    if conv_curs%NOTFOUND then
      lv_conv_rate1 := 1;
    end if;
    CLOSE conv_curs;
    lv_uom_code := in_to_uom_code;
    OPEN conv_curs;
    FETCH conv_curs into lv_conv_rate2;
    if conv_curs%NOTFOUND then
      lv_conv_rate2 := 1;
    end if;
    CLOSE conv_curs;
    lv_conv_rate := lv_conv_rate1 / lv_conv_rate2;
End If;
return lv_conv_rate;
EXCEPTION
WHEN NO_DATA_FOUND
THEN
--  DBMS_OUTPUT.PUT_LINE('..Failed to find required conversion data');
--  DBMS_OUTPUT.PUT_LINE('..Failed during '|| lv_trace);
  return 1;
end uom_conversion;

 