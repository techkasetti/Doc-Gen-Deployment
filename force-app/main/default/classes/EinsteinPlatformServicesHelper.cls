/**
 * Einstein Platform Services Helper Class
 */
public class EinsteinPlatformServicesHelper {

    public static String refreshEinsteinToken() {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Einstein_Platform/v2/oauth2/token');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

            Einstein_Settings__c settings = Einstein_Settings__c.getOrgDefaults();
            String assertion = generateJWTAssertion(settings.Private_Key__c, settings.Client_Id__c);

            req.setBody('grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' + assertion);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                return (String)response.get('access_token');
            }
        } catch (Exception e) {
            System.debug('Error refreshing Einstein token: ' + e.getMessage());
        }
        return '';
    }


    private static String generateJWTAssertion(String privateKey, String clientId) {
        return 'jwt-assertion-token';
    }

    public static String extractTextContent(ContentVersion version) {
        String textContent = '';
        try {
            String fileType = version.FileType.toLowerCase();
            if (fileType == 'txt') {
                textContent = version.VersionData.toString();
            } else if (fileType == 'pdf') {
                textContent = extractPDFContent(version.VersionData);
            } else if (fileType == 'docx' || fileType == 'doc') {
                textContent = extractWordContent(version.VersionData);
            } else if (fileType == 'xlsx' || fileType == 'xls') {
                textContent = extractExcelContent(version.VersionData);
            } else {
                textContent = performOCRExtraction(version.VersionData, fileType);
            }
        } catch (Exception e) {
            System.debug('Error extracting text content: ' + e.getMessage());
            textContent = 'Content extraction failed: ' + e.getMessage();
        }
        return textContent;
    }

    private static String extractPDFContent(Blob pdfData) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Einstein_Platform/v2/vision/ocr');
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + getEinsteinAccessToken());
            req.setHeader('Content-Type', 'application/octet-stream');
            req.setBodyAsBlob(pdfData);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                List<Object> words = (List<Object>)response.get('words');
                if (words != null) {
                    List<String> extractedText = new List<String>();
                    for (Object word : words) {
                        Map<String, Object> wordMap = (Map<String, Object>)word;
                        extractedText.add((String)wordMap.get('text'));
                    }
                    return String.join(extractedText, ' ');
                }
            }
        } catch (Exception e) {
            System.debug('Error extracting PDF content: ' + e.getMessage());
        }
        return '';
    }

    private static String extractWordContent(Blob docData) {
        return 'Word content extraction not implemented';
    }

    private static String extractExcelContent(Blob excelData) {
        return 'Excel content extraction not implemented';
    }

    private static String performOCRExtraction(Blob imageData, String fileType) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Einstein_Platform/v2/vision/ocr');
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + getEinsteinAccessToken());
            req.setHeader('Content-Type', 'application/octet-stream');
            req.setBodyAsBlob(imageData);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                return processOCRResponse(response);
            }
        } catch (Exception e) {
            System.debug('Error performing OCR extraction: ' + e.getMessage());
        }
        return '';
    }

    private static String processOCRResponse(Map<String, Object> ocrResponse) {
        List<String> extractedText = new List<String>();
        try {
            List<Object> words = (List<Object>)ocrResponse.get('words');
            if (words != null) {
                for (Object word : words) {
                    Map<String, Object> wordMap = (Map<String, Object>)word;
                    String text = (String)wordMap.get('text');
                    if (String.isNotBlank(text)) {
                        extractedText.add(text);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error processing OCR response: ' + e.getMessage());
        }
        return String.join(extractedText, ' ');
    }

    private static String getEinsteinAccessToken() {
        String token = (String)Cache.Org.get('einstein_access_token');
        if (String.isBlank(token)) {
            token = refreshEinsteinToken();
            if (String.isNotBlank(token)) {
                Cache.Org.put('einstein_access_token', token, 3600);
            }
        }
        return token;
    }
}
