/**
 * Example for slide 12 (not deployed): the coarse cut the database answers cheaply.
 * The follow-up rule, which may change, lives in the {@link CampaignMembers} Domain.
 */
public virtual inherited sharing class CampaignMembersSelector extends fflib_SObjectSelector {
	/**
	* Factory that returns this selector.
	* @return {@link CampaignMembersSelector} instance.
	*/
	public static CampaignMembersSelector newInstance() {
		return new CampaignMembersSelector();
	}

	/**
	* Constructs a user-mode campaign member selector.
	*/
	public CampaignMembersSelector() {
		super(false, fflib_SObjectSelector.DataAccess.USER_MODE);
	}

	/**
	* Common campaign member fields, including those the Domain's rule reads.
	* @return Field list for the query factory.
	*/
	public List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
			CampaignMember.Id,
			CampaignMember.CampaignId,
			CampaignMember.ContactId,
			CampaignMember.LeadId,
			CampaignMember.Status,
			CampaignMember.HasResponded,
			CampaignMember.FirstRespondedDate
		};
	}

	/**
	* SObject type this selector queries.
	* @return {@link CampaignMember} SObject type.
	*/
	public Schema.SObjectType getSObjectType() {
		return CampaignMember.SObjectType;
	}

	/**
	* Responded members of the given campaigns: the stable, selective criteria only.
	* @param campaignIds Campaign Ids to query.
	* @return Matching campaign members, in the default order.
	*/
	public virtual List<CampaignMember> selectRespondedByCampaign(Set<Id> campaignIds) {
		return (List<CampaignMember>) Database.query(
			newQueryFactory()
				.setCondition(
					CampaignMember.CampaignId + ' IN :campaignIds AND '
					+ CampaignMember.HasResponded + ' = true'
				)
				.toSOQL()
		);
	}
}
