
use WAREHOUSE DEV_ENGINEER_WH;
use DATABASE EDM_CONFIRMED_DEV;
use schema EDM_CONFIRMED_DEV.SCRATCH;


CREATE OR REPLACE PROCEDURE sp_GetItemMasterSupplyChain_To_BIM_load_COPY()
    RETURNS STRING
    LANGUAGE JAVASCRIPT
    AS 
    $$ 
	// Global Variable Declaration
	
    var cnf_db = "EDM_CONFIRMED_DEV";
    var wrk_schema = "SCRATCH";
    var cnf_schema = "SCRATCH";
    var ref_db = "EDM_REFINED_DEV";
    var ref_schema = "DW_R_PRODUCT";
	
	var src_wrk_tbl = ref_db + "." + ref_schema + ".GetItemMasterSupplyChain_FLAT_wrk";
	var src_tbl = cnf_db + "." + SCRATCH + ".GETITEMMASTERSUPPLYCHAIN_FLAT_R_STREAM_Test";
	var src_rerun_tbl = cnf_db + "." + wrk_schema + ".GETITEMMASTERSUPPLYCHAIN_Flat_Rerun";
	
	// check if rerun queue table exists otherwise create it
	var sql_crt_rerun_tbl = `CREATE TABLE IF NOT EXISTS `+ src_rerun_tbl +` DATA_RETENTION_TIME_IN_DAYS = 0 AS SELECT * FROM `+ src_tbl +` where 1=2 `;
	try {
        snowflake.execute (
            {sqlText: sql_crt_rerun_tbl  }
            );
        }
    catch (err)  {
        throw "Creation of rerun queue table "+ src_rerun_tbl +" Failed with error: " + err;   // Return a error message.
        }
	
	// persist stream data in work table for the current transaction, includes data from previous failed run
	var sql_crt_src_wrk_tbl = `create or replace table `+ src_wrk_tbl +` DATA_RETENTION_TIME_IN_DAYS = 0 as select * from `+ src_tbl +` 
								UNION ALL select * from `+ src_rerun_tbl;
    try {
        snowflake.execute (
            {sqlText: sql_crt_src_wrk_tbl  }
            );
        }
    catch (err)  {
        throw "Creation of Source Work table "+ src_wrk_tbl +" Failed with error: " + err;   // Return a error message.
        }
	
	// Empty the rerun queue table
	var sql_empty_rerun_tbl = `CREATE OR REPLACE TABLE `+ src_rerun_tbl +` DATA_RETENTION_TIME_IN_DAYS = 0 AS SELECT * FROM `+ src_tbl +` where 1=2 `;
	try {
        snowflake.execute (
            {sqlText: sql_empty_rerun_tbl  }
            );
        }
    catch (err)  {
        throw "Truncation of rerun queue table "+ src_rerun_tbl +" Failed with error: " + err;   // Return a error message.
        }
    
	// query to load rerun queue table when encountered a failure
	var sql_ins_rerun_tbl = `CREATE OR REPLACE TABLE `+ src_rerun_tbl+`  as SELECT * FROM `+ src_wrk_tbl+``;

	// function to facilitate child stored procedure executions	
	function execSubProc(sub_proc_nm, params) 
    {
		try {
			 ret_obj = snowflake.execute (
						{sqlText: "call " + sub_proc_nm + "("+ params +")"  }
						);
             ret_obj.next();
             ret_msg = ret_obj.getColumnValue(1);
             
			}
		catch (err)  {
			return "Error executing stored procedure "+ sub_proc_nm + "("+ params +")" + err;   // Return a error message.
			}
		return ret_msg;
	}
	
	var sub_proc_list = [
						'sp_GetItemMasterSupplyChain_To_BIM_load_Buyer'
						]
						
	for (index = 0; index < sub_proc_list.length; index++) 
	{
			sub_proc_nm = sub_proc_list[index];
			params = "'"+ src_wrk_tbl +"','"+ cnf_db +"','"+ cnf_schema +"','"+ wrk_schema + "'";
			return_msg = execSubProc(sub_proc_nm, params);
			if (return_msg)
			{
				snowflake.execute (
						{sqlText: sql_ins_rerun_tbl }
						);
				throw return_msg;
			}
	}
	$$;
	
	

