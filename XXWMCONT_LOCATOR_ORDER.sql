create or replace 
function xxwmcont_locator_order(v_inventory_item_id number,v_organization_id number,
							v_subinventory_code varchar2,v_locator_id number) return number is
v_picking_order apps.mtl_item_locations.picking_order%type;
begin
	begin
	select 	picking_order
	into	v_picking_order
	from	mtl_item_locations
	where	inventory_location_id = v_locator_id;
	exception
		when no_data_found then
			v_picking_order := null;
		when too_many_rows then
			v_picking_order := null;
		when others then
			v_picking_order := null;
	end;
	return v_picking_order;
end;

 