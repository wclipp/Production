create or replace 
function xxwmc_convert_to_number(p_number in varchar2) return number is 
begin
  return to_number(p_number);
exception 
   when others then
  return null; 
end xxwmc_convert_to_number;

 