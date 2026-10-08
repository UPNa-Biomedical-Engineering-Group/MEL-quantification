
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//In this macro it is preprocessed a directory of imaged using pre-computed segmentation
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var r=0.502, labT=1, thBlue=100, minCellSize=30, maxCellSize=15000;

macro "QKI Action Tool 1 - Ca3fT0b09QT7b09KTdb09ITfb09c"{

	run("Close All");
	
	imgDir = getDirectory("Select the image directory");
	imgDir = replace(imgDir, "\\", "/"); 
	segDir = getDirectory("Select the segmentation directory");
	segDir = replace(segDir, "\\", "/"); 

	Dialog.create("Parameters for the analysis");
	Dialog.addNumber("Ratio micra/pixel", r);
	Dialog.addNumber("Tumor label", labT);     
	Dialog.addNumber("Nuclei threshold", thBlue);
	Dialog.addNumber("Min nuclei size", minCellSize);
	Dialog.addNumber("Max nuclei size", maxCellSize);
	
	Dialog.show();
	
	r= Dialog.getNumber();
	labT= Dialog.getNumber();
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

OutDir = segDir+File.separator+"Quantification_results_cytoplasmic";
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
rename("label");
run("Conversions...", " ");
run("8-bit");
run("Conversions...", "scale");
run("Subtract...", "value=1");

// Create tumour area:
selectWindow("label");
run("Select Label(s)", "label(s)="+labT);
setThreshold(labT, 255);
run("Convert to Mask");
setThreshold(129, 255);
run("Convert to Mask");
run("Create Selection");
roiManager("Add");	// ROI0 --> Tumour area
close();
selectWindow("label");
close();

// MEASURE AREA OF TUMOUR--
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
run("Dilate");	// dilate nuclei to avoid counting as cytoplasm the border of the nucleus
run("Create Selection");
run("Add to Manager");	// ROI1 --> Cell nuclei in tumor area
close();


// OBTAIN CYTOPLASM AREA IN TUMOUR REGION

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
roiManager("deselect");	// ROI1 --> Cytoplasm area in tumour



// MEASURE DAB STAINING--

run("Clear Results");
selectWindow("brown");
run("Select All");
setBatchMode(true);
run("Invert");
roiManager("Select", 1);
run("Set Measurements...", "area mean standard modal min redirect=None decimal=2");
roiManager("Measure");
IavgCyto=getResult("Mean",0);
Acyto=getResult("Area",0);
//Table.renameColumn("Area", "Area Cytoplasm");
//Table.renameColumn("Mean", "Mean Intensity Cytoplasm");
Acytom=Acyto*r*r;
r1=(parseInt(Acytom)/parseInt(Atm))*100;

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
setResult("Tumour area (um2)",i,Atm);	
setResult("Cytoplasm area in tumour (%)",i,r1);
setResult("Iavg cytoplasm",i,IavgCyto);

saveAs("Results", OutDir+File.separator+"QuantificationResults.xls");	


// Draw

selectWindow(MyTitle);
setBatchMode(false);
rename("orig");
roiManager("Show None");
roiManager("Select",1);
roiManager("Set Color", "red");
roiManager("Set Line Width", 1);
run("Flatten");
wait(100);

saveAs("Jpeg", OutDir+File.separator+MyTitle_short+"_analyzed.jpg");
wait(100);


setTool("zoom");
selectWindow("orig");
close();

close("*");

}

macro "QKI Action Tool 1 Options" {
     Dialog.create("TMA Parameters");
     
     Dialog.addNumber("Ratio micra/pixel", r);
     Dialog.addNumber("Non-tumor label", labNT);
     Dialog.addNumber("Tumor label", labT);     
     Dialog.addNumber("Nuclei threshold", thBlue);
     Dialog.addNumber("Min nuclei size", minCellSize);
     Dialog.addNumber("Max nuclei size", maxCellSize);
     Dialog.addNumber("Threshold 0-1", th1);
     Dialog.addNumber("Threshold 1-2", th2);
     Dialog.addNumber("Threshold 2-3", th3);
     Dialog.show();
     r= Dialog.getNumber();
     labNT= Dialog.getNumber();
     labT= Dialog.getNumber();
     thBlue= Dialog.getNumber();
     minCellSize= Dialog.getNumber();
     maxCellSize= Dialog.getNumber();
     th1= Dialog.getNumber();
     th2= Dialog.getNumber();
     th3= Dialog.getNumber();
             
}


