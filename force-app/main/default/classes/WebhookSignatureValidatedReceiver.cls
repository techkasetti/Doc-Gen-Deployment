@RestResource(urlMapping='/webhook/v1/*')
global with sharing class WebhookSignatureValidatedReceiver {
    @HttpPost
    global static void receive() {
        RestRequest req = RestContext.request;
        String sigHeader = req.headers.get('X-Signature');
        // Basic idempotency check via header X-Request-Id
        String reqId = req.headers.get('X-Request-Id');
        if (String.isBlank(reqId)) {
            RestContext.response.statusCode = 400;
            return;
        }
        // For demo: accept if signature header equals 'valid' else 403
        if (sigHeader != 'valid') {
            RestContext.response.statusCode = 403;
            return;
        }
        // record an integration call
        Integration_Call__c ic = new Integration_Call__c(Endpoint__c = req.requestURI, StatusCode__c = 200, Response__c = req.requestBody.toString());
        insert ic;
        RestContext.response.statusCode = 200;
    }
}