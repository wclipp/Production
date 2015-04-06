create or replace 
function xxwmcwsh_update_trip(p_trip_id number,p_waybill varchar2,
p_weight number,p_cartons number,p_load_no varchar2,p_pallet varchar2,p_carrier varchar2) return varchar2 is
l_Trip_Pub_Rec_Type wsh_trips_pub.Trip_Pub_Rec_Type;
l_msg_count     number:=0;
l_msg_data      varchar2(1000);
l_return_status varchar2(1000);
l_trip_id number:=0;
l_trip_name wsh_trips.name%type;
begin
l_Trip_Pub_Rec_Type.trip_id := p_trip_id;
l_Trip_Pub_Rec_Type.attribute1 := p_waybill;
l_Trip_Pub_Rec_Type.attribute2 := p_weight;
l_Trip_Pub_Rec_Type.attribute3 := p_cartons;
l_Trip_Pub_Rec_Type.attribute4 := p_pallet;
l_Trip_Pub_Rec_Type.attribute5 := p_carrier;
l_Trip_Pub_Rec_Type.routing_instructions := p_load_no;


        wsh_trips_pub.Create_Update_Trip
  ( p_api_version_number=>1.0,
    p_init_msg_list=> 'F',
    x_return_status=>l_return_status,
    x_msg_count=>l_msg_count,
    x_msg_data=>l_msg_data,
    p_action_code=>'UPDATE',
    p_trip_info=>l_Trip_Pub_Rec_Type,
    p_trip_name=>null,
    x_trip_id=>l_trip_id,
    x_trip_name=> l_trip_name);
commit;
return nvl(l_return_status,'E');
end;


 