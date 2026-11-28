@IsTest
private class GreeterTest {
    @IsTest
    static void greetsByName() {
        Assert.isTrue(Greeter.greet('Sally').contains('Sally'));
    }

    @IsTest
    static void trimsWhitespace() {
        Assert.isTrue(Greeter.greet('  Sally  ').endsWith(' Sally!'));
    }

    @IsTest
    static void fallsBackWhenBlank() {
        Assert.areEqual('Hello, World!', Greeter.greet(null));
        Assert.areEqual('Hello, World!', Greeter.greet('   '));
    }
}
