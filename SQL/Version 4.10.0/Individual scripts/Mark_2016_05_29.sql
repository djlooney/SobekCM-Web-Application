

-- Saves the behavior information about an item in this library
-- Written by Mark Sullivan 
ALTER PROCEDURE [dbo].[SobekCM_Save_Item_Behaviors]
	@ItemID int,
	@TextSearchable bit,
	@MainThumbnail varchar(100),
	@MainJPEG varchar(100),
	@IP_Restriction_Mask smallint,
	@CheckoutRequired bit,
	@Dark_Flag bit,
	@Born_Digital bit,
	@Disposition_Advice int,
	@Disposition_Advice_Notes varchar(150),
	@Material_Received_Date datetime,
	@Material_Recd_Date_Estimated bit,
	@Tracking_Box varchar(25),
	@AggregationCode1 varchar(20),
	@AggregationCode2 varchar(20),
	@AggregationCode3 varchar(20),
	@AggregationCode4 varchar(20),
	@AggregationCode5 varchar(20),
	@AggregationCode6 varchar(20),
	@AggregationCode7 varchar(20),
	@AggregationCode8 varchar(20),
	@HoldingCode varchar(20),
	@SourceCode varchar(20),
	@Icon1_Name varchar(50),
	@Icon2_Name varchar(50),
	@Icon3_Name varchar(50),
	@Icon4_Name varchar(50),
	@Icon5_Name varchar(50),
	@Left_To_Right bit,
	@CitationSet varchar(50)
AS
begin transaction

	--Update the main item
	update SobekCM_Item
	set TextSearchable = @TextSearchable, Deleted = 0, MainThumbnail=@MainThumbnail,
		MainJPEG=@MainJPEG, CheckoutRequired=@CheckoutRequired, IP_Restriction_Mask=@IP_Restriction_Mask,
		Dark=@Dark_Flag, Born_Digital=@Born_Digital, Disposition_Advice=@Disposition_Advice,
		Material_Received_Date=@Material_Received_Date, Material_Recd_Date_Estimated=@Material_Recd_Date_Estimated,
		Tracking_Box=@Tracking_Box, Disposition_Advice_Notes = @Disposition_Advice_Notes, Left_To_Right=@Left_To_Right,
		CitationSet=@CitationSet
	where ( ItemID = @ItemID )

	-- Clear the links to all existing icons
	delete from SobekCM_Item_Icons where ItemID=@ItemID
	
	-- Add the first icon to this object  (this requires the icons have been pre-established )
	declare @IconID int
	if ( len( isnull( @Icon1_Name, '' )) > 0 ) 
	begin
		-- Get the Icon ID for this icon
		select @IconID = IconID from SobekCM_Icon where Icon_Name = @Icon1_Name

		-- Tie this item to this icon
		if ( ISNULL(@IconID,-1) > 0 )
		begin
			insert into SobekCM_Item_Icons ( ItemID, IconID, [Sequence] )
			values ( @ItemID, @IconID, 1 )
		end
	end

	-- Add the second icon to this object  (this requires the icons have been pre-established )
	if ( len( isnull( @Icon2_Name, '' )) > 0 ) 
	begin
		-- Get the Icon ID for this icon
		select @IconID = IconID from SobekCM_Icon where Icon_Name = @Icon2_Name

		-- Tie this item to this icon
		if ( ISNULL(@IconID,-1) > 0 )
		begin
			insert into SobekCM_Item_Icons ( ItemID, IconID, [Sequence] )
			values ( @ItemID, @IconID, 2 )
		end
	end

	-- Add the third icon to this object  (this requires the icons have been pre-established )
	if ( len( isnull( @Icon3_Name, '' )) > 0 ) 
	begin
		-- Get the Icon ID for this icon
		select @IconID = IconID from SobekCM_Icon where Icon_Name = @Icon3_Name

		-- Tie this item to this icon
		if ( ISNULL(@IconID,-1) > 0 )
		begin
			insert into SobekCM_Item_Icons ( ItemID, IconID, [Sequence] )
			values ( @ItemID, @IconID, 3 )
		end
	end

	-- Add the fourth icon to this object  (this requires the icons have been pre-established )
	if ( len( isnull( @Icon4_Name, '' )) > 0 ) 
	begin
		-- Get the Icon ID for this icon
		select @IconID = IconID from SobekCM_Icon where Icon_Name = @Icon4_Name
		
		-- Tie this item to this icon
		if ( ISNULL(@IconID,-1) > 0 )
		begin
			insert into SobekCM_Item_Icons ( ItemID, IconID, [Sequence] )
			values ( @ItemID, @IconID, 4 )
		end
	end

	-- Add the fifth icon to this object  (this requires the icons have been pre-established )
	if ( len( isnull( @Icon5_Name, '' )) > 0 ) 
	begin
		-- Get the Icon ID for this icon
		select @IconID = IconID from SobekCM_Icon where Icon_Name = @Icon5_Name

		-- Tie this item to this icon
		if ( ISNULL(@IconID,-1) > 0 )
		begin
			insert into SobekCM_Item_Icons ( ItemID, IconID, [Sequence] )
			values ( @ItemID, @IconID, 5 )
		end
	end

	-- Clear all links to aggregations
	delete from SobekCM_Item_Aggregation_Item_Link where ItemID = @ItemID

	-- Add all of the aggregations
	exec SobekCM_Save_Item_Item_Aggregation_Link @ItemID, @AggregationCode1
	exec SobekCM_Save_Item_Item_Aggregation_Link @ItemID, @AggregationCode2
	exec SobekCM_Save_Item_Item_Aggregation_Link @ItemID, @AggregationCode3
	exec SobekCM_Save_Item_Item_Aggregation_Link @ItemID, @AggregationCode4
	exec SobekCM_Save_Item_Item_Aggregation_Link @ItemID, @AggregationCode5
	exec SobekCM_Save_Item_Item_Aggregation_Link @ItemID, @AggregationCode6
	exec SobekCM_Save_Item_Item_Aggregation_Link @ItemID, @AggregationCode7
	exec SobekCM_Save_Item_Item_Aggregation_Link @ItemID, @AggregationCode8
	
	-- Create one string of all the aggregation codes
	declare @aggregationCodes varchar(100)
	set @aggregationCodes = rtrim(isnull(@AggregationCode1,'') + ' ' + isnull(@AggregationCode2,'') + ' ' + isnull(@AggregationCode3,'') + ' ' + isnull(@AggregationCode4,'') + ' ' + isnull(@AggregationCode5,'') + ' ' + isnull(@AggregationCode6,'') + ' ' + isnull(@AggregationCode7,'') + ' ' + isnull(@AggregationCode8,''))
	
	-- Update matching items to have the aggregation codes value
	update SobekCM_Item set AggregationCodes = @aggregationCodes where ItemID=@ItemID

	-- Check for Holding Institution Code
	declare @AggregationID int
	if ( len ( isnull ( @HoldingCode, '' ) ) > 0 )
	begin
		-- Does this institution already exist?
		if (( select count(*) from SobekCM_Item_Aggregation where Code = @HoldingCode ) = 0 )
		begin
			-- Add new institution
			insert into SobekCM_Item_Aggregation ( Code, [Name], ShortName, Description, ThematicHeadingID, [Type], isActive, Hidden, DisplayOptions, Map_Search, Map_Display, OAI_Flag, ContactEmail, HasNewItems )
			values ( @HoldingCode, 'Added automatically', 'Added automatically', 'Added automatically', -1, 'Institution', 'false', 'true', '', 0, 0, 'false', '', 'false' )
		end
		
		-- Add the link to this holding code ( and any legitimate parent aggregations )
		exec SobekCM_Save_Item_Item_Aggregation_Link @ItemID, @HoldingCode		
	end

	-- Check for Source Institution Code
	if ( len ( isnull ( @SourceCode, '' ) ) > 0 )
	begin
		-- Does this institution already exist?
		if (( select count(*) from SobekCM_Item_Aggregation where Code = @SourceCode ) = 0 )
		begin
			-- Add new institution
			insert into SobekCM_Item_Aggregation ( Code, [Name], ShortName, Description, ThematicHeadingID, [Type], isActive, Hidden, DisplayOptions, Map_Search, Map_Display, OAI_Flag, ContactEmail, HasNewItems )
			values ( @SourceCode, 'Added automatically', 'Added automatically', 'Added automatically', -1, 'Institution', 'false', 'true', '', 0, 0, 'false', '', 'false' )
		end

		-- Add the link to this holding code ( and any legitimate parent aggregations )
		exec SobekCM_Save_Item_Item_Aggregation_Link @ItemID, @SourceCode	
	end	
	
commit transaction;
GO

-- Written by Mark Sullivan 
ALTER PROCEDURE [dbo].[SobekCM_Save_Item_Behaviors_Minimal]
	@ItemID int,
	@TextSearchable bit
AS
begin transaction;

	--Update the main item
	update SobekCM_Item
	set TextSearchable = @TextSearchable
	where ( ItemID = @ItemID );

commit transaction;
GO


-- Add or update existing viewers for an item
-- NOTE: This does not delete any existing viewers
CREATE PROCEDURE SobekCM_Add_Item_Viewers 
	@ItemID int,
	@Viewer1_TypeID int,
	@Viewer1_Label nvarchar(50),
	@Viewer1_Attribute nvarchar(250),
	@Viewer2_TypeID int,
	@Viewer2_Label nvarchar(50),
	@Viewer2_Attribute nvarchar(250),
	@Viewer3_TypeID int,
	@Viewer3_Label nvarchar(50),
	@Viewer3_Attribute nvarchar(250),
	@Viewer4_TypeID int,
	@Viewer4_Label nvarchar(50),
	@Viewer4_Attribute nvarchar(250),
	@Viewer5_TypeID int,
	@Viewer5_Label nvarchar(50),
	@Viewer5_Attribute nvarchar(250),
	@Viewer6_TypeID int,
	@Viewer6_Label nvarchar(50),
	@Viewer6_Attribute nvarchar(250)
AS
BEGIN 


	--	-- Clear the links to all existing viewers
	--delete from SobekCM_Item_Viewers where ItemID=@ItemID
	
	-- Add the first viewer information
	if ( @Viewer1_TypeID > 0 )
	begin
		-- Does this already exist?
		if ( exists ( select 1 from SobekCM_Item_Viewers where ItemID=@ItemID and ItemViewTypeID=@Viewer1_TypeID ))
		begin
			-- Update this viewer information
			update SobekCM_Item_Viewers
			set Attribute=@Viewer1_Attribute, Label=@Viewer1_Label, Exclude='false'
			where ( ItemID = @ItemID )
			  and ( ItemViewTypeID = @Viewer1_TypeID );
		end
		else
		begin
			-- Insert this viewer information
			insert into SobekCM_Item_Viewers ( ItemID, ItemViewTypeID, Attribute, Label )
			values ( @ItemID, @Viewer1_TypeID, @Viewer1_Attribute, @Viewer1_Label );
		end;
	end;
	
	-- Add the second viewer information
	if ( @Viewer2_TypeID > 0 )
	begin
		-- Does this already exist?
		if ( exists ( select 1 from SobekCM_Item_Viewers where ItemID=@ItemID and ItemViewTypeID=@Viewer2_TypeID ))
		begin
			-- Update this viewer information
			update SobekCM_Item_Viewers
			set Attribute=@Viewer2_Attribute, Label=@Viewer2_Label, Exclude='false'
			where ( ItemID = @ItemID )
			  and ( ItemViewTypeID = @Viewer2_TypeID );
		end
		else
		begin
			-- Insert this viewer information
			insert into SobekCM_Item_Viewers ( ItemID, ItemViewTypeID, Attribute, Label )
			values ( @ItemID, @Viewer2_TypeID, @Viewer2_Attribute, @Viewer2_Label );
		end;
	end;
	
	-- Add the third viewer information
	if ( @Viewer3_TypeID > 0 )
	begin
		-- Does this already exist?
		if ( exists ( select 1 from SobekCM_Item_Viewers where ItemID=@ItemID and ItemViewTypeID=@Viewer3_TypeID ))
		begin
			-- Update this viewer information
			update SobekCM_Item_Viewers
			set Attribute=@Viewer3_Attribute, Label=@Viewer3_Label, Exclude='false'
			where ( ItemID = @ItemID )
			  and ( ItemViewTypeID = @Viewer3_TypeID );
		end
		else
		begin
			-- Insert this viewer information
			insert into SobekCM_Item_Viewers ( ItemID, ItemViewTypeID, Attribute, Label )
			values ( @ItemID, @Viewer3_TypeID, @Viewer3_Attribute, @Viewer3_Label );
		end;
	end;
	
	-- Add the fourth viewer information
	if ( @Viewer4_TypeID > 0 )
	begin
		-- Does this already exist?
		if ( exists ( select 1 from SobekCM_Item_Viewers where ItemID=@ItemID and ItemViewTypeID=@Viewer4_TypeID ))
		begin
			-- Update this viewer information
			update SobekCM_Item_Viewers
			set Attribute=@Viewer4_Attribute, Label=@Viewer4_Label, Exclude='false'
			where ( ItemID = @ItemID )
			  and ( ItemViewTypeID = @Viewer4_TypeID );
		end
		else
		begin
			-- Insert this viewer information
			insert into SobekCM_Item_Viewers ( ItemID, ItemViewTypeID, Attribute, Label )
			values ( @ItemID, @Viewer4_TypeID, @Viewer4_Attribute, @Viewer4_Label );
		end;
	end;
	
	-- Add the fifth viewer information
	if ( @Viewer5_TypeID > 0 )
	begin
		-- Does this already exist?
		if ( exists ( select 1 from SobekCM_Item_Viewers where ItemID=@ItemID and ItemViewTypeID=@Viewer5_TypeID ))
		begin
			-- Update this viewer information
			update SobekCM_Item_Viewers
			set Attribute=@Viewer5_Attribute, Label=@Viewer5_Label, Exclude='false'
			where ( ItemID = @ItemID )
			  and ( ItemViewTypeID = @Viewer5_TypeID );
		end
		else
		begin
			-- Insert this viewer information
			insert into SobekCM_Item_Viewers ( ItemID, ItemViewTypeID, Attribute, Label )
			values ( @ItemID, @Viewer5_TypeID, @Viewer5_Attribute, @Viewer5_Label );
		end;
	end;
	
	-- Add the first viewer information
	if ( @Viewer6_TypeID > 0 )
	begin
		-- Does this already exist?
		if ( exists ( select 1 from SobekCM_Item_Viewers where ItemID=@ItemID and ItemViewTypeID=@Viewer6_TypeID ))
		begin
			-- Update this viewer information
			update SobekCM_Item_Viewers
			set Attribute=@Viewer6_Attribute, Label=@Viewer6_Label, Exclude='false'
			where ( ItemID = @ItemID )
			  and ( ItemViewTypeID = @Viewer6_TypeID );
		end
		else
		begin
			-- Insert this viewer information
			insert into SobekCM_Item_Viewers ( ItemID, ItemViewTypeID, Attribute, Label )
			values ( @ItemID, @Viewer6_TypeID, @Viewer6_Attribute, @Viewer6_Label );
		end;
	end;

END;
GO

GRANT EXECUTE ON SobekCM_Add_Item_Viewers TO sobek_builder;
GRANT EXECUTE ON SobekCM_Add_Item_Viewers TO sobek_user;
GO


-- Remove an existing viewer for an item
-- NOTE: This does not delete any existing viewers
CREATE PROCEDURE SobekCM_Remove_Item_Viewers 
	@ItemID int,
	@Viewer1_TypeID int,
	@Viewer2_TypeID int,
	@Viewer3_TypeID int,
	@Viewer4_TypeID int,
	@Viewer5_TypeID int,
	@Viewer6_TypeID int
AS
BEGIN 

	-- Exclude the first viewer
	if ( @Viewer1_TypeID > 0 )
	begin
		update SobekCM_Item_Viewers 
		set Exclude='true' 
		where ItemID=@ItemID and ItemViewTypeID=@Viewer1_TypeID;
	end;

	-- Exclude the second viewer
	if ( @Viewer2_TypeID > 0 )
	begin
		update SobekCM_Item_Viewers 
		set Exclude='true' 
		where ItemID=@ItemID and ItemViewTypeID=@Viewer2_TypeID;
	end;

	-- Exclude the third viewer
	if ( @Viewer3_TypeID > 0 )
	begin
		update SobekCM_Item_Viewers 
		set Exclude='true' 
		where ItemID=@ItemID and ItemViewTypeID=@Viewer3_TypeID;
	end;

	-- Exclude the fourth viewer
	if ( @Viewer4_TypeID > 0 )
	begin
		update SobekCM_Item_Viewers 
		set Exclude='true' 
		where ItemID=@ItemID and ItemViewTypeID=@Viewer4_TypeID;
	end;

	-- Exclude the fifth viewer
	if ( @Viewer5_TypeID > 0 )
	begin
		update SobekCM_Item_Viewers 
		set Exclude='true' 
		where ItemID=@ItemID and ItemViewTypeID=@Viewer5_TypeID;
	end;

	-- Exclude the sixth viewer
	if ( @Viewer6_TypeID > 0 )
	begin
		update SobekCM_Item_Viewers 
		set Exclude='true' 
		where ItemID=@ItemID and ItemViewTypeID=@Viewer6_TypeID;
	end;

END;
GO

GRANT EXECUTE ON SobekCM_Remove_Item_Viewers TO sobek_builder;
GRANT EXECUTE ON SobekCM_Remove_Item_Viewers TO sobek_user;
GO

