public with sharing class SeedDataRunner {
  @AuraEnabled
  public static void insertSeedData() {
    List<DocumentTemplate__c> templates = new List<DocumentTemplate__c>{
      new DocumentTemplate__c(Name='Standard NDA', Region__c='US', Default_Output_Format__c='PDF', Template_Content__c='<<PartyA>> agrees...'),
      new DocumentTemplate__c(Name='Employment Contract', Region__c='US', Default_Output_Format__c='PDF', Template_Content__c='Employment terms...')
    };
    insert templates;

    List<ClauseLibrary__c> clauses = new List<ClauseLibrary__c>{
      new ClauseLibrary__c(Name='Confidentiality', Body__c='The parties shall maintain confidentiality...'),
      new ClauseLibrary__c(Name='NonCompete', Body__c='The employee agrees...')
    };
    insert clauses;
  }
}