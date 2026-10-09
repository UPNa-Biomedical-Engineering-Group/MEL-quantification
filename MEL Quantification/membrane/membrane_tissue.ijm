
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//In this macro it is processed a directory of imaged without using an external pre-segmented image
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var r=0.502, thBlue=140, prominence=5, thBrown=130, minMembSize=50;

macro "GLUT Action Tool 1 - Ca3fT0b09GT6b09LTab09UTfb09T"{

	run("Close All");
	
	imgDir = getDirectory("Select the image directory");

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
	
	//InDir=getDirectory("Choose a Directory");
	list=getFileList(imgDir);
	L=lengthOf(list);
	
	for (j=0; j<L; j++)
	{
		if(endsWith(list[j],"tif")){
			
			name=list[j];
			print(name);
			//setBatchMode(true);
			glut(imgDir,list[j]);
			setBatchMode(false);
			
		}
	}
	showMessage("Done!");
}


function glut(imgDir,name)
{

open(imgDir+File.separator+name);
rename(name);

roiManager("Reset");
run("Clear Results");
MyTitle=getTitle();
output=getInfo("image.directory");

aa = split(MyTitle,".");
MyTitle_short = aa[0];

setBatchMode(true);
run("Colors...", "foreground=white background=black selection=green");


// Get marker
par=File.getParent(output);
marker = substring(output, lengthOf(par)+1, lengthOf(output)-1);
//print(marker);

// Open automatic segmentation
run("Duplicate...");
run("8-bit");
run("Conversions...", "scale");

// Background remove
run("Subtract Background...", "rolling=50 light");
run("Median...", "radius=5");
run("Threshold...");
setAutoThreshold("Huang");
//run("Auto Threshold", "method=Triangle white");
run("Convert to Mask");
run("Create Selection");
run("Add to Manager");
roiManager("Select", 0); //ROI 0: Whole tissue


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
roiManager("Select", 1);
run("Clear Outside");
run("Select None");
selectWindow("blueSeeds");
roiManager("Select", 1);
run("Clear", "slice");
run("Select None");
imageCalculator("OR", "blueSeeds","brownSeeds");
selectWindow("blueSeeds");
rename("seeds");
selectWindow("brownSeeds");
close();
selectWindow("brownMask");
close();

// Keep seeds only in ROI:

selectWindow("seeds");
roiManager("Select", 0);
run("Clear Outside");
run("Select None");

// Create edges from GLUT1 staining:

selectWindow("brown");
run("Duplicate...", "title=cellEdges");
//run("Find Edges");
run("8-bit");
run("Invert");

// Create ROI mask:

selectWindow("brown");
roiManager("Select", 0);
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
roiManager("Select", 0);
run("Clear Outside");
run("Select None");
run("Analyze Particles...", "size="+minMembSize+"-Infinity pixel show=Masks in_situ");
run("Create Selection");
roiManager("Add");
roiManager("Select", 1);
roiManager("Delete");	// ROI1 --> Cell membrane in the whole tissue


// MEASURE DAB STAINING--

run("Clear Results");
selectWindow("brown");
run("Select All");
setBatchMode(true);
run("Invert");
roiManager("Select", 1);
run("Set Measurements...", "area mean standard modal min redirect=None decimal=2");
roiManager("Measure");
Table.renameColumn("Area", "Area Membrane");
Table.renameColumn("Mean", "Mean Intensity Membrane");
IavgMemb=getResult("Mean",0);
Amemb=getResult("Area",0);

selectWindow(MyTitle);
setBatchMode(false);
rename("orig");
roiManager("Show None");
roiManager("Select", 1);
roiManager("Set Color", "red");
roiManager("Set Line Width", 0.5);

waitForUser("Press OK to continue to the next image");

run("Close All");

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
setResult("Label", i, MyTitle); 	
setResult("Non-ROI area (um2)",i,Antm);
setResult("ROI area (um2)",i,Atm);
setResult("ROI area in tissue (%)",i,rROI);
setResult("Membrane area in ROI (%)",i,r1);
setResult("Iavg membrane",i,IavgMemb);
setResult("0 %",i,B0);
setResult("1+ %",i,B1);
setResult("2+ %",i,B2);
setResult("3+ %",i,B3);	
setResult("H-score",i,H);	
saveAs("Results", OutDir+File.separator+"QuantificationResults.xlsx");	


// Draw
selectWindow(MyTitle);
setBatchMode(false);
rename("orig");
roiManager("Show None");
roiManager("Select", 0);
roiManager("Set Color", "black");
roiManager("Set Line Width", 2);
run("Flatten");
wait(100);
selectWindow("orig-1");
roiManager("Show None");
roiManager("Select", 2);
roiManager("Set Color", "blue");
roiManager("Set Line Width", 1);
run("Flatten");
wait(100);
selectWindow("orig-2");
roiManager("Show None");
roiManager("Select", 3);
roiManager("Set Color", "green");
roiManager("Set Line Width", 1);
run("Flatten");
wait(100);
selectWindow("orig-3");
roiManager("Show None");
roiManager("Select", 4);
roiManager("Set Color", "yellow");
roiManager("Set Line Width", 1);
run("Flatten");
wait(100);
selectWindow("orig-4");
roiManager("Show None");
roiManager("Select", 5);
roiManager("Set Color", "red");
roiManager("Set Line Width", 1);
run("Flatten");
wait(100);

saveAs("Jpeg", OutDir+File.separator+MyTitle_short+"_analyzed.jpg");
wait(100);
close(); 

selectWindow("orig");
roiManager("Show None");
roiManager("Select", 1);
roiManager("Set Color", "red");
roiManager("Set Line Width", 1);
run("Flatten");
wait(100);
saveAs("Jpeg", OutDirSeg+File.separator+MyTitle_short+"_membraneSegmentation.jpg");
wait(100);
close(); 


setTool("zoom");
selectWindow("orig");
close();
selectWindow("orig-1");
close();
selectWindow("orig-2");
close();
selectWindow("orig-3");
close();
selectWindow("orig-4");
close();

*/
}



