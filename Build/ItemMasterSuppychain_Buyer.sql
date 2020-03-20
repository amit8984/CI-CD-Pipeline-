
//***********************************
// Choose warehouse,database and schema 
//***********************************

//selecting warehouse,database and schema
use WAREHOUSE DEV_ENGINEER_WH;
use DATABASE EDM_CONFIRMED_DEV;
use schema EDM_CONFIRMED_DEV.SCRATCH;

 CREATE OR REPLACE PROCEDURE sp_GetItemMasterSupplyChain_To_BIM_load_Buyer(src_wrk_tbl varchar,cnf_db varchar,cnf_schema varchar,wrk_schema varchar)
     RETURNS STRING
    LANGUAGE JAVASCRIPT
    AS 
    $$ 
	// **************	Load for Buyer table BEGIN *****************            
	// Variables specific to Target table declaration
    var src_wrk_tbl = SRC_WRK_TBL;
    var cnf_db = CNF_DB;
    var cnf_schema = CNF_SCHEMA;
    var wrk_schema = WRK_SCHEMA;
    var tgt_wrk_tbl = cnf_db + "." + wrk_schema + ".BUYER_WRK";
    var tgt_tbl = cnf_db +"."+ cnf_schema +".BUYER";

 // identify  if the columns have changed between Target table and changed dataset and create a work table specific to the BIM table.
                var sql_command = `CREATE OR REPLACE TABLE ` + tgt_wrk_tbl + ` as 
                  SELECT                           
                                 src.Buyer_Id
                                ,src.Buyer_Nm
                                ,src.Facility_Id
                                ,src.Buyer_Phone_Nbr
                                ,src.Buyer_Email_Id
                                ,src.BODNm
                                ,src.DW_Logical_delete_ind
                                ,CASE WHEN tgt.Buyer_Id is NULL then 'I' ELSE 'U' END as DML_Type
                                ,CASE WHEN DW_First_Effective_dt < CURRENT_DATE or DW_FIRST_EFFECTIVE_DT is  Null  THEN 0 Else 1 END as Sameday_chg_ind
                                FROM (
                                SELECT DISTINCT 
                                  BUYERID as  Buyer_Id                              
                                 ,BuyerNm as Buyer_Nm
                                 , FacilityId as Facility_Id
                                 , BuyerPhoneNbr as Buyer_Phone_Nbr
                                 ,BuyerEmailId as Buyer_Email_Id
                                 ,CASE WHEN upper(ActionTypeCd) = 'DELETE' THEN TRUE ELSE FALSE END as DW_Logical_delete_ind
                                 ,BODNm
                                FROM  ` + src_wrk_tbl +`
                                WHERE  BuyerId is not null 
                              
                                ) as src
                                LEFT JOIN
                                (
                                 SELECT  Buyer_Id
                                        ,Buyer_Nm
                                        ,Facility_Id
                                        ,Buyer_Phone_Nbr
                                        ,Buyer_Email_Id
                                        ,DW_Logical_delete_ind
                                        ,DW_First_Effective_dt
                                       FROM  ` + tgt_tbl + `
                                 WHERE DW_CURRENT_VERSION_IND = TRUE
                                 )  as tgt on src.Buyer_Id = tgt.Buyer_Id `;
                                              
                try {
        snowflake.execute (
            {sqlText: sql_command  }
            );
        }
    catch (err)  {
        return "Creation of Buyer work table "+ tgt_wrk_tbl +" Failed with error: " + err;   // Return a error message.
        }
        
       
                //SCD Type2 transaction begins
    var sql_begin = "BEGIN"
                var sql_updates = `// Processing Updates of Type 2 SCD
                    UPDATE ` + tgt_tbl + ` as tgt
                             SET    DW_Last_Effective_dt = CURRENT_DATE 
                         ,DW_CURRENT_VERSION_IND = FALSE  
                         ,DW_LAST_UPDATE_TS = TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP)
                         ,DW_SOURCE_UPDATE_NM = BODNm
                    FROM   (SELECT Buyer_Id
                            ,Buyer_Nm
                            ,Facility_Id
                            ,Buyer_Phone_Nbr
                            ,Buyer_Email_Id
                            ,BODNm
                            FROM   `+ tgt_wrk_tbl +`
                            WHERE DML_Type = 'U'
                            AND
                            Sameday_chg_ind = 0
                            ) src
                    WHERE tgt.Buyer_Id = src.Buyer_Id                   
                    AND     tgt.DW_CURRENT_VERSION_IND = TRUE`;
                    
    

   var sql_sameday = `// Processing Sameday updates
    UPDATE ` + tgt_tbl + ` as tgt
    SET                                    
                                 Buyer_Nm = src.Buyer_Nm   
                                ,Facility_Id=src.Facility_Id
                                ,Buyer_Phone_Nbr=src.Buyer_Phone_Nbr
                                ,Buyer_Email_Id= src.Buyer_Email_Id
                                ,DW_Logical_delete_ind = src.DW_Logical_delete_ind
                                ,DW_LAST_UPDATE_TS = TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP)
                                ,DW_SOURCE_UPDATE_NM = BODNm
    FROM   (              SELECT   Buyer_Id
                                ,Buyer_Nm
                                ,Facility_Id
                                ,Buyer_Phone_Nbr
                                ,Buyer_Email_Id
                                ,DW_Logical_delete_ind
                                ,BODNm
                        FROM  `+ tgt_wrk_tbl +`   
                        WHERE DML_Type = 'U'
                        AND     Sameday_chg_ind = 1
                                    ) src
    WHERE tgt.Buyer_Id = src.Buyer_Id
    AND     tgt.DW_CURRENT_VERSION_IND = TRUE `;

 

// Processing Inserts
    var sql_inserts = `INSERT INTO ` + tgt_tbl + `
(Buyer_Id
,Buyer_Nm
,Facility_Id
,Buyer_Phone_Nbr
,Buyer_Email_Id
,DW_First_Effective_Dt 
,DW_Last_Effective_Dt
,DW_LAST_UPDATE_TS
,DW_CREATE_TS          
,DW_LOGICAL_DELETE_IND  
,DW_SOURCE_CREATE_NM   
,DW_SOURCE_UPDATE_NM
,DW_CURRENT_VERSION_IND

)
SELECT   
         Buyer_Id
        ,Buyer_Nm
        ,Facility_Id
        ,Buyer_Phone_Nbr
        ,Buyer_Email_Id
        ,CURRENT_DATE + 1
        ,'31-DEC-9999'
        ,TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP)
        ,TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP)
        ,DW_Logical_delete_ind
        ,BODNm
        ,BODNm
        ,TRUE
        FROM   `+ tgt_wrk_tbl +`
        WHERE Sameday_chg_ind = 0`; 
        
   
   
   var sql_commit = "COMMIT"
    var sql_rollback = "ROLLBACK"
                try {
        snowflake.execute (
            {sqlText: sql_begin  }
            );
        snowflake.execute (
            {sqlText: sql_updates  }
            );
        snowflake.execute (
            {sqlText: sql_sameday  }
            );
        snowflake.execute (
            {sqlText: sql_inserts  }
            );
        snowflake.execute (
            {sqlText: sql_commit  }
            );    
        }
    catch (err)  {
        snowflake.execute (
            {sqlText: sql_rollback  }
            );
       return "Loading of Buyer table "+ tgt_tbl + " Failed with error: " + err;   // Return a error message.
        }
                // **************        Load for Buyer table ENDs *****************
                
                         
    $$;

