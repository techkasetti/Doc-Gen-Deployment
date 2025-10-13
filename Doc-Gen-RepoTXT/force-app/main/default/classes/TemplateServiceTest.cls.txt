@IsTest
private class TemplateServiceTest {
    @IsTest static void testCreateAndReadTemplate() {
        Test.startTest();
        Id tid = TemplateService.createTemplate('T1','<p>Hello {{name}}</p>','HTML', true);
        Template__c t = TemplateService.getTemplateById(tid);
        System.assertEquals('T1', t.Name);
        Test.stopTest();
    }

    @IsTest static void testUpdateTemplate() {
        Id tid = TemplateService.createTemplate('T2','content','DOCX', true);
        Template__c updated = TemplateService.updateTemplate(tid, 'new content', 'DOCX', false);
        System.assertEquals('new content', updated.Content__c);
        System.assertEquals(false, updated.IsActive__c);
    }

    @IsTest static void testListTemplates() {
        TemplateService.createTemplate('T3','c','HTML', true);
        TemplateService.createTemplate('T4','c2','HTML', false);
        List<Template__c> allTemplates = TemplateService.listTemplates(false);
        System.assert(allTemplates.size() >= 2);
    }
}
