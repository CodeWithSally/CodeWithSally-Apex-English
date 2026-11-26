trigger ContactTrigger on Contact (before insert) {
    ContactNamePrefixer.addPrefix(Trigger.new);
}
