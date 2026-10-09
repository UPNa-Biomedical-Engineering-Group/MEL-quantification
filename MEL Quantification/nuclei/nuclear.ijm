
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//In this macro it is preprocessed a directory of imaged using pre-computed segmentation
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


var r=0.502, roiLabel=1, thBlue=190, minCellSize=30, maxCellSize=15000;

macro "BRCA Action Tool 1 - Ca3fT0b09BT5b09RTab09CTfb09A"{

	run("Close All");

	
	
	imgDir = getDirectory("Select the image directory");
	imgDir = replace(imgDir, "\\", "/"); 
	segDir = getDirectory("Select the segmentation directory");
	segDir = replace(segDir, "\\", "/"); 
    
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
	
	print("Image Folder: " + imgDir);
	print("Segmentation Folder: " + segDir);
	
	//InDir=getDirectory("Choose a Directory");
	list=getFileList(imgDir);
	L=lengthOf(list);
	
	for (j=0; j<L; j++)
	{
		if(endsWith(list[j],"tif")){
			
			name=list[j];
			print(name);
			//setBatchMode(true);
			brca(imgDir,list[j]);
			setBatchMode(false);
			
		}
	}
	showMessage("Done!");
	

}


function brca(imgDir,name)
{

open(imgDir+File.separator+name);
rename(name);

roiManager("Reset");
run("Clear Results");
MyTitle=getTitle();
output=getInfo("image.directory");

OutDir = segDir+File.separator+"Quantification_results";
File.makeDirectory(OutDir);

aa = split(MyTitle,".");
MyTitle_short = aa[0];

setBatchMode(true);
run("Colors...", "foreground=white background=black selection=green");

// Get marker
par=File.getParent(output);
marker = substring(output, lengthOf(par)+1, lengthOf(output)-1);
//print(marker);

// Open automatic segmentation
open(segDir+File.separator+MyTitle);

// Create ROI area:
setThreshold(roiLabel, roiLabel);
run("Convert to Mask");
run("Create Selection");
roiManager("Add");	// ROI==0 --> ROI area
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
setBatchMode(true);
run("Invert");
roiManager("Select", 1);
run("Set Measurements...", "area mean standard modal min redirect=None decimal=2");
roiManager("Measure");
//Table.renameColumn("Area", "Area Nuclei");
//Table.renameColumn("Mean", "Mean Intensity Nuclei");
IavgNucl=getResult("Mean",0);
Anucl=getResult("Area",0);
Anuclm=Anucl*r*r;
r1=(parseInt(Anuclm)/parseInt(Atm))*100;


close(); 

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

}



