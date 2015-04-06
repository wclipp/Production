create or replace 
FUNCTION wmc_getitembyupc (p_inUPC IN VARCHAR2,
					     p_outPart OUT VARCHAR2)
    RETURN NUMBER
IS
   v_UPC VARCHAR2(11);
BEGIN
   /* Assumes receiving 11 digit Retail UPC value stored in mtl_system_items */
   p_outPart := 'Not Found';
   v_UPC := SUBSTR(p_inUPC,1,11);
   SELECT segment1 INTO p_outPart
   FROM mtl_system_items msi
   WHERE msi.attribute1 = v_UPC
   AND organization_id = 102
   AND attribute15 = '0';  /* NOT Customer Specific UPC */
   RETURN(0);
EXCEPTION
   WHEN NO_DATA_FOUND THEN RETURN SQLCODE;
   WHEN OTHERS THEN RETURN SQLCODE;
END;
 