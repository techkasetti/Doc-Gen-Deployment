@IsTest
private class DocumentGenerationControllerTest {
    @IsTest static void testPreview_noTemplate() {
        Test.startTest();
        Map<String,Object> res = DocumentGenerationController.preview(null, new Map<String,Object>());
        Test.stopTest();
        System.assertEquals(false, (Boolean)res.get('ok'));
    }
    @IsTest static void testGenerate_flow() {
        Id tempId = null;
        if (Schema.getGlobalDescribe().containsKey('Template__c')) {
            Template__c t = new Template__c(Name='UT'); insert t; tempId = t.Id;
        }
        Test.startTest();
        Map<String,Object> res = DocumentGenerationController.generate(tempId, new Map<String,Object>{});
        Test.stopTest();
        System.assert(res.containsKey('ok'));
    }
}