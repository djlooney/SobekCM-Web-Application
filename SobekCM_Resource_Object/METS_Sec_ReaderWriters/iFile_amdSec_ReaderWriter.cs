﻿#region Using directives

using System.Collections.Generic;
using System.IO;
using System.Xml;
using SobekCM.Resource_Object.Divisions;

#endregion

namespace SobekCM.Resource_Object.METS_Sec_ReaderWriters
{
    /// <summary> Interface which must be implemented by  all amdSec reader/writers employed 
    /// by the METS  reader to write the administrative metadata portions tied to files under the main 
    /// digital resource </summary>
    public interface iFile_amdSec_ReaderWriter
    {
        /// <summary> Writes the amdSec for one file from the METS </summary>
        /// <param name="Output_Stream">Stream to which the formatted text is written </param>
        /// <param name="MetsFile"> File from the overall package with all the metadata to save</param>
        /// <param name="Options"> Dictionary of any options which this METS section writer may utilize</param>
        /// <returns>TRUE if successful, otherwise FALSE </returns>
        bool Write_amdSec(TextWriter Output_Stream, SobekCM_File_Info MetsFile, Dictionary<string, object> Options);

        /// <summary> Reads the amdSec at the current position in the XmlTextReader and associates it with 
        /// one file from the METS </summary>
        /// <param name="Input_XmlReader"> Open XmlReader from which to read the metadata </param>
        /// <param name="MetsFile"> File from the overall package into which to read the metadata</param>
        /// <param name="Options"> Dictionary of any options which this METS section writer may utilize</param>
        /// <returns> TRUE if successful, otherwise FALSE</returns>
        bool Read_amdSec(XmlReader Input_XmlReader, SobekCM_File_Info MetsFile, Dictionary<string, object> Options);

        /// <summary> Flag indicates if this active reader/writer will write a amdSec for this node </summary>
        /// <param name="MetsFile"> Files to check if a amdSec will be written </param>
        /// <param name="Options"> Dictionary of any options which this METS section writer may utilize</param>
        /// <returns> TRUE if the package has data to be written, otherwise fALSE </returns>
        bool Include_amdSec(SobekCM_File_Info MetsFile, Dictionary<string, object> Options);

        /// <summary> Flag indicates if this active reader/writer needs to append schema reference information
        /// to the METS XML header by analyzing the contents of the digital resource item </summary>
        /// <param name="METS_Item"> Package with all the metadata to save</param>
        /// <returns> TRUE if the schema should be attached, otherwise fALSE </returns>
        bool Schema_Reference_Required_Division(SobekCM_Item METS_Item);

        /// <summary> Returns the schema namespace (xmlns) information to be written in the XML/METS Header</summary>
        /// <param name="METS_Item"> Package with all the metadata to save</param>
        /// <returns> Formatted schema namespace info for the METS header</returns>
        string[] Schema_Namespace(SobekCM_Item METS_Item);

        /// <summary> Returns the schema location information to be written in the XML/METS Header</summary>
        /// <param name="METS_Item"> Package with all the metadata to save</param>
        /// <returns> Formatted schema location for the METS header</returns>
        string[] Schema_Location(SobekCM_Item METS_Item);
    }
}