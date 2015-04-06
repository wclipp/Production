create or replace 
PROCEDURE XXWMC_CABELAS_EDI_BACKORDER (errbuf   OUT   VARCHAR2
                               ,retcode  OUT   VARCHAR2
                               ,emailto  IN    VARCHAR2) as
/*
*********************************************************************************
****  This procedure looks up the Back ordered lines from the Cabelas EDI orders 
****  which are not fill kill                    ****                          
****  It then builds a text file, and an email   ****
****  and attaches the text file to the email and sends it to a distribution     ****
****   email list.                                                             ****
****  this is used to send out the report as attachements for excel                                                                           ****
****************************** HISTORY ********************************************
*** REV *** DATE **** Developer ***  *********** Notes ****************************
   001     02/27/2014  Narendra Pothula 
   002     03/19/2014  Narendra Pothula  Added onhand information and conversions
   003     03/26/2014  Narendra Pothula  Added Cabelas sub inventory ohnand qty
   004     06/03/2014  Narendra Pothula  Added Putaway Sub Inventory Onhand qty
**********************************************************************************
*/
l_oraerr                  NUMBER;          -- oracle error number
l_oraerrmsg               VARCHAR2 (32767);  -- oracle error message
f_err                     utl_file.file_type;
v_emailto                 varchar2(400);
v_detail_string1          VARCHAR2(32767);
v_header_string1          VARCHAR2(1000);
v_data_cust_name          VARCHAR2(50);
v_data_po_num             VARCHAR2(20);
v_data_sales_order_num    VARCHAR2(15);
v_data_line_number        Number;
v_data_item               VARCHAR2(20);
v_data_order_qty          Number;
v_data_order_uom          Varchar2(10);
v_data_ordered_date       DATE;
v_data_sche_ship_date     DATE;
v_data_last_update_date   DATE;
v_data_forecast_date      VARCHAR2(20);
v_data_user_name          VARCHAR2(20);
v_data_status             VARCHAR2(1);
v_data_qty_ctn            NUMBER;
v_data_stockroom	  NUMBER;
v_data_warehouse	  NUMBER;
v_data_race     	  NUMBER;
v_data_cabelas            NUMBER;
v_data_put_away           NUMBER;
v_smtp_server             varchar2(25) := 'localhost';
v_smtp_server_port        number       := 25;
crlf                      varchar2(10)  := chr(10);
mesg                      varchar2(32767);
conn                      UTL_SMTP.CONNECTION;
mesg_len                  number;
to_names                  varchar2(32767);
v_directory_name          varchar2(100);
v_file_name               varchar2(100);
type varchar2_table is table of varchar2(200) index by binary_integer;
file_array                varchar2_table;
i                         binary_integer;
v_file_handle             utl_file.file_type;
v_slash_pos               number;
v_line                    varchar2(1000);
mesg_too_long             exception;
invalid_path              exception;
mesg_length_exceeded      boolean := false;
max_size                  number  := 9999999999;
v_file_title              varchar2(50);
v_deliverydate            Date := sysdate;
debug                     number := 0;
-- Custom Error Logging -- changes for Ver 002
v_loc                     number := '0';  -- initialized Error loc
v_module                  varchar2(50) := 'XXWMC_CABELAS_BACK_ORDER_report';
v_count                   number;
--separate with commas or chr(9) tab???
--v_deliverydate := '28-AUG-08';
CURSOR c_list IS
select   SUBSTRB (hp.party_name, 1, 20) customer_name,
         oha.order_number,
         oha.cust_po_number ,
	 oha.ordered_date ,
         ola.ordered_quantity,
         ola.order_quantity_uom,
         ola.schedule_ship_date,
         ola.line_number,
         wdd.released_status,
         wdd.last_update_date,
         wdd.last_updated_by,
         ola.tp_attribute1,
         msib.segment1 ,
         MSIB.INVENTORY_ITEM_ID,
         (SELECT SUM(TRANSACTION_QUANTITY)  FROM MTL_ONHAND_QUANTITIES WHERE ORGANIZATION_ID = 102 AND  INVENTORY_ITEM_ID = msib.INVENTORY_ITEM_ID    AND SUBINVENTORY_CODE = 'STOCKROOM' ) STOCKROOM,
         (SELECT SUM(TRANSACTION_QUANTITY)  FROM MTL_ONHAND_QUANTITIES WHERE ORGANIZATION_ID = 102 AND  INVENTORY_ITEM_ID = msib.INVENTORY_ITEM_ID    AND SUBINVENTORY_CODE = 'WAREHOUSE' ) WAREHOUSE,
         (SELECT SUM(TRANSACTION_QUANTITY)  FROM MTL_ONHAND_QUANTITIES WHERE ORGANIZATION_ID = 102 AND  INVENTORY_ITEM_ID = msib.INVENTORY_ITEM_ID    AND SUBINVENTORY_CODE = 'RACE' ) RACE,
         (SELECT SUM(TRANSACTION_QUANTITY)  FROM MTL_ONHAND_QUANTITIES WHERE ORGANIZATION_ID = 102 AND  INVENTORY_ITEM_ID = msib.INVENTORY_ITEM_ID    AND SUBINVENTORY_CODE = 'CABELAS' ) CABELAS,
         (SELECT SUM(TRANSACTION_QUANTITY)  FROM MTL_ONHAND_QUANTITIES WHERE ORGANIZATION_ID = 102 AND  INVENTORY_ITEM_ID = msib.INVENTORY_ITEM_ID    AND SUBINVENTORY_CODE = 'PUT-AWAY' ) PUT_AWAY,         
         (SELECT conversion_rate   FROM mtl_uom_conversions WHERE uom_class = 'Quantity' AND uom_code = 'RTL'  AND inventory_item_id = msib.INVENTORY_ITEM_ID) Retail_rate,
         (SELECT conversion_rate   FROM mtl_uom_conversions WHERE uom_class = 'Quantity' AND uom_code = 'CTN'  AND inventory_item_id = msib.INVENTORY_ITEM_ID) carton_rate,
         fnd.user_name
from
oe_order_headers_all oha,
oe_order_lines_all ola,
hz_parties hp,
hz_cust_accounts hca,
wsh_delivery_details wdd,
mtl_system_items_b msib,
fnd_user fnd
where oha.header_id =ola.header_id
  and oha.attribute2 ='N'
  and  oha.sold_to_org_id = hca.cust_account_id
  and  oha.open_flag      = 'Y'
  and  oha.booked_flag    = 'Y'
  and  oha.cancelled_flag = 'N'
  and  ola.open_flag = 'Y'
  and  hca.party_id       = hp.party_id
  and hp.party_id = 7068
  and  oha.header_id = wdd.source_header_id
  and  ola.line_id = wdd.source_line_id
  and  wdd.released_status='B'
  and wdd.inventory_item_id = msib.inventory_item_id 
  and wdd.organization_id = msib.organization_id
  and wdd.last_updated_by =fnd.user_id
  order by oha.order_number asc ;
BEGIN
      IF emailto is null THEN   -- default for testing
         v_emailto:='npothula@mail.eagleclaw.com';
      ELSE
         v_emailto := emailto;
      END IF;
      SELECT 'CABELAS BACK ORDER LINES '||TO_CHAR(SYSDATE,'MMDDYY')||'.csv'
        INTO v_file_title
        FROM dual;
      -- open file for this report for today
      f_err := UTL_FILE.FOPEN ('/ora1/app/prodcomn/temp',v_file_title,'w',32760); --build todays file
      file_array(1) := '/ora1/app/prodcomn/temp/'||v_file_title;
      v_header_string1   := 'CUSTOMER NAME'||','||'ORDER NUMBER'||','||'PO NUMBER'||','||'ORDERED DATE'||','||'SCHE SHIP DATE'||','||'ITEM NUMBER'||','||'QTY in RTL'||','||'UOM'||','||'QTY in CTNS'||','||'STOCKROOM'||','||'WAREHOSE'||','||'RACE'||','||'CABELAS'||','||'PUT_AWAY'||','||'FORECAST DATE';
      utl_file.put_line(f_err,v_header_string1);
      FOR c_list_data IN c_list LOOP    --detail loop, write to file               
 	       v_data_cust_name             := c_list_data.customer_name;
	       v_data_po_num                := c_list_data.cust_po_number;
	       v_data_sales_order_num       := c_list_data.order_number;
	       v_data_line_number           := c_list_data.line_number;
	       v_data_item                  := c_list_data.segment1; 
	       v_data_order_qty             := c_list_data.ordered_quantity;
	       v_data_order_uom             := c_list_data.order_quantity_uom;
	       v_data_ordered_date          := c_list_data.ordered_date;
	       v_data_sche_ship_date        := c_list_data.schedule_ship_date;
	       v_data_last_update_date      := c_list_data.last_update_date;
	       v_data_forecast_date         := c_list_data.tp_attribute1;
	       v_data_user_name             := c_list_data.user_name;
	       v_data_status                := c_list_data.released_status;
	       v_data_qty_ctn               := c_list_data.ordered_quantity * c_list_data.Retail_rate / c_list_data.carton_rate ;
	       v_data_stockroom             := c_list_data.stockroom;
	       v_data_warehouse             := c_list_data.warehouse;
	       v_data_race                  := c_list_data.race;
	       v_data_cabelas               := c_list_data.cabelas;
               v_data_put_away              := c_list_data.put_away;
               v_detail_string1             := v_data_cust_name||','||v_data_sales_order_num||','||v_data_po_num||','||v_data_ordered_date||','||v_data_sche_ship_date||','||v_data_item||','||v_data_order_qty||','||v_data_order_uom||','||v_data_qty_ctn||','||v_data_stockroom||','||v_data_warehouse||','||v_data_race||','||v_data_cabelas||','||v_data_put_away||','||v_data_forecast_date;
             --  v_detail_string1           := v_data_cust_name||','||v_data_po_num||','||v_data_sales_order_num||','||v_data_line_number||','||v_data_item||','||v_data_order_qty||','||v_data_order_uom||','||v_data_sche_ship_date||','||v_data_last_update_date||','||v_data_user_name||','||v_data_status;
          utl_file.put_line(f_err,v_detail_string1);
      END LOOP;  --c_list
      -- Close the open files.
      utl_file.fclose(f_err); -- Close file
-- Count the records and if exists then send the email 
	select   count(*)
	into     v_count
	from
	oe_order_headers_all oha,
	oe_order_lines_all ola,
	hz_parties hp,
	hz_cust_accounts hca,
	wsh_delivery_details wdd,
	mtl_system_items_b msib,
	fnd_user fnd
	where oha.header_id =ola.header_id
	  and oha.attribute2 = 'N'
	  and  oha.sold_to_org_id = hca.cust_account_id
	  and  oha.open_flag      = 'Y'
	  and  oha.booked_flag    = 'Y'
	  and  oha.cancelled_flag = 'N'
	  and  ola.open_flag = 'Y'
	  and  hca.party_id       = hp.party_id
          and hp.party_id = 7068
	  and  oha.header_id = wdd.source_header_id
	  and  ola.line_id = wdd.source_line_id
	  and  wdd.released_status='B'
	  and wdd.inventory_item_id = msib.inventory_item_id 
	  and wdd.organization_id = msib.organization_id
	  and wdd.last_updated_by =fnd.user_id
	  order by oha.order_number asc ;
  If v_count < 1 Then 
   null;
  ELSE
      -- Now mail the files --
      -- Open the SMTP connection ...
      conn:= utl_smtp.open_connection( v_smtp_server, v_smtp_server_port );
         -- Initial handshaking ...
         -- -------------------
      UTL_SMTP.HELO( CONN, V_SMTP_SERVER );
      utl_smtp.mail( conn, 'applprod@shark-1.eagleclaw.com' ); -- transmitting user account
      utl_smtp.rcpt( conn, v_emailto );
      utl_smtp.open_data ( conn );
   -- build the start of the mail message ...
   -- -----------------------------------
      mesg:= 'Date: ' || TO_CHAR( SYSDATE, 'dd Mon yy hh24:mi:ss' ) || crlf ||
             'From: Oracle.Cabelas_Report'|| crlf ||
             'MIME-Version: 1.0' || crlf ||
             'Subject:  Report For ' ||v_file_title|| crlf ||
             'To: ' || emailto || crlf ||
             'Content-Type: multipart/mixed; boundary="DMW.Boundary.605592468"' || crlf ||
             '--DMW.Boundary.605592468' || crlf ||
             'Content-Type: text/plain' || crlf ||
             'Content-Transfer-Encoding: 7bit' || crlf ||'' || crlf ||
             'Open the attached file with Excel' || crlf || crlf ||
             '' || crlf ;
      mesg_len := length(mesg);
      utl_smtp.write_data ( conn, mesg );
      -- Append the files ...
      for i in  1..1 loop
             -- Exit if message length already exceeded ...
          exit when mesg_length_exceeded;
          -- If the filename has been supplied ...
          if file_array(i) is not null then
          IF file_array(i) = '/ora1/app/prodcomn/temp/'||v_file_title  THEN
             begin
             -- locate the final '/' or '\' in the pathname ...
             v_slash_pos := instr(file_array(i), '/', -1 );
             if v_slash_pos = 0 then
                v_slash_pos := instr(file_array(i), '\', -1 );
             end if;
             -- separate the filename from the directory name ...
             v_directory_name := substr(file_array(i), 1, v_slash_pos - 1 );
             v_file_name      := substr(file_array(i), v_slash_pos + 1 );
             -- generate the MIME boundary line ...
             utl_smtp.write_data(conn, '--DMW.Boundary.605592468' || crlf );
             utl_smtp.write_data(conn, 'Content-Type: application/octet-stream; name="' || v_file_name || '"' || crlf);
             utl_smtp.write_data(conn, 'Content-Transfer_Encoding: 8bit' || crlf);
             utl_smtp.write_data(conn, 'Content-Disposition: attachment; filename="' || v_file_name || '"' || crlf || '' || crlf);
             -- open the file ...
             v_file_handle := utl_file.fopen(v_directory_name, v_file_name, 'r' );
             -- and append the file contents to the end of the message ...
             loop
                 utl_file.get_line(v_file_handle, v_line);
                 if mesg_len + length(v_line) > max_size then
                    mesg := '*** truncated ***' || crlf;
                    utl_smtp.write_data ( conn, mesg );
                    mesg_length_exceeded := true;
                    raise mesg_too_long;
                 end if;
                 mesg := v_line || crlf;
                 utl_smtp.write_data ( conn, mesg );
                 mesg_len := mesg_len + length(mesg);
             end loop;
          exception
             when utl_file.invalid_path then
                 if debug > 0 then
                    dbms_output.put_line('Error in opening attachment '||
                                          file_array(i) );
                 end if;
             -- All other exceptions are ignored ....
             -- Ver 002 - catch EOF error
                WHEN NO_DATA_FOUND THEN
                  v_loc := 10;
                 -- INSERT INTO XXWMC_ERROR_LOGGER VALUES (SYSDATE,V_LOC,V_MODULE,'Oracle Error EOF-No Data Found - MsgLen '||mesg_len|| ' ERROR: ' || l_oraerr || ' '  || l_oraerrmsg);
                WHEN OTHERS THEN
                  v_loc := 20;
                  INSERT INTO XXWMC_ERROR_LOGGER VALUES (SYSDATE,V_LOC,V_MODULE,'Other Error using Utl_SMTP - MsgLen '||mesg_len|| ' ERROR: ' || l_oraerr || ' '  || l_oraerrmsg);
               --when others THEN null; -- change for ver 002
          end;
          mesg := crlf;
          utl_smtp.write_data ( conn, mesg );
          -- close the file ...
          utl_file.fclose(v_file_handle);
         end if;
        end if;
   end loop;
   -- append the final boundary line ...
   /* Ver 002.1- || '.' || crlf at end maybe causing 500 error - Note 806105.1 */
   mesg := crlf || '--DMW.Boundary.605592468--' || crlf || crlf ;  
   utl_smtp.write_data ( conn, mesg );
   utl_smtp.close_data( conn );
   utl_smtp.quit( conn );
  End if; 
EXCEPTION
WHEN OTHERS THEN
      l_oraerr := SQLCODE;
      l_oraerrmsg := SUBSTR(SQLERRM, 1, 100);
      errbuf := l_oraerrmsg;
      retcode := l_oraerr;
      dbms_output.put_line (sysdate || 'ERROR: ' || l_oraerr || ' ' || l_oraerrmsg);
      fnd_file.put_line(fnd_file.output, sysdate || 'ERROR: ' || l_oraerr || ' '  || l_oraerrmsg);
END XXWMC_CABELAS_EDI_BACKORDER;
