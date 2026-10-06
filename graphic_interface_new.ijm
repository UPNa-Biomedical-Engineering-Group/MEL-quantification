/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//The main macro “graphic_interface_new.ijm” provides a step-by-step graphical dialog
//allowing users to choose the appropriate processing pipeline based on three primary criteria:
//Single image or batch mode;
//ROI: whole tissue, ROI from mask or manual ROI
//Tissue compartment of interest: nuclei, cytoplasm or membrane
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Title
Dialog.create("Adenocarcinoma Plugin");

mode1 = newArray("Single image mode", "Batch mode");
Dialog.addRadioButtonGroup("Analysis mode:", mode1, 2, 2, mode1[0]);
Dialog.show();

selected_choice1 = Dialog.getRadioButton();
print(selected_choice1);

if (selected_choice1 == mode1[0]){
	Dialog.create("Single image");
	mode2 = newArray("Whole tissue", "ROI from mask","Manual ROI");
	Dialog.addRadioButtonGroup("Region to analyze:", mode2, 3, 3, mode2[0]);
	Dialog.show();
	selected_choice2 = Dialog.getRadioButton();
	print(selected_choice2);
	if (selected_choice2 == mode2[0]){
		Dialog.create("Tissue structure of interest");
		// Marker selection
		markers = newArray("Nuclei", "Membrane", "Cytoplasm");
		Dialog.addChoice("Structure selection:", markers, markers[0]);
		// Show the list
		Dialog.show();
		// Marker selected
		selected_marker = Dialog.getChoice();
		print("Marker selected: " + selected_marker);
		if(selected_marker == markers[0]){
			run("a0 nuclear whole tissue");
		}else if(selected_marker == markers[1]){
			run("a0 membrane whole tissue");
		}else if(selected_marker == markers[2]){
			run("a0 cytoplasm whole tissue");
		}
		
	}else if (selected_choice2 == mode2[1]){
		Dialog.create("Tissue structure of interest");
		// Marker selection
		markers = newArray("Nuclei", "Membrane", "Cytoplasm");
		Dialog.addChoice("Structure selection:", markers, markers[0]);
		// Show the list
		Dialog.show();
		// Marker selected
		selected_marker = Dialog.getChoice();
		print("Marker selected: " + selected_marker);
		if(selected_marker == markers[0]){
			run("a0 nuclear single");
		}else if(selected_marker == markers[1]){
			run("a0 membrane single");
		}else if(selected_marker == markers[2]){
			run("a0 cytoplasm single");
		}
	}else{
		Dialog.create("Tissue structure of interest");
		// Marker selection
		markers = newArray("Nuclei", "Membrane", "Cytoplasm");
		Dialog.addChoice("Structure selection:", markers, markers[0]);
		// Show the list
		Dialog.show();
		// Marker selected
		selected_marker = Dialog.getChoice();
		print("Marker selected: " + selected_marker);
		if(selected_marker == markers[0]){
			run("a0 nuclear ROI");
		}else if(selected_marker == markers[1]){
			run("a0 membrane ROI");
		}else if(selected_marker == markers[2]){
			run("a0 cytoplasm ROI");
		}
	}
}else{
	Dialog.create("Batch mode");
	mode2 = newArray("Whole tissue", "ROI from mask");
	Dialog.addRadioButtonGroup("Region to analyze:", mode2, 2, 2, mode2[0]);
	Dialog.show();
	selected_choice2 = Dialog.getRadioButton();
	print(selected_choice2);
	if (selected_choice2 == mode2[0]){
		Dialog.create("Tissue structure of interest");
		// Marker selection
		markers = newArray("Nuclei", "Membrane", "Cytoplasm");
		Dialog.addChoice("Structure selection:", markers, markers[0]);
		// Show the list
		Dialog.show();
		// Marker selected
		selected_marker = Dialog.getChoice();
		print("Marker selected: " + selected_marker);
		if(selected_marker == markers[0]){
			run("a0 nuclear tissue");
		}else if(selected_marker == markers[1]){
			run("a0 membrane tissue");
		}else if(selected_marker == markers[2]){
			run("a0 cytoplasm tissue");
		}
		
	}else{
		Dialog.create("Tissue structure of interest");
		// Marker selection
		markers = newArray("Nuclei", "Membrane", "Cytoplasm");
		Dialog.addChoice("Structure selection:", markers, markers[0]);
		// Show the list
		Dialog.show();
		// Marker selected
		selected_marker = Dialog.getChoice();
		print("Marker selected: " + selected_marker);
		if(selected_marker == markers[0]){
			run("a0 nuclear");
		}else if(selected_marker == markers[1]){
			run("a0 membrane");
		}else if(selected_marker == markers[2]){
			run("a0 cytoplasm");
		}
	}
}

