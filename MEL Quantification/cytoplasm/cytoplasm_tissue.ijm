
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//In this macro it is processed a directory of imaged without using an external pre-segmented image
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var r=0.502, thBlue=100, minCellSize=30, maxCellSize=15000;

macro "QKI Action Tool 1 - Ca3fT0b09QT7b09KTdb09ITfb09c"{

	run("Close All");
	
	imgDir = getDirectory("Select the image directory");
	
	Dialog.create("Parameters for the analysis");
     
	Dialog.addNumber("Ratio micra/pixel", r);    
	Dialog.addNumber("Nuclei threshold", thBlue);
	Dialog.addNumber("Min nuclei size", minCellSize);
	Dialog.addNumber("Max nuclei size", maxCellSize);
	Dialog.show();
	r= Dialog.getNumber();
	thBlue= Dialog.getNumber();
	minCellSize= Dialog.getNumber();
	maxCellSize= Dialog.getNumber();
	
	//InDir=getDirectory("Choose a Directory");
	list=getFileList(imgDir);
	L=lengthOf(list);
	
	for (j=0; j<L; j++)
	{
		if(endsWith(list[j],"tif")){
			
			name=list[j];
			print(name);
			
			qki(imgDir,list[j]);
			setBatchMode(false);
			
			
		}
	}
	showMessage("Done!");
}


function qki(imgDir,name)
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
titles = getList("image.titles");
blueTitle = "";
brownTitle = "";
for (i=0; i<titles.length; i++) {
	if (indexOf(titles[i], "Colour_2")>=0 || indexOf(titles[i], "Colour 2")>=0 || indexOf(titles[i], "Colour2")>=0) {
		selectWindow(titles[i]);
		close();
	}
}
titles = getList("image.titles");
for (i=0; i<titles.length; i++) {
	if (indexOf(titles[i], "Colour_1")>=0 || indexOf(titles[i], "Colour 1")>=0 || indexOf(titles[i], "Colour1")>=0)
		blueTitle = titles[i];
	if (indexOf(titles[i], "Colour_3")>=0 || indexOf(titles[i], "Colour 3")>=0 || indexOf(titles[i], "Colour3")>=0)
		brownTitle = titles[i];
}
if (blueTitle=="" || brownTitle=="")
	exit("Colour Deconvolution did not create the expected channels. Available windows: "+getList("image.titles"));

// SEGMENT BLUE CELLS
selectWindow(blueTitle);
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
run("Dilate");	// dilate nuclei to avoid counting as cytoplasm the border of the nucleus
run("Create Selection");
run("Add to Manager");	// ROI1 --> Cell nuclei in the whole tissue
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
roiManager("deselect");	// ROI1 --> Cytoplasm area in the whole tissue



// MEASURE DAB STAINING--

run("Clear Results");
selectWindow(brownTitle);
run("Select All");
setBatchMode(true);
run("Invert");
roiManager("Select", 1);
run("Set Measurements...", "area mean standard modal min redirect=None decimal=2");
roiManager("Measure");
Table.renameColumn("Area", "Area Cytoplasm");
Table.renameColumn("Mean", "Mean Intensity Cytoplasm");
IavgCyto=getResult("Mean",0);
Acyto=getResult("Area",0);

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
setResult("Cytoplasm area in ROI (%)",i,r1);
setResult("Iavg cytoplasm",i,IavgCyto);
setResult("0 %",i,B0);
setResult("1+ %",i,B1);
setResult("2+ %",i,B2);
setResult("3+ %",i,B3);	
setResult("H-score",i,H);	
saveAs("Results", OutDir+File.separator+"QuantificationResults.xlsx");	
close();
}
/*
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

macro "QKI Action Tool 1 Options" {
     Dialog.create("TMA Parameters");
     
     Dialog.addNumber("Ratio micra/pixel", r);   
     Dialog.addNumber("Nuclei threshold", thBlue);
     Dialog.addNumber("Min nuclei size", minCellSize);
     Dialog.addNumber("Max nuclei size", maxCellSize);
     Dialog.show();
     r= Dialog.getNumber();
     thBlue= Dialog.getNumber();
     minCellSize= Dialog.getNumber();
     maxCellSize= Dialog.getNumber();
             
}

