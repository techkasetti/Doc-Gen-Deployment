\
        @RestResource(urlMapping='/api/templates/*')
        global with sharing class TemplateRest {
            @HttpGet
            global static void doGet() {
                RestRequest req = RestContext.request;
                RestResponse res = RestContext.response;
                String id = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
                if (id == null || id == '' || id == 'api' || id == 'templates') {
                    List<Template__c> rows = TemplateService.listTemplates(false);
                    res.statusCode = 200;
                    res.responseBody = Blob.valueOf(JSON.serialize(rows));
                    return;
                }
                try {
                    Template__c t = TemplateService.getTemplateById(Id.valueOf(id));
                    res.statusCode = 200;
                    res.responseBody = Blob.valueOf(JSON.serialize(t));
                } catch (Exception e) {
                    res.statusCode = 404;
                    res.responseBody = Blob.valueOf('{"error":"not found"}');
                }
            }

            @HttpPost
            global static void doPost() {
                RestRequest req = RestContext.request;
                RestResponse res = RestContext.response;
                Map<String,Object> payload = (Map<String,Object>) JSON.deserializeUntyped(req.requestBody.toString());
                String name = (String)payload.get('name');
                String content = (String)payload.get('content');
                String format = (String)payload.get('format');
                Boolean isActive = (payload.containsKey('isActive')) ? (Boolean)payload.get('isActive') : true;
                Id id = TemplateService.createTemplate(name, content, format, isActive);
                res.statusCode = 201;
                res.responseBody = Blob.valueOf('{"id":"'+String.valueOf(id)+'"}');
            }

            @HttpPut
            global static void doPut() {
                RestRequest req = RestContext.request;
                RestResponse res = RestContext.response;
                String id = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
                Map<String,Object> payload = (Map<String,Object>) JSON.deserializeUntyped(req.requestBody.toString());
                String content = (String)payload.get('content');
                String format = (String)payload.get('format');
                Boolean isActive = (payload.containsKey('isActive')) ? (Boolean)payload.get('isActive') : true;

                Template__c updated = TemplateService.updateTemplate(Id.valueOf(id), content, format, isActive);
                res.statusCode = 200;
                res.responseBody = Blob.valueOf(JSON.serialize(updated));
            }

            @HttpDelete
            global static void doDelete() {
                RestRequest req = RestContext.request;
                RestResponse res = RestContext.response;
                String id = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
                TemplateService.deleteTemplate(Id.valueOf(id));
                res.statusCode = 204;
            }
        }
