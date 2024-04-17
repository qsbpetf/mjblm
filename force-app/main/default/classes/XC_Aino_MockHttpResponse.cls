@IsTest
global class XC_Aino_MockHttpResponse implements HttpCalloutMock{

    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('success');
        res.setStatusCode(200);
        return res;
    }
}