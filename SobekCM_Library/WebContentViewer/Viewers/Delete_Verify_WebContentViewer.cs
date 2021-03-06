﻿using System;
using System.IO;
using System.Web;
using SobekCM.Core.Client;
using SobekCM.Core.MemoryMgmt;
using SobekCM.Core.Message;
using SobekCM.Core.Navigation;
using SobekCM.Core.WebContent;
using SobekCM.Engine_Library.Configuration;
using SobekCM.Library.UI;
using SobekCM.Tools;

namespace SobekCM.Library.WebContentViewer.Viewers
{
    /// <summary> Web content viewer requests verification to delete a web content page or redirect before it is deleted </summary>
    /// <remarks> This viewer extends the <see cref="abstractWebContentViewer" /> abstract class and implements the <see cref="iWebContentViewer"/> interface. </remarks>
    public class Delete_Verify_WebContentViewer : abstractWebContentViewer
    {
        private readonly string errorMessage;
        private readonly bool canDelete;
        private readonly HTML_Based_Content webContent;
        private readonly bool deleted;

        /// <summary>  Constructor for a new instance of the Delete_Verify_WebContentViewer class  </summary>
        /// <param name="RequestSpecificValues">  All the necessary, non-global data specific to the current request  </param>
        /// <param name="StaticPage"> Static page info for this request </param>
        public Delete_Verify_WebContentViewer(RequestCache RequestSpecificValues, HTML_Based_Content StaticPage)
            : base(RequestSpecificValues, StaticPage )
        {
            // Pull the web content page
            if (RequestSpecificValues.Current_Mode.WebContentID.HasValue)
                webContent = SobekEngineClient.WebContent.Get_HTML_Based_Content(RequestSpecificValues.Current_Mode.WebContentID.Value, true, RequestSpecificValues.Tracer);

            // This should never occur, but just a double check
            if ((webContent == null) || (!webContent.WebContentID.HasValue))
            {
                RequestSpecificValues.Current_Mode.Mode = Display_Mode_Enum.Aggregation;
                UrlWriterHelper.Redirect(RequestSpecificValues.Current_Mode);
                return;
            }

            // Ensure there IS a logged on user 
            RequestSpecificValues.Tracer.Add_Trace("Delete_Item_MySobekViewer.Delete_Verify_WebContentViewer", "Validate user");
            if ((RequestSpecificValues.Current_User == null) || (!RequestSpecificValues.Current_User.LoggedOn))
            {
                RequestSpecificValues.Current_Mode.Mode = Display_Mode_Enum.Aggregation;
                UrlWriterHelper.Redirect(RequestSpecificValues.Current_Mode);
                return;
            }

            // If the user was logged on, but did not have permissions, show an error message
            canDelete = true;
            deleted = false;
            if (!webContent.Can_Delete(RequestSpecificValues.Current_User))
            {
                errorMessage = "ERROR: You do not have permission to delete this page";
                canDelete = false;
            }
            else if ( HttpContext.Current.Request.RequestType == "POST" )
            {
                string save_value = HttpContext.Current.Request.Form["admin_delete_item"];

                // Better say "DELETE", or just send back to the item
                if (( save_value != null ) && ( String.Compare(save_value,"DELETE", StringComparison.OrdinalIgnoreCase) == 0))
                {
                    string entered_value = HttpContext.Current.Request.Form["admin_delete_confirm"];
                    if ((entered_value == null) || (entered_value.ToUpper() != "DELETE"))
                    {
                        errorMessage = "ERROR: To verify this deletion, type DELETE into the text box and press CONFIRM";
                    }
                    else
                    {
                        string deleteReason = "Requested via web application";


                        RestResponseMessage message = SobekEngineClient.WebContent.Delete_HTML_Based_Content(webContent.WebContentID.Value, RequestSpecificValues.Current_User.Full_Name, deleteReason, RequestSpecificValues.Tracer);

                        errorMessage = message.Message;
                        if ((message.ErrorTypeEnum != ErrorRestTypeEnum.Successful) && (String.IsNullOrEmpty(errorMessage)))
                        {
                            errorMessage = "Error encountered on SobekCM engine.";
                        }
                        else
                        {
                            errorMessage = "Successfully deleted this web content page.";

                            // Clear cached data here on the client
                            CachedDataManager.WebContent.Clear_All_Web_Content_Lists();
                            CachedDataManager.WebContent.Clear_All_Web_Content_Pages();
                            CachedDataManager.WebContent.Clear_Page_Details();
                            UI_ApplicationCache_Gateway.WebContent_Hierarchy_Clear();

                            deleted = true;
                        }
                    }
                }

            }
        }


        /// <summary> Gets the type of specialized web content viewer </summary>
        public override WebContent_Type_Enum Type { get { return WebContent_Type_Enum.Delete_Verify; }}

        /// <summary> Title for the page that displays this viewer, this is shown in the search box at the top of the page, just below the banner </summary>
        public override string Viewer_Title
        {
            get { return "Verify Web Content Deletion"; }
        }

        /// <summary> Gets the URL for the icon related to this web content viewer task </summary>
        public override string Viewer_Icon
        {
            get { return null; }
        }

        /// <summary> Add the HTML to be displayed </summary>
        /// <param name="Output"> Textwriter to write the HTML for this viewer </param>
        /// <param name="Tracer">Trace object keeps a list of each method executed and important milestones in rendering</param>
        public override void Add_HTML(TextWriter Output, Custom_Tracer Tracer)
        {
            if (Tracer != null)
            {
                Tracer.Add_Trace("Delete_Verify_WebContentViewer.Add_HTML", "No html added");
            }

            // Start the form
            string return_url = (RequestSpecificValues.Current_Mode.Base_URL + HttpContext.Current.Request.RawUrl).Replace("//", "/").Replace("http:/", "http://");
            Output.WriteLine("<form name=\"itemNavForm\" method=\"post\" action=\"" + return_url + "\" id=\"itemNavForm\">");

            // Add the hidden field
            Output.WriteLine("<!-- Hidden field is used for postbacks to indicate what to save and reset -->");
            Output.WriteLine("<input type=\"hidden\" id=\"admin_delete_item\" name=\"admin_delete_item\" value=\"\" />");
            Output.WriteLine();

            if (!String.IsNullOrEmpty(errorMessage))
            {
                Output.WriteLine("  <br />");
                Output.WriteLine("  <div id=\"sbkWchs_ActionMessageError\">" + errorMessage + "</div>");
            }

            if (!deleted)
            {

                Output.WriteLine("<div class=\"Wchs_Text\">");
                Output.WriteLine("  <p>This form allows you to delete a web content page from the system.  The source files will remain, but the page or redirect will be removed from the system.</p>");
                Output.WriteLine();
                Output.WriteLine("  <table id=\"sbkWchs_DeleteTable\">");
                Output.WriteLine("    <tr><td>Title: &nbsp; </td><td>" + webContent.Title + "</td></tr>");
                string url = webContent.URL(RequestSpecificValues.Current_Mode.Base_URL);
                Output.WriteLine("    <tr><td>URL:</td><td><a href=\"" + url + "\">" + url + "</a></td></tr>");
                Output.WriteLine("  </table>");
                Output.WriteLine();

                if (canDelete)
                {
                    Output.WriteLine("  <p>Enter DELETE in the textbox below and select GO to complete this deletion.</p>");
                    Output.WriteLine("  <div id=\"sbkWchs_DeleteVerifyDiv\">");
                    Output.WriteLine("    <input class=\"sbkDimv_input sbk_Focusable\" name=\"admin_delete_confirm\" id=\"admin_delete_confirm\" type=\"text\" value=\"\" /> &nbsp; &nbsp; ");
                    Output.WriteLine("    <button title=\"Confirm delete of this page\" class=\"roundbutton\" onclick=\"delete_item(); return false;\">CONFIRM <img src=\"" + Static_Resources_Gateway.Button_Next_Arrow_Png + "\" class=\"sbkMySobek_RoundButton_RightImg\" alt=\"\" /></button>");
                    Output.WriteLine("  </div>");
                }

                Output.WriteLine("</div>");
            }

            Output.WriteLine();
            Output.WriteLine("<!-- Focus on confirm box -->");
            Output.WriteLine("<script type=\"text/javascript\">focus_element('admin_delete_confirm');</script>");
            Output.WriteLine();

            Output.WriteLine("</form>");
            Output.WriteLine();
        }
    }
}
