@IsTest
private class WebhookSignatureValidatedReceiverTest {
    @IsTest static void testReceive_valid() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/webhook/v1/notify';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"evt":"x"}');
        req.headers.put('X-Signature','valid');
        req.headers.put('X-Request-Id','req-1');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        WebhookSignatureValidatedReceiver.receive();
        System.assertEquals(200, RestContext.response.statusCode);
        Integer cnt = [SELECT count() FROM Integration_Call__c WHERE Endpoint__c = :req.requestURI];
        System.assert(cnt > 0);
    }
    @IsTest static void testReceive_invalidSig() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/webhook/v1/notify';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"evt":"x"}');
        req.headers.put('X-Signature','bad');
        req.headers.put('X-Request-Id','req-2');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        WebhookSignatureValidatedReceiver.receive();
        System.assertEquals(403, RestContext.response.statusCode);
    }
}
