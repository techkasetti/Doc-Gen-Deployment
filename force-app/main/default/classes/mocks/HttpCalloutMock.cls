@IsTest
global class HttpCalloutMock implements HttpCalloutMock {
  global HTTPResponse respond(HTTPRequest req) {
    HttpResponse res = new HttpResponse();
    res.setStatusCode(200);
    res.setBody('{"access_token":"FAKE_TOKEN","expires_in":3600}');
    return res;
  }
}
