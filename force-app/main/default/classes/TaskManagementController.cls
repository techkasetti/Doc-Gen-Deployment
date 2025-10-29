public with sharing class TaskManagementController {
    @AuraEnabled public static Id createTask(String summary, Id whoId) {
        if (String.isBlank(summary) || whoId == null) return null;
        Task t = new Task(Subject = summary, WhatId = whoId);
        try { insert t; return t.Id; } catch(Exception ex) { return null; }
    }
}