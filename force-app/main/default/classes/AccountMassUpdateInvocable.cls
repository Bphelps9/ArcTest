public class AccountMassUpdateInvocable {

    public class Input {
        @InvocableVariable(label='Concatenated Zip Codes' description='List of Zip Codes concatenated with a semicolon. If no value is provided all Accounts are updated.' required='false')
        public String concatZipCodes;
        @InvocableVariable(label='Batch Size' description='Amount of Accounts to update in each batch. Values below 0 and above 200 are ignored and set to default instead.' required='false')
        public Integer batchSize;
        
        public Input() {}
    }

    @InvocableMethod(label='Recalculate Territory Details' category='Account')
    public static List<Id> scheduleBatchableJob(List<Input> inputs) {
        Set<String> zipCodeSet = new Set<String>();
        // Loop through all inputs and collect all zipcode values
        for (Input i: inputs) {
            // If one of the inputs is blank, then all other inputs should be ignored to eventually update all Accounts in batchable class
            if (!String.isBlank(i.concatZipCodes)) {
                List<String> zipCodeList = i.concatZipCodes.split(';');            
                for (String zip: zipCodeList) {
                    zipCodeSet.add(zip.trim());
                }
            } else {
                zipCodeSet = new Set<String>();
                break;
            }
        }
        AccountTerritoryRecalcBatchable batchable = new AccountTerritoryRecalcBatchable(zipCodeSet);
        Integer batchSize = inputs[0].batchSize;
        // Fallback to default if provided batch size is lower than 0 or higher than 200
        if (batchSize != null && batchSize <= 200 && 0 < batchSize) {
            return buildReturnList(inputs.size(), Database.executeBatch(batchable, batchSize));
        } else {
            return buildReturnList(inputs.size(), Database.executeBatch(batchable));
        }
    }

    private static List<Id> buildReturnList(Integer size, Id jobId) {
        List<Id> idList = new List<Id>();
        for (Integer i = 0; i < size; i++) {
            idList.add(jobId);
        }
        return idList;
    }
}