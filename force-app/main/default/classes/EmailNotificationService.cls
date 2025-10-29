public class EmailNotificationService {
    public static void sendTemplatedEmail(String templateName, List<String> recipients, Map<String, String> mergeData) {
        // Implementation for sending templated emails
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (String recipient : recipients) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{recipient});
            email.setSubject('Document Management Alert: ' + templateName);
            
            String body = 'Document: ' + mergeData.get('documentTitle') + '\n' +
                         'Action Required: ' + mergeData.get('recommendedActions');
            email.setPlainTextBody(body);
            
            emails.add(email);
        }
        
        Messaging.sendEmail(emails);
    }
}