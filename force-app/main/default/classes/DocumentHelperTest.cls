@isTest
public with sharing class DocumentHelperTest {

    @isTest
    static void testExtractTextContent() {
        ContentVersion cv = new ContentVersion(
            Title = 'TestDoc',
            PathOnClient = 'TestDoc.txt',
            VersionData = Blob.valueOf('Sample content for testing')
        );
        insert cv;

        Test.startTest();
        String content = DocumentHelper.extractTextContent(cv.Id);
        Test.stopTest();

        System.assertNotEquals(null, content, 'Extracted content should not be null');
        System.assert(content.contains('Sample content'), 'Content should contain expected text');
    }
}