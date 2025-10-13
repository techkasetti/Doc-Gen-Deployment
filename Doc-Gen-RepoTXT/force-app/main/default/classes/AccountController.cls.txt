public with sharing class AccountController {
    @AuraEnabled(cacheable=true)
   public  static List<Account> accountController() {
       List<Account> accList=[SELECT Id,Name FROM Account ];
       System.debug('accList'+accList);
        return accList;
   }

  @AuraEnabled(cacheable=true)
  public static List<Account> getAccountsWithContacts() {
       List<Account> accounts = [SELECT Id, Name, Industry,
                                  (SELECT Id, Name FROM Contacts)
                                  FROM Account];
       return accounts;
   }

 @AuraEnabled(cacheable=true)
 public static List<OpportunityLineItem> getOpportunityItem(String selctedCompanyValue){
   List<OpportunityLineItem> oppLineItem=[SELECT Id,Name,ServiceDate,Discount
                                          FROM OpportunityLineItem
                                           WHERE Opportunity.Id=:selctedCompanyValue];
  system.debug('oppLineItem'+oppLineItem);
                                           return oppLineItem;
 }
   
 @AuraEnabled(cacheable=true)
 public static List<OpportunityLineItem> getOpportunityItemId(String selctedOppId){
   List<OpportunityLineItem> oppLineItem=[SELECT Id
                                          FROM OpportunityLineItem
                                           WHERE Opportunity.Id=:selctedOppId];
  system.debug('oppLineItem'+oppLineItem);
                                           return oppLineItem;
 }
         
 @AuraEnabled(cacheable=true)
 public static List<Opportunity> getOpportunity(String accountId){
   List<Opportunity> oppList=[SELECT Id,Name,AccountId,StageName,Amount,CloseDate ,Account.Name ,Account.BillingCountry ,Account.BillingPostalCode,
   Account.BillingCity  ,  Account.BillingState  , Account.BillingStreet
                                   FROM Opportunity
                                   WHERE AccountId=:accountId];
                                   return oppList;
 }
    
 @AuraEnabled(cacheable=true)
 public static List<OpportunityLineItem> getOpportunityLineId(list<String> lineId){
   system.debug('lineId'+lineId);
   List<OpportunityLineItem> oppLineItem=[SELECT Id,Name,ServiceDate,Discount,OpportunityId
   FROM OpportunityLineItem
    WHERE Id IN:lineId];
  system.debug('oppLineItem'+oppLineItem.Size());
                                           return oppLineItem;
 }
}