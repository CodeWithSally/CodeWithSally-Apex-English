/**
 * Example for slide 12 (not deployed): the business rule that may change,
 * applied to records {@link CampaignMembersSelector} has already narrowed.
 */
public virtual inherited sharing class CampaignMembers extends fflib_SObjects {
	/** Status for members who asked not to be contacted. */
	public static final String STATUS_DO_NOT_CONTACT = 'Do Not Contact';
	/** Days after first response during which a follow-up is worthwhile. */
	public static final Integer FOLLOW_UP_WINDOW_DAYS = 30;

	/**
	* Factory that wraps the given campaign members.
	* @param recordList Campaign members to manage. Null is treated as an empty list.
	* @return {@link CampaignMembers} instance.
	*/
	public static CampaignMembers newInstance(List<CampaignMember> recordList) {
		return new CampaignMembers(recordList);
	}

	/**
	* Creates a domain wrapping the given campaign members.
	* @param sObjectList Campaign members to manage. Null is treated as an empty list.
	*/
	public CampaignMembers(List<CampaignMember> sObjectList) {
		super(sObjectList == null ? new List<CampaignMember>() : sObjectList);
	}

	/**
	* Members ready for a sales follow-up as of the given date.
	* @param asOf Date to measure the follow-up window from.
	* @return Members that pass {@link #isReadyForFollowUp}.
	*/
	public List<CampaignMember> selectReadyForFollowUp(Date asOf) {
		List<CampaignMember> ready = new List<CampaignMember>();
		List<CampaignMember> members = (List<CampaignMember>) getRecords();
		for (Integer i = 0; i < members.size(); i++) {
			if (isReadyForFollowUp(members[i], asOf)) {
				ready.add(members[i]);
			}
		}
		return ready;
	}

	/**
	* Follow-up rule: responded within the window and not marked Do Not Contact.
	* @param member Campaign member to check.
	* @param asOf Date to measure the follow-up window from.
	* @return True when a follow-up is worthwhile.
	*/
	public static Boolean isReadyForFollowUp(CampaignMember member, Date asOf) {
		return member.HasResponded
			&& member.FirstRespondedDate != null
			&& member.FirstRespondedDate.daysBetween(asOf) <= FOLLOW_UP_WINDOW_DAYS
			&& member.Status != STATUS_DO_NOT_CONTACT;
	}
}
