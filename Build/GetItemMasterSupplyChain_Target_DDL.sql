//***********************************
// Choose warehouse,database and schema 
//***********************************

//selecting warehouse,database and schema
use WAREHOUSE DEV_ENGINEER_WH;
use DATABASE EDM_CONFIRMED_DEV;
use schema EDM_CONFIRMED_DEV.SCRATCH;



//***********************************
// Create Target Tables 
//***********************************
CREATE OR REPLACE TABLE Buyer
(
 Buyer_Id              VARCHAR  NOT NULL ,
 DW_First_Effective_Dt  DATE  NOT NULL ,
 DW_Last_Effective_Dt  DATE  NOT NULL ,
 Buyer_Nm              VARCHAR  ,
 Facility_Id           VARCHAR  ,
 Buyer_Phone_Nbr       VARCHAR  ,
 Buyer_Email_Id        VARCHAR  ,
 DW_CREATE_TS          TIMESTAMP  ,
 DW_LAST_UPDATE_TS     TIMESTAMP  ,
 DW_LOGICAL_DELETE_IND  BOOLEAN  ,
 DW_SOURCE_CREATE_NM   VARCHAR(255)  ,
 DW_SOURCE_UPDATE_NM   VARCHAR(255)  ,
 DW_CURRENT_VERSION_IND  BOOLEAN  
);

ALTER TABLE Buyer
 ADD CONSTRAINT XPKBuyer PRIMARY KEY (Buyer_Id, DW_First_Effective_Dt, DW_Last_Effective_Dt);
 
