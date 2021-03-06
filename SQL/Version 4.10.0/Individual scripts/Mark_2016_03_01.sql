
-- Make some table changes
alter table SobekCM_Builder_Module_Schedule add [Description] varchar(250) not null default('');
GO


-- Gets the latest and greatest for when the builder ran, version, etc.. and also scheduled task information to show
CREATE procedure [dbo].[SobekCM_Builder_Get_Latest_Update]
as
begin

	-- Get the latest status / builder values which are stored in the settings table
	select Setting_Key, Setting_Value, Help, Options
	from SobekCM_Settings
	where ( Hidden = 'false' )
	  and ( TabPage = 'Builder' )
	  and ( Heading = 'Status' )
	order by TabPage, Heading, Setting_Key;

	
	-- Return all the scheduled type modules, with the schedule and the last run info
	with last_run_cte ( ModuleScheduleID, LastRun) as 
	(
		select ModuleScheduleID, MAX([Timestamp])
		from SobekCM_Builder_Module_Scheduled_Run
		group by ModuleScheduleID
	)
	-- Return all the scheduled type modules, along with information on when it was last run
	select S.ModuleSetID, S.SetName, S.[Enabled] as SetEnabled, C.ModuleScheduleID, C.[Enabled] as ScheduleEnabled, C.DaysOfWeek, C.TimesOfDay, C.[Description], coalesce(L.LastRun,'') as LastRun, coalesce(R.Outcome,'') as Outcome, coalesce(R.[Message],'') as [Message]
	from SobekCM_Builder_Module_Set S inner join
		 SobekCM_Builder_Module_Type T on S.ModuleTypeID = T.ModuleTypeID inner join
		 SobekCM_Builder_Module_Schedule C on C.ModuleSetID = S.ModuleSetID left outer join
		 last_run_cte L on L.ModuleScheduleID = C.ModuleScheduleID left outer join
		 SobekCM_Builder_Module_Scheduled_Run R on R.ModuleSchedRunID=L.ModuleScheduleID and R.[Timestamp] = L.LastRun
	where T.TypeAbbrev = 'SCHD'
	order by C.[Description], S.SetOrder;

end;
GO

GRANT EXECUTE ON [dbo].[SobekCM_Builder_Get_Latest_Update] to sobek_user;
GRANT EXECUTE ON [dbo].[SobekCM_Builder_Get_Latest_Update] to sobek_builder;
GO


-- If not present, add the usage stats computation set
if ( not exists ( select 1 from SobekCM_Builder_Module_Set where SetName = 'Usage statistics computation' ))
begin
	insert into SobekCM_Builder_Module_Set ( ModuleTypeID, SetName, SetOrder, [Enabled] )
	values ( 5, 'Usage statistics calculation', 1, 1 );
end;
GO
   
-- Get the usage stats setid
declare @usagesetid int;
set @usagesetid = ( select ModuleSetID from SobekCM_Builder_Module_Set where SetName = 'Usage statistics computation' );

-- If not present, add the usage stats computation module
if ( not exists ( select 1 from SobekCM_Builder_Module where Class = 'SobekCM.Builder_Library.Modules.Schedulable.CalculateUsageStatisticsModule' ))
begin
	insert into SobekCM_Builder_Module ( ModuleSetID, ModuleDesc, Class, [Enabled], [Order] )
	values ( @usagesetid, 'Usage statistics calculation and usage email sends', 'SobekCM.Builder_Library.Modules.Schedulable.CalculateUsageStatisticsModule', 1, 1 );
end;

-- Get the usage stats setid
declare @usagemoduleid int;
set @usagemoduleid = ( select ModuleID from SobekCM_Builder_Module where Class = 'SobekCM.Builder_Library.Modules.Schedulable.CalculateUsageStatisticsModule' );


-- Insert the schedule for this one
if ( not exists ( select 1 from SobekCM_Builder_Module_Schedule where ModuleSetID=@usagesetid ))
begin
	insert into SobekCM_Builder_Module_Schedule ( ModuleSetID, DaysOfWeek, [Enabled], TimesOfDay, [Description] )
	values ( @usagesetid, 'M', 'true', '0600', 'Calculate the usage statistics' );
end;
GO

-- Insert other schedules, if not existing
if (( not exists ( select 1 from SobekCM_Builder_Module_Schedule where ModuleSetID=5  )) and ( exists ( select 1 from SobekCM_Builder_Module_Set where ModuleSetID=5 and ModuleTypeID=5 )))
begin
	insert into SobekCM_Builder_Module_Schedule ( ModuleSetID, DaysOfWeek, [Enabled], TimesOfDay, [Description] )
	values ( 5, 'MWF', 'true', '0530', 'Expire old builder logs' );
end;
GO

-- Insert other schedules, if not existing
if (( not exists ( select 1 from SobekCM_Builder_Module_Schedule where ModuleSetID=6  )) and ( exists ( select 1 from SobekCM_Builder_Module_Set where ModuleSetID=6 and ModuleTypeID=5 )))
begin
	insert into SobekCM_Builder_Module_Schedule ( ModuleSetID, DaysOfWeek, [Enabled], TimesOfDay, [Description] )
	values ( 6, 'MTWRF', 'true', '0900', 'Rebuild all aggregation browse files' );
end;
GO

-- Insert other schedules, if not existing
if (( not exists ( select 1 from SobekCM_Builder_Module_Schedule where ModuleSetID=7  )) and ( exists ( select 1 from SobekCM_Builder_Module_Set where ModuleSetID=7 and ModuleTypeID=5 )))
begin
	insert into SobekCM_Builder_Module_Schedule ( ModuleSetID, DaysOfWeek, [Enabled], TimesOfDay, [Description] )
	values ( 7, 'MTWRF', 'true', '2100', 'Send new item emails' );
end;
GO

-- Insert other schedules, if not existing
if (( not exists ( select 1 from SobekCM_Builder_Module_Schedule where ModuleSetID=8  )) and ( exists ( select 1 from SobekCM_Builder_Module_Set where ModuleSetID=8 and ModuleTypeID=5 )))
begin
	insert into SobekCM_Builder_Module_Schedule ( ModuleSetID, DaysOfWeek, [Enabled], TimesOfDay, [Description] )
	values ( 8, 'S', 'true', '2200', 'Solr/Lucene index optimization' );
end;
GO

-- Insert other schedules, if not existing
if (( not exists ( select 1 from SobekCM_Builder_Module_Schedule where ModuleSetID=9  )) and ( exists ( select 1 from SobekCM_Builder_Module_Set where ModuleSetID=9 and ModuleTypeID=5 )))
begin
	insert into SobekCM_Builder_Module_Schedule ( ModuleSetID, DaysOfWeek, [Enabled], TimesOfDay, [Description] )
	values ( 9, 'MWF', 'true', '2130', 'Update all cached aggregation browses' );
end;
GO