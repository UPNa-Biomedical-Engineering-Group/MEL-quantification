
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//In this macro only one image is processed using a manual ROI chosen by the user
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var r=0.502, thBlue=140, prominence=5, thBrown=130, minMembSize=50;

macro "GLUT Action Tool 1 - Ca3fT0b09GT6b09LTab09UTfb09T"{

	run("Close All");
	
	img=File.openDialog("Select ORIGINAL image");
    

	Dialog.create("Parameters for the analysis");
    
	Dialog.addNumber("Ratio micra/pixel", r);     
	Dialog.addNumber("Nuclei threshold", thBlue);
	Dialog.addNumber("Prominence for nuclei detection", prominence);
	Dialog.addNumber("GLUT threshold", thBrown);
	Dialog.addNumber("Min membrane size (px)", minMembSize);	
	Dialog.show();
	
	r= Dialog.getNumber();
	thBlue= Dialog.getNumber();
	prominence= Dialog.getNumber();	
	thBrown= Dialog.getNumber();	
	minMembSize= Dialog.getNumber();	

open(img);
MyTitle=getTitle();
aa = split(MyTitle,".");
MyTitle_short = aa[0];

roiManager("Reset");
run("Clear Results");
MyTitle=getTitle();
output=getInfo("image.directory");

//OutDir = segDir+File.separator+"Quantification_results";
//File.makeDirectory(OutDir);
//OutDirSeg = segDir+File.separator+"Membrane_segmentations";

run("ROI Manager...");

setTool("freehand");
while (true) {
    waitForUser("Please draw a region to add. Press OK when ready. To stop, click Cancel.");

    // Add ROI to ROI Manager
    roiManager("Add");
    print("ROI successfully added!");
	
	roiManager("Show All");
	
    // Possibility to add another manual ROI
    Dialog.create("Add another ROI?");
    Dialog.addMessage("Do you want to add another ROI?");
    Dialog.addChoice("Response", newArray("Yes", "No"), "Yes");
    Dialog.show();

    response = Dialog.getChoice();

    
    if (response == "No") {
        break;
    }
}

// Merging all ROI together
roiManager("Combine");
roiManager("Add"); // Add ROI to ROI Manager
print("All ROIs have been combined into one.");
count = roiManager("count");
print(count);
for (i = count-2; i >= 0; i--) {
	roiManager("Select", i);
	roiManager("delete");
}

setBatchMode(true); //set to true, once the tests are finished
run("Colors...", "foreground=white background=black selection=green");

// Get marker
par=File.getParent(output);
marker = substring(output, lengthOf(par)+1, lengthOf(output)-1);
//print(marker);

selectWindow(MyTitle);
run("Select None"); // deselect ROI temporarily
run("Duplicate...","title=label");
//rename("label");

run("Conversions...", " ");
run("8-bit");
run("Conversions...", "scale");
roiManager("Select", roiManager("Count") - 1); //

// Background remove
roiManager("select", 0);
run("Clear Outside");
run("Subtract Background...", "rolling=50 light");
run("Median...", "radius=5");
run("Threshold...");
setAutoThreshold("Huang");
//run("Auto Threshold", "method=Triangle white");
run("Convert to Mask");
run("Create Selection");
run("Add to Manager");
//roiManager("Select", 1); //ROI 1: whole tissue


//Intersection phase
roiManager("Select",newArray(0,1));
roiManager("and");
run("Create Selection");
roiManager("add"); // --> ROI2 tissue in ROI


// SEPARATE STAINING CHANNELS--

selectWindow(MyTitle);
roiManager("Show None");
run("Select All");
showStatus("Deconvolving channels...");
run("Colour Deconvolution", "vectors=[H&E DAB] hide");
selectWindow(MyTitle+"-(Colour_2)");
close();
selectWindow(MyTitle+"-(Colour_1)");
rename("blue");
selectWindow(MyTitle+"-(Colour_3)");
rename("brown");

//--SEGMENT CELLS

// Segment nuclei from hematoxylin:

selectWindow("blue");
run("Mean...", "radius=2");
run("Enhance Contrast", "saturated=0.35");
  // prominence=5
run("Find Maxima...", "prominence="+prominence+" light output=[Single Points]");
rename("blueSeeds");


selectWindow("blue");
   //thBlue = 100;
setThreshold(0, thBlue);
setOption("BlackBackground", false);
run("Convert to Mask");
run("Fill Holes");
run("Median...", "radius=1");
run("Create Selection");
selectWindow("blueSeeds");
run("Restore Selection");
setBackgroundColor(255,255,255);
run("Clear Outside");

// Segment highly stained GLUT1 areas:

selectWindow("brown");
run("Duplicate...", "title=brownMask");
  // thBrown=130;
setThreshold(0, thBrown);
setOption("BlackBackground", false);
run("Convert to Mask");
run("Open");
run("Median...", "radius=1");
run("Analyze Particles...", "size=1000-Inf pixel show=Masks in_situ");
run("Duplicate...", "title=brownDM");
selectWindow("brownMask");
run("Fill Holes");

// Detect seeds in highly stained GLUT1 areas:

selectWindow("brownDM");
run("Distance Map");
run("Find Maxima...", "prominence=0.1 output=[Single Points]");
rename("brownSeeds");
selectWindow("brownDM");
close();

// Combine blue seeds and brown seeds:

selectWindow("brownMask");
run("Create Selection");
type=selectionType();
if(type==-1) {
	makeRectangle(1,1,1,1);
}
roiManager("Add");
selectWindow("brownSeeds");
roiManager("Select", 3);
run("Clear Outside");
run("Select None");
selectWindow("blueSeeds");
roiManager("Select", 3);
run("Clear", "slice");
run("Select None");
imageCalculator("OR", "blueSeeds","brownSeeds");
selectWindow("blueSeeds");
rename("seeds");
selectWindow("brownSeeds");
close();
selectWindow("brownMask");
close();

// Keep seeds only in tissue in ROI selected:

selectWindow("seeds");
roiManager("Select", 2);
run("Clear Outside");
run("Select None");

// Create edges from GLUT1 staining:

selectWindow("brown");
run("Duplicate...", "title=cellEdges");
//run("Find Edges");
run("8-bit");
run("Invert");

// Create tissue selected mask:

selectWindow("brown");
roiManager("Select", 2);
run("Create Mask");
rename("ROIMask");

selectWindow("brown");
run("Select None");


// MARKER-CONTROLLED WATERSHED
run("Marker-controlled Watershed", "input=cellEdges marker=seeds mask=ROIMask binary calculate use");

selectWindow("cellEdges-watershed");
run("8-bit");
setThreshold(1, 255);
setOption("BlackBackground", false);
run("Convert to Mask");
run("Erode");
run("Invert");
roiManager("Select", 2);
run("Clear Outside");
run("Select None");
run("Analyze Particles...", "size="+minMembSize+"-Infinity pixel show=Masks in_situ");
run("Create Selection");
roiManager("Add");
roiManager("Select", 3);
roiManager("Delete");	// ROI3 --> Cell membrane in tissue selected area
close();
// MEASURE DAB STAINING--

run("Clear Results");
selectWindow("brown");
run("Select All");
setBatchMode(true);
run("Invert");
roiManager("Select", 3);
run("Set Measurements...", "area mean standard modal min redirect=None decimal=2");
roiManager("Measure");
Table.renameColumn("Area", "Area Membrane");
Table.renameColumn("Mean", "Mean Intensity Membrane");
IavgMemb=getResult("Mean",0);
//print(IavgMemb); debugging
Amemb=getResult("Area",0);
Amembm=Amemb*r*r;

selectWindow(MyTitle);
setBatchMode(false);
rename("orig");
roiManager("Show None");
roiManager("Select", 3);
roiManager("Set Color", "red");
roiManager("Set Line Width", 0.5)
//run("Flatten");
showMessage("Done!S");
//close();

/*

// Write results:

run("Clear Results");
if(File.exists(OutDir+File.separator+"QuantificationResults.xlsx"))
{	
	//if exists add and modify
	open(OutDir+File.separator+"QuantificationResults.xlsx");
	IJ.renameResults("Results");
	
}
i=nResults;

print(i);
setResult("Label", i, MyTitle); 	
setResult("Non-ROI area (um2)",i,Antm);
setResult("ROI area (um2)",i,Atm);
setResult("ROI area in tissue (%)",i,rROI);
setResult("Membrane area in ROI (%)",i,r1);
setResult("Iavg membrane",i,IavgMemb);

saveAs("Results", OutDir+File.separator+"QuantificationResults.xlsx");	

// Draw

selectWindow(MyTitle);
setBatchMode(false);
rename("orig");
roiManager("Show None");
roiManager("Select", 1);
roiManager("Set Color", "red");
roiManager("Set Line Width", 1);
run("Flatten");
wait(100);
saveAs("Jpeg", OutDirSeg+File.separator+MyTitle_short+"_membraneSegmentation.jpg");
wait(100);



setTool("zoom");
selectWindow("orig");
close();

close("*");
*/
}



