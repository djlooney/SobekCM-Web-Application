﻿#region Using directives

using System.IO;
using System.Text;
using SobekCM.Tools;

#endregion

namespace SobekCM.Library.ItemViewer.Viewers
{
    /// <summary> Item viewer displays a you tube video embedded in within the SobekCM window. </summary>
    /// <remarks> This class extends the abstract class <see cref="abstractItemViewer_OLD"/> and implements the 
    /// <see cref="iItemViewer" /> interface. </remarks>
    public class YouTube_Embedded_Video_ItemViewer : abstractItemViewer_OLD
    {
        /// <summary> Gets the type of item viewer this object represents </summary>
        /// <value> This property always returns the enumerational value <see cref="ItemViewer_Type_Enum.YouTube_Video"/>. </value>
        public override ItemViewer_Type_Enum ItemViewer_Type
        {
            get { return ItemViewer_Type_Enum.YouTube_Video; }
        }

        /// <summary> Flag indicates if this view should be overriden if the item is checked out by another user </summary>
        /// <remarks> This always returns the value TRUE for this viewer </remarks>
        public override bool Override_On_Checked_Out
        {
            get
            {
                return true;
            }
        }

        /// <summary> Gets the number of pages for this viewer </summary>
        /// <value> This is a single page viewer, so this property always returns the value 1</value>
        public override int PageCount
        {
            get
            {
                return 1;
            }
        }

        /// <summary> Gets the flag that indicates if the page selector should be shown </summary>
        /// <value> This is a single page viewer, so this property always returns NONE</value>
        public override ItemViewer_PageSelector_Type_Enum Page_Selector
        {
            get
            {
                return ItemViewer_PageSelector_Type_Enum.NONE;
            }
        }

        /// <summary> Width for the main viewer section to adjusted to accomodate this viewer</summary>
        /// <value> This always returns the value 650 </value>
        public override int Viewer_Width
        {
            get
            {
                return 650;
            }
        }

        /// <summary> Stream to which to write the HTML for this subwriter  </summary>
        /// <param name="Output"> Response stream for the item viewer to write directly to </param>
        /// <param name="Tracer"> Trace object keeps a list of each method executed and important milestones in rendering </param>
        public override void Write_Main_Viewer_Section(TextWriter Output, Custom_Tracer Tracer)
        {
            if (Tracer != null)
            {
                Tracer.Add_Trace("YouTube_Embedded_Video_ItemViewer.Write_Main_Viewer_Section", "");
            }

            //Determine the name of the FLASH file
            string youtube_url = CurrentItem.Bib_Info.Location.Other_URL;
             if ( youtube_url.IndexOf("watch") > 0 )
                 youtube_url = youtube_url.Replace("watch?v=","v/") + "?fs=1&amp;hl=en_US";
            const int width = 600;
            const int height = 480;

            // Add the HTML for the image
            StringBuilder result = new StringBuilder(500);
            Output.WriteLine("          <td><div id=\"sbkEmv_ViewerTitle\">Streaming Video</div></td>");
            Output.WriteLine("        </tr>");
            Output.WriteLine("        <tr>");
            Output.WriteLine("          <td id=\"sbkEmv_MainArea\">");
            Output.WriteLine("            <object style=\"width:" + width + ";height:" + height + "\">");
            Output.WriteLine("              <param name=\"allowscriptaccess\" value=\"always\" />");
            Output.WriteLine("              <param name=\"movie\" value=\"" + youtube_url + "\" />");
            Output.WriteLine("              <param name=\"allowFullScreen\" value=\"true\"></param>");
            Output.WriteLine("              <embed src=\"" + youtube_url + "\" type=\"application/x-shockwave-flash\" AllowScriptAccess=\"always\" allowfullscreen=\"true\" width=\"" + width + "\" height=\"" + height + "\"></embed>");
            Output.WriteLine("            </object>");
            Output.WriteLine("          </td>" );
        }
    }
}
