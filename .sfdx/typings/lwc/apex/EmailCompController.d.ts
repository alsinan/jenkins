declare module "@salesforce/apex/EmailCompController.previewMailMethod" {
  export default function previewMailMethod(param: {mMail: any, mSubject: any, mbody: any, leadId: any, folderId: any, templateId: any}): Promise<any>;
}
declare module "@salesforce/apex/EmailCompController.sendMailMethod" {
  export default function sendMailMethod(param: {mMail: any, mSubject: any, mbody: any, leadId: any, folderId: any, templateId: any}): Promise<any>;
}
declare module "@salesforce/apex/EmailCompController.getEmailTempaltes" {
  export default function getEmailTempaltes(): Promise<any>;
}
declare module "@salesforce/apex/EmailCompController.getLeadRec" {
  export default function getLeadRec(param: {leadId: any}): Promise<any>;
}
