/**
 * REST resource that applies a discount to a single Opportunity identified in the URL path.
 * Path pattern: {@code /opportunities/{id}/applydiscount} with optional {@code discount} query parameter.
 */
@RestResource(UrlMapping='/opportunities/*/applydiscount')
global inherited sharing class OpportunitiesResource {
	/**
	 * Applies a discount to the Opportunity Id in the request URI via {@link OpportunitiesService}.
	 * Reads the {@code discount} query parameter; defaults to zero when absent.
	 */
	@HttpPost
	global static void applyDiscount() {
		RestRequest req = RestContext.request;
		String[] uriParts = req.requestURI.split('/');
		Id opportunityId = uriParts[2];
		String discountParam = req.params.get('discount');
		Decimal discountPercent = discountParam != null ? Decimal.valueOf(discountParam) : 0;
		OpportunitiesService.newInstance().applyDiscounts(new Set<Id>{ opportunityId }, discountPercent);
	}
}
