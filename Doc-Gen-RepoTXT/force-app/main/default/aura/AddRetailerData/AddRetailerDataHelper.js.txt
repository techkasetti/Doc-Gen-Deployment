({
	 fetchDepPreferredCurrencyValues:function(component, ListOfDependentFields) {
        
        //alert('Inside fetchDepPreferredCurrencyValues>>>'+ListOfDependentFields);
        var dependentFields = [];
        dependentFields.push('--- None ---');
        for (var i = 0; i < ListOfDependentFields.length; i++) {
            //alert('Inside For loop>>>'+ListOfDependentFields[i]);
            dependentFields.push(ListOfDependentFields[i]);
        }
        // set the dependentFields variable values to store(dependent picklist field) on lightning:select
        component.set("v.listPreferredCurrencyDependingValues", dependentFields);
        //alert('Final Values>>>'+ component.get("v.listPreferredCurrencyDependingValues"));
        
    },
    
})