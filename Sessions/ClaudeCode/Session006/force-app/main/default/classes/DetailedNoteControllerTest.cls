@IsTest
private class DetailedNoteControllerTest {

    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Case c = new Case(Subject = 'Test Case', AccountId = acc.Id);
        insert c;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        List<DetailedNote__c> notes = new List<DetailedNote__c>{
            new DetailedNote__c(Title__c = 'Case Note', Body__c = '<p>case body</p>', Case__c = c.Id),
            new DetailedNote__c(Title__c = 'Opp Note', Body__c = '<p>opp body</p>', Opportunity__c = opp.Id),
            new DetailedNote__c(Title__c = 'Account Note', Body__c = '<p>acc body</p>', Account__c = acc.Id)
        };
        insert notes;
    }

    @IsTest
    static void getNotes_case_returnsOnlyCaseNotes() {
        Case c = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        List<DetailedNoteController.NoteWrapper> result =
            DetailedNoteController.getNotes(c.Id, 'Case');
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Should return 1 case note');
        Assert.areEqual('Case Note', result[0].title);
        Assert.isNull(result[0].sourceLabel, 'Case notes have no source label');
    }

    @IsTest
    static void getNotes_opportunity_returnsOnlyOppNotes() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<DetailedNoteController.NoteWrapper> result =
            DetailedNoteController.getNotes(opp.Id, 'Opportunity');
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Should return 1 opportunity note');
        Assert.areEqual('Opp Note', result[0].title);
        Assert.isNull(result[0].sourceLabel, 'Opportunity notes have no source label');
    }

    @IsTest
    static void getNotes_account_returnsDirectAndRolledUpNotes() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<DetailedNoteController.NoteWrapper> result =
            DetailedNoteController.getNotes(acc.Id, 'Account');
        Test.stopTest();

        Assert.areEqual(3, result.size(), 'Should return account note + case note + opp note');

        Integer sourceLabelCount = 0;
        for (DetailedNoteController.NoteWrapper w : result) {
            if (w.sourceLabel != null) {
                sourceLabelCount++;
            }
        }
        Assert.areEqual(2, sourceLabelCount, 'Case and Opp notes should have source labels');
    }

    @IsTest
    static void getNotes_account_sourceLabelContainsRecordName() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<DetailedNoteController.NoteWrapper> result =
            DetailedNoteController.getNotes(acc.Id, 'Account');
        Test.stopTest();

        Boolean foundCaseLabel = false;
        Boolean foundOppLabel = false;
        for (DetailedNoteController.NoteWrapper w : result) {
            if (w.sourceLabel != null && w.sourceLabel.startsWith('Case:')) {
                foundCaseLabel = true;
            }
            if (w.sourceLabel != null && w.sourceLabel.startsWith('Opportunity:')) {
                foundOppLabel = true;
            }
        }
        Assert.isTrue(foundCaseLabel, 'Should have a Case source label');
        Assert.isTrue(foundOppLabel, 'Should have an Opportunity source label');
    }

    @IsTest
    static void saveNote_case_createsNoteWithCaseLookup() {
        Case c = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        DetailedNoteController.saveNote('New Title', '<p>new body</p>', c.Id, 'Case');
        Test.stopTest();

        List<DetailedNote__c> notes = [
            SELECT Id, Title__c, Body__c, Case__c, Account__c, Opportunity__c
            FROM DetailedNote__c
            WHERE Title__c = 'New Title'
        ];
        Assert.areEqual(1, notes.size(), 'Should have created one note');
        Assert.areEqual(c.Id, notes[0].Case__c, 'Case lookup should be set');
        Assert.isNull(notes[0].Account__c, 'Account lookup should be null');
        Assert.isNull(notes[0].Opportunity__c, 'Opportunity lookup should be null');
    }

    @IsTest
    static void saveNote_account_createsNoteWithAccountLookup() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        DetailedNoteController.saveNote('Account Title', '<p>body</p>', acc.Id, 'Account');
        Test.stopTest();

        List<DetailedNote__c> notes = [
            SELECT Id, Account__c
            FROM DetailedNote__c
            WHERE Title__c = 'Account Title'
        ];
        Assert.areEqual(1, notes.size());
        Assert.areEqual(acc.Id, notes[0].Account__c);
    }

    @IsTest
    static void saveNote_opportunity_createsNoteWithOpportunityLookup() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        DetailedNoteController.saveNote('Opp Title', '<p>body</p>', opp.Id, 'Opportunity');
        Test.stopTest();

        List<DetailedNote__c> notes = [
            SELECT Id, Opportunity__c
            FROM DetailedNote__c
            WHERE Title__c = 'Opp Title'
        ];
        Assert.areEqual(1, notes.size());
        Assert.areEqual(opp.Id, notes[0].Opportunity__c);
    }

    @IsTest
    static void updateNote_creator_succeeds() {
        DetailedNote__c note = [SELECT Id FROM DetailedNote__c WHERE Title__c = 'Case Note' LIMIT 1];

        Test.startTest();
        DetailedNoteController.updateNote(note.Id, 'Updated Title', '<p>updated</p>');
        Test.stopTest();

        DetailedNote__c updated = [SELECT Title__c, Body__c FROM DetailedNote__c WHERE Id = :note.Id];
        Assert.areEqual('Updated Title', updated.Title__c);
        Assert.areEqual('<p>updated</p>', updated.Body__c);
    }

    @IsTest
    static void updateNote_nonCreator_throwsException() {
        DetailedNote__c note = [SELECT Id FROM DetailedNote__c WHERE Title__c = 'Case Note' LIMIT 1];

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User otherUser = new User(
            FirstName = 'Other',
            LastName = 'User',
            Email = 'other@example.com',
            Username = 'other' + System.now().getTime() + '@example.com',
            Alias = 'other',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert otherUser;

        Test.startTest();
        System.runAs(otherUser) {
            try {
                DetailedNoteController.updateNote(note.Id, 'Hacked', '<p>x</p>');
                Assert.fail('Expected AuraHandledException');
            } catch (AuraHandledException e) {
                Assert.isTrue(
                    e.getMessage().contains('permission'),
                    'Exception message should mention permission'
                );
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void updateNote_userWithOverridePermission_succeeds() {
        DetailedNote__c note = [SELECT Id FROM DetailedNote__c WHERE Title__c = 'Case Note' LIMIT 1];

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User adminUser = new User(
            FirstName = 'Admin',
            LastName = 'Override',
            Email = 'adminoverride@example.com',
            Username = 'adminoverride' + System.now().getTime() + '@example.com',
            Alias = 'admov',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert adminUser;

        PermissionSet ps = new PermissionSet(Name = 'TestEditAllNotes', Label = 'Test Edit All Notes');
        insert ps;
        CustomPermission cp = [
            SELECT Id FROM CustomPermission
            WHERE DeveloperName = 'Edit_All_Detailed_Notes'
            LIMIT 1
        ];
        SetupEntityAccess sea = new SetupEntityAccess(ParentId = ps.Id, SetupEntityId = cp.Id);
        insert sea;
        insert new PermissionSetAssignment(AssigneeId = adminUser.Id, PermissionSetId = ps.Id);

        Test.startTest();
        System.runAs(adminUser) {
            DetailedNoteController.updateNote(note.Id, 'Admin Override Title', '<p>ok</p>');
        }
        Test.stopTest();

        DetailedNote__c updated = [SELECT Title__c FROM DetailedNote__c WHERE Id = :note.Id];
        Assert.areEqual('Admin Override Title', updated.Title__c);
    }

    @IsTest
    static void deleteNote_creator_succeeds() {
        DetailedNote__c note = [SELECT Id FROM DetailedNote__c WHERE Title__c = 'Opp Note' LIMIT 1];
        Id noteId = note.Id;

        Test.startTest();
        DetailedNoteController.deleteNote(noteId);
        Test.stopTest();

        Assert.areEqual(
            0,
            [SELECT COUNT() FROM DetailedNote__c WHERE Id = :noteId],
            'Note should be deleted'
        );
    }

    @IsTest
    static void deleteNote_nonCreator_throwsException() {
        DetailedNote__c note = [SELECT Id FROM DetailedNote__c WHERE Title__c = 'Opp Note' LIMIT 1];

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User otherUser = new User(
            FirstName = 'Del',
            LastName = 'Test',
            Email = 'deltest@example.com',
            Username = 'deltest' + System.now().getTime() + '@example.com',
            Alias = 'delt',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert otherUser;

        Test.startTest();
        System.runAs(otherUser) {
            try {
                DetailedNoteController.deleteNote(note.Id);
                Assert.fail('Expected AuraHandledException');
            } catch (AuraHandledException e) {
                Assert.isTrue(e.getMessage().contains('permission'));
            }
        }
        Test.stopTest();
    }
}
