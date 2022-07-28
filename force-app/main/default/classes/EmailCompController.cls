public class EmailCompController {
    
     @AuraEnabled 
    public static String previewMailMethod(String mMail ,String mSubject ,String mbody, String leadId,String folderId,String templateId ){
        
        string leadName = '';
        String leadOwnerName = '' ;
        String contactId = '' ;
        List<Messaging.RenderEmailTemplateBodyResult> renderResults = Messaging.renderEmailTemplate(contactId, leadId, new List<String>{mbody});
        System.debug('renderResults'+renderResults);
        return renderResults[0].getMergedBody();
    }   

    @AuraEnabled 
    public static void sendMailMethod(String mMail ,String mSubject ,String mbody, String leadId,String folderId,String templateId ){
        
        String contactId = '' ;
        list<EmailTemplate> em = new list<EmailTemplate>();
        em = [SELECT Id,Subject,Body,HtmlValue From EmailTemplate where id =: templateId limit 1];
        
        if(leadId != null ){ 
            Case ldObj = [select id,Contact.Name, AccountId, ContactId,Owner.Name from Case where Id =: leadId];
            contactId = ldObj.ContactId;
        }
        
        List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>(); 
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> sendTo = new List<String>();
        sendTo.add(mMail);
        mail.setToAddresses(sendTo);
        mail.setSenderDisplayName('Organization Email'); 
        mail.setSubject(mSubject);
        mail.setHtmlBody(mbody);
        mail.setTargetObjectId(contactId); 
        mail.setWhatId(leadId);
        mail.setReplyTo('alsinan.sf@1jtpj6bx0q00prpzasny2ko2uem5xth577irzsflwypkkrbczu.5h-4xmg5eam.ap25.case.salesforce.com');
        mail.setSaveAsActivity(true);
        mail.setTreatTargetObjectAsRecipient(false);
        mail.setTreatBodiesAsTemplate(true);
        mail.setTemplateId(em.get(0).id);
        mails.add(mail);
        
        Messaging.sendEmail(mails);
    }   
    
    @AuraEnabled
    public static list<emailTemplateWrapper> getEmailTempaltes(){
        list<emailTemplateWrapper> emailTemplateWrapperlist = new list<emailTemplateWrapper>();
        
        map<String,emailTemplateWrapper> folderIdVsTemplateMap = new map<String,emailTemplateWrapper>();
        Folder folderObj = new folder();
        folderObj= [SELECT Id,Name FROM Folder where Name='Brand Email'];
        for(sobject emailtemp : [ SELECT Id, FolderId, HtmlValue, FolderName, isActive, body,Name,subject FROM EmailTemplate where isActive= true and FolderId =: folderObj.Id ]){ 
            if( folderIdVsTemplateMap.containskey( String.valueof(emailtemp.get('FolderId'))) ){
                
                EmailTemplates template = new EmailTemplates();
                template.emailTemplateId = String.valueOf(emailtemp.get('Id'));
                template.emailTemplatename = String.valueOf(emailtemp.get('Name'));
                template.emailbody = (emailtemp.get('HtmlValue') != null ? String.valueOf(emailtemp.get('HtmlValue')) : '' );
                template.emailSubject = String.valueOf(emailtemp.get('subject'));
                folderIdVsTemplateMap.get( String.valueof(emailtemp.get('FolderId')) ).emailtemplatelist.add( template );
                
            }else{
                emailTemplateWrapper tempWrap = new emailTemplateWrapper();
                tempWrap.folderId = String.valueOf(emailtemp.get('FolderId'));
                tempWrap.folderName = String.valueOf(emailtemp.get('FolderName'));
                
                emailTemplates template = new emailTemplates();
                template.emailTemplateId = String.valueOf(emailtemp.get('Id'));
                template.emailTemplatename = String.valueOf(emailtemp.get('Name'));
                template.emailbody = (emailtemp.get('HtmlValue') != null ? String.valueOf(emailtemp.get('HtmlValue')) : '' );
                template.emailSubject = String.valueOf(emailtemp.get('subject'));
                tempWrap.emailtemplatelist = new list<emailTemplates>{ template };
                    folderIdVsTemplateMap.put( String.valueof(emailtemp.get('FolderId'))  , tempWrap );
            }   
        }
        
        if( !folderIdVsTemplateMap.isEmpty() ){
            emailTemplateWrapperlist.addAll( folderIdVsTemplateMap.values() );
            
            return emailTemplateWrapperlist;
        }
        return null;
    }
    
    public class emailTemplateWrapper{
        
        @AuraEnabled 
        public String folderName{get;set;}
        
        @AuraEnabled 
        public String folderId{get;set;}
        
        @AuraEnabled
        public list<emailTemplates> emailtemplatelist{get;set;}
        
    }
    
    public class emailTemplates{
        
        @AuraEnabled 
        public String emailTemplateId{get;set;}
        
        @AuraEnabled 
        public String emailbody{get;set;}
        
        @AuraEnabled
        public String emailSubject {get;set;}
        
        @AuraEnabled 
        public String emailTemplatename{get;set;}
    }  
    
    @AuraEnabled
    public static Case getLeadRec(String leadId){
        Case leadObj = new Case();
        leadObj = [select id,AccountId, ContactEmail, ContactId  from Case where id=: leadId Limit 1];
        return leadObj;
        
    }
}