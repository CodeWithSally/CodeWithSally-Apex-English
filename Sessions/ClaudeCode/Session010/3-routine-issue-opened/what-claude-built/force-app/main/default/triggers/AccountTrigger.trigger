trigger AccountTrigger on Account (before insert) {
    AccountNamePrefixer.addPrefix(Trigger.new);
}
