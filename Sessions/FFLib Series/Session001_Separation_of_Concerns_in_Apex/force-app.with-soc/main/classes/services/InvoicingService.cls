/**
 * Polymorphic invoicing service that generates invoices from registered source SObject types
 * via {@link InvoicingTargetsRegistry} and domains implementing {@link ISupportInvoicing}.
 */
public inherited sharing class InvoicingService {
	@TestVisible
	private static InvoicingService mock;

	/**
	 * Factory that returns this service, or {@link #mock} when tests have set one.
	 * @return {@link InvoicingService} instance.
	 */
	public static InvoicingService newInstance() {
		return mock != null ? mock : new InvoicingService();
	}

	/**
	 * Contract for domains that can contribute invoices to an {@link InvoiceFactory}.
	 */
	public interface ISupportInvoicing {
		/**
		 * Adds invoice DTOs for the domain's records to the factory.
		 * @param invoiceFactory Factory that collects invoice headers and lines. Cannot be null.
		 */
		void generate(InvoiceFactory invoiceFactory);
	}

	/**
	 * Collects invoice headers and lines in memory; the service inserts them.
	 */
	public class InvoiceFactory {
		/**
		 * Invoice__c headers accumulated so far; Ids are set after insert.
		 */
		public List<Invoice__c> Invoices { get; private set; }
		private List<List<InvoiceLine__c>> linesByInvoice = new List<List<InvoiceLine__c>>();

		/**
		 * Creates an empty factory ready to accept {@link Invoice} DTOs.
		 */
		public InvoiceFactory() {
			this.Invoices = new List<Invoice__c>();
		}

		/**
		 * Converts an {@link Invoice} DTO into Invoice__c / InvoiceLine__c rows held in memory.
		 * @param invoice Invoice header and optional lines to add. Cannot be null.
		 */
		public void add(Invoice invoice) {
			Invoice__c invoiceRecord = new Invoice__c();
			invoiceRecord.Account__c = invoice.Account;
			invoiceRecord.Description__c = invoice.Description;
			invoiceRecord.InvoiceDate__c = invoice.InvoiceDate;
			Invoices.add(invoiceRecord);

			List<InvoiceLine__c> lines = new List<InvoiceLine__c>();
			if (invoice.Lines != null) {
				for (InvoiceLine line : invoice.Lines) {
					InvoiceLine__c invoiceLineItem = new InvoiceLine__c();
					invoiceLineItem.Description__c = line.Description;
					invoiceLineItem.Product__c = line.Product;
					invoiceLineItem.UnitPrice__c = line.UnitPrice;
					invoiceLineItem.Quantity__c = line.Quantity;
					lines.add(invoiceLineItem);
				}
			}
			linesByInvoice.add(lines);
		}

		/**
		 * Stamps parent Invoice__c Ids onto accumulated lines after headers have been inserted.
		 * @return Flat list of InvoiceLine__c ready to insert; empty when there are no lines.
		 */
		public List<InvoiceLine__c> buildLinesWithInvoiceIds() {
			List<InvoiceLine__c> allLines = new List<InvoiceLine__c>();
			for (Integer i = 0; i < Invoices.size(); i++) {
				for (InvoiceLine__c line : linesByInvoice[i]) {
					line.Invoice__c = Invoices[i].Id;
					allLines.add(line);
				}
			}
			return allLines;
		}
	}

	/**
	 * In-memory invoice header used by domains before persistence.
	 */
	public class Invoice {
		/**
		 * Invoice line DTOs for this header.
		 */
		public List<InvoiceLine> Lines { get; set; }
		/**
		 * Account Id for Invoice__c.Account__c.
		 */
		public Id Account { get; set; }
		/**
		 * Description for Invoice__c.Description__c.
		 */
		public String Description { get; set; }
		/**
		 * Invoice date for Invoice__c.InvoiceDate__c.
		 */
		public Date InvoiceDate { get; set; }
	}

	/**
	 * In-memory invoice line used by domains before persistence.
	 */
	public class InvoiceLine {
		/**
		 * Line description for InvoiceLine__c.Description__c.
		 */
		public String Description { get; set; }
		/**
		 * Product Id for InvoiceLine__c.Product__c; may be null.
		 */
		public Id Product { get; set; }
		/**
		 * Unit price for InvoiceLine__c.UnitPrice__c.
		 */
		public Decimal UnitPrice { get; set; }
		/**
		 * Quantity for InvoiceLine__c.Quantity__c.
		 */
		public Decimal Quantity { get; set; }
	}

	/**
	 * Loads source records via {@link InvoicingTargetsRegistry}, asks the domain to generate invoices,
	 * and inserts Invoice__c / InvoiceLine__c.
	 * @param sourceRecordIds Homogeneous Ids of registered invoice source records. Cannot be null.
	 * @return Ids of inserted Invoice__c records; empty list when none were created.
	 * @throws InvoicingException When the source type is invalid, DML fails, or another unexpected error occurs; transaction is rolled back.
	 */
	public List<Id> generate(List<Id> sourceRecordIds) {
		Savepoint sp = Database.setSavepoint();
		try {
			InvoiceFactory invoiceFactory = new InvoiceFactory();
			List<SObject> records = InvoicingTargetsRegistry.selectById(new Set<Id>(sourceRecordIds));
			Object domain = InvoicingTargetsRegistry.newDomain(records);
			if (!(domain instanceof ISupportInvoicing)) {
				throw new InvoicingException('Invalid source object for generating invoices.');
			}

			((ISupportInvoicing) domain).generate(invoiceFactory);

			if (!invoiceFactory.Invoices.isEmpty()) {
				Database.insert(invoiceFactory.Invoices);
			}
			List<InvoiceLine__c> lines = invoiceFactory.buildLinesWithInvoiceIds();
			if (!lines.isEmpty()) {
				Database.insert(lines);
			}

			List<Id> invoiceIds = new List<Id>();
			for (Invoice__c invoice : invoiceFactory.Invoices) {
				invoiceIds.add(invoice.Id);
			}
			return invoiceIds;
		} catch (InvoicingException e) {
			Database.rollback(sp);
			throw e;
		} catch (DmlException e) {
			Database.rollback(sp);
			throw new InvoicingException('Error generating invoices: ' + e.getDmlMessage(0), e);
		} catch (Exception e) {
			Database.rollback(sp);
			throw new InvoicingException(e.getMessage(), e);
		}
	}

	/**
	 * Represents an exception thrown by {@link InvoicingService} operations.
	 */
	public class InvoicingException extends Exception {
	}
}
