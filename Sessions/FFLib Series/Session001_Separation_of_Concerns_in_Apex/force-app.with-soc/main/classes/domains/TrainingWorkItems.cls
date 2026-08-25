/**
 * Domain for TrainingWorkItem__c that calculates training cost and builds invoice DTOs.
 * Implements {@link InvoicingService.ISupportInvoicing} for polymorphic invoicing.
 */
public virtual inherited sharing class TrainingWorkItems extends AbstractChargeable
	implements InvoicingService.ISupportInvoicing {

	@TestVisible
	private static TrainingWorkItems mock;

	/**
	 * Factory that wraps the given training work items, or {@link #mock} when tests have set one.
	 * @param recordList Training work items to manage. Null is treated as an empty list.
	 * @return {@link TrainingWorkItems} instance.
	 */
	public static TrainingWorkItems newInstance(List<TrainingWorkItem__c> recordList) {
		return mock != null ? mock : new TrainingWorkItems(recordList);
	}

	/**
	 * Creates a domain wrapping the given training work items.
	 * @param workItems Training work items to manage. Null is treated as an empty list.
	 */
	public TrainingWorkItems(List<TrainingWorkItem__c> workItems) {
		super(workItems);
	}

	/**
	 * Returns the field that stores calculated training cost.
	 * @return {@code TrainingWorkItem__c.TrainingCost__c}.
	 */
	public override Schema.SObjectField getCostOfHoursWorkedField() {
		return TrainingWorkItem__c.TrainingCost__c;
	}

	/**
	 * Sums delivery and preparation hours for each work item; null hour fields count as zero.
	 * @return Hours worked per record in domain order.
	 */
	public override List<Integer> calculateHoursWorked() {
		List<Integer> hoursWorked = new List<Integer>();
		for (TrainingWorkItem__c wi : (List<TrainingWorkItem__c>) records) {
			Decimal d =
				(wi.DeliveryHours__c != null ? wi.DeliveryHours__c : 0) +
				(wi.PreparationHours__c != null ? wi.PreparationHours__c : 0);
			hoursWorked.add(d.intValue());
		}
		return hoursWorked;
	}

	/**
	 * Adds one invoice per work item that has a related Work Order account.
	 * Unit price comes from TrainingCost__c; work items without an account are skipped.
	 * @param invoiceFactory Factory that collects invoice headers and lines. Cannot be null.
	 */
	public virtual void generate(InvoicingService.InvoiceFactory invoiceFactory) {
		for (TrainingWorkItem__c wi : (List<TrainingWorkItem__c>) getRecords()) {
			Id accountId = wi.WorkOrder__r != null ? wi.WorkOrder__r.Account__c : null;
			if (accountId == null) {
				continue;
			}
			InvoicingService.Invoice invoice = new InvoicingService.Invoice();
			invoice.Account = accountId;
			invoice.Description = 'Training: ' + (wi.Name != null ? wi.Name : 'Work Item');
			invoice.InvoiceDate = Date.today();
			InvoicingService.InvoiceLine line = new InvoicingService.InvoiceLine();
			line.Description = 'Training delivery';
			line.Product = null;
			line.UnitPrice = wi.TrainingCost__c != null ? wi.TrainingCost__c : 0;
			line.Quantity = 1;
			invoice.Lines = new List<InvoicingService.InvoiceLine>{ line };
			invoiceFactory.add(invoice);
		}
	}
}
