
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//In this macro only one image is processed using a manual ROI chosen by the user
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var r=0.502, thBlue=100, minCellSize=30, maxCellSize=15000;

macro "QKI Action Tool 1 - Ca3fT0b09QT7b09KTdb09ITfb09c"{

	run("Close All");
	
	img=File.openDialog("Select ORIGINAL image");

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

open(img);
MyTitle=getTitle();
aa = split(MyTitle,".");
MyTitle_short = aa[0];
	
roiManager("Reset");
run("Clear Results");
MyTitle=getTitle();
output=getInfo("image.directory");

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
roiManager("Select", 2);
setBackgroundColor(255, 255, 255);
run("Clear Outside");
run("Select All");
//run("Analyze Particles...", "size=10-15000 pixel show=Masks in_situ");
run("Analyze Particles...", "size="+minCellSize+"-"+maxCellSize+" pixel show=Masks in_situ");
run("Dilate");	// dilate nuclei to avoid counting as cytoplasm the border of the nucleus
run("Create Selection");
run("Add to Manager");	// ROI3 --> Cell nuclei in ROI selected area
close();


// OBTAIN CYTOPLASM AREA IN ROI REGION

roiManager("deselect");
roiManager("Select", newArray(2,3));
roiManager("AND");
roiManager("Add");
roiManager("deselect");
roiManager("Select", newArray(2,4));
roiManager("XOR");
roiManager("Add");
roiManager("deselect");
roiManager("Select", newArray(3,4));
roiManager("Delete");
roiManager("deselect");	// ROI3 --> Cytoplasm area in tisse ROI



// MEASURE DAB STAINING--

run("Clear Results");
selectWindow("brown");
run("Select All");
setBatchMode(true);
run("Invert");
roiManager("Select", 3);
run("Set Measurements...", "area mean standard modal min redirect=None decimal=2");
roiManager("Measure");
Table.renameColumn("Area", "Area Cytoplasm");
Table.renameColumn("Mean", "Mean Intensity Cytoplasm");
IavgCyto=getResult("Mean",0);
Acyto=getResult("Area",0);
Acytom=Acyto*r*r;

selectWindow(MyTitle);
setBatchMode(false);
rename("orig");
roiManager("Show None");
roiManager("Select", 3);
roiManager("Set Color", "red");
roiManager("Set Line Width", 1);
showMessage("Done!");

//close();
/*
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
setResult("Cytoplasm area in ROI (%)",i,r1);
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
*/
}

macro "QKI Action Tool 1 Options" {
     Dialog.create("TMA Parameters");
     
     Dialog.addNumber("Ratio micra/pixel", r);
     Dialog.addNumber("Non-ROI label", labNT);
     Dialog.addNumber("ROI label", roiLabel);
     Dialog.addNumber("Nuclei threshold", thBlue);
     Dialog.addNumber("Min nuclei size", minCellSize);
     Dialog.addNumber("Max nuclei size", maxCellSize);
     Dialog.addNumber("Threshold 0-1", th1);
     Dialog.addNumber("Threshold 1-2", th2);
     Dialog.addNumber("Threshold 2-3", th3);
     Dialog.show();
     r= Dialog.getNumber();
     labNT= Dialog.getNumber();
     roiLabel= Dialog.getNumber();
     thBlue= Dialog.getNumber();
     minCellSize= Dialog.getNumber();
     maxCellSize= Dialog.getNumber();
     th1= Dialog.getNumber();
     th2= Dialog.getNumber();
     th3= Dialog.getNumber();
             
}


