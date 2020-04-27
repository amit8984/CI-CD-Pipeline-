use WAREHOUSE DEV_ENGINEER_WH;
use DATABASE EDM_CONFIRMED_DEV;
use schema EDM_CONFIRMED_DEV.SCRATCH;


create or replace Stream GETITEMMASTERSUPPLYCHAIN_FLAT_R_STREAM_Test on table GETITEMMASTERSUPPLYCHAIN_FLAT_COPY;

Insert into  GETITEMMASTERSUPPLYCHAIN_FLAT_COPY  select * from   EDM_REFINED_DEV.DW_R_PRODUCT.GETITEMMASTERSUPPLYCHAIN_FLAT limit 100;
 

create or replace task MasterSupplyChain_BIM_load_TASK_COPY
  warehouse = DEV_ENGINEER_WH
  schedule = '1 minute'
WHEN SYSTEM$STREAM_HAS_DATA('GETITEMMASTERSUPPLYCHAIN_FLAT_R_STREAM_Test')
AS
CALL sp_GetItemMasterSupplyChain_To_BIM_load_COPY();


alter MasterSupplyChain_BIM_load_TASK_COPY resume;
