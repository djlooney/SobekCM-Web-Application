﻿#region Using directives

using System;
using System.Collections.Generic;
using System.Text;
using System.Web.UI.WebControls;
using SobekCM.Core.Navigation;
using SobekCM.Core.Results;
using SobekCM.Tools;

#endregion

namespace SobekCM.Library.ResultsViewer
{
    /// <summary> Results viewer shows the titles/items in bookshelf view with the action links to the left to remove an item from the bookshelf,  edit a user note, and view the item.  The view also includes any current user notes below the title </summary>
    /// <remarks> This class extends the abstract class <see cref="abstract_ResultsViewer"/> and implements the 
    /// <see cref="iResultsViewer" /> interface. </remarks>
    public class Bookshelf_View_ResultsViewer : abstract_ResultsViewer
    {
        /// <summary> Constructor for a new instance of the Bookshelf_View_ResultsViewer class </summary>
        /// <param name="RequestSpecificValues"> All the necessary, non-global data specific to the current request </param>
        /// <param name="ResultsStats"> Statistics about the results to display including the facets </param>
        /// <param name="PagedResults"> Actual pages of results </param>
        public Bookshelf_View_ResultsViewer(RequestCache RequestSpecificValues, Search_Results_Statistics ResultsStats, List<iSearch_Title_Result> PagedResults)
            : base(RequestSpecificValues, ResultsStats, PagedResults)
        {
            // do nothing
        }

        /// <summary> Adds the controls for this result viewer to the place holder on the main form </summary>
        /// <param name="MainPlaceHolder"> Main place holder ( &quot;mainPlaceHolder&quot; ) in the itemNavForm form into which the the bulk of the result viewer's output is displayed</param>
        /// <param name="Tracer"> Trace object keeps a list of each method executed and important milestones in rendering </param>
        /// <returns> Sorted tree with the results in hierarchical structure with volumes and issues under the titles and sorted by serial hierarchy </returns>
        public override void Add_HTML(PlaceHolder MainPlaceHolder, Custom_Tracer Tracer)
        {
            if (Tracer != null)
            {
                Tracer.Add_Trace("Bookshelf_View_ResultsViewer.Add_HTML", "Rendering results in table view");
            }

            // If results are null, or no results, return empty string
            if ((PagedResults == null) || (ResultsStats == null) || (ResultsStats.Total_Items <= 0))
                return;

            // Get the text search redirect stem and (writer-adjusted) base url 
            string textRedirectStem = Text_Redirect_Stem;
            string base_url = RequestSpecificValues.Current_Mode.Base_URL;
            if (RequestSpecificValues.Current_Mode.Writer_Type == Writer_Type_Enum.HTML_LoggedIn)
                base_url = RequestSpecificValues.Current_Mode.Base_URL + "l/";

            // Start this table
            StringBuilder resultsBldr = new StringBuilder(5000);
            resultsBldr.AppendLine();
            resultsBldr.AppendLine("<br />\n<table width=\"100%\" cellspacing=\"0px\" class=\"statsTable\">");

            // Start the header row and add the 'No.' part
            resultsBldr.AppendLine("\t<tr align=\"left\" bgcolor=\"#0022a7\" >");
            resultsBldr.AppendLine("\t\t<td width=\"170px\"><span style=\"color: White\"><b> &nbsp; ACTIONS</b></span></td>");
            resultsBldr.AppendLine("\t\t<td width=\"25px\">&nbsp;</td>");
            resultsBldr.AppendLine("\t\t<td><span style=\"color: White\"><b>TITLE / NOTES</b></span></td>");
            resultsBldr.AppendLine("\t</tr>");

            resultsBldr.AppendLine("\t<tr><td bgcolor=\"#e7e7e7\" colspan=\"3\"></td></tr>");

            // Add the next row for manipulating checked items
            resultsBldr.AppendLine("\t<tr align=\"left\" bgcolor=\"#7d90d5\" >");
            resultsBldr.Append("\t\t<td class=\"SobekFolderActionLink\" ><span style=\"color: White\"> ( <a href=\"\" id=\"bookshelf_all_remove\" name=\"bookshelf_all_remove\" onclick=\"return remove_all('" + PagedResults.Count + "' );\"><span style=\"color: White\" title=\"Remove all checked items from your bookshelf\" >remove<span style=\"color: White\"></a> | ");
            resultsBldr.AppendLine("<a href=\"\" id=\"bookshelf_all_move\" id=\"bookshelf_all_move\" onclick=\"return move_all('" + PagedResults.Count + "' );\"><span style=\"color: White\" title=\"Move all checked items to a new bookshelf\" >move<span style=\"color: White\"></a> )</span></td>");

            // Add the check box (checks all or removes all checks)
            resultsBldr.AppendLine("\t\t<td><span style=\"color: White\"><input title=\"Select or unselect all items in this bookshelf\" type=\"checkbox\" id=\"bookshelf_all_check\" name=\"bookshelf_all_check\" onclick=\"bookshelf_all_check_clicked('" + PagedResults.Count + "');\" /></span></td>");

            // Add the title
            resultsBldr.AppendLine("\t\t<td><span style=\"color: White\">&nbsp;</span></td>\n\t</tr>");

            // Add this to the place holder
            Literal startLiteral = new Literal {Text = resultsBldr.ToString()};
            MainPlaceHolder.Controls.Add(startLiteral);
            resultsBldr.Remove(0, resultsBldr.Length);

            // Determine if this is an internal user
            bool internal_user = (RequestSpecificValues.Current_User != null) && ((RequestSpecificValues.Current_User.Is_Internal_User) || (RequestSpecificValues.Current_User.Is_System_Admin));

            // Set the counter for these results from the page 
            int current_row = 0;

            // Step through all the results
            foreach (iSearch_Title_Result titleResult in PagedResults)
            {
                // Write a single row
                Write_Single_Row(resultsBldr, titleResult, current_row + 1, textRedirectStem, base_url, internal_user);

                // Add a horizontal line
                resultsBldr.AppendLine("\t<tr><td bgcolor=\"#e7e7e7\" colspan=\"3\"></td></tr>");
                current_row++;
            }

            // End this table
            resultsBldr.AppendLine("</table>");

            // Add this to the html table
            Literal mainLiteral = new Literal
                                      { Text = resultsBldr.ToString().Replace("&lt;role&gt;", "<i>").Replace( "&lt;/role&gt;", "</i>") };
            MainPlaceHolder.Controls.Add(mainLiteral);
        }

        private void Write_Single_Row(StringBuilder resultsBldr, iSearch_Title_Result titleRow, int index_in_page, string textRedirectStem, string base_url, bool internal_user)
        {
            // Start this row
            resultsBldr.AppendLine("\t<tr valign=\"top\">");
            iSearch_Item_Result itemRow = titleRow.Get_Item(0);
            string identifier = titleRow.BibID.ToUpper() + "_" + itemRow.VID;

            // Add the actions as the first column
            resultsBldr.Append("\t\t<td class=\"SobekFolderActionLink\" width=\"170px\" >( ");
            resultsBldr.Append("<a title=\"Remove this item from your bookshelf\" href=\"\" onclick=\"return remove_item( '" + identifier + "' );\">remove</a> | ");
            resultsBldr.Append("<a title=\"Move this item to a new bookshelf\" href=\"\" name=\"item_move_" + index_in_page + "\" id=\"item_move_" + index_in_page + "\" onclick=\"return move_form_open('item_move_" + index_in_page + "', '" + identifier + "' );\">move</a> | ");
            resultsBldr.Append("<a title=\"Send this item to a friend\" href=\"\" name=\"item_send_" + index_in_page + "\" id=\"item_send_" + index_in_page + "\" onclick=\"return email_form_open('item_send_" + index_in_page + "', '" + identifier + "' );\">send</a>");

            if (internal_user)
            {
                resultsBldr.Append(" | <a title=\"Edit this item\" href=\"" + RequestSpecificValues.Current_Mode.Base_URL + "my/edit/" + titleRow.BibID + "/" + itemRow.VID + "\" name=\"item_edit_" + index_in_page + "\" id=\"item_edit_" + index_in_page + "\" >edit</a> )</td>\n");
            }
            else
            {
                resultsBldr.AppendLine(" ) </td>");
            }

            // Add the check box
            resultsBldr.AppendLine("\t\t<td><input title=\"Select or unselect this item\"  type=\"checkbox\" name=\"item_select_" + index_in_page.ToString() + "\" id=\"item_select_" + index_in_page.ToString() + "\" value=\"" + identifier + "\" /></td>");


            string user_notes = titleRow.UserNotes;

            // Add the title and user notes next
            resultsBldr.Append("\t\t<td><a href=\"" + base_url + titleRow.BibID + "/" + itemRow.VID + textRedirectStem + "\">" + itemRow.Title);
            if ((itemRow.Level1_Text.Length > 0) || (itemRow.Level2_Text.Length > 0) || (itemRow.Level3_Text.Length > 0))
            {
                resultsBldr.Append(" ( ");
                if (itemRow.Level1_Text.Length > 0)
                    resultsBldr.Append(itemRow.Level1_Text);
                if (itemRow.Level2_Text.Length > 0)
                    resultsBldr.Append(" - " + itemRow.Level2_Text);
                if (itemRow.Level3_Text.Length > 0)
                    resultsBldr.Append(" - " + itemRow.Level3_Text);
                resultsBldr.Append(" ) ");
            }

            resultsBldr.AppendLine("</a>");
            if (!String.IsNullOrEmpty(user_notes))
            {
                resultsBldr.AppendLine("<br />" + user_notes + " <span class=\"SobekFolderActionLink\">( <a href=\"\" onclick=\"return edit_notes_form_open('item_send_" + index_in_page + "', '" + identifier + "','" + user_notes.Replace("\"", "%22").Replace("'", "%27").Replace("=", "%3D").Replace("&", "%26") + "' );\">edit note</a> )</span></td>");
            }
            else
            {
                resultsBldr.AppendLine("<br /><span class=\"SobekFolderActionLink\">( <a href=\"\" onclick=\"return edit_notes_form_open('item_send_" + index_in_page + "', '" + identifier + "','' );\" >add note</a> )</span></td>");
            }

            // End this row
            resultsBldr.AppendLine("\t</tr>");
        }
    }
}

