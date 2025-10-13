@IsTest
private class SignatureRequestControllerTest {
  @IsTest static void testCreateAndVerify() {
    Document__c d = new Document__c(Name='UT Doc');
    insert d;
    Test.startTest();
    Id sigId = SignatureRequestController.createSignatureRequest(d.Id, 'test@x.com', 'Test User');
    Test.stopTest();
    System.assertNotEquals(null, sigId);
  }
}
