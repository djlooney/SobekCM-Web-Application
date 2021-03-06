



CREATE PROCEDURE Delete_User_Completely 
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
