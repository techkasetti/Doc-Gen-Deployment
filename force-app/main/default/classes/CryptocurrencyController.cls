public with sharing class CryptocurrencyController {
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getMarketData(String symbol) {
        Map<String,Object> out = new Map<String,Object>{ 'symbol' => symbol, 'price' => 0.0 };
        if (String.isBlank(symbol)) return out;
        // TODO: integrate with market data provider
        out.put('price', 123.45);
        out.put('fetchedAt', String.valueOf(Datetime.now()));
        return out;
    }
}