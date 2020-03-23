pipeline {
   agent any

   stages {
      stage('Build Stage') {
          
         steps {
            bat 'snowsql -c myconnection --config C:\\Users\\91827\\.snowsql\\config -f Build\\GetItemMasterSupplyChain_Target_DDL.sql'
            bat 'snowsql -c myconnection --config C:\\Users\\91827\\.snowsql\\config -f Build\\ItemMasterSuppychain_Buyer.sql'
            bat 'snowsql -c myconnection --config C:\\Users\\91827\\.snowsql\\config -f Build\\sp_GetItemMasterSupplyChain_To_BIM_load.sql'

         }
         
      }
      
      stage('Test Stage') {
          
         steps {
            bat 'snowsql -c myconnection --config C:\\Users\\91827\\.snowsql\\config -f test\\Checking_records.sql'
            bat 'snowsql -c myconnection --config C:\\Users\\91827\\.snowsql\\config -f test\\counting_records.sql'
            
         }
         
      }
      
   }
  
}
