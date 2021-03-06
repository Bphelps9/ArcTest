public class AccountTriggerHandler {
    
    public static Boolean bypassTrigger = false;
    
    public AccountTriggerHandler() {}
    
    public void run() {
        if (bypassTrigger == true) {
            return;
        }

        if (Trigger.isBefore && Trigger.isInsert) {
            assignCustomTerritories(Trigger.new);
            AccountUtility.setParentAccounts(Trigger.new);
        }
        else if (Trigger.isBefore && Trigger.isUpdate) {
            assignCustomTerritories(Trigger.new);
            AccountUtility.setParentAccountsOnUpdate(Trigger.new, (Map<Id, Account>)Trigger.oldMap);
        }
        else if (Trigger.isAfter && Trigger.isUpdate) {
            // reevaluateOpportunityTerritoryFilter();
        }
    }

    public static List<Account> assignCustomTerritories(List<Account> accounts) {
        Set<String> postalCodes = new Set<String>();
        List<Account> accList = new List<Account>();
        Map<Id, String> overrideMap = new Map<Id, String>();
        for (Account acc: accounts) {
            if (acc.TerritoryOverride__c == 'Override by ID') {
            	postalCodes.add(acc.ShippingPostalCode);
            	accList.add(acc);
                overrideMap.put(acc.Id, acc.Territory_ID__c);
            } else if (String.isBlank(acc.TerritoryOverride__c)) {
            	postalCodes.add(acc.ShippingPostalCode);
            	accList.add(acc);
            }
        }
        // Collect accounts with modified owners
        Map<Id, Account> accMap = new Map<Id, Account>();
        TerritoryAssignmentHandler handler = new TerritoryAssignmentHandler(postalCodes, 'Account', overrideMap);
        for (Account acc: accList) {
            TerritoryAssignmentHandler.TerritoryStruct territoryDetails = handler.getTerritoryDetails(acc.Id, acc.ShippingPostalCode, acc.Special_Territory_Assignment__c);
            acc.Territory_ID__c = territoryDetails.territoryNumber;
            acc.Territory_Name__c = territoryDetails.territoryId;
            acc.AM__c = territoryDetails.am;
            acc.AMUser__c = territoryDetails.amId;
            acc.RVP__c = territoryDetails.rvp;
            acc.RVPUser__c = territoryDetails.rvpId;
            acc.PC__c = territoryDetails.pc;
            acc.PCUser__c = territoryDetails.pcId;
            acc.State__c = territoryDetails.state;
            acc.County__c = territoryDetails.county;

            if (!String.isBlank(territoryDetails.amId)) {
                acc.OwnerId = territoryDetails.amId;
                accMap.put(acc.Id, acc);
            }
        }
        // Update the Owners of related open Opportunities and Contacts
		OpportunityUtility.setRelatedOpenOpportunityOwner(accMap);
        ContactUtility.setRelatedContactOwner(accMap);
        return accList;
    }
}