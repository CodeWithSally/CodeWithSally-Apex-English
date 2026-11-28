@IsTest
private class AccountNamePrefixerTest {
    @IsTest
    static void prefixesNameOnInsert() {
        Account acc = new Account(Name = 'Acme');
        insert acc;
        Assert.areEqual('PENDING REVIEW: Acme', [SELECT Name FROM Account WHERE Id = :acc.Id].Name);
    }

    @IsTest
    static void prefixesEveryAccountInBulkInsert() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(Name = 'Bulk ' + i));
        }
        insert accounts;
        Map<Id, Account> saved = new Map<Id, Account>([SELECT Name FROM Account WHERE Id IN :accounts]);
        Assert.areEqual(200, saved.size());
        for (Integer i = 0; i < 200; i++) {
            Assert.areEqual('PENDING REVIEW: Bulk ' + i, saved.get(accounts[i].Id).Name);
        }
    }

    @IsTest
    static void doesNotDoublePrefix() {
        Account acc = new Account(Name = 'PENDING REVIEW: Acme');
        insert acc;
        Assert.areEqual('PENDING REVIEW: Acme', [SELECT Name FROM Account WHERE Id = :acc.Id].Name);
    }

    @IsTest
    static void doesNotPrefixOnUpdate() {
        Account acc = new Account(Name = 'Acme');
        insert acc;
        acc.Name = 'Renamed';
        update acc;
        Assert.areEqual('Renamed', [SELECT Name FROM Account WHERE Id = :acc.Id].Name);
    }

    @IsTest
    static void truncatesToMaxNameLength() {
        Account acc = new Account(Name = 'x'.repeat(255));
        insert acc;
        Assert.areEqual('PENDING REVIEW: ' + 'x'.repeat(239), [SELECT Name FROM Account WHERE Id = :acc.Id].Name);
    }
}
