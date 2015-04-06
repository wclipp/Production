create or replace 
FUNCTION      XXWMC_GET_UPC
(in_uom IN VARCHAR2, in_part IN VARCHAR2, out_part_id OUT NUMBER, out_upc OUT VARCHAR2, out_desc OUT VARCHAR2, out_finish OUT VARCHAR2)
RETURN NUMBER AS
  c_org_id      CONSTANT NUMBER(3) := '102';  
  v_odd_sum     NUMBER := 0;
  v_even_sum    NUMBER := 0;
  v_sum         NUMBER := 0;
  v_mod         NUMBER := 0;
  v_upc         VARCHAR2(14) := NULL;
  i             NUMBER := 0;
BEGIN
  IF UPPER(in_uom) NOT IN ('RETAIL','CARTON','CASE','CASE4') THEN
    RETURN(110);
  END IF;
  SELECT inventory_item_id,
         NVL(SUBSTR(attribute3,1,25),'N/A') part_desc,
         NVL(SUBSTR(attribute4,1,20),'N/A') part_finish
  INTO out_part_id, out_desc, out_finish
  FROM mtl_system_items
  WHERE organization_id = c_org_id
  AND UPPER(segment1) = UPPER(in_part);
  
  CASE
    WHEN UPPER(in_uom) = 'RETAIL' THEN
       SELECT SUBSTR(cross_reference,3,12) cross_reference
       INTO out_upc
       FROM mtl_cross_references_v
       WHERE inventory_item_id = out_part_id
       AND organization_id = c_org_id
       AND uom_code = 'RTL';
    WHEN UPPER(in_uom) = 'CTN' THEN
       SELECT cross_reference
       INTO out_upc
       FROM mtl_cross_references_v
       WHERE inventory_item_id = out_part_id
       AND organization_id = c_org_id
       AND uom_code = 'CTN';
    WHEN UPPER(in_uom) = 'CS' THEN
       SELECT cross_reference
       INTO out_upc
       FROM mtl_cross_references_v
       WHERE inventory_item_id = out_part_id
       AND organization_id = c_org_id
       AND uom_code = 'CS';
    WHEN UPPER(in_uom) = '4CS' THEN
       SELECT cross_reference
       INTO out_upc
       FROM mtl_cross_references_v
       WHERE inventory_item_id = out_part_id
       AND organization_id = c_org_id
       AND uom_code = '4CS';
    ELSE RETURN(110);
  END CASE;
  IF UPPER(in_uom) = 'RETAIL' THEN
    RETURN(0);
  END IF;
  IF LENGTH(out_upc) <> 14 THEN
    RETURN(130);
  END IF;
  v_upc := SUBSTR(out_upc,1,13);  --Strip off precalculated check digit
  FOR i IN 1..14 LOOP
    IF MOD(i,2) = 0 THEN
      v_even_sum := v_even_sum + TO_NUMBER(SUBSTR(v_upc,i,1));
    ELSE
      v_odd_sum := v_odd_sum + TO_NUMBER(SUBSTR(v_upc,i,1));
    END IF;
  END LOOP;
  v_sum := v_odd_sum * 3 + v_even_sum;
  v_mod := MOD(v_sum,10);
  IF v_mod = 0 THEN
    out_upc := v_upc || '0';
  ELSE
    out_upc := v_upc || TO_CHAR(10 - v_mod);
  END IF;
  RETURN(0);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN SQLCODE;
  WHEN OTHERS THEN
    RETURN SQLCODE;
END XXWMC_GET_UPC;
 