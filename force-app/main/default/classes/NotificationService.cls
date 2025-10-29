public class NotificationService {
    
    public class NotificationRequest {
        @AuraEnabled public String recipientId;
        @AuraEnabled public String recipientEmail;
        @AuraEnabled public String notificationType;
        @AuraEnabled public String subject;
        @AuraEnabled public String message;
        @AuraEnabled public Map<String, Object> templateData;
        @AuraEnabled public String priority;
        @AuraEnabled public Boolean sendEmail;
        @AuraEnabled public Boolean sendInApp;
    }

    public class NotificationResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String notificationId;
        @AuraEnabled public String status;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public DateTime sentTime;
    }

    @AuraEnabled(cacheable=false)
    public static NotificationResult sendNotification(NotificationRequest request) {
        NotificationResult result = new NotificationResult();
        result.sentTime = DateTime.now();
        try {
            Notification_Queue__c notification = new Notification_Queue__c(
                Recipient_Id__c      = request.recipientId,
                Recipient_Email__c   = request.recipientEmail,
                Notification_Type__c = request.notificationType,
                Subject__c           = request.subject,
                Message__c           = request.message,
                Priority__c          = request.priority != null ? request.priority : 'Medium',
                Status__c            = 'Queued',
                Send_Email__c        = request.sendEmail != null ? request.sendEmail : true,
                Send_In_App__c       = request.sendInApp != null ? request.sendInApp : true,
                Template_Data__c     = request.templateData != null ? JSON.serialize(request.templateData) : null,
                Created_Date__c      = DateTime.now()
            );
            insert notification;

            if (request.sendInApp == true) {
                createInAppNotification(notification);
            }
            if (request.sendEmail == true && String.isNotBlank(request.recipientEmail)) {
                sendEmailNotification(notification);
            }

            notification.Status__c   = 'Sent';
            notification.Sent_Date__c = DateTime.now();
            update notification;

            result.success       = true;
            result.notificationId = notification.Id;
            result.status        = 'Sent';
        } catch (Exception e) {
            result.success     = false;
            result.errorMessage = e.getMessage();
            result.status       = 'Failed';
        }
        return result;
    }

    private static void createInAppNotification(Notification_Queue__c notification) {
        try {
            In_App_Notification__c inAppNotification = new In_App_Notification__c(
                User_Id__c   = notification.Recipient_Id__c,
                Title__c     = notification.Subject__c,
                Message__c   = notification.Message__c,
                Type__c      = notification.Notification_Type__c,
                Priority__c  = notification.Priority__c,
                Read__c      = false,
                Created_Date__c = DateTime.now()
            );
            insert inAppNotification;
        } catch (Exception e) {
            System.debug('Failed to create in-app notification: ' + e.getMessage());
        }
    }

    private static void sendEmailNotification(Notification_Queue__c notification) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { notification.Recipient_Email__c });
            email.setSubject(notification.Subject__c);
            email.setPlainTextBody(notification.Message__c);

            if (String.isNotBlank(notification.Template_Data__c)) {
                Map<String, Object> templateData = 
                    (Map<String, Object>)JSON.deserializeUntyped(notification.Template_Data__c);
                String htmlBody = processEmailTemplate(notification.Message__c, templateData);
                email.setHtmlBody(htmlBody);
            }

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        } catch (Exception e) {
            System.debug('Failed to send email notification: ' + e.getMessage());
        }
    }

    private static String processEmailTemplate(String template, Map<String, Object> templateData) {
        if (templateData == null || templateData.isEmpty()) {
            return template;
        }
        String processedTemplate = template;
        for (String key : templateData.keySet()) {
            String placeholder = '{{' + key + '}}';
            String value = String.valueOf(templateData.get(key));
            processedTemplate = processedTemplate.replace(placeholder, value);
        }
        return processedTemplate;
    }

    @AuraEnabled(cacheable=false)
    public static List<NotificationResult> sendBulkNotifications(List<NotificationRequest> requests) {
        List<NotificationResult> results = new List<NotificationResult>();
        for (NotificationRequest request : requests) {
            try {
                NotificationResult result = sendNotification(request);
                results.add(result);
            } catch (Exception e) {
                NotificationResult errorResult = new NotificationResult();
                errorResult.success = false;
                errorResult.errorMessage = 'Bulk notification error: ' + e.getMessage();
                results.add(errorResult);
            }
        }
        return results;
    }

    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getUserNotifications(String userId, Boolean unreadOnly) {
        List<Map<String, Object>> notifications = new List<Map<String, Object>>();
        try {
            String query = 'SELECT Id, Title__c, Message__c, Type__c, Priority__c, Read__c, Created_Date__c ' +
                           'FROM In_App_Notification__c WHERE User_Id__c = :userId';
            if (unreadOnly) {
                query += ' AND Read__c = false';
            }
            query += ' ORDER BY Created_Date__c DESC LIMIT 50';

            List<In_App_Notification__c> notificationRecords = Database.query(query);

            for (In_App_Notification__c notification : notificationRecords) {
                notifications.add(new Map<String, Object>{
                    'id'          => notification.Id,
                    'title'       => notification.Title__c,
                    'message'     => notification.Message__c,
                    'type'        => notification.Type__c,
                    'priority'    => notification.Priority__c,
                    'read'        => notification.Read__c,
                    'createdDate' => notification.Created_Date__c
                });
            }
        } catch (Exception e) {
            System.debug('Error retrieving user notifications: ' + e.getMessage());
        }
        return notifications;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean markNotificationAsRead(String notificationId) {
        try {
            In_App_Notification__c notification = [
                SELECT Id, Read__c FROM In_App_Notification__c WHERE Id = :notificationId LIMIT 1
            ];
            if (notification != null && !notification.Read__c) {
                notification.Read__c = true;
                notification.Read_Date__c = DateTime.now();
                update notification;
                return true;
            }
            return false;
        } catch (Exception e) {
            System.debug('Failed to mark notification as read: ' + e.getMessage());
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean markAllNotificationsAsRead(String userId) {
        try {
            List<In_App_Notification__c> notifications = [
                SELECT Id FROM In_App_Notification__c WHERE User_Id__c = :userId AND Read__c = false
            ];
            for (In_App_Notification__c notification : notifications) {
                notification.Read__c = true;
                notification.Read_Date__c = DateTime.now();
            }
            if (!notifications.isEmpty()) {
                update notifications;
            }
            return true;
        } catch (Exception e) {
            System.debug('Failed to mark all notifications as read: ' + e.getMessage());
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getNotificationSettings(String userId) {
        Map<String, Object> settings = new Map<String, Object>();
        try {
            List<Notification_Preference__c> preferences = [
                SELECT Id, Notification_Type__c, Email_Enabled__c, In_App_Enabled__c, Push_Enabled__c
                FROM Notification_Preference__c
                WHERE User_Id__c = :userId
            ];
            Map<String, Map<String, Boolean>> preferenceMap = new Map<String, Map<String, Boolean>>();
            for (Notification_Preference__c pref : preferences) {
                preferenceMap.put(pref.Notification_Type__c, new Map<String, Boolean>{
                    'email' => pref.Email_Enabled__c,
                    'inApp' => pref.In_App_Enabled__c,
                    'push'  => pref.Push_Enabled__c
                });
            }
            settings.put('preferences', preferenceMap);

            Integer unreadCount = [
                SELECT COUNT() FROM In_App_Notification__c WHERE User_Id__c = :userId AND Read__c = false
            ];
            settings.put('unreadCount', unreadCount);

            List<String> availableTypes = new List<String>{
                'DOCUMENT_SIGNED', 'DOCUMENT_EXPIRED', 'COMPLIANCE_ALERT',
                'SYSTEM_MAINTENANCE', 'SIGNATURE_REMINDER'
            };
            settings.put('availableTypes', availableTypes);
        } catch (Exception e) {
            settings.put('error', e.getMessage());
        }
        return settings;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean updateNotificationSettings(String userId, Map<String, Object> settingsData) {
        try {
            Map<String, Object> preferences = (Map<String, Object>)settingsData.get('preferences');

            List<Notification_Preference__c> existingPrefs = [
                SELECT Id, Notification_Type__c FROM Notification_Preference__c WHERE User_Id__c = :userId
            ];
            Map<String, Notification_Preference__c> existingPrefMap = 
                new Map<String, Notification_Preference__c>();
            for (Notification_Preference__c pref : existingPrefs) {
                existingPrefMap.put(pref.Notification_Type__c, pref);
            }

            List<Notification_Preference__c> prefsToUpsert = new List<Notification_Preference__c>();
            for (String notificationType : preferences.keySet()) {
                Map<String, Object> typeSettings = (Map<String, Object>)preferences.get(notificationType);
                Boolean emailEnabled = (Boolean)typeSettings.get('email');
                Boolean inAppEnabled = (Boolean)typeSettings.get('inApp');
                Boolean pushEnabled  = (Boolean)typeSettings.get('push');

                Notification_Preference__c pref;
                if (existingPrefMap.containsKey(notificationType)) {
                    pref = existingPrefMap.get(notificationType);
                } else {
                    pref = new Notification_Preference__c(
                        User_Id__c = userId,
                        Notification_Type__c = notificationType
                    );
                }
                pref.Email_Enabled__c = emailEnabled != null ? emailEnabled : false;
                pref.In_App_Enabled__c = inAppEnabled != null ? inAppEnabled : true;
                pref.Push_Enabled__c   = pushEnabled != null ? pushEnabled : false;
                prefsToUpsert.add(pref);
            }
            if (!prefsToUpsert.isEmpty()) {
                upsert prefsToUpsert;
            }
            return true;
        } catch (Exception e) {
            System.debug('Failed to update notification settings: ' + e.getMessage());
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getNotificationMetrics() {
        Map<String, Object> metrics = new Map<String, Object>();
        try {
            Date sevenDaysAgo = Date.today().addDays(-7);
            DateTime sevenDaysAgoDateTime = DateTime.newInstance(sevenDaysAgo, Time.newInstance(0, 0, 0, 0));

            Integer totalSent = [
                SELECT COUNT() FROM Notification_Queue__c WHERE CreatedDate >= :sevenDaysAgoDateTime
            ];
            Integer emailsSent = [
                SELECT COUNT() FROM Notification_Queue__c WHERE Send_Email__c = true AND CreatedDate >= :sevenDaysAgoDateTime
            ];
            Integer inAppSent = [
                SELECT COUNT() FROM Notification_Queue__c WHERE Send_In_App__c = true AND CreatedDate >= :sevenDaysAgoDateTime
            ];

            metrics.put('totalNotificationsSent', totalSent);
            metrics.put('emailNotificationsSent', emailsSent);
            metrics.put('inAppNotificationsSent', inAppSent);

            List<AggregateResult> typeBreakdown = [
                SELECT Notification_Type__c notType, COUNT(Id) typeCount
                FROM Notification_Queue__c
                WHERE CreatedDate >= :sevenDaysAgoDateTime
                GROUP BY Notification_Type__c
            ];
            Map<String, Integer> typeMetrics = new Map<String, Integer>();
            for (AggregateResult ar : typeBreakdown) {
                String notType = (String)ar.get('notType');
                Integer typeCount = (Integer)ar.get('typeCount');
                typeMetrics.put(notType != null ? notType : 'Unknown', typeCount);
            }
            metrics.put('notificationTypeBreakdown', typeMetrics);

            Integer totalUnread = [SELECT COUNT() FROM In_App_Notification__c WHERE Read__c = false];
            Integer totalRead = [
                SELECT COUNT() FROM In_App_Notification__c WHERE Read__c = true AND CreatedDate >= :sevenDaysAgoDateTime
            ];
            metrics.put('totalUnreadNotifications', totalUnread);
            metrics.put('totalReadNotifications', totalRead);
            metrics.put('readRate', 
                (totalRead + totalUnread) > 0 ? (totalRead * 100) / (totalRead + totalUnread) : 0
            );
        } catch (Exception e) {
            metrics.put('error', e.getMessage());
        }
        return metrics;
    }
}