pipeline {
   agent any

   stages {
      stage('Build Stage') {
          
         steps {
            bat 'snowsql -c myconnection --config C:\\Users\\91827\\.snowsql\\config -f Build\GetItemMasterPrice_Target_DDL.sql'
            bat 'snowsql -c myconnection --config C:\\Users\\91827\\.snowsql\\config -f Build\ItemMasterPrice_Pending_Retail_Item_Price.sql'
            bat 'snowsql -c myconnection --config C:\\Users\\91827\\.snowsql\\config -f Build\sp_GetItemMasterPrice_To_BIM_load.sql'

         }
         
      }
      
      stage('Test Stage') {
          
         steps {
            bat 'snowsql -c myconnection --config C:\\Users\\91827\\.snowsql\\config -f test\counting_records.sql'
         }
         
      }
      
   }
}
