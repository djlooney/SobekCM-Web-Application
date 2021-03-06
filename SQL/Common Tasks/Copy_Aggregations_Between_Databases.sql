

-- NEED SELECT STATEMENT FOR ANY THEMATIC HEADINGS

-- Select statements for the aggreagtions
select 'insert into SobekCM_Item_Aggregation ( [AggregationID], [Code], [Name], [ShortName], [Description], [ThematicHeadingID], [Type], [isActive], [Hidden], [DisplayOptions], [Map_Search], DateAdded, Can_Browse_Items, Include_In_Collection_Facet, Browse_Results_Display_SQL, OAI_Flag, ContactEmail ) ' +
       'values ( ' + cast(AggregationID as varchar(4)) + ',''' + Code + ''', ''' + Name + ''',''' + ShortName + ''',''' + [Description] + ''',' + cast(ThematicHeadingID as varchar(1)) + ',''' + [Type] + ''',''' + cast (isActive as varchar(10)) + ''',''' + cast(Hidden as varchar(10)) + ''',''' + DisplayOptions + ''',' +cast(Map_Search as varchar(2)) +',''' + cast(DateAdded as varchar(12)) + ''', ''' + cast(Can_Browse_Items as varchar(10)) + ''',''' + cast(Include_In_Collection_Facet as varchar(10)) + ''',''' + Browse_Results_Display_SQL + ''', ''false'', '''');'
from SobekCM_Item_Aggregation 
where Deleted = 'false' and AggregationID <> 1 ;

-- Replace, in the lines above, ',*,' with ',-1,'

-- Add the hierarchy
select 'insert into SobekCM_Item_Aggregation_Hierarchy ( ParentID, ChildID, Search_Parent_Only ) ' +
       'values ( ' + cast(ParentID as varchar(4)) + ',' + cast(ChildID as varchar(4)) + ', ' + cast(Search_Parent_Only as varchar(10)) + ');'
from SobekCM_Item_Aggregation_Hierarchy;


