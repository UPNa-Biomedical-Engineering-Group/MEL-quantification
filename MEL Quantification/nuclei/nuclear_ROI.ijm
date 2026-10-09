
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//In this macro only one image is processed using a manual ROI chosen by the user
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var r=0.502, thBlue=190, minCellSize=30, maxCellSize=15000;

macro "BRCA Action Tool 1 - Ca3fT0b09BT5b09RTab09CTfb09A"{

	run("Close All");

	
	img=File.openDialog("Select ORIGINAL image");
	//seg = File.openDialog("Select SEGMENTATION image");
	
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


//OutDir = segDir+File.separator+"Quantification_results";
//File.makeDirectory(OutDir);


setBatchMode(true);//set to true, once the tests are finished
run("Colors...", "foreground=white background=black selection=green");

// Get marker
par=File.getParent(output);
marker = substring(output, lengthOf(par)+1, lengthOf(output)-1);
//print(marker);
selectWindow(MyTitle);
run("Select None"); // deselect ROI temporarily
run("Duplicate...", "title=label");
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

//close();
/*

// Measure non-ROI area:
run("Set Measurements...", "area redirect=None decimal=2");
selectWindow(MyTitle);
//run("Select All");
roiManager("Select", 2);
roiManager("Measure");
Ant=getResult("Area",0);
Antm=Ant*r*r;
//print(Antm); debugging
run("Clear Results");
roiManager("Select", 2);
roiManager("delete");
roiManager("Select",1);
roiManager("delete");

// Create ROI area:
selectWindow("label");
setThreshold(roiLabel, roiLabel);
run("Convert to Mask");
run("Create Selection");
roiManager("add");

//Intersection phase 
roiManager("Select",newArray(0,1));
roiManager("and");
roiManager("add"); // --> ROI2 ROI AREA

//close();
//selectWindow("label");
//close();

*/

// TOTAL TISSUE AREA:
//Atissuem = Antm+Atm;
//rROI = Atm/Atissuem*100;	// ROI area in %


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
run("Create Selection");
run("Add to Manager");	// ROI3 --> Cell nuclei in ROI
close();



// MEASURE DAB STAINING--

run("Clear Results");
selectWindow("brown");
setBatchMode(true);
run("Invert");
roiManager("Select", 3);
run("Set Measurements...", "area mean standard modal min redirect=None decimal=2");
roiManager("Measure");
Table.renameColumn("Area", "Area Nuclei");
Table.renameColumn("Mean", "Mean Intensity Nuclei");
IavgNucl=getResult("Mean",0);
print(IavgNucl);
Anucl=getResult("Area",0);
Anuclm=Anucl*r*r;

selectWindow(MyTitle);
setBatchMode(false);
rename("orig");
roiManager("Show None");
roiManager("Select", 3);
roiManager("Set Color", "red");
roiManager("Set Line Width", 2);
//run("Flatten");
showMessage("Done!");

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
setResult("Label", i, MyTitle); 	
setResult("Non-ROI area (um2)",i,Antm);
setResult("ROI area (um2)",i,Atm);
setResult("ROI area in tissue (%)",i,rROI);
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
roiManager("Select", 3);
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





