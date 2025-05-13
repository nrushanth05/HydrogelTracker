An ImageJ Macro (.ijm) for automating the extraction and analysis of hydrogel sample videos.
HydrogelTracker splits a user-supplied video into individual frames, isolates each hydrogel sample, and computes its area over time.

🚀 Features
Video → Frames
Splits any supported video into still frames at a user-defined interval (e.g. one frame every n seconds or frames).

Automated ROI Detection
Applies thresholding, morphological cleanup, and particle analysis to identify and isolate the hydrogel sample in each frame.

Area Measurement
Calculates the area (in pixels or calibrated units) of the isolated hydrogel region for every extracted frame.

Interactive UI
Prompts you to:

Select the input video file

Choose an output folder for frames and results

Specify frame-extraction parameters (interval, start/end times)

Adjust thresholding options (method, min/max grey levels)

Batch-ready
Processes entire videos in one go—no need to manually extract or analyze individual images.

Application

Was used in lab analysis to eliminate manual analysis giving repeatable results in less than 5 minutes (manually would take several hours).

📦 Requirements
ImageJ / Fiji (latest recommended build)

Basic familiarity with running ImageJ macros
