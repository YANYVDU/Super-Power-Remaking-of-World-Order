-- Medieval: -1 happiness per era after the Medieval era
update Resources set HappinessDecayEra = 'ERA_MEDIEVAL'
where Type in ('RESOURCE_SALT','RESOURCE_INCENSE','RESOURCE_COPPER');

-- Renaissance: -1 happiness per era after the Renaissance era
update Resources set HappinessDecayEra = 'ERA_RENAISSANCE'
where Type in ('RESOURCE_SPICES','RESOURCE_SUGAR','RESOURCE_TOBACCO','RESOURCE_MARBLE','RESOURCE_OLIVE','RESOURCE_CITRUS');

-- Industrial: -1 happiness per era after the Industrial era
update Resources set HappinessDecayEra = 'ERA_INDUSTRIAL'
where Type in ('RESOURCE_COTTON','RESOURCE_DYE','RESOURCE_SILK','RESOURCE_TEA','RESOURCE_COFFEE','RESOURCE_COCOA','RESOURCE_WHALE','RESOURCE_CRAB','RESOURCE_WINE','RESOURCE_FUR');

-- Everlasting: clear decay era so these resources never decay
update Resources set HappinessDecayEra = NULL
where Type in ('RESOURCE_PEPPER','RESOURCE_CLOVES','RESOURCE_NUTMEG','RESOURCE_PORCELAIN','RESOURCE_GLASS');
