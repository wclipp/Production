create or replace 
Procedure PO_tildy_add ( errbuf OUT   VARCHAR2
                                          ,retcode OUT   VARCHAR2
                                          ,p_cust_po IN   VARCHAR2) AS

l_oraerr          NUMBER;          -- oracle error number
l_oraerrmsg       VARCHAR2 (100);  -- oracle error message

CURSOR c_get_po_header_info IS
select t.rowid, t.header_id, t.orig_sys_document_ref, t.cust_po_number
from ont.oe_order_headers_all t
where t.cust_po_number = p_cust_po;


BEGIN

FOR c_get_po_header_info_data IN c_get_po_header_info LOOP

UPDATE ont.oe_order_headers_all
SET orig_sys_document_ref = c_get_po_header_info_data.orig_sys_document_ref||'X',
    cust_po_number = c_get_po_header_info_data.cust_po_number||'X'
WHERE rowid     = c_get_po_header_info_data.rowid
AND   header_id = c_get_po_header_info_data.header_id;


UPDATE ont.oe_order_lines_all
SET cust_po_number = c_get_po_header_info_data.cust_po_number||'X'
WHERE  header_id = c_get_po_header_info_data.header_id;

END LOOP;
COMMIT;

 EXCEPTION
WHEN OTHERS THEN
      l_oraerr := SQLCODE;
      l_oraerrmsg := SUBSTR(SQLERRM, 1, 100);
      errbuf := l_oraerrmsg;
      retcode := l_oraerr;
      dbms_output.put_line (sysdate || 'ERROR: ' || l_oraerr || ' ' || l_oraerrmsg);
END PO_tildy_add;

 