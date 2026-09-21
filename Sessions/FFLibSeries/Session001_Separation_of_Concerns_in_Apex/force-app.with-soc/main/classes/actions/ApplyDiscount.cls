/**
 * Invocable action that applies a percentage discount to an Opportunity.
 * Delegates to {@link OpportunitiesService}.
 */
public inherited sharing class ApplyDiscount {
	/**
	 * Applies a discount for each request via {@link OpportunitiesService#applyDiscounts}.
	 * @param requests Opportunity Id and discount percent per request. Cannot be null.
	 * @return Opportunity Ids in the same order as {@code requests}.
	 */
	@InvocableMethod(
		label='Apply Discount'
		description='Applies a percentage discount to an Opportunity and its discountable products.'
		category='Opportunities'
	)
	public static List<Result> execute(List<Request> requests) {
		List<Result> results = new List<Result>();
		for (Request request : requests) {
			OpportunitiesService.newInstance().applyDiscounts(
				new Set<Id>{ request.opportunityId },
				request.discountPercentage
			);
			Result result = new Result();
			result.opportunityId = request.opportunityId;
			result.discountPercentage = request.discountPercentage;
			results.add(result);
		}
		return results;
	}

	/**
	 * Input for {@link #execute}.
	 */
	public class Request {
		/**
		 * Opportunity Id to discount.
		 */
		@InvocableVariable(label='Opportunity Id' required=true)
		public Id opportunityId;
		/**
		 * Discount percent to apply (for example 10 for 10%).
		 */
		@InvocableVariable(label='Discount Percentage' required=true)
		public Decimal discountPercentage;
	}

	/**
	 * Output for {@link #execute}.
	 */
	public class Result {
		/**
		 * Id of the discounted Opportunity.
		 */
		@InvocableVariable(label='Opportunity Id')
		public Id opportunityId;
		/**
		 * Discount percent that was applied.
		 */
		@InvocableVariable(label='Discount Percentage')
		public Decimal discountPercentage;
	}
}
