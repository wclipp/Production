create or replace 
function  ctn_to_rtl(
			              in_uom_code   varchar2,
			   	      in_part       number,
				      in_qty        integer)
return integer
is
lv_uom_class     varchar2(10);
lv_carton_qty    integer;
lv_min_carton    integer;
lv_retail_rate   number;
lv_carton_rate  number;
lv_case_rate     number;
wrk_number       number(20,4);
ret_value        integer;
lv_trace   varchar2(50);
cursor retail_curs is
select conversion_rate
from mtl_uom_conversions
where inventory_item_id = in_part
 and uom_code = 'RTL'
 and uom_class = lv_uom_class;
cursor carton_curs is
select conversion_rate
from mtl_uom_conversions
where inventory_item_id = in_part
 and uom_code = 'CTN'
 and uom_class = lv_uom_class;
cursor case_curs is
select conversion_rate
from mtl_uom_conversions
where inventory_item_id = in_part
 and uom_code = 'CS'
 and uom_class = lv_uom_class;
begin
-- dbms_output.put_line('..Entering retail_to_carton() function');
-- dbms_output.put_line('....IN uom_code = '|| in_uom_code);
-- dbms_output.put_line('....IN part = '|| in_part);
lv_trace:= '..First uom class select';
select u.uom_class
into lv_uom_class
from mtl_units_of_measure      u
where in_uom_code = u.uom_code;
-- dbms_output.put_line('..UOM_CLASS = '||lv_uom_class);
OPEN retail_curs;
FETCH retail_curs into lv_retail_rate;
 if retail_curs%NOTFOUND then
       lv_retail_rate := -1;
 end if;
CLOSE retail_curs;
OPEN carton_curs;
FETCH carton_curs into lv_carton_rate;
 if carton_curs%NOTFOUND then
       lv_carton_rate := -1;
 end if;
CLOSE carton_curs;
if (lv_carton_rate = -1) or (lv_retail_rate = -1) then
  ret_value := 1;
else
-- dbms_output.put_line('....Primary UOM is Carton - Perform Conversion');
   select round((in_qty * lv_carton_rate / lv_retail_rate) + 0.4)
   into ret_value
   from dual;
end if;
-- dbms_output.put_line('Retail Rate ' || lv_retail_rate) ;
-- dbms_output.put_line('Carton Rate ' || lv_carton_rate) ;
-- dbms_output.put_line('..Exiting retail_to_carton() function');
return ret_value;
EXCEPTION
WHEN NO_DATA_FOUND
THEN
--  DBMS_OUTPUT.PUT_LINE('..Failed to find required conversion data');
--  DBMS_OUTPUT.PUT_LINE('..Failed during '|| lv_trace);
  return 1;
end ctn_to_rtl;

 