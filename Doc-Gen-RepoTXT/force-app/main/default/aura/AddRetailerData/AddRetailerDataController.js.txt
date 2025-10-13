({
    
    doInit : function(cmp, event, helper)
    {
        
        //alert('Inside AddRetailerData doInit>>>');
       console.log('Inside AddRetailerData depnedentFieldMap is>>>'+JSON.stringify(cmp.get("v.depnedentFieldMap")));
        console.log('Inside AddRetailerData  SubDepnedentFieldMap is>>>'+JSON.stringify(cmp.get("v.SubDepnedentFieldMap")));
        var depnedentFieldMap = cmp.get("v.depnedentFieldMap");
        var IndRetailerData = cmp.get("v.IndRetailerData");
       console.log('IndRetailerData.Id>>>#'+JSON.stringify(IndRetailerData));
        if(IndRetailerData.Id != undefined)
        {
            //alert('IndRetailerData.Id not emptey');
            //alert('AddRetailerData IndRetailerData is:'+IndRetailerData +' and  Retailer Code is>>'+IndRetailerData.Retailer_Code__r.Name);
            //alert('AddRetailerData IndRetailerData is:'+IndRetailerData +' and  Retailer Name is>>'+IndRetailerData.Retailer_Code_Name__c);
            IndRetailerData.Retailer_Code_Name__c = IndRetailerData.Retailer_Code__r.Name;
            var ListOfDependentFields = depnedentFieldMap[IndRetailerData.Retailer_Code_Name__c];
            var dependentFields = [];
            dependentFields.push('--- None ---');
            for (var i = 0; i < ListOfDependentFields.length; i++) {
                dependentFields.push(ListOfDependentFields[i]);
            }
            cmp.set("v.listDependingValues", dependentFields);
            
            var SubDepnedentFieldMap = cmp.get("v.SubDepnedentFieldMap");
            if(IndRetailerData.Order_to_Company__c != undefined)
            {
                //alert('IndRetailerData.Order_to_Company__c>>'+IndRetailerData.Order_to_Company__c);
                if(IndRetailerData.Order_to_Company__c != '--- None ---') 
                {
                    var ListOfDependentFields = SubDepnedentFieldMap[IndRetailerData.Order_to_Company__c];
                    //alert('ListOfDependentFields>>'+ListOfDependentFields);
                    //alert('ListOfDependentFields.length>>'+ListOfDependentFields.length);
                    if(ListOfDependentFields.length > 0){
                        //alert('Inside ListOfDependentFields.length is > 0');
                        //cmp.set("v.bDisabledPreferredCurrency" , false); 
                        //cmp.set("v.GetInitDetailsWrapper.DefaultPreferredCurrency",'');
                        helper.fetchDepPreferredCurrencyValues(cmp, ListOfDependentFields);    
                    }
                }
            }
        }
        
        
        
        
    },
    
    onChangeOrdeToCompany: function (component, event, helper) {
        var IndRetailerData = component.get("v.IndRetailerData");
        var selectedOrderToCompany = IndRetailerData.Order_to_Company__c;
        // alert('Inside onChangeOrdeToCompany selectedOrderToCompany>>>'+selectedOrderToCompany);
        var SubDepnedentFieldMap = component.get("v.SubDepnedentFieldMap");
        if (selectedOrderToCompany != '--- None ---') 
        {
            //alert('Inside main if');
            var ListOfDependentFields = SubDepnedentFieldMap[selectedOrderToCompany];
            //alert('ListOfDependentFields>>'+ListOfDependentFields);
            //alert('ListOfDependentFields.length>>'+ListOfDependentFields.length);
            if(ListOfDependentFields.length > 0){
                //alert('Inside ListOfDependentFields.length is > 0');
                component.set("v.bDisabledPreferredCurrency" , false); 
                component.set("v.GetInitDetailsWrapper.DefaultPreferredCurrency",'');
            	component.set("v.IndRetailerData.Preferred_Currency__c" , '--- None ---'); 
                helper.fetchDepPreferredCurrencyValues(component, ListOfDependentFields);    
            }
            else
            {
                component.set("v.bDisabledPreferredCurrency" , true); 
               
                component.set("v.listPreferredCurrencyDependingValues", ['--- None ---']);
            }  
            
        } 
        else 
        {
            //alert('Inside main else');
            component.set("v.listPreferredCurrencyDependingValues", ['--- None ---']);
            component.set("v.bDisabledPreferredCurrency" , true);
        }	
        console.log('IndRetailerData.Retailer_Code__c', IndRetailerData.Retailer_Code__c);
    },
    
    onChangePreferredCurrency: function (component, event, helper) {
        var IndRetailerData = component.get("v.IndRetailerData");
        var selectedOrderToCompany = IndRetailerData.Preferred_Currency__c;
        var selectedPreferredCurrency = event.getSource().get("v.value");
        //alert('selectedPreferredCurrency>>>'+selectedPreferredCurrency);
        console.log('IndRetailerData.Retailer_Code__c', IndRetailerData.Retailer_Code__c);
    },
    
    
    DeleteIndividualRetailerRow : function(component, event, helper)
    {
        var RecordtoDelete = component.get('v.IndRetailerData.Retailer_Code__c');
        if(RecordtoDelete)
        {
            //alert('RecordtoDelete>>'+RecordtoDelete);
            var idListStr=component.get('v.idListStr');
            idListStr = idListStr.replace(RecordtoDelete, "");
            component.set('v.idListStr',idListStr);
            
        }
        
        var cmpEvent = component.getEvent("ModifyRetailerdata");
        cmpEvent.setParams({
            "rowIndex" : component.get('v.rowIndex') ,
            "flag" : "DeleteIndividualRetailer",
            //"RecordID" : component.get('v.IndRetailerData.Retailer_Code__c')
        });
        
        cmpEvent.fire();
    },
    
    handleLookupValueselected:function (component, event, helper)
    {
        
        var SelectedLookupValue = component.get('v.IndRetailerData.Retailer_Code__c');
        console.log('IndRetailerData.Retailer_Code***'+JSON.stringify(component.get('v.IndRetailerData')));
        alert('SelectedLookupValue>>'+SelectedLookupValue +' and Name is >>'+component.get('v.IndRetailerData.Retailer_Code__r.Name'));
        var IndRetailerData = component.get('v.IndRetailerData');
        //alert('IndRetailer Name is >>'+IndRetailerData.Retailer_Code__r.Name);
        
        if(component.get('v.IndRetailerData.Retailer_Code_Name__c') != null)
        {
            
            //alert('Inside IndRetailer Name is not empty >'+component.get('v.IndRetailerData.Retailer_Code__r.Name'));
            var depnedentFieldMap = component.get("v.depnedentFieldMap");
            //alert('depnedentFieldMap>>'+JSON.stringify(depnedentFieldMap) +' Length is'+depnedentFieldMap.length);
            //var ListOfDependentFields = depnedentFieldMap[IndRetailerData.Retailer_Code__r.Name];
            var ListOfDependentFields = depnedentFieldMap[IndRetailerData.Retailer_Code_Name__c];
            
            var dependentFields = [];
            dependentFields.push('--- None ---');
            for (var i = 0; i < ListOfDependentFields.length; i++) {
                dependentFields.push(ListOfDependentFields[i]);
            }
            component.set("v.listDependingValues", dependentFields); 
            //alert('After Setting listDependingValues>>>'+JSON.stringify(component.get("v.listDependingValues")));
        }
        var idListStr=component.get('v.idListStr');
        if(!idListStr)
            idListStr=component.get('v.IndRetailerData.Retailer_Code__c');
        else
            idListStr+='\',\''+component.get('v.IndRetailerData.Retailer_Code__c');
        component.set('v.idListStr',idListStr);
        //alert('idListStr>>'+component.get('v.idListStr'));
        
    },
    
    
    ClearLookupValue: function (component, event, helper) 
    {
        
        //alert('Inside ClearLookupValue idListStr>>'+JSON.stringify(event.getParam('data')));
        var Data = event.getParam('data');
        var ObjectAPI = Data.ObjectAPI;
        var flag = event.getParam('flag');
        var ClearedRecordID = Data.ClearedRecordID;
        //alert('Inside ClearLookupValue ObjectAPI>>'+ObjectAPI +' flag'+flag +' ClearedRecordID'+ClearedRecordID);
        
        if(flag=='ClearLookup')
        {
            //alert('Inside  ClearedLookupValue>>'+ClearedLookupValue);
            var idListStr=component.get('v.idListStr');
            if(idListStr)
                idListStr = idListStr.replace(ClearedRecordID, "");
            component.set('v.idListStr',idListStr);
            //alert('Inside ClearLookupValue idListStr>>'+component.get('v.idListStr'));
        }
        
        
        
    },  
    
})