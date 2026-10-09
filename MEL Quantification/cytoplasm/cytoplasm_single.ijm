
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//In this macro it is only one image is processed using a pre-computed segmentation
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var r=0.502, roiLabel=1, thBlue=100, minCellSize=30, maxCellSize=15000;

macro "QKI Action Tool 1 - Ca3fT0b09QT7b09KTdb09ITfb09c"{

	run("Close All");
	
	img=File.openDialog("Select ORIGINAL image");
	seg = File.openDialog("Select SEGMENTATION image");
	segDir = File.getParent(seg);
	OutDir = segDir+File.separator+"Quantification_results_cytoplasmic";
	File.makeDirectory(OutDir);
	resultsPath = OutDir+File.separator+"QuantificationResults.xlsx";

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

// Create ROI area:
setThreshold(roiLabel, roiLabel);
run("Convert to Mask");
run("Create Selection");
roiManager("Add");	// ROI0 --> ROI area
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
setBatchMode(false);
beforeTitles = getList("image.titles");
run("Colour Deconvolution", "vectors=[H&E DAB]");
wait(1000);
titles = getList("image.titles");
blueTitle = "";
brownTitle = "";
for (i=0; i<titles.length; i++) {
	if (indexOf(titles[i], "Colour_1")>=0 || indexOf(titles[i], "Colour 1")>=0 || indexOf(titles[i], "Colour1")>=0)
		blueTitle = titles[i];
	if (indexOf(titles[i], "Colour_3")>=0 || indexOf(titles[i], "Colour 3")>=0 || indexOf(titles[i], "Colour3")>=0)
		brownTitle = titles[i];
}
if (blueTitle=="" || brownTitle=="")
	exit("Cytoplasm analysis stopped: Colour Deconvolution did not create Colour1 and Colour3. Open the original RGB image and verify that the Colour Deconvolution command works from Fiji's Plugins menu. Windows currently open: "+getList("image.titles"));
for (i=0; i<titles.length; i++) {
	if (indexOf(titles[i], "Colour_2")>=0 || indexOf(titles[i], "Colour 2")>=0 || indexOf(titles[i], "Colour2")>=0) {
		selectWindow(titles[i]);
		close();
	}
}

// SEGMENT BLUE CELLS
selectWindow(blueTitle);
setBatchMode(false);
run("Threshold...");
setThreshold(0, thBlue);
waitForUser("Adjust the threshold for the purple nuclei in the 'blue' window, then click OK to continue.");
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
run("Dilate");	// dilate nuclei to avoid counting as cytoplasm the border of the nucleus
run("Create Selection");
run("Add to Manager");	// ROI1 --> Cell nuclei in ROI area
close();


// OBTAIN CYTOPLASM AREA IN ROI REGION

roiManager("deselect");
roiManager("Select", newArray(0,1));
roiManager("AND");
roiManager("Add");
roiManager("deselect");
roiManager("Select", newArray(0,2));
roiManager("XOR");
roiManager("Add");
roiManager("deselect");
roiManager("Select", newArray(1,2));
roiManager("Delete");
roiManager("deselect");	// ROI1 --> Cytoplasm area in ROI



// MEASURE DAB STAINING--

run("Clear Results");
selectWindow(brownTitle);
run("Select All");
setBatchMode(false);
run("Invert");
roiManager("Select", 1);
run("Set Measurements...", "area mean standard modal min redirect=None decimal=2");
roiManager("Measure");
Table.renameColumn("Area", "Area Cytoplasm");
Table.renameColumn("Mean", "Mean Intensity Cytoplasm");
IavgCyto=getResult("Mean",0);
Acyto=getResult("Area",0);
Acytom=Acyto*r*r;
r1=(parseInt(Acytom)/parseInt(Atm))*100;


selectWindow(MyTitle);
setBatchMode(false);
rename("orig");
roiManager("Show None");
roiManager("Select", 1);
roiManager("Set Color", "red");
roiManager("Set Line Width", 1);

run("Clear Results");
i=0;
setResult("Label", i, MyTitle); 	
setResult("ROI area (um2)",i,Atm);
setResult("Cytoplasm area in ROI (%)",i,r1);
setResult("Iavg cytoplasm",i,IavgCyto);

saveAs("Results", resultsPath);
if (!File.exists(resultsPath))
	exit("The results table could not be saved to: "+resultsPath);

run("Flatten");
wait(100);

saveAs("Jpeg", OutDir+File.separator+MyTitle_short+"_analyzed.jpg");
wait(100);

setTool("zoom");
showMessage("Done!\nResults saved to:\n"+resultsPath+"\n\nOverlay saved to:\n"+OutDir+File.separator+MyTitle_short+"_analyzed.jpg");
}

macro "QKI Action Tool 1 Options" {
     Dialog.create("TMA Parameters");
     
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
             
}
