public with sharing class CalcHistoryController {
    @AuraEnabled
    public static Id createRecord(Decimal number1, Decimal number2, String operation, Decimal answer) {
        Calc_History__c rec = new Calc_History__c(
            Number_1__c = number1,
            Number_2__c = number2,
            Operation__c = operation,
            Answer__c = answer
        );
        insert rec;
        return rec.Id;
    }
}