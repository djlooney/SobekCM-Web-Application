/** Upgrades the database for a SobekCM system to Version 4.10.2 from Verrsion 4.10.1 **/


-- Since the constraint wasn't there before, there MAY be (incorrect) duplication
if ( exists ( select ViewType from SobekCM_Item_Viewer_Types group by ViewType having count(*) > 1 ))
begin
	-- Need to fix this then
	declare @viewtype varchar(50);
	declare @minViewTypeId int;
	declare @otherViewTypeId int;

	declare dupe_cursor cursor for
	select ViewType 
	from SobekCM_Item_Viewer_Types 
	group by ViewType having count(*) > 1;

	open dupe_cursor;

	-- Get the first viewtype with duplication
	fetch next from dupe_cursor   
	into @viewtype;

	while @@FETCH_STATUS = 0  
	begin 

		-- Get the MINIMUM id that matched ( we will keep that one )
		set @minViewTypeId = ( select MIN(ItemViewTypeID) from SobekCM_Item_Viewer_Types where ViewType=@viewtype );

		-- Using another cursor here actually seems like the best performance
		-- as it results in updating/scanning the least number of rows
		declare dupe2_cursor cursor for
		select ItemViewTypeID  
		from SobekCM_Item_Viewer_Types 
		where ViewType=@viewType  
		  and ItemViewTypeID != @minViewTypeId;

		open dupe2_cursor;

		-- Get the first view type id to remove
		fetch next from dupe2_cursor   
		into @otherViewTypeId;

		while @@FETCH_STATUS = 0  
		begin 
			-- Any items linked to this will be moved to the one we are keeping
			update SobekCM_Item_Viewers 
			set ItemViewTypeID=@minViewTypeId
			where ItemViewTypeID=@otherViewTypeId
			  and not exists ( select 1 
			                   from SobekCM_Item_Viewers V2 
			                   where V2.ItemID = SobekCM_Item_Viewers.ItemID 
							     and V2.ItemViewTypeID=@minViewTypeId );

			-- Any remaining links between the item and this view type are because they
			-- are already linked to the view type we are keeping
			delete from SobekCM_Item_Viewers 
			where ItemViewTypeID=@otherViewTypeId;

			-- Get the next matching view type id to remove (in case
			-- there were more than two dupes with the same viewtype)
			fetch next from dupe2_cursor   
			into @otherViewTypeId;
		end;

		close dupe2_cursor;  
		deallocate dupe2_cursor;  

		-- Now that all items are linked correctly, we can remove the extraneous views
		delete from SobekCM_Item_Viewer_Types 
		where ViewType=@viewtype
		  and ItemViewTypeID != @minViewTypeId;

		-- Next viewtype with duplication
		fetch next from dupe_cursor   
		into @viewtype;
	end;

	close dupe_cursor;  
	deallocate dupe_cursor;  
end;
GO

if ( not exists ( select 1 from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_NAME='SobekCM_Item_Viewer_Types_Viewer_Unique' ))
begin
	ALTER TABLE SobekCM_Item_Viewer_Types  
	ADD CONSTRAINT SobekCM_Item_Viewer_Types_Viewer_Unique UNIQUE (ViewType);   
end;
GO



IF object_id('SobekCM_Metadata_By_Bib_Vid') IS NULL EXEC ('create procedure dbo.SobekCM_Metadata_By_Bib_Vid as select 1;');
GO

--exec SobekCM_Metadata_By_Bib_Vid '', 'UM00000012', '00001', 'DUKE000061', '00001', 'UM00000317', '00001'



ALTER PROCEDURE [dbo].[SobekCM_Metadata_By_Bib_Vid] 
	@aggregationcode varchar(20),
	@bibid1 varchar(10),
	@vid1 varchar(5),
	@bibid2 varchar(10),
	@vid2 varchar(5),
	@bibid3 varchar(10),
	@vid3 varchar(5),
	@bibid4 varchar(10),
	@vid4 varchar(5),
	@bibid5 varchar(10),
	@vid5 varchar(5),
	@bibid6 varchar(10),
	@vid6 varchar(5),
	@bibid7 varchar(10),
	@vid7 varchar(5),
	@bibid8 varchar(10),
	@vid8 varchar(5),
	@bibid9 varchar(10),
	@vid9 varchar(5),
	@bibid10 varchar(10),
	@vid10 varchar(5)											
AS
BEGIN
	-- No need to perform any locks here, especially given the possible
	-- length of this search
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;

	-- Create the temporary tables first
	-- Create the temporary table to hold all the item id's
	create table #TEMP_ITEMS ( ItemID int primary key, fk_TitleID int, Hit_Count int, SortDate bigint );
		
	-- Determine the aggregationid
	declare @aggregationid int;
	set @aggregationid = coalesce( (select AggregationID from SobekCM_Item_Aggregation where Code=@aggregationcode), -1 );
	
	-- Get the sql which will be used to return the aggregation-specific display values for all the items in this page of results
	declare @item_display_sql nvarchar(max);
	if ( @aggregationid < 0 )
	begin
		select @item_display_sql=coalesce(Browse_Results_Display_SQL, 'select S.ItemID, S.Publication_Date, S.Creator, S.[Publisher.Display], S.Format, S.Edition, S.Material, S.Measurements, S.Style_Period, S.Technique, S.[Subjects.Display], S.Source_Institution, S.Donor from SobekCM_Metadata_Basic_Search_Table S, @itemtable T where S.ItemID = T.ItemID order by T.RowNumber;')
		from SobekCM_Item_Aggregation
		where Code='all';
	end
	else
	begin
		select @item_display_sql=coalesce(Browse_Results_Display_SQL, 'select S.ItemID, S.Publication_Date, S.Creator, S.[Publisher.Display], S.Format, S.Edition, S.Material, S.Measurements, S.Style_Period, S.Technique, S.[Subjects.Display], S.Source_Institution, S.Donor from SobekCM_Metadata_Basic_Search_Table S, @itemtable T where S.ItemID = T.ItemID order by T.RowNumber;')
		from SobekCM_Item_Aggregation
		where AggregationID=@aggregationid;
	end;

	-- Perform the actual metadata search differently, depending on whether an aggregation was 
	-- included to limit this search
	if ( @aggregationid > 0 )
	begin		  
		insert into #TEMP_ITEMS ( ItemID, fk_TitleID, Hit_Count, SortDate )
		select CL.ItemID, I.GroupID, 1, I.SortDate
		from SobekCM_Item AS I inner join
				SobekCM_Item_Aggregation_Item_Link AS CL ON CL.ItemID = I.ItemID inner join
				SobekCM_Item_Group AS M on M.GroupID = I.GroupID
		where ( I.Deleted = 'false' )
			and ( CL.AggregationID = @aggregationid )
			and ( I.Dark = 'false' )
			and (    (( M.BibID=coalesce(@bibid1,'')) and ( I.VID=coalesce(@vid1,'')))
			      or (( M.BibID=coalesce(@bibid2,'')) and ( I.VID=coalesce(@vid2,'')))
				  or (( M.BibID=coalesce(@bibid3,'')) and ( I.VID=coalesce(@vid3,''))) 
				  or (( M.BibID=coalesce(@bibid4,'')) and ( I.VID=coalesce(@vid4,'')))
				  or (( M.BibID=coalesce(@bibid5,'')) and ( I.VID=coalesce(@vid5,'')))
				  or (( M.BibID=coalesce(@bibid6,'')) and ( I.VID=coalesce(@vid6,'')))
				  or (( M.BibID=coalesce(@bibid7,'')) and ( I.VID=coalesce(@vid7,'')))
				  or (( M.BibID=coalesce(@bibid8,'')) and ( I.VID=coalesce(@vid8,'')))
				  or (( M.BibID=coalesce(@bibid9,'')) and ( I.VID=coalesce(@vid9,'')))
				  or (( M.BibID=coalesce(@bibid10,'')) and ( I.VID=coalesce(@vid10,'')))  );			  
			  
	end
	else
	begin	
		insert into #TEMP_ITEMS ( ItemID, fk_TitleID, Hit_Count, SortDate )
		select I.ItemID, I.GroupID, 1, I.SortDate
		from SobekCM_Item AS I inner join
			 SobekCM_Item_Group AS M on M.GroupID = I.GroupID
		where ( I.Deleted = 'false' )
			and ( I.IncludeInAll = 'true' )
			and ( I.Dark = 'false' )
			and (    (( M.BibID=coalesce(@bibid1,'')) and ( I.VID=coalesce(@vid1,'')))
			      or (( M.BibID=coalesce(@bibid2,'')) and ( I.VID=coalesce(@vid2,'')))
				  or (( M.BibID=coalesce(@bibid3,'')) and ( I.VID=coalesce(@vid3,''))) 
				  or (( M.BibID=coalesce(@bibid4,'')) and ( I.VID=coalesce(@vid4,'')))
				  or (( M.BibID=coalesce(@bibid5,'')) and ( I.VID=coalesce(@vid5,'')))
				  or (( M.BibID=coalesce(@bibid6,'')) and ( I.VID=coalesce(@vid6,'')))
				  or (( M.BibID=coalesce(@bibid7,'')) and ( I.VID=coalesce(@vid7,'')))
				  or (( M.BibID=coalesce(@bibid8,'')) and ( I.VID=coalesce(@vid8,'')))
				  or (( M.BibID=coalesce(@bibid9,'')) and ( I.VID=coalesce(@vid9,'')))
				  or (( M.BibID=coalesce(@bibid10,'')) and ( I.VID=coalesce(@vid10,'')))  );		
	end;

	-- Create the temporary item table variable for paging purposes
	declare @TEMP_PAGED_ITEMS TempPagedItemsTableType;
			

	-- create the temporary title table definition
	declare @TEMP_TITLES table ( TitleID int, BibID varchar(10), RowNumber int);		
							  
	-- Create saved select across titles for row numbers
	with TITLES_SELECT AS
		(	select GroupID, G.BibID, ROW_NUMBER() OVER (ORDER BY BibID ASC) as RowNumber
			from #TEMP_ITEMS I, SobekCM_Item_Group G
			where I.fk_TitleID = G.GroupID
			group by G.GroupID, G.BibID, G.SortTitle )

	-- Insert the correct rows into the temp title table	
	insert into @TEMP_TITLES ( TitleID, BibID, RowNumber )
	select GroupID, BibID, RowNumber
	from TITLES_SELECT;
			
	-- Return the title information for this page
	select RowNumber as TitleID, T.BibID, G.GroupTitle, G.ALEPH_Number as OPAC_Number, G.OCLC_Number, coalesce(G.GroupThumbnail,'') as GroupThumbnail, G.[Type], coalesce(G.Primary_Identifier_Type,'') as Primary_Identifier_Type, coalesce(G.Primary_Identifier, '') as Primary_Identifier
	from @TEMP_TITLES T, SobekCM_Item_Group G
	where ( T.TitleID = G.GroupID )
	order by RowNumber ASC;
			
	-- Get the item id's for the items related to these titles
	insert into @TEMP_PAGED_ITEMS
	select ItemID, RowNumber
	from @TEMP_TITLES T, SobekCM_Item I
	where ( T.TitleID = I.GroupID )
		and ( I.Deleted = 'false' )
		and ( I.Dark = 'false' );
			
	-- Return the basic system required item information for this page of results
	select T.RowNumber as fk_TitleID, I.ItemID, VID, Title, IP_Restriction_Mask, coalesce(I.MainThumbnail,'') as MainThumbnail, coalesce(I.Level1_Index, -1) as Level1_Index, coalesce(I.Level1_Text,'') as Level1_Text, coalesce(I.Level2_Index, -1) as Level2_Index, coalesce(I.Level2_Text,'') as Level2_Text, coalesce(I.Level3_Index,-1) as Level3_Index, coalesce(I.Level3_Text,'') as Level3_Text, isnull(I.PubDate,'') as PubDate, I.[PageCount], coalesce(I.Link,'') as Link, coalesce( Spatial_KML, '') as Spatial_KML, coalesce(COinS_OpenURL, '') as COinS_OpenURL		
	from SobekCM_Item I, @TEMP_PAGED_ITEMS T
	where ( T.ItemID = I.ItemID )
	order by T.RowNumber, Level1_Index, Level2_Index, Level3_Index;			
								
	-- Return the aggregation-specific display values for all the items in this page of results
	execute sp_Executesql @item_display_sql, N' @itemtable TempPagedItemsTableType READONLY', @TEMP_PAGED_ITEMS; 	
	
	-- Drop the temporary table
	drop table #TEMP_ITEMS;
	
	SET NOCOUNT OFF;
END;
GO

GRANT EXECUTE ON SobekCM_Metadata_By_Bib_Vid TO Sobek_Builder;
GRANT EXECUTE ON SobekCM_Metadata_By_Bib_Vid TO Sobek_User;
GO

-- Add a setting for the Ace editor theme
update SobekCM_Settings
set Options='{STATIC_SOURCE_CODES}'
where Setting_Key='Static Resources Source';
GO


IF ( NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SobekCM_Item_Aggregation_Result_Types'))
begin
	CREATE TABLE dbo.SobekCM_Item_Aggregation_Result_Types (
		ItemAggregationResultTypeID int IDENTITY(1,1) NOT NULL,
		ResultType varchar(50) NOT NULL,
		DefaultOrder int NOT NULL DEFAULT ((100)),
		DefaultView bit NOT NULL DEFAULT ('false'),
	 CONSTRAINT PK_SobekCM_Item_Aggregation_Result_Types PRIMARY KEY CLUSTERED ( ItemAggregationResultTypeID ASC ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	 CONSTRAINT SobekCM_Item_Aggregation_Result_Types_Unique UNIQUE NONCLUSTERED ( ResultType ASC ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
end;
GO

IF ( NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SobekCM_Item_Aggregation_Result_Views'))
begin
	CREATE TABLE dbo.SobekCM_Item_Aggregation_Result_Views (
		ItemAggregationResultID int IDENTITY(1,1) NOT NULL,
		AggregationID int NOT NULL,
		ItemAggregationResultTypeID int NOT NULL,
		DefaultView bit NOT NULL DEFAULT('false'),
	 CONSTRAINT PK_SobekCM_Item_Aggregation_Result_Views PRIMARY KEY CLUSTERED ( ItemAggregationResultID ASC ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
end;
GO

IF ( not exists ( SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME='FK_SobekCM_Item_Aggregation_Result_Views_AggregationID' ))
begin
	ALTER TABLE dbo.SobekCM_Item_Aggregation_Result_Views ADD CONSTRAINT FK_SobekCM_Item_Aggregation_Result_Views_AggregationID FOREIGN KEY(AggregationID) REFERENCES [dbo].SobekCM_Item_Aggregation ([AggregationID]);
end;
GO

IF ( not exists ( SELECT * FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_NAME='FK_SobekCM_Item_Aggregation_Result_Views_AggregationID' ))
begin
	ALTER TABLE dbo.SobekCM_Item_Aggregation_Result_Views ADD CONSTRAINT FK_SobekCM_Item_Aggregation_Result_Views_TypeID FOREIGN KEY(ItemAggregationResultTypeID) REFERENCES dbo.SobekCM_Item_Aggregation_Result_Types (ItemAggregationResultTypeID);
end;
GO

-- Add all the standard result types
if ( ( select count(*) from SobekCM_Item_Aggregation_Result_Types ) = 0 )
begin
	insert into SobekCM_Item_Aggregation_Result_Types ( ResultType, DefaultOrder, DefaultView ) values ( 'BRIEF', 1, 1 );
	insert into SobekCM_Item_Aggregation_Result_Types ( ResultType, DefaultOrder, DefaultView ) values ( 'THUMBNAIL', 2, 1 );
	insert into SobekCM_Item_Aggregation_Result_Types ( ResultType, DefaultOrder, DefaultView ) values ( 'TABLE', 3, 1 );
	insert into SobekCM_Item_Aggregation_Result_Types ( ResultType, DefaultOrder, DefaultView ) values ( 'EXPORT', 4, 0 );
	insert into SobekCM_Item_Aggregation_Result_Types ( ResultType, DefaultOrder, DefaultView ) values ( 'GMAP', 5, 1 );
end;
GO

-- Add all the standard result types to the aggregations
insert into SobekCM_Item_Aggregation_Result_Views ( AggregationID, ItemAggregationResultTypeID, DefaultView )
select AggregationID, ItemAggregationResultTypeID, 'false'
from SobekCM_Item_Aggregation_Result_Types T, SobekCM_Item_Aggregation A
where ( T.DefaultView = 'true' )
  and ( not exists ( select 1 from SobekCM_Item_Aggregation_Result_Views V
                     where V.AggregationID=A.AggregationID 
					   and V.ItemAggregationResultTypeID=T.ItemAggregationResultTypeID));

-- Also, set defaults
declare @briefid int;
set @briefid = ( select ItemAggregationResultTypeID from SobekCM_Item_Aggregation_Result_Types T where T.ResultType='BRIEF' );
if ( coalesce(@briefid, -1) > 0 )
begin
	with aggrs_no_default as
	( 
		select AggregationID 
		from SobekCM_Item_Aggregation A
		where not exists ( select 1 from SobekCM_Item_Aggregation_Result_Views V where V.AggregationID = A.AggregationID and V.DefaultView='true')
	)
	update SobekCM_Item_Aggregation_Result_Views
	set DefaultView='true'
	where ( exists ( select 1 from aggrs_no_default D where D.AggregationID=SobekCM_Item_Aggregation_Result_Views.AggregationID ))
	  and ( ItemAggregationResultTypeID = @briefid );
end;
GO


IF object_id('Delete_User_Completely') IS NULL EXEC ('create procedure dbo.Delete_User_Completely as select 1;');
GO


ALTER PROCEDURE Delete_User_Completely 
	@username nvarchar(100)
AS
BEGIN TRANSACTION

	-- Ensure the username exists before continuing
	if ( exists ( select 1 from mySobek_User where UserName=@username))
	begin

		-- Get the 	user id
		declare @userid int;
		set @userid = ( select UserID from mySobek_User where Username=@username);

		-- Delete from all the satellite tables
		delete from mySobek_User_Bib_Link where UserID=@userid;
		delete from mySobek_User_DefaultMetadata_Link where UserID=@userid;
		delete from mySobek_User_Description_Tags where UserID=@userid;
		delete from mySobek_User_Edit_Aggregation where UserID=@userid;
		delete from mySobek_User_Editable_Link where UserID=@userid;

		delete from mySobek_User_Item_Link where UserID=@userid;
		delete from mySobek_User_Item_Permissions where UserID=@userid;
		delete from mySobek_User_Search where UserID=@userid;
		delete from mySobek_User_Settings where UserID=@userid;
		delete from mySobek_User_Template_Link where UserID=@userid;
		delete from mySobek_User_Group_Link where UserID=@userid;

		-- Delete the folder
		delete from mySobek_User_Item where UserFolderID in ( select UserFolderID from mySobek_User_Folder where UserID=@userid);
		delete from mySobek_User_Folder where UserID=@userid;

		-- Delete from main user table
		delete from mySobek_User where UserID=@userid;

	end;
COMMIT TRANSACTION;
GO
 
-- Deletes an item, and deletes the group if there are no additional items attached
ALTER PROCEDURE [dbo].[SobekCM_Delete_Item] 
	@bibid varchar(10),
	@vid varchar(5),
	@as_admin bit,
	@delete_message varchar(1000)
AS
begin transaction
	-- Perform transactionally in case there is a problem deleting some of the rows
	-- so the entire delete is rolled back

   declare @itemid int;
   set @itemid = 0;

    -- first to get the itemid of the specified bibid and vid
   select @itemid = isnull(I.itemid, 0)
   from SobekCM_Item I, SobekCM_Item_Group G
   where (G.bibid = @bibid) 
       and (I.vid = @vid)
       and ( I.GroupID = G.GroupID );

   -- if there is such an itemid in the UFDC database, then delete this item and its related information
  if ( isnull(@itemid, 0 ) > 0)
  begin

	-- Delete all references to this item 
	delete from SobekCM_Metadata_Unique_Link where ItemID=@itemid;
	delete from SobekCM_Metadata_Basic_Search_Table where ItemID=@itemid;
	delete from SobekCM_Item_Footprint where ItemID=@itemid;
	delete from SobekCM_Item_Icons where ItemID=@itemid;
	delete from SobekCM_Item_Statistics where ItemID=@itemid;
	delete from SobekCM_Item_GeoRegion_Link where ItemID=@itemid;
	delete from SobekCM_Item_Aggregation_Item_Link where ItemID=@itemid;
	delete from mySobek_User_Item where ItemID=@itemid;
	delete from mySobek_User_Item_Link where ItemID=@itemid;
	delete from mySobek_User_Description_Tags where ItemID=@itemid;
	delete from SobekCM_Item_Viewers where ItemID=@itemid;
	delete from Tracking_Item where ItemID=@itemid;
	delete from Tracking_Progress where ItemID=@itemid;
	delete from SobekCM_Item_OAI where ItemID=@itemid;
	delete from SobekCM_QC_Errors where ItemID=@itemid;
	delete from SobekCM_QC_Errors_History where ItemID=@itemid;
	delete from SobekCM_Item_Settings where ItemID=@itemid;
	
	if ( @as_admin = 'true' )
	begin
		delete from Tracking_Archive_Item_Link where ItemID=@itemid;
		update Tivoli_File_Log set DeleteMsg=@delete_message, ItemID = -1 where ItemID=@itemid;
	end;
	
	-- Finally, delete the item 
	delete from SobekCM_Item where ItemID=@itemid;
	
	-- Delete the item group if it is the last one existing
	if (( select count(I.ItemID) from SobekCM_Item_Group G, SobekCM_Item I where ( G.BibID = @bibid ) and ( G.GroupID = I.GroupID ) and ( I.Deleted = 0 )) < 1 )
	begin
		
		declare @groupid int;
		set @groupid = 0;	
		
		-- first to get the itemid of the specified bibid and vid
		select @groupid = isnull(G.GroupID, 0)
		from SobekCM_Item_Group G
		where (G.bibid = @bibid);
		
		-- Delete if this selected something
		if ( ISNULL(@groupid, 0 ) > 0 )
		begin		
			-- delete from the item group table	and all references
			delete from SobekCM_Item_Group_External_Record where GroupID=@groupid;
			delete from SobekCM_Item_Group_Web_Skin_Link where GroupID=@groupid;
			delete from SobekCM_Item_Group_Statistics where GroupID=@groupid;
			delete from mySobek_User_Bib_Link where GroupID=@groupid;
			delete from SobekCM_Item_Group_OAI where GroupID=@groupid;
			delete from SobekCM_Item_Group where GroupID=@groupid;
		end;
	end
	else
	begin
		-- Finally set the volume count for this group correctly
		update SobekCM_Item_Group
		set ItemCount = ( select count(*) from SobekCM_Item I where ( I.GroupID = SobekCM_Item_Group.GroupID ))	
		where ( SobekCM_Item_Group.BibID = @bibid );
	end;
  end;
   
commit transaction;
GO


-- Retrive the very simple list of items to save in XML format or to step through
-- and add to the solr/lucene index, etc..  
ALTER PROCEDURE [dbo].[SobekCM_Simple_Item_List]
	@collection_code varchar(10)
AS
BEGIN

	-- No need to perform any locks here
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
	if ( len( isnull( @collection_code, '' )) = 0 )
	begin

		select G.BibID, I.VID, I.Title, I.CreateDate, Resource_Link = File_Location, I.LastSaved
		from SobekCM_Item_Group G, SobekCM_Item I
		where ( G.GroupID = I.GroupID )
		  and ( I.IP_Restriction_Mask = 0 )
		  and ( G.Deleted = CONVERT(bit,0) )
	      and ( I.Deleted = CONVERT(bit,0) )
		  and ( I.Dark = 0 )

	end
	else
	begin

		select G.BibID, I.VID, I.Title, I.CreateDate, Resource_Link = File_Location, I.LastSaved
		from SobekCM_Item_Group G, SobekCM_Item I, SobekCM_Item_Aggregation C, SobekCM_Item_Aggregation_Item_Link CL
		where ( G.GroupID = I.GroupID )
		  and ( I.IP_Restriction_Mask = 0 )
		  and ( G.Deleted = CONVERT(bit,0) )
	      and ( I.Deleted = CONVERT(bit,0) )
		  and ( I.Dark = 0 )
		  and ( I.ItemID = CL.ItemID )
		  and ( CL.AggregationID = C.AggregationID )
		  and ( Code = @collection_code );
	end;
END;
GO


-- Pull any additional item details before showing this item
ALTER PROCEDURE [dbo].[SobekCM_Get_Item_Details2]
	@BibID varchar(10),
	@VID varchar(5)
AS
BEGIN

	-- No need to perform any locks here
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	-- Does this BIbID exist?
	if (not exists ( select 1 from SobekCM_Item_Group where BibID = @BibID ))
	begin
		select 'INVALID BIBID' as ErrorMsg, '' as BibID, '' as VID;
		return;
	end;

	-- Was this for one item within a group?
	if ( LEN( ISNULL(@VID,'')) > 0 )
	begin	

		-- Does this VID exist in that stored procedure?
		if ( not exists ( select 1 from SobekCM_Item I, SobekCM_Item_Group G where I.GroupID = G.GroupID and G.BibID=@BibID and I.VID = @VID ))
		begin

			select top 1 'INVALID VID' as ErrorMsg, @BibID as BibID, VID
			from SobekCM_Item I, SobekCM_Item_Group G
			where I.GroupID = G.GroupID 
			  and G.BibID = @BibID
			order by VID;

			return;
		end;
	
		-- Only continue if there is ONE match
		if (( select COUNT(*) from SobekCM_Item I, SobekCM_Item_Group G where I.GroupID = G.GroupID and G.BibID = @BibID and I.VID = @VID ) = 1 )
		begin
			-- Get the itemid
			declare @ItemID int;
			select @ItemID = ItemID from SobekCM_Item I, SobekCM_Item_Group G where I.GroupID = G.GroupID and G.BibID = @BibID and I.VID = @VID;

			-- Return any descriptive tags
			select U.FirstName, U.NickName, U.LastName, G.BibID, I.VID, T.Description_Tag, T.TagID, T.Date_Modified, U.UserID, isnull([PageCount], 0) as Pages, ExposeFullTextForHarvesting
			from mySobek_User U, mySobek_User_Description_Tags T, SobekCM_Item I, SobekCM_Item_Group G
			where ( T.ItemID = @ItemID )
			  and ( I.ItemID = T.ItemID )
			  and ( I.GroupID = G.GroupID )
			  and ( T.UserID = U.UserID );
			
			-- Return the aggregation information linked to this item
			select A.Code, A.Name, A.ShortName, A.[Type], A.Map_Search, A.DisplayOptions, A.Items_Can_Be_Described, L.impliedLink, A.Hidden, A.isActive, ISNULL(A.External_Link,'') as External_Link
			from SobekCM_Item_Aggregation_Item_Link L, SobekCM_Item_Aggregation A
			where ( L.ItemID = @ItemID )
			  and ( A.AggregationID = L.AggregationID );
		  
			-- Return information about the actual item/group
			select G.BibID, I.VID, G.File_Location, G.SuppressEndeca, 'true' as [Public], I.IP_Restriction_Mask, G.GroupID, I.ItemID, I.CheckoutRequired, Total_Volumes=(select COUNT(*) from SobekCM_Item J where G.GroupID = J.GroupID ),
				isnull(I.Level1_Text, '') as Level1_Text, isnull( I.Level1_Index, 0 ) as Level1_Index, 
				isnull(I.Level2_Text, '') as Level2_Text, isnull( I.Level2_Index, 0 ) as Level2_Index, 
				isnull(I.Level3_Text, '') as Level3_Text, isnull( I.Level3_Index, 0 ) as Level3_Index,
				G.GroupTitle, I.TextSearchable, Comments=isnull(I.Internal_Comments,''), Dark, G.[Type],
				I.Title, I.Publisher, I.Author, I.Donor, I.PubDate, G.ALEPH_Number, G.OCLC_Number, I.Born_Digital, 
				I.Disposition_Advice, I.Material_Received_Date, I.Material_Recd_Date_Estimated, I.Tracking_Box, I.Disposition_Advice_Notes, 
				I.Left_To_Right, I.Disposition_Notes, G.Track_By_Month, G.Large_Format, G.Never_Overlay_Record, I.CreateDate, I.SortDate, 
				G.Primary_Identifier_Type, G.Primary_Identifier, G.[Type] as GroupType, coalesce(I.MainThumbnail,'') as MainThumbnail,
				T.EmbargoEnd, coalesce(T.UMI,'') as UMI, T.Original_EmbargoEnd, coalesce(T.Original_AccessCode,'') as Original_AccessCode,
				I.CitationSet
			from SobekCM_Item as I inner join
				 SobekCM_Item_Group as G on G.GroupID=I.GroupID left outer join
				 Tracking_Item as T on T.ItemID=I.ItemID
			where ( I.ItemID = @ItemID );
		  
			-- Return any ticklers associated with this item
			select MetadataValue
			from SobekCM_Metadata_Unique_Search_Table M, SobekCM_Metadata_Unique_Link L
			where ( L.ItemID = @ItemID ) 
			  and ( L.MetadataID = M.MetadataID )
			  and ( M.MetadataTypeID = 20 );
			
			-- Return the viewers for this item
			select T.ViewType, V.Attribute, V.Label, coalesce(V.MenuOrder, T.MenuOrder) as MenuOrder, V.Exclude, coalesce(V.OrderOverride, T.[Order])
			from SobekCM_Item_Viewers V, SobekCM_Item_Viewer_Types T
			where ( V.ItemID = @ItemID )
			  and ( V.ItemViewTypeID = T.ItemViewTypeID )
			group by T.ViewType, V.Attribute, V.Label, coalesce(V.MenuOrder, T.MenuOrder), V.Exclude, coalesce(V.OrderOverride, T.[Order])
			order by coalesce(V.OrderOverride, T.[Order]) ASC;
				
			-- Return the icons for this item
			select Icon_URL, Link, Icon_Name, I.Title
			from SobekCM_Icon I, SobekCM_Item_Icons L
			where ( L.IconID = I.IconID ) 
			  and ( L.ItemID = @ItemID )
			order by Sequence;
			  
			-- Return any web skin restrictions
			select S.WebSkinCode
			from SobekCM_Item_Group_Web_Skin_Link L, SobekCM_Item I, SobekCM_Web_Skin S
			where ( L.GroupID = I.GroupID )
			  and ( L.WebSkinID = S.WebSkinID )
			  and ( I.ItemID = @ItemID )
			order by L.Sequence;

			-- Return all of the key/value pairs of settings
			select Setting_Key, Setting_Value
			from SobekCM_Item_Settings 
			where ItemID=@ItemID;
		end;		
	end
	else
	begin
		-- Return the aggregation information linked to this item
		select GroupTitle, BibID, G.[Type], G.File_Location, isnull(AGGS.Code,'') AS Code, G.GroupID, isnull(GroupThumbnail,'') as Thumbnail, G.Track_By_Month, G.Large_Format, G.Never_Overlay_Record, G.Primary_Identifier_Type, G.Primary_Identifier
		from SobekCM_Item_Group AS G LEFT JOIN
			 ( select distinct(A.Code),  G2.GroupID
			   from SobekCM_Item_Group G2, SobekCM_Item IL, SobekCM_Item_Aggregation_Item_Link L, SobekCM_Item_Aggregation A
		       where IL.ItemID=L.ItemID 
		         and A.AggregationID=L.AggregationID
		         and G2.GroupID=IL.GroupID
		         and G2.BibID=@BibID
		         and G2.Deleted='false'
		       group by A.Code, G2.GroupID ) AS AGGS ON G.GroupID=AGGS.GroupID
		where ( G.BibID = @BibID )
		  and ( G.Deleted = 'false' );

		-- Get list of icon ids
		select distinct(IconID)
		into #TEMP_ICON
		from SobekCM_Item_Icons II, SobekCM_Item It, SobekCM_Item_Group G
		where ( It.GroupID = G.GroupID )
			and ( G.BibID = @bibid )
			and ( It.Deleted = 0 )
			and ( II.ItemID = It.ItemID )
		group by IconID;

		-- Return icons
		select Icon_URL, Link, Icon_Name, Title
		from SobekCM_Icon I, (	select distinct(IconID)
								from SobekCM_Item_Icons II, SobekCM_Item It, SobekCM_Item_Group G
								where ( It.GroupID = G.GroupID )
							 	  and ( G.BibID = @bibid )
								  and ( It.Deleted = 0 )
								  and ( II.ItemID = It.ItemID )
								group by IconID) AS T
		where ( T.IconID = I.IconID );
		
		-- Return any web skin restrictions
		select S.WebSkinCode
		from SobekCM_Item_Group_Web_Skin_Link L, SobekCM_Item_Group G, SobekCM_Web_Skin S
		where ( L.GroupID = G.GroupID )
		  and ( L.WebSkinID = S.WebSkinID )
		  and ( G.BibID = @BibID )
		order by L.Sequence;
		
		-- Get the distinct list of all aggregations linked to this item
		select distinct( Code )
		from SobekCM_Item_Aggregation A, SobekCM_Item_Aggregation_Item_Link L, SobekCM_Item_Group G, SobekCM_Item I
		where ( I.ItemID = L.ItemID )
		  and ( I.GroupID = G.GroupID )
		  and ( G.BibID = @BibID )
		  and ( L.AggregationID = A.AggregationID );		
	end;
		
	-- Get the list of related item groups
	select B.BibID, B.GroupTitle, R.Relationship_A_to_B AS Relationship
	from SobekCM_Item_Group A, SobekCM_Item_Group_Relationship R, SobekCM_Item_Group B
	where ( A.BibID = @bibid ) 
	  and ( R.GroupA = A.GroupID )
	  and ( R.GroupB = B.GroupID )
	union
	select A.BibID, A.GroupTitle, R.Relationship_B_to_A AS Relationship
	from SobekCM_Item_Group A, SobekCM_Item_Group_Relationship R, SobekCM_Item_Group B
	where ( B.BibID = @bibid ) 
	  and ( R.GroupB = B.GroupID )
	  and ( R.GroupA = A.GroupID );
		  
END;
GO

-- Update the version number
if (( select count(*) from SobekCM_Database_Version ) = 0 )
begin
	insert into SobekCM_Database_Version ( Major_Version, Minor_Version, Release_Phase )
	values ( 4, 10, '2' );
end
else
begin
	update SobekCM_Database_Version
	set Major_Version=4, Minor_Version=10, Release_Phase='2';
end;
GO
