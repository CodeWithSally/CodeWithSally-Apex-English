@IsTest
private class ContactNamePrefixerTest {
    @IsTest
    static void prefixesFirstNameOnInsert() {
        Contact c = new Contact(FirstName = 'John', LastName = 'Smith');
        insert c;

        Contact saved = [SELECT FirstName, LastName, Name FROM Contact WHERE Id = :c.Id];
        Assert.areEqual('NEW CONTACT: John', saved.FirstName);
        Assert.areEqual('Smith', saved.LastName);
        Assert.areEqual('NEW CONTACT: John Smith', saved.Name);
    }

    @IsTest
    static void prefixesLastNameWhenNoFirstName() {
        Contact c = new Contact(LastName = 'Smith');
        insert c;

        Contact saved = [SELECT FirstName, LastName, Name FROM Contact WHERE Id = :c.Id];
        Assert.isNull(saved.FirstName);
        Assert.areEqual('NEW CONTACT: Smith', saved.LastName);
        Assert.areEqual('NEW CONTACT: Smith', saved.Name);
    }

    @IsTest
    static void prefixesLastNameWhenFirstNameTooLong() {
        String longFirst = 'Abcdefghijklmnopqrstuvwxyzabcd'; // 30 chars; 43 with prefix
        Contact c = new Contact(FirstName = longFirst, LastName = 'Smith');
        insert c;

        Contact saved = [SELECT FirstName, LastName FROM Contact WHERE Id = :c.Id];
        Assert.areEqual(longFirst, saved.FirstName);
        Assert.areEqual('NEW CONTACT: Smith', saved.LastName);
    }

    @IsTest
    static void doesNotPrefixTwice() {
        Contact c = new Contact(FirstName = 'NEW CONTACT: John', LastName = 'Smith');
        insert c;

        Contact saved = [SELECT FirstName, LastName FROM Contact WHERE Id = :c.Id];
        Assert.areEqual('NEW CONTACT: John', saved.FirstName);
        Assert.areEqual('Smith', saved.LastName);
    }

    @IsTest
    static void doesNotPrefixOnUpdate() {
        Contact c = new Contact(FirstName = 'John', LastName = 'Smith');
        insert c;
        c.FirstName = 'Jane';
        update c;

        Contact saved = [SELECT FirstName, LastName FROM Contact WHERE Id = :c.Id];
        Assert.areEqual('Jane', saved.FirstName);
        Assert.areEqual('Smith', saved.LastName);
    }

    @IsTest
    static void prefixesEveryContactInBulkInsert() {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            contacts.add(new Contact(FirstName = 'First' + i, LastName = 'Last' + i));
        }
        insert contacts;

        for (Contact saved : [SELECT FirstName, LastName FROM Contact WHERE Id IN :contacts]) {
            String suffix = saved.LastName.removeStart('Last');
            Assert.areEqual('NEW CONTACT: First' + suffix, saved.FirstName);
        }
        Assert.areEqual(200, [SELECT COUNT() FROM Contact WHERE Id IN :contacts]);
    }
}
