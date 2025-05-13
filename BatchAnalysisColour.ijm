//Name: Nrushanth Suthaharan
//Date: 2025-02-18
//Description: Automatic batch analysis of multiple frames for area, using colour thresholding
//Notes: I recommend to do run the code on initial frames seperately and handpick the areas
// (due to external lighting issues) and then run code on other frames
//if run correctly, should get numSamples * numFrames = numRows in excel sheet

//Ask if scale is set
checkScale = getBoolean("Have you editted either of line 148 or line 156 in this code according to your scale?", "Yes, the scale is set", "No, the scale is not set");
if(!checkScale){
	print("Please go to Plugin > Macros > Record, then open one frame, create your linear or circular reference");
	exit("Copy and paste your scale from the Record window into line 78 (if you have a circular reference) or line 86 (if you have a linear reference). Read the SOP for more guidance, terminating program.");
}
//Help with circular scale
isCircle = getBoolean("Are you using a circular reference scale?", "yes", "no");
//isCircle = true;
if(isCircle){
	diameter = getNumber("Enter known diameter in mm:", 90);
	//diameter = 85.51;
}
else{
	knownScale = getNumber("Enter known distance in mm:", 90);
}

//Check if samples are arranged horizontally or vertically
isHorizontal = getBoolean("Are your samples arranged horizontally?", "Yes, they're arranged horizontally", "No, they're arranged vertically");

//Select input directory
input = getDirectory("input folder containing images");

//Select output directory
output = getDirectory("output folder to store results");
//list of images
listImages = getFileList(input);

//Skip Optimization for initial frames
options = newArray("Yes","No, I'm doing regular frames now","No, I'm stuck");
Dialog.create("What do you want to do?");
Dialog.addChoice("Are you analysing initial frames?", options,"No, I'm doing regular frames now");
Dialog.show();
selected = Dialog.getChoice();
if(selected == "No, I'm stuck"){
	exit("Open your last initial frame in fiji. Navigate Image > Adjust > Color Threshold. Move the sliders until your samples are highlighted to your desire. Keep note of the min and max values for all 3 sliders. If you want to analyse your regular frames, do the same as above for the first and last frame. Terminating program.");
}
//get number samples per frame
numSamples = getNumber("Enter the number of samples per frame:", 0);
//numSamples =6;
//get estimate minimum size of sample
minSize = getNumber("Enter Minimum Size of samples [mm^2] (Assume you cut your sample short by ~1mm):", 20);
//minSize = 16;
//get estimate max size of sample
maxSize = getNumber("Enter Maximum Size of samples [mm^2]:", 50);
//maxSize = 100;
minHue = getNumber("Enter the Minimum Hue colour of your samples:", 0);
//minHue = 0;
maxHue = getNumber("Enter the Maximum Hue colour of your samples:", 255);
//maxHue = 52;
minSat = getNumber("Enter the Minimum Saturation of your samples:",0);
//minSat = 0;
maxSat = getNumber("Enter the Maximum Saturation of your samples:", 255);
//maxSat = 255;
minBright = getNumber("Enter the Minimum Brightness of your samples:", 0);
//minBright = 210;
maxBright = getNumber("Enter the Maximum Brightness of your samples", 255);
//maxBright = 255;

//adjustment factor for brightness
adjustmentFactor = getNumber("Enter adjustment factor for brightness optimization:", 20);
//adjustmentFactor = 30;

//def function to perform analysis
function analyse(minHue,maxHue,minSat,maxSat,minBright,maxBright,minSize){
	run("Duplicate...", "title=Thresholding");
	min=newArray(3);
	max=newArray(3);
	filter=newArray(3);
	run("HSB Stack");
	run("Convert Stack to Images");
	selectWindow("Hue");
	rename("0");
	selectWindow("Saturation");
	rename("1");
	selectWindow("Brightness");
	rename("2");
	min[0]=minHue;
	max[0]=maxHue;
	filter[0]="pass";
	min[1]=minSat;
	max[1]=maxSat;
	filter[1]="pass";
	min[2]=minBright;
	max[2]=maxBright;
	filter[2]="pass";
	for (i=0;i<3;i++){
		selectWindow(""+i);
		setThreshold(min[i], max[i]);
		run("Convert to Mask");
		//run("Watershed"); // this might cause issues
		if (filter[i]=="stop")  run("Invert");
	}
	imageCalculator("AND create", "0","2");
	imageCalculator("AND create", "Result of 0","1");
	for(j=0;j<3;j++){
		selectWindow(""+j);
		close();
	}
	selectWindow("Result of Result of 0");
	run("Analyze Particles...", "size="+minSize+"-Infinity exclude add");
	close();
	selectWindow("Result of 0");
	close();
}

function deleteROIs() {
	count = roiManager("count");
	print("deletion");
    for (j = 0; j < count; j++) {
        // Access global ROI Manager list
        lastIndex = roiManager("count")-1;
        roiManager("Select", lastIndex);
        roiManager("delete");
    }
}
function getMinArea(){
	count = roiManager("count");
	if(count == 0) return 0;
	
	roiManager("measure");
	minArea = getResult("Area", 0);;
	
	for(k = 0; k< count; k++){
		currentArea = getResult("Area", k);
		if(currentArea<minArea) minArea = currentArea;
	}
	Table.reset("Results");
	return minArea;
}

isDim = getBoolean("Is your sample getting dimmer through the experiment", "Yes it dims slightly", "No, it gets brighter");
setBatchMode(true);

globalROIs = newArray(0);
for (i = 0; i < listImages.length; i++) {
	tempROIPath = output + "temp_" + i + ".zip";	
	//Generic Do Not Delete
	open(input+listImages[i]);
	//title = getTitle();
	
	roiManager("Reset");
	//INSERT SCALE FROM MACRO RECORD HERE BELOW
	if(isCircle){
		makeOval(708, 270, 664, 670); //Replace this with your own circle from the Macro Record
		run("Measure");
		perimeter = getResult("Perim.", nResults-1);
		Table.deleteRows(nResults-1, nResults-1);
		calcDiameter = perimeter/PI;
		run("Set Scale...","distance="+calcDiameter+" known="+ diameter+" unit=mm");
	}
	else{
		makeLine(415, 151, 595, 161); //Replace this with your own line from the Macro Record
		run("Measure");
		calcLength = getResult("Length", 0);
		Table.deleteRows(nResults-1, nResults-1);
		run("Set Scale...", "distance="+calcLength+" known="+ knownScale+" unit=mm");
	}
	//INSERT SCALE FROM MACRO RECORD HERE ABOVE
	close("Results");
	
	//Rotate if needed
	if(isHorizontal){
		run("Rotate 90 Degrees Right");
	}

	analyse(minHue,maxHue,minSat,maxSat,minBright,maxBright,minSize);
	if(selected == "No, I'm doing regular frames now" && isDim == true){
		count = roiManager("count");
		attempt = 0;
		maxAttempt = 6; // limit brightness drop per frame to 15
		if(i ==0){
			lastArea = 0;
		}
		minArea = getMinArea();
		print(count +", "+ minSize+ ", "+minBright+", "+minArea+", "+lastArea);
		while(count!=numSamples && minSize >0 && minSize<maxSize && attempt < maxAttempt || minBright>=0 && attempt < maxAttempt && minArea<lastArea){			
			isShrinking =false;
			deleteROIs();
			print(count +", "+ minSize+ ", "+minBright+", "+minArea+", "+lastArea);
			//If smallest sample shrinking it may be getting dimmer
			if(minArea < lastArea){ // loosing area, lower brightness
				minBright -= adjustmentFactor;
				analyse(minHue,maxHue,minSat,maxSat,minBright,maxBright,minSize);
				count = roiManager("count");
				isShrinking = true;
			}
			
			if(count<numSamples){ // sample not detected, lower size margin and brightness
				if(isShrinking){
					deleteROIs();
					count =0;
				}
				minBright -= adjustmentFactor;
				minSize -= 0.1;
				analyse(minHue,maxHue,minSat,maxSat,minBright,maxBright,minSize);
				count = roiManager("count");
				
			}
			else if(count>numSamples){ // noise detected, increase size margin
				if(isShrinking){
					deleteROIs();
					count = 0;
				}
				minSize +=0.2;
				analyse(minHue,maxHue,minSat,maxSat,minBright,maxBright,minSize);
				count = roiManager("count");
			}
			minArea = getMinArea();
			attempt += 1;
			close;
		}
		lastArea = minArea;
		
	}
	else if(isDim == false){ // reverse code for brightening sample
		exit("Work in progress. Terminating program.");
	}
	
	
	if(minBright < 0){
	print("Sample is too dim!");
	break;
	}
	else if(minSize > maxSize || minSize<0){
	print("Too much sample size descrepency!");
	break;
	}
	
	roiManager("Save", tempROIPath);
	globalROIs = Array.concat(globalROIs,tempROIPath);
	//run("Close All");
}
	//DEBUGGING SECTION
	//roiManager("Measure");
	//saveAs("Results", output+i+".csv");
	//run("Clear Results");
	//roiManager("Save",output+i+".zip");
	//run("Close All");
roiManager("Reset");
for (i = 0; i < globalROIs.length; i++) {
    roiManager("Open", globalROIs[i]);
    //roiManager("Combine");
}

// SAVE FINAL RESULTS
roiManager("Measure");
saveAs("Results", output+"all_results.csv");
roiManager("Save", output+"all_rois.zip");

// CLEAN TEMP FILES
for (i = 0; i < globalROIs.length; i++) {
    File.delete(globalROIs[i]);
}

minSize = maxSize;
maxSize = 0;
for(i = 0;i<nResults;i++){
	currentSize = getResult("Area", i);
	if(currentSize>maxSize){
		maxSize = currentSize;
	}
	if(currentSize<minSize){
		minSize = currentSize;
	}
}
print("Minimum sample size:"+minSize);
print("Maximum sample size: "+maxSize);
print("Minimum brightness threshold: "+minBright);