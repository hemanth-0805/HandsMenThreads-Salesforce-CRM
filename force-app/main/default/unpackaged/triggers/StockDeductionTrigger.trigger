trigger StockDeductionTrigger on HandsMen_Order__c (after insert, after update) {

    Map<Id, Integer> productQtyMap = new Map<Id, Integer>();

    for (HandsMen_Order__c order : Trigger.new) {

        Boolean shouldDeduct = false;

        if (Trigger.isInsert && order.Status__c == 'Confirmed') {
            shouldDeduct = true;
        }

        if (Trigger.isUpdate &&
            order.Status__c == 'Confirmed' &&
            Trigger.oldMap.get(order.Id).Status__c != 'Confirmed') {
            shouldDeduct = true;
        }

        if (shouldDeduct && order.HandsMen_Product__c != null) {
            Integer qty = productQtyMap.containsKey(order.HandsMen_Product__c)
                ? productQtyMap.get(order.HandsMen_Product__c)
                : 0;
            productQtyMap.put(order.HandsMen_Product__c, qty + Integer.valueOf(order.Quantity__c));
        }
    }

    if (productQtyMap.isEmpty()) return;

    List<Inventory__c> inventoriesToUpdate = new List<Inventory__c>();

    for (Inventory__c inv : [
        SELECT Id, Stock_Quantity__c, HandsMen_Product__c
        FROM Inventory__c
        WHERE HandsMen_Product__c IN :productQtyMap.keySet()
    ]) {
        inv.Stock_Quantity__c -= productQtyMap.get(inv.HandsMen_Product__c);
        inventoriesToUpdate.add(inv);
    }

    if (!inventoriesToUpdate.isEmpty()) {
        update inventoriesToUpdate;
    }
}