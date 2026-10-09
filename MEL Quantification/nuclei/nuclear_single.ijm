
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//In this macro it is only one image is processed using a pre-computed segmentation
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var r=0.502, roiLabel=1, thBlue=190, minCellSize=30, maxCellSize=15000;

macro "BRCA Action Tool 1 - Ca3fT0b09BT5b09RTab09CTfb09A"{

	run("Close All");
	
	img=File.openDialog("Select ORIGINAL image");
	seg = File.openDialog("Select SEGMENTATION image");
    
    Dialog.create("Parameters for the analysis");
	Dialog.addNumber("Ratio micra/pixel", r);
	Dialog.addNumber("ROI label", roiLabel);
	Dialog.addNumber("Nuclei threshold", thBlue);
	Dialog.addNumber("Min nuclei size", minCellSize);
	Dialog.addNumber("Max nuclei size", maxCellSize);
	Dialog.show();
	
	r= Dialog.getNumber();
	roiLabel= Dialog.getNumber();
	thBlue= Dialog.getNumber();
	minCellSize= Dialog.getNumber();
	maxCellSize= Dialog.getNumber();

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

// Open automatic segmentation
open(seg);
rename("label");
run("Conversions...", " ");
run("8-bit");
run("Conversions...", "scale");
run("Subtract...", "value=1");

// Create ROI area:
selectWindow("label");
run("Select Label(s)", "label(s)="+roiLabel);
setThreshold(roiLabel, 255);
run("Convert to Mask");
setThreshold(129, 255);
run("Convert to Mask");
run("Create Selection");
roiManager("Add");	// ROI0 --> ROI area
close();
selectWindow("label");
close();

// MEASURE AREA OF ROI--
run("Set Measurements...", "area redirect=None decimal=2");
selectWindow(MyTitle);
run("Select All");
roiManager("Select", 0);
roiManager("Measure");
At=getResult("Area",0);
Atm=At*r*r;
run("Clear Results");


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

// SEGMENT BLUE CELLS
selectWindow("blue");
run("Threshold...");
setAutoThreshold("Default");
setAutoThreshold("Huang");
   //thBlue = 180;
setThreshold(0, thBlue);
//waitForUser("Adjust threshold for cell segmentation and press OK when ready");
setOption("BlackBackground", false);
run("Convert to Mask");
run("Fill Holes");
run("Median...", "radius=2");
run("Watershed");
roiManager("Select", 0);
setBackgroundColor(255, 255, 255);
run("Clear Outside");
run("Select All");
//run("Analyze Particles...", "size=10-15000 pixel show=Masks in_situ");
run("Analyze Particles...", "size="+minCellSize+"-"+maxCellSize+" pixel show=Masks in_situ");
run("Create Selection");
run("Add to Manager");	// ROI1 --> Cell nuclei in ROI area
close();



// MEASURE DAB STAINING--

run("Clear Results");
selectWindow("brown");
setBatchMode(false);
run("Invert");
roiManager("Select", 1);
run("Set Measurements...", "area mean standard modal min redirect=None decimal=2");
roiManager("Measure");
Table.renameColumn("Area", "Area Nuclei");
Table.renameColumn("Mean", "Mean Intensity Nuclei");
IavgNucl=getResult("Mean",0);
Anucl=getResult("Area",0);
Anuclm=Anucl*r*r;
r1=(parseInt(Anuclm)/parseInt(Atm))*100;

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

run("Clear Results");
if(File.exists(OutDir+File.separator+"QuantificationResults.xls"))
{	
	//if exists add and modify
	open(OutDir+File.separator+"QuantificationResults.xls");
	IJ.renameResults("Results");
}
i=nResults;
setResult("Label", i, MyTitle); 	
setResult("Non-ROI area (um2)",i,Antm);
setResult("ROI area (um2)",i,Atm);
setResult("ROI area in tissue (%)",i,rROI);
setResult("Nuclei area in ROI (%)",i,r1);
setResult("Iavg nuclei",i,IavgNucl);	
saveAs("Results", OutDir+File.separator+"QuantificationResults.xls");	

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



