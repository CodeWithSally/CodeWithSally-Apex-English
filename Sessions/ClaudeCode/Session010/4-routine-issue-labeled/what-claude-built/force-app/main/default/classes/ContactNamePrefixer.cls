/**
 * Adds "NEW CONTACT: " to the front of a new contact's name, so the full
 * name reads "NEW CONTACT: John Smith". The prefix goes on FirstName when it
 * has one and the result fits; otherwise it goes on LastName.
 */
public with sharing class ContactNamePrefixer {
    public static final String PREFIX = 'NEW CONTACT: ';

    public static void addPrefix(List<Contact> contacts) {
        Integer firstNameMax = Schema.SObjectType.Contact.fields.FirstName.getLength();
        for (Contact c : contacts) {
            if (hasPrefix(c.FirstName) || hasPrefix(c.LastName)) {
                continue;
            }
            if (String.isNotBlank(c.FirstName) && (PREFIX + c.FirstName).length() <= firstNameMax) {
                c.FirstName = PREFIX + c.FirstName;
            } else {
                c.LastName = PREFIX + (c.LastName == null ? '' : c.LastName);
            }
        }
    }

    private static Boolean hasPrefix(String value) {
        return value != null && value.startsWith(PREFIX);
    }
}
