/**
 * Wizard to create an Opportunity from recently used line items on an Account.
 * Record quick action uses LWC; logic is duplicated in @AuraEnabled methods below.
 */
public inherited sharing class QuickOpportunityWizardController {
	/**
	 * Loads default Opportunity name and recently used line items for the Account Lightning action.
	 * @param accountId Account Id whose recent opportunity products are offered. Cannot be null.
	 * @return Wizard state with default name and selectable line items.
	 */
	@AuraEnabled(cacheable=false)
	public static WizardState getWizardData(Id accountId) {
		try {
			Account account = [SELECT Id, Name FROM Account WHERE Id = :accountId];
			WizardState wizardState = new WizardState();
			wizardState.opportunityName = account.Name;
			wizardState.selectLineItemList = new List<WizardLineItem>();

			List<OpportunityLineItem> lines = [
				SELECT
					Id,
					OpportunityId,
					Description,
					Quantity,
					UnitPrice,
					ListPrice,
					PricebookEntryId,
					SortOrder,
					PricebookEntry.Name,
					PricebookEntry.Product2Id,
					PricebookEntry.Product2.DiscountingApproved__c,
					PricebookEntry.Pricebook2.Name
				FROM OpportunityLineItem
				WHERE Opportunity.Account.Id = :account.Id
				ORDER BY SystemModstamp DESC
				LIMIT 10
			];

			Integer rowKey = 0;
			for (OpportunityLineItem item : lines) {
				WizardLineItem lineItem = new WizardLineItem();
				lineItem.key = String.valueOf(rowKey++);
				lineItem.selected = false;
				lineItem.productName = item.PricebookEntry.Name;
				lineItem.pricebookName = item.PricebookEntry.Pricebook2.Name;
				lineItem.description = item.Description;
				lineItem.listPrice = item.ListPrice;
				lineItem.unitPrice = item.UnitPrice;
				lineItem.quantity = item.Quantity;
				lineItem.pricebookEntryId = item.PricebookEntryId;
				wizardState.selectLineItemList.add(lineItem);
			}
			return wizardState;
		} catch (Exception e) {
			throw toAura(e);
		}
	}

	/**
	 * Inserts the Opportunity and selected line items, then returns the new Opportunity Id.
	 * @param accountId Account Id to own the Opportunity. Cannot be null.
	 * @param name Opportunity name.
	 * @param stageName Opportunity stage.
	 * @param closeDate Opportunity close date.
	 * @param selectLineItemList Line items from the wizard; only selected rows are inserted.
	 * @return Id of the inserted Opportunity.
	 */
	@AuraEnabled(cacheable=false)
	public static Id createOpportunity(
		Id accountId,
		String name,
		String stageName,
		Date closeDate,
		List<WizardLineItem> selectLineItemList
	) {
		try {
			Opportunity opportunity = new Opportunity();
			opportunity.Name = name;
			opportunity.AccountId = accountId;
			opportunity.StageName = stageName;
			opportunity.CloseDate = closeDate;
			opportunity.DiscountType__c = OpportunitySettings__c.getInstance().DiscountType__c;
			Database.insert(opportunity);

			List<OpportunityLineItem> lines = new List<OpportunityLineItem>();
			if (selectLineItemList != null) {
				for (WizardLineItem item : selectLineItemList) {
					if (item != null && item.selected == true) {
						lines.add(
							new OpportunityLineItem(
								OpportunityId = opportunity.Id,
								PricebookEntryId = item.pricebookEntryId,
								Description = item.description,
								Quantity = item.quantity,
								UnitPrice = item.unitPrice
							)
						);
					}
				}
			}
			if (!lines.isEmpty()) {
				Database.insert(lines);
			}
			return opportunity.Id;
		} catch (Exception e) {
			throw toAura(e);
		}
	}

	private static AuraHandledException toAura(Exception e) {
		AuraHandledException auraException = new AuraHandledException(e.getMessage());
		auraException.setMessage(e.getMessage());
		return auraException;
	}

	/**
	 * Holds wizard Opportunity defaults and selectable recent line items for the Lightning action.
	 */
	public class WizardState {
		/**
		 * Default Opportunity name, taken from the Account.
		 */
		@AuraEnabled
		public String opportunityName { get; set; }
		/**
		 * Recent line items the user may select to copy onto the new Opportunity.
		 */
		@AuraEnabled
		public List<WizardLineItem> selectLineItemList { get; set; }
	}

	/**
	 * Line item row for the Lightning wizard datatable.
	 */
	public class WizardLineItem {
		/**
		 * Client-side row key for the datatable.
		 */
		@AuraEnabled
		public String key { get; set; }
		/**
		 * Whether the user selected this line for the new Opportunity.
		 */
		@AuraEnabled
		public Boolean selected { get; set; }
		/**
		 * Product name from the price book entry.
		 */
		@AuraEnabled
		public String productName { get; set; }
		/**
		 * Price book name from the price book entry.
		 */
		@AuraEnabled
		public String pricebookName { get; set; }
		/**
		 * Line description to insert when selected.
		 */
		@AuraEnabled
		public String description { get; set; }
		/**
		 * List price shown read-only in the wizard.
		 */
		@AuraEnabled
		public Decimal listPrice { get; set; }
		/**
		 * Unit price to insert when selected.
		 */
		@AuraEnabled
		public Decimal unitPrice { get; set; }
		/**
		 * Quantity to insert when selected.
		 */
		@AuraEnabled
		public Decimal quantity { get; set; }
		/**
		 * Price book entry used when inserting the line.
		 */
		@AuraEnabled
		public Id pricebookEntryId { get; set; }
	}
}
