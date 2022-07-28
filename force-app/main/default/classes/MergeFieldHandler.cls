public class MergeFieldHandler
{
    /*parser main class which fetches mergefields and replaces them*/
    public static String parse(Set<Id> ids, String content)
    {
        try
        {System.debug('content+++++++++++++'+content);
            System.debug('IDS+++++++++++++'+ids);
            Map<Id,Set<string>> objectFieldPair = new  Map<Id,Set<string>>();
            Map<Id,string> iDAPIMap = new Map<Id,string>();
            for(Id objId : ids)
            {
                String objectAPI = getObjectAPI(objId);
                if(objectAPI == 'AllUsersBasic')
                {
                    objectAPI = 'User';
                }
                Set<String> allFields = new Set<String>();
                allFields.addAll(getFields(content, objectAPI));
                objectFieldPair.put(objId, allFields);
                iDAPIMap.put(objId, objectAPI);
            }
            
            for(Id objId : iDAPIMap.keySet()) {
                List<Id> idsToQuery = new List<Id>();
                idsToQuery.add(objId);
                String objectFields = '';
                for(String field : objectFieldPair.get(objId))
                {  
                    objectFields += field + ', ';
                }
                
                if(objectFields != '')
                {
                    Map<Id, String> objectIdToNewContent = new Map<Id, String>();
                    objectFields = objectFields.substring(0, objectFields.length() - 2);
                    String queryStr = 'select ' + objectFields + ' from ' + iDAPIMap.get(objId) + ' where Id in :idsToQuery';
                    Map<String, String> tempMap = new Map<String, String>();
                    Map<String, String> fieldTypeMap = getFieldTypes(iDAPIMap.get(objId) ,objectFieldPair.get(objId));
                    
                    for(sObject obj : Database.query(queryStr))
                    {
                        for(String field : objectFieldPair.get(objId))
                        {  
                            tempMap.put(field, String.valueOf(getFieldValue(obj, field)));
                            
                        }
                        objectIdToNewContent.put(obj.Id, match(content, tempMap, iDAPIMap.get(objId),fieldTypeMap));
                        content = match(content, tempMap, iDAPIMap.get(objId),fieldTypeMap);
                        System.debug('***'+objectIdToNewContent);
                    }
                }
            }
            return content;
            
        }
        catch(Exception ex)
        {
            system.debug('Exception ****'+ex);
            return null;
        }
        
    }
    
    /*Gets field value from given fieldname and Sobject*/
    public static Object getFieldValue(SObject entity, String fieldName)
    {  
        try
        {
            if(entity == null)
            {
                return null;
            }
            
            if(fieldName.contains('.'))
            {
                return getFieldValue(entity.getSObject(fieldName.substringBefore('.')), fieldName.substringAfter('.'));
            }
            else
            {
                return entity.get(fieldName);
            }
        }
        catch(Exception ex)
        {
            system.debug('Exception ****'+ex);
            return null;
        }
    }
    
    /*Gets list of all fields of a given object*/
    public static Set<String> getFields(String content, String objectAPI)
    {
        try{
            
            Set<String> validFields = getAllFields(objectAPI);
            Set<String> fieldApis = new Set<String>();
            Matcher m = Pattern.compile('\\{!('+objectAPI+')\\.([a-zA-Z0-9_]*)(&&[T|D][1-4])*\\}').matcher(content);
            Set<String> matchFields = new Set<String>();
            while(m.find())
            {  
                String merge_field = m.group(2);
                system.debug('merge_field--'+merge_field);
                String template_field=merge_field.toLowerCase();
                if(validFields.contains(template_field))
                    fieldApis.add(merge_field);
            }
            return fieldApis;
        }
        catch(Exception ex)
        {
            system.debug('Exception ****'+ex);
            return null;
        }
    }
    
    /*Replaces  MergeFields in content with obtained values in map*/
    private static String match(String content, Map<String, String> obj, String objectAPI,Map<String,String>fieldtypes)
    {
        try
        {
            Matcher m = Pattern.compile('\\{!('+objectAPI+')\\.([a-zA-Z0-9_]*)(&&[T|D][1-4])*\\}').matcher(content);
            Set<String> matchFields = new Set<String>();
            while(m.find())
            {
                String merge_field = (String)m.group(0);
                String field = (String)m.group(2);
                
                String value;
                System.debug('field$$$'+field);
                try
                {  
                    if(fieldtypes.get(field)=='ADDRESS')
                    {
                        value= getModifiedAddressValue((String)obj.get(field));
                    }
                    //fix for billing street
                    else if(field=='BillingStreet')
                    {
                        value = (String)obj.get(field);
                        value= value.unescapeJava();
                        value = value.substringBefore('\n');
                        value= value.left(80);
                        value=value.normalizeSpace();
                        
                    }
                    else
                    {
                        value = (String)obj.get(field);
                        
                    }
                }
                catch(Exception e)
                {
                    value = '';
                }
                if(value != null)
                {
                    content = content.replace(merge_field, value);
                    
                }
                else
                {
                    content = content.replace(merge_field, '');
                }
            }
            System.debug('content'+content);
            return content;
        }
        catch(Exception ex)
        {
            system.debug('Exception ****'+ex);
            return null;
        }
        
    }
    
    private static Set<String> getAllFields(string objectApiName)
    {
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
        Set<String>fieldList=new Set<String>();
        fieldList = new Set<String>(objectFields.keySet());
        return fieldList;
    }
    
    
    private static Map<String,string> getFieldTypes(string objectApiName,set<string> fieldSet)
        
    {
        Map<String, Schema.SObjectField>fieldMap;
        Map<String,string> objectTypeMap = new    Map<String,string>();
        fieldMap = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
        for(string field : fieldSet)
        {
            Schema.SObjectField fieldName = fieldMap.get(field);
            Schema.DisplayType FldType = fieldName.getDescribe().getType();
            objectTypeMap.put(field, String.valueOf(FldType));
            
        }
        return objectTypeMap;
    }
   
    private static string getModifiedAddressValue(string stringAddress)        
    {
        
        
        string    jsonFormattedAddress;
        // gets the keys from  square brackets
        jsonFormattedAddress =stringAddress.substring( stringAddress.indexOf('[')+1,stringAddress.indexOf(']'));
        
        //map for each element in address eg state, city pincode
        Map<string,string>addressMap= new  Map<string,string>();
        //each pair is split using ;
        for (string keyValuePair :jsonFormattedAddress.split(';') )
        {  
            //each pair is again split by = (format is key=value)
            string keyToken;
            string valueToken;
            integer swapper=0;
            
            for(string pairToken:keyValuePair.split('='))
            {
                if(swapper==0)
                {
                    keyToken=pairToken;
                    swapper=1;
                }
                else
                {
                    valueToken=pairToken;
                    if(valueToken==null)
                    {
                        valueToken='';
                    }
                    swapper=0;
                }
                
            }addressMap.put(keyToken, valueToken);
        }
        string formattedAddress=addressMap.get('getStreet')+', /n '+addressMap.get('getCity')+' '+addressMap.get('getState')+addressMap.get('getPostalCode');
        
        return formattedAddress;
    }
    
    /*Identifies the type of object and its Api value from recordID*/
    public static String getObjectAPI(String recordId)
    {
        try
        {
            
            List<Schema.SObjectType> gd = Schema.getGlobalDescribe().Values();
            
            Map<String,String> objectMap = new Map<String,String>();
            for(Schema.SObjectType f : gd)
            {
                objectMap.put(f.getDescribe().getKeyPrefix(),f.getDescribe().getName());
            }
            
            String prefix = recordId.substring(0,3);
            String objectName = objectMap.get(prefix);
            if(objectName!=null)
                return objectName;
            else
                return null;    
            
        }
        catch(Exception ex)
        {
            system.debug('Exception ****'+ex);
            return null;
        }
    }
}