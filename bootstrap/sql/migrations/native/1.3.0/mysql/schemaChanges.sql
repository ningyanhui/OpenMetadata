-- Data quality failure status extension time series
CREATE TABLE test_case_resolution_status_time_series (
  id varchar(36) GENERATED ALWAYS AS (json_unquote(json_extract(json,'$.id'))) VIRTUAL NOT NULL,
  stateId varchar(36) GENERATED ALWAYS AS (json_unquote(json_extract(json,'$.stateId'))) VIRTUAL NOT NULL,
  assignee varchar(256) GENERATED ALWAYS AS (json_unquote(json_extract(json,'$.testCaseResolutionStatusDetails.assignee.name'))) VIRTUAL NULL,
  timestamp bigint unsigned GENERATED ALWAYS AS (json_unquote(json_extract(json,'$.timestamp'))) VIRTUAL NOT NULL,
  testCaseResolutionStatusType varchar(36) GENERATED ALWAYS AS (json_unquote(json_extract(json,'$.testCaseResolutionStatusType'))) VIRTUAL NOT NULL,
  jsonSchema varchar(256) NOT NULL,
  json json NOT NULL,
  entityFQNHash varchar(768) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  CONSTRAINT test_case_resolution_status_unique_constraint UNIQUE (id,timestamp,entityFQNHash),
  INDEX (id),
  INDEX(testCaseResolutionStatusType),
  INDEX(id, testCaseResolutionStatusType)

) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- DataInsightsApplication should not allow configuration
update apps_marketplace
set json = JSON_INSERT(
  JSON_REMOVE(json, '$.allowConfiguration'),
  '$.allowConfiguration',
  false
)
where name = 'DataInsightsApplication';

update installed_apps
set json = JSON_INSERT(
  JSON_REMOVE(json, '$.allowConfiguration'),
  '$.allowConfiguration',
  false
)
where name = 'DataInsightsApplication';


-- update service type to UnityCatalog - update database entity
UPDATE database_entity de
SET de.json = JSON_INSERT(
    JSON_REMOVE(de.json, '$.serviceType'),
    '$.serviceType',
    'UnityCatalog'
 )
where id in (
select toId from entity_relationship er 
where 
  fromEntity = 'databaseService'
  and toEntity = 'database'
  and fromId in (
    select id from dbservice_entity dbe 
    where 
      serviceType = 'Databricks' 
      and JSON_EXTRACT(
        dbe.json, '$.connection.config.useUnityCatalog'
      ) = true
  ));
 

-- update service type to UnityCatalog - update database schema entity
UPDATE database_schema_entity dse
SET dse.json = JSON_INSERT(
    JSON_REMOVE(dse.json, '$.serviceType'),
    '$.serviceType',
    'UnityCatalog'
 )
where JSON_EXTRACT(dse.json, '$.database.id') in (
select toId from entity_relationship er 
where 
  fromEntity = 'databaseService'
  and toEntity = 'database'
  and fromId in (
    select id from dbservice_entity dbe 
    where 
      serviceType = 'Databricks' 
      and JSON_EXTRACT(
        dbe.json, '$.connection.config.useUnityCatalog'
      ) = true
  ));
 

-- update service type to UnityCatalog - update table entity
UPDATE table_entity te
SET te.json = JSON_INSERT(
    JSON_REMOVE(te.json, '$.serviceType'),
    '$.serviceType',
    'UnityCatalog'
 )
where JSON_EXTRACT(te.json, '$.database.id') in (
select toId from entity_relationship er 
where 
  fromEntity = 'databaseService'
  and toEntity = 'database'
  and fromId in (
    select id from dbservice_entity dbe 
    where 
      serviceType = 'Databricks' 
      and JSON_EXTRACT(
        dbe.json, '$.connection.config.useUnityCatalog'
      ) = true
  ));


-- update service type to UnityCatalog - update db service entity
UPDATE dbservice_entity de
SET de.json = JSON_INSERT(
    JSON_REMOVE(de.json, '$.connection.config.type'),
    '$.connection.config.type',
    'UnityCatalog'
 ),de.json = JSON_INSERT(
    JSON_REMOVE(de.json, '$.serviceType'),
    '$.serviceType',
    'UnityCatalog'
 ) 
WHERE de.serviceType = 'Databricks'
  AND JSON_EXTRACT(de.json, '$.connection.config.useUnityCatalog') = True
;

-- remove `useUnityCatalog` flag from service connection details of databricks
UPDATE dbservice_entity de 
SET de.json = JSON_REMOVE(de.json, '$.connection.config.useUnityCatalog')
WHERE de.serviceType IN ('Databricks','UnityCatalog');
