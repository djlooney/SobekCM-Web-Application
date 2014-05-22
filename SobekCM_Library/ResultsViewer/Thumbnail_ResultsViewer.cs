#region Using directives

using System.Text;
using System.Web.UI.WebControls;
using SobekCM.Library.Application_State;
using SobekCM.Library.Navigation;
using SobekCM.Library.Results;
using SobekCM.Library.Search;
using SobekCM.Library.Settings;

#endregion

namespace SobekCM.Library.ResultsViewer
{
    /// <summary> Results viewer shows just the thumbnails for each item in a large grid.  </summary>
    /// <remarks> This class extends the abstract class <see cref="abstract_ResultsViewer"/> and implements the 
    /// <see cref="iResultsViewer" /> interface. </remarks>
    public class Thumbnail_ResultsViewer : abstract_ResultsViewer
    {
        /// <summary> Constructor for a new instance of the Thumbnail_ResultsViewer class </summary>
        /// <param name="All_Items_Lookup"> Lookup object used to pull basic information about any item loaded into this library </param>
        public Thumbnail_ResultsViewer(Item_Lookup_Object All_Items_Lookup)
        {
            base.All_Items_Lookup = All_Items_Lookup;
        }

        /// <summary> Adds the controls for this result viewer to the place holder on the main form </summary>
        /// <param name="MainPlaceHolder"> Main place holder ( &quot;mainPlaceHolder&quot; ) in the itemNavForm form into which the the bulk of the result viewer's output is displayed</param>
        /// <param name="Tracer"> Trace object keeps a list of each method executed and important milestones in rendering </param>
        /// <returns> Sorted tree with the results in hierarchical structure with volumes and issues under the titles and sorted by serial hierarchy </returns>
        public override void Add_HTML(PlaceHolder MainPlaceHolder, Custom_Tracer Tracer)
        {
            if (Tracer != null)
            {
                Tracer.Add_Trace("Thumbnail_ResultsWriter.Add_HTML", "Rendering results in thumbnail view");
            }

            // If results are null, or no results, return empty string
            if ((Paged_Results == null) || (Results_Statistics == null) || (Results_Statistics.Total_Items <= 0))
                return;

            // Get the text search redirect stem and (writer-adjusted) base url 
            string textRedirectStem = Text_Redirect_Stem;
            string base_url = CurrentMode.Base_URL;
            if (CurrentMode.Writer_Type == Writer_Type_Enum.HTML_LoggedIn)
                base_url = CurrentMode.Base_URL + "l/";

            // Should the publication date be shown?
            bool showDate = false;
            if (CurrentMode.Sort >= 10)
            {
                showDate = true;
            }

            // Start this table
            StringBuilder resultsBldr = new StringBuilder(5000);

            //Add the necessary JavaScript, CSS files
            //resultsBldr.AppendLine("<script type=\"text/javascript\" src=\"" + CurrentMode.Base_URL + "default/scripts/jquery/jquery-1.10.2.min.js\"></script>");
            //resultsBldr.AppendLine("<script type=\"text/javascript\" src=\"" + CurrentMode.Base_URL + "default/scripts/jquery/jquery.qtip.min.js\"></script>");
            //resultsBldr.AppendLine("  <link rel=\"stylesheet\" type=\"text/css\" href=\"" + CurrentMode.Base_URL + "default/scripts/jquery/jquery.qtip.min.css\" /> ");


    //        resultsBldr.AppendLine("<script type=\"text/javascript\" src=\"" + CurrentMode.Base_URL + "default/scripts/jquery/jquery-ui-1.10.1.js\"></script>");
            resultsBldr.AppendLine("  <script type=\"text/javascript\" src=\"" + CurrentMode.Base_URL + "default/scripts/sobekcm_thumb_results.js\"></script>");


            // Start this table
            resultsBldr.AppendLine("<table align=\"center\" width=\"100%\" cellspacing=\"15px\">");
            resultsBldr.AppendLine("\t<tr>");
            resultsBldr.AppendLine("\t\t<td width=\"25%\">&nbsp;</td>");
            resultsBldr.AppendLine("\t\t<td width=\"25%\">&nbsp;</td>");
            resultsBldr.AppendLine("\t\t<td width=\"25%\">&nbsp;</td>");
            resultsBldr.AppendLine("\t\t<td width=\"25%\">&nbsp;</td>");
            resultsBldr.AppendLine("\t</tr>");
            resultsBldr.AppendLine("\t<tr valign=\"top\">");

            // Step through all the results
            int col = 0;
            int title_count = 0;

            foreach (iSearch_Title_Result titleResult in Paged_Results)
            {
                title_count++;
                // Should a new row be started
                if (col == 4)
                {
                    col = 0;
                    resultsBldr.AppendLine("\t</tr>");
                    // Horizontal Line
                    resultsBldr.AppendLine("\t<tr><td bgcolor=\"#e7e7e7\" colspan=\"4\"></td></tr>");
                    resultsBldr.AppendLine("\t<tr valign=\"top\">");
                }

                bool multiple_title = titleResult.Item_Count > 1;

                // Always get the first item for things like the main link and thumbnail
                iSearch_Item_Result firstItemResult = titleResult.Get_Item(0);

                // Determine the internal link to the first (possibly only) item
                string internal_link = base_url + titleResult.BibID + "/" + firstItemResult.VID + textRedirectStem;

                // For browses, just point to the title
                if ((CurrentMode.Mode == Display_Mode_Enum.Aggregation) && ( CurrentMode.Aggregation_Type == Aggregation_Type_Enum.Browse_Info ))
                    internal_link = base_url + titleResult.BibID + textRedirectStem;

                resultsBldr.AppendLine("\t\t<td align=\"center\" onmouseover=\"this.className='tableRowHighlight'\" onmouseout=\"this.className='tableRowNormal'\" onclick=\"window.location.href='" + internal_link + "';\" >");

                string title;
                if (multiple_title)
                {
                    // Determine term to use
                    string multi_term = "volume";
                    if (titleResult.MaterialType.ToUpper() == "NEWSPAPER")
                    {
                        multi_term = titleResult.Item_Count > 1 ? "issues" : "issue";
                    }
                    else
                    {
                        if (titleResult.Item_Count > 1)
                            multi_term = "volumes";
                    }

                    if ((showDate))
                    {
                        if (firstItemResult.PubDate.Length > 0)
                        {
                            title = "[" + firstItemResult.PubDate + "] " + titleResult.GroupTitle;
                        }
                        else
                        {
                            title = titleResult.GroupTitle;
                        }
                    }
                    else
                    {
                        title = titleResult.GroupTitle + "<br />( " + titleResult.Item_Count + " " + multi_term + " )";
                    }
                }
                else
                {
                    if (showDate)
                    {
                        if (firstItemResult.PubDate.Length > 0)
                        {
                            title = "[" + firstItemResult.PubDate + "] " + firstItemResult.Title;
                        }
                        else
                        {
                            title = firstItemResult.Title;
                        }
                    }
                    else
                    {
                        title = firstItemResult.Title;
                    }
                }

                // Start the HTML for this item
                resultsBldr.AppendLine("<table width=\"150px\">");

                //// Is this restricted?
                bool restricted_by_ip = false;
                if ((titleResult.Item_Count == 1) && (firstItemResult.IP_Restriction_Mask > 0))
                {
                    int comparison = firstItemResult.IP_Restriction_Mask & current_user_mask;
                    if (comparison == 0)
                    {
                        restricted_by_ip = true;
                    }
                }

                // Calculate the thumbnail

                // Add the thumbnail
                if ((firstItemResult.MainThumbnail.ToUpper().IndexOf(".JPG") < 0) && (firstItemResult.MainThumbnail.ToUpper().IndexOf(".GIF") < 0))
                {
                    resultsBldr.AppendLine("<tr><td><span id=\"sbkThumbnailSpan"+title_count+"\"><a href=\"" + internal_link + "\"><img id=\"sbkThumbnailImg" + title_count + "\" src=\"" + CurrentMode.Default_Images_URL + "NoThumb.jpg\" /></a></span></td></tr>");
                }
                else
                {
                    string thumb = SobekCM_Library_Settings.Image_URL + titleResult.BibID.Substring(0, 2) + "/" + titleResult.BibID.Substring(2, 2) + "/" + titleResult.BibID.Substring(4, 2) + "/" + titleResult.BibID.Substring(6, 2) + "/" + titleResult.BibID.Substring(8) + "/" + firstItemResult.VID + "/" + (firstItemResult.MainThumbnail).Replace("\\", "/").Replace("//", "/");
                    resultsBldr.AppendLine("<tr><td><span id=\"sbkThumbnailSpan" + title_count + "\"><a href=\"" + internal_link + "\"><img id=\"sbkThumbnailImg" + title_count + "\"src=\"" + thumb + "\" alt=\"MISSING THUMBNAIL\" /></a></span></td></tr>");
                }

                #region Add the div displayed as a tooltip for this thumbnail on hover
             
                const string VARIES_STRING = "<span style=\"color:Gray\">( varies )</span>";
                //Add the hidden item values for display in the tooltip
                resultsBldr.AppendLine("<tr style=\"display:none;\"><td colspan=\"100%\"><div  id=\"descThumbnail" + title_count + "\" >");
                   // Add each element to this table
                resultsBldr.AppendLine("\t\t\t<table cellspacing=\"0px\">");

                if (multiple_title)
                {
                    //<a href=\"" + internal_link + "\">
                    resultsBldr.AppendLine("\t\t\t\t<tr style=\"height:40px;\" valign=\"middle\"><td colspan=\"3\"><span class=\"qtip_BriefTitle\" style=\"color: #a5a5a5;font-weight: bold;\">" + titleResult.GroupTitle.Replace("<", "&lt;").Replace(">", "&gt;") + "</span> &nbsp; </td></tr>");
                    resultsBldr.AppendLine("<tr><td colspan=\"100%\"><br/></td></tr>");
                }
                else
                {
                    resultsBldr.AppendLine(
                        "\t\t\t\t<tr style=\"height:40px;\" valign=\"middle\"><td colspan=\"3\"><span class=\"qtip_BriefTitle\" style=\"color: #a5a5a5;font-weight: bold;\">" + firstItemResult.Title.Replace("<", "&lt;").Replace(">", "&gt;") +
                        "</span> &nbsp; </td></tr><br/>");
                    resultsBldr.AppendLine("<tr><td colspan=\"100%\"><br/></td></tr>");
                }

                if ((titleResult.Primary_Identifier_Type.Length > 0) && (titleResult.Primary_Identifier.Length > 0))
                {
                    resultsBldr.AppendLine("\t\t\t\t<tr><td>" + Translator.Get_Translation(titleResult.Primary_Identifier_Type, CurrentMode.Language) + ":</td><td>&nbsp;</td><td>" + titleResult.Primary_Identifier + "</td></tr>");
                }

                if (CurrentMode.Internal_User)
                {
                    resultsBldr.AppendLine("\t\t\t\t<tr><td>BibID:</td><td>&nbsp;</td><td>" + titleResult.BibID + "</td></tr>");

                    if (titleResult.OPAC_Number > 1)
                    {
                        resultsBldr.AppendLine("\t\t\t\t<tr><td>OPAC:</td><td>&nbsp;</td><td>" +titleResult.OPAC_Number + "</td></tr>");
                    }

                    if (titleResult.OCLC_Number > 1)
                    {
                        resultsBldr.AppendLine("\t\t\t\t<tr><td>OCLC:</td><td>&nbsp;</td><td>" + titleResult.OCLC_Number + "</td></tr>");
                    }
                }

				for (int i = 0 ; i < Results_Statistics.Metadata_Labels.Count ; i++ )
				{
					string field = Results_Statistics.Metadata_Labels[i];
					string value = titleResult.Metadata_Display_Values[i];
					Metadata_Search_Field thisField = SobekCM_Library_Settings.Metadata_Search_Field_By_Name(field);
					string display_field = string.Empty;
					if ( thisField != null )
						display_field = thisField.Display_Term;
					if (display_field.Length == 0)
						display_field = field.Replace("_", " ");

					if (value == "*")
					{
						resultsBldr.AppendLine("\t\t\t\t<tr><td>" + Translator.Get_Translation(display_field, CurrentMode.Language) + ":</td><td>&nbsp;</td><td>" + VARIES_STRING + "</td></tr>");
					}
					else if ( value.Trim().Length > 0 )
					{
						if (value.IndexOf("|") > 0)
						{
							bool value_found = false;
							string[] value_split = value.Split("|".ToCharArray());

							foreach (string thisValue in value_split)
							{
								if (thisValue.Trim().Trim().Length > 0)
								{
									if (!value_found)
									{
										resultsBldr.AppendLine("\t\t\t\t<tr valign=\"top\"><td>" + Translator.Get_Translation(display_field, CurrentMode.Language) + ":</td><td>&nbsp;</td><td>");
										value_found = true;
									}
									resultsBldr.Append(System.Web.HttpUtility.HtmlEncode(thisValue) + "<br />");
								}
							}

							if (value_found)
							{
								resultsBldr.AppendLine("</td></tr>");
							}
						}
						else
						{
							resultsBldr.AppendLine("\t\t\t\t<tr><td>" + Translator.Get_Translation(display_field, CurrentMode.Language) + ":</td><td>&nbsp;</td><td>" + System.Web.HttpUtility.HtmlEncode(value) + "</td></tr>");
						}
					}
				}

	
                if (titleResult.Snippet.Length > 0)
                {
                    resultsBldr.AppendLine("\t\t\t\t<tr><td colspan=\"3\"><br />&ldquo;..." + titleResult.Snippet.Replace("<em>", "<span class=\"texthighlight\">").Replace ("</em>", "</span>") + "...&rdquo;</td></tr>");
                }

                resultsBldr.AppendLine("\t\t\t</table>");

                // End this row
     //           resultsBldr.AppendLine("\t\t<br />");

                //// Add children, if there are some
                //if (multiple_title)
                //{
                //    // Add this to the place holder
                //    Literal thisLiteral = new Literal
                //                              { Text = resultsBldr.ToString().Replace("&lt;role&gt;", "<i>").Replace( "&lt;/role&gt;", "</i>") };
                //    MainPlaceHolder.Controls.Add(thisLiteral);
                //    resultsBldr.Remove(0, resultsBldr.Length);

                //    Add_Issue_Tree(MainPlaceHolder, titleResult, current_row, textRedirectStem, base_url);
                //}

                //resultsBldr.AppendLine("\t\t</td>");
                //resultsBldr.AppendLine("\t</tr>");

                // Add a horizontal line
         //       resultsBldr.AppendLine("\t<tr><td bgcolor=\"#e7e7e7\" colspan=\"3\"></td></tr>");

 
       
            // End this table
 //           resultsBldr.AppendLine("</table>");
            resultsBldr.AppendLine("</div></td></tr>");


                #endregion


                // Add the title
                resultsBldr.AppendLine("<tr><td align=\"center\"><span class=\"SobekThumbnailText\">" + title + "</span></td></tr>");

                // If this was access restricted, add that
                if (restricted_by_ip)
                {
                    resultsBldr.AppendLine("<tr><td align=\"center\"><span class=\"RestrictedItemText\">Access Restricted</span></td></tr>");
                }

                // Finish this one thumbnail
                resultsBldr.AppendLine("</table></td>");
                col++;
            }

            // Finish this row out
            while (col < 4)
            {
                resultsBldr.AppendLine("\t\t<td>&nbsp;</td>");
                col++;
            }

            // End this table
            resultsBldr.AppendLine("\t</tr>");
            resultsBldr.AppendLine("</table>");

            // Add this to the html table
            Literal mainLiteral = new Literal {Text = resultsBldr.ToString()};
            MainPlaceHolder.Controls.Add(mainLiteral);
        }
    }
}
