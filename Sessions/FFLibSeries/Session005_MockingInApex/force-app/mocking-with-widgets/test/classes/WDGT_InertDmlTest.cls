/**
 * Unit tests for {@link WDGT_InertDml}: fake Ids on insert, so registered relationships resolve, and per-type views.
 * Uses standard Account and Contact because Widgets have no relationships; nothing is saved.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs') // unit test: inert DML, nothing saved
private class WDGT_InertDmlTest {
	@IsTest
	private static void dmlInsert_WHEN_parentAndChildCommitted_EXPECT_childLinkedToFakeParentId() {
		// Given a Unit of Work over the inert DML, with an Account and a Contact related to it
		WDGT_InertDml inertDml = new WDGT_InertDml();
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType>{ Account.SObjectType, Contact.SObjectType },
			inertDml
		);
		Account acme = new Account(Name = 'Acme');
		Contact coyote = new Contact(LastName = 'Coyote');
		uow.registerNew(acme);
		uow.registerNew(coyote, Contact.AccountId, acme);

		// When the work is committed
		uow.commitWork();

		// Then the parent has a fake Id and the child is linked to it
		Assert.isNotNull(acme.Id, 'The Account should get a fake Id');
		Assert.areEqual(Account.SObjectType, acme.Id.getSObjectType(), 'The fake Id should be an Account Id');
		Assert.areEqual(acme.Id, coyote.AccountId, 'The Contact should be linked to the Account');
	}

	@IsTest
	private static void getInserted_WHEN_twoTypesCommitted_EXPECT_recordsByTypeInCommitOrder() {
		// Given a Unit of Work over the inert DML, with two Accounts and one Contact
		WDGT_InertDml inertDml = new WDGT_InertDml();
		fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
			new List<SObjectType>{ Account.SObjectType, Contact.SObjectType },
			inertDml
		);
		uow.registerNew(new Contact(LastName = 'Coyote'));
		uow.registerNew(new Account(Name = 'Acme'));
		uow.registerNew(new Account(Name = 'Roadrunner Inc'));

		// When the work is committed
		uow.commitWork();

		// Then each type can be pulled on its own, and the flat list keeps the Unit of Work's type order
		Assert.areEqual(2, inertDml.getInserted(Account.SObjectType).size(), 'Two Accounts');
		Assert.areEqual(1, inertDml.getInserted(Contact.SObjectType).size(), 'One Contact');
		Assert.areEqual(Account.SObjectType, inertDml.inserted[0].getSObjectType(), 'Accounts are inserted first');
		Assert.areEqual(Contact.SObjectType, inertDml.inserted[2].getSObjectType(), 'Contacts are inserted after');
	}
}
