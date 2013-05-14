//Update the division types when a division checkbox is checked/unchecked
function UpdateDivDropdown(CheckBoxID, MaxPageCount)
{
	//get the list of all the thumbnail spans on the page
	var spanArrayObjects = new Array();

	if(window.spanArrayGlobal!= null)
	 { 
	
	  spanArrayObjects = window.spanArrayGlobal;
	 
	 }
	else
	{
	  for(var j=0;j<MaxPageCount;j++)
	  {
	     spanArrayObjects[j]='span'+j;
	  }
	 
	}
	
	 var spanArray=new Array();

	 //get the spanIDs from the array of span objects 
	 for(var k=0;k<spanArrayObjects.length;k++)
	 {
	 //var pageIndex = spanID.split('span')[1];
	   spanArray[k]=spanArrayObjects[k].split('span')[1];
	 }
     

	if(document.getElementById('selectDivType'+(CheckBoxID.split('newdiv')[1])).disabled==true)
	{
	  document.getElementById('selectDivType'+(CheckBoxID.split('newdiv')[1])).disabled=false;
	}
	else
	{
	 document.getElementById('selectDivType'+(CheckBoxID.split('newdiv')[1])).disabled=true;
	 
	 //update the subsequent divs
	 var index=CheckBoxID.split('newdiv')[1];
	 var i = spanArray.indexOf(index);

	  if(i==0)
	  {
		document.getElementById('selectDivType'+index).value='Main';
		
//		while(document.getElementById('selectDivType'+spanArray[i]).disabled==true)
       while(i<spanArray.length)
		{
          i++;
		  if(document.getElementById('selectDivType'+spanArray[i]))
			{
			  document.getElementById('selectDivType'+spanArray[i]).value = 'Main';
			  document.getElementById('newDivType'+spanArray[i]).checked=false;
              document.getElementById('newDivType'+spanArray[i]).disabled=true;

			}
		
		}
	
	  }
	  else
	  {
		var j=i-1;
		var valToSet = 'Main';

		while(!(document.getElementById('selectDivType'+spanArray[j])))
		{
		 j--;
		}

		valToSet = document.getElementById('selectDivType'+spanArray[j]).value;

		var k=i;
		  
		//set the page division type of all pages till the start of the next div
		while(document.getElementById('selectDivType'+spanArray[k]).disabled==true && k<spanArray.length)
		{
		  if(document.getElementById('selectDivType'+spanArray[k]))
			document.getElementById('selectDivType'+spanArray[k]).value = valToSet;
		  k++;
		}
		
	  }
	  
	}

}

//Change all subsequent division types when one div type is changed
function DivisionTypeChanged(selectID,MaxPageCount)
{
   //get the list of all the thumbnail spans on the page
	var spanArrayObjects = new Array();

	if(window.spanArrayGlobal!= null)
	 { 
	  spanArrayObjects = window.spanArrayGlobal;
	 }
	else
	{
	  for(var j=0;j<MaxPageCount;j++)
	  {
	     spanArrayObjects[j]='span'+j;
	  }
	 
	}
	
	 var spanArray=new Array();

	 //get the spanIDs from the array of span objects 
	 for(var k=0;k<spanArrayObjects.length;k++)
	 {
	 //var pageIndex = spanID.split('span')[1];
	   spanArray[k]=spanArrayObjects[k].split('span')[1];
	 }

	var currID = selectID.split('selectDivType')[1];
   // var i=parseInt(currID)+1;
    var i = spanArray.indexOf(currID)+1;
	var currVal = document.getElementById(selectID).value;

	while(document.getElementById('selectDivType'+spanArray[i]).disabled==true)
	{
	  //alert(i);
	  if(document.getElementById('selectDivType'+ spanArray[i]))
	    document.getElementById('selectDivType'+ spanArray[i]).value = currVal;
	  i++;
	}
}




//Autonumber subsequent textboxes on changing one textbox value
function PaginationTextChanged(textboxID,mode,MaxPageCount)
{

    //get the list of all the thumbnail spans on the page
	var spanArrayObjects = new Array();

	if(window.spanArrayGlobal!= null)
	 { 
	  spanArrayObjects = window.spanArrayGlobal;
	 }
	else
	{
	  for(var j=0;j<MaxPageCount;j++)
	  {
	     spanArrayObjects[j]='span'+j;
	  }
	 
	}
	
	 var spanArray=new Array();

	 //get the spanIDs from the array of span objects 
	 for(var k=0;k<spanArrayObjects.length;k++)
	 {
	 //var pageIndex = spanID.split('span')[1];
	   spanArray[k]=spanArrayObjects[k].split('span')[1];
	 }

  //Mode '0': Autonumber all the thumbnail page names till the end
  if(mode=='0')
  {
    
    var matches = document.getElementById(textboxID).value.match(/\d+/g);
    if (matches != null) 
    {
       // the id attribute contains a digit
       var len=matches.length;
       var number = matches[len-1];
	   var nonNumber='';
	   var val=document.getElementById(textboxID).value;
      // alert(number);
       
	   //if the number is at the end of the string, with a space before
	   if(val.indexOf(number.toString())==(val.length-number.toString().length) && val.substr(val.indexOf(number.toString())-1,1)==' ')
       {
      //      for(var i=parseInt(textboxID.split('textbox')[1])+1;i<=MaxPageCount;i++)
			for(var i=spanArray.indexOf(textboxID.split('textbox')[1])+1;i<=MaxPageCount;i++)
			{
			  number++;
			 //alert(i);
			  if(document.getElementById('textbox'+spanArray[i]))
			  {
			    document.getElementById('textbox'+spanArray[i]).value = 
				 document.getElementById(textboxID).value.substr(0,(document.getElementById(textboxID).value.length-number.toString.length)-1)+' '+number.toString();
			  }//end if
			}//end for
           
       }//end if
    }//end if


  }//end if
 
 //Mode '1': Autonumber all the thumbnail pages till the start of the next div
   if(mode=='1')
  {
    
    var matches = document.getElementById(textboxID).value.match(/\d+/g);
    if (matches != null) 
    {
       // the id attribute contains a digit
       var len=matches.length;
       var number = matches[len-1];
	   var nonNumber='';
	   var val=document.getElementById(textboxID).value;
      // alert(number);
       
	   //if the number is at the end of the string, with a space before
	   if(val.indexOf(number.toString())==(val.length-number.toString().length) && val.substr(val.indexOf(number.toString())-1,1)==' ')
       {
      //      for(var i=parseInt(textboxID.split('textbox')[1])+1;i<=MaxPageCount;i++)
			var i=spanArray.indexOf(textboxID.split('textbox')[1])+1;
			while(document.getElementById('selectDivType'+spanArray[i]).disabled==true && i<MaxPageCount)
			{
			  number++;
			 //alert(i);
			  if(document.getElementById('textbox'+spanArray[i]))
			  {
			    document.getElementById('textbox'+spanArray[i]).value = 
				 document.getElementById(textboxID).value.substr(0,(document.getElementById(textboxID).value.length-number.toString.length)-1)+' '+number.toString();
			  }//end if
			  i++;
			}//end while
           
       }//end if
    }//end if


  }//end if
  
  
}//end function


//Assign the 'main thumbnail' to the selected thumbnail span
function PickMainThumbnail(spanID)
{
	var pageIndex = spanID.split('span')[1];
	var hiddenfield = document.getElementById('Main_Thumbnail_Index');
	var hidden_request = document.getElementById('QC_behaviors_request');
	 hidden_request.value="";
	 
	//Cursor currently set to the "Pick Main Thumbnail" cursor?
	if($('body').css('cursor').indexOf("url")>-1)
	{
	  var spanImageID='spanImg'+pageIndex;
	  //is there a previously selected Main Thumbnail?
	  if(hiddenfield.length>0 && document.getElementById('spanImg'+hiddenfield).className=="pickMainThumbnailIconSelected")
	  {
	    //First unmark the existing one as the main thumbnail
		document.getElementById('spanImg'+hiddenfield).className='pickMainThumbnailIcon';
		
		//Then set the hidden request value to 'unpick'
		hidden_request.value='unpick_main_thumbnail';
							
	  }
	  
	  //User selects a main thumbnail
	  if(document.getElementById(spanImageID).className=="pickMainThumbnailIcon")
	  {
		document.getElementById(spanImageID).className="pickMainThumbnailIconSelected";
		//Change the cursor back to default
		$('body').addClass('qcResetMouseCursorToDefault');
					 //Set the hidden field value with the main thumbnail
			 
			 hiddenfield.value = pageIndex;
	         hidden_request.value = "pick_main_thumbnail";

		
	  }
	  else
	  {
	  //Confirm if the user wants to unmark this as a thumbnail image
	  
		//   var t=confirm('Are you sure you want to remove this as the main thumbnail?');   
		 // if(t==true)
		  {
			  document.getElementById(spanImageID).className = "pickMainThumbnailIcon";
			 //Change the cursor back to default
			 $('body').addClass('qcResetMouseCursorToDefault');
			 
			 //Set the hidden field value with the main thumbnail
			 
			 hiddenfield.value = pageIndex;
	         hidden_request.value = 'unpick_main_thumbnail';  
			 
			 			 
		  }
	  }
	  // Submit this
	  document.itemNavForm.submit();
	  return false;
	  
	}

}

//Show the QC Icon bar below the thumbnail on mouseover
function showQcPageIcons(spanID)
{
  //alert(spanID);
  var pageIndex = spanID.split('span')[1];
  var qcPageIconsSpan = 'qcPageOptions'+pageIndex;
  document.getElementById(qcPageIconsSpan).className = "qcPageOptionsSpanHover";
}

//Hide the QC Icon bar below the thumbnail on mouseout
function hideQcPageIcons(spanID)
{
  var pageIndex = spanID.split('span')[1];
  var qcPageIconsSpan = 'qcPageOptions'+pageIndex;
  document.getElementById(qcPageIconsSpan).className = "qcPageOptionsSpan";
}

//Show the error icon on mouseover
function showErrorIcon(spanID)
{
  var pageIndex = spanID.split('span')[1];
  var qcErrorIconSpan = 'error'+pageIndex;
  document.getElementById(qcErrorIconSpan).className = "errorIconSpanHover";
}

//Hide the error icon on mouseout
function hideErrorIcon(spanID)
{
  var pageIndex = spanID.split('span')[1];
  var qcErrorIconSpan = 'error'+pageIndex;
  document.getElementById(qcErrorIconSpan).className = "errorIconSpan";

}

//Change the cursor to the custom cursor
function ChangeMouseCursor()
{

//Remove the default cursor style class first before setting the custom one, 
//otherwise it will override the custom cursor class
$('body').removeClass('qcResetMouseCursorToDefault');

//Set the custom cursor
$('body').addClass('qcPickMainThumbnailCursor');

}

function ResetCursorToDefault()
{
$('body').addClass('qcResetMouseCursorToDefault');
}

//Make the thumbnails sortable
function MakeSortable1()
{

 var startPosition;
 var newPosition; 
 var oldArray;
 var newArray;

$("#allThumbnailsOuterDiv").sortable({containment: 'parent',
											start: function(event, ui)
                                             {
											   startPosition=$(ui.item).index()+1;
											 },
                                             stop: function(event, ui)
									         {
												   newPosition = $(ui.item).index()+1;
																								  
												
												//get the list of all the thumbnail spans on the page
												 var spanArrayObjects = $(ui.item).parent().children();
												 
												 var spanArray=new Array();
												
												 //get the spanIDs from the array of span objects 
												 for(var i=0;i<spanArrayObjects.length;i++)
												 {
												   spanArray[i]=spanArrayObjects[i].id;
												 }
																								
												//save the array of spans in the UI as a global window variable
												 window.spanArrayGlobal = spanArray;
												
												//if position has been changed, update the page division correspondingly
												  if(startPosition != newPosition)
												  {
												    alert('Div moved');
													 //get the spanID of the current span being dragged & dropped
													 var spanID=$(ui.item).attr('id');
													 var pageIndex = spanID.split('span')[1];
													
													
												   //get the current index of the moved span in the UI spanArray
													var indexSpanArray = spanArray.indexOf(spanID);   												
													   
													var nextPosition=spanArray[indexSpanArray+1].split('span')[1];
																										
													var indexTemp = spanArray[startPosition].split('span')[1];
													
													//If the span being moved is the start of a new Div 															
													if(document.getElementById('newDivType'+indexTemp).checked==false)
													{
													   document.getElementById('newDivType'+(spanArray[startPosition].split('span')[1])).checked=true;
													   document.getElementById('selectDivType'+(spanArray[startPosition].split('span')[1])).disabled=false;
													   //alert('still in the right place');
													   document.getElementById('selectDivType'+(spanArray[startPosition].split('span')[1])).value=document.getElementById('selectDivType'+pageIndex).value;
														  														  														  
													}
													//else do nothing
													
													//CASE 1: 
													//If the new position is position 0: Theoretically this cannot happen since the sortable list container boundary
													//is set to make this impossible, but just in case...
													if(indexSpanArray==0)
													{
							                          //Make the moved div the start of a new div
													  document.getElementById('newDivType'+(spanArray[newPosition-1].split('span')[1])).checked=true;
													  //Enable the moved div's DivType dropdown
													  document.getElementById('selectDivType'+(spanArray[newPosition-1].split('span')[1])).disabled=false;
													  //Set the moved div's DivType value to that of the one it is replacing
													  document.getElementById('selectDivType'+(spanArray[newPosition-1].split('span')[1])).value = document.getElementById('selectDivType'+(spanArray[newPosition].split('span')[1])).value;
													  
													  //Unmark the replaced div's NewDiv Checkbox (and disable the dropdown)
													  document.getElementById('newDivType'+(spanArray[newPosition].split('span')[1])).checked=false;
													  document.getElementById('selectDivType'+(spanArray[newPosition].split('span')[1])).disabled=true;
	
													}
													
													//else
													//CASE 2: Span moved to any location other than 0
													
													//else check if the span being replaced is not the start of a new div
													else if(indexSpanArray>0)
													{
                                                      //Moved span's DivType = preceding Div's Div type
													  document.getElementById('selectDivType'+(spanArray[newPosition-1].split('span')[1])).value = document.getElementById('selectDivType'+(spanArray[newPosition-2].split('span')[1])).value;
													  //Moved span != start of a new Division
													  document.getElementById('newDivType'+(spanArray[newPosition-1].split('span')[1])).checked=false;
													  document.getElementById('selectDivType'+(spanArray[newPosition-1].split('span')[1])).disabled=true;
													  
													}//end else if
											 
													 
												 }//end if(startPosition!=newPosition)
											  

											 },placeholder: "ui-state-highlight"});
									 
$("#allThumbnailsOuterDiv").disableSelection();


                                                 															 

}



//Cancel function: set the hidden field(s) accordingly
function behaviors_cancel_form() 
{
	var hiddenfield = document.getElementById('QC_behaviors_request');
	hiddenfield.value = 'cancel';

	
    // Submit this
    document.itemNavForm.submit();
    return false;
}


//Save function: set the hidden field(s) accordingly
function behaviors_save_form() 
{
    var hiddenfield = document.getElementById('QC_behaviors_request');
	hiddenfield.value = 'save';
	
    // Submit this
    document.itemNavForm.submit();
    return false;

}


//Turn On/Off the autosave option
function changeAutoSaveOption()
{
   var linkID = document.getElementById('autosaveLink');
   var hiddenfield = document.getElementById('Autosave_Option');
   var hiddenfield_behavior = document.getElementById('QC_behaviors_request');
    hiddenfield_behavior.value = 'save';

	if(linkID.innerHTML=='Turn Off Autosave')
	{
	  linkID.innerHTML = 'Turn On Autosave';
	  hiddenfield.value = 'false';
//	  alert(hiddenfield.value);
	}
	else
	{
	 linkID.innerHTML = 'Turn Off Autosave';
	 hiddenfield.value = 'true';
	}
    
	//Submit the form
	document.itemNavForm.submit();
    return false;
}

//Autosave the QC form. Called from the main form every three minutes
function qc_auto_save()
{

	jQuery('form').each(function() {
	    var hiddenfield = document.getElementById('QC_behaviors_request');
		hiddenfield.value = 'save';

		var thisURL =window.location.href.toString();
        // For each form on the page, pass the form data via an ajax POST to
        // the save action
        $.ajax({
					url: thisURL,
					data: 'autosave=true&'+jQuery(this).serialize(),
					type: 'POST',
					async: true,
					success: function(data)
					{
						  
							alert('Autosaving...');
							return false;
		 
					}// end successful POST function
				}); // end jQuery ajax call
    }); // end setting up the autosave on every form on the page
}
