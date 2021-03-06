/** Version 4.02 to Version 4.03 SQL script **/

--Create the Project Table
IF NOT EXISTS
(SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SobekCM_Project]') AND type in (N'U'))
BEGIN
CREATE TABLE dbo.SobekCM_Project
	(
	ProjectID int NOT NULL IDENTITY (1, 1),
	ProjectCode nvarchar(20) NULL,
	ProjectName nvarchar(100) NOT NULL,
	ProjectManager nvarchar(100) NULL,
	GrantID nvarchar(20) NULL,
	GrantName nvarchar(250) NULL,
	StartDate date NULL,
	EndDate date NULL,
	isActive bit NULL,
	Description nvarchar(1000) NULL,
	Specifications nvarchar(1000) NULL,
	Priority nvarchar(100) NULL,
	QC_Profile nvarchar(100) NULL,
	TargetItemCount int NULL,
	TargetPageCount int NULL,
	Comments nvarchar(1000) NULL,
	CopyrightPermissions nvarchar(1000) NULL
	)  ON [PRIMARY]
END
GO
ALTER TABLE dbo.SobekCM_Project ADD CONSTRAINT
	PK_SobekCM_Project PRIMARY KEY CLUSTERED 
	(
	ProjectID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.SobekCM_Project SET (LOCK_ESCALATION = TABLE)
GO


--Create the Project-Aggregation Link table
IF NOT EXISTS
(SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SobekCM_Project_Aggregation_Link]') AND type in (N'U'))
BEGIN

CREATE TABLE dbo.SobekCM_Project_Aggregation_Link
	(
	ProjectID int NOT NULL,
	AggregationID int NOT NULL
	)  ON [PRIMARY]
END
GO
ALTER TABLE dbo.SobekCM_Project_Aggregation_Link ADD CONSTRAINT
	PK_SobekCM_Project_Aggregation_Link PRIMARY KEY CLUSTERED 
	(
	ProjectID,
	AggregationID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.SobekCM_Project_Aggregation_Link SET (LOCK_ESCALATION = TABLE)
GO

--Add the foreign keys
ALTER TABLE dbo.SobekCM_Project_Aggregation_Link ADD CONSTRAINT FK_Project_Aggregation
FOREIGN KEY(ProjectID) REFERENCES SobekCM_Project(ProjectID)
ON DELETE CASCADE
ON UPDATE CASCADE
GO

--Create the Project - Default Metadata link table

IF NOT EXISTS
(SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SobekCM_Project_DefaultMetadata_Link]') AND type in (N'U'))
BEGIN

CREATE TABLE dbo.SobekCM_Project_DefaultMetadata_Link
	(
	ProjectID int NOT NULL,
	DefaultMetadataID int NOT NULL
	)  ON [PRIMARY]

END
ALTER TABLE dbo.SobekCM_Project_DefaultMetadata_Link ADD CONSTRAINT
	PK_SobekCM_Project_DefaultMetadata_Link PRIMARY KEY CLUSTERED 
	(
	ProjectID,
	DefaultMetadataID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO

--Add the foreign key constrants
ALTER TABLE dbo.SobekCM_Project_DefaultMetadata_Link SET (LOCK_ESCALATION = TABLE)
GO

ALTER TABLE dbo.SobekCM_Project_DefaultMetadata_Link ADD CONSTRAINT FK_Project
FOREIGN KEY(ProjectID) REFERENCES SobekCM_Project(ProjectID)
ON DELETE CASCADE
ON UPDATE CASCADE
GO

ALTER TABLE dbo.SobekCM_Project_DefaultMetadata_Link ADD CONSTRAINT FK_DefaultMetadata
FOREIGN KEY(DefaultMetadataID) REFERENCES mySobek_DefaultMetadata(DefaultMetadataID)
ON DELETE CASCADE
ON UPDATE CASCADE
GO


--Create the Project-Template Link table
IF NOT EXISTS
(SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SobekCM_Project_Template_Link]') AND type in (N'U'))
BEGIN
CREATE TABLE dbo.SobekCM_Project_Template_Link
	(
	ProjectID int NOT NULL,
	TemplateID int NOT NULL
	)  ON [PRIMARY]
END

ALTER TABLE dbo.SobekCM_Project_Template_Link ADD CONSTRAINT
	PK_SobekCM_Project_Template_Link PRIMARY KEY CLUSTERED 
	(
	ProjectID,
	TemplateID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.SobekCM_Project_Template_Link SET (LOCK_ESCALATION = TABLE)
GO

--Add the foreign key constraints
ALTER TABLE dbo.SobekCM_Project_Template_Link ADD CONSTRAINT FK_Project_1
FOREIGN KEY(ProjectID) REFERENCES SobekCM_Project(ProjectID)
ON DELETE CASCADE
ON UPDATE CASCADE
GO

ALTER TABLE dbo.SobekCM_Project_Template_Link ADD CONSTRAINT FK_Template
FOREIGN KEY(TemplateID) REFERENCES mySobek_Template(TemplateID)
ON DELETE CASCADE
ON UPDATE CASCADE
GO


--Create the Project_Item Link Table
IF NOT EXISTS
(SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SobekCM_Project_Item_Link]') AND type in (N'U'))
BEGIN
CREATE TABLE dbo.SobekCM_Project_Item_Link
	(
	ProjectID int NOT NULL,
	ItemID int NOT NULL
	)  ON [PRIMARY]
END
GO


ALTER TABLE dbo.SobekCM_Project_Item_Link ADD CONSTRAINT
	PK_SobekCM_Project_Item_Link PRIMARY KEY CLUSTERED 
	(
	ProjectID,
	ItemID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
ALTER TABLE dbo.SobekCM_Project_Item_Link SET (LOCK_ESCALATION = TABLE)
GO

--Create the foreign key constraints
ALTER TABLE dbo.SobekCM_Project_Item_Link ADD CONSTRAINT FK_Project_Item_ProjectID
FOREIGN KEY(ProjectID) REFERENCES SobekCM_Project(ProjectID)
ON DELETE CASCADE
ON UPDATE CASCADE
GO

ALTER TABLE dbo.SobekCM_Project_Item_Link ADD CONSTRAINT FK_Project_Item_ItemID
FOREIGN KEY(ItemID) REFERENCES SobekCM_Item(ItemID)
ON DELETE CASCADE
ON UPDATE CASCADE
GO


--Create the stored procedure to save/edit a Project

-- Ensure the stored procedure exists
IF object_id('SobekCM_Save_Project') IS NULL EXEC ('create procedure dbo.SobekCM_Save_Project as select 1;');
GO



ALTER PROCEDURE [dbo].[SobekCM_Save_Project]
	@ProjectID int,
	@ProjectCode nvarchar(20),
	@ProjectName nvarchar(100),
	@ProjectManager nvarchar(100),
	@GrantID nvarchar(250),
	@GrantName bigint,
	@StartDate date,
	@EndDate date,
	@isActive bit,
	@Description nvarchar(MAX),
	@Specifications nvarchar(MAX),
	@Priority nvarchar(100),
	@QC_Profile nvarchar(100),
	@TargetItemCount int,
	@TargetPageCount int,
	@Comments nvarchar(MAX),
	@CopyrightPermissions nvarchar(1000),
	@New_ProjectID int output
	
AS
  Begin transaction

	-- Set the return ProjectID value first
	set @New_ProjectID = @ProjectID;
	

	-- If this project does not exist (ProjectID) insert, else update
	if (( select count(*) from SobekCM_Project  where ( ProjectID = @ProjectID ))  < 1 )
	   begin	
	    	-- begin insert
		    insert into SobekCM_Project (ProjectCode, ProjectName, ProjectManager, GrantID, GrantName, StartDate, EndDate, isActive, [Description], Specifications, [Priority],QC_Profile, TargetItemCount, TargetPageCount, Comments, CopyrightPermissions)
		    values (@ProjectCode, @ProjectName, @ProjectManager, @GrantID, @GrantName, @StartDate, @EndDate, @isActive, @Description, @Specifications, @Priority, @QC_Profile, @TargetItemCount, @TargetPageCount, @Comments, @CopyrightPermissions);
     	--Get the new ProjectID for this row
     	set @New_ProjectID = @@IDENTITY;
     	end
	else
	    begin
	    --update the corresponding row in the SobekCM_Project table
	    update SobekCM_Project
	    set ProjectCode=@ProjectCode, ProjectName=@ProjectName, ProjectManager=@ProjectManager, GrantID=@GrantID, GrantName=@GrantName, StartDate=@StartDate, EndDate=@EndDate, isActive=@isActive, [Description]=@Description, Specifications=@Specifications, [Priority]=@Priority, QC_Profile=@QC_Profile, TargetItemCount=@TargetItemCount, TargetPageCount=@TargetPageCount, Comments=@Comments, CopyrightPermissions=@CopyrightPermissions
	    where ProjectID=@ProjectID;
	    end	
		
commit transaction;		
GO

--Stored procedure for creating a Project_Aggregation Link
-- Ensure the stored procedure exists
IF object_id('SobekCM_Save_Project_Aggregation_Link') IS NULL EXEC ('create procedure dbo.SobekCM_Save_Project_Aggregation_Link as select 1;');
GO



ALTER PROCEDURE [dbo].[SobekCM_Save_Project_Aggregation_Link]
	@ProjectID int,
	@AggregationID int
	
AS
Begin
  --If this link does not already exist, insert it
  if((select count(*) from SobekCM_Project_Aggregation_Link  where ( ProjectID = @ProjectID and AggregationID=@AggregationID ))  < 1 )
    insert into SobekCM_Project_Aggregation_Link(ProjectID, AggregationID)
    values(@ProjectID, @AggregationID);
End
GO

--Stored procedure to insert a new Project-DefaultMetadata Link
-- Ensure the stored procedure exists
IF object_id('SobekCM_Save_Project_DefaultMetadata_Link') IS NULL EXEC ('create procedure dbo.SobekCM_Save_Project_DefaultMetadata_Link as select 1;');
GO



ALTER PROCEDURE [dbo].[SobekCM_Save_Project_DefaultMetadata_Link]
	@ProjectID int,
	@DefaultMetadataID int
	
AS
Begin
  --If this link does not already exist, insert it
  if((select count(*) from SobekCM_Project_DefaultMetadata_Link  where ( ProjectID = @ProjectID and DefaultMetadataID=@DefaultMetadataID ))  < 1 )
    insert into SobekCM_Project_DefaultMetadata_Link(ProjectID, DefaultMetadataID)
    values(@ProjectID, @DefaultMetadataID);
End
GO

--Stored procedure to create Project - Template Link
-- Ensure the stored procedure exists
IF object_id('SobekCM_Save_Project_Template_Link') IS NULL EXEC ('create procedure dbo.SobekCM_Save_Project_Template_Link as select 1;');
GO



ALTER PROCEDURE [dbo].[SobekCM_Save_Project_Template_Link]
	@ProjectID int,
	@TemplateID int
	
AS
Begin
  --If this link does not already exist, insert it
  if((select count(*) from SobekCM_Project_Template_Link  where ( ProjectID = @ProjectID and TemplateID=@TemplateID ))  < 1 )
    insert into SobekCM_Project_Template_Link(ProjectID, TemplateID)
    values(@ProjectID, @TemplateID);
End
GO

--Stored procedure for creating a new Project-Item link
-- Ensure the stored procedure exists
IF object_id('SobekCM_Save_Project_Item_Link') IS NULL EXEC ('create procedure dbo.SobekCM_Save_Project_Item_Link as select 1;');
GO



ALTER PROCEDURE [dbo].[SobekCM_Save_Project_Item_Link]
	@ProjectID int,
	@ItemID int
	
AS
Begin
  --If this link does not already exist, insert it
  if((select count(*) from SobekCM_Project_Item_Link  where ( ProjectID = @ProjectID and ItemID=@ItemID ))  < 1 )
    insert into SobekCM_Project_Item_Link(ProjectID, ItemID)
    values(@ProjectID, @ItemID);
End
GO

--Delete a Project-Item link
-- Ensure the stored procedure exists
IF object_id('SobekCM_Delete_Project_Item_Link') IS NULL EXEC ('create procedure dbo.SobekCM_Delete_Project_Item_Link as select 1;');
GO



ALTER PROCEDURE [dbo].[SobekCM_Delete_Project_Item_Link]
	@ProjectID int,
	@ItemID int
	
AS
Begin
  --If this link exists, delete it
  if((select count(*) from SobekCM_Project_Item_Link  where ( ProjectID = @ProjectID and ItemID=@ItemID ))  = 1 )
    delete from SobekCM_Project_Item_Link
    where (ProjectID=@ProjectID and ItemID=@ItemID);
End
GO


--Delete a Project-DefaultMetadata Link
-- Ensure the stored procedure exists
IF object_id('SobekCM_Delete_Project_DefaultMetadata_Link') IS NULL EXEC ('create procedure dbo.SobekCM_Delete_Project_DefaultMetadata_Link as select 1;');
GO



ALTER PROCEDURE [dbo].[SobekCM_Delete_Project_DefaultMetadata_Link]
	@ProjectID int,
	@DefaultMetadataID int
	
AS
Begin
  --If this link exists, delete it
  if((select count(*) from SobekCM_Project_DefaultMetadata_Link  where ( ProjectID = @ProjectID and DefaultMetadataID=@DefaultMetadataID ))  = 1 )
    delete from SobekCM_Project_DefaultMetadata_Link
    where (ProjectID=@ProjectID and DefaultMetadataID=@DefaultMetadataID);
End
GO

--Delete Project-Input Template link

-- Ensure the stored procedure exists
IF object_id('SobekCM_Delete_Project_Template_Link') IS NULL EXEC ('create procedure dbo.SobekCM_Delete_Project_Template_Link as select 1;');
GO



ALTER PROCEDURE [dbo].[SobekCM_Delete_Project_Template_Link]
	@ProjectID int,
	@TemplateID int
	
AS
Begin
  --If this link exists, delete it
  if((select count(*) from SobekCM_Project_Template_Link  where ( ProjectID = @ProjectID and TemplateID=@TemplateID ))  = 1 )
    delete from SobekCM_Project_Template_Link
    where (ProjectID=@ProjectID and TemplateID=@TemplateID);
End
GO


--Delete the Project-Aggregation Link

-- Ensure the stored procedure exists
IF object_id('SobekCM_Delete_Project_Aggregation_Link') IS NULL EXEC ('create procedure dbo.SobekCM_Delete_Project_Aggregation_Link as select 1;');
GO



ALTER PROCEDURE [dbo].[SobekCM_Delete_Project_Aggregation_Link]
	@ProjectID int,
	@AggregationID int
	
AS
Begin
  --If this link exists, delete it
  if((select count(*) from SobekCM_Project_Aggregation_Link  where ( ProjectID = @ProjectID and AggregationID=@AggregationID ))  = 1 )
    delete from SobekCM_Project_Aggregation_Link
    where (ProjectID=@ProjectID and AggregationID=@AggregationID);
End
GO

--Get the aggregations by ProjectID
-- Ensure the stored procedure exists
IF object_id('SobekCM_Get_Aggregations_By_ProjectID') IS NULL EXEC ('create procedure dbo.SobekCM_Get_Aggregations_By_ProjectID as select 1;');
GO


ALTER PROCEDURE [dbo].[SobekCM_Get_Aggregations_By_ProjectID]
	@ProjectID int
		
AS
Begin
  
  select AggregationID from SobekCM_Project_Aggregation_Link
  where ProjectID=@ProjectID;
 End
 GO
 
 --Get Items by ProjectID
 -- Ensure the stored procedure exists
IF object_id('SobekCM_Get_Items_By_ProjectID') IS NULL EXEC ('create procedure dbo.SobekCM_Get_Items_By_ProjectID as select 1;');
GO


ALTER PROCEDURE [dbo].[SobekCM_Get_Items_By_ProjectID]
	@ProjectID int
		
AS
Begin
  
  select ItemID from SobekCM_Project_Item_Link
  where ProjectID=@ProjectID;
 End
 GO

--Get the default metadata by Project ID
-- Ensure the stored procedure exists
IF object_id('SobekCM_Get_DefaultMetadata_By_ProjectID') IS NULL EXEC ('create procedure dbo.SobekCM_Get_DefaultMetadata_By_ProjectID as select 1;');
GO


ALTER PROCEDURE [dbo].[SobekCM_Get_DefaultMetadata_By_ProjectID]
	@ProjectID int
		
AS
Begin
  
  select DefaultMetadataID from SobekCM_Project_DefaultMetadata_Link
  where ProjectID=@ProjectID;
 End
 GO

 --Get the templates by ProjectID
 -- Ensure the stored procedure exists
IF object_id('SobekCM_Get_Templates_By_ProjectID') IS NULL EXEC ('create procedure dbo.SobekCM_Get_Templates_By_ProjectID as select 1;');
GO


ALTER PROCEDURE [dbo].[SobekCM_Get_Templates_By_ProjectID]
	@ProjectID int
		
AS
Begin
  
  select TemplateID from SobekCM_Project_Template_Link
  where ProjectID=@ProjectID;
 End
GO

 
 -- Add internal notes to the user table
alter table mySobek_User add InternalNotes nvarchar(500) null;
GO


-- Add columns to the user group table for the group to be a default 
-- depending on the authentication method
alter table mySobek_User_Group add IsSobekDefault bit not null default('false');
alter table mySobek_User_Group add IsShibbolethDefault bit not null default('false');
alter table mySobek_User_Group add IsLdapDefault bit not null default('false');
GO

-- Rename UFID to ShibbID ( last remnant of UFDC-only original design)
sp_RENAME 'mySobek_User.UFID' , 'ShibbID', 'COLUMN';
GO

/****** Object:  StoredProcedure [dbo].[mySobek_Save_User2]    Script Date: 12/20/2013 05:43:36 ******/
-- Saves a user
ALTER PROCEDURE [dbo].[mySobek_Save_User]
	@userid int,
	@shibbid char(8),
	@username nvarchar(100),
	@password nvarchar(100),
	@emailaddress nvarchar(100),
	@firstname nvarchar(100),
	@lastname nvarchar(100),
	@cansubmititems bit,
	@nickname nvarchar(100),
	@organization nvarchar(250),
	@college nvarchar(250),
	@department nvarchar(250),
	@unit nvarchar(250),
	@rights nvarchar(1000),
	@sendemail bit,
	@language nvarchar(50),
	@default_template varchar(50),
	@default_metadata varchar(50),
	@organization_code varchar(15),
	@receivestatsemail bit,
	@scanningtechnician bit,
	@processingtechnician bit,
	@internalnotes nvarchar(500),
	@authentication varchar(20)
	
AS
BEGIN

	if ( @userid < 0 )
	begin

		-- Add this into the user table first
		insert into mySobek_User ( ShibbID, UserName, [Password], EmailAddress, LastName, FirstName, DateCreated, LastActivity, isActive,  Note_Length, Can_Make_Folders_Public, isTemporary_Password, Can_Submit_Items, NickName, Organization, College, Department, Unit, Default_Rights, sendEmailOnSubmission, UI_Language, Internal_User, OrganizationCode, Receive_Stats_Emails, Include_Tracking_Standard_Forms, ScanningTechnician, ProcessingTechnician, InternalNotes )
		values ( @shibbid, @username, @password, @emailaddress, @lastname, @firstname, getdate(), getDate(), 'true', 1000, 'true', 'false', @cansubmititems, @nickname, @organization, @college, @department, @unit, @rights, @sendemail, @language, 'false', @organization_code, @receivestatsemail, 'false', @scanningtechnician, @processingtechnician, @internalnotes );

		-- Get the user is
		declare @newuserid int;
		set @newuserid = @@identity;
		
		-- This is a brand new user, so we must set the default groups, according to
		-- the authentication method
		-- Authentticated used the built-in Sobek authentication
		if (( @authentication='sobek' ) and (( select count(*) from mySobek_user_Group where IsSobekDefault = 'true' ) > 0 ))
		begin
			-- insert any groups set as default for this
			insert into mySobek_User_Group_Link ( UserID, UserGroupID )
			select @newuserid, UserGroupID
			from mySobek_User_Group where IsSobekDefault='true';
		end;
		
		-- Authenticated using Shibboleth authentication
		if (( @authentication='shibboleth' ) and (( select count(*) from mySobek_user_Group where IsShibbolethDefault = 'true' ) > 0 ))
		begin
			-- insert any groups set as default for this
			insert into mySobek_User_Group_Link ( UserID, UserGroupID )
			select @newuserid, UserGroupID
			from mySobek_User_Group where IsShibbolethDefault='true';
		end;
		
		-- Authenticated using Ldap authentication
		if (( @authentication='ldap' ) and (( select count(*) from mySobek_user_Group where IsLdapDefault = 'true' ) > 0 ))
		begin
			-- insert any groups set as default for this
			insert into mySobek_User_Group_Link ( UserID, UserGroupID )
			select @newuserid, UserGroupID
			from mySobek_User_Group where IsLdapDefault='true';
		end;
	end
	else
	begin

		-- Update this user
		update mySobek_User
		set ShibbID = @shibbid, UserName = @username, EmailAddress=@emailAddress,
			Firstname = @firstname, Lastname = @lastname, Can_Submit_Items = @cansubmititems,
			NickName = @nickname, Organization=@organization, College=@college, Department=@department,
			Unit=@unit, Default_Rights=@rights, sendEmailOnSubmission = @sendemail, UI_Language=@language,
			OrganizationCode=@organization_code, Receive_Stats_Emails=@receivestatsemail,
			ScanningTechnician=@scanningtechnician, ProcessingTechnician=@processingtechnician,
			InternalNotes=@internalnotes
		where UserID = @userid;

		-- Set the default template
		if ( len( @default_template ) > 0 )
		begin
			-- Get the template id
			declare @templateid int;
			select @templateid = TemplateID from mySobek_Template where TemplateCode=@default_template;

			-- Clear the current default template
			update mySobek_User_Template_Link set DefaultTemplate = 'false' where UserID=@userid;

			-- Does this link already exist?
			if (( select count(*) from mySobek_User_Template_Link where UserID=@userid and TemplateID=@templateid ) > 0 )
			begin
				-- Update the link
				update mySobek_User_Template_Link set DefaultTemplate = 'true' where UserID=@userid and TemplateID=@templateid;
			end
			else
			begin
				-- Just add this link
				insert into mySobek_User_Template_Link ( UserID, TemplateID, DefaultTemplate ) values ( @userid, @templateid, 'true' );
			end;
		end;

		-- Set the default metadata
		if ( len( @default_metadata ) > 0 )
		begin
			-- Get the project id
			declare @projectid int;
			select @projectid = DefaultMetadataID from mySobek_DefaultMetadata where MetadataCode=@default_metadata;

			-- Clear the current default project
			update mySobek_User_DefaultMetadata_Link set CurrentlySelected = 'false' where UserID=@userid;

			-- Does this link already exist?
			if (( select count(*) from mySobek_User_DefaultMetadata_Link where UserID=@userid and DefaultMetadataID=@projectid ) > 0 )
			begin
				-- Update the link
				update mySobek_User_DefaultMetadata_Link set CurrentlySelected = 'true' where UserID=@userid and DefaultMetadataID=@projectid;
			end
			else
			begin
				-- Just add this link
				insert into mySobek_User_DefaultMetadata_Link ( UserID, DefaultMetadataID, CurrentlySelected ) values ( @userid, @projectid, 'true' );
			end;
		end;
	end;
END;
GO

/****** Object:  StoredProcedure [dbo].[mySobek_Get_User_By_UserID]    Script Date: 12/20/2013 05:43:35 ******/
ALTER PROCEDURE [dbo].[mySobek_Get_User_By_UserID]
	@userid int
AS
BEGIN

	-- No need to perform any locks here
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	-- Get the basic user information
	select UserID, ShibbID=coalesce(ShibbID,''), UserName=coalesce(UserName,''), EmailAddress=coalesce(EmailAddress,''), 
	  FirstName=coalesce(FirstName,''), LastName=coalesce(LastName,''), Note_Length, 
	  Can_Make_Folders_Public, isTemporary_Password, sendEmailOnSubmission, Can_Submit_Items, 
	  NickName=coalesce(NickName,''), Organization=coalesce(Organization, ''), College=coalesce(College,''),
	  Department=coalesce(Department,''), Unit=coalesce(Unit,''), Rights=coalesce(Default_Rights,''), Language=coalesce(UI_Language, ''), 
	  Internal_User, OrganizationCode, EditTemplate, EditTemplateMarc, IsSystemAdmin, IsPortalAdmin, Include_Tracking_Standard_Forms,
	  Descriptions=( select COUNT(*) from mySobek_User_Description_Tags T where T.UserID=U.UserID),
	  Receive_Stats_Emails, Has_Item_Stats, Can_Delete_All_Items, ScanningTechnician, ProcessingTechnician, InternalNotes=coalesce(InternalNotes,'')
	from mySobek_User U
	where ( UserID = @userid ) and ( isActive = 'true' );

	-- Get the templates
	select T.TemplateCode, T.TemplateName, GroupDefined='false', DefaultTemplate
	from mySobek_Template T, mySobek_User_Template_Link L
	where ( L.UserID = @userid ) and ( L.TemplateID = T.TemplateID )
	union
	select T.TemplateCode, T.TemplateName, GroupDefined='true', 'false'
	from mySobek_Template T, mySobek_User_Group_Template_Link TL, mySobek_User_Group_Link GL
	where ( GL.UserID = @userid ) and ( GL.UserGroupID = TL.UserGroupID ) and ( TL.TemplateID = T.TemplateID )
	order by DefaultTemplate DESC, TemplateCode ASC;
	
	-- Get the default metadata
	select P.MetadataCode, P.MetadataName, GroupDefined='false', CurrentlySelected
	from mySobek_DefaultMetadata P, mySobek_User_DefaultMetadata_Link L
	where ( L.UserID = @userid ) and ( L.DefaultMetadataID = P.DefaultMetadataID )
	union
	select P.MetadataCode, P.MetadataName, GroupDefined='true', 'false'
	from mySobek_DefaultMetadata P, mySobek_User_Group_DefaultMetadata_Link PL, mySobek_User_Group_Link GL
	where ( GL.UserID = @userid ) and ( GL.UserGroupID = PL.UserGroupID ) and ( PL.DefaultMetadataID = P.DefaultMetadataID )
	order by CurrentlySelected DESC, MetadataCode ASC;

	-- Get the bib id's of items submitted
	select distinct( G.BibID )
	from mySobek_User_Folder F, mySobek_User_Item B, SobekCM_Item I, SobekCM_Item_Group G
	where ( F.UserID = @userid ) and ( B.UserFolderID = F.UserFolderID ) and ( F.FolderName = 'Submitted Items' ) and ( B.ItemID = I.ItemID ) and ( I.GroupID = G.GroupID );

	-- Get the regular expression for editable items
	select R.EditableRegex, GroupDefined='false', CanEditMetadata, CanEditBehaviors, CanPerformQc, CanUploadFiles, CanChangeVisibility, CanDelete
	from mySobek_Editable_Regex R, mySobek_User_Editable_Link L
	where ( L.UserID = @userid ) and ( L.EditableID = R.EditableID )
	union
	select R.EditableRegex, GroupDefined='true', CanEditMetadata, CanEditBehaviors, CanPerformQc, CanUploadFiles, CanChangeVisibility, CanDelete
	from mySobek_Editable_Regex R, mySobek_User_Group_Editable_Link L, mySobek_User_Group_Link GL
	where ( GL.UserID = @userid ) and ( GL.UserGroupID = L.UserGroupID ) and ( L.EditableID = R.EditableID );

	-- Get the list of aggregations associated with this user
	select A.Code, A.[Name], L.CanSelect, L.CanEditItems, L.IsAdmin AS IsAggregationAdmin, L.OnHomePage, L.IsCurator AS IsCollectionManager, GroupDefined='false', CanEditMetadata, CanEditBehaviors, CanPerformQc, CanUploadFiles, CanChangeVisibility, CanDelete
	from SobekCM_Item_Aggregation A, mySobek_User_Edit_Aggregation L
	where  ( L.AggregationID = A.AggregationID ) and ( L.UserID = @userid )
	union
	select A.Code, A.[Name], L.CanSelect, L.CanEditItems, L.IsAdmin AS IsAggregationAdmin, OnHomePage = 'false', L.IsCurator AS IsCollectionManager, GroupDefined='true', CanEditMetadata, CanEditBehaviors, CanPerformQc, CanUploadFiles, CanChangeVisibility, CanDelete
	from SobekCM_Item_Aggregation A, mySobek_User_Group_Edit_Aggregation L, mySobek_User_Group_Link GL
	where  ( L.AggregationID = A.AggregationID ) and ( GL.UserID = @userid ) and ( GL.UserGroupID = L.UserGroupID );

	-- Return the names of all the folders
	select F.FolderName, F.UserFolderID, ParentFolderID=isnull(F.ParentFolderID,-1), isPublic
	from mySobek_User_Folder F
	where ( F.UserID=@userid );

	-- Get the list of all items associated with a user folder (other than submitted items)
	select G.BibID, I.VID
	from mySobek_User_Folder F, mySobek_User_Item B, SobekCM_Item I, SobekCM_Item_Group G
	where ( F.UserID = @userid ) and ( B.UserFolderID = F.UserFolderID ) and ( F.FolderName != 'Submitted Items' ) and ( B.ItemID = I.ItemID ) and ( I.GroupID = G.GroupID );
	
	-- Get the list of all user groups associated with this user
	select G.GroupName, Can_Submit_Items, Internal_User, IsSystemAdmin, IsPortalAdmin, Include_Tracking_Standard_Forms 
	from mySobek_User_Group G, mySobek_User_Group_Link L
	where ( G.UserGroupID = L.UserGroupID )
	  and ( L.UserID = @userid );
	  
	-- Get the user settings
	select * from mySobek_User_Settings where UserID=@userid;
	  
	-- Update the user table to include this as the last activity
	update mySobek_User
	set LastActivity = getdate()
	where UserID=@userid;
END;
GO


/****** Object:  StoredProcedure [dbo].[mySobek_Save_User_Group]    Script Date: 12/20/2013 05:43:36 ******/
-- Saves information about a single user group
ALTER PROCEDURE [dbo].[mySobek_Save_User_Group]
	@usergroupid int,
	@groupname nvarchar(150),
	@groupdescription nvarchar(1000),
	@can_submit_items bit,
	@is_internal bit,
	@can_edit_all bit,
	@is_system_admin bit,
	@is_portal_admin bit,
	@include_tracking_standard_forms bit,
	@clear_metadata_templates bit,
	@clear_aggregation_links bit,
	@clear_editable_links bit,
	@is_sobek_default bit,
	@is_shibboleth_default bit,
	@is_ldap_default bit,
	@new_usergroupid int output
AS 
begin
	
	-- Is there a user group id provided
	if ( @usergroupid < 0 )
	begin
		-- Insert as a new user group
		insert into mySobek_User_Group ( GroupName, GroupDescription, Can_Submit_Items, Internal_User, IsSystemAdmin, IsPortalAdmin, Include_Tracking_Standard_Forms, IsSobekDefault, IsShibbolethDefault, IsLdapDefault  )
		values ( @groupname, @groupdescription, @can_submit_items, @is_internal, @is_system_admin, @is_portal_admin, @include_tracking_standard_forms, @is_sobek_default, @is_shibboleth_default, @is_ldap_default );
		
		-- Return the new primary key
		set @new_usergroupid = @@IDENTITY;	
	end
	else
	begin
		-- Update, if it exists
		update mySobek_User_Group
		set GroupName = @groupname, GroupDescription = @groupdescription, Can_Submit_Items = @can_submit_items, Internal_User=@is_internal, IsSystemAdmin=@is_system_admin, IsPortalAdmin=@is_portal_admin, Include_Tracking_Standard_Forms=@include_tracking_standard_forms, 
			IsSobekDefault=@is_sobek_default, IsShibbolethDefault=@is_shibboleth_default, IsLdapDefault=@is_ldap_default
		where UserGroupID = @usergroupid;
	
	end;
	
	-- Check the flag to edit all items
	if ( @can_edit_all = 'true' )
	begin	
		if ( ( select count(*) from mySobek_User_Group_Editable_Link where EditableID=1 and UserGroupID=@usergroupid ) = 0 )
		begin
			-- Add the link to the ALL EDITABLE
			insert into mySobek_User_Group_Editable_Link ( UserGroupID, EditableID )
			values ( @usergroupid, 1 );
		end
	end
	else
	begin
		-- Delete the link to all
		delete from mySobek_User_Group_Editable_Link where EditableID = 1 and UserGroupID=@usergroupid;
	end;
	
		-- Clear the projects/templates
	if ( @clear_metadata_templates = 'true' )
	begin
		delete from mySobek_User_Group_DefaultMetadata_Link where UserGroupID=@usergroupid;
		delete from mySobek_User_Group_Template_Link where UserGroupID=@usergroupid;
	end;

	-- Clear the aggregations link
	if ( @clear_aggregation_links = 'true' )
	begin
		delete from mySobek_User_Group_Edit_Aggregation where UserGroupID=@usergroupid;
	end;
	
	-- Clear the editable link
	if ( @clear_editable_links = 'true' )
	begin
		delete from mySobek_User_Group_Editable_Link where UserGroupID=@usergroupid;
	end;

end;
GO

CREATE PROCEDURE [dbo].[mySobek_Get_User_By_ShibbID]
	@shibbid char(8)
AS
BEGIN  

	-- No need to perform any locks here.  A slightly dirty read won't hurt much
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
	-- Look for the user by Shibboleth ID.  Does one exist?
	if (( select COUNT(*) from mySobek_User where ShibbID=@shibbid and isActive = 'true' ) = 1 )
	begin
		-- Get the userid for this user
		declare @userid int;
		select @userid = UserID from mySobek_User where ShibbID=@shibbid and isActive = 'true';  
  
		-- Stored procedure used to return standard data across all user fetch stored procedures
		exec mySobek_Get_User_By_UserID @userid; 
	end;
END;
GO

GRANT EXECUTE ON [dbo].[mySobek_Get_User_By_ShibbID] to sobek_user;
GO

DROP PROCEDURE [dbo].[mySobek_Get_User_By_UFID];
GO

UPDATE mySobek_User set ProcessingTechnician='false' where ProcessingTechnician is null;
UPDATE mySobek_User set ScanningTechnician='false' where ScanningTechnician is null;
GO

ALTER TABLE mySobek_User ALTER COLUMN ProcessingTechnician bit not null;
ALTER TABLE mySobek_User ALTER COLUMN ScanningTechnician bit not null;
GO





alter table mySobek_User_Group add IsSpecialGroup bit not null default('false');
GO



ALTER PROCEDURE dbo.mySobek_Get_All_User_Groups AS
BEGIN

	with linked_users_cte ( UserGroupID, UserCount ) AS
	(
		select UserGroupID, count(*)
		from mySobek_User_Group_Link
		group by UserGroupID
	)
	select G.UserGroupID, GroupName, GroupDescription, coalesce(UserCount,0) as UserCount, IsSpecialGroup
	from mySobek_User_Group G 
	     left outer join linked_users_cte U on U.UserGroupID=G.UserGroupID
	order by IsSpecialGroup, GroupName;

END
GO

GRANT EXECUTE ON dbo.mySobek_Get_All_User_Groups to sobek_user;
GO

drop table mySobek_User_Item_Permissions;
go



CREATE TABLE [dbo].[mySobek_User_Item_Permissions](
	[UserPermissionID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[ItemID] [int] NOT NULL,
	[isOwner] [bit] NOT NULL,
	[canView] [bit] NULL,
	[canEditMetadata] [bit] NULL,
	[canEditBehaviors] [bit] NULL,
	[canPerformQc] [bit] NULL,
	[canUploadFiles] [bit] NULL,
	[canChangeVisibility] [bit] NULL,
	[canDelete] [bit] NULL,
	[customPermissions] [varchar](max) NULL,
 CONSTRAINT [PK_mySobek_User_Item_Permissions] PRIMARY KEY CLUSTERED 
(
	[UserPermissionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO


ALTER TABLE [mySobek_User_Item_Permissions]
ADD CONSTRAINT fk_mySobek_User_Item_Permissions_UserID
FOREIGN KEY (UserID)
REFERENCES mySobek_User(UserID);
GO

ALTER TABLE [mySobek_User_Item_Permissions]
ADD CONSTRAINT fk_mySobek_User_Item_Permissions_ItemID
FOREIGN KEY (ItemID)
REFERENCES SobekCM_Item(ItemID);
GO


CREATE TABLE [dbo].[mySobek_User_Group_Item_Permissions](
	[UserGroupPermissionID] [int] IDENTITY(1,1) NOT NULL,
	[UserGroupID] [int] NOT NULL,
	[ItemID] [int] NULL,
	[isOwner] [bit] NOT NULL,
	[canView] [bit] NULL,
	[canEditMetadata] [bit] NULL,
	[canEditBehaviors] [bit] NULL,
	[canPerformQc] [bit] NULL,
	[canUploadFiles] [bit] NULL,
	[canChangeVisibility] [bit] NULL,
	[canDelete] [bit] NULL,
	[customPermissions] [varchar](max) NULL,
	[isDefaultPermissions] [bit] NOT NULL,
 CONSTRAINT [PK_mySobek_User_Group_Item_Permissions] PRIMARY KEY CLUSTERED 
(
	[UserGroupPermissionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

ALTER TABLE [dbo].[mySobek_User_Group_Item_Permissions] ADD  DEFAULT ('false') FOR [isDefaultPermissions]
GO


ALTER TABLE [mySobek_User_Group_Item_Permissions]
ADD CONSTRAINT fk_mySobek_User_Group_Item_Permissions_UserGroupID
FOREIGN KEY (UserGroupID)
REFERENCES mySobek_User_Group(UserGroupID);
GO

ALTER TABLE [mySobek_User_Group_Item_Permissions]
ADD CONSTRAINT fk_mySobek_User_Group_Item_Permissions_ItemID
FOREIGN KEY (ItemID)
REFERENCES SobekCM_Item(ItemID);
GO




SET IDENTITY_INSERT mySobek_User_Group ON;
GO

insert into mySobek_User_Group ( UserGroupID, GroupName, GroupDescription, Can_Submit_Items, Internal_User, IsSystemAdmin, IsPortalAdmin, Include_Tracking_Standard_Forms, autoAssignUsers, Can_Delete_All_Items, IsSobekDefault, IsShibbolethDefault, IsLdapDefault, IsSpecialGroup )
values ( -1, 'Everyone', 'Default everyone group within the SobekCM system', 'false', 'false', 'false', 'false', 'false', 'true', 'false', 'false', 'false', 'false', 'true' );
GO

SET IDENTITY_INSERT mySobek_User_Group OFF;
GO

ALTER PROCEDURE [dbo].[mySobek_Delete_User_Group]
	@usergroupid int
AS
begin
	delete from mySobek_User_Group
	where UserGroupID = @usergroupid
	  and isSpecialGroup = 'false';
end
GO

ALTER PROCEDURE [dbo].[mySobek_Get_All_Users] AS
BEGIN
	
	select UserID, LastName + ', ' + FirstName AS [Full_Name], UserName, EmailAddress
	from mySobek_User 
	order by Full_Name;
END;
GO



/****** Object:  StoredProcedure [dbo].[SobekCM_Get_Item_Details2]    Script Date: 12/20/2013 05:43:36 ******/
-- Pull any additional item details before showing this item
ALTER PROCEDURE [dbo].[SobekCM_Get_Item_Details2]
	@BibID varchar(10),
	@VID varchar(5)
AS
BEGIN

	-- No need to perform any locks here
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	-- Was this for one item within a group?
	if ( LEN( ISNULL(@VID,'')) > 0 )
	begin	
	
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
				T.EmbargoEnd, coalesce(T.UMI,'') as UMI, T.Original_EmbargoEnd, coalesce(T.Original_AccessCode,'') as Original_AccessCode
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
			select T.ViewType, V.Attribute, V.Label
			from SobekCM_Item_Viewers V, SobekCM_Item_Viewer_Types T
			where ( V.ItemID = @ItemID )
			  and ( V.ItemViewTypeID = T.ItemViewTypeID );
				
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

		-- Return the individual volumes
		select I.ItemID, Title, Level1_Text=isnull(Level1_Text,''), Level1_Index=isnull(Level1_Index,-1), Level2_Text=isnull(Level2_Text, ''), Level2_Index=isnull(Level2_Index, -1), Level3_Text=isnull(Level3_Text, ''), Level3_Index=isnull(Level3_Index, -1), Level4_Text=isnull(Level4_Text, ''), Level4_Index=isnull(Level4_Index, -1), Level5_Text=isnull(Level5_Text, ''), Level5_Index=isnull(Level5_Index,-1), I.MainThumbnail, I.VID, I.IP_Restriction_Mask, I.SortTitle, I.Dark
		from SobekCM_Item I, SobekCM_Item_Group G
		where ( G.GroupID = I.GroupID )
		  and ( G.BibID = @bibid )
		  and ( I.Deleted = 'false' )
		  and ( G.Deleted = 'false' )
		order by Level1_Index ASC, Level1_Text ASC, Level2_Index ASC, Level2_Text ASC, Level3_Index ASC, Level3_Text ASC, Level4_Index ASC, Level4_Text ASC, Level5_Index ASC, Level5_Text ASC, Title ASC;

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


/****** Object:  StoredProcedure [dbo].[Tracking_Get_Aggregation_Privates]    Script Date: 12/20/2013 05:43:38 ******/
-- Return the browse of all PRIVATE or DARK items for a single aggregation
ALTER PROCEDURE [dbo].[Tracking_Get_Aggregation_Privates]
	@code varchar(20),
	@pagesize int, 
	@pagenumber int,
	@sort int,	
	@minpagelookahead int,
	@maxpagelookahead int,
	@lookahead_factor float,
	@total_items int output,
	@total_titles int output
AS
begin

	-- No need to perform any locks here
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	-- Create the temporary tables first
	-- Create the temporary table to hold all the item id's
	declare @TEMP_ITEMS table ( ItemID int, fk_TitleID int, LastActivityDate datetime, LastActivityType varchar(100), LastMilestone_Date datetime, LastMilestone int, EmbargoDate datetime );	
	declare @TEMP_TITLES table ( BibID varchar(10), fk_TitleID int, GroupTitle nvarchar(1000), LastActivityDate datetime, LastMilestone_Date datetime, RowNumber int);
	
	-- Do not need to maintain row counts
	Set NoCount ON
	
	-- Determine the start and end rows
	declare @rowstart int; 
	declare @rowend int; 
	set @rowstart = (@pagesize * ( @pagenumber - 1 )) + 1;
	set @rowend = @rowstart + @pagesize - 1; 
	
	-- Determine the aggregationid
	declare @aggregationid int;
	set @aggregationid = ( select ISNULL(AggregationID,-1) from SobekCM_Item_Aggregation where Code=@code );

	-- Get the maximum possible date
	declare @maxDate datetime;
	set @maxDate = cast('12/31/9999' as datetime);
	  
	-- Populate the entire temporary item list	
	insert into @TEMP_ITEMS ( ItemID, fk_TitleID, LastMilestone, LastMilestone_Date, EmbargoDate )
	select I.ItemID, I.GroupID, I.Last_MileStone, 
		CASE I.Last_MileStone 
			WHEN 1 THEN I.Milestone_DigitalAcquisition
			WHEN 2 THEN I.Milestone_ImageProcessing
			WHEN 3 THEN I.Milestone_QualityControl
			WHEN 4 THEN I.Milestone_OnlineComplete
			ELSE I.CreateDate
		END, coalesce(EmbargoEnd, @maxDate)					
	from SobekCM_Item as I inner join
		 SobekCM_Item_Aggregation_Item_Link as CL on ( CL.ItemID = I.ItemID ) left outer join
		 Tracking_Item as T on T.ItemID=I.ItemID
	where ( CL.AggregationID = @aggregationid )
	  and ( I.Deleted = 'false' )
	  and (( I.IP_Restriction_Mask < 0 ) or ( I.Dark = 'true' ));
		
	-- Using common table expressions, add the latest activity and activity type
	with CTE AS (
		select P.ItemID, DateCompleted, WorkFlowName,
		   Rnum=ROW_NUMBER() OVER ( PARTITION BY P.ItemID ORDER BY DateCompleted DESC )
		from Tracking_Progress P, @TEMP_ITEMS T, Tracking_WorkFlow W
		where P.ItemID=T.ItemID and P.WorkFlowID = W.WorkFlowID)
	update I
	set LastActivityDate=cte.DateCompleted, LastActivityType=cte.WorkFlowName
	from @TEMP_ITEMS I INNER JOIN CTE ON CTE.ItemID=I.ItemID and Rnum=1;
	
	-- Set the total counts
	select @total_items=COUNT(ItemID), @total_titles=COUNT(distinct fk_TitleID)
	from @TEMP_ITEMS;
		  
	-- Now, calculate the actual ending row, based on the ration, page information,
	-- and the lookahead factor		
	-- Compute equation to determine possible page value ( max - log(factor, (items/title)/2))
	if (( @total_items > 0 ) and ( @total_titles > 0 ))
	begin
		declare @computed_value int;
		select @computed_value = (@maxpagelookahead - CEILING( LOG10( ((cast(@total_items as float)) / (cast(@total_titles as float)))/@lookahead_factor)));
		
		-- Compute the minimum value.  This cannot be less than @minpagelookahead.
		declare @floored_value int;
		select @floored_value = 0.5 * ((@computed_value + @minpagelookahead) + ABS(@computed_value - @minpagelookahead));
		
		-- Compute the maximum value.  This cannot be more than @maxpagelookahead.
		declare @actual_pages int;
		select @actual_pages = 0.5 * ((@floored_value + @maxpagelookahead) - ABS(@floored_value - @maxpagelookahead));

		-- Set the final row again then
		set @rowend = @rowstart + ( @pagesize * @actual_pages ) - 1;  
	end;
	
	-- SORT ORDERS
	-- 0 = BibID/VID
	-- 1 = Title/VID
	-- 2 = Last Activity Date (most recent first)
	-- 3 = Last Milestone Date (most recent first)
	-- 4 = Last Activity Date (oldest first)
	-- 5 = Last Milestone Date (oldest forst)
	-- 6 = Embargo Date (ASC)
	if (( @sort != 4 ) and ( @sort != 5 ))
	begin
		-- Create saved select across titles for row numbers
		with TITLES_SELECT AS
		 (	select fk_TitleID, MAX(I.LastActivityDate) as MaxActivityDate, MAX(I.LastMilestone_Date) as MaxMilestoneDate,
				ROW_NUMBER() OVER (order by case when @sort=0 THEN G.BibID end,
											case when @sort=1 THEN G.SortTitle end,
											case when @sort=2 THEN MAX(I.LastActivityDate) end DESC,
											case when @sort=3 THEN MAX(I.LastMilestone_Date) end DESC,
											case when @sort=6 THEN MIN(I.EmbargoDate) end ASC) as RowNumber
				from @TEMP_ITEMS I, SobekCM_Item_Group G
				where ( I.fk_TitleID = G.GroupID )
				group by fk_TitleID, G.BibID, G.SortTitle )
			  
		-- Insert the correct rows into the temp title table	
		insert into @TEMP_TITLES ( BibID, fk_TitleID, GroupTitle, LastActivityDate, LastMilestone_Date, RowNumber )
		select G.BibID, S.fk_TitleID, G.GroupTitle, S.MaxActivityDate, S.MaxMilestoneDate, RowNumber
		from TITLES_SELECT S, SobekCM_Item_Group G
		where S.fk_TitleID = G.GroupID
		  and RowNumber >= @rowstart
		  and RowNumber <= @rowend;
	end
	else
	begin
		-- Create saved select across titles for row numbers
		with TITLES_SELECT AS
		 (	select fk_TitleID, MIN(I.LastActivityDate) as MaxActivityDate, MIN(I.LastMilestone_Date) as MaxMilestoneDate,
				ROW_NUMBER() OVER (order by case when @sort=4 THEN MIN(I.LastActivityDate) end ASC,
											case when @sort=5 THEN MIN(I.LastMilestone_Date) end ASC ) as RowNumber
				from @TEMP_ITEMS I, SobekCM_Item_Group G
				where ( I.fk_TitleID = G.GroupID )
				group by fk_TitleID, G.BibID, G.SortTitle )
			  
		-- Insert the correct rows into the temp title table	
		insert into @TEMP_TITLES ( BibID, fk_TitleID, GroupTitle, LastActivityDate, LastMilestone_Date, RowNumber )
		select G.BibID, S.fk_TitleID, G.GroupTitle, S.MaxActivityDate, S.MaxMilestoneDate, RowNumber
		from TITLES_SELECT S, SobekCM_Item_Group G
		where S.fk_TitleID = G.GroupID
		  and RowNumber >= @rowstart
		  and RowNumber <= @rowend;
	end;
	
	-- Return the title information
	select RowNumber, G.BibID, G.GroupTitle, G.[Type], G.ALEPH_Number, G.OCLC_Number, T.LastActivityDate, T.LastMilestone_Date, G.ItemCount, isnull(G.Primary_Identifier_Type, '') as Primary_Identifier_Type, isnull(G.Primary_Identifier,'') as Primary_Identifier
	from @TEMP_TITLES T, SobekCM_Item_Group G
	where T.fk_TitleID = G.GroupID
	order by RowNumber;
	
	-- Return the item informaiton
	select T.RowNumber, VID, I2.Title, isnull(Internal_Comments,'') as Internal_Comments, isnull(PubDate,'') as PubDate, Locally_Archived, Remotely_Archived, AggregationCodes, I.LastActivityDate, I.LastActivityType, I.LastMilestone, I.LastMilestone_Date, Born_Digital, Material_Received_Date, isnull(DAT.DispositionFuture,'') AS Disposition_Advice, Disposition_Date, isnull(DT.DispositionPast,'') AS Disposition_Type, I2.Tracking_Box, I.EmbargoDate, coalesce(M.Creator,'') as Creator
	from @TEMP_ITEMS AS I inner join
		 @TEMP_TITLES AS T ON I.fk_TitleID=T.fk_TitleID inner join
		 SobekCM_Item AS I2 ON I.ItemID = I2.ItemID left outer join
		 Tracking_Disposition_Type AS DAT ON I2.Disposition_Advice=DAT.DispositionID left outer join
		 Tracking_Disposition_Type AS DT ON I2.Disposition_Type=DT.DispositionID left outer join
		 SobekCM_Metadata_Basic_Search_Table as M ON M.ItemID=I.ItemID
	order by T.RowNumber ASC, case when @sort=0 THEN VID end,
							case when @sort=1 THEN VID end,
							case when @sort=2 THEN I.LastActivityDate end DESC,
							case when @sort=3 THEN I.LastMilestone_Date end DESC,
							case when @sort=4 THEN I.LastActivityDate end ASC,
							case when @sort=5 THEN I.LastMilestone_Date end ASC,
							case when @sort=6 THEN I2.SortTitle end ASC;		 
			
    Set NoCount OFF;

end;
GO

CREATE PROCEDURE SobekCM_Set_Item_Visibility 
	@ItemID int,
	@IpRestrictionMask smallint,
	@DarkFlag bit,
	@EmbargoDate datetime,
	@User varchar(255)
AS 
BEGIN

	-- Build the note text and value
	declare @noteText varchar(200);
	set @noteText = '';

	-- Set the embargo date
	if ( @EmbargoDate is null )
	begin
		if ( exists ( select 1 from Tracking_Item where ItemID=@ItemID and EmbargoEnd is not null ))
		begin
			update Tracking_Item set EmbargoEnd=null where ItemID=@ItemID;

			set @noteText = 'Embargo date removed.  ';
		end;
	end
	else
	begin
		if ( exists ( select 1 from Tracking_Item where ItemID=@ItemID ))
		begin
			update Tracking_Item set EmbargoEnd=@EmbargoDate where ItemID=@ItemID;
		end
		else
		begin
			insert into Tracking_Item ( ItemID, Original_EmbargoEnd, EmbargoEnd )
			values ( @ItemID, @EmbargoDate, @EmbargoDate );
		end;

		set @noteText = 'Embargo date of ' + convert(varchar(20), @EmbargoDate, 102) + '.  ';
	end;

	-- Set the workflow id
	declare @workflowId int;
	set @workflowId = 34;
	if ( @IpRestrictionMask < 0 )
		set @workflowId = 35;
	if ( @IpRestrictionMask < 0 )
		set @workflowId = 36;
	if ( @DarkFlag = 'true' )
	begin
		set @workflowId = 35;
		set @noteText = @noteText + 'Item made dark.';
	end;

	-- Update the main item table ( and set for the builder to review this)
	update SobekCM_Item 
	set IP_Restriction_Mask = @IpRestrictionMask, Dark = @DarkFlag, AdditionalWorkNeeded = 'true' 
	where ItemID=@ItemID;

	insert into Tracking_Progress ( ItemID, WorkFlowID, DateCompleted, WorkPerformedBy, ProgressNote, DateStarted )
	values ( @ItemID, @workflowId, getdate(), @User, @noteText, getdate() );
END;
GO

GRANT EXECUTE ON SobekCM_Set_Item_Visibility to sobek_user;
GRANT EXECUTE ON SobekCM_Set_Item_Visibility to sobek_builder;
GO



ALTER TABLE SobekCM_Builder_Incoming_Folders ADD ModuleConfig varchar(max) null;
GO



-- Procedure looks for items to unembargo, and then sends emails out and unembargos them
CREATE PROCEDURE dbo.Admin_Unembargo_Items_Past_Embargo_Date 
	@subject_line varchar(500),
	@email_message varchar(max),
	@send_email bit
AS
BEGIN

	-- No need to perform any locks here, especially given the possible
	-- length of this search
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;

	-- Create the temporary tables first
	-- Create the temporary table to hold all the item id's
	create table #EmailPrep ( EmailAddress varchar(100) primary key, ItemList nvarchar(max));


	-- Get the items that need to be processed
	select I.ItemID, G.BibID, I.VID, CONVERT(nvarchar(10), T.EmbargoEnd, 102) as EmbargoEnd, substring(M.Title,4,1000) as Title, substring(M.Creator, 4, 1000) as Author
	into #Unembargo_Items
	from SobekCM_Item I, Tracking_Item T, SobekCM_Metadata_Basic_Search_Table M, SobekCM_Item_Group G
	where ( I.ItemID=T.ItemID )
	  and (( I.IP_Restriction_Mask <> 0 ) or ( I.Dark = 'true' ))
	  and ( T.EmbargoEnd < getdate() )
	  and ( M.ItemID = I.ItemID )
	  and ( I.GroupID = G.GroupID );


	-- Variables to hold the iteration's data for the main item cursor
	declare @itemid int;
	declare @bibid varchar(10);
	declare @vid varchar(5);
	declare @embargoend varchar(10);
	declare @title varchar(1000);
	declare @creator varchar(1000);

	-- Variables to hold the inner iteration data
	declare @contactemail varchar(255);

	-- Create the cursor to step through each item to un-embargo
	declare item_cursor cursor for
	select ItemID, BibID, VID, Title, Author, EmbargoEnd
	from #Unembargo_Items
	order by Title;

	open item_cursor;

	-- Get the first item to unembargo
	fetch next from item_cursor 
	into @itemid, @bibid, @vid, @title, @creator, @embargoend;

	-- Loop through them all
	while ( @@FETCH_STATUS = 0 )
	begin
	
		-- Now, step through all aggregations linked to this item
		declare aggregation_cursor cursor for
		select distinct( A.ContactEmail )
		from SobekCM_Item_Aggregation A, SobekCM_Item_Aggregation_Item_Link L
		where ( L.ItemID= @itemid )
		  and ( L.impliedLink = 'false' )
		  and ( A.AggregationID = L.AggregationID )
		  and ( len(A.ContactEmail) > 0 );

		open aggregation_cursor;

		-- Get the first aggregation email 
		fetch next from aggregation_cursor
		into @contactemail;

		-- Loop through all distinct email addresses for this item 
		while ( @@FETCH_STATUS = 0 )
		begin

			-- Does this email already exist?
			if ( exists ( select 1 from #EmailPrep where EmailAddress=@contactemail ))
			begin
				update #EmailPrep
				set ItemList=ItemList + '<br /><br /><i>' + @title + '</i>, by ' + @creator + ' ( ' + @bibid + ':' + @vid + ' ) - ' + @embargoend
				where EmailAddress=@contactemail;

			end
			else
			begin
				insert into #EmailPrep ( EmailAddress, ItemList )
				values ( @contactemail, '<i>' + @title + '</i>, by ' + @creator + ' ( ' + @bibid + ':' + @vid + ' ) - ' + @embargoend);
			end;

			-- Get the next aggregation email 
			fetch next from aggregation_cursor
			into @contactemail;
		end;
		close aggregation_cursor;
		deallocate aggregation_cursor;
   
		-- Get the next item to un-embargo
		fetch next from item_cursor 
		into @itemid, @bibid, @vid, @title, @creator, @embargoend;
	end;
	close item_cursor;
	deallocate item_cursor;
	
	-- Actually mark the items as unembargoed next
	update SobekCM_Item
	set Dark='false', IP_Restriction_Mask=0, AdditionalWorkNeeded='true'
	where exists ( select * from #Unembargo_Items T where T.ItemID=SobekCM_Item.ItemID );

	-- Also add a workflow progress for this
	insert into Tracking_Progress ( ItemID, WorkFlowID, DateCompleted, WorkPerformedBy, ProgressNote, DateStarted )
	select ItemID, 34, getdate(), 'Builder Service', 'Automatically unembargoed ( original unembargo date of ' + @embargoend + ' )', getdate()
	from #Unembargo_Items;

	-- Send emails via database email?
	if ( @send_email = 'true' )
	begin

		-- Prepare to send emails
		declare @emailaddress varchar(255);
		declare @itemlist varchar(max);
		declare @emailbody varchar(max);

		-- Now, create the cursor to send the email
		declare email_cursor cursor for
		select EmailAddress, ItemList
		from #EmailPrep;

		open email_cursor;

		-- Get the first email to send
		fetch next from email_cursor 
		into @emailaddress, @itemlist;

		-- Loop through them all
		while ( @@FETCH_STATUS = 0 )
		begin

			-- Set the email body
			set @emailbody = REPLACE(@email_message, '{0}', @itemlist);
	
			-- Send this email
			exec [SobekCM_Send_Email] @emailaddress, @subject_line, @emailbody, 'true', 'false', -1, -1;
		
			-- Get the next email to send
			fetch next from email_cursor 
			into @emailaddress, @itemlist;
		end;
		close email_cursor;
		deallocate email_cursor;
	end;

	-- Return the list of items unembargoed
	select * from #Unembargo_Items;

	-- Return the email information as well
	select * from #EmailPrep;

	-- Drop the temporary tables
	drop table #Unembargo_Items;
	drop table #EmailPrep;

END;
GO

grant execute on dbo.Admin_Unembargo_Items_Past_Embargo_Date to sobek_user;
grant execute on dbo.Admin_Unembargo_Items_Past_Embargo_Date to sobek_builder;
GO




-- Gets the list of all system-wide settings from the database, including the full list of all
-- metadata search fields, possible workflows, and all disposition data
ALTER PROCEDURE [dbo].[SobekCM_Get_Settings]
AS
begin

	-- No need to perform any locks here.  A slightly dirty read won't hurt much
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	
	-- Get all the standard SobekCM settings
	select Setting_Key, Setting_Value
	from SobekCM_Settings;

	-- Return all the builder folders
	select IncomingFolderId, NetworkFolder, ErrorFolder, ProcessingFolder, Perform_Checksum_Validation, Archive_TIFF, Archive_All_Files,
		   Allow_Deletes, Allow_Folders_No_Metadata, Allow_Metadata_Updates, FolderName, Can_Move_To_Content_Folder, BibID_Roots_Restrictions,
		   ModuleConfig
	from SobekCM_Builder_Incoming_Folders F;

	-- Return all the metadata search fields
	select MetadataTypeID, MetadataName, SobekCode, SolrCode, DisplayTerm, FacetTerm, CustomField, canFacetBrowse
	from SobekCM_Metadata_Types
	order by DisplayTerm;

	-- Return all the possible workflow types
	select WorkFlowID, WorkFlowName, WorkFlowNotes, Start_Event_Number, End_Event_Number, Start_And_End_Event_Number, Start_Event_Desc, End_Event_Desc
	from Tracking_WorkFlow;

	-- Return all the possible disposition options
	select DispositionID, DispositionFuture, DispositionPast, DispositionNotes
	from Tracking_Disposition_Type;

end;
GO


-- Gets a list of items and groups which exist within this instance
CREATE PROCEDURE [dbo].[SobekCM_Item_List]
	@include_private bit
as
begin

	-- No need to perform any locks here
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	-- Set value for filtering privates
	declare @lower_mask int;
	set @lower_mask = 0;
	if ( @include_private = 'true' )
	begin
		set @lower_mask = -256;
	end;

	-- Return the item group / item information in one large table
	select G.BibID, I.VID, IP_Restriction_Mask, I.Title, G.[Type], I.Dark
	from SobekCM_Item I, SobekCM_Item_Group G
	where ( I.GroupID = G.GroupID )
	  and ( G.Deleted = CONVERT(bit,0) )
	  and ( I.Deleted = CONVERT(bit,0) )
	  and ( I.IP_Restriction_Mask >= @lower_mask )
	order by BibID, VID;

end;
GO

GRANT EXECUTE ON SobekCM_Item_List to sobek_builder;
GRANT EXECUTE ON SobekCM_Item_List to sobek_user;
GO



DROP PROCEDURE SobekCM_Item_List_Web;
DROP PROCEDURE SobekCM_Get_Builder_Settings;
GO

/****** Object:  StoredProcedure [dbo].[Tracking_Add_Workflow_By_ItemID]    Script Date: 12/20/2013 05:43:38 ******/
ALTER PROCEDURE [dbo].[Tracking_Add_Workflow_By_ItemID]
	@itemid int,
	@user varchar(50),
	@progressnote varchar(1000),
	@workflow varchar(100),
	@storagelocation varchar(255)
AS
begin transaction
	    
	-- continue if an itemid was located
	if ( isnull( @itemid, -1 ) > 0 )
	begin
		-- Get the workflow id
		declare @workflowid int;
		if ( ( select COUNT(*) from Tracking_WorkFlow where ( WorkFlowName=@workflow)) > 0 )
		begin
			-- Get the existing ID for this workflow
			select @workflowid = workflowid from Tracking_WorkFlow where WorkFlowName=@workflow;
		end
		else
		begin 
			-- Create the workflow for this
			insert into Tracking_WorkFlow ( WorkFlowName, WorkFlowNotes )
			values ( @workflow, 'Added ' + CONVERT(VARCHAR(10), GETDATE(), 101) + ' by ' + @user );
			
			-- Get this ID
			set @workflowid = SCOPE_IDENTITY();
		end;
	
		-- Just add this new progress then
		insert into Tracking_Progress ( ItemID, WorkFlowID, DateCompleted, WorkPerformedBy, ProgressNote, WorkingFilePath )
		values ( @itemid, @workflowid, GETDATE(), @user, @progressnote, @storagelocation );
	end;
commit transaction;
GO

ALTER PROCEDURE [dbo].[Tracking_Add_Workflow]
	@bibid varchar(10),
	@vid varchar(5),
	@user varchar(50),
	@progressnote varchar(1000),
	@workflow varchar(100),
	@storagelocation varchar(255)
AS
begin transaction

	-- Get the volume id
	declare @itemid int
	select @itemid = ItemID
	from SobekCM_Item_Group G, SobekCM_Item I
	where ( BibID = @bibid )
	    and ( I.GroupID = G.GroupID ) 
	    and ( VID = @vid);
	    
	-- continue if an itemid was located
	if ( isnull( @itemid, -1 ) > 0 )
	begin
		-- Get the workflow id
		declare @workflowid int;
		if ( ( select COUNT(*) from Tracking_WorkFlow where ( WorkFlowName=@workflow)) > 0 )
		begin
			-- Get the existing ID for this workflow
			select @workflowid = workflowid from Tracking_WorkFlow where WorkFlowName=@workflow;
		end
		else
		begin 
			-- Create the workflow for this
			insert into Tracking_WorkFlow ( WorkFlowName, WorkFlowNotes )
			values ( @workflow, 'Added ' + CONVERT(VARCHAR(10), GETDATE(), 101) + ' by ' + @user );
			
			-- Get this ID
			set @workflowid = SCOPE_IDENTITY();
		end;
	
		-- Just add this new progress then
		insert into Tracking_Progress ( ItemID, WorkFlowID, DateCompleted, WorkPerformedBy, ProgressNote, WorkingFilePath )
		values ( @itemid, @workflowid, GETDATE(), @user, @progressnote, @storagelocation );
	end;
commit transaction;
GO



if (( select count(*) from SobekCM_Database_Version ) = 0 )
begin
	insert into SobekCM_Database_Version ( Major_Version, Minor_Version, Release_Phase )
	values ( 4, 3, '' );
end
else
begin
	update SobekCM_Database_Version
	set Major_Version=4, Minor_Version=3, Release_Phase='';
end;
GO