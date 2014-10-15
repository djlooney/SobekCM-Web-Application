#region Using directives

using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Windows.Forms;
using SobekCM.Core.Configuration;
using SobekCM.Core.Settings;
using SobekCM.Builder_Library.Modules;
using SobekCM.Builder_Library.Modules.Folders;
using SobekCM.Builder_Library.Modules.Items;
using SobekCM.Builder_Library.Modules.PostProcess;
using SobekCM.Builder_Library.Modules.PreProcess;
using SobekCM.Library.Application_State;
using SobekCM.Library.Database;
using SobekCM.Library.Settings;
using SobekCM.Library.Solr;
using SobekCM.Tools.Logs;
using SobekCM.Builder_Library;

#endregion

namespace SobekCM.Builder
{
    /// <summary> Class is the worker thread for the main bulk loader processor </summary>
    public class Worker_BulkLoader
    {
        private Database_Instance_Configuration dbInstance;
        private InstanceWide_Settings settings;
        private DataTable itemTable;

        private string imageMagickExecutable;
        private string ghostscriptExecutable;
        
        private DataSet incomingFileInstructions;
        private readonly Aggregation_Code_Manager codeManager;
        private readonly LogFileXHTML logger;
        
        
	    private readonly bool canAbort;
        private bool aborted;
        private bool verbose;


	    private readonly bool multiInstanceBuilder;


	    private readonly string instanceName;
	    private string finalmessage;


        private readonly List<string> aggregations_to_refresh;
        private readonly List<BibVidStruct> processed_items;
        private readonly List<BibVidStruct> deleted_items;


        private readonly List<iPreProcessModule> preProcessModules;
        private readonly List<iSubmissionPackageModule> processItemModules;
        private readonly List<iSubmissionPackageModule> deleteItemModules;
        private readonly List<iPostProcessModule> postProcessModules;
        private readonly List<iFolderModule> folderModules;


	    ///  <summary> Constructor for a new instance of the Worker_BulkLoader class </summary>
	    ///  <param name="Logger"> Log file object for logging progress </param>
	    ///  <param name="Verbose"> Flag indicates if the builder is in verbose mode, where it should log alot more information </param>
        ///  <param name="DbInstance"> This database instance </param>
	    public Worker_BulkLoader(LogFileXHTML Logger, bool Verbose, Database_Instance_Configuration DbInstance, bool MultiInstanceBuilder, string ImageMagickExecutable, string GhostscriptExecutable )
        {
            // Save the log file and verbose flag
            logger = Logger;
            verbose = Verbose;
	        instanceName = DbInstance.Name;
		    canAbort = DbInstance.Can_Abort;
	        multiInstanceBuilder = MultiInstanceBuilder;
	        dbInstance = DbInstance;
	        ghostscriptExecutable = GhostscriptExecutable;
	        imageMagickExecutable = ImageMagickExecutable;
 
            Add_NonError_To_Log("Worker_BulkLoader.Constructor: Start", verbose, String.Empty, String.Empty, -1);


            // Create new list of collections to build
            aggregations_to_refresh = new List<string>();
	        processed_items = new List<BibVidStruct>();
	        deleted_items = new List<BibVidStruct>();

			// get all the info
	        settings = InstanceWide_Settings_Builder.Build_Settings(dbInstance);


			// Ensure there is SOME instance name
	        if (instanceName.Length == 0)
		        instanceName = settings.System_Name;
            if (verbose)
                settings.Builder_Verbose_Flag = true;


            Add_NonError_To_Log("Worker_BulkLoader.Constructor: Created Static Pages Builder", verbose, String.Empty, String.Empty, -1);

            // Get the list of collection codes
            codeManager = new Aggregation_Code_Manager();
            SobekCM_Database.Populate_Code_Manager(codeManager, null);

            Add_NonError_To_Log("Worker_BulkLoader.Constructor: Populated code manager with " + codeManager.All_Aggregations.Count + " aggregations.", verbose, String.Empty, String.Empty, -1);

            // Set some defaults
            aborted = false;


            Add_NonError_To_Log("Worker_BulkLoader.Constructor: Building modules for pre, post, and item processing", verbose, String.Empty, String.Empty, -1);

            // Create the default list of pre-processor modules
            preProcessModules = new List<iPreProcessModule> { new ProcessPendingFdaReportsModule() };
            foreach (iPreProcessModule thisModule in preProcessModules)
            {
                thisModule.Error += module_Error;
                thisModule.Process += module_Process;
            }

            // Create the default list of folder modules
	        folderModules = new List<iFolderModule> { new MoveAgedPackagesToProcessModule(), new ApplyBibIdRestrictionModule(), new ValidateAndClassifyModule() };
            foreach (iFolderModule thisModule in folderModules)
            {
                thisModule.Error += module_Error;
                thisModule.Process += module_Process;
            }


            // Create the default list of deleting a single item 
	        deleteItemModules = new List<iSubmissionPackageModule>();

            // Create the default list of modules for processing an item
	        processItemModules = new List<iSubmissionPackageModule>
	        {
	            new ConvertOfficeFilesToPdfModule(), 
                new ExtractTextFromPdfModule(), 
                new CreatePdfThumbnailModule(), 
                new ExtractTextFromHtmlModule(), 
                new ExtractTextFromXmlModule(), 
                new OcrTiffsModule(), 
                new CleanDirtyOcrModule(), 
                new CheckForSsnModule(), 
                new CreateImageDerivativesModule(), 
                new CopyToArchiveFolderModule(), 
                new MoveFilesToImageServerModule(), 
                new ReloadMetsAndBasicDbInfoModule(), 
                new UpdateJpegAttributesModule(), 
                new AttachAllNonImageFilesModule(), 
                new AddNewImagesAndViewsModule(), 
                new EnsureMainThumbnailModule(), 
                new GetPageCountFromPdfModule(), 
                new UpdateWebConfigModule(), 
                new SaveServiceMetsModule(), 
                new SaveMarcXmlModule(), 
                new SaveToDatabaseModule(), 
                new SaveToSolrLuceneModule(), 
                new CleanWebResourceFolderModule(), 
                new CreateStaticVersionModule(), 
                new AddTrackingWorkflowModule()
	        };
	        foreach (iSubmissionPackageModule thisModule in processItemModules)
            {
                thisModule.Error += module_Error;
                thisModule.Process += module_Process;
            }

            // Create the default modules for post-processing
	        postProcessModules = new List<iPostProcessModule> {new BuildAggregationBrowsesModule()};
	        foreach (iPostProcessModule thisModule in postProcessModules)
	        {
	            thisModule.Error += module_Error;
                thisModule.Process += module_Process;
	        }

	        Add_NonError_To_Log("Worker_BulkLoader.Constructor: Done", verbose, String.Empty, String.Empty, -1);
        }

        #region Main Method that steps through each package and performs work

        /// <summary> Performs the bulk loader process and handles any incoming digital resources </summary>
        public void Perform_BulkLoader( bool Verbose )
        {

            verbose = Verbose;
            finalmessage = String.Empty;

            Add_NonError_To_Log("Worker_BulkLoader.Perform_BulkLoader: Start", verbose, String.Empty, String.Empty, -1);

            // Refresh any settings and item lists 
            if (!Refresh_Settings_And_Item_List())
            {
                Add_Error_To_Log("Worker_BulkLoader.Perform_BulkLoader: Error refreshing settings and item list", String.Empty, String.Empty, -1);
                finalmessage = "Error refreshing settings and item list";
                return;
            }

            // If not already verbose, check settings
            if (!verbose)
            {
                verbose = settings.Builder_Verbose_Flag;
            }

            Add_NonError_To_Log("Worker_BulkLoader.Perform_BulkLoader: Refreshed settings and item list", verbose, String.Empty, String.Empty, -1);

            // Check for abort
            if (CheckForAbort()) 
            {
                Add_NonError_To_Log("Worker_BulkLoader.Perform_BulkLoader: Aborted (line 137)", verbose, String.Empty, String.Empty, -1);
                finalmessage = "Aborted per database request";
                return; 
            }
            else
            {
	            // Set to standard operation then
				Abort_Database_Mechanism.Builder_Operation_Flag = Builder_Operation_Flag_Enum.STANDARD_OPERATION;
            }

            // RUN ANY PRE-PROCESSING MODULES HERE 
            if (preProcessModules.Count > 0)
            {
                Add_NonError_To_Log("Running all pre-processing steps", verbose, String.Empty, String.Empty, -1);
                foreach (iPreProcessModule thisModule in preProcessModules)
                {
                    // Check for abort
                    if (CheckForAbort())
                    {
                        Abort_Database_Mechanism.Builder_Operation_Flag = Builder_Operation_Flag_Enum.ABORTING;
                        break;
                    }

                    thisModule.DoWork(settings);
                }
            }

            // Load the settings into thall the item and folder processors
            foreach (iSubmissionPackageModule thisModule in processItemModules)
                thisModule.Settings = settings;
            foreach (iSubmissionPackageModule thisModule in deleteItemModules)
                thisModule.Settings = settings;
            foreach (iFolderModule thisModule in folderModules)
                thisModule.Settings = settings;


            Add_NonError_To_Log("Worker_BulkLoader.Perform_BulkLoader: Begin completing any recent loads requiring additional work", verbose, String.Empty, String.Empty, -1);

            // Handle all packages already on the web server which are flagged for additional work required
            Complete_Any_Recent_Loads_Requiring_Additional_Work();

            Add_NonError_To_Log("Worker_BulkLoader.Perform_BulkLoader: Finished completing any recent loads requiring additional work", verbose, String.Empty, String.Empty, -1);

            // Check for abort
            if (CheckForAbort())
            {
                Add_NonError_To_Log("Worker_BulkLoader.Perform_BulkLoader: Aborted (line 151)", verbose, String.Empty, String.Empty, -1);
                finalmessage = "Aborted per database request";
                ReleaseResources();
                return;
            }

            // Create the seperate queues for each type of incoming digital resource files
            List<Incoming_Digital_Resource> incoming_packages = new List<Incoming_Digital_Resource>();
            List<Incoming_Digital_Resource> deletes = new List<Incoming_Digital_Resource>();

            // Step through all the incoming folders, and run the folder modules
            if (settings.Incoming_Folders.Count == 0)
            {
                Add_NonError_To_Log("Worker_BulkLoader.Move_Appropriate_Inbound_Packages_To_Processing: There are no incoming folders set in the database", "Standard", String.Empty, String.Empty, -1);
            }
            else
            {
                Add_NonError_To_Log("Worker_BulkLoader.Perform_BulkLoader: Begin processing builder folders", verbose, String.Empty, String.Empty, -1);

                foreach (Builder_Source_Folder folder in settings.Incoming_Folders)
                {
                    Actionable_Builder_Source_Folder actionFolder = new Actionable_Builder_Source_Folder(folder);

                    foreach (iFolderModule thisModule in folderModules)
                    {
                        // Check for abort
                        if (CheckForAbort())
                        {
                            Add_NonError_To_Log("Worker_BulkLoader.Perform_BulkLoader: Aborted (line 151)", verbose, String.Empty, String.Empty, -1);
                            finalmessage = "Aborted per database request";
                            ReleaseResources();
                            return;
                        }

                        thisModule.DoWork(actionFolder, incoming_packages, deletes);
                    }
                }

                // Since all folder processing is complete, release resources
                foreach (iFolderModule thisModule in folderModules)
                    thisModule.ReleaseResources();
            }
            

            // Check for abort
            if (CheckForAbort())
            {
                Add_NonError_To_Log("Worker_BulkLoader.Perform_BulkLoader: Aborted (line 179)", verbose, String.Empty, String.Empty, -1);
                finalmessage = "Aborted per database request";
                ReleaseResources();
                return;
            }

            // If there were no packages to process further stop here
            if ((incoming_packages.Count == 0) && (deletes.Count == 0))
            {
	            Add_Complete_To_Log("No New Packages - Process Complete", "No Work", String.Empty, String.Empty, -1);
                if (finalmessage.Length == 0)
                    finalmessage = "No New Packages - Process Complete";
                ReleaseResources();
                return;
            }

            // Iterate through all non-delete resources ready for processing
            Add_NonError_To_Log("Worker_BulkLoader.Perform_BulkLoader: Process any incoming packages", verbose, String.Empty, String.Empty, -1);
            Process_All_Incoming_Packages(incoming_packages);

            // Can now release these resources
            foreach (iSubmissionPackageModule thisModule in processItemModules)
            {
                thisModule.ReleaseResources();
            }

            // Process any delete requests ( iterate through all deletes )
            Add_NonError_To_Log("Worker_BulkLoader.Perform_BulkLoader: Process any deletes", verbose, String.Empty, String.Empty, -1);
            Process_All_Deletes(deletes);

            // Can now release these resources
            foreach (iSubmissionPackageModule thisModule in deleteItemModules)
            {
                thisModule.ReleaseResources();
            }


            // RUN ANY POST-PROCESSING MODULES HERE 
            if (postProcessModules.Count > 0)
            {
                Add_NonError_To_Log("Running all post-processing steps", verbose, String.Empty, String.Empty, -1);
                foreach (iPostProcessModule thisModule in postProcessModules)
                {
                    // Check for abort
                    if (CheckForAbort())
                    {
                        Abort_Database_Mechanism.Builder_Operation_Flag = Builder_Operation_Flag_Enum.ABORTING;
                        break;
                    }

                    thisModule.DoWork(aggregations_to_refresh, processed_items, deleted_items, settings);
                }
            }

            // Add the complete entry for the log
            if (!CheckForAbort())
            {
                Add_Complete_To_Log("Process Complete", "Complete", String.Empty, String.Empty, -1);
                if (finalmessage.Length == 0)
                    finalmessage = "Process completed successfully";
            }
            else
            {
                finalmessage = "Aborted per database request";
                Add_Complete_To_Log("Process Aborted Cleanly", "Complete", String.Empty, String.Empty, -1);
            }

            // Clear lots of collections and such from memory, since we are done processing
            ReleaseResources();


            Add_NonError_To_Log("Worker_BulkLoader.Perform_BulkLoader: Done", verbose, String.Empty, String.Empty, -1);

        }

        public void ReleaseResources()
        {
            // Set some things to NULL
            itemTable = null;
            aggregations_to_refresh.Clear();
            processed_items.Clear();
            deleted_items.Clear();
            incomingFileInstructions = null;

            // release all modules
            foreach (iFolderModule thisModule in folderModules)
            {
                thisModule.ReleaseResources();
            }
            foreach (iSubmissionPackageModule thisModule in deleteItemModules)
            {
                thisModule.ReleaseResources();
            }
            foreach (iSubmissionPackageModule thisModule in processItemModules)
            {
                thisModule.ReleaseResources();
            }
        }

        #endregion

        #region Refresh any settings and item lists and clear the item list

		/// <summary> Refresh the settings and item list from the database </summary>
		/// <returns> TRUE if successful, otherwise FALSE </returns>
        public bool Refresh_Settings_And_Item_List()
        {
            // Reload the settings
            settings = InstanceWide_Settings_Builder.Build_Settings(dbInstance);

		    if (settings == null)
		    {
	            Add_Error_To_Log("Unable to pull the newest settings from the database", String.Empty, String.Empty, -1);
                return false;
		    }
		    settings.ImageMagick_Executable = imageMagickExecutable;
		    settings.Ghostscript_Executable = ghostscriptExecutable;

            Resource_Object.Database.SobekCM_Database.Connection_String = dbInstance.Connection_String;
            Library.Database.SobekCM_Database.Connection_String = dbInstance.Connection_String;

            // Save the item table
		    itemTable = SobekCM_Database.Get_Item_List(true, null).Tables[0];



            return true;
        }


        #endregion

        #region Process any recent loads which require additonal work

        private void Complete_Any_Recent_Loads_Requiring_Additional_Work()
        {
            // Get the list of recent loads requiring additional work
            DataTable additionalWorkRequired = SobekCM_Database.Items_Needing_Aditional_Work;
            if ((additionalWorkRequired != null) && (additionalWorkRequired.Rows.Count > 0))
            {
	            Add_NonError_To_Log("Processing recently loaded items needing additional work", "Standard", String.Empty, String.Empty, -1);

                // Create the incoming digital folder object which will be used for all these
                Actionable_Builder_Source_Folder sourceFolder = new Actionable_Builder_Source_Folder();

                // Step through each one
                foreach (DataRow thisRow in additionalWorkRequired.Rows)
                {
                    // Get the information about this item
                    string bibID = thisRow["BibID"].ToString();
                    string vid = thisRow["VID"].ToString();

	                // Determine the file root for this
                    string file_root = bibID.Substring(0, 2) + "\\" + bibID.Substring(2, 2) + "\\" + bibID.Substring(4, 2) + "\\" + bibID.Substring(6, 2) + "\\" + bibID.Substring(8, 2);

                    // Determine the source folder for this resource
                    string resource_folder = settings.Image_Server_Network + file_root + "\\" + vid;

                    // Determine the METS file name
                    string mets_file = resource_folder + "\\" + bibID + "_" + vid + ".mets.xml";

                    // Ensure these both exist
                    if ((Directory.Exists(resource_folder)) && (File.Exists(mets_file)))
                    {
                        // Create the incoming digital resource object
                        Incoming_Digital_Resource additionalWorkResource = new Incoming_Digital_Resource(resource_folder, sourceFolder) 
							{BibID = bibID, VID = vid, File_Root = bibID.Substring(0, 2) + "\\" + bibID.Substring(2, 2) + "\\" + bibID.Substring(4, 2) + "\\" + bibID.Substring(6, 2) + "\\" + bibID.Substring(8, 2)};

	                    Complete_Single_Recent_Load_Requiring_Additional_Work( resource_folder, additionalWorkResource);
                    }
                    else
                    {
	                    Add_Error_To_Log("Unable to find valid resource files for reprocessing " + bibID + ":" + vid, bibID + ":" + vid, "Reprocess", -1);

	                    int itemID = SobekCM_Database.Get_ItemID_From_Bib_VID(bibID, vid);

						SobekCM_Database.Update_Additional_Work_Needed_Flag(itemID, false, null);
                    }
                }
            }
        }

        private void Complete_Single_Recent_Load_Requiring_Additional_Work(string Resource_Folder, Incoming_Digital_Resource AdditionalWorkResource)
        {
	        AdditionalWorkResource.METS_Type_String = "Reprocess";
            AdditionalWorkResource.BuilderLogId = Add_NonError_To_Log("........Reprocessing '" + AdditionalWorkResource.BibID + ":" + AdditionalWorkResource.VID + "'", "Standard",  AdditionalWorkResource.BibID + ":" + AdditionalWorkResource.VID, AdditionalWorkResource.METS_Type_String, -1);

            try
            {
                // Load the METS file
                if ((!AdditionalWorkResource.Load_METS()) || (AdditionalWorkResource.BibID.Length == 0))
                {
                    Add_Error_To_Log("Error reading METS file from " + AdditionalWorkResource.Folder_Name.Replace("_", ":"), AdditionalWorkResource.Folder_Name.Replace("_", ":"), "Reprocess", AdditionalWorkResource.BuilderLogId);
                    return;
                }

                AdditionalWorkResource.METS_Type_String = "Reprocess";

                // Add thumbnail and aggregation informaiton from the database 
                SobekCM_Database.Add_Minimum_Builder_Information(AdditionalWorkResource.Metadata);

                // Do all the item processing per instance config
                foreach (iSubmissionPackageModule thisModule in processItemModules)
                {
                    thisModule.DoWork(AdditionalWorkResource);
                }

                // Save these collections to mark them for refreshing the RSS feeds, etc..
                Add_Process_Info_To_PostProcess_Lists(AdditionalWorkResource.BibID, AdditionalWorkResource.VID, AdditionalWorkResource.Metadata.Behaviors.Aggregation_Code_List);

                // Finally, clear the memory a little bit
                AdditionalWorkResource.Clear_METS();
            }
            catch (Exception ee)
            {
                Add_Error_To_Log("Unable to complete additional work for " + AdditionalWorkResource.BibID + ":" + AdditionalWorkResource.VID, AdditionalWorkResource.BibID + ":" + AdditionalWorkResource.VID, AdditionalWorkResource.METS_Type_String, AdditionalWorkResource.BuilderLogId, ee);
            }
        }

        #endregion

        #region Process any complete packages, whether a new resource or a replacement

        private void Process_All_Incoming_Packages(List<Incoming_Digital_Resource> IncomingPackages )
        {
            if (IncomingPackages.Count == 0)
                return;

            try
            {
                // Step through each package and handle all the files and metadata
                Add_NonError_To_Log("....Processing incoming packages", "Standard", String.Empty, String.Empty, -1);
                IncomingPackages.Sort();
                foreach (Incoming_Digital_Resource resourcePackage in IncomingPackages)
                {
                    // Check for abort
                    if (CheckForAbort())
                    {
                        Abort_Database_Mechanism.Builder_Operation_Flag = Builder_Operation_Flag_Enum.ABORTING;
                        return;
                    }

                    Process_Single_Incoming_Package(resourcePackage);

                }
            }
            catch (Exception ee)
            {
                StreamWriter errorWriter = new StreamWriter(Application.StartupPath + "\\Logs\\error.log", true);
                errorWriter.WriteLine("Message: " + ee.Message);
                errorWriter.WriteLine("Stack Trace: " + ee.StackTrace);
                errorWriter.Flush();
                errorWriter.Close();

                Add_Error_To_Log("Unable to process all of the NEW and REPLACEMENT packages.", String.Empty, String.Empty, -1, ee);
            }
        }

        private void Process_Single_Incoming_Package(Incoming_Digital_Resource ResourcePackage)
        {

            ResourcePackage.BuilderLogId = Add_NonError_To_Log("........Processing '" + ResourcePackage.Folder_Name + "'", "Standard", ResourcePackage.BibID + ":" + ResourcePackage.VID, ResourcePackage.METS_Type_String, -1);

            // Clear any existing error linked to this item
			SobekCM_Database.Builder_Clear_Item_Error_Log(ResourcePackage.BibID, ResourcePackage.VID, "SobekCM Builder");

            // Before we save this or anything, let's see if this is truly a new resource
            ResourcePackage.NewPackage = !(itemTable.Select("BibID='" + ResourcePackage.BibID + "' and VID='" + ResourcePackage.VID + "'").Length > 0);
            ResourcePackage.Package_Time = DateTime.Now;

            // Rename the received METS files
            Rename_Any_Received_METS_File(ResourcePackage);

            try
            {
                // Do all the item processing per instance config
                foreach (iSubmissionPackageModule thisModule in processItemModules)
                {
                    thisModule.DoWork(ResourcePackage);
                }

                // Save these collections to mark them for refreshing the RSS feeds, etc..
                Add_Process_Info_To_PostProcess_Lists(ResourcePackage.BibID, ResourcePackage.VID, ResourcePackage.Metadata.Behaviors.Aggregation_Code_List);

                // Finally, clear the memory a little bit
                ResourcePackage.Clear_METS();
            }
            catch (Exception ee)
            {
                StreamWriter errorWriter = new StreamWriter(Application.StartupPath + "\\Logs\\error.log", true);
                errorWriter.WriteLine("Message: " + ee.Message);
                errorWriter.WriteLine("Stack Trace: " + ee.StackTrace);
                errorWriter.Flush();
                errorWriter.Close();

                Add_Error_To_Log("Unable to complete new/replacement for " + ResourcePackage.BibID + ":" + ResourcePackage.VID, ResourcePackage.BibID + ":" + ResourcePackage.VID, String.Empty, ResourcePackage.BuilderLogId, ee);
            }
        }


        long module_Error(string LogStatement, string BibID_VID, string MetsType, long RelatedLogID)
        {
            return Add_Error_To_Log(LogStatement, BibID_VID, MetsType, RelatedLogID);
        }

        long module_Process(string LogStatement, string DbLogType, string BibID_VID, string MetsType, long RelatedLogID)
        {
            return Add_NonError_To_Log(LogStatement, DbLogType, BibID_VID, MetsType, RelatedLogID);
        }

        private void Rename_Any_Received_METS_File(Incoming_Digital_Resource ResourcePackage)
        {
            string recd_filename = "recd_" + DateTime.Now.Year + "_" + DateTime.Now.Month.ToString().PadLeft(2, '0') + "_" + DateTime.Now.Day.ToString().PadLeft(2, '0') + ".mets.bak";

            // If a renamed file already exists for this year, delete the incoming with that name (shouldn't exist)
            if (File.Exists(ResourcePackage.Resource_Folder + "\\" + recd_filename))
				File.Delete(ResourcePackage.Resource_Folder + "\\" + recd_filename);

            if (File.Exists(ResourcePackage.Resource_Folder + "\\" + ResourcePackage.BibID + "_" + ResourcePackage.VID + ".mets"))
            {
				File.Move(ResourcePackage.Resource_Folder + "\\" + ResourcePackage.BibID + "_" + ResourcePackage.VID + ".mets", ResourcePackage.Resource_Folder + "\\" + recd_filename);
                ResourcePackage.METS_File = recd_filename;
                return;
            }
            if (File.Exists(ResourcePackage.Resource_Folder + "\\" + ResourcePackage.BibID + "_" + ResourcePackage.VID + ".mets.xml"))
            {
				File.Move(ResourcePackage.Resource_Folder + "\\" + ResourcePackage.BibID + "_" + ResourcePackage.VID + ".mets.xml", ResourcePackage.Resource_Folder + "\\" + recd_filename);
                ResourcePackage.METS_File = recd_filename;
                return;
            }
            if (File.Exists(ResourcePackage.Resource_Folder + "\\" + ResourcePackage.BibID + ".mets"))
            {
				File.Move(ResourcePackage.Resource_Folder + "\\" + ResourcePackage.BibID + ".mets", ResourcePackage.Resource_Folder + "\\" + recd_filename);
                ResourcePackage.METS_File = recd_filename;
                return;
            }
            if (File.Exists(ResourcePackage.Resource_Folder + "\\" + ResourcePackage.BibID + ".mets.xml"))
            {
				File.Move(ResourcePackage.Resource_Folder + "\\" + ResourcePackage.BibID + ".mets.xml", ResourcePackage.Resource_Folder + "\\" + recd_filename);
                ResourcePackage.METS_File = recd_filename;
            }
        }





        #endregion

        #region Process any delete requests

        private void Process_All_Deletes(List<Incoming_Digital_Resource> Deletes)
        {
            if (Deletes.Count == 0)
                return;

            Add_NonError_To_Log("....Processing delete packages", "Standard", String.Empty, String.Empty, -1);
            Deletes.Sort();
            foreach (Incoming_Digital_Resource deleteResource in Deletes)
            {
                // Check for abort
                if (CheckForAbort())
                {
                    Abort_Database_Mechanism.Builder_Operation_Flag = Builder_Operation_Flag_Enum.ABORTING;
                    return;
                }

				// Read the METS and load the basic information before continuing
	            deleteResource.Load_METS();
				SobekCM_Database.Add_Minimum_Builder_Information(deleteResource.Metadata);

                deleteResource.BuilderLogId = Add_NonError_To_Log("........Processing '" + deleteResource.Folder_Name + "'", "Standard", deleteResource.BibID + ":" + deleteResource.VID, deleteResource.METS_Type_String, -1 );

				SobekCM_Database.Builder_Clear_Item_Error_Log(deleteResource.BibID, deleteResource.VID, "SobekCM Builder");

                if (itemTable.Select("BibID='" + deleteResource.BibID + "' and VID='" + deleteResource.VID + "'").Length > 0)
                {
                    deleteResource.File_Root = deleteResource.BibID.Substring(0, 2) + "\\" + deleteResource.BibID.Substring(2, 2) + "\\" + deleteResource.BibID.Substring(4, 2) + "\\" + deleteResource.BibID.Substring(6, 2) + "\\" + deleteResource.BibID.Substring(8);
                    string existing_folder = settings.Image_Server_Network + deleteResource.File_Root + "\\" + deleteResource.VID;

                    // Remove from the primary collection area
                    try
                    {
                        if (Directory.Exists(existing_folder))
                        {
                            // Make sure the delete folder exists
							if (!Directory.Exists(settings.Image_Server_Network + "\\RECYCLE BIN"))
                            {
								Directory.CreateDirectory(settings.Image_Server_Network + "\\RECYCLE BIN");
                            }

                            // Create the final directory
							string final_folder = settings.Image_Server_Network + "\\RECYCLE BIN\\" + deleteResource.File_Root + "\\" + deleteResource.VID;
                            if (!Directory.Exists(final_folder))
                            {
                                Directory.CreateDirectory(final_folder);
                            }

                            // Move each file
                            string[] delete_files = Directory.GetFiles(existing_folder);
                            foreach (string thisDeleteFile in delete_files)
                            {
                                string destination_file = final_folder + "\\" + Path.GetFileName(thisDeleteFile);
                                if (File.Exists(destination_file))
                                    File.Delete(destination_file);
                                File.Move(thisDeleteFile, destination_file);
                            }
                        }
                    }
                    catch (Exception ee)
                    {
                        Add_Error_To_Log("Unable to move resource ( " + deleteResource.BibID + ":" + deleteResource.VID + " ) to deletes", deleteResource.BibID + ":" + deleteResource.VID, deleteResource.METS_Type_String, deleteResource.BuilderLogId, ee);
                    }

                    // Delete the static page
	                string static_page1 = settings.Static_Pages_Location + deleteResource.BibID.Substring(0, 2) + "\\" + deleteResource.BibID.Substring(2, 2) + "\\" + deleteResource.BibID.Substring(4, 2) + "\\" + deleteResource.BibID.Substring(6, 2) + "\\" + deleteResource.BibID.Substring(8) + "\\" + deleteResource.VID + "\\" + deleteResource.BibID + "_" + deleteResource.VID + ".html";
					if (File.Exists(static_page1))
                    {
						File.Delete(static_page1);
                    }
					string static_page2 = settings.Static_Pages_Location + deleteResource.BibID.Substring(0, 2) + "\\" + deleteResource.BibID.Substring(2, 2) + "\\" + deleteResource.BibID.Substring(4, 2) + "\\" + deleteResource.BibID.Substring(6, 2) + "\\" + deleteResource.BibID.Substring(8) + "\\" + deleteResource.BibID + "_" + deleteResource.VID + ".html";
					if (File.Exists(static_page2))
					{
						File.Delete(static_page2);
					}

                    // Delete the file from the database
                    SobekCM_Database.Delete_SobekCM_Item(deleteResource.BibID, deleteResource.VID, true, "Deleted upon request by builder");

                    // Delete from the solr/lucene indexes
                    if (settings.Document_Solr_Index_URL.Length > 0)
                    {
                        try
                        {
                            Solr_Controller.Delete_Resource_From_Index(settings.Document_Solr_Index_URL, settings.Page_Solr_Index_URL, deleteResource.BibID, deleteResource.VID);
                        }
                        catch (Exception ee)
                        {
	                        Add_Error_To_Log("Error deleting item from the Solr/Lucene index.  The index may not reflect this delete.", deleteResource.BibID + ":" + deleteResource.VID, deleteResource.METS_Type_String, deleteResource.BuilderLogId);
							Add_Error_To_Log("Solr Error: " + ee.Message, deleteResource.BibID + ":" + deleteResource.VID, deleteResource.METS_Type_String, deleteResource.BuilderLogId);
                         }
                    }
                    

                    // Save these collections to mark them for search index building
                    Add_Delete_Info_To_PostProcess_Lists(deleteResource.BibID, deleteResource.VID, deleteResource.Metadata.Behaviors.Aggregation_Code_List);
                }
                else
                {
					Add_Error_To_Log("Delete ( " + deleteResource.BibID + ":" + deleteResource.VID + " ) invalid... no pre-existing resource", deleteResource.BibID + ":" + deleteResource.VID, deleteResource.METS_Type_String, deleteResource.BuilderLogId);

                    // Finally, clear the memory a little bit
                    deleteResource.Clear_METS();
                }

                // Delete the handled METS file and package
                deleteResource.Delete();
            }
        }

        #endregion

        #region Log-supporting methods

		private long Add_NonError_To_Log(string LogStatement, string DbLogType, string BibID_VID, string MetsType, long RelatedLogID )
        {
			if (multiInstanceBuilder)
			{
				Console.WriteLine(instanceName + " - " + LogStatement);
				logger.AddNonError(instanceName + " - " + LogStatement.Replace("\t", "....."));
			}
			else
			{
				Console.WriteLine( LogStatement);
				logger.AddNonError( LogStatement.Replace("\t", "....."));
			}
			return SobekCM_Database.Builder_Add_Log_Entry(RelatedLogID, BibID_VID, DbLogType, LogStatement.Replace("\t", ""), MetsType);
        }

		private long Add_NonError_To_Log(string LogStatement, bool IsVerbose, string BibID_VID, string MetsType, long RelatedLogID)
        {
            if (IsVerbose)
            {
	            if (multiInstanceBuilder)
	            {
		            Console.WriteLine(instanceName + " - " + LogStatement);
		            logger.AddNonError(instanceName + " - " + LogStatement.Replace("\t", "....."));
	            }
	            else
				{
					Console.WriteLine( LogStatement);
					logger.AddNonError( LogStatement.Replace("\t", "....."));
				}
	            return SobekCM_Database.Builder_Add_Log_Entry(RelatedLogID, BibID_VID, "Verbose", LogStatement.Replace("\t", ""), MetsType);
            }
			return -1;
        }

		private long Add_Error_To_Log(string LogStatement, string BibID_VID, string MetsType, long RelatedLogID)
        {
			if (multiInstanceBuilder)
			{
				Console.WriteLine(instanceName + " - " + LogStatement);
				logger.AddError(instanceName + " - " + LogStatement.Replace("\t", "....."));
			}
			else
			{
				Console.WriteLine( LogStatement);
				logger.AddError( LogStatement.Replace("\t", "....."));
			}
			return SobekCM_Database.Builder_Add_Log_Entry(RelatedLogID, BibID_VID, "Error", LogStatement.Replace("\t", ""), MetsType);
        }

        private void Add_Error_To_Log(string LogStatement, string BibID_VID, string MetsType, long RelatedLogID, Exception Ee)
        {
            if (multiInstanceBuilder)
            {
                Console.WriteLine(instanceName + " - " + LogStatement);
                logger.AddError(instanceName + " - " + LogStatement.Replace("\t", "....."));
            }
            else
            {
                Console.WriteLine(LogStatement);
                logger.AddError(LogStatement.Replace("\t", "....."));
            }
            long mainErrorId = SobekCM_Database.Builder_Add_Log_Entry(RelatedLogID, BibID_VID, "Error", LogStatement.Replace("\t", ""), MetsType);


            string[] split = Ee.ToString().Split("\n".ToCharArray());
            foreach (string thisSplit in split)
            {
                SobekCM_Database.Builder_Add_Log_Entry(mainErrorId, BibID_VID, "Error", thisSplit, MetsType);
            }


            // Save the exception to an exception file
            StreamWriter exception_writer = new StreamWriter(settings.Local_Log_Directory + "\\exceptions_log.txt", true);
            exception_writer.WriteLine(String.Empty);
            exception_writer.WriteLine(String.Empty);
            exception_writer.WriteLine("----------------------------------------------------------");
            exception_writer.WriteLine("EXCEPTION CAUGHT " + DateTime.Now.ToString() + " BY PRELOADER");
            exception_writer.WriteLine(LogStatement.ToUpper().Replace("\t", "").Trim());
            exception_writer.WriteLine(Ee.ToString());
            exception_writer.Flush();
            exception_writer.Close();
        }

        private void Add_Complete_To_Log(string LogStatement, string DbLogType, string BibID_VID, string MetsType, long RelatedLogID )
        {
	        if (multiInstanceBuilder)
	        {
		        Console.WriteLine(instanceName + " - " + LogStatement);
		        logger.AddComplete(instanceName + " - " + LogStatement.Replace("\t", "....."));
	        }
	        else
			{
				Console.WriteLine( LogStatement);
				logger.AddComplete( LogStatement.Replace("\t", "....."));
			}
	        SobekCM_Database.Builder_Add_Log_Entry(RelatedLogID, BibID_VID, DbLogType, LogStatement.Replace("\t", ""), MetsType);
        }

        #endregion

        #region Methods used to get the list of collections to mark in db for build

        private void Add_Aggregation_To_Refresh_List(string Code)
        {
            // Only continue if there is length
            if (Code.Length > 1)
            {
                // This aggregation should be refreshed
                if (!aggregations_to_refresh.Contains(Code.ToUpper()))
                    aggregations_to_refresh.Add(Code.ToUpper());
            }
        }

        private void Add_Process_Info_To_PostProcess_Lists(string BibID, string VID, IEnumerable<string> Codes)
        {
            foreach (string collectionCode in Codes)
            {
                Add_Aggregation_To_Refresh_List(collectionCode);
            }
            processed_items.Add(new BibVidStruct(BibID, VID));
        }

        private void Add_Delete_Info_To_PostProcess_Lists(string BibID, string VID, IEnumerable<string> Codes)
        {
            foreach (string collectionCode in Codes)
            {
                Add_Aggregation_To_Refresh_List(collectionCode);
            }
            deleted_items.Add(new BibVidStruct(BibID, VID));
        }

        #endregion

        #region Methods to handle checking for abort requests

		/// <summary> Flag indicates if the last run of the bulk loader was ABORTED </summary>
        public bool Aborted
        {
            get { return aborted; }
        }

        private bool CheckForAbort()
        {
	        if (!canAbort)
		        return false;

            if (aborted)
                return true;

            bool returnValue = Abort_Database_Mechanism.Abort_Requested();
            if (returnValue )
            {
                aborted = true;
                
                logger.AddError("ABORT REQUEST RECEIVED VIA DATABASE KEY");
            }
            return returnValue;
        }

        #endregion
        
		/// <summary> Gets the message to sum up this execution  </summary>
        public string Final_Message
        {
            get { return finalmessage; }
        }
    }
}
