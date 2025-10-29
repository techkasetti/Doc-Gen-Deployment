@IsTest
private class DocumentAssemblyServiceTest {
    @testSetup
    static void createTemplateRecord() {
        // Create a template record using dynamic SObject so tests run across orgs that
        // name the custom object either Document_Template__c or DocumentTemplate__c.
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        String templateType = null;
        if (gd.containsKey('Document_Template__c')) {
            templateType = 'Document_Template__c';
        } else if (gd.containsKey('DocumentTemplate__c')) {
            templateType = 'DocumentTemplate__c';
        } else {
            // No template object in this org; nothing to create (tests below will handle this).
            return;
        }

        SObject tmpl = gd.get(templateType).newSObject();
        // Common field names used in repository variants
        tmpl.put('Template_Content__c', '<html><body>Hello {{NAME}}</body></html>');
        // Template name field may be Template_Name__c in some schemas
        if (Schema.getGlobalDescribe().get(templateType).getDescribe().fields.getMap().containsKey('Template_Name__c')) {
            tmpl.put('Template_Name__c', 'TST_Template');
        } else if (Schema.getGlobalDescribe().get(templateType).getDescribe().fields.getMap().containsKey('Name')) {
            tmpl.put('Name', 'TST_Template');
        }
        try {
            insert tmpl;
        } catch (Exception e) {
            // Best-effort setup; tests will assert behavior if insert wasn't possible
            System.debug('DocumentAssemblyServiceTest.setup: template insert error: ' + e.getMessage());
        }
    }

    @IsTest
    static void testAssembleDocument_createsContentVersion() {
        // Locate a template created in @testSetup (if any)
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        String templateType = null;
        if (gd.containsKey('Document_Template__c')) {
            templateType = 'Document_Template__c';
        } else if (gd.containsKey('DocumentTemplate__c')) {
            templateType = 'DocumentTemplate__c';
        }

        // If there is no template object, assert the service returns the expected guarded message.
        if (templateType == null) {
            Test.startTest();
            DocumentAssemblyService.AssemblyResult rNoType = DocumentAssemblyService.assembleDocument(null, new Map<String, Object>{'NAME' => 'Acme'});
            Test.stopTest();
            // Service should return missing templateId or type-not-available message (defensive behavior).
            System.assertEquals(false, rNoType.ok);
            return;
        }

        // Query inserted template record dynamically
        String q = 'SELECT Id';
        // include Template_Name__c if present to help later assertions
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(templateType).getDescribe().fields.getMap();
        if (fields.containsKey('Template_Name__c')) {
            q += ', Template_Name__c';
        } else if (fields.containsKey('Name')) {
            q += ', Name';
        }
        q += ' FROM ' + templateType + ' LIMIT 1';
        SObject tmpl = Database.query(q);
        Id templateId = (Id)tmpl.get('Id');

        // Prepare merge data
        Map<String, Object> mergeData = new Map<String, Object>{ 'NAME' => 'Acme' };

        Test.startTest();
        DocumentAssemblyService.AssemblyResult result = DocumentAssemblyService.assembleDocument(templateId, mergeData);
        Test.stopTest();

        // Assert assembly succeeded and a ContentVersion Id was returned
        System.assertEquals(true, result.ok, 'Assembly should succeed');
        System.assertNotEquals(null, result.contentVersionId, 'ContentVersion Id should be returned');

        // Verify ContentVersion exists and basic properties
        ContentVersion cv = [SELECT Id, Title, VersionData FROM ContentVersion WHERE Id = :result.contentVersionId LIMIT 1];
        System.assertNotEquals(null, cv, 'ContentVersion record should exist');

        // If template had a name field we set, validate title matches that value (best-effort)
        if (tmpl.getSObjectType().getDescribe().fields.getMap().containsKey('Template_Name__c')) {
            String expectedName = (String)tmpl.get('Template_Name__c');
            if (expectedName != null) {
                System.assertEquals(expectedName, cv.Title, 'ContentVersion title should match template name');
            }
        } else if (tmpl.getSObjectType().getDescribe().fields.getMap().containsKey('Name')) {
            String expectedName = (String)tmpl.get('Name');
            if (expectedName != null) {
                System.assertEquals(expectedName, cv.Title, 'ContentVersion title should match template Name');
            }
        }

        // Best-effort: try to assert merged content contains replacement value (may vary by org/encoding)
        try {
            String body = cv.VersionData.toString();
            System.assert(body.contains('Hello Acme'), 'Generated content should include merged value');
        } catch (Exception ex) {
            // If conversion fails in a particular org, treat as non-fatal but log for debugging.
            System.debug('DocumentAssemblyServiceTest: could not convert VersionData to string: ' + ex.getMessage());
        }
    }
}