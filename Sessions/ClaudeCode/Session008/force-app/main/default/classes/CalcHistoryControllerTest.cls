@IsTest
private class CalcHistoryControllerTest {
    @IsTest
    static void createRecordSavesAllFields() {
        Test.startTest();
        Id recordId = CalcHistoryController.createRecord(2, 3, 'Add', 5);
        Test.stopTest();

        Assert.isNotNull(recordId, 'createRecord should return the new record Id');

        Calc_History__c rec = [
            SELECT Number_1__c, Number_2__c, Operation__c, Answer__c, Calculated_At__c
            FROM Calc_History__c
            WHERE Id = :recordId
        ];
        Assert.areEqual(2, rec.Number_1__c, 'Number 1 should be saved');
        Assert.areEqual(3, rec.Number_2__c, 'Number 2 should be saved');
        Assert.areEqual('Add', rec.Operation__c, 'Operation should be saved');
        Assert.areEqual(5, rec.Answer__c, 'Answer should be saved');
        Assert.isNotNull(rec.Calculated_At__c, 'Calculated At should default to now');
    }

    @IsTest
    static void createRecordAcceptsEveryOperation() {
        Map<String, Decimal> answersByOperation = new Map<String, Decimal>{
            'Add' => 14,
            'Subtract' => 6,
            'Multiply' => 40,
            'Divide' => 2.5
        };

        Test.startTest();
        for (String operation : answersByOperation.keySet()) {
            CalcHistoryController.createRecord(10, 4, operation, answersByOperation.get(operation));
        }
        Test.stopTest();

        List<Calc_History__c> recs = [SELECT Operation__c, Answer__c FROM Calc_History__c];
        Assert.areEqual(4, recs.size(), 'One record should be saved per operation');
        for (Calc_History__c rec : recs) {
            Assert.areEqual(
                answersByOperation.get(rec.Operation__c),
                rec.Answer__c,
                'Answer should match for ' + rec.Operation__c
            );
        }
    }

    @IsTest
    static void createRecordSavesDecimalsAndNegatives() {
        Test.startTest();
        Id recordId = CalcHistoryController.createRecord(-1.25, 3.5, 'Subtract', -4.75);
        Test.stopTest();

        Calc_History__c rec = [
            SELECT Number_1__c, Number_2__c, Answer__c
            FROM Calc_History__c
            WHERE Id = :recordId
        ];
        Assert.areEqual(-1.25, rec.Number_1__c, 'Negative decimal Number 1 should be saved');
        Assert.areEqual(3.5, rec.Number_2__c, 'Decimal Number 2 should be saved');
        Assert.areEqual(-4.75, rec.Answer__c, 'Negative decimal Answer should be saved');
    }

    @IsTest
    static void createRecordRejectsUnknownOperation() {
        Test.startTest();
        try {
            CalcHistoryController.createRecord(2, 3, 'Modulo', 2);
            Assert.fail('An operation outside the restricted picklist should be rejected');
        } catch (DmlException e) {
            Assert.areEqual(
                StatusCode.INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST,
                e.getDmlType(0),
                'Error should be the restricted picklist error'
            );
        }
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Calc_History__c], 'No record should be saved');
    }

    @IsTest
    static void createRecordRejectsMissingRequiredValues() {
        Test.startTest();
        try {
            CalcHistoryController.createRecord(2, null, 'Add', null);
            Assert.fail('Missing required numbers should be rejected');
        } catch (DmlException e) {
            Assert.areEqual(
                StatusCode.REQUIRED_FIELD_MISSING,
                e.getDmlType(0),
                'Error should be the required field error'
            );
        }
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Calc_History__c], 'No record should be saved');
    }
}
