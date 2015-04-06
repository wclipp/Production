create or replace 
FUNCTION      XXWMC_GET_CONV
(in_uom IN VARCHAR2, in_part_id IN NUMBER, out_conv OUT NUMBER)
RETURN NUMBER AS
  conv NUMBER;
BEGIN
  SELECT conversion_rate INTO conv
  FROM mtl_uom_conversions
  WHERE inventory_item_id = in_part_id
  AND UPPER(uom_code) = UPPER(in_uom);
  out_conv := conv;
  RETURN(0);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IF in_uom = '4CS' THEN
      out_conv := 0;
      RETURN(0);
    ELSE
      RETURN(SQLCODE);
    END IF;
  WHEN OTHERS THEN
    RETURN SQLCODE;
END;
 