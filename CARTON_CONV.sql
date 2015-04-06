create or replace 
function carton_conv (in_uom_class    IN varchar2, in_item_id      IN   number,  in_shipped_qty  IN number)
            return number
AS
    lv_retail_rate   number;
    lv_carton_rate  number;
    ret_value        integer;


   cursor retail_uom_curs is
      select conversion_rate
      from mtl_uom_conversions
      where uom_class = in_uom_class
      and   uom_code = 'RTL'
      and   inventory_item_id = in_item_id;

   cursor carton_uom_curs is
      select conversion_rate
      from mtl_uom_conversions
      where uom_class = in_uom_class
      and   uom_code = 'CTN'
      and   inventory_item_id = in_item_id;


begin

   OPEN retail_uom_curs;
   FETCH retail_uom_curs into lv_retail_rate;
   if retail_uom_curs%NOTFOUND then
      lv_retail_rate := -1;
   end if;
   CLOSE retail_uom_curs;
--DBMS_OUTPUT.PUT_LINE('lv_retail_rate  '||lv_retail_rate);
   OPEN carton_uom_curs;
   FETCH carton_uom_curs into lv_carton_rate;
   if carton_uom_curs%NOTFOUND then
      lv_carton_rate := -1;
   end if;
   CLOSE carton_uom_curs;
--DBMS_OUTPUT.PUT_LINE('lv_carton_rate  '||lv_carton_rate);
    if (lv_carton_rate = -1) or (lv_retail_rate = -1) then
	ret_value := in_shipped_qty;
     else

        select in_shipped_qty *  ( lv_carton_rate / lv_retail_rate )
        into ret_value
        from dual;
--DBMS_OUTPUT.PUT_LINE('ret_value  '||ret_value);
    	if ret_value = 0 then
 	     ret_value := in_shipped_qty;
	    end if;
   end if;
return ret_value;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('..Failed to find required conversion data for item');

      return -1;
end carton_conv;

 