@isTest
private class CryptocurrencyControllerTest {
    @isTest static void testGetMarketData() {
        Test.startTest();
        Map<String,Object> r = CryptocurrencyController.getMarketData('BTC');
        Test.stopTest();
        System.assert(r.containsKey('price'));
    }
}