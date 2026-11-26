public with sharing class AccountNamePrefixer {
    public static final String PREFIX = 'PENDING REVIEW: ';
    private static final Integer MAX_NAME_LENGTH = 255;

    public static void addPrefix(List<Account> accounts) {
        for (Account acc : accounts) {
            if (acc.Name == null || acc.Name.startsWith(PREFIX)) {
                continue;
            }
            acc.Name = (PREFIX + acc.Name).left(MAX_NAME_LENGTH);
        }
    }
}
