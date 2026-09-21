/**
 * Integration tests for ProductsSelector field set support.
 */
@IsTest
private class ProductsSelectorTest {
	@TestSetup
	static void setup() {
		// Given a run-as user with sample app permissions
		TestDataFactory.createUserWithSampleAppPermissions();
	}

	@IsTest
	private static void selectByIdReturnsExpectedFields() {
		// Given an active product with subscriber field data
		Product2 product = new Product2(
			Description = 'Something cool',
			Name = 'CoolItem',
			IsActive = true,
			SubscriberField__c = 'My Text Field'
		);
		insert product;

		System.runAs(TestDataFactory.getRunAsUser()) {
			// When the product is selected by id
			Test.startTest();
			List<Product2> products = ProductsSelector.newInstance(true).selectById(new Set<Id>{ product.Id });
			Test.stopTest();

			// Then expected product fields are returned
			System.assertEquals('Something cool', products[0].Description, 'Description should match');
			System.assertEquals('CoolItem', products[0].Name, 'Name should match');
			System.assertEquals(true, products[0].IsActive, 'IsActive should be true');
			System.assertEquals('My Text Field', products[0].SubscriberField__c, 'SubscriberField should match');
		}
	}

	@IsTest
	private static void queryLocatorByIdReturnsExpectedFields() {
		// Given an active product with subscriber field data
		Product2 product = new Product2(
			Description = 'Something cool',
			Name = 'CoolItem',
			IsActive = true,
			SubscriberField__c = 'My Text Field'
		);
		insert product;

		System.runAs(TestDataFactory.getRunAsUser()) {
			// When products are queried through a query locator
			Test.startTest();
			Database.QueryLocator queryLocator = ProductsSelector.newInstance(true)
				.queryLocatorById(new Set<Id>{ product.Id });
			Database.QueryLocatorIterator productsIterator = queryLocator.iterator();
			Product2 queriedProduct = (Product2) productsIterator.next();
			Test.stopTest();

			// Then expected product fields are returned
			System.assertEquals('Something cool', queriedProduct.Description, 'Description should match');
			System.assertEquals('CoolItem', queriedProduct.Name, 'Name should match');
			System.assertEquals(true, queriedProduct.IsActive, 'IsActive should be true');
			System.assertEquals('My Text Field', queriedProduct.SubscriberField__c, 'SubscriberField should match');
		}
	}
}
