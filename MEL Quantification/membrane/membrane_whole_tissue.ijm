
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//In this macro only one image is processed without using an external pre-segmented image
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var r=0.502, thBlue=140, prominence=5, thBrown=130, minMembSize=50;

macro "BRCA Action Tool 1 - Ca3fT0b09BT5b09RTab09CTfb09A"{

	run("Close All");

	
	img = File.openDialog("Select the image directory");
	
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
	
	print("Image Folder: " + img);

open(img);
MyTitle=getTitle();
output=getInfo("image.directory");
aa = split(MyTitle,".");
MyTitle_short = aa[0];

roiManager("Reset");
run("Clear Results");

setBatchMode(true);
run("Colors...", "foreground=white background=black selection=green");

// Get marker
par=File.getParent(output);
marker = substring(output, lengthOf(par)+1, lengthOf(output)-1);
//print(marker);

// 8-bit conversion
run("Duplicate...","title=label");
//rename("label");
run("Conversions...", " ");
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

// Keep seeds in the whole tissue

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

// Create tissue mask

selectWindow("brown");
roiManager("Select", 0);
run("Create Mask");
rename("tissueMask");

selectWindow("brown");
run("Select None");


// MARKER-CONTROLLED WATERSHED
run("Marker-controlled Watershed", "input=cellEdges marker=seeds mask=tissueMask binary calculate use");

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
roiManager("Delete");	// ROI1 --> Cell membrane in the whole tissue area


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
Amembm=Amemb*r*r;

selectWindow(MyTitle);
setBatchMode(false);
rename("orig");
roiManager("Show None");
roiManager("Select", 1);
roiManager("Set Color", "red");
roiManager("Set Line Width", 0.5);
showMessage("Done!");

/*

close(); 

// Write results:

i=nResults;
setResult("Label", i, MyTitle); 	
setResult("ROI area (um2)",i,Atm);
setResult("Nuclei area in ROI (%)",i,r1);
setResult("Iavg nuclei",i,IavgNucl);	
saveAs("Results", OutDir+File.separator+"QuantificationResults.xlsx");	

//selectWindow(MyTitle);
//close();


// Draw

selectWindow(MyTitle);
setBatchMode(false);
rename("orig");
roiManager("Show None");
roiManager("Select", 1);
roiManager("Set Color", "red");
roiManager("Set Line Width", 2);
run("Flatten");
wait(100);

saveAs("Jpeg", OutDir+File.separator+MyTitle_short+"_analyzed.jpg");
wait(100);



setTool("zoom");
selectWindow("orig");
close();
close("*");

*/
}



