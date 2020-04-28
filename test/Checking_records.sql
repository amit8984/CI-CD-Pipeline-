
use WAREHOUSE DEV_ENGINEER_WH;
use DATABASE EDM_CONFIRMED_DEV;
use schema EDM_CONFIRMED_DEV.SCRATCH;

select 
    case when cnt1 = cnt2 then True else false end as Result
    from 
    (
       select 
        count(distinct(buyer_id)) as cnt1, count(distinct(buyerid)) as cnt2
            from Buyer,edm_refined_dev.dw_r_product.GetItemMasterSupplyChain_FLAT_wrk
      
    );
